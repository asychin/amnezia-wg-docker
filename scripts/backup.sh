#!/bin/sh
# AmneziaWG Docker Server — Скрипт автоматического бэкапа
# Запускается как sidecar-контейнер в docker-compose

set -e

BACKUP_DIR="/backups"
DATA_DIR="/data"
BACKUP_INTERVAL="${BACKUP_INTERVAL:-24h}"
BACKUP_KEEP="${BACKUP_KEEP:-10}"

log() {
    echo "[BACKUP $(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo "[BACKUP ERROR $(date '+%Y-%m-%d %H:%M:%S')] $1" >&2
}

# Создание бэкапа
create_backup() {
    local backup_file="${BACKUP_DIR}/amneziawg-$(date +%Y%m%d-%H%M%S).tar.gz"

    log "Создаём бэкап: ${backup_file}"

    # Проверяем наличие данных
    if [ ! -d "${DATA_DIR}/config" ] && [ ! -d "${DATA_DIR}/clients" ]; then
        log "Нет данных для бэкапа, пропускаем"
        return 0
    fi

    # Создаём архив
    if tar -czf "${backup_file}" -C "${DATA_DIR}" config clients 2>/dev/null; then
        # Верифицируем архив
        if tar -tzf "${backup_file}" >/dev/null 2>&1; then
            local size
            size=$(du -h "${backup_file}" | cut -f1)
            log "Бэкап создан успешно: ${backup_file} (${size})"
        else
            error "Архив повреждён, удаляем: ${backup_file}"
            rm -f "${backup_file}"
            return 1
        fi
    else
        error "Не удалось создать бэкап"
        rm -f "${backup_file}"
        return 1
    fi

    # Ротация: удаляем старые бэкапы сверх лимита
    cleanup_old_backups
}

# Ротация старых бэкапов
cleanup_old_backups() {
    local count
    count=$(ls -1 "${BACKUP_DIR}"/amneziawg-*.tar.gz 2>/dev/null | wc -l)

    if [ "$count" -gt "$BACKUP_KEEP" ]; then
        local to_remove=$((count - BACKUP_KEEP))
        log "Удаляем ${to_remove} старых бэкапов (лимит: ${BACKUP_KEEP})"
        ls -t "${BACKUP_DIR}"/amneziawg-*.tar.gz | tail -n +"$((BACKUP_KEEP + 1))" | xargs rm -f
    fi
}

# Основной цикл
main() {
    mkdir -p "${BACKUP_DIR}"

    log "Сервис бэкапов запущен"
    log "  Интервал: ${BACKUP_INTERVAL}"
    log "  Хранить: ${BACKUP_KEEP} бэкапов"

    while true; do
        sleep "${BACKUP_INTERVAL}"
        create_backup || error "Цикл бэкапа завершился с ошибкой"
    done
}

main "$@"
