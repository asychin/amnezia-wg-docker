#!/bin/bash
# AmneziaWG Docker Server — Генерация vpn:// URI для подключения клиентов
# Формат vpn:// URI: vpn:// + base64url(4-byte-header + zlib(json))
# Формат QR: base64url(12-byte-header + zlib(json)) — бинарный формат AmneziaVPN
# Совместимо с AmneziaVPN клиентом (Desktop + Mobile)
#
# JSON структура соответствует формату AmneziaVPN клиента:
# - last_config: JSON-строка с параметрами AWG (не raw .conf!)
# - protocol_version: "2" при наличии S3/S4
# - isThirdPartyConfig: true для стороннего сервера
#
# Референс: https://github.com/ne0x/wg-easy/blob/feat/amneziavpn-qr/src/server/utils/wgHelper.ts

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Директории
CONFIG_DIR="${CONFIG_DIR:-/app/config}"
CLIENT_DIR="${CLIENT_DIR:-/app/clients}"

# Параметры по умолчанию
AWG_PORT=${AWG_PORT:-51820}

# Режим вывода: normal (с форматированием), raw (только URI), qr (бинарный для QR)
OUTPUT_MODE="normal"

# Использование
usage() {
    echo "Использование: $(basename "$0") [--raw|--qr] <имя_клиента>"
    echo ""
    echo "Генерирует vpn:// URI для импорта в AmneziaVPN клиент."
    echo "Клиент должен быть создан заранее через manage-clients.sh."
    echo ""
    echo "Опции:"
    echo "  --raw    Вывести только vpn:// URI без форматирования (для скриптов)"
    echo "  --qr     Вывести данные в бинарном формате для QR кода (без vpn://)"
    echo ""
    echo "Пример:"
    echo "  $(basename "$0") client1"
    echo "  $(basename "$0") --raw client1"
    echo "  $(basename "$0") --qr client1 | qrencode -t ansiutf8"
    exit 1
}

# Генерация vpn:// URI или QR данных через python3
# Формат JSON совместим с AmneziaVPN клиентом (референс: ne0x/wg-easy)
encode_config() {
    local conf_file="$1"
    local mode="$2"  # vpn или qr

    python3 -c '
import base64, json, zlib, struct, sys, os

conf_file = sys.argv[1]
mode = sys.argv[2]

# Читаем .conf файл
with open(conf_file, "r") as f:
    conf_content = f.read().strip()

# Парсим .conf файл по секциям
sections = {"Interface": {}, "Peer": {}}
current = None
for line in conf_content.split("\n"):
    line = line.strip()
    if line == "[Interface]":
        current = "Interface"
    elif line == "[Peer]":
        current = "Peer"
    elif "=" in line and current:
        key, val = line.split("=", 1)
        sections[current][key.strip()] = val.strip()

iface = sections["Interface"]
peer = sections["Peer"]

# Извлекаем server host и port из Endpoint
endpoint = peer.get("Endpoint", "")
if ":" in endpoint:
    server_host, server_port = endpoint.rsplit(":", 1)
else:
    server_host = endpoint
    server_port = "51820"

# Имя клиента из имени файла
client_name = os.path.splitext(os.path.basename(conf_file))[0]

# Формируем структурированный last_config (JSON объект как строка)
# Формат: все AWG параметры + ключи + мета-данные
last_config_obj = {}

# AWG параметры обфускации
for param in ["Jc", "Jmin", "Jmax", "S1", "S2", "S3", "S4",
              "H1", "H2", "H3", "H4"]:
    if param in iface:
        last_config_obj[param] = iface[param]

# Параметры подключения
last_config_obj["allowed_ips"] = [
    a.strip() for a in peer.get("AllowedIPs", "0.0.0.0/0").split(",")
]
last_config_obj["client_ip"] = iface.get("Address", "")
last_config_obj["client_priv_key"] = iface.get("PrivateKey", "")
last_config_obj["config"] = conf_content
last_config_obj["hostName"] = server_host
last_config_obj["mtu"] = iface.get("MTU", "1280")
last_config_obj["persistent_keep_alive"] = peer.get("PersistentKeepalive", "25")
last_config_obj["port"] = int(server_port)
last_config_obj["psk_key"] = peer.get("PresharedKey", "")
last_config_obj["server_pub_key"] = peer.get("PublicKey", "")

# DNS
dns_raw = iface.get("DNS", "8.8.8.8,8.8.4.4")
dns_parts = [d.strip() for d in dns_raw.split(",")]
# Фильтруем только IPv4 DNS (AmneziaVPN не поддерживает IPv6 DNS)
ipv4_dns = [d for d in dns_parts if all(p.isdigit() for p in d.split("."))]
dns1 = ipv4_dns[0] if len(ipv4_dns) > 0 else ""
dns2 = ipv4_dns[1] if len(ipv4_dns) > 1 else ""

# Определяем версию протокола (v2 если S3/S4 > 0)
protocol_info = {}
s3 = int(iface.get("S3", "0")) if "S3" in iface else 0
s4 = int(iface.get("S4", "0")) if "S4" in iface else 0
if s3 > 0 or s4 > 0:
    protocol_info["protocol_version"] = "2"

# Формируем конфигурацию AmneziaVPN клиента
config = {
    "containers": [{
        "awg": {
            "isThirdPartyConfig": True,
            "last_config": json.dumps(last_config_obj, separators=(",", ":")),
            "port": server_port,
            **protocol_info,
            "transport_proto": "udp",
        },
        "container": "amnezia-awg"
    }],
    "defaultContainer": "amnezia-awg",
    "description": client_name,
    "dns1": dns1,
    "dns2": dns2,
    "hostName": server_host,
}

json_str = json.dumps(config, separators=(",", ":"))
json_bytes = json_str.encode("utf-8")

if mode == "vpn":
    # vpn:// URI формат: vpn:// + base64url(4-byte BE length + zlib.compress(json))
    # Совместим с Qt qCompress/qUncompress
    compressed = zlib.compress(json_bytes)
    header = len(json_bytes).to_bytes(4, byteorder="big")
    encoded = base64.urlsafe_b64encode(header + compressed).decode().rstrip("=")
    print(f"vpn://{encoded}")
elif mode == "qr":
    # QR бинарный формат AmneziaVPN:
    # [0..3]  magic/version = 0x07C00100
    # [4..7]  zlib_len + 4
    # [8..11] uncompressed_len
    # [12..]  zlib compressed data
    # Референс: ne0x/wg-easy buildAmneziaQrPack
    compressed = zlib.compress(json_bytes)
    MAGIC = 0x07C00100
    header = struct.pack(">III", MAGIC, len(compressed) + 4, len(json_bytes))
    packed = header + compressed
    encoded = base64.urlsafe_b64encode(packed).decode().rstrip("=")
    print(encoded)
' "$conf_file" "$mode"
}

