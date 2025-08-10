#!/bin/bash

# AmneziaWG Docker Server - Health Check Script
# Проверка здоровья контейнера для Docker HEALTHCHECK

set -o pipefail

# Переменные окружения по умолчанию
AWG_INTERFACE=${AWG_INTERFACE:-awg0}
AWG_PORT=${AWG_PORT:-51820}
HEALTHCHECK_TIMEOUT=${HEALTHCHECK_TIMEOUT:-5}
VERBOSE=${HEALTHCHECK_VERBOSE:-false}

# Функция логирования
log() {
    echo "[HEALTHCHECK] $(date '+%H:%M:%S') $1"
}

debug() {
    if [ "$VERBOSE" = "true" ]; then
        echo "[HEALTHCHECK DEBUG] $(date '+%H:%M:%S') $1"
    fi
}

warn() {
    echo "[HEALTHCHECK WARN] $(date '+%H:%M:%S') $1"
}

error() {
    echo "[HEALTHCHECK ERROR] $(date '+%H:%M:%S') $1" >&2
}

# Код возврата
HEALTH_STATUS=0
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Функция для выполнения проверки с таймаутом
run_check() {
    local check_name="$1"
    local check_command="$2"
    local is_critical="${3:-true}"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    debug "Выполняем проверку: $check_name"
    
    if timeout "$HEALTHCHECK_TIMEOUT" bash -c "$check_command" >/dev/null 2>&1; then
        log "✅ $check_name"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        if [ "$is_critical" = "true" ]; then
            error "❌ $check_name (критическая ошибка)"
            HEALTH_STATUS=1
        else
            warn "⚠️  $check_name (предупреждение)"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        fi
        return 1
    fi
}

# ============================================================================
# ПРОВЕРКИ
# ============================================================================

log "Начинаем проверку здоровья AmneziaWG сервера..."

# 1. Проверка процесса amneziawg-go
debug "Проверка процесса amneziawg-go..."
if [ -f /var/run/amneziawg.pid ]; then
    PID=$(cat /var/run/amneziawg.pid 2>/dev/null)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        log "✅ Процесс amneziawg-go работает (PID: $PID)"
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        error "❌ Процесс amneziawg-go не отвечает (PID: $PID)"
        HEALTH_STATUS=1
        TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    fi
else
    error "❌ PID файл не найден"
    HEALTH_STATUS=1
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
fi

# 2. Проверка сетевого интерфейса
run_check "Интерфейс $AWG_INTERFACE существует" "ip link show $AWG_INTERFACE"
# Для userspace WireGuard интерфейсов состояние может быть UNKNOWN, проверяем флаги UP,LOWER_UP
run_check "Интерфейс $AWG_INTERFACE активен" "ip link show $AWG_INTERFACE | grep -q 'UP,LOWER_UP'"

# 3. Проверка порта (с несколькими методами)
if run_check "Порт $AWG_PORT прослушивается (netstat)" "netstat -ulnp 2>/dev/null | grep -q ':$AWG_PORT '" false; then
    debug "Порт проверен через netstat"
elif run_check "Порт $AWG_PORT прослушивается (ss)" "ss -ulnp 2>/dev/null | grep -q ':$AWG_PORT '" false; then
    debug "Порт проверен через ss"
elif run_check "Порт $AWG_PORT прослушивается (lsof)" "lsof -i UDP:$AWG_PORT 2>/dev/null" false; then
    debug "Порт проверен через lsof"
else
    error "❌ Порт $AWG_PORT не прослушивается (проверено всеми методами)"
    HEALTH_STATUS=1
fi

# 4. Проверка конфигурации AmneziaWG (с fallback)
if run_check "AmneziaWG конфигурация доступна" "awg show $AWG_INTERFACE" false; then
    debug "AWG интерфейс отвечает на команды"
elif [ -f "/app/config/${AWG_INTERFACE}.conf" ]; then
    log "✅ Конфигурационный файл AmneziaWG существует (fallback проверка)"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    error "❌ AmneziaWG конфигурация недоступна и файл конфигурации не найден"
    HEALTH_STATUS=1
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
fi

# 5. Проверка DNS (не критическая)
run_check "DNS работает (google.com)" "nslookup google.com" false

# 6. Проверка файловой системы
run_check "Директории конфигурации доступны" "[ -d /app/config ] && [ -d /app/clients ]"

# 7. Дополнительная проверка - IP адрес на интерфейсе
run_check "IP адрес назначен на $AWG_INTERFACE" "ip addr show $AWG_INTERFACE | grep -q 'inet '" false

# 8. Проверка iptables (не критическая)
run_check "iptables правила существуют" "iptables -t nat -L POSTROUTING | grep -q MASQUERADE" false

# ============================================================================
# РЕЗУЛЬТАТ
# ============================================================================

log "Проверок выполнено: $PASSED_CHECKS/$TOTAL_CHECKS"

if [ $HEALTH_STATUS -eq 0 ]; then
    log "✅ Все критические проверки пройдены успешно"
    debug "Сервис работает корректно"
    exit 0
else
    error "❌ Обнаружены критические проблемы в работе сервера"
    error "Проверьте логи контейнера для получения дополнительной информации"
    if [ "$VERBOSE" = "true" ]; then
        error "Для детальной диагностики используйте:"
        error "  docker exec <container> /app/scripts/healthcheck.sh"
        error "  docker logs <container>"
    fi
    exit 1
fi
