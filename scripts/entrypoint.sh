#!/bin/bash
# AmneziaWG Docker Server Entrypoint
# Docker-реализация: asychin (https://github.com/asychin)
# Оригинальный VPN сервер: AmneziaWG Team (https://github.com/amnezia-vpn)

set -e

# Подключаем общую библиотеку
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

# Конфигурация по умолчанию
AWG_INTERFACE=${AWG_INTERFACE:-awg0}
AWG_PORT=${AWG_PORT:-51820}
AWG_NET=${AWG_NET:-10.13.13.0/24}
AWG_SERVER_IP=${AWG_SERVER_IP:-10.13.13.1}
AWG_DNS=${AWG_DNS:-8.8.8.8,8.8.4.4}

# Параметры обфускации AmneziaWG (v2)
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

# Путь к конфигурации
CONFIG_FILE="/app/config/${AWG_INTERFACE}.conf"
CLIENT_DIR="/app/clients"

# get_public_ip() — используется из common.sh (режим strict)

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

# Параметры обфускации AmneziaWG (v2)
Jc = ${AWG_JC}
Jmin = ${AWG_JMIN}
Jmax = ${AWG_JMAX}
S1 = ${AWG_S1}
S2 = ${AWG_S2}
S3 = ${AWG_S3}
S4 = ${AWG_S4}
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
    
    # Определяем интерфейс для маршрутизации (SERVER_INTERFACE или автоопределение)
    local out_interface="${SERVER_INTERFACE:-}"
    if [ -z "$out_interface" ]; then
        # Автоопределение основного интерфейса
        out_interface=$(ip route | grep default | awk '{print $5}' | head -1)
        if [ -z "$out_interface" ]; then
            out_interface="eth0"
        fi
    fi
    log "Используем интерфейс для NAT: $out_interface"
    
    # Очистка старых правил (игнорируем ошибки)
    iptables -t nat -F 2>/dev/null || warn "Не удалось очистить NAT правила"
    iptables -t filter -F FORWARD 2>/dev/null || warn "Не удалось очистить FORWARD правила"
    
    # Пытаемся включить NAT для клиентов (доступ в интернет)
    if iptables -t nat -A POSTROUTING -s ${AWG_NET} -o $out_interface -j MASQUERADE 2>/dev/null; then
        log "✅ NAT правило добавлено (VPN -> интернет)"
    else
        warn "❌ Не удалось добавить NAT правило"
    fi
    
    # Site-to-site: если SERVER_SUBNET задан, добавляем маршрутизацию к локальной сети
    if [ -n "${SERVER_SUBNET:-}" ]; then
        log "Site-to-site режим: настраиваем доступ к локальной сети $SERVER_SUBNET"
        
        # NAT для доступа VPN клиентов к локальной сети сервера
        if iptables -t nat -A POSTROUTING -s ${AWG_NET} -d ${SERVER_SUBNET} -j MASQUERADE 2>/dev/null; then
            log "✅ NAT правило добавлено (VPN -> локальная сеть $SERVER_SUBNET)"
        else
            warn "❌ Не удалось добавить NAT правило для локальной сети"
        fi
        
        # Forward правила для трафика между VPN и локальной сетью
        if iptables -A FORWARD -s ${AWG_NET} -d ${SERVER_SUBNET} -j ACCEPT 2>/dev/null; then
            log "✅ FORWARD правило добавлено (VPN -> локальная сеть)"
        else
            warn "❌ Не удалось добавить FORWARD правило (VPN -> локальная сеть)"
        fi
        
        if iptables -A FORWARD -s ${SERVER_SUBNET} -d ${AWG_NET} -j ACCEPT 2>/dev/null; then
            log "✅ FORWARD правило добавлено (локальная сеть -> VPN)"
        else
            warn "❌ Не удалось добавить FORWARD правило (локальная сеть -> VPN)"
        fi
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
    
    # MSS clamping для предотвращения PMTUD Black Hole
    # В режиме host network (S2S) нет Docker-прослойки которая делает это автоматически
    # Это правило заставляет TCP соединения использовать правильный размер сегмента
    if iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null; then
        log "✅ MSS clamping правило добавлено (предотвращение PMTUD Black Hole)"
    else
        warn "❌ Не удалось добавить MSS clamping правило"
    fi
    
    log "Настройка iptables завершена (могут быть предупреждения в CI/CD)"
}

# Функция создания TUN устройства при необходимости
ensure_tun_device() {
    log "Проверяем доступность TUN устройства..."
    
    # Проверяем наличие /dev/net/tun
    if [ ! -e "/dev/net/tun" ]; then
        warn "TUN устройство не найдено, пытаемся создать..."
        
        # Создаем директорию если нужно
        mkdir -p /dev/net
        
        # Пытаемся создать TUN устройство
        if mknod /dev/net/tun c 10 200 2>/dev/null; then
            log "✅ TUN устройство создано: /dev/net/tun"
            chmod 666 /dev/net/tun
        else
            # Альтернативный способ через modprobe
            if command -v modprobe >/dev/null 2>&1; then
                log "Пытаемся загрузить модуль tun..."
                modprobe tun 2>/dev/null || warn "Не удалось загрузить модуль tun"
            fi
            
            # Еще одна попытка создания
            if mknod /dev/net/tun c 10 200 2>/dev/null; then
                log "✅ TUN устройство создано после загрузки модуля"
                chmod 666 /dev/net/tun
            else
                error "❌ Не удалось создать TUN устройство"
                error "Запустите контейнер с флагами: --privileged --cap-add=NET_ADMIN --device=/dev/net/tun"
                exit 1
            fi
        fi
    else
        log "✅ TUN устройство доступно: /dev/net/tun"
    fi
    
    # Проверяем права доступа
    if [ ! -r "/dev/net/tun" ] || [ ! -w "/dev/net/tun" ]; then
        warn "Недостаточно прав для доступа к TUN устройству"
        chmod 666 /dev/net/tun 2>/dev/null || warn "Не удалось изменить права доступа"
    fi
}

# Функция запуска AmneziaWG userspace (правильный подход согласно документации)
start_amneziawg() {
    log "Запускаем AmneziaWG userspace интерфейс ${AWG_INTERFACE}..."
    
    # Убеждаемся что TUN устройство доступно
    ensure_tun_device
    
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
S3 = ${AWG_S3}
S4 = ${AWG_S4}
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
        
        # Устанавливаем MTU для предотвращения проблем с фрагментацией
        # WireGuard/AmneziaWG добавляет ~60 байт overhead, поэтому MTU должен быть меньше 1500
        # 1280 - безопасное значение, работает везде (минимальный MTU для IPv6)
        ip link set ${AWG_INTERFACE} mtu 1280
        log "MTU интерфейса ${AWG_INTERFACE} установлен на 1280"
        
        # Синхронизируем конфигурацию с peer'ами (клиентами)
        log "Применяем конфигурацию с клиентами..."
        awg syncconf ${AWG_INTERFACE} ${CONFIG_FILE}
        
        log "AmneziaWG интерфейс настроен"
    else
        error "Ошибка запуска AmneziaWG userspace"
        exit 1
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

# Проверяем аргументы командной строки
if [ $# -gt 0 ]; then
    # Если переданы аргументы, выполняем их напрямую вместо запуска сервера
    log "Выполняем переданную команду: $*"
    exec "$@"
else
    # Если аргументов нет, запускаем сервер
    main "$@"
fi
