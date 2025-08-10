#!/bin/bash
# AmneziaWG Docker Server Entrypoint
# Docker-реализация: asychin (https://github.com/asychin)
# Оригинальный VPN сервер: AmneziaWG Team (https://github.com/amnezia-vpn)

set -e

# Цвета для логов
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция логирования
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Конфигурация по умолчанию
AWG_INTERFACE=${AWG_INTERFACE:-awg0}
AWG_PORT=${AWG_PORT:-51820}
AWG_NET=${AWG_NET:-10.13.13.0/24}
AWG_SERVER_IP=${AWG_SERVER_IP:-10.13.13.1}
AWG_DNS=${AWG_DNS:-8.8.8.8,8.8.4.4}

# Параметры обфускации AmneziaWG
AWG_JC=${AWG_JC:-7}
AWG_JMIN=${AWG_JMIN:-50}
AWG_JMAX=${AWG_JMAX:-1000}
AWG_S1=${AWG_S1:-86}
AWG_S2=${AWG_S2:-574}
AWG_H1=${AWG_H1:-1}
AWG_H2=${AWG_H2:-2}
AWG_H3=${AWG_H3:-3}
AWG_H4=${AWG_H4:-4}

# Путь к конфигурации
CONFIG_FILE="/app/config/${AWG_INTERFACE}.conf"
CLIENT_DIR="/app/clients"

# Функция получения публичного IP
get_public_ip() {
    if [ "$SERVER_PUBLIC_IP" = "auto" ] || [ -z "$SERVER_PUBLIC_IP" ]; then
        # Исправляем DNS если нужно
        if ! nslookup google.com >/dev/null 2>&1; then
            log "Исправляем DNS настройки..."
            echo "nameserver 8.8.8.8" > /etc/resolv.conf
            echo "nameserver 8.8.4.4" >> /etc/resolv.conf
        fi
        
        log "Определяем публичный IP автоматически..."
        
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
        
        SERVER_PUBLIC_IP=""
        
        # Пробуем каждый сервис до получения валидного IP
        for service in "${IP_SERVICES[@]}"; do
            log "Пробуем сервис: $service"
            
            # Получаем ответ с таймаутом 10 секунд
            response=$(curl -s --connect-timeout 10 --max-time 15 "$service" 2>/dev/null)
            
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
                    SERVER_PUBLIC_IP="$ip"
                    log "✅ Публичный IP определён: $SERVER_PUBLIC_IP (через $service)"
                    break
                fi
            fi
            
            log "❌ Сервис $service не ответил корректно: '$ip'"
            sleep 1
        done
        
        # Если все сервисы не сработали, используем fallback
        if [ -z "$SERVER_PUBLIC_IP" ]; then
            warn "⚠️ Не удалось определить публичный IP автоматически!"
            warn "Используем fallback IP. ОБЯЗАТЕЛЬНО укажите правильный IP в .env файле:"
            warn "echo 'SERVER_PUBLIC_IP=ВАШ_ПУБЛИЧНЫЙ_IP' > .env"
            SERVER_PUBLIC_IP="UNKNOWN_IP_PLEASE_SET_MANUALLY"
        fi
    else
        log "Используется заданный IP: $SERVER_PUBLIC_IP"
    fi
    
    log "Публичный IP: $SERVER_PUBLIC_IP"
}

# Функция генерации ключей
generate_keys() {
    log "Генерируем ключи для сервера..."
    
    # Убеждаемся что директория config существует
    mkdir -p /app/config
    chmod 750 /app/config
    
    if [ ! -f "/app/config/server_private.key" ]; then
        awg genkey > /app/config/server_private.key
        chmod 600 /app/config/server_private.key
    fi
    
    if [ ! -f "/app/config/server_public.key" ]; then
        awg pubkey < /app/config/server_private.key > /app/config/server_public.key
    fi
    
    SERVER_PRIVATE_KEY=$(cat /app/config/server_private.key | tr -d '\n')
    SERVER_PUBLIC_KEY=$(cat /app/config/server_public.key | tr -d '\n')
    
    log "Ключи сервера сгенерированы"
}

