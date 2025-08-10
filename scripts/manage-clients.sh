#!/bin/bash

# Скрипт для управления клиентами AmneziaWG

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Функции вывода
log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Конфигурация
AWG_INTERFACE=${AWG_INTERFACE:-awg0}
AWG_PORT=${AWG_PORT:-51820}
CONFIG_FILE="/app/config/${AWG_INTERFACE}.conf"
CLIENTS_DIR="/app/clients"

# Параметры обфускации
AWG_JC=${AWG_JC:-7}
AWG_JMIN=${AWG_JMIN:-50}
AWG_JMAX=${AWG_JMAX:-1000}
AWG_S1=${AWG_S1:-86}
AWG_S2=${AWG_S2:-574}
AWG_H1=${AWG_H1:-1}
AWG_H2=${AWG_H2:-2}
AWG_H3=${AWG_H3:-3}
AWG_H4=${AWG_H4:-4}

usage() {
    echo "Использование: $0 {add|remove|list|show|qr} [options]"
    echo ""
    echo "Команды:"
    echo "  add <name> [ip]     - Добавить нового клиента (IP назначается автоматически если не указан)"
    echo "  remove <name>       - Удалить клиента"
    echo "  list                - Показать список клиентов"
    echo "  show <name>         - Показать конфигурацию клиента"
    echo "  qr <name>           - Показать QR код клиента"
    echo ""
    echo "Примеры:"
    echo "  $0 add client2               # IP будет назначен автоматически"
    echo "  $0 add client3 10.13.13.5    # Указать конкретный IP"
    echo "  $0 remove client2"
    echo "  $0 qr client1"
}

# Получение публичного IP сервера
get_public_ip() {
    if [ "$SERVER_PUBLIC_IP" = "auto" ] || [ -z "$SERVER_PUBLIC_IP" ]; then
        PUBLIC_IP=$(curl -s --connect-timeout 5 ipinfo.io/ip 2>/dev/null || echo "127.0.0.1")
    else
        PUBLIC_IP="$SERVER_PUBLIC_IP"
    fi
}

# Получение публичного ключа сервера
get_server_public_key() {
    if [ -f "/app/config/server_public.key" ]; then
        SERVER_PUBLIC_KEY=$(cat /app/config/server_public.key)
    else
        error "Файл публичного ключа сервера не найден"
        exit 1
    fi
}

