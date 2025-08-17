# AmneziaWG Web Interface Makefile
# Docker-реализация: asychin (https://github.com/asychin)
# Оригинальный VPN сервер: AmneziaWG Team (https://github.com/amnezia-vpn)
# Удобное управление веб-интерфейсом AmneziaWG

# ============================================================================
# ПЕРЕМЕННЫЕ
# ============================================================================

# Настройки проекта
WEB_COMPOSE_FILE := docker-compose.web.yml
WEB_PROJECT_NAME := amneziawg-web
VPN_PROJECT_PATH := ..
PROJECT_NAME := amneziawg-web

# Команды Docker
DOCKER_COMPOSE := docker compose
WEB_DOCKER_COMPOSE := $(DOCKER_COMPOSE) -f $(WEB_COMPOSE_FILE) -p $(WEB_PROJECT_NAME)
VPN_DOCKER_COMPOSE := $(DOCKER_COMPOSE) -f ../docker-compose.yml

# Сервисы
WEB_API_SERVICE := amneziawg-web-api
WEB_FRONTEND_SERVICE := amneziawg-web-frontend
WEB_NGINX_SERVICE := amneziawg-web-nginx
VPN_SERVICE := amneziawg-server

# Цвета для вывода
BLUE := \033[34m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
PURPLE := \033[35m
CYAN := \033[36m
NC := \033[0m # No Color

# ============================================================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# ============================================================================

.PHONY: check-compose check-vpn-server check-web-env check-container check-web-running check-web-stopped

# Проверка наличия docker compose
check-compose:
	@$(DOCKER_COMPOSE) version > /dev/null 2>&1 || (echo "$(RED)Error: Docker Compose не установлен$(NC)" && exit 1)

# Проверка что VPN сервер запущен
check-vpn-server:
	@if ! $(VPN_DOCKER_COMPOSE) ps | grep -q "$(VPN_SERVICE).*Up"; then \
		echo "$(RED)❌ VPN сервер не запущен$(NC)"; \
		echo "$(YELLOW)💡 Запустите VPN сервер командой: cd .. && make up$(NC)"; \
		exit 1; \
	fi

# Проверка наличия .env файлов
check-web-env:
	@if [ ! -f "backend/.env" ] && [ ! -f "backend/env.example" ]; then \
		echo "$(RED)❌ Не найден backend/.env файл$(NC)"; \
		echo "$(YELLOW)💡 Скопируйте backend/env.example в backend/.env$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f "frontend/.env" ] && [ ! -f "frontend/env.example" ]; then \
		echo "$(RED)❌ Не найден frontend/.env файл$(NC)"; \
		echo "$(YELLOW)💡 Скопируйте frontend/env.example в frontend/.env$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f ".env" ] && [ ! -f "env.web.example" ]; then \
		echo "$(RED)❌ Не найден .env файл$(NC)"; \
		echo "$(YELLOW)💡 Скопируйте env.web.example в .env$(NC)"; \
		exit 1; \
	fi

# Проверка запущенности контейнера
check-container:
	@if ! $(WEB_DOCKER_COMPOSE) ps | grep -q "Up"; then \
		echo "$(RED)❌ Веб-интерфейс не запущен$(NC)"; \
		echo "$(YELLOW)💡 Используйте 'make up' для запуска$(NC)"; \
		exit 1; \
	fi

# Проверка что веб-интерфейс запущен
check-web-running:
	@if ! $(WEB_DOCKER_COMPOSE) ps | grep -q "Up"; then \
		echo "$(RED)❌ Веб-интерфейс не запущен$(NC)"; \
		echo "$(YELLOW)💡 Используйте 'make up' для запуска веб-интерфейса$(NC)"; \
		exit 1; \
	fi

# Проверка что веб-интерфейс остановлен
check-web-stopped:
	@if $(WEB_DOCKER_COMPOSE) ps | grep -q "Up"; then \
		echo "$(YELLOW)⚠️  Веб-интерфейс уже запущен$(NC)"; \
		echo "$(YELLOW)💡 Используйте 'make down' для остановки$(NC)"; \
		exit 1; \
	fi

.PHONY: help
help: ## Показать эту справку
	@echo "$(PURPLE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(PURPLE)║            AmneziaWG Web Interface Commands                  ║$(NC)"
	@echo "$(PURPLE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)📋 ОСНОВНЫЕ КОМАНДЫ:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' | \
		grep -E "(init|build|up|down|restart|status|logs)"
	@echo ""
	@echo "$(CYAN)🔗 CONNECTION STRINGS:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' | \
		grep -E "(connection-)"
	@echo ""
	@echo "$(CYAN)🔧 УТИЛИТЫ:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' | \
		grep -E "(shell|clean|debug|monitor)"
	@echo ""
	@echo "$(YELLOW)💡 Примеры использования:$(NC)"
	@echo "  make up                                         # Запустить веб-интерфейс"
	@echo "  make connection-generate name=\"My Server\"       # Сгенерировать connection string"
	@echo "  make connection-list                            # Список connection strings"
	@echo ""

# ============================================================================
# ИНИЦИАЛИЗАЦИЯ И НАСТРОЙКА
# ============================================================================

.PHONY: init
init: check-compose ## Инициализация веб-интерфейса
	@echo "$(BLUE)📦 Инициализация веб-интерфейса...$(NC)"
	@# Создаем .env файлы если их нет
	@if [ ! -f ".env" ]; then \
		echo "$(YELLOW)Создаем .env из шаблона env.web.example...$(NC)"; \
		cp env.web.example .env; \
		echo "$(GREEN)✅ Web .env создан$(NC)"; \
	fi
	@if [ ! -f "backend/.env" ]; then \
		echo "$(YELLOW)Создаем backend/.env из шаблона...$(NC)"; \
		cp backend/env.example backend/.env; \
		echo "$(GREEN)✅ Backend .env создан$(NC)"; \
	fi
	@if [ ! -f "frontend/.env" ]; then \
		echo "$(YELLOW)Создаем frontend/.env из шаблона...$(NC)"; \
		cp frontend/env.example frontend/.env; \
		echo "$(GREEN)✅ Frontend .env создан$(NC)"; \
	fi
	@# Создаем директории для данных
	@mkdir -p backend/data nginx/ssl
	@echo "$(GREEN)✅ Веб-интерфейс инициализирован$(NC)"
	@echo "$(CYAN)💡 Отредактируйте файлы .env при необходимости$(NC)"

# ============================================================================
# ОСНОВНЫЕ КОМАНДЫ
# ============================================================================

.PHONY: build
build: check-compose init ## Сборка веб-интерфейса
	@echo "$(BLUE)🔨 Сборка веб-интерфейса...$(NC)"
	@$(WEB_DOCKER_COMPOSE) build
	@echo "$(GREEN)✅ Веб-интерфейс собран$(NC)"

.PHONY: up
up: check-compose check-vpn-server check-web-stopped init ## Запуск веб-интерфейса
	@echo "$(BLUE)🚀 Запуск веб-интерфейса...$(NC)"
	@$(WEB_DOCKER_COMPOSE) up -d
	@echo "$(GREEN)✅ Веб-интерфейс запущен$(NC)"
	@sleep 3
	@$(MAKE) status

.PHONY: down
down: check-compose check-web-running ## Остановка веб-интерфейса
	@echo "$(BLUE)🛑 Остановка веб-интерфейса...$(NC)"
	@$(WEB_DOCKER_COMPOSE) down
	@echo "$(GREEN)✅ Веб-интерфейс остановлен$(NC)"

.PHONY: restart
restart: check-compose check-web-running ## Перезапуск веб-интерфейса
	@echo "$(BLUE)🔄 Перезапуск веб-интерфейса...$(NC)"
	@$(WEB_DOCKER_COMPOSE) down
	@sleep 2
	@$(MAKE) up

.PHONY: logs
logs: check-compose ## Логи веб-интерфейса
	@echo "$(BLUE)📄 Логи веб-интерфейса (Ctrl+C для выхода):$(NC)"
	@$(WEB_DOCKER_COMPOSE) logs -f

.PHONY: status
status: check-compose ## Статус веб-интерфейса
	@echo "$(PURPLE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(PURPLE)║                 Статус Веб-интерфейса                        ║$(NC)"
	@echo "$(PURPLE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)📊 Статус сервисов:$(NC)"
	@$(WEB_DOCKER_COMPOSE) ps || echo "$(RED)Веб-интерфейс не запущен$(NC)"
	@echo ""
	@if $(WEB_DOCKER_COMPOSE) ps | grep -q "Up"; then \
		echo "$(CYAN)🌐 Доступные адреса:$(NC)"; \
		echo "$(GREEN)  Frontend: http://localhost:3000$(NC)"; \
		echo "$(GREEN)  API:      http://localhost:8080$(NC)"; \
		echo "$(GREEN)  Nginx:    http://localhost:80$(NC)"; \
		echo ""; \
		echo "$(CYAN)💻 Тест API:$(NC)"; \
		curl -s http://localhost:8080/health >/dev/null 2>&1 && \
			echo "$(GREEN)✅ API отвечает$(NC)" || \
			echo "$(RED)❌ API недоступен$(NC)"; \
	else \
		echo "$(RED)❌ Веб-интерфейс не запущен. Используйте 'make up' для запуска$(NC)"; \
	fi

.PHONY: logs-api
logs-api: check-compose ## Логи только API
	@echo "$(BLUE)📄 Логи API (Ctrl+C для выхода):$(NC)"
	@$(WEB_DOCKER_COMPOSE) logs -f $(WEB_API_SERVICE)

.PHONY: logs-frontend
logs-frontend: check-compose ## Логи только frontend
	@echo "$(BLUE)📄 Логи Frontend (Ctrl+C для выхода):$(NC)"
	@$(WEB_DOCKER_COMPOSE) logs -f $(WEB_FRONTEND_SERVICE)

# ============================================================================
# УПРАВЛЕНИЕ CONNECTION STRINGS
# ============================================================================

.PHONY: connection-generate
connection-generate: check-compose ## Генерировать connection string (name=имя [location=место] [ttl=время])
	@if [ -z "$(name)" ]; then \
		echo "$(RED)❌ Необходимо указать имя сервера$(NC)"; \
		echo "$(YELLOW)Пример: make connection-generate name=\"My Server\" location=\"Moscow\" ttl=720h$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)🔗 Генерация connection string для '$(name)'...$(NC)"
	@LOCATION_ARG=""; if [ ! -z "$(location)" ]; then LOCATION_ARG="--location $(location)"; fi; \
	TTL_ARG=""; if [ ! -z "$(ttl)" ]; then TTL_ARG="--ttl $(ttl)"; fi; \
	HOST_ARG=""; if [ ! -z "$(host)" ]; then HOST_ARG="--host $(host)"; fi; \
	PROTOCOL_ARG=""; if [ ! -z "$(protocol)" ]; then PROTOCOL_ARG="--protocol $(protocol)"; fi; \
	docker exec $(WEB_API_SERVICE) ./connection-gen \
		--server-name "$(name)" \
		$$LOCATION_ARG \
		$$TTL_ARG \
		$$HOST_ARG \
		$$PROTOCOL_ARG \
		--output string
	@echo ""
	@echo "$(GREEN)✅ Connection string сгенерирован$(NC)"

.PHONY: connection-generate-json
connection-generate-json: check-compose ## Генерировать connection string в JSON формате
	@if [ -z "$(name)" ]; then \
		echo "$(RED)❌ Необходимо указать имя сервера$(NC)"; \
		echo "$(YELLOW)Пример: make connection-generate-json name=\"My Server\"$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)🔗 Генерация connection string (JSON) для '$(name)'...$(NC)"
	@LOCATION_ARG=""; if [ ! -z "$(location)" ]; then LOCATION_ARG="--location $(location)"; fi; \
	TTL_ARG=""; if [ ! -z "$(ttl)" ]; then TTL_ARG="--ttl $(ttl)"; fi; \
	HOST_ARG=""; if [ ! -z "$(host)" ]; then HOST_ARG="--host $(host)"; fi; \
	PROTOCOL_ARG=""; if [ ! -z "$(protocol)" ]; then PROTOCOL_ARG="--protocol $(protocol)"; fi; \
	docker exec $(WEB_API_SERVICE) ./connection-gen \
		--server-name "$(name)" \
		$$LOCATION_ARG \
		$$TTL_ARG \
		$$HOST_ARG \
		$$PROTOCOL_ARG \
		--output json

.PHONY: connection-generate-qr
connection-generate-qr: check-compose ## Генерировать connection string с QR кодом
	@if [ -z "$(name)" ]; then \
		echo "$(RED)❌ Необходимо указать имя сервера$(NC)"; \
		echo "$(YELLOW)Пример: make connection-generate-qr name=\"My Server\"$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)🔗 Генерация connection string с QR кодом для '$(name)'...$(NC)"
	@LOCATION_ARG=""; if [ ! -z "$(location)" ]; then LOCATION_ARG="--location $(location)"; fi; \
	TTL_ARG=""; if [ ! -z "$(ttl)" ]; then TTL_ARG="--ttl $(ttl)"; fi; \
	HOST_ARG=""; if [ ! -z "$(host)" ]; then HOST_ARG="--host $(host)"; fi; \
	PROTOCOL_ARG=""; if [ ! -z "$(protocol)" ]; then PROTOCOL_ARG="--protocol $(protocol)"; fi; \
	docker exec $(WEB_API_SERVICE) ./connection-gen \
		--server-name "$(name)" \
		$$LOCATION_ARG \
		$$TTL_ARG \
		$$HOST_ARG \
		$$PROTOCOL_ARG \
		--output qr

.PHONY: connection-test
connection-test: check-compose ## Тестировать connection string (conn=строка)
	@if [ -z "$(conn)" ]; then \
		echo "$(RED)❌ Необходимо указать connection string$(NC)"; \
		echo "$(YELLOW)Пример: make connection-test conn=\"awgwc://eyJ2ZXJzaW9uIjoiMS4wIi...\"$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)🧪 Тестирование connection string...$(NC)"
	@curl -s -X POST http://localhost:8080/api/v1/connections/test \
		-H "Content-Type: application/json" \
		-d "{\"connection_string\": \"$(conn)\"}" | \
		python3 -m json.tool 2>/dev/null || \
		echo "$(RED)❌ Ошибка тестирования или API недоступен$(NC)"

.PHONY: connection-list
connection-list: check-compose ## Список всех connection strings (требует авторизации)
	@echo "$(BLUE)📋 Список connection strings...$(NC)"
	@echo "$(YELLOW)⚠️  Для просмотра требуется авторизация через веб-интерфейс$(NC)"
	@echo "$(CYAN)💡 Откройте http://localhost:3000 и войдите как admin$(NC)"



# ============================================================================
# УТИЛИТЫ
# ============================================================================

.PHONY: shell
shell: check-compose ## Войти в контейнер API
	@echo "$(BLUE)🐚 Вход в контейнер API...$(NC)"
	@docker exec -it $(WEB_API_SERVICE) /bin/sh

.PHONY: shell-frontend
shell-frontend: check-compose ## Войти в контейнер Frontend
	@echo "$(BLUE)🐚 Вход в контейнер Frontend...$(NC)"
	@docker exec -it $(WEB_FRONTEND_SERVICE) /bin/sh

.PHONY: clean
clean: check-compose ## Полная очистка веб-интерфейса
	@echo "$(YELLOW)⚠️  Это удалит все данные веб-интерфейса!$(NC)"
	@read -p "Продолжить? [y/N]: " confirm && [ "$$confirm" = "y" ]
	@$(WEB_DOCKER_COMPOSE) down -v --remove-orphans
	@docker rm -f $(WEB_API_SERVICE) $(WEB_FRONTEND_SERVICE) 2>/dev/null || true
	@docker system prune -f
	@rm -rf backend/data/* backend/.env frontend/.env .env
	@echo "$(GREEN)✅ Веб-интерфейс очищен$(NC)"

.PHONY: test
test: check-compose ## Тест веб-интерфейса и его соединений
	@echo "$(BLUE)🧪 Тестирование веб-интерфейса...$(NC)"
	@echo ""
	@echo "$(CYAN)1. Проверка контейнеров:$(NC)"
	@$(WEB_DOCKER_COMPOSE) ps | grep Up && echo "$(GREEN)✅ Контейнеры запущены$(NC)" || echo "$(RED)❌ Контейнеры не запущены$(NC)"
	@echo ""
	@echo "$(CYAN)2. Проверка API:$(NC)"
	@curl -s http://localhost:8080/health >/dev/null 2>&1 && echo "$(GREEN)✅ API отвечает$(NC)" || echo "$(RED)❌ API недоступен$(NC)"
	@echo ""
	@echo "$(CYAN)3. Проверка Frontend:$(NC)"
	@curl -s http://localhost:3000 >/dev/null 2>&1 && echo "$(GREEN)✅ Frontend доступен$(NC)" || echo "$(RED)❌ Frontend недоступен$(NC)"
	@echo ""
	@echo "$(CYAN)4. Проверка Nginx:$(NC)"
	@curl -s http://localhost:80 >/dev/null 2>&1 && echo "$(GREEN)✅ Nginx работает$(NC)" || echo "$(RED)❌ Nginx недоступен$(NC)"

.PHONY: debug
debug: check-compose ## Отладочная информация
	@echo "$(PURPLE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(PURPLE)║               Отладка Веб-интерфейса                         ║$(NC)"
	@echo "$(PURPLE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)📊 Статус контейнеров:$(NC)"
	@$(WEB_DOCKER_COMPOSE) ps
	@echo ""
	@echo "$(CYAN)🔍 Логи (последние 10 строк):$(NC)"
	@$(WEB_DOCKER_COMPOSE) logs --tail=10
	@echo ""
	@echo "$(CYAN)🌐 Сетевые подключения:$(NC)"
	@docker network ls | grep web || echo "Веб-сети не найдены"
	@echo ""
	@echo "$(CYAN)💾 Использование ресурсов:$(NC)"
	@docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $$($(WEB_DOCKER_COMPOSE) ps -q) 2>/dev/null || echo "Контейнеры не запущены"

.PHONY: monitor
monitor: check-compose ## Мониторинг веб-интерфейса в реальном времени
	@echo "$(BLUE)📈 Мониторинг веб-интерфейса (Ctrl+C для выхода)$(NC)"
	@while true; do \
		clear; \
		echo "$(PURPLE)═══════════════ AmneziaWG Web Monitor $(shell date) ═══════════════$(NC)"; \
		echo ""; \
		$(MAKE) status --no-print-directory; \
		echo ""; \
		echo "$(CYAN)💾 Ресурсы:$(NC)"; \
		docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" $$($(WEB_DOCKER_COMPOSE) ps -q) 2>/dev/null || echo "Контейнеры не запущены"; \
		sleep 5; \
	done

# По умолчанию показываем справку
.DEFAULT_GOAL := help