# Функция создания конфигурации сервера
create_server_config() {
    log "Создаем конфигурацию сервера..."
    
    cat > "$CONFIG_FILE" << EOF
[Interface]
# Минимальная конфигурация для userspace режима
ListenPort = ${AWG_PORT}
PrivateKey = ${SERVER_PRIVATE_KEY}

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

EOF
    
    log "Конфигурация сервера создана: $CONFIG_FILE"
}

# Функция синхронизации существующих клиентов
sync_existing_clients() {
    log "Синхронизируем существующих клиентов с серверной конфигурацией..."
    log "CLIENT_DIR: $CLIENT_DIR"
    
    if [ -d "$CLIENT_DIR" ]; then
        log "Директория клиентов найдена"
        for client_file in "$CLIENT_DIR"/*.conf; do
            log "Проверяем файл: $client_file"
            if [ -f "$client_file" ]; then
                # Извлекаем имя клиента из имени файла
                client_name=$(basename "$client_file" .conf)
                log "Найден клиент: $client_name"
                
                # Получаем публичный ключ клиента
                public_key_file="${CLIENT_DIR}/${client_name}_public.key"
                if [ -f "$public_key_file" ]; then
                    public_key=$(cat "$public_key_file")
                    log "Публичный ключ получен для $client_name"
                    
                    # Получаем IP адрес клиента из конфигурации
                    client_ip=$(grep "^Address" "$client_file" | cut -d'=' -f2 | tr -d ' ' | cut -d'/' -f1)
                    log "IP адрес клиента $client_name: $client_ip"
                    
                    # Добавляем peer в серверную конфигурацию
                    cat >> "$CONFIG_FILE" << EOF

[Peer]
# $client_name
PublicKey = $public_key
AllowedIPs = $client_ip/32
EOF
                    log "Добавлен клиент в серверную конфигурацию: $client_name ($client_ip)"
                else
                    log "Файл публичного ключа не найден: $public_key_file"
                fi
            fi
        done
    else
        log "Директория клиентов не найдена: $CLIENT_DIR"
    fi
    
    log "Синхронизация клиентов завершена"
}

# Функция проверки доступности iptables
check_iptables_available() {
    # Проверяем принудительное отключение через переменную окружения
    if [ "$DISABLE_IPTABLES" = "true" ] || [ "$AWG_DISABLE_IPTABLES" = "true" ]; then
        warn "iptables принудительно отключен через переменную окружения"
        return 1
    fi
    
    # Проверяем CI/CD окружения
    if [ "$GITHUB_ACTIONS" = "true" ] || [ "$CI" = "true" ] || [ "$GITLAB_CI" = "true" ] || [ "$JENKINS_URL" != "" ]; then
        warn "Обнаружено CI/CD окружение, iptables может быть недоступен"
        return 1
    fi
    
    # Проверяем доступность iptables
    if ! command -v iptables >/dev/null 2>&1; then
        warn "iptables не найден в системе"
        return 1
    fi
    
    # Тестируем базовую работу iptables
    if ! iptables -L >/dev/null 2>&1; then
        warn "iptables недоступен (нет прав или nf_tables недоступен)"
        return 1
    fi
    
    return 0
}

# Функция настройки iptables
setup_iptables() {
    log "Настраиваем iptables..."
    
    # Проверяем доступность iptables
    if ! check_iptables_available; then
        warn "⚠️ iptables недоступен, переходим в режим только userspace"
        warn "ВНИМАНИЕ: NAT и маршрутизация должны быть настроены на уровне хоста!"
        warn "Для продакшена обязательно настройте:"
        warn "  • IP forwarding: echo 1 > /proc/sys/net/ipv4/ip_forward"
        warn "  • NAT правила: iptables -t nat -A POSTROUTING -s ${AWG_NET} -o eth0 -j MASQUERADE"
        warn "  • Forward правила: iptables -A FORWARD -i ${AWG_INTERFACE} -j ACCEPT"
        return 0
    fi
    
    # Пытаемся настроить iptables с обработкой ошибок
    log "Попытка настройки iptables..."
    
    # Очистка старых правил (игнорируем ошибки)
    iptables -t nat -F 2>/dev/null || warn "Не удалось очистить NAT правила"
    iptables -t filter -F FORWARD 2>/dev/null || warn "Не удалось очистить FORWARD правила"
    
    # Пытаемся включить NAT для клиентов
    if iptables -t nat -A POSTROUTING -s ${AWG_NET} -o eth0 -j MASQUERADE 2>/dev/null; then
        log "✅ NAT правило добавлено"
    else
        warn "❌ Не удалось добавить NAT правило"
    fi
    
    # Пытаемся настроить forward правила
    if iptables -A FORWARD -i ${AWG_INTERFACE} -j ACCEPT 2>/dev/null; then
        log "✅ FORWARD правило (входящий) добавлено"
    else
        warn "❌ Не удалось добавить FORWARD правило (входящий)"
    fi
    
    if iptables -A FORWARD -o ${AWG_INTERFACE} -j ACCEPT 2>/dev/null; then
        log "✅ FORWARD правило (исходящий) добавлено"
    else
        warn "❌ Не удалось добавить FORWARD правило (исходящий)"
    fi
    
    log "Настройка iptables завершена (могут быть предупреждения в CI/CD)"
}

# Функция запуска AmneziaWG userspace (правильный подход согласно документации)
start_amneziawg() {
    log "Запускаем AmneziaWG userspace интерфейс ${AWG_INTERFACE}..."
    
    # Проверяем, существует ли уже интерфейс
    if ip link show ${AWG_INTERFACE} &>/dev/null; then
        warn "Интерфейс ${AWG_INTERFACE} уже существует, удаляем..."
        ip link del ${AWG_INTERFACE} 2>/dev/null || true
    fi
    
    # Очищаем старый сокет если существует
    rm -f /var/run/amneziawg/${AWG_INTERFACE}.sock 2>/dev/null || true
    
    # Запускаем amneziawg-go в фоновом режиме (принудительно userspace режим)
    log "Запускаем amneziawg-go для интерфейса ${AWG_INTERFACE}..."
    export WG_PROCESS_FOREGROUND=1
    amneziawg-go ${AWG_INTERFACE} &
    AWG_PID=$!
    echo $AWG_PID > /var/run/amneziawg.pid
    
    # Ждем создания интерфейса
    sleep 3
    
    # Проверяем, что процесс запустился и интерфейс создан
    if kill -0 $AWG_PID 2>/dev/null && ip link show ${AWG_INTERFACE} &>/dev/null; then
        log "AmneziaWG userspace успешно запущен (PID: $AWG_PID)"
        
        # Настраиваем интерфейс через прямые awg команды (правильный способ для userspace)
        log "Настраиваем интерфейс ${AWG_INTERFACE} через awg команды..."
        
        # Устанавливаем приватный ключ через файл
        awg set ${AWG_INTERFACE} private-key /app/config/server_private.key
        
        # Устанавливаем порт прослушивания
        awg set ${AWG_INTERFACE} listen-port ${AWG_PORT}
        
        # Создаем файл только с обфускационными параметрами AmneziaWG
        cat > "/tmp/obfuscation.conf" << EOF
[Interface]
Jc = ${AWG_JC}
Jmin = ${AWG_JMIN}
Jmax = ${AWG_JMAX}
S1 = ${AWG_S1}
S2 = ${AWG_S2}
H1 = ${AWG_H1}
H2 = ${AWG_H2}
H3 = ${AWG_H3}
H4 = ${AWG_H4}
EOF
        
        # Применяем обфускационные параметры через addconf
        awg addconf ${AWG_INTERFACE} /tmp/obfuscation.conf
        
        # Поднимаем интерфейс и назначаем IP
        ip link set ${AWG_INTERFACE} up
        ip addr add ${AWG_SERVER_IP}/${AWG_NET##*/} dev ${AWG_INTERFACE}
        
        log "AmneziaWG интерфейс настроен"
    else
        error "Ошибка запуска AmneziaWG userspace"
        exit 1
    fi
}

