#!/bin/bash

# AmneziaWG Docker Server - Скрипт быстрого старта
# Для пользователей которые хотят быстро развернуть сервер

set -e

# Цвета
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${PURPLE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                  AmneziaWG Quick Start                      ║
║                 Быстрое развертывание                       ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

# Проверка git
if ! command -v git &> /dev/null; then
    error "Git не установлен. Установите git и попробуйте снова."
    exit 1
fi

# Получение URL репозитория
REPO_URL=${1:-}
if [[ -z "$REPO_URL" ]]; then
    echo -e "${BLUE}Введите URL вашего git репозитория с AmneziaWG Docker:${NC}"
    read -p "URL: " REPO_URL
fi

if [[ -z "$REPO_URL" ]]; then
    error "URL репозитория не указан"
    exit 1
fi

# Определение имени директории
REPO_NAME=$(basename "$REPO_URL" .git)
TARGET_DIR=${2:-$REPO_NAME}

log "Клонирование репозитория..."
if [[ -d "$TARGET_DIR" ]]; then
    warn "Директория $TARGET_DIR уже существует"
    read -p "Удалить и пересоздать? [y/N]: " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        rm -rf "$TARGET_DIR"
    else
        error "Операция отменена"
        exit 1
    fi
fi

# Клонирование с сабмодулями
git clone --recursive "$REPO_URL" "$TARGET_DIR"
cd "$TARGET_DIR"

log "Переход в директорию $TARGET_DIR"

# Проверка структуры проекта
if [[ ! -f "Makefile" ]] || [[ ! -f "docker-compose.yml" ]]; then
    error "Это не похоже на корректный AmneziaWG Docker проект"
    exit 1
fi

log "Проект клонирован успешно!"

echo -e "\n${BLUE}🚀 Следующие шаги:${NC}"
echo "1. Перейдите в директорию: cd $TARGET_DIR"
echo "2. Запустите автоустановку: sudo ./install.sh"
echo ""
echo "Или выполните ручную настройку:"
echo "3. Настройте конфигурацию: cp env.example .env && nano .env"
echo "4. Соберите проект: make build"
echo "5. Запустите сервер: make up"
echo "6. Получите QR код: make client-qr name=client1"
echo ""

echo -e "${GREEN}✅ Готово! Проект развернут в директории $TARGET_DIR${NC}"
