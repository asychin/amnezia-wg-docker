#!/bin/bash
# AmneziaWG Docker Server — Генерация vpn:// URI для подключения клиентов
# Формат: vpn:// + base64url(4-byte-header + zlib(json))
# Совместимо с AmneziaVPN клиентом (Desktop + Mobile)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Директории
CONFIG_DIR="${CONFIG_DIR:-/app/config}"
CLIENT_DIR="${CLIENT_DIR:-/app/clients}"

# Параметры обфускации AWG v2
AWG_INTERFACE=${AWG_INTERFACE:-awg0}
AWG_PORT=${AWG_PORT:-51820}
AWG_NET=${AWG_NET:-10.13.13.0/24}
AWG_DNS=${AWG_DNS:-8.8.8.8,8.8.4.4}
AWG_JC=${AWG_JC:-7}
AWG_JMIN=${AWG_JMIN:-50}
AWG_JMAX=${AWG_JMAX:-1000}
AWG_S1=${AWG_S1:-86}
AWG_S2=${AWG_S2:-120}
AWG_S3=${AWG_S3:-40}
AWG_S4=${AWG_S4:-10}
AWG_H1=${AWG_H1:-1}
AWG_H2=${AWG_H2:-2}
AWG_H3=${AWG_H3:-3}
AWG_H4=${AWG_H4:-4}

# Режим вывода: normal (с форматированием) или raw (только URI)
OUTPUT_MODE="normal"

# Использование
usage() {
    echo "Использование: $(basename "$0") [--raw] <имя_клиента>"
    echo ""
    echo "Генерирует vpn:// URI для импорта в AmneziaVPN клиент."
    echo "Клиент должен быть создан заранее через manage-clients.sh."
    echo ""
    echo "Опции:"
    echo "  --raw    Вывести только URI без форматирования (для скриптов)"
    echo ""
    echo "Пример:"
    echo "  $(basename "$0") client1"
    echo "  $(basename "$0") --raw client1"
    exit 1
}

# Кодирование .conf файла в vpn:// URI через python3
# Формат: vpn:// + base64url(4-byte-big-endian-length + zlib(json))
encode_vpn_uri() {
    local conf_file="$1"
    local client_name="$2"

    python3 -c "
import base64, json, zlib, sys

conf_file = sys.argv[1]
client_name = sys.argv[2]

# Читаем .conf файл
with open(conf_file, 'r') as f:
    conf_content = f.read().strip()

# Формируем JSON конфигурацию для AmneziaVPN клиента
config = {
    'containers': [{
        'awg': {
            'last_config': conf_content
        },
        'container': 'amnezia-awg'
    }],
    'defaultContainer': 'amnezia-awg',
    'description': 'AmneziaWG Server',
    'hostName': client_name
}

# Кодируем: JSON -> zlib -> 4-byte header + compressed -> base64url
json_bytes = json.dumps(config, separators=(',', ':')).encode('utf-8')
compressed = zlib.compress(json_bytes)
header = len(json_bytes).to_bytes(4, byteorder='big')
encoded = base64.urlsafe_b64encode(header + compressed).decode().rstrip('=')

print(f'vpn://{encoded}')
" "$conf_file" "$client_name"
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

    # Генерируем vpn:// URI
    local vpn_uri
    vpn_uri=$(encode_vpn_uri "$conf_file" "$client_name")

    if [ -z "$vpn_uri" ]; then
        error "Не удалось сгенерировать vpn:// URI"
        exit 1
    fi

    # Выводим результат
    if [ "$OUTPUT_MODE" = "raw" ]; then
        # Только URI без форматирования — для использования в скриптах и QR кодах
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
}

main "$@"