# Поиск следующего свободного IP адреса в подсети
find_next_available_ip() {
    # Получаем переменные из окружения или используем значения по умолчанию
    local awg_net="${AWG_NET:-10.13.13.0/24}"
    local awg_server_ip="${AWG_SERVER_IP:-10.13.13.1}"
    
    local subnet_base="${awg_net%/*}"  # Получаем базовую часть подсети (например, 10.13.13.0)
    local network_part="${subnet_base%.*}"  # Получаем первые три октета (например, 10.13.13)
    
    # Создаем массив занятых IP из существующих конфигураций клиентов
    local used_ips=()
    
    # Добавляем IP сервера как занятый
    local server_ip="${awg_server_ip##*.}"  # Получаем последний октет IP сервера
    used_ips+=("$server_ip")
    
    # Сканируем существующие конфигурации клиентов
    if [ -d "$CLIENTS_DIR" ]; then
        for config in "$CLIENTS_DIR"/*.conf; do
            if [ -f "$config" ]; then
                local client_ip=$(grep "^Address" "$config" 2>/dev/null | cut -d' ' -f3 | cut -d'/' -f1)
                if [ -n "$client_ip" ]; then
                    local last_octet="${client_ip##*.}"
                    used_ips+=("$last_octet")
                fi
            fi
        done
    fi
    
    # Сканируем конфигурацию сервера для peer записей
    if [ -f "$CONFIG_FILE" ]; then
        while IFS= read -r line; do
            if [[ "$line" =~ ^AllowedIPs[[:space:]]*=[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)/32 ]]; then
                local peer_ip="${BASH_REMATCH[1]}"
                local last_octet="${peer_ip##*.}"
                used_ips+=("$last_octet")
            fi
        done < "$CONFIG_FILE"
    fi
    
    # Ищем первый свободный IP начиная с .2 (так как .1 обычно сервер)
    for i in $(seq 2 254); do
        local ip_found=false
        for used_ip in "${used_ips[@]}"; do
            if [ "$i" = "$used_ip" ]; then
                ip_found=true
                break
            fi
        done
        
        if [ "$ip_found" = false ]; then
            echo "${network_part}.${i}"
            return 0
        fi
    done
    
    error "Нет доступных IP адресов в подсети"
    exit 1
}

# Добавление нового клиента
add_client() {
    local client_name="$1"
    local client_ip="$2"
    
    if [ -z "$client_name" ]; then
        error "Необходимо указать имя клиента"
        usage
        exit 1
    fi
    
    # Если IP не указан, автоматически находим свободный
    if [ -z "$client_ip" ]; then
        log "IP адрес не указан, ищем свободный автоматически..."
        client_ip=$(find_next_available_ip)
        log "Автоматически назначен IP: $client_ip"
    fi
    
    if [ -f "${CLIENTS_DIR}/${client_name}.conf" ]; then
        error "Клиент $client_name уже существует"
        exit 1
    fi
    
    log "Добавляем клиента: $client_name с IP: $client_ip"
    
    # Генерируем ключи клиента
    CLIENT_PRIVATE_KEY=$(awg genkey)
    CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | awg pubkey)
    
    # Получаем данные сервера
    get_public_ip
    get_server_public_key
    
    # Создаем конфигурацию клиента
    cat > "${CLIENTS_DIR}/${client_name}.conf" << EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${client_ip}/24
DNS = ${AWG_DNS:-8.8.8.8,8.8.4.4}

# Параметры обфускации AmneziaWG
Jc = ${AWG_JC}
Jmin = ${AWG_JMIN}
Jmax = ${AWG_JMAX}
S1 = ${AWG_S1}
S2 = ${AWG_S2}
H1 = ${AWG_H1}
H2 = ${AWG_H2}
H3 = ${AWG_H3}
H4 = ${AWG_H4}

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
Endpoint = ${PUBLIC_IP}:${AWG_PORT}
AllowedIPs = ${ALLOWED_IPS:-0.0.0.0/0}
PersistentKeepalive = 25
EOF
    
    # Сохраняем ключи отдельно
    echo "$CLIENT_PRIVATE_KEY" > "${CLIENTS_DIR}/${client_name}_private.key"
    echo "$CLIENT_PUBLIC_KEY" > "${CLIENTS_DIR}/${client_name}_public.key"
    
    # Добавляем peer в конфигурацию сервера
    cat >> "$CONFIG_FILE" << EOF

[Peer]
# ${client_name}
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = ${client_ip}/32
EOF
    
    # Устанавливаем безопасные права доступа к файлу конфигурации
    chmod 600 "$CONFIG_FILE"
    
    # Обновляем конфигурацию интерфейса
    if awg show ${AWG_INTERFACE} >/dev/null 2>&1; then
        # Интерфейс запущен, обновляем конфигурацию
        awg syncconf ${AWG_INTERFACE} "$CONFIG_FILE"
        log "Конфигурация интерфейса обновлена"
    else
        # Интерфейс не запущен, запускаем его
        awg-quick up "$CONFIG_FILE"
        log "Интерфейс запущен с новой конфигурацией"
    fi
    
    log "Клиент $client_name успешно добавлен"
    log "Конфигурация сохранена в: ${CLIENTS_DIR}/${client_name}.conf"
    
    # Показываем QR код
    if command -v qrencode &> /dev/null; then
        echo ""
        log "QR код для клиента $client_name:"
        qrencode -t ansiutf8 < "${CLIENTS_DIR}/${client_name}.conf"
    fi
}

# Удаление клиента
remove_client() {
    local client_name="$1"
    
    if [ -z "$client_name" ]; then
        error "Необходимо указать имя клиента"
        usage
        exit 1
    fi
    
    if [ ! -f "${CLIENTS_DIR}/${client_name}.conf" ]; then
        error "Клиент $client_name не найден"
        exit 1
    fi
    
    log "Удаляем клиента: $client_name"
    
    # Получаем публичный ключ клиента
    CLIENT_PUBLIC_KEY=$(cat "${CLIENTS_DIR}/${client_name}_public.key" 2>/dev/null || echo "")
    
    # Удаляем файлы клиента
    rm -f "${CLIENTS_DIR}/${client_name}.conf"
    rm -f "${CLIENTS_DIR}/${client_name}_private.key"
    rm -f "${CLIENTS_DIR}/${client_name}_public.key"
    
    # Удаляем peer из конфигурации сервера
    if [ -n "$CLIENT_PUBLIC_KEY" ]; then
        # Создаем временную конфигурацию без этого peer
        awk -v key="$CLIENT_PUBLIC_KEY" '
        /^\[Peer\]/ { in_peer=1; peer_block=""; next }
        in_peer && /^PublicKey = / {
            if ($3 == key) {
                skip_peer=1
                next
            } else {
                print "[Peer]"
                print peer_block
                print $0
                in_peer=0
                peer_block=""
                skip_peer=0
                next
            }
        }
        in_peer && !skip_peer { peer_block = peer_block $0 "\n"; next }
        in_peer && skip_peer && /^$/ { in_peer=0; skip_peer=0; next }
        in_peer && skip_peer { next }
        !in_peer { print }
        ' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
        
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    fi
    
    # Устанавливаем безопасные права доступа к файлу конфигурации
    chmod 600 "$CONFIG_FILE"
    
    # Обновляем конфигурацию интерфейса
    if awg show ${AWG_INTERFACE} >/dev/null 2>&1; then
        # Интерфейс запущен, обновляем конфигурацию
        awg syncconf ${AWG_INTERFACE} "$CONFIG_FILE"
        log "Конфигурация интерфейса обновлена"
    else
        # Интерфейс не запущен, запускаем его
        awg-quick up "$CONFIG_FILE"
        log "Интерфейс запущен с новой конфигурацией"
    fi
    
    log "Клиент $client_name успешно удален"
}

# Список клиентов
list_clients() {
    log "Список клиентов:"
    echo ""
    
    if [ ! -d "$CLIENTS_DIR" ] || [ -z "$(ls -A $CLIENTS_DIR/*.conf 2>/dev/null)" ]; then
        warn "Клиенты не найдены"
        return
    fi
    
    for config in "$CLIENTS_DIR"/*.conf; do
        if [ -f "$config" ]; then
            client_name=$(basename "$config" .conf)
            client_ip=$(grep "Address" "$config" | cut -d' ' -f3 | cut -d'/' -f1)
            echo "  - $client_name ($client_ip)"
        fi
    done
}

# Показать конфигурацию клиента
show_client() {
    local client_name="$1"
    
    if [ -z "$client_name" ]; then
        error "Необходимо указать имя клиента"
        usage
        exit 1
    fi
    
    if [ ! -f "${CLIENTS_DIR}/${client_name}.conf" ]; then
        error "Клиент $client_name не найден"
        exit 1
    fi
    
    log "Конфигурация клиента $client_name:"
    echo ""
    cat "${CLIENTS_DIR}/${client_name}.conf"
}

# Показать QR код клиента
show_qr() {
    local client_name="$1"
    
    if [ -z "$client_name" ]; then
        error "Необходимо указать имя клиента"
        usage
        exit 1
    fi
    
    if [ ! -f "${CLIENTS_DIR}/${client_name}.conf" ]; then
        error "Клиент $client_name не найден"
        exit 1
    fi
    
    if ! command -v qrencode &> /dev/null; then
        error "qrencode не установлен"
        exit 1
    fi
    
    log "QR код для клиента $client_name:"
    echo ""
    qrencode -t ansiutf8 < "${CLIENTS_DIR}/${client_name}.conf"
}

# Основная логика
case "$1" in
    add)
        add_client "$2" "$3"
        ;;
    remove)
        remove_client "$2"
        ;;
    list)
        list_clients
        ;;
    show)
        show_client "$2"
        ;;
    qr)
        show_qr "$2"
        ;;
    *)
        usage
        exit 1
        ;;
esac
