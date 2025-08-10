#!/bin/bash

# AmneziaWG Docker Server - Diagnostic Script
# Расширенная диагностика для отладки проблем

set -e

# Переменные окружения по умолчанию
AWG_INTERFACE=${AWG_INTERFACE:-awg0}
AWG_PORT=${AWG_PORT:-51820}

# Цвета для логов
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[ДИАГНОСТИКА]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[ПРЕДУПРЕЖДЕНИЕ]${NC} $1"
}

error() {
    echo -e "${RED}[ОШИБКА]${NC} $1"
}

info() {
    echo -e "${BLUE}[ИНФОРМАЦИЯ]${NC} $1"
}

section() {
    echo -e "\n${CYAN}=== $1 ===${NC}"
}

# Функция для выполнения команды с отловом ошибок
safe_exec() {
    local cmd="$1"
    local description="$2"
    
    info "Выполняем: $description"
    echo "$ $cmd"
    
    if eval "$cmd" 2>&1; then
        log "✅ $description - успешно"
    else
        error "❌ $description - ошибка"
    fi
    echo
}

section "ОБЩАЯ ИНФОРМАЦИЯ О СИСТЕМЕ"
safe_exec "uname -a" "Информация о системе"
safe_exec "date" "Текущее время"
safe_exec "uptime" "Время работы системы"

section "ИНФОРМАЦИЯ О КОНТЕЙНЕРЕ"
safe_exec "whoami" "Текущий пользователь"
safe_exec "id" "ID пользователя и группы"
safe_exec "ps aux" "Список процессов"

section "ПЕРЕМЕННЫЕ ОКРУЖЕНИЯ AMNEZIAWG"
info "AWG_INTERFACE=$AWG_INTERFACE"
info "AWG_PORT=$AWG_PORT"
info "AWG_NET=${AWG_NET:-не установлено}"
info "AWG_SERVER_IP=${AWG_SERVER_IP:-не установлено}"
info "SERVER_PUBLIC_IP=${SERVER_PUBLIC_IP:-не установлено}"

section "ПРОВЕРКА ФАЙЛОВ И ДИРЕКТОРИЙ"
safe_exec "ls -la /app/" "Содержимое /app/"
safe_exec "ls -la /app/config/" "Содержимое /app/config/"
safe_exec "ls -la /app/clients/" "Содержимое /app/clients/"
safe_exec "ls -la /var/run/" "Содержимое /var/run/"

section "ПРОВЕРКА БИНАРНЫХ ФАЙЛОВ"
safe_exec "which amneziawg-go" "Путь к amneziawg-go"
safe_exec "amneziawg-go --version" "Версия amneziawg-go"
safe_exec "which awg" "Путь к awg"
safe_exec "awg --version" "Версия awg"

section "ПРОВЕРКА ПРОЦЕССОВ AMNEZIAWG"
if [ -f /var/run/amneziawg.pid ]; then
    PID=$(cat /var/run/amneziawg.pid 2>/dev/null)
    if [ -n "$PID" ]; then
        info "PID из файла: $PID"
        safe_exec "kill -0 $PID" "Проверка существования процесса"
        safe_exec "ps -p $PID -f" "Детали процесса"
    else
        error "PID файл пуст"
    fi
else
    error "PID файл не найден"
fi

safe_exec "ps aux | grep amneziawg" "Поиск процессов amneziawg"
safe_exec "ps aux | grep awg" "Поиск процессов awg"

section "СЕТЕВЫЕ ИНТЕРФЕЙСЫ"
safe_exec "ip link show" "Все сетевые интерфейсы"
safe_exec "ip addr show" "IP адреса на интерфейсах"
safe_exec "ip route show" "Таблица маршрутизации"

if ip link show "$AWG_INTERFACE" >/dev/null 2>&1; then
    safe_exec "ip link show $AWG_INTERFACE" "Детали интерфейса $AWG_INTERFACE"
    safe_exec "ip addr show $AWG_INTERFACE" "IP адреса на $AWG_INTERFACE"
else
    warn "Интерфейс $AWG_INTERFACE не найден"
fi

section "ПРОВЕРКА ПОРТОВ"
safe_exec "netstat -ulnp" "Прослушиваемые UDP порты"
safe_exec "ss -ulnp" "Прослушиваемые UDP порты (ss)"
safe_exec "lsof -i UDP" "Открытые UDP сокеты"

section "КОНФИГУРАЦИЯ AMNEZIAWG"
if [ -f "/app/config/${AWG_INTERFACE}.conf" ]; then
    safe_exec "cat /app/config/${AWG_INTERFACE}.conf" "Конфигурация сервера"
else
    warn "Конфигурационный файл /app/config/${AWG_INTERFACE}.conf не найден"
fi

safe_exec "awg show" "Все интерфейсы AmneziaWG"
if ip link show "$AWG_INTERFACE" >/dev/null 2>&1; then
    safe_exec "awg show $AWG_INTERFACE" "Статус интерфейса $AWG_INTERFACE"
else
    warn "Интерфейс $AWG_INTERFACE недоступен для awg show"
fi

section "IPTABLES ПРАВИЛА"
safe_exec "iptables -t nat -L -n -v" "NAT правила"
safe_exec "iptables -t filter -L FORWARD -n -v" "FORWARD правила"

section "DNS И СЕТЕВАЯ СВЯЗНОСТЬ"
safe_exec "cat /etc/resolv.conf" "DNS настройки"
safe_exec "nslookup google.com" "Тест DNS"
safe_exec "ping -c 3 8.8.8.8" "Тест связности с 8.8.8.8"

section "ЛОГИ СИСТЕМЫ"
safe_exec "dmesg | tail -20" "Последние сообщения ядра"
safe_exec "journalctl --no-pager -n 20" "Последние системные логи"

section "ПРОВЕРКА ХЕЛСЧЕКА"
safe_exec "/app/scripts/healthcheck.sh" "Выполнение хелсчека"

section "ДИАГНОСТИКА ЗАВЕРШЕНА"
log "Для дополнительной информации проверьте логи Docker:"
info "docker logs <container_name>"
info "docker exec <container_name> /app/scripts/diagnose.sh"

