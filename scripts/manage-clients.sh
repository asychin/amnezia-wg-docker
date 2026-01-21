#!/bin/bash
# AmneziaWG Client Management Script
# Docker-реализация: asychin (https://github.com/asychin)
# Оригинальный VPN сервер: AmneziaWG Team (https://github.com/amnezia-vpn)

# Скрипт для управления клиентами AmneziaWG

set -e

# БЕЗОПАСНОСТЬ: Защита приватных ключей через umask
umask 077

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

# БЕЗОПАСНОСТЬ: Валидация имени клиента
validate_client_name() {
    local name="$1"
    
    # Проверка на пустое имя
    if [ -z "$name" ]; then
        error "Имя клиента не может быть пустым"
        return 1
    fi
    
    # Проверка длины (макс 63 символа для совместимости с DNS)
    if [ ${#name} -gt 63 ]; then
        error "Имя клиента слишком длинное (максимум 63 символа)"
        return 1
    fi
    
    # ЗАЩИТА: Только буквы, цифры, дефис и подчеркивание
    if ! echo "$name" | grep -qE '^[A-Za-z0-9_-]+$'; then
        error "Недопустимые символы в имени клиента"
        error "Разрешены только: A-Z, a-z, 0-9, дефис (-), подчеркивание (_)"
        return 1
    fi
    
    # ЗАЩИТА: Path traversal атаки (.. и /)
    if echo "$name" | grep -qE '\.\.|/'; then
        error "Обнаружена попытка path traversal атаки"
        return 1
    fi
    
    # ЗАЩИТА: Имя не должно начинаться с дефиса (shell injection)
    if [[ "$name" =~ ^- ]]; then
        error "Имя клиента не может начинаться с дефиса"
        return 1
    fi
    
    return 0
}

# БЕЗОПАСНОСТЬ: Получение эксклюзивной блокировки для предотвращения race conditions
acquire_lock() {
    local lockfile="/var/lock/amneziawg-manage.lock"
    local lock_fd=200
    
    # Создаем директорию для блокировок если не существует
    mkdir -p /var/lock 2>/dev/null || true
    
    # Открываем файл блокировки
    eval "exec $lock_fd>$lockfile"
    
    # Пытаемся получить эксклюзивную блокировку (ждём до 30 секунд)
    if ! flock -x -w 30 $lock_fd; then
        error "Не удалось получить блокировку (другая операция выполняется)"
        return 1
    fi
    
    return 0
}

# БЕЗОПАСНОСТЬ: Освобождение блокировки
release_lock() {
    local lock_fd=200
    flock -u $lock_fd 2>/dev/null || true
}

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
        log "Определяем публичный IP автоматически..."
        
        # Исправляем DNS если нужно (с проверкой прав записи)
        if ! nslookup google.com >/dev/null 2>&1; then
            log "Исправляем DNS настройки..."
            if [ -w /etc/resolv.conf ] || [ -w /etc ]; then
                echo "nameserver 8.8.8.8" > /etc/resolv.conf
                echo "nameserver 8.8.4.4" >> /etc/resolv.conf
            else
                warn "Нет прав для изменения /etc/resolv.conf, пропускаем..."
            fi
        fi
        
        PUBLIC_IP=""
        
        # ПРИОРИТЕТНЫЙ МЕТОД: Определение IP через маршрутизацию (самый надёжный)
        if command -v ip >/dev/null 2>&1; then
            log "Пробуем определить IP через маршрутизацию (ip route)..."
            local_ip=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || true)
            
            if [ -n "$local_ip" ] && echo "$local_ip" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
                # Проверяем, не является ли это приватным IP
                if ! echo "$local_ip" | grep -qE '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|127\.)'; then
                    PUBLIC_IP="$local_ip"
                    log "✅ Публичный IP определён через маршрутизацию: $PUBLIC_IP"
                else
                    log "IP из маршрутизации приватный ($local_ip), используем внешние сервисы..."
                fi
            fi
        fi
        
        # Если приоритетный метод не сработал, используем внешние сервисы
        if [ -z "$PUBLIC_IP" ]; then
            # Список сервисов для определения публичного IP (в порядке приоритета)
            IP_SERVICES=(
                "http://eth0.me"                    # Быстрый HTTP сервис
                "https://ipv4.icanhazip.com"        # Надежный HTTPS
                "https://api.ipify.org"             # JSON API
                "https://checkip.amazonaws.com"     # AWS сервис
                "https://ipinfo.io/ip"              # Подробная информация
                "https://ifconfig.me/ip"            # Классический сервис
                "http://whatismyip.akamai.com"      # CDN Akamai
                "http://i.pn"                       # JSON ответ
            )
            
            # Пробуем каждый сервис до получения валидного IP
            for service in "${IP_SERVICES[@]}"; do
                log "Пробуем сервис: $service"
                
                # Получаем ответ с таймаутом 10 секунд (ПРИНУДИТЕЛЬНО IPv4)
                response=$(curl -4 -s --connect-timeout 10 --max-time 15 "$service" 2>/dev/null)
                
                # Извлекаем IP из ответа
                if [[ "$service" == *"i.pn"* ]]; then
                    # Парсим JSON ответ от i.pn
                    ip=$(echo "$response" | grep '"query"' | sed 's/.*"query"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
                else
                    # Простой текстовый ответ - удаляем пробелы и переносы строк
                    ip=$(echo "$response" | tr -d '[:space:]')
                fi
                
                # Проверяем что получили валидный IPv4 адрес
                if echo "$ip" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
                    # Дополнительная проверка диапазонов IPv4
                    if echo "$ip" | awk -F. '$1>=1 && $1<=255 && $2>=0 && $2<=255 && $3>=0 && $3<=255 && $4>=0 && $4<=255' | grep -q "$ip"; then
                        PUBLIC_IP="$ip"
                        log "✅ Публичный IP определён: $PUBLIC_IP (через $service)"
                        break
                    fi
                fi
                
                log "❌ Сервис $service не ответил корректно: '$ip'"
                sleep 1
            done
        fi
        
        # Если все методы не сработали - ОШИБКА
        if [ -z "$PUBLIC_IP" ]; then
            error "❌ Не удалось определить публичный IP автоматически!"
            warn "Используем fallback. ОБЯЗАТЕЛЬНО укажите правильный IP в .env:"
            warn "  SERVER_PUBLIC_IP=ВАШ_ПУБЛИЧНЫЙ_IP"
            PUBLIC_IP="UNKNOWN_IP_PLEASE_SET_MANUALLY"
        fi
    else
        PUBLIC_IP="$SERVER_PUBLIC_IP"
        log "Используем заданный IP: $PUBLIC_IP"
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
    
    # БЕЗОПАСНОСТЬ: Валидация имени клиента
    if ! validate_client_name "$client_name"; then
        usage
        exit 1
    fi
    
    # БЕЗОПАСНОСТЬ: Получаем блокировку для предотвращения race conditions
    if ! acquire_lock; then
        error "Не удалось получить блокировку, попробуйте позже"
        exit 1
    fi
    
    # Гарантируем освобождение блокировки при выходе
    trap release_lock EXIT
    
    # Если IP не указан, автоматически находим свободный
    if [ -z "$client_ip" ]; then
        log "IP адрес не указан, ищем свободный автоматически..."
        client_ip=$(find_next_available_ip)
        log "Автоматически назначен IP: $client_ip"
    else
        # БЕЗОПАСНОСТЬ: Валидация IP адреса если предоставлен
        # Проверка что IP содержит только цифры и точки
        if [[ ! "$client_ip" =~ ^[0-9.]+$ ]]; then
            error "Недопустимый формат IP адреса: $client_ip"
            exit 1
        fi
        
        # Проверка структуры IPv4
        if [[ ! "$client_ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
            error "Недопустимый формат IPv4 адреса: $client_ip"
            exit 1
        fi
        
        # Проверка диапазонов октетов
        IFS='.' read -r -a octets <<< "$client_ip"
        for octet in "${octets[@]}"; do
            if [ "$octet" -gt 255 ]; then
                error "Недопустимый IP адрес (октет > 255): $client_ip"
                exit 1
            fi
        done
    fi
    
    # БЕЗОПАСНОСТЬ: Проверка существования с использованием безопасного пути
    if [ -f "${CLIENTS_DIR}/${client_name}.conf" ]; then
        error "Клиент $client_name уже существует"
        release_lock
        exit 1
    fi
    
    log "Добавляем клиента: $client_name с IP: $client_ip"
    
    # Генерируем ключи клиента (umask 077 уже установлен в начале скрипта)
    CLIENT_PRIVATE_KEY=$(awg genkey)
    CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | awg pubkey)
    
    # Получаем данные сервера
    get_public_ip
    get_server_public_key
    
    # Создаем конфигурацию клиента
    cat > "${CLIENTS_DIR}/${client_name}.conf" << EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${client_ip}/32
DNS = ${AWG_DNS:-8.8.8.8,8.8.4.4}
MTU = 1280
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
    
    # Make client config readable for users to import
    chmod 644 "${CLIENTS_DIR}/${client_name}.conf"
    
    # Сохраняем ключи отдельно (keep private key secure)
    echo "$CLIENT_PRIVATE_KEY" > "${CLIENTS_DIR}/${client_name}_private.key"
    chmod 600 "${CLIENTS_DIR}/${client_name}_private.key"
    echo "$CLIENT_PUBLIC_KEY" > "${CLIENTS_DIR}/${client_name}_public.key"
    chmod 644 "${CLIENTS_DIR}/${client_name}_public.key"
    
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
    
    # БЕЗОПАСНОСТЬ: Валидация имени клиента
    if ! validate_client_name "$client_name"; then
        usage
        exit 1
    fi
    
    # БЕЗОПАСНОСТЬ: Получаем блокировку для предотвращения race conditions
    if ! acquire_lock; then
        error "Не удалось получить блокировку, попробуйте позже"
        exit 1
    fi
    
    # Гарантируем освобождение блокировки при выходе
    trap release_lock EXIT
    
    # БЕЗОПАСНОСТЬ: Проверка существования с использованием безопасного пути
    if [ ! -f "${CLIENTS_DIR}/${client_name}.conf" ]; then
        error "Клиент $client_name не найден"
        release_lock
        exit 1
    fi
    
    log "Удаляем клиента: $client_name"
    
    # БЕЗОПАСНОСТЬ: Получаем публичный ключ клиента с безопасным путём
    CLIENT_PUBLIC_KEY=$(cat "${CLIENTS_DIR}/${client_name}_public.key" 2>/dev/null || echo "")
    
    # БЕЗОПАСНОСТЬ: Удаляем файлы клиента (используем безопасные пути)
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
    
    # БЕЗОПАСНОСТЬ: Валидация имени клиента
    if ! validate_client_name "$client_name"; then
        usage
        exit 1
    fi
    
    # БЕЗОПАСНОСТЬ: Проверка существования с использованием безопасного пути
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
    
    # БЕЗОПАСНОСТЬ: Валидация имени клиента
    if ! validate_client_name "$client_name"; then
        usage
        exit 1
    fi
    
    # БЕЗОПАСНОСТЬ: Проверка существования с использованием безопасного пути
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