# Функция создания клиентской конфигурации
create_client_config() {
    local client_name=${1:-"client1"}
    local client_ip=${2:-"10.13.13.2"}
    
    log "Создаем конфигурацию для клиента: $client_name"
    
    # Убеждаемся что директория clients существует
    mkdir -p /app/clients
    chmod 750 /app/clients
    
    # Генерируем ключи клиента
    CLIENT_PRIVATE_KEY=$(awg genkey)
    CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | awg pubkey)
    
    # Сохраняем ключи
    echo "$CLIENT_PRIVATE_KEY" > "/app/clients/${client_name}_private.key"
    echo "$CLIENT_PUBLIC_KEY" > "/app/clients/${client_name}_public.key"
    
    # Создаем конфигурацию клиента
    cat > "/app/clients/${client_name}.conf" << EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${client_ip}/24
DNS = ${AWG_DNS}

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
    
    # Добавляем peer в конфигурацию сервера
    cat >> "$CONFIG_FILE" << EOF

[Peer]
# ${client_name}
PublicKey = ${CLIENT_PUBLIC_KEY}
AllowedIPs = ${client_ip}/32
EOF
    
    log "Конфигурация клиента $client_name создана"
    log "Приватный ключ: $CLIENT_PRIVATE_KEY"
    log "Публичный ключ: $CLIENT_PUBLIC_KEY"
    
    # Генерируем QR код
    if command -v qrencode &> /dev/null; then
        qrencode -t ansiutf8 < "/app/clients/${client_name}.conf"
        log "QR код для клиента $client_name сгенерирован"
    fi
}

