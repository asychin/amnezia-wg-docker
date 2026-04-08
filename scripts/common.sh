#!/bin/bash
# AmneziaWG Docker Server — Общая библиотека
# Shared functions for all scripts
# Docker-реализация: asychin (https://github.com/asychin)

# Защита от повторного подключения
[[ -n "$_COMMON_SH_LOADED" ]] && return 0
_COMMON_SH_LOADED=1

# ============================================================================
# ЦВЕТА ДЛЯ ЛОГОВ
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# ФУНКЦИИ ЛОГИРОВАНИЯ
# ============================================================================

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1" >&2
}

info() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

debug() {
    if [ "${VERBOSE:-false}" = "true" ]; then
        echo -e "[DEBUG $(date '+%H:%M:%S')] $1"
    fi
}

section() {
    echo -e "\n${CYAN}=== $1 ===${NC}"
}

# ============================================================================
# ВАЛИДАЦИЯ
# ============================================================================

# Валидация имени клиента (защита от инъекций и path traversal)
validate_client_name() {
    local name="$1"

    if [ -z "$name" ]; then
        error "Имя клиента не может быть пустым"
        return 1
    fi

    if [ ${#name} -gt 63 ]; then
        error "Имя клиента слишком длинное (максимум 63 символа)"
        return 1
    fi

    if ! echo "$name" | grep -qE '^[A-Za-z0-9_-]+$'; then
        error "Недопустимые символы в имени клиента"
        error "Разрешены только: A-Z, a-z, 0-9, дефис (-), подчеркивание (_)"
        return 1
    fi

    if echo "$name" | grep -qE '\.\.|/'; then
        error "Обнаружена попытка path traversal атаки"
        return 1
    fi

    if [[ "$name" =~ ^- ]]; then
        error "Имя клиента не может начинаться с дефиса"
        return 1
    fi

    return 0
}

# Валидация IPv4 адреса
validate_ipv4() {
    local ip="$1"

    if [[ ! "$ip" =~ ^[0-9.]+$ ]]; then
        error "Недопустимый формат IP адреса: $ip"
        return 1
    fi

    if [[ ! "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        error "Недопустимый формат IPv4 адреса: $ip"
        return 1
    fi

    IFS='.' read -r -a octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if [ "$octet" -gt 255 ]; then
            error "Недопустимый IP адрес (октет > 255): $ip"
            return 1
        fi
    done

    return 0
}

# ============================================================================
# БЛОКИРОВКА ФАЙЛОВ (предотвращение race conditions)
# ============================================================================

acquire_lock() {
    local lockfile="/var/lock/amneziawg-manage.lock"
    local lock_fd=200

    mkdir -p /var/lock 2>/dev/null || true

    eval "exec $lock_fd>$lockfile"

    if ! flock -x -w 30 $lock_fd; then
        error "Не удалось получить блокировку (другая операция выполняется)"
        return 1
    fi

    return 0
}

release_lock() {
    local lock_fd=200
    flock -u $lock_fd 2>/dev/null || true
}

# ============================================================================
# ОПРЕДЕЛЕНИЕ ПУБЛИЧНОГО IP
# ============================================================================

# Определяет публичный IP сервера.
# Результат сохраняется в глобальную переменную SERVER_PUBLIC_IP.
# Аргументы:
#   $1 — "strict" (выход с ошибкой если IP не определён) или "lenient" (fallback на placeholder)
#   По умолчанию: "strict"
get_public_ip() {
    local mode="${1:-strict}"

    if [ "$SERVER_PUBLIC_IP" = "auto" ] || [ -z "$SERVER_PUBLIC_IP" ]; then
        # Исправляем DNS если нужно
        if ! nslookup google.com >/dev/null 2>&1; then
            log "Исправляем DNS настройки..."
            if [ -w /etc/resolv.conf ] || [ -w /etc ]; then
                echo "nameserver 8.8.8.8" > /etc/resolv.conf
                echo "nameserver 8.8.4.4" >> /etc/resolv.conf
            else
                warn "Нет прав для изменения /etc/resolv.conf, пропускаем..."
            fi
        fi

        log "Определяем публичный IP автоматически..."

        SERVER_PUBLIC_IP=""

        # ПРИОРИТЕТНЫЙ МЕТОД: Определение IP через маршрутизацию (самый надёжный)
        if command -v ip >/dev/null 2>&1; then
            log "Пробуем определить IP через маршрутизацию (ip route)..."
            local local_ip
            local_ip=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || true)

            if [ -n "$local_ip" ] && echo "$local_ip" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
                if ! echo "$local_ip" | grep -qE '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|127\.)'; then
                    SERVER_PUBLIC_IP="$local_ip"
                    log "✅ Публичный IP определён через маршрутизацию: $SERVER_PUBLIC_IP"
                else
                    log "IP из маршрутизации приватный ($local_ip), используем внешние сервисы..."
                fi
            fi
        fi

        # Если приоритетный метод не сработал, используем внешние сервисы
        if [ -z "$SERVER_PUBLIC_IP" ]; then
            local IP_SERVICES=(
                "http://eth0.me"
                "https://ipv4.icanhazip.com"
                "https://api.ipify.org"
                "https://checkip.amazonaws.com"
                "https://ipinfo.io/ip"
                "https://ifconfig.me/ip"
                "http://whatismyip.akamai.com"
                "http://i.pn"
            )

            local service response ip
            for service in "${IP_SERVICES[@]}"; do
                log "Пробуем сервис: $service"

                response=$(curl -4 -s --connect-timeout 10 --max-time 15 "$service" 2>/dev/null)

                if [[ "$service" == *"i.pn"* ]]; then
                    ip=$(echo "$response" | grep '"query"' | sed 's/.*"query"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
                else
                    ip=$(echo "$response" | tr -d '[:space:]')
                fi

                if echo "$ip" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
                    if echo "$ip" | awk -F. '$1>=1 && $1<=255 && $2>=0 && $2<=255 && $3>=0 && $3<=255 && $4>=0 && $4<=255' | grep -q "$ip"; then
                        SERVER_PUBLIC_IP="$ip"
                        log "✅ Публичный IP определён: $SERVER_PUBLIC_IP (через $service)"
                        break
                    fi
                fi

                log "❌ Сервис $service не ответил корректно: '$ip'"
                sleep 1
            done
        fi

        # Обработка неудачного определения
        if [ -z "$SERVER_PUBLIC_IP" ]; then
            if [ "$mode" = "strict" ]; then
                error "❌ КРИТИЧЕСКАЯ ОШИБКА: Не удалось определить публичный IP!"
                error "Пожалуйста, укажите IP вручную через переменную окружения:"
                error "  SERVER_PUBLIC_IP=ВАШ_ПУБЛИЧНЫЙ_IP"
                exit 1
            else
                warn "❌ Не удалось определить публичный IP автоматически!"
                warn "Используем fallback. ОБЯЗАТЕЛЬНО укажите правильный IP в .env:"
                warn "  SERVER_PUBLIC_IP=ВАШ_ПУБЛИЧНЫЙ_IP"
                SERVER_PUBLIC_IP="UNKNOWN_IP_PLEASE_SET_MANUALLY"
            fi
        fi
    else
        log "Используется заданный IP: $SERVER_PUBLIC_IP"
    fi

    log "Публичный IP: $SERVER_PUBLIC_IP"
}
