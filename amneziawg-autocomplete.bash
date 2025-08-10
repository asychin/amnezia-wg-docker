#!/bin/bash

# AmneziaWG Docker Server - Bash Autocomplete
# Автокомплит для make команд проекта AmneziaWG
#
# Установка:
#   source amneziawg-autocomplete.bash
# Или добавьте в ~/.bashrc:
#   source /path/to/amneziawg-autocomplete.bash

# =============================================================================
# MAKEFILE АВТОКОМПЛИТ
# =============================================================================

_amneziawg_make() {
    local cur prev opts makefile_targets client_names ips
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Получение списка целей из Makefile
    if [[ -f "Makefile" ]]; then
        makefile_targets=$(grep -E '^[a-zA-Z_-]+:.*?##.*$$' Makefile 2>/dev/null | \
                          awk -F: '{print $1}' | sort)
    else
        # Fallback список основных команд
        makefile_targets="help install init build up down restart logs status 
                         client-add client-rm client-qr client-config client-list client-info
                         shell clean update backup restore test debug monitor"
    fi

    # Получение списка клиентов
    _get_client_names() {
        if [[ -d "clients" ]]; then
            ls clients/*.conf 2>/dev/null | sed 's|clients/||g; s|\.conf||g'
        elif command -v docker &>/dev/null && docker ps --format "{{.Names}}" | grep -q "amneziawg-server"; then
            docker exec amneziawg-server ls /app/clients/*.conf 2>/dev/null | \
                sed 's|/app/clients/||g; s|\.conf||g' 2>/dev/null || echo ""
        fi
    }

    # Получение следующего доступного IP
    _get_next_ip() {
        local base_ip="10.13.13"
        local used_ips=""
        
        if [[ -d "clients" ]]; then
            used_ips=$(grep -h "Address" clients/*.conf 2>/dev/null | \
                      awk '{print $3}' | cut -d'/' -f1 | cut -d'.' -f4)
        fi
        
        for i in {2..254}; do
            if ! echo "$used_ips" | grep -q "^$i$"; then
                echo "${base_ip}.$i"
                break
            fi
        done
    }

    # Обработка параметров команд клиентов
    case "$prev" in
        name=*)
            # Автокомплит после name= - список существующих клиентов
            client_names=$(_get_client_names)
            COMPREPLY=($(compgen -W "$client_names" -- "${cur}"))
            return 0
            ;;
        ip=*)
            # Автокомплит после ip= - предложение следующего IP
            COMPREPLY=($(compgen -W "$(_get_next_ip)" -- "${cur}"))
            return 0
            ;;
        file=*)
            # Автокомплит после file= - список файлов архивов
            COMPREPLY=($(compgen -f -X "!*.tar.gz" -- "${cur}"))
            return 0
            ;;
    esac

    # Обработка команд клиентов с параметрами
    case "$prev" in
        client-add)
            if [[ $cur == name=* ]]; then
                COMPREPLY=($(compgen -W "name=" -- "$cur"))
            elif [[ $cur == ip=* ]]; then
                COMPREPLY=($(compgen -W "ip=" -- "$cur"))
            else
                COMPREPLY=($(compgen -W "name= ip=" -- "$cur"))
            fi
            return 0
            ;;
        client-rm|client-qr|client-config)
            if [[ $cur == name=* ]]; then
                # Убираем префикс name= и дополняем имена клиентов
                local names_with_prefix=""
                for name in $(_get_client_names); do
                    names_with_prefix="$names_with_prefix name=$name"
                done
                COMPREPLY=($(compgen -W "$names_with_prefix" -- "$cur"))
            else
                COMPREPLY=($(compgen -W "name=" -- "$cur"))
            fi
            return 0
            ;;
        restore)
            if [[ $cur == file=* ]]; then
                local files_with_prefix=""
                for file in $(ls *.tar.gz 2>/dev/null); do
                    files_with_prefix="$files_with_prefix file=$file"
                done
                COMPREPLY=($(compgen -W "$files_with_prefix" -- "$cur"))
            else
                COMPREPLY=($(compgen -W "file=" -- "$cur"))
            fi
            return 0
            ;;
    esac

    # Основной автокомплит команд make
    COMPREPLY=($(compgen -W "$makefile_targets" -- "$cur"))
}

# =============================================================================
# MANAGE-CLIENTS.SH АВТОКОМПЛИТ
# =============================================================================

_amneziawg_manage_clients() {
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Основные команды manage-clients.sh
    local commands="add remove list show qr"

    case "$prev" in
        add)
            # После команды add нужны имя и IP
            if [[ ${#COMP_WORDS[@]} -eq 3 ]]; then
                # Первый аргумент - имя клиента
                COMPREPLY=($(compgen -W "client1 client2 client3 test-client mobile-device" -- "$cur"))
            elif [[ ${#COMP_WORDS[@]} -eq 4 ]]; then
                # Второй аргумент - IP адрес
                COMPREPLY=($(compgen -W "$(echo 10.13.13.{2..10})" -- "$cur"))
            fi
            return 0
            ;;
        remove|show|qr)
            # Для этих команд нужно имя существующего клиента
            local client_names=""
            if [[ -d "clients" ]]; then
                client_names=$(ls clients/*.conf 2>/dev/null | sed 's|clients/||g; s|\.conf||g')
            elif command -v docker &>/dev/null; then
                client_names=$(docker exec amneziawg-server ls /app/clients/*.conf 2>/dev/null | \
                              sed 's|/app/clients/||g; s|\.conf||g' 2>/dev/null || echo "")
            fi
            COMPREPLY=($(compgen -W "$client_names" -- "$cur"))
            return 0
            ;;
        */manage-clients.sh|manage-clients.sh)
            COMPREPLY=($(compgen -W "$commands" -- "$cur"))
            return 0
            ;;
    esac

    COMPREPLY=($(compgen -W "$commands" -- "$cur"))
}



