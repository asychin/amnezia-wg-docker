#!/bin/bash

# AmneziaWG Docker Server - Build Script
# Автоматическая сборка с метаданными

set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

log() { echo -e "${GREEN}[BUILD]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo -e "${PURPLE}"
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                 AmneziaWG Docker Builder                    ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

# Проверка зависимостей
log "Проверка зависимостей..."

if ! command -v docker &> /dev/null; then
    error "Docker не установлен"
    exit 1
fi

if ! command -v git &> /dev/null; then
    error "Git не установлен"
    exit 1
fi

# Проверка сабмодулей
log "Проверка сабмодулей..."
if [ ! -d "amneziawg-go/.git" ] || [ ! -d "amneziawg-tools/.git" ]; then
    warn "Сабмодули не инициализированы. Инициализация..."
    git submodule update --init --recursive
fi

# Получение метаданных для сборки
log "Получение метаданных сборки..."

# Дата сборки
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Git информация
if git rev-parse --git-dir > /dev/null 2>&1; then
    VCS_REF=$(git rev-parse --short HEAD)
    VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "latest")
    
    # Проверка на изменения
    if ! git diff-index --quiet HEAD --; then
        VCS_REF="${VCS_REF}-dirty"
        warn "Есть незафиксированные изменения в git"
    fi
else
    VCS_REF="unknown"
    VERSION="latest"
    warn "Не git репозиторий - используем значения по умолчанию"
fi

# Имя образа
IMAGE_NAME=${1:-"amneziawg-server"}
IMAGE_TAG=${2:-$VERSION}
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

log "Сборка образа $FULL_IMAGE_NAME..."
log "Дата сборки: $BUILD_DATE"
log "Git ревизия: $VCS_REF"
log "Версия: $VERSION"

# Аргументы сборки
BUILD_ARGS=(
    --build-arg "BUILD_DATE=$BUILD_DATE"
    --build-arg "VCS_REF=$VCS_REF"
    --build-arg "VERSION=$VERSION"
    --tag "$FULL_IMAGE_NAME"
    --tag "${IMAGE_NAME}:latest"
)

# Опции сборки
if [[ "${NO_CACHE:-false}" == "true" ]]; then
    BUILD_ARGS+=(--no-cache)
    log "Сборка без кеша"
fi

if [[ "${VERBOSE:-false}" == "true" ]]; then
    BUILD_ARGS+=(--progress=plain)
    log "Подробный вывод включен"
fi

# Сборка
log "Запуск Docker сборки..."
docker build "${BUILD_ARGS[@]}" .

# Проверка успешности сборки
if [ $? -eq 0 ]; then
    echo ""
    log "✅ Сборка завершена успешно!"
    echo ""
    echo -e "${BLUE}📋 Информация об образе:${NC}"
    docker images "$IMAGE_NAME" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
    echo ""
    echo -e "${BLUE}🏷️  Теги:${NC}"
    echo "  • $FULL_IMAGE_NAME"
    echo "  • ${IMAGE_NAME}:latest"
    echo ""
    echo -e "${BLUE}🚀 Запуск:${NC}"
    echo "  docker run -d --privileged --cap-add NET_ADMIN \\"
    echo "    -p 51820:51820/udp \\"
    echo "    -v amneziawg-config:/app/config \\"
    echo "    -v amneziawg-clients:/app/clients \\"
    echo "    $FULL_IMAGE_NAME"
    echo ""
    echo -e "${BLUE}🔍 Тестирование:${NC}"
    echo "  docker run --rm $FULL_IMAGE_NAME /app/scripts/healthcheck.sh"
    echo ""
else
    error "❌ Сборка завершилась с ошибкой"
    exit 1
fi

