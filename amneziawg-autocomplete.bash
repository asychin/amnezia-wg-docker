#!/bin/bash

# AmneziaWG Docker Server - Bash Autocomplete
# Автокомплит для make команд проекта AmneziaWG
#
# Установка:
#   source amneziawg-autocomplete.bash
# Или добавьте в ~/.bashrc:
#   source /path/to/amneziawg-autocomplete.bash

# =============================================================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# =============================================================================

# Переменная для управления отладкой (установите в 1 для включения отладки)
AWG_DEBUG=${AWG_DEBUG:-0}

# Функция отладочного вывода
_debug_log() {
    [[ $AWG_DEBUG -eq 1 ]] && echo "DEBUG: $*" >&2
}

# Получение списка клиентов
_get_client_names() {
    local client_names=""
    
    # Сначала пробуем локальную директорию clients
    if [[ -d "clients" ]]; then
        client_names=$(ls clients/*.conf 2>/dev/null | sed 's|clients/||g; s|\.conf||g' | sort)
    fi
    
    # Если локально не найдены, пробуем через Docker
    if [[ -z "$client_names" ]] && command -v docker &>/dev/null; then
        if docker ps --format "{{.Names}}" 2>/dev/null | grep -q "amneziawg-server"; then
            client_names=$(docker exec amneziawg-server ls /app/clients/*.conf 2>/dev/null | \
                          sed 's|/app/clients/||g; s|\.conf||g' 2>/dev/null | sort || echo "")
        fi
    fi
    
    echo "$client_names"
}

# Получение следующего доступного IP
_get_next_ip() {
    local base_ip="10.13.13"
    local used_ips=""
    
    # Получаем используемые IP из локальных файлов
    if [[ -d "clients" ]]; then
        used_ips=$(grep -h "Address" clients/*.conf 2>/dev/null | \
                  awk '{print $3}' | cut -d'/' -f1 | cut -d'.' -f4 | sort -n)
    fi
    
    # Если локально не найдены, пробуем через Docker
    if [[ -z "$used_ips" ]] && command -v docker &>/dev/null; then
        if docker ps --format "{{.Names}}" 2>/dev/null | grep -q "amneziawg-server"; then
            used_ips=$(docker exec amneziawg-server grep -h "Address" /app/clients/*.conf 2>/dev/null | \
                      awk '{print $3}' | cut -d'/' -f1 | cut -d'.' -f4 | sort -n 2>/dev/null || echo "")
        fi
    fi
    
    # Находим первый свободный IP
    for i in {2..254}; do
        if ! echo "$used_ips" | grep -q "^$i$"; then
            echo "${base_ip}.$i"
            return
        fi
    done
    
    # Если все заняты, предложим 10.13.13.2
    echo "${base_ip}.2"
}

# Получение списка архивных файлов
_get_backup_files() {
    ls *.tar.gz 2>/dev/null | sort -r || echo ""
}

# =============================================================================
# MAKEFILE АВТОКОМПЛИТ
# =============================================================================

_amneziawg_make() {
    local cur prev opts makefile_targets client_names ips
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # ОТЛАДКА: установите AWG_DEBUG=1 для включения отладки
    _debug_log "cur='$cur' prev='$prev' words='${COMP_WORDS[*]}' cword=$COMP_CWORD"
    
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

    # =============================================================================
    # ОБРАБОТКА ПАРАМЕТРОВ СО ЗНАКОМ РАВЕНСТВА
    # =============================================================================
    
    # Обработка случаев когда cur начинается с параметра ИЛИ когда prev=parameter и cur="=" ИЛИ когда prev="=" и параметр перед ним name
    if [[ $cur == name=* ]] || [[ $prev == "name" && $cur == "=" ]] || [[ $prev == "=" && ${COMP_WORDS[COMP_CWORD-2]} == "name" ]]; then
        _debug_log "Обработка name, prev='$prev', cur='$cur'"
        
        # Определяем какая команда используется
        local last_make_command=""
        local i
        for (( i=1; i<${#COMP_WORDS[@]}; i++ )); do
            local word="${COMP_WORDS[i]}"
            if [[ $word != *=* ]] && echo "$makefile_targets" | grep -q "\\b$word\\b"; then
                last_make_command="$word"
            fi
        done
        _debug_log "Команда: $last_make_command"
        
        local param_value=""
        local suggestions=""
        
        # Определяем значение параметра
        if [[ $cur == name=* ]]; then
            param_value="${cur#name=}"
            _debug_log "Формат name=value, param_value='$param_value'"
        elif [[ $prev == "name" && $cur == "=" ]]; then
            param_value=""
            _debug_log "Формат name =, определяем что предлагать"
        elif [[ $prev == "=" && ${COMP_WORDS[COMP_CWORD-2]} == "name" ]]; then
            param_value="$cur"
            _debug_log "Формат name = value, param_value='$param_value'"
        fi
        
        # Логика зависит от команды
        if [[ $last_make_command == "client-add" ]]; then
            _debug_log "client-add: НЕ предлагаем имена - пользователь должен сам придумать!"
            # Для добавления клиента НЕ предлагаем никаких имен
            # Пользователь должен сам придумать уникальное имя
            suggestions=""
        else
            _debug_log "client-qr/rm/config: предлагаем СУЩЕСТВУЮЩИХ клиентов"
            # Для остальных команд предлагаем существующих клиентов
            local client_names="$(_get_client_names)"
            _debug_log "client_names='$client_names'"
            
            if [[ -z "$param_value" ]]; then
                for name in $client_names; do
                    if [[ $prev == "name" && $cur == "=" ]]; then
                        suggestions="$suggestions $name"
                    else
                        suggestions="$suggestions name=$name"
                    fi
                done
            else
                # Собираем все подходящие имена
                _debug_log "Ищем совпадения с '$param_value'"
                for name in $client_names; do
                    if [[ $name == $param_value* ]]; then
                        # Для случая name = частичное_имя возвращаем только имена без префикса
                        if [[ $prev == "=" && ${COMP_WORDS[COMP_CWORD-2]} == "name" ]]; then
                            suggestions="$suggestions $name"
                        else
                            suggestions="$suggestions name=$name"
                        fi
                        _debug_log "Найдено совпадение: $name"
                    fi
                done
                
                # Если нет точных совпадений, предложим все имена
                if [[ -z "$suggestions" ]]; then
                    _debug_log "Нет совпадений, предлагаем все имена"
                    for name in $client_names; do
                        if [[ $prev == "=" && ${COMP_WORDS[COMP_CWORD-2]} == "name" ]]; then
                            suggestions="$suggestions $name"
                        else
                            suggestions="$suggestions name=$name"
                        fi
                    done
                fi
            fi
        fi
        
        # Удаляем лишние пробелы и используем compgen без добавления пробела
        suggestions=$(echo "$suggestions" | xargs)
        _debug_log "suggestions='$suggestions'"
        
        # Если cur="=" или prev="=" (случай name = value), то не используем compgen для фильтрации
        if [[ $prev == "name" && $cur == "=" ]] || [[ $prev == "=" && ${COMP_WORDS[COMP_CWORD-2]} == "name" ]]; then
            COMPREPLY=($suggestions)  # Прямое присваивание без фильтрации
        else
            COMPREPLY=($(compgen -W "$suggestions" -- "$cur"))
        fi
        _debug_log "COMPREPLY='${COMPREPLY[*]}'"
        
        # Отключаем добавление пробела после завершения
        compopt -o nospace 2>/dev/null || true
        return 0
    fi
    
    if [[ $cur == ip=* ]] || [[ $prev == "ip" && $cur == "=" ]]; then
        _debug_log "Обработка ip, prev='$prev', cur='$cur'"
        local param_value=""
        local next_ip="$(_get_next_ip)"
        local suggestions=""
        
        # Определяем значение параметра
        if [[ $cur == ip=* ]]; then
            param_value="${cur#ip=}"
            _debug_log "Формат ip=value, param_value='$param_value'"
        elif [[ $prev == "ip" && $cur == "=" ]]; then
            param_value=""
            _debug_log "Формат ip =, предлагаем IP адреса"
        fi
        
        if [[ -z "$param_value" ]]; then
            if [[ $prev == "ip" && $cur == "=" ]]; then
                suggestions="$next_ip"  # Для случая ip = добавляем без префикса
                # Добавим несколько вариантов IP
                local base_ip="10.13.13"
                for i in {2..10}; do
                    suggestions="$suggestions ${base_ip}.$i"
                done
            else
                suggestions="ip=$next_ip"
                # Добавим несколько вариантов IP
                local base_ip="10.13.13"
                for i in {2..10}; do
                    suggestions="$suggestions ip=${base_ip}.$i"
                done
            fi
        else
            suggestions="ip=$next_ip"
            # Добавим несколько вариантов IP
            local base_ip="10.13.13"
            for i in {2..10}; do
                suggestions="$suggestions ip=${base_ip}.$i"
            done
        fi
        
        # Если cur="=", то не используем compgen для фильтрации
        if [[ $prev == "ip" && $cur == "=" ]]; then
            COMPREPLY=($suggestions)  # Прямое присваивание без фильтрации
        else
            COMPREPLY=($(compgen -W "$suggestions" -- "$cur"))
        fi
        _debug_log "IP suggestions='$suggestions', COMPREPLY='${COMPREPLY[*]}'"
        
        # Отключаем добавление пробела после завершения
        compopt -o nospace 2>/dev/null || true
        return 0
    fi
    
    if [[ $cur == file=* ]] || [[ $prev == "file" && $cur == "=" ]]; then
        _debug_log "Обработка file, prev='$prev', cur='$cur'"
        local param_value=""
        local backup_files="$(_get_backup_files)"
        local suggestions=""
        
        # Определяем значение параметра
        if [[ $cur == file=* ]]; then
            param_value="${cur#file=}"
            _debug_log "Формат file=value, param_value='$param_value'"
        elif [[ $prev == "file" && $cur == "=" ]]; then
            param_value=""
            _debug_log "Формат file =, предлагаем файлы"
        fi
        
        if [[ -z "$param_value" ]]; then
            for file in $backup_files; do
                if [[ $prev == "file" && $cur == "=" ]]; then
                    suggestions="$suggestions $file"  # Для случая file = добавляем без префикса
                else
                    suggestions="$suggestions file=$file"
                fi
            done
        else
            for file in $backup_files; do
                if [[ $file == $param_value* ]]; then
                    suggestions="$suggestions file=$file"
                fi
            done
            
            # Если нет точных совпадений, предложим все файлы
            if [[ -z "$suggestions" ]]; then
                for file in $backup_files; do
                    suggestions="$suggestions file=$file"
                done
            fi
        fi
        
        # Если cur="=", то не используем compgen для фильтрации
        if [[ $prev == "file" && $cur == "=" ]]; then
            COMPREPLY=($suggestions)  # Прямое присваивание без фильтрации
        else
            COMPREPLY=($(compgen -W "$suggestions" -- "$cur"))
        fi
        _debug_log "File suggestions='$suggestions', COMPREPLY='${COMPREPLY[*]}'"
        
        # Отключаем добавление пробела после завершения
        compopt -o nospace 2>/dev/null || true
        return 0
    fi

    # =============================================================================
    # ОБРАБОТКА КОМАНД И ИХ ПАРАМЕТРОВ
    # =============================================================================
    
    # Определяем последнюю команду make в строке
    local last_make_command=""
    local i
    for (( i=1; i<${#COMP_WORDS[@]}; i++ )); do
        local word="${COMP_WORDS[i]}"
        if [[ $word != *=* ]] && echo "$makefile_targets" | grep -q "\b$word\b"; then
            last_make_command="$word"
        fi
    done
    
    # Обработка команд клиентов
    case "$last_make_command" in
        client-add)
            # Для client-add предлагаем name= и ip=
            if [[ $cur == "" || $cur != *=* ]]; then
                COMPREPLY=($(compgen -W "name= ip=" -- "$cur"))
                compopt -o nospace 2>/dev/null || true
            fi
            return 0
            ;;
        client-rm|client-qr|client-config)
            # Для этих команд только name=
            if [[ $cur == "" || $cur != *=* ]]; then
                COMPREPLY=($(compgen -W "name=" -- "$cur"))
                compopt -o nospace 2>/dev/null || true
            fi
            return 0
            ;;
        restore)
            # Для restore только file=
            if [[ $cur == "" || $cur != *=* ]]; then
                COMPREPLY=($(compgen -W "file=" -- "$cur"))
                compopt -o nospace 2>/dev/null || true
            fi
            return 0
            ;;
    esac
    
    # Если предыдущее слово - команда make, предлагаем её параметры
    case "$prev" in
        client-add)
            COMPREPLY=($(compgen -W "name= ip=" -- "$cur"))
            compopt -o nospace 2>/dev/null || true
            return 0
            ;;
        client-rm|client-qr|client-config)
            COMPREPLY=($(compgen -W "name=" -- "$cur"))
            compopt -o nospace 2>/dev/null || true
            return 0
            ;;
        restore)
            COMPREPLY=($(compgen -W "file=" -- "$cur"))
            compopt -o nospace 2>/dev/null || true
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
                # Первый аргумент - имя клиента (предлагаем популярные имена)
                COMPREPLY=($(compgen -W "client1 client2 client3 mobile laptop desktop phone tablet work home test-client" -- "$cur"))
            elif [[ ${#COMP_WORDS[@]} -eq 4 ]]; then
                # Второй аргумент - IP адрес
                local suggested_ip="$(_get_next_ip)"
                local ip_suggestions="$suggested_ip"
                
                # Добавим несколько вариантов IP
                for i in {2..20}; do
                    ip_suggestions="$ip_suggestions 10.13.13.$i"
                done
                
                COMPREPLY=($(compgen -W "$ip_suggestions" -- "$cur"))
            fi
            return 0
            ;;
        remove|show|qr)
            # Для этих команд нужно имя существующего клиента
            local client_names="$(_get_client_names)"
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
            COMPREPLY=($(compgen -W "latest v1.0 stable dev test" -- "$cur"))
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
            COMPREPLY=($(compgen -W "https://github.com/user/amneziawg-docker.git git@github.com:user/amneziawg-docker.git ." -- "$cur"))
            ;;
        3)
            # Второй аргумент - имя директории
            COMPREPLY=($(compgen -W "amneziawg-docker docker-wg vpn-server amnezia-wg" -- "$cur"))
            ;;
    esac
}

# =============================================================================
# DOCKER COMPOSE АВТОКОМПЛИТ
# =============================================================================

_amneziawg_docker_compose() {
    local cur prev
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    local compose_commands="build up down restart logs ps exec pull push config version"
    local service_name="amneziawg-server"
    
    case "$prev" in
        compose)
            COMPREPLY=($(compgen -W "$compose_commands" -- "$cur"))
            return 0
            ;;
        exec)
            COMPREPLY=($(compgen -W "$service_name" -- "$cur"))
            return 0
            ;;
        logs)
            COMPREPLY=($(compgen -W "$service_name -f --tail" -- "$cur"))
            return 0
            ;;
    esac
    
    if [[ ${COMP_WORDS[1]} == "compose" ]]; then
        COMPREPLY=($(compgen -W "$compose_commands" -- "$cur"))
    fi
}

# =============================================================================
# РЕГИСТРАЦИЯ АВТОКОМПЛИТОВ
# =============================================================================

# Автокомплит для make команд
# Принудительно переопределяем системный автокомплит для make
complete -r make 2>/dev/null || true
complete -F _amneziawg_make make

# Автокомплит для manage-clients.sh
complete -F _amneziawg_manage_clients scripts/manage-clients.sh
complete -F _amneziawg_manage_clients ./scripts/manage-clients.sh
complete -F _amneziawg_manage_clients /root/docker-wg/scripts/manage-clients.sh

# Автокомплит для Docker Compose
complete -F _amneziawg_docker_compose docker

# Автокомплит для скриптов проекта
complete -F _amneziawg_build_sh build.sh
complete -F _amneziawg_build_sh ./build.sh
complete -F _amneziawg_quick_start quick-start.sh
complete -F _amneziawg_quick_start ./quick-start.sh

# Автокомплит файлов конфигурации
complete -f -X "!*.conf" -o default cat less more nano vim vi gedit
complete -f -X "!*.tar.gz" -o default tar

# =============================================================================
# ДОПОЛНИТЕЛЬНЫЕ УТИЛИТЫ
# =============================================================================

# Функция для быстрого добавления клиента с автокомплитом
awg_add_client() {
    local name="$1"
    local ip="$2"
    
    if [[ -z "$name" ]]; then
        echo "Использование: awg_add_client <имя> [IP]"
        echo "Примеры:"
        echo "  awg_add_client mobile"
        echo "  awg_add_client laptop 10.13.13.5"
        echo "Доступные IP: $(_get_next_ip) и далее..."
        return 1
    fi
    
    if [[ -z "$ip" ]]; then
        ip="$(_get_next_ip)"
    fi
    
    echo "🚀 Добавляем клиента: $name с IP: $ip"
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
            # Предлагаем популярные имена + существующие клиенты для ориентира
            local existing_clients="$(_get_client_names)"
            local suggested_names="mobile laptop desktop phone tablet work home office"
            COMPREPLY=($(compgen -W "$suggested_names $existing_clients" -- "$cur"))
            ;;
        3)
            # Предлагаем следующий доступный IP и еще несколько вариантов
            local suggested_ip="$(_get_next_ip)"
            local ip_suggestions="$suggested_ip"
            
            # Добавим еще несколько IP для выбора
            local base_ip="10.13.13"
            for i in {2..15}; do
                ip_suggestions="$ip_suggestions ${base_ip}.$i"
            done
            
            COMPREPLY=($(compgen -W "$ip_suggestions" -- "$cur"))
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
        local clients="$(_get_client_names)"
        if [[ -n "$clients" ]]; then
            echo "$clients" | tr ' ' '\n' | sort
        else
            echo "❌ Клиенты не найдены"
        fi
        return 1
    fi
    
    echo "📱 QR код для клиента '$name':"
    make client-qr name="$name" --no-print-directory
}

# Автокомплит для awg_qr
_awg_qr() {
    local cur client_names
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    
    client_names="$(_get_client_names)"
    COMPREPLY=($(compgen -W "$client_names" -- "$cur"))
}

complete -F _awg_qr awg_qr

# Функция для быстрого удаления клиента
awg_rm_client() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Использование: awg_rm_client <имя_клиента>"
        echo "Доступные клиенты:"
        local clients="$(_get_client_names)"
        if [[ -n "$clients" ]]; then
            echo "$clients" | tr ' ' '\n' | sort
        else
            echo "❌ Клиенты не найдены"
        fi
        return 1
    fi
    
    echo "🗑️ Удаляем клиента: $name"
    make client-rm name="$name"
}

# Автокомплит для awg_rm_client
_awg_rm_client() {
    local cur client_names
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    
    client_names="$(_get_client_names)"
    COMPREPLY=($(compgen -W "$client_names" -- "$cur"))
}

complete -F _awg_rm_client awg_rm_client

# =============================================================================
# СПРАВОЧНЫЕ ФУНКЦИИ
# =============================================================================

# Функция для отображения информации о клиентах
awg_list() {
    echo "👥 Список клиентов AmneziaWG:"
    make client-list --no-print-directory 2>/dev/null || echo "❌ Клиенты не найдены"
}

# Функция для показа конфигурации клиента
awg_config() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Использование: awg_config <имя_клиента>"
        echo "Доступные клиенты:"
        awg_list
        return 1
    fi
    
    echo "📄 Конфигурация клиента '$name':"
    make client-config name="$name" --no-print-directory
}

# Автокомплит для awg_config
_awg_config() {
    local cur client_names
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    
    client_names="$(_get_client_names)"
    COMPREPLY=($(compgen -W "$client_names" -- "$cur"))
}

complete -F _awg_config awg_config

# Справка по автокомплиту
awg_help() {
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║             AmneziaWG Make Autocomplete Справка             ║
╚══════════════════════════════════════════════════════════════╝

🎯 КОМАНДЫ MAKE (с полным автокомплитом):
  make <TAB>                    - Все доступные команды
  make client-add name=<TAB>    - Автокомплит имен клиентов
  make client-add ip=<TAB>      - Автокомплит следующего IP
  make client-qr name=<TAB>     - Автокомплит существующих клиентов
  make client-rm name=<TAB>     - Автокомплит для удаления
  make restore file=<TAB>       - Автокомплит архивных файлов

🔧 СКРИПТЫ:
  ./build.sh <TAB>              - Автокомплит имени образа и тега
  ./scripts/manage-clients.sh <TAB> - Автокомплит команд управления
  ./quick-start.sh <TAB>        - Автокомплит URL репозитория
  docker compose <TAB>          - Автокомплит Docker Compose команд

🚀 БЫСТРЫЕ КОМАНДЫ:
  awg_add_client <имя> [IP]     - Быстрое добавление клиента
  awg_rm_client <имя>           - Быстрое удаление клиента
  awg_qr <имя>                  - Быстрое отображение QR кода
  awg_config <имя>              - Показать конфигурацию клиента
  awg_list                      - Список всех клиентов
  awg_status                    - Быстрый статус сервера
  awg_logs                      - Быстрый просмотр логов

📝 УСТАНОВКА:
  source amneziawg-autocomplete.bash
  
  Или добавьте в ~/.bashrc:
  source /путь/к/amneziawg-autocomplete.bash

💡 ПРИМЕРЫ:
  make client-add name=john ip=10.13.13.5
  make client-qr name=john
  awg_add_client mobile          # IP назначится автоматически
  awg_qr mobile
  awg_rm_client old-device

🔍 ОСОБЕННОСТИ:
  ✅ Автокомплит работает с параметрами name=, ip=, file=
  ✅ Умный подбор следующего свободного IP
  ✅ Поддержка всех команд Makefile
  ✅ Автокомплит существующих клиентов для удаления/просмотра
  ✅ Поддержка Docker Compose команд

🔧 ОТЛАДКА:
  export AWG_DEBUG=1              - Включить отладочные сообщения
  export AWG_DEBUG=0              - Выключить отладку (по умолчанию)

EOF
}

# Экспорт функций для использования в других скриптах
export -f awg_add_client awg_rm_client awg_status awg_logs awg_qr awg_config awg_list awg_help
export -f _get_client_names _get_next_ip _get_backup_files

# Приветственное сообщение
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "🚀 AmneziaWG Make Autocomplete загружен!"
    echo "   Используйте 'awg_help' для подробной справки"
    echo "   Попробуйте: make <TAB> или make client-qr name=<TAB>"
    echo "   Быстрые команды: awg_add_client <TAB>, awg_qr <TAB>"
    echo ""
    echo "   💡 Если автокомплит не работает, выполните:"
    echo "      source $(readlink -f "${BASH_SOURCE[0]}")"
    echo ""
    echo "   🔧 Для отладки: export AWG_DEBUG=1"
fi
