#!/bin/bash

# AmneziaWG Docker Server - Скрипт быстрой установки
# Автоматическая установка и настройка AmneziaWG сервера

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функции для красивого вывода
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

title() {
    echo -e "\n${PURPLE}=== $1 ===${NC}\n"
}

# Проверка прав root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Этот скрипт должен быть запущен с правами root (sudo)"
        exit 1
    fi
}

# Проверка операционной системы
check_os() {
    title "Проверка операционной системы"
    
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
        log "Обнаружена ОС: $OS $VER"
    else
        error "Не удалось определить операционную систему"
        exit 1
    fi
    
    # Проверка поддерживаемых ОС
    case $OS in
        "Ubuntu"|"Debian GNU/Linux")
            log "ОС поддерживается"
            ;;
        *)
            warn "ОС может не поддерживаться. Продолжаем..."
            ;;
    esac
}

# Обновление системы
update_system() {
    title "Обновление системы"
    
    log "Обновляем список пакетов..."
    apt-get update -qq
    
    log "Устанавливаем базовые пакеты..."
    apt-get install -y curl wget git software-properties-common apt-transport-https ca-certificates gnupg lsb-release
}

# Установка Docker
install_docker() {
    title "Установка Docker"
    
    if command -v docker &> /dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d ' ' -f3 | cut -d ',' -f1)
        log "Docker уже установлен: $DOCKER_VERSION"
        return 0
    fi
    
    log "Устанавливаем Docker..."
    
    # Официальный способ установки Docker
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Альтернативная установка docker-compose если нет плагина
    if ! command -v docker-compose &> /dev/null; then
        log "Устанавливаем docker-compose..."
        apt-get install -y docker-compose
    fi
    
    # Запуск Docker
    systemctl enable docker
    systemctl start docker
    
    success "Docker установлен успешно"
    docker --version
    docker-compose --version || docker compose version
}

# Настройка DNS для Docker
configure_docker_dns() {
    title "Настройка Docker DNS"
    
    if [[ ! -f /etc/docker/daemon.json ]]; then
        log "Создаем конфигурацию Docker DNS..."
        mkdir -p /etc/docker
        cat > /etc/docker/daemon.json << EOF
{
    "dns": ["8.8.8.8", "8.8.4.4"]
}
EOF
        systemctl restart docker
        success "DNS для Docker настроен"
    else
        log "Docker DNS уже настроен"
    fi
}

# Настройка файрвола
configure_firewall() {
    title "Настройка файрвола"
    
    # Получаем порт из переменных или используем по умолчанию
    VPN_PORT=${AWG_PORT:-51820}
    
    if command -v ufw &> /dev/null; then
        log "Настраиваем UFW файрвол..."
        ufw --force enable
        ufw allow ssh
        ufw allow ${VPN_PORT}/udp
        ufw reload
        success "UFW настроен для порта ${VPN_PORT}/udp"
    elif command -v firewall-cmd &> /dev/null; then
        log "Настраиваем firewalld..."
        firewall-cmd --permanent --add-port=${VPN_PORT}/udp
        firewall-cmd --reload
        success "Firewalld настроен для порта ${VPN_PORT}/udp"
    else
        warn "Файрвол не обнаружен. Убедитесь что порт ${VPN_PORT}/udp открыт"
    fi
}

# Включение IP forwarding
enable_ip_forwarding() {
    title "Включение IP forwarding"
    
    if grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        log "IP forwarding уже включен"
    else
        log "Включаем IP forwarding..."
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
        sysctl -p
        success "IP forwarding включен"
    fi
}

# Создание конфигурации
create_config() {
    title "Создание конфигурации"
    
    if [[ -f .env ]]; then
        log "Файл .env уже существует"
        return 0
    fi
    
    log "Создаем файл конфигурации .env..."
    
    # Определяем публичный IP
    PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || curl -s ipecho.net/plain)
    
    if [[ -z "$PUBLIC_IP" ]]; then
        warn "Не удалось автоматически определить публичный IP"
        read -p "Введите публичный IP адрес сервера: " PUBLIC_IP
    else
        log "Обнаружен публичный IP: $PUBLIC_IP"
    fi
    
    # Копируем пример конфигурации
    cp env.example .env
    
    # Устанавливаем публичный IP если он определен
    if [[ -n "$PUBLIC_IP" ]]; then
        echo "SERVER_PUBLIC_IP=$PUBLIC_IP" >> .env
    fi
    
    success "Конфигурация создана в файле .env"
    warn "Проверьте и отредактируйте настройки в файле .env при необходимости"
}

# Сборка и запуск
build_and_start() {
    title "Сборка и запуск AmneziaWG"
    
    log "Обновляем сабмодули..."
    git submodule update --init --recursive
    
    log "Собираем Docker образ..."
    make build
    
    log "Запускаем сервер..."
    make up
    
    sleep 10
    
    log "Проверяем статус..."
    make status
}

# Показ информации для подключения
show_connection_info() {
    title "Информация для подключения"
    
    echo -e "${CYAN}📱 Для подключения мобильных устройств:${NC}"
    echo "1. Установите приложение AmneziaVPN"
    echo "2. Получите QR код командой: make client-qr name=client1"
    echo "3. Отсканируйте QR код в приложении"
    echo ""
    
    echo -e "${CYAN}🖥️  Для подключения компьютера:${NC}"
    echo "1. Скачайте конфигурацию: make client-config name=client1"
    echo "2. Используйте с совместимым AmneziaWG клиентом"
    echo ""
    
    echo -e "${CYAN}⚙️  Управление:${NC}"
    echo "• Статус сервера: make status"
    echo "• Логи: make logs"
    echo "• Добавить клиента: make client-add name=newclient ip=10.13.13.5"
    echo "• Список команд: make help"
    echo ""
    
    echo -e "${CYAN}🔥 Порт для файрвола: ${AWG_PORT:-51820}/udp${NC}"
}

# Основная функция
main() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    AmneziaWG Docker Server                   ║"
    echo "║                     Автоматическая установка                 ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    check_root
    check_os
    update_system
    install_docker
    configure_docker_dns
    enable_ip_forwarding
    create_config
    configure_firewall
    build_and_start
    show_connection_info
    
    echo ""
    success "🎉 Установка завершена успешно!"
    echo -e "${GREEN}AmneziaWG сервер запущен и готов к подключениям${NC}"
    echo ""
    echo -e "${YELLOW}💡 Первый клиент уже создан. Получите QR код:${NC}"
    echo -e "${CYAN}make client-qr name=client1${NC}"
    echo ""
}

# Обработка опций командной строки
case "${1:-}" in
    --help|-h)
        echo "Использование: $0 [опции]"
        echo "Опции:"
        echo "  --help, -h     Показать эту справку"
        echo "  --no-firewall  Пропустить настройку файрвола"
        echo "  --port PORT    Использовать указанный порт (по умолчанию 51820)"
        exit 0
        ;;
    --no-firewall)
        CONFIGURE_FIREWALL=false
        ;;
    --port)
        if [[ -n "${2:-}" ]]; then
            AWG_PORT="$2"
            shift
        else
            error "Не указан порт для опции --port"
            exit 1
        fi
        ;;
esac

# Запуск основной функции
main "$@"