# =============================================================================
# СКРИПТЫ ПРОЕКТА
# =============================================================================

_amneziawg_build_sh() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # build.sh может принимать имя образа и тег
    case "${#COMP_WORDS[@]}" in
        2)
            # Первый аргумент - имя образа
            COMPREPLY=($(compgen -W "amneziawg-server amneziawg-custom" -- "$cur"))
            ;;
        3)
            # Второй аргумент - тег
            COMPREPLY=($(compgen -W "latest v1.0 stable dev" -- "$cur"))
            ;;
    esac
}

_amneziawg_quick_start() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # quick-start.sh может принимать URL репозитория и имя директории
    case "${#COMP_WORDS[@]}" in
        2)
            # Первый аргумент - URL репозитория (предлагаем общие варианты)
            COMPREPLY=($(compgen -W "https://github.com/user/amneziawg-docker.git git@github.com:user/amneziawg-docker.git" -- "$cur"))
            ;;
        3)
            # Второй аргумент - имя директории
            COMPREPLY=($(compgen -W "amneziawg-docker docker-wg vpn-server" -- "$cur"))
            ;;
    esac
}

# =============================================================================
# РЕГИСТРАЦИЯ АВТОКОМПЛИТОВ
# =============================================================================

# Автокомплит для make команд
complete -F _amneziawg_make make

# Автокомплит для manage-clients.sh
complete -F _amneziawg_manage_clients scripts/manage-clients.sh
complete -F _amneziawg_manage_clients ./scripts/manage-clients.sh



# Автокомплит для скриптов проекта
complete -F _amneziawg_build_sh build.sh
complete -F _amneziawg_build_sh ./build.sh
complete -F _amneziawg_quick_start quick-start.sh
complete -F _amneziawg_quick_start ./quick-start.sh

# Автокомплит файлов конфигурации
complete -f -X "!*.conf" -o default cat less more nano vim vi

# =============================================================================
# ДОПОЛНИТЕЛЬНЫЕ УТИЛИТЫ
# =============================================================================

