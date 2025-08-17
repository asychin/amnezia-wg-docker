# AmneziaWG Docker Server Makefile
# Docker-реализация: asychin (https://github.com/asychin)
# Оригинальный VPN сервер: AmneziaWG Team (https://github.com/amnezia-vpn)
# Удобное управление AmneziaWG VPN сервером

# ============================================================================
# ПЕРЕМЕННЫЕ
# ============================================================================

# Настройки проекта
COMPOSE_FILE := docker-compose.yml
SERVICE_NAME := amneziawg-server
PROJECT_NAME := amneziawg-docker

# Команды Docker (для переиспользования)
DOCKER_COMPOSE := docker compose
DOCKER_EXEC := docker exec $(SERVICE_NAME)
DOCKER_LOGS := docker logs

# Цвета для вывода
BLUE := \033[34m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
PURPLE := \033[35m
CYAN := \033[36m
NC := \033[0m # No Color

# Сообщения
MSG_SERVER_NOT_RUNNING := $(RED)❌ Контейнер $(SERVICE_NAME) не запущен$(NC)\n$(YELLOW)Запустите сервер командой: make up$(NC)

# ============================================================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# ============================================================================

.PHONY: check-compose check-container check-client-name init-submodules auto-backup

# Проверка наличия docker compose
check-compose:
	@$(DOCKER_COMPOSE) version > /dev/null 2>&1 || (echo "$(RED)Error: Docker Compose не установлен$(NC)" && exit 1)

# Проверка запущенности контейнера для команд клиентов
check-container:
	@if ! $(DOCKER_COMPOSE) ps | grep -q "$(SERVICE_NAME).*Up"; then \
		echo -e "$(MSG_SERVER_NOT_RUNNING)"; \
		exit 1; \
	fi

# Проверка имени клиента
check-client-name:
	@if [ -z "$(name)" ]; then \
		echo "$(RED)❌ Необходимо указать имя клиента$(NC)"; \
		echo "$(YELLOW)Пример: make client-add name=john ip=10.13.13.5$(NC)"; \
		exit 1; \
	fi

# Автоматическая инициализация git submodules
init-submodules:
	@if [ ! -d "amneziawg-go/.git" ] || [ ! -d "amneziawg-tools/.git" ]; then \
		echo "$(YELLOW)🔧 Инициализация git submodules...$(NC)"; \
		git submodule update --init --recursive; \
		echo "$(GREEN)✅ Submodules инициализированы$(NC)"; \
	fi

# Автоматическое создание бэкапа конфигурации
auto-backup:
	@if [ -d "config" ] || [ -d "clients" ] || [ -f ".env" ]; then \
		BACKUP_FILE="amneziawg-auto-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz"; \
		echo "$(YELLOW)💾 Автоматическое создание резервной копии...$(NC)"; \
		tar -czf $$BACKUP_FILE config/ clients/ .env 2>/dev/null || true; \
		echo "$(GREEN)✅ Автобэкап создан: $$BACKUP_FILE$(NC)"; \
		# Автоматическая очистка старых бэкапов (оставляем последние 10) \
		BACKUP_COUNT=$$(ls amneziawg-auto-backup-*.tar.gz 2>/dev/null | wc -l); \
		if [ $$BACKUP_COUNT -gt 10 ]; then \
			ls -t amneziawg-auto-backup-*.tar.gz | tail -n +11 | xargs rm -f 2>/dev/null || true; \
		fi; \
	fi

# Проверка что сервер запущен
check-server-running:
	@if ! $(DOCKER_COMPOSE) ps | grep -q "$(SERVICE_NAME).*Up"; then \
		echo "$(RED)❌ Сервер не запущен$(NC)"; \
		echo "$(YELLOW)💡 Используйте 'make up' для запуска сервера$(NC)"; \
		exit 1; \
	fi

# Проверка что сервер остановлен
check-server-stopped:
	@if $(DOCKER_COMPOSE) ps | grep -q "$(SERVICE_NAME).*Up"; then \
		echo "$(YELLOW)⚠️  Сервер уже запущен$(NC)"; \
		echo "$(YELLOW)💡 Используйте 'make down' для остановки сервера$(NC)"; \
		exit 1; \
	fi

# Проверка что контейнер существует
check-container-exists:
	@if ! $(DOCKER_COMPOSE) ps -a | grep -q "$(SERVICE_NAME)"; then \
		echo "$(RED)❌ Контейнер $(SERVICE_NAME) не найден$(NC)"; \
		echo "$(YELLOW)💡 Используйте 'make build' для создания контейнера$(NC)"; \
		exit 1; \
	fi

# Проверка что есть конфигурация
check-config-exists:
	@if [ ! -d "config" ] && [ ! -d "clients" ] && [ ! -f ".env" ]; then \
		echo "$(YELLOW)⚠️  Конфигурация не найдена$(NC)"; \
		echo "$(YELLOW)💡 Используйте 'make init' для инициализации проекта$(NC)"; \
	fi

.PHONY: help
help: ## Показать эту справку
	@echo "$(PURPLE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(PURPLE)║               AmneziaWG VPN Server Commands                  ║$(NC)"
	@echo "$(PURPLE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)📋 ОСНОВНЫЕ КОМАНДЫ:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' | \
		grep -E "(init|build|up|down|restart|status|logs)"
	@echo ""
	@echo "$(CYAN)👥 УПРАВЛЕНИЕ КЛИЕНТАМИ:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' | \
		grep -E "(client-)"
	@echo ""
	@echo "$(CYAN)🔧 УТИЛИТЫ:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' | \
		grep -E "(shell|clean|update|backup|restore|autocomplete)"
	@echo ""
	@echo "$(YELLOW)💡 Примеры использования:$(NC)"
	@echo "  make client-add name=john                   # Добавить клиента john (IP автоматически)"
	@echo "  make client-add name=anna ip=10.13.13.15   # Добавить клиента anna с конкретным IP"
	@echo "  make client-qr name=john                    # Показать QR код для john"
	@echo "  make client-config name=john > john.conf   # Сохранить конфигурацию"
	@echo ""
	@echo "$(CYAN)💡 Для веб-интерфейса используйте:$(NC) $(GREEN)cd web && make help$(NC)"
	@echo ""

# ============================================================================
# ОСНОВНЫЕ КОМАНДЫ
# ============================================================================



.PHONY: init
init: check-compose init-submodules ## Инициализация проекта (сабмодули + конфигурация)
	@echo "$(BLUE)📦 Инициализация проекта...$(NC)"
	@if [ ! -f ".env" ]; then \
		echo "$(YELLOW)Создаем конфигурацию из шаблона...$(NC)"; \
		cp env.example .env; \
		echo "$(GREEN)✅ Файл .env создан. Отредактируйте его при необходимости.$(NC)"; \
	fi
	@echo "$(CYAN)💡 Команда init автоматически вызывается при:$(NC)"
	@echo "$(CYAN)   - make up (если .env отсутствует)$(NC)"
	@echo "$(CYAN)   - make build (если .env отсутствует)$(NC)"

.PHONY: build
build: check-compose init-submodules check-config-exists auto-backup ## Сборка Docker образа
	@echo "$(BLUE)🔨 Сборка Docker образа...$(NC)"
	@# Автоматическая инициализация если нужно
	@if [ ! -f ".env" ]; then \
		echo "$(YELLOW)🔧 Автоматическая инициализация проекта...$(NC)"; \
		$(MAKE) init; \
	fi
	@$(DOCKER_COMPOSE) build
	@echo "$(GREEN)✅ Образ собран успешно$(NC)"





.PHONY: up
up: check-compose init-submodules check-server-stopped ## Запуск сервера
	@echo "$(BLUE)🚀 Запуск AmneziaWG сервера...$(NC)"
	@# Автоматическая инициализация если нужно
	@if [ ! -f ".env" ]; then \
		echo "$(YELLOW)🔧 Автоматическая инициализация проекта...$(NC)"; \
		$(MAKE) init; \
	fi
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)✅ Сервер запущен$(NC)"
	@sleep 5
	@$(MAKE) status

.PHONY: down
down: check-compose check-server-running auto-backup ## Остановка сервера
	@echo "$(BLUE)🛑 Остановка AmneziaWG сервера...$(NC)"
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)✅ Сервер остановлен$(NC)"

.PHONY: restart
restart: check-compose check-server-running auto-backup ## Перезапуск сервера
	@echo "$(BLUE)🔄 Перезапуск сервера...$(NC)"
	@$(DOCKER_COMPOSE) down
	@sleep 2
	@$(MAKE) up

.PHONY: logs
logs: check-compose check-server-running ## Просмотр логов в реальном времени
	@echo "$(BLUE)📄 Логи AmneziaWG сервера (Ctrl+C для выхода):$(NC)"
	@$(DOCKER_LOGS) -f $(SERVICE_NAME)

.PHONY: status
status: check-compose ## Статус сервера и соединений
	@echo "$(PURPLE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(PURPLE)║                    Статус AmneziaWG Сервера                  ║$(NC)"
	@echo "$(PURPLE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)📊 Статус контейнера:$(NC)"
	@$(DOCKER_COMPOSE) ps || echo "$(RED)Контейнер не запущен$(NC)"
	@echo ""
	@if $(DOCKER_COMPOSE) ps | grep -q "Up"; then \
		echo "$(CYAN)🔗 Статус AmneziaWG интерфейса:$(NC)"; \
		$(DOCKER_EXEC) awg show awg0 2>/dev/null || echo "$(YELLOW)Интерфейс недоступен$(NC)"; \
		echo ""; \
		echo "$(CYAN)🌐 Активные соединения:$(NC)"; \
		$(DOCKER_EXEC) awg show awg0 latest-handshakes 2>/dev/null || echo "$(YELLOW)Нет активных соединений$(NC)"; \
	else \
		echo "$(RED)❌ Сервер не запущен. Используйте 'make up' для запуска$(NC)"; \
	fi

# ============================================================================
# УПРАВЛЕНИЕ КЛИЕНТАМИ
# ============================================================================

.PHONY: client-add
client-add: check-compose check-server-running check-client-name auto-backup ## Добавить клиента (name=имя [ip=IP])
	@if [ -z "$(ip)" ]; then \
		echo "$(YELLOW)⚠️  IP не указан, будет выбран автоматически$(NC)"; \
		$(DOCKER_EXEC) /app/scripts/manage-clients.sh add $(name) || exit 1; \
	else \
		$(DOCKER_EXEC) /app/scripts/manage-clients.sh add $(name) $(ip) || exit 1; \
	fi
	@echo "$(GREEN)✅ Клиент $(name) добавлен$(NC)"

.PHONY: client-rm
client-rm: check-compose check-server-running check-client-name auto-backup ## Удалить клиента (name=имя)
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh remove $(name) || exit 1
	@echo "$(GREEN)✅ Клиент $(name) удален$(NC)"

.PHONY: client-qr
client-qr: check-compose check-server-running check-client-name ## Показать QR код клиента (name=имя)
	@echo "$(BLUE)📱 QR код для клиента '$(name)':$(NC)"
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh qr $(name)

.PHONY: client-config
client-config: check-compose check-server-running check-client-name ## Показать конфигурацию клиента (name=имя)
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh show $(name)

.PHONY: client-list
client-list: check-compose check-server-running ## Список всех клиентов
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh list

.PHONY: client-info
client-info: check-compose check-server-running ## Информация о подключениях клиентов
	@echo "$(BLUE)📊 Информация о клиентах:$(NC)"
	@$(DOCKER_EXEC) awg show awg0 dump 2>/dev/null || \
		echo "$(YELLOW)Информация недоступна$(NC)"

# ============================================================================
# УТИЛИТЫ
# ============================================================================

.PHONY: shell
shell: check-compose check-server-running ## Войти в контейнер
	@echo "$(BLUE)🐚 Вход в контейнер AmneziaWG...$(NC)"
	@docker exec -it $(SERVICE_NAME) /bin/bash

.PHONY: clean
clean: check-compose check-container-exists auto-backup ## Полная очистка (остановка + удаление данных)
	@echo "$(YELLOW)⚠️  Это удалит все данные сервера и клиентов!$(NC)"
	@echo "$(GREEN)💾 Резервная копия уже создана автоматически$(NC)"
	@read -p "Продолжить? [y/N]: " confirm && [ "$$confirm" = "y" ]
	@$(DOCKER_COMPOSE) down -v --remove-orphans
	@docker system prune -f
	@rm -rf config/ clients/
	@echo "$(GREEN)✅ Очистка завершена$(NC)"

.PHONY: update
update: check-compose init-submodules check-server-running auto-backup ## Обновление сабмодулей и пересборка
	@echo "$(BLUE)🔄 Обновление проекта...$(NC)"
	@echo "$(BLUE)📥 Обновляем сабмодули...$(NC)"
	@git submodule update --remote --recursive
	@echo "$(BLUE)🛑 Останавливаем сервер...$(NC)"
	@$(DOCKER_COMPOSE) down
	@echo "$(BLUE)🔨 Пересобираем образ...$(NC)"
	@$(MAKE) build
	@echo "$(BLUE)🚀 Запускаем сервер...$(NC)"
	@$(MAKE) up
	@echo "$(GREEN)✅ Обновление завершено$(NC)"
	@echo "$(YELLOW)💡 Если возникли проблемы с конфигурацией, используйте 'make restore file=<backup_file>'$(NC)"

.PHONY: backup
backup: check-compose ## Создать резервную копию конфигураций
	@BACKUP_FILE="amneziawg-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz"; \
	echo "$(BLUE)💾 Создание резервной копии...$(NC)"; \
	tar -czf $$BACKUP_FILE config/ clients/ .env 2>/dev/null || true; \
	echo "$(GREEN)✅ Резервная копия создана: $$BACKUP_FILE$(NC)"

.PHONY: backup-cleanup
backup-cleanup: ## Очистка старых автоматических бэкапов (оставляет последние 10)
	@echo "$(BLUE)🧹 Очистка старых автоматических бэкапов...$(NC)"; \
	BACKUP_COUNT=$$(ls amneziawg-auto-backup-*.tar.gz 2>/dev/null | wc -l); \
	if [ $$BACKUP_COUNT -gt 10 ]; then \
		ls -t amneziawg-auto-backup-*.tar.gz | tail -n +11 | xargs rm -f; \
		echo "$(GREEN)✅ Удалено $$(($$BACKUP_COUNT - 10)) старых бэкапов$(NC)"; \
	else \
		echo "$(YELLOW)ℹ️  Количество бэкапов ($$BACKUP_COUNT) в пределах нормы$(NC)"; \
	fi

.PHONY: autocomplete-install autocomplete-remove autocomplete-status
autocomplete-install: ## Установить автокомплит в ~/.bashrc
	@echo "$(BLUE)🔧 Установка автокомплита AmneziaWG...$(NC)"; \
	if [ ! -f "amneziawg-autocomplete.bash" ]; then \
		echo "$(RED)❌ Файл amneziawg-autocomplete.bash не найден$(NC)"; \
		exit 1; \
	fi; \
	AUTOCOMPLETE_PATH="$$(readlink -f amneziawg-autocomplete.bash)"; \
	BASHRC_PATH="$$HOME/.bashrc"; \
	if grep -q "amneziawg-autocomplete.bash" "$$BASHRC_PATH" 2>/dev/null; then \
		echo "$(YELLOW)⚠️  Автокомплит уже установлен в $$BASHRC_PATH$(NC)"; \
		echo "$(CYAN)💡 Используйте 'make autocomplete-status' для проверки$(NC)"; \
	else \
		echo "" >> "$$BASHRC_PATH"; \
		echo "# AmneziaWG Docker Server Autocomplete" >> "$$BASHRC_PATH"; \
		echo "source \"$$AUTOCOMPLETE_PATH\"" >> "$$BASHRC_PATH"; \
		echo "$(GREEN)✅ Автокомплит установлен в $$BASHRC_PATH$(NC)"; \
		echo "$(CYAN)💡 Перезапустите терминал или выполните: source $$BASHRC_PATH$(NC)"; \
	fi

autocomplete-remove: ## Удалить автокомплит из ~/.bashrc
	@echo "$(BLUE)🗑️ Удаление автокомплита AmneziaWG...$(NC)"; \
	BASHRC_PATH="$$HOME/.bashrc"; \
	if [ ! -f "$$BASHRC_PATH" ]; then \
		echo "$(RED)❌ Файл $$BASHRC_PATH не найден$(NC)"; \
		exit 1; \
	fi; \
	if grep -q "amneziawg-autocomplete.bash" "$$BASHRC_PATH" 2>/dev/null; then \
		echo "$(YELLOW)Удаляем строки автокомплита...$(NC)"; \
		grep -v "amneziawg-autocomplete.bash" "$$BASHRC_PATH" | \
		grep -v "AmneziaWG Docker Server Autocomplete" > "$$BASHRC_PATH.tmp"; \
		mv "$$BASHRC_PATH.tmp" "$$BASHRC_PATH"; \
		echo "$(GREEN)✅ Автокомплит удален из $$BASHRC_PATH$(NC)"; \
		echo "$(CYAN)💡 Перезапустите терминал для применения изменений$(NC)"; \
	else \
		echo "$(YELLOW)ℹ️  Автокомплит не найден в $$BASHRC_PATH$(NC)"; \
	fi

autocomplete-status: ## Проверить статус автокомплита
	@echo "$(BLUE)🔍 Проверка статуса автокомплита...$(NC)"; \
	AUTOCOMPLETE_PATH="$$(readlink -f amneziawg-autocomplete.bash 2>/dev/null || echo '')"; \
	BASHRC_PATH="$$HOME/.bashrc"; \
	echo "$(CYAN)📁 Файл автокомплита:$(NC)"; \
	if [ -f "amneziawg-autocomplete.bash" ]; then \
		echo "$(GREEN)✅ amneziawg-autocomplete.bash найден$(NC)"; \
		echo "   Путь: $$AUTOCOMPLETE_PATH"; \
	else \
		echo "$(RED)❌ amneziawg-autocomplete.bash не найден$(NC)"; \
	fi; \
	echo ""; \
	echo "$(CYAN)📝 Интеграция в bashrc:$(NC)"; \
	if [ -f "$$BASHRC_PATH" ] && grep -q "amneziawg-autocomplete.bash" "$$BASHRC_PATH" 2>/dev/null; then \
		echo "$(GREEN)✅ Автокомплит интегрирован в $$BASHRC_PATH$(NC)"; \
		grep "amneziawg-autocomplete.bash" "$$BASHRC_PATH" | head -1; \
	else \
		echo "$(RED)❌ Автокомплит НЕ интегрирован в $$BASHRC_PATH$(NC)"; \
		echo "$(YELLOW)💡 Используйте 'make autocomplete-install' для установки$(NC)"; \
	fi; \
	echo ""; \
	echo "$(CYAN)🔧 Текущая сессия:$(NC)"; \
	if command -v _amneziawg_make &>/dev/null; then \
		echo "$(GREEN)✅ Автокомплит активен в текущей сессии$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  Автокомплит НЕ активен в текущей сессии$(NC)"; \
		echo "$(CYAN)💡 Выполните: source amneziawg-autocomplete.bash$(NC)"; \
	fi

autocomplete-test: ## Протестировать автокомплит
	@echo "$(BLUE)🧪 Тестирование автокомплита...$(NC)"; \
	if [ ! -f "amneziawg-autocomplete.bash" ]; then \
		echo "$(RED)❌ Файл amneziawg-autocomplete.bash не найден$(NC)"; \
		exit 1; \
	fi; \
	echo "$(CYAN)📋 Загружаем автокомплит...$(NC)"; \
	echo "$(GREEN)✅ Автокомплит готов к тестированию$(NC)"; \
	echo ""; \
	echo "$(CYAN)🎯 Инструкции для тестирования:$(NC)"; \
	echo "   1. Выполните: source amneziawg-autocomplete.bash"; \
	echo "   2. Попробуйте: make <TAB>"; \
	echo "   3. Попробуйте: make client-add name=<TAB>"; \
	echo "   4. Попробуйте: awg_add_client <TAB>"; \
	echo ""; \
	echo "$(YELLOW)💡 Для постоянной установки используйте: make autocomplete-install$(NC)"
	@echo "$(CYAN)💡 Автокомплит предоставляет:$(NC)"
	@echo "$(CYAN)   - Автодополнение всех make команд$(NC)"
	@echo "$(CYAN)   - Умный подбор имен клиентов и IP адресов$(NC)"
	@echo "$(CYAN)   - Быстрые команды awg_* для частых операций$(NC)"

.PHONY: restore
restore: ## Восстановить из резервной копии (file=путь_к_архиву)
	@if [ -z "$(file)" ]; then \
		echo "$(RED)❌ Укажите файл: make restore file=backup.tar.gz$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)📥 Восстановление из $(file)...$(NC)"
	@$(MAKE) down
	@tar -xzf $(file)
	@$(MAKE) up
	@echo "$(GREEN)✅ Восстановление завершено$(NC)"

.PHONY: test
test: check-compose ## Тест соединения и конфигурации
	@echo "$(BLUE)🧪 Тестирование AmneziaWG сервера...$(NC)"
	@echo ""
	@echo "$(CYAN)1. Проверка контейнера:$(NC)"
	@$(DOCKER_COMPOSE) ps | grep $(SERVICE_NAME) | grep Up && echo "$(GREEN)✅ Контейнер запущен$(NC)" || echo "$(RED)❌ Контейнер не запущен$(NC)"
	@echo ""
	@echo "$(CYAN)2. Проверка интерфейса:$(NC)"
	@$(DOCKER_EXEC) ip link show awg0 >/dev/null 2>&1 && echo "$(GREEN)✅ Интерфейс awg0 активен$(NC)" || echo "$(RED)❌ Интерфейс awg0 неактивен$(NC)"
	@echo ""
	@echo "$(CYAN)3. Проверка порта:$(NC)"
	@$(DOCKER_EXEC) netstat -ulnp | grep :51820 >/dev/null 2>&1 && echo "$(GREEN)✅ Порт 51820 прослушивается$(NC)" || echo "$(RED)❌ Порт 51820 не прослушивается$(NC)"
	@echo ""
	@echo "$(CYAN)4. Проверка DNS:$(NC)"
	@$(DOCKER_EXEC) nslookup google.com >/dev/null 2>&1 && echo "$(GREEN)✅ DNS работает$(NC)" || echo "$(RED)❌ Проблемы с DNS$(NC)"

.PHONY: debug
debug: check-compose ## Отладочная информация
	@echo "$(PURPLE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(PURPLE)║                    Отладочная информация                    ║$(NC)"
	@echo "$(PURPLE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)🐳 Docker версия:$(NC)"
	@docker --version
	@$(DOCKER_COMPOSE) version
	@echo ""
	@echo "$(CYAN)📊 Статус контейнера:$(NC)"
	@$(DOCKER_COMPOSE) ps
	@echo ""
	@echo "$(CYAN)🔍 Последние логи:$(NC)"
	@$(DOCKER_LOGS) --tail=20 $(SERVICE_NAME) 2>/dev/null || echo "$(YELLOW)Логи недоступны$(NC)"
	@echo ""
	@echo "$(CYAN)🌐 Сетевые интерфейсы:$(NC)"
	@$(DOCKER_EXEC) ip addr show 2>/dev/null || echo "Контейнер недоступен"
	@echo ""
	@echo "$(CYAN)🔥 iptables правила:$(NC)"
	@$(DOCKER_EXEC) iptables -L -n 2>/dev/null || echo "Контейнер недоступен"

.PHONY: monitor
monitor: check-compose ## Мониторинг в реальном времени
	@echo "$(BLUE)📈 Мониторинг AmneziaWG (Ctrl+C для выхода)$(NC)"
	@while true; do \
		clear; \
		echo "$(PURPLE)═══════════════════ AmneziaWG Monitor $(shell date) ═══════════════════$(NC)"; \
		echo ""; \
		$(MAKE) status --no-print-directory; \
		echo ""; \
		echo "$(CYAN)💾 Использование ресурсов:$(NC)"; \
		docker stats $(SERVICE_NAME) --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" 2>/dev/null || echo "Контейнер недоступен"; \
		sleep 5; \
	done

# ============================================================================
# НАСТРОЙКИ ПО УМОЛЧАНИЮ
# ============================================================================

# ============================================================================
# RELEASE MANAGEMENT (MOVED TO GITHUB ACTIONS)
# ============================================================================
# Releases are now handled through GitHub Actions pipeline.
# Use the GitHub UI to create releases with semantic versioning:
# 
# 1. Go to: https://github.com/{your-repo}/actions/workflows/release.yml
# 2. Click "Run workflow" 
# 3. Select release type: patch, minor, major, prerelease, or custom
# 4. The pipeline will automatically:
#    - Calculate new version using semantic versioning
#    - Update VERSION file
#    - Create git tag
#    - Build and publish Docker images
#    - Generate changelog
#    - Create GitHub release
#
# For more information, see: PIPELINE.md

.PHONY: release-info
release-info: ## Показать информацию о релизах (теперь через GitHub Actions)
	@echo "$(PURPLE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(PURPLE)║                    RELEASE INFORMATION                      ║$(NC)"
	@echo "$(PURPLE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(YELLOW)📢 Релизы теперь создаются через GitHub Actions!$(NC)"
	@echo ""
	@echo "$(CYAN)🚀 Как создать релиз:$(NC)"
	@echo "1. Откройте: https://github.com/$$(git config --get remote.origin.url | sed 's/.*github.com[\/:]//; s/.git$$//')/actions/workflows/release.yml"
	@echo "2. Нажмите 'Run workflow'"
	@echo "3. Выберите тип релиза:"
	@echo "   • patch  - увеличивает версию патча (1.0.0 → 1.0.1)"
	@echo "   • minor  - увеличивает минорную версию (1.0.0 → 1.1.0)"
	@echo "   • major  - увеличивает мажорную версию (1.0.0 → 2.0.0)"
	@echo "   • prerelease - создает предварительную версию (1.0.0 → 1.0.1-rc.1)"
	@echo "   • custom - позволяет указать произвольную версию"
	@echo ""
	@echo "$(CYAN)⚡ Пайплайн автоматически:$(NC)"
	@echo "   ✓ Вычислит новую версию по семантическому версионированию"
	@echo "   ✓ Обновит файл VERSION"
	@echo "   ✓ Создаст git тег"
	@echo "   ✓ Соберет и опубликует Docker образы"
	@echo "   ✓ Сгенерирует changelog"
	@echo "   ✓ Создаст GitHub релиз"
	@echo ""
	@echo "$(CYAN)📚 Подробнее:$(NC) $(GREEN)PIPELINE.md$(NC)"

.PHONY: release-current
release-current: ## Показать текущую версию
	@if [ -f "VERSION" ]; then \
		CURRENT_VERSION=$$(cat VERSION | tr -d '\n'); \
		echo "$(GREEN)📁 Current version (from VERSION file): $$CURRENT_VERSION$(NC)"; \
	else \
		LATEST_TAG=$$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0"); \
		echo "$(YELLOW)🏷️ Latest tag: $$LATEST_TAG$(NC)"; \
		echo "$(CYAN)💡 No VERSION file found. Consider creating a release to initialize versioning.$(NC)"; \
	fi

# По умолчанию показываем справку
.DEFAULT_GOAL := help