#!/bin/bash
# AmneziaWG Docker Server v2.0.0 - Quick Start Script
# Автоматическая инициализация и запуск VPN сервера с веб-интерфейсом

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Логотип
print_logo() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║         AmneziaWG Docker Server v2.0.0 QuickStart           ║"
    echo "║              VPN Server + Web Interface                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Проверка зависимостей
check_dependencies() {
    echo -e "${BLUE}🔍 Проверка зависимостей...${NC}"
    
    local missing_deps=()
    
    if ! command -v docker &> /dev/null; then
        missing_deps+=("docker")
    fi
    
    if ! command -v docker compose &> /dev/null; then
        if ! command -v docker-compose &> /dev/null; then
            missing_deps+=("docker-compose")
        fi
    fi
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo -e "${RED}❌ Отсутствуют зависимости: ${missing_deps[*]}${NC}"
        echo -e "${YELLOW}Установите их и попробуйте снова.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Все зависимости установлены${NC}"
}

# Инициализация git submodules
init_submodules() {
    echo -e "${BLUE}📦 Инициализация git submodules...${NC}"
    
    if [ ! -d "amneziawg-go/.git" ] || [ ! -d "amneziawg-tools/.git" ]; then
        git submodule update --init --recursive
        echo -e "${GREEN}✅ Submodules инициализированы${NC}"
    else
        echo -e "${CYAN}ℹ️  Submodules уже инициализированы${NC}"
    fi
}

# Создание .env файла
create_env() {
    if [ -f ".env" ]; then
        echo -e "${YELLOW}⚠️  Файл .env уже существует${NC}"
        read -p "Перезаписать? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${CYAN}ℹ️  Используем существующий .env${NC}"
            return
        fi
    fi
    
    echo -e "${BLUE}📝 Создание конфигурации...${NC}"
    cp env.example .env
    
    # Генерация случайных паролей
    echo -e "${CYAN}🔐 Генерация безопасных паролей...${NC}"
    
    # PostgreSQL пароль
    PG_PASSWORD=$(openssl rand -base64 32)
    sed -i "s/change_this_password_to_secure_one/${PG_PASSWORD}/" .env
    
    # API Secret (опционально)
    read -p "Установить API_SECRET для защиты API? (Рекомендуется) (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        API_SECRET=$(openssl rand -base64 32)
        sed -i "s/^API_SECRET=$/API_SECRET=${API_SECRET}/" .env
        echo -e "${GREEN}✅ API_SECRET установлен (Production режим)${NC}"
        echo -e "${YELLOW}💾 Сохраните этот секрет: ${API_SECRET}${NC}"
    else
        echo -e "${YELLOW}⚠️  API_SECRET не установлен (DEMO режим - небезопасно для production!)${NC}"
    fi
    
    echo -e "${GREEN}✅ Конфигурация создана: .env${NC}"
}

# Определение публичного IP
detect_public_ip() {
    echo -e "${BLUE}🌐 Определение публичного IP адреса...${NC}"
    
    PUBLIC_IP=$(curl -s -4 https://eth0.me || curl -s -4 https://ipv4.icanhazip.com || echo "auto")
    
    if [ "$PUBLIC_IP" = "auto" ] || [ -z "$PUBLIC_IP" ]; then
        echo -e "${YELLOW}⚠️  Не удалось определить публичный IP${NC}"
        read -p "Введите ваш публичный IP вручную (или оставьте пустым для auto): " MANUAL_IP
        if [ -n "$MANUAL_IP" ]; then
            PUBLIC_IP="$MANUAL_IP"
        else
            PUBLIC_IP="auto"
        fi
    fi
    
    sed -i "s/^SERVER_PUBLIC_IP=.*/SERVER_PUBLIC_IP=${PUBLIC_IP}/" .env
    echo -e "${GREEN}✅ Публичный IP: ${PUBLIC_IP}${NC}"
}

# Сборка образов
build_images() {
    echo -e "${BLUE}🔨 Сборка Docker образов...${NC}"
    docker compose build
    echo -e "${GREEN}✅ Образы собраны${NC}"
}

# Запуск сервисов
start_services() {
    echo -e "${BLUE}🚀 Запуск сервисов...${NC}"
    docker compose up -d
    echo -e "${GREEN}✅ Сервисы запущены${NC}"
}

# Ожидание готовности сервисов
wait_for_services() {
    echo -e "${BLUE}⏳ Ожидание готовности сервисов...${NC}"
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if docker compose ps | grep -q "healthy"; then
            echo -e "${GREEN}✅ Сервисы готовы${NC}"
            return 0
        fi
        echo -ne "${CYAN}⏳ Попытка ${attempt}/${max_attempts}...\r${NC}"
        sleep 2
        ((attempt++))
    done
    
    echo -e "${YELLOW}⚠️  Превышено время ожидания. Проверьте логи: docker compose logs${NC}"
}

# Вывод информации о доступе
print_access_info() {
    echo ""
    echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║                  Сервер успешно запущен!                     ║${NC}"
    echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Получаем значения из .env
    source .env
    
    SERVER_IP=$(curl -s -4 https://eth0.me || echo "your-server-ip")
    WEB_PORT=${WEB_PORT:-8080}
    VPN_PORT=${AWG_PORT:-51820}
    
    echo -e "${CYAN}📱 Веб-интерфейс управления:${NC}"
    echo -e "   ${GREEN}http://${SERVER_IP}:${WEB_PORT}${NC}"
    echo ""
    
    echo -e "${CYAN}🔌 VPN Server (UDP):${NC}"
    echo -e "   ${GREEN}${SERVER_IP}:${VPN_PORT}${NC}"
    echo ""
    
    if [ -n "$API_SECRET" ]; then
        echo -e "${CYAN}🔐 API Authorization (Production режим):${NC}"
        echo -e "   ${YELLOW}API_SECRET установлен${NC}"
        echo -e "   Используйте: ${GREEN}Authorization: Bearer YOUR_API_SECRET${NC}"
        echo ""
    else
        echo -e "${YELLOW}⚠️  API работает в DEMO режиме (без авторизации)${NC}"
        echo -e "   ${RED}НЕ БЕЗОПАСНО для публичного доступа!${NC}"
        echo -e "   Установите API_SECRET в .env для production${NC}"
        echo ""
    fi
    
    echo -e "${CYAN}📚 Полезные команды:${NC}"
    echo -e "   ${GREEN}make status${NC}              - Статус сервера"
    echo -e "   ${GREEN}make client-add name=john${NC} - Добавить VPN клиента"
    echo -e "   ${GREEN}make client-qr name=john${NC}  - Показать QR код"
    echo -e "   ${GREEN}make logs${NC}                 - Просмотр логов"
    echo -e "   ${GREEN}make help${NC}                 - Все доступные команды"
    echo ""
    
    echo -e "${CYAN}📖 Документация:${NC}"
    echo -e "   ${GREEN}README.md${NC}      - Основная документация"
    echo -e "   ${GREEN}SECURITY.md${NC}    - Руководство по безопасности"
    echo -e "   ${GREEN}MIGRATION.md${NC}   - Инструкции по миграции"
    echo ""
    
    echo -e "${YELLOW}💡 Следующий шаг: Добавьте первого VPN клиента${NC}"
    echo -e "   ${GREEN}make client-add name=john${NC}"
    echo ""
}

# Главная функция
main() {
    print_logo
    
    check_dependencies
    init_submodules
    create_env
    detect_public_ip
    build_images
    start_services
    wait_for_services
    print_access_info
    
    echo -e "${GREEN}✅ Установка завершена!${NC}"
}

# Запуск скрипта
main