# Функция для быстрого добавления клиента с автокомплитом
awg_add_client() {
    local name="$1"
    local ip="$2"
    
    if [[ -z "$name" ]]; then
        echo "Использование: awg_add_client <имя> [IP]"
        echo "Доступные IP: $(echo 10.13.13.{2..10})"
        return 1
    fi
    
    if [[ -z "$ip" ]]; then
        # Автоматически найти следующий доступный IP
        local base_ip="10.13.13"
        local used_ips=""
        
        if [[ -d "clients" ]]; then
            used_ips=$(grep -h "Address" clients/*.conf 2>/dev/null | \
                      awk '{print $3}' | cut -d'/' -f1 | cut -d'.' -f4)
        fi
        
        for i in {2..254}; do
            if ! echo "$used_ips" | grep -q "^$i$"; then
                ip="${base_ip}.$i"
                break
            fi
        done
    fi
    
    echo "Добавляем клиента: $name с IP: $ip"
    make client-add name="$name" ip="$ip"
}

# Автокомплит для awg_add_client
_awg_add_client() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "${#COMP_WORDS[@]}" in
        2)
            COMPREPLY=($(compgen -W "client1 client2 mobile laptop desktop test" -- "$cur"))
            ;;
        3)
            COMPREPLY=($(compgen -W "$(echo 10.13.13.{2..10})" -- "$cur"))
            ;;
    esac
}

complete -F _awg_add_client awg_add_client

# Функция для быстрого просмотра статуса
awg_status() {
    echo "🔍 Статус AmneziaWG сервера:"
    make status --no-print-directory 2>/dev/null || echo "❌ Сервер недоступен"
}

# Функция для быстрого просмотра логов
awg_logs() {
    echo "📄 Последние логи AmneziaWG:"
    make logs --no-print-directory 2>/dev/null || echo "❌ Логи недоступны"
}

# Функция для быстрого отображения QR кода
awg_qr() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Использование: awg_qr <имя_клиента>"
        echo "Доступные клиенты:"
        make client-list --no-print-directory 2>/dev/null || echo "❌ Клиенты не найдены"
        return 1
    fi
    
    make client-qr name="$name" --no-print-directory
}

# Автокомплит для awg_qr
_awg_qr() {
    local cur client_names
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"

    if [[ -d "clients" ]]; then
        client_names=$(ls clients/*.conf 2>/dev/null | sed 's|clients/||g; s|\.conf||g')
    elif command -v docker &>/dev/null; then
        client_names=$(docker exec amneziawg-server ls /app/clients/*.conf 2>/dev/null | \
                      sed 's|/app/clients/||g; s|\.conf||g' 2>/dev/null || echo "")
    fi

    COMPREPLY=($(compgen -W "$client_names" -- "$cur"))
}

complete -F _awg_qr awg_qr

# =============================================================================
# СПРАВОЧНЫЕ ФУНКЦИИ
# =============================================================================

# Справка по автокомплиту
awg_help() {
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║             AmneziaWG Make Autocomplete Справка             ║
╚══════════════════════════════════════════════════════════════╝

🎯 КОМАНДЫ MAKE:
  make <TAB>                    - Показать все доступные команды
  make client-add name=<TAB>    - Автокомплит имен клиентов
  make client-add ip=<TAB>      - Автокомплит следующего IP
  make client-qr name=<TAB>     - Автокомплит существующих клиентов

🔧 СКРИПТЫ:
  ./build.sh <TAB>              - Автокомплит имени образа и тега
  ./scripts/manage-clients.sh <TAB> - Автокомплит команд управления
  ./quick-start.sh <TAB>        - Автокомплит URL репозитория

🚀 БЫСТРЫЕ КОМАНДЫ:
  awg_add_client <имя> [IP]     - Быстрое добавление клиента
  awg_status                    - Быстрый статус сервера
  awg_logs                      - Быстрый просмотр логов  
  awg_qr <имя>                  - Быстрое отображение QR кода

📝 УСТАНОВКА:
  source amneziawg-autocomplete.bash
  
  Или добавьте в ~/.bashrc:
  source /путь/к/amneziawg-autocomplete.bash

💡 ПРИМЕРЫ:
  make client-add name=john ip=10.13.13.5
  make client-qr name=john
  awg_add_client mobile
  awg_qr mobile

EOF
}

# Экспорт функций для использования в других скриптах
export -f awg_add_client awg_status awg_logs awg_qr awg_help

# Приветственное сообщение
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "🚀 AmneziaWG Make Autocomplete загружен!"
    echo "   Используйте 'awg_help' для справки"
    echo "   Попробуйте: make <TAB> или awg_add_client <TAB>"
fi
