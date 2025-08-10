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
PROJECT_NAME := docker-wg

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

.PHONY: check-compose check-container check-client-name

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

.PHONY: help
help: ## Показать эту справку
	@echo "$(PURPLE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(PURPLE)║               AmneziaWG Docker Server Commands               ║$(NC)"
	@echo "$(PURPLE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)📋 ОСНОВНЫЕ КОМАНДЫ:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' | \
		grep -E "(build|up|down|restart|status|logs)"
	@echo ""
	@echo "$(CYAN)👥 УПРАВЛЕНИЕ КЛИЕНТАМИ:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' | \
		grep -E "(client-)"
	@echo ""
	@echo "$(CYAN)🔧 УТИЛИТЫ:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' | \
		grep -E "(shell|clean|update|backup|restore)"
	@echo ""
	@echo "$(YELLOW)💡 Примеры использования:$(NC)"
	@echo "  make client-add name=john                   # Добавить клиента john (IP автоматически)"
	@echo "  make client-add name=anna ip=10.13.13.15   # Добавить клиента anna с конкретным IP"
	@echo "  make client-qr name=john                    # Показать QR код для john"
	@echo "  make client-config name=john > john.conf   # Сохранить конфигурацию"
	@echo ""

# ============================================================================
# ОСНОВНЫЕ КОМАНДЫ
# ============================================================================

.PHONY: install
install: ## Автоматическая установка (требует root)
	@echo "$(BLUE)🚀 Запуск автоматической установки...$(NC)"
	@sudo ./install.sh

.PHONY: init
init: check-compose ## Инициализация проекта (сабмодули + конфигурация)
	@echo "$(BLUE)📦 Инициализация проекта...$(NC)"
	@if [ ! -d "amneziawg-go/.git" ]; then \
		echo "$(YELLOW)Обновляем сабмодули...$(NC)"; \
		git submodule update --init --recursive; \
	fi
	@if [ ! -f ".env" ]; then \
		echo "$(YELLOW)Создаем конфигурацию из шаблона...$(NC)"; \
		cp env.example .env; \
		echo "$(GREEN)✅ Файл .env создан. Отредактируйте его при необходимости.$(NC)"; \
	fi

.PHONY: build build-advanced
build: init ## Сборка Docker образа (обычная)
	@echo "$(BLUE)🔨 Сборка Docker образа...$(NC)"
	@$(DOCKER_COMPOSE) build --no-cache
	@echo "$(GREEN)✅ Образ собран успешно$(NC)"

build-advanced: init ## Сборка с метаданными и версионированием
	@echo "$(BLUE)🔨 Расширенная сборка Docker образа...$(NC)"
	@./build.sh

.PHONY: quick-start
quick-start: ## Клонирование проекта для разработки (url=repo-url [dir=dirname])
	@echo "$(PURPLE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(PURPLE)║                  AmneziaWG Quick Start                      ║$(NC)"
	@echo "$(PURPLE)║                 Быстрое развертывание                       ║$(NC)"
	@echo "$(PURPLE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@if [ -z "$(url)" ]; then \
		echo "$(RED)❌ Укажите URL репозитория: make quick-start url=https://github.com/user/repo.git$(NC)"; \
		exit 1; \
	fi
	@if ! command -v git &> /dev/null; then \
		echo "$(RED)❌ Git не установлен$(NC)"; \
		exit 1; \
	fi
	@REPO_NAME=$$(basename "$(url)" .git); \
	TARGET_DIR=$${dir:-$$REPO_NAME}; \
	echo "$(BLUE)📥 Клонирование $$REPO_NAME в $$TARGET_DIR...$(NC)"; \
	if [ -d "$$TARGET_DIR" ]; then \
		echo "$(YELLOW)⚠️  Директория $$TARGET_DIR уже существует$(NC)"; \
		read -p "Удалить и пересоздать? [y/N]: " confirm; \
		if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
			rm -rf "$$TARGET_DIR"; \
		else \
			echo "$(RED)❌ Операция отменена$(NC)"; \
			exit 1; \
		fi; \
	fi; \
	git clone --recursive "$(url)" "$$TARGET_DIR"; \
	if [ ! -f "$$TARGET_DIR/Makefile" ] || [ ! -f "$$TARGET_DIR/docker-compose.yml" ]; then \
		echo "$(RED)❌ Это не AmneziaWG Docker проект$(NC)"; \
		exit 1; \
	fi; \
	echo "$(GREEN)✅ Проект клонирован в $$TARGET_DIR$(NC)"; \
	echo "$(BLUE)🚀 Следующие шаги:$(NC)"; \
	echo "1. cd $$TARGET_DIR"; \
	echo "2. sudo make install"; \
	echo "3. make build && make up"