# Основная логика
main() {
    # Парсинг аргументов
    while [ $# -gt 0 ]; do
        case "$1" in
            --raw)
                OUTPUT_MODE="raw"
                shift
                ;;
            --qr)
                OUTPUT_MODE="qr"
                shift
                ;;
            -h|--help)
                usage
                ;;
            -*)
                error "Неизвестная опция: $1"
                usage
                ;;
            *)
                break
                ;;
        esac
    done

    local client_name="${1:-}"

    if [ -z "$client_name" ]; then
        usage
    fi

    # Проверяем имя клиента
    validate_client_name "$client_name" || exit 1

    # Проверяем существование конфигурации клиента
    local conf_file="${CLIENT_DIR}/${client_name}.conf"
    if [ ! -f "$conf_file" ]; then
        error "Конфигурация клиента не найдена: ${conf_file}"
        error "Сначала создайте клиента: make client-add NAME=${client_name}"
        exit 1
    fi

    # Проверяем наличие python3
    if ! command -v python3 &>/dev/null; then
        error "python3 не найден. Необходим для генерации vpn:// URI."
        exit 1
    fi

    # Генерируем данные
    if [ "$OUTPUT_MODE" = "qr" ]; then
        # QR бинарный формат — только данные без vpn:// префикса
        local qr_data
        qr_data=$(encode_config "$conf_file" "qr")
        if [ -z "$qr_data" ]; then
            error "Не удалось сгенерировать QR данные"
            exit 1
        fi
        echo "${qr_data}"
    else
        # vpn:// URI формат
        local vpn_uri
        vpn_uri=$(encode_config "$conf_file" "vpn")
        if [ -z "$vpn_uri" ]; then
            error "Не удалось сгенерировать vpn:// URI"
            exit 1
        fi

        if [ "$OUTPUT_MODE" = "raw" ]; then
            # Только URI без форматирования — для использования в скриптах
            echo "${vpn_uri}"
        else
            echo ""
            section "vpn:// URI для клиента: ${client_name}"
            echo ""
            echo "${vpn_uri}"
            echo ""
            info "Скопируйте строку выше и вставьте в AmneziaVPN клиент"
            info "Или отсканируйте QR-код: make client-qr NAME=${client_name}"
            echo ""
        fi
    fi
}

main "$@"