# Функция для остановки сервиса
cleanup() {
    log "Получен сигнал завершения..."
    
    # Останавливаем amneziawg-go процесс
    if [ -f /var/run/amneziawg.pid ]; then
        AWG_PID=$(cat /var/run/amneziawg.pid)
        if kill -0 $AWG_PID 2>/dev/null; then
            log "Останавливаем amneziawg-go процесс (PID: $AWG_PID)..."
            kill $AWG_PID
            rm -f /var/run/amneziawg.pid
        fi
    fi
    
    # Удаляем сокет (альтернативный способ остановки согласно документации)
    rm -f /var/run/amneziawg/${AWG_INTERFACE}.sock 2>/dev/null || true
    
    # Удаляем интерфейс если он еще существует
    if ip link show ${AWG_INTERFACE} &>/dev/null; then
        log "Удаляем интерфейс ${AWG_INTERFACE}..."
        ip link del ${AWG_INTERFACE} 2>/dev/null || true
    fi
    
    log "AmneziaWG userspace остановлен"
    exit 0
}

# Обработка сигналов
trap cleanup SIGTERM SIGINT

# Основная логика
main() {
    log "=== Запуск AmneziaWG сервера ==="
    log "Интерфейс: $AWG_INTERFACE"
    log "Порт: $AWG_PORT"
    log "Сеть: $AWG_NET"
    log "IP сервера: $AWG_SERVER_IP"
    
    # Получаем публичный IP
    get_public_ip
    
    # Генерируем ключи
    generate_keys
    
    # Создаем конфигурацию сервера
    create_server_config
    
    # Синхронизируем существующих клиентов
    sync_existing_clients
    
    # Настраиваем iptables
    setup_iptables
    
    # Запускаем AmneziaWG
    start_amneziawg
    
    log "=== AmneziaWG сервер запущен успешно ==="
    log "Конфигурации клиентов доступны в /app/clients/"
    
    # Показываем статус
    if [ -f /var/run/amneziawg.pid ]; then
        AWG_PID=$(cat /var/run/amneziawg.pid)
        log "AmneziaWG userspace работает с PID: $AWG_PID"
        awg show ${AWG_INTERFACE} 2>/dev/null || log "Статус интерфейса недоступен"
    fi
    
    # Ожидание сигналов
    while true; do
        sleep 30
        if [ -f /var/run/amneziawg.pid ]; then
            AWG_PID=$(cat /var/run/amneziawg.pid)
            if ! kill -0 $AWG_PID 2>/dev/null; then
                error "Процесс amneziawg-go (PID: $AWG_PID) завершился, перезапускаем..."
                start_amneziawg
            fi
        else
            error "PID файл не найден, перезапускаем amneziawg-go..."
            start_amneziawg
        fi
    done
}

# Запуск основной функции
main "$@"