.PHONY: up
up: check-compose ## Запуск сервера
	@echo "$(BLUE)🚀 Запуск AmneziaWG сервера...$(NC)"
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)✅ Сервер запущен$(NC)"
	@sleep 5
	@$(MAKE) status

.PHONY: down
down: check-compose ## Остановка сервера
	@echo "$(BLUE)🛑 Остановка AmneziaWG сервера...$(NC)"
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)✅ Сервер остановлен$(NC)"

.PHONY: restart
restart: ## Перезапуск сервера
	@echo "$(BLUE)🔄 Перезапуск сервера...$(NC)"
	@$(MAKE) down
	@sleep 2
	@$(MAKE) up

.PHONY: logs
logs: check-compose ## Просмотр логов в реальном времени
	@echo "$(BLUE)📄 Логи AmneziaWG сервера (Ctrl+C для выхода):$(NC)"
	@$(DOCKER_LOGS) -f $(SERVICE_NAME) 2>/dev/null || echo "$(RED)Контейнер не найден$(NC)"

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
client-add: check-compose check-container check-client-name ## Добавить клиента (name=имя [ip=IP])
	@if [ -z "$(ip)" ]; then \
		echo "$(YELLOW)⚠️  IP не указан, будет выбран автоматически$(NC)"; \
		$(DOCKER_EXEC) /app/scripts/manage-clients.sh add $(name) || exit 1; \
	else \
		$(DOCKER_EXEC) /app/scripts/manage-clients.sh add $(name) $(ip) || exit 1; \
	fi
	@echo "$(GREEN)✅ Клиент $(name) добавлен$(NC)"

.PHONY: client-rm
client-rm: check-compose check-container check-client-name ## Удалить клиента (name=имя)
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh remove $(name) || exit 1
	@echo "$(GREEN)✅ Клиент $(name) удален$(NC)"

.PHONY: client-qr
client-qr: check-compose check-container check-client-name ## Показать QR код клиента (name=имя)
	@echo "$(BLUE)📱 QR код для клиента '$(name)':$(NC)"
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh qr $(name)

.PHONY: client-config
client-config: check-compose check-container check-client-name ## Показать конфигурацию клиента (name=имя)
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh show $(name)

.PHONY: client-list
client-list: check-compose check-container ## Список всех клиентов
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh list

.PHONY: client-info
client-info: check-compose check-container ## Информация о подключениях клиентов
	@echo "$(BLUE)📊 Информация о клиентах:$(NC)"
	@$(DOCKER_EXEC) awg show awg0 dump 2>/dev/null || \
		echo "$(YELLOW)Информация недоступна$(NC)"

# ============================================================================
# УТИЛИТЫ
# ============================================================================

.PHONY: shell
shell: check-compose ## Войти в контейнер
	@echo "$(BLUE)🐚 Вход в контейнер AmneziaWG...$(NC)"
	@docker exec -it $(SERVICE_NAME) /bin/bash

.PHONY: clean
clean: check-compose ## Полная очистка (остановка + удаление данных)
	@echo "$(YELLOW)⚠️  Это удалит все данные сервера и клиентов!$(NC)"
	@read -p "Продолжить? [y/N]: " confirm && [ "$$confirm" = "y" ]
	@$(MAKE) down
	@$(DOCKER_COMPOSE) down -v --remove-orphans
	@docker system prune -f
	@rm -rf config/ clients/
	@echo "$(GREEN)✅ Очистка завершена$(NC)"

.PHONY: update
update: ## Обновление сабмодулей и пересборка
	@echo "$(BLUE)🔄 Обновление проекта...$(NC)"
	@git submodule update --remote --recursive
	@$(MAKE) down
	@$(MAKE) build
	@$(MAKE) up
	@echo "$(GREEN)✅ Обновление завершено$(NC)"

.PHONY: backup
backup: check-compose ## Создать резервную копию конфигураций
	@BACKUP_FILE="amneziawg-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz"; \
	echo "$(BLUE)💾 Создание резервной копии...$(NC)"; \
	tar -czf $$BACKUP_FILE config/ clients/ .env 2>/dev/null || true; \
	echo "$(GREEN)✅ Резервная копия создана: $$BACKUP_FILE$(NC)"

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

# По умолчанию показываем справку
.DEFAULT_GOAL := help