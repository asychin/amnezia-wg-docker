# AmneziaWG Web Interface Makefile
# Управление веб-интерфейсом для AmneziaWG сервера

# ============================================================================
# ПЕРЕМЕННЫЕ
# ============================================================================

# Пути к проектам
WEB_DIR := $(PWD)
FRONTEND_DIR := $(WEB_DIR)/frontend
BACKEND_DIR := $(WEB_DIR)/backend
AMNEZIA_DIR := $(shell dirname $(WEB_DIR))

# Docker Compose файлы
COMPOSE_WEB := docker-compose.web.yml
COMPOSE_MAIN := ../docker-compose.yml

# Цвета для вывода
BLUE := \033[34m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
PURPLE := \033[35m
NC := \033[0m

# ============================================================================
# ОСНОВНЫЕ КОМАНДЫ
# ============================================================================

.PHONY: help
help: ## Показать справку
	@echo "$(PURPLE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(PURPLE)║            AmneziaWG Web Interface Commands                  ║$(NC)"
	@echo "$(PURPLE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)🌐 ВЕБ-ИНТЕРФЕЙС:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' | \
		grep -E "(web-|dev-|build-)"
	@echo ""
	@echo "$(CYAN)🐳 DOCKER:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' | \
		grep -E "(up|down|restart|status|logs)"
	@echo ""
	@echo "$(CYAN)🔧 РАЗРАБОТКА:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' | \
		grep -E "(install|test|clean)"

# ============================================================================
# УСТАНОВКА И РАЗРАБОТКА
# ============================================================================

.PHONY: install
install: ## Установить зависимости для frontend и backend
	@echo "$(BLUE)📦 Устанавливаем зависимости...$(NC)"
	@echo "$(YELLOW)Installing frontend dependencies...$(NC)"
	@cd $(FRONTEND_DIR) && npm install
	@echo "$(YELLOW)Installing backend dependencies...$(NC)"
	@cd $(BACKEND_DIR) && go mod download
	@echo "$(GREEN)✅ Зависимости установлены$(NC)"

.PHONY: dev-frontend
dev-frontend: ## Запустить frontend в режиме разработки
	@echo "$(BLUE)🚀 Запускаем frontend dev server...$(NC)"
	@cd $(FRONTEND_DIR) && npm run dev

.PHONY: dev-backend
dev-backend: ## Запустить backend в режиме разработки
	@echo "$(BLUE)🚀 Запускаем backend dev server...$(NC)"
	@cd $(BACKEND_DIR) && go run cmd/main.go

.PHONY: dev
dev: ## Запустить полный dev stack (требует два терминала)
	@echo "$(BLUE)🚀 Для разработки запустите в разных терминалах:$(NC)"
	@echo "$(YELLOW)Terminal 1: make dev-backend$(NC)"
	@echo "$(YELLOW)Terminal 2: make dev-frontend$(NC)"

# ============================================================================
# СБОРКА
# ============================================================================

.PHONY: build-frontend
build-frontend: ## Собрать frontend для продакшена
	@echo "$(BLUE)🔨 Сборка frontend...$(NC)"
	@cd $(FRONTEND_DIR) && npm run build
	@echo "$(GREEN)✅ Frontend собран$(NC)"

.PHONY: build-backend
build-backend: ## Собрать backend бинарник
	@echo "$(BLUE)🔨 Сборка backend...$(NC)"
	@cd $(BACKEND_DIR) && go build -o bin/amneziawg-web-api cmd/main.go
	@echo "$(GREEN)✅ Backend собран$(NC)"

.PHONY: build
build: build-frontend build-backend ## Собрать весь проект

# ============================================================================
# DOCKER КОМАНДЫ
# ============================================================================

.PHONY: web-build
web-build: ## Собрать Docker образы для веб-интерфейса
	@echo "$(BLUE)🐳 Сборка Docker образов...$(NC)"
	@docker compose -f $(COMPOSE_WEB) build
	@echo "$(GREEN)✅ Docker образы собраны$(NC)"

.PHONY: web-build-minimal
web-build-minimal: ## Минимальная сборка для слабых серверов (1vCPU, 1GB RAM)
	@echo "$(BLUE)🐳 Минимальная сборка Docker образов...$(NC)"
	@echo "$(YELLOW)⚠️  Оптимизировано для слабых серверов (1vCPU, 1GB RAM)$(NC)"
	@docker compose -f docker-compose.minimal.yml build --no-cache
	@echo "$(GREEN)✅ Минимальные Docker образы собраны$(NC)"

.PHONY: web-up
web-up: ## Запустить весь веб-интерфейс (с AmneziaWG сервером)
	@echo "$(BLUE)🚀 Запускаем веб-интерфейс...$(NC)"
	@# Сначала убеждаемся что основной сервер запущен
	@cd $(AMNEZIA_DIR) && make up
	@# Затем запускаем веб-интерфейс
	@docker compose -f $(COMPOSE_WEB) up -d
	@echo "$(GREEN)✅ Веб-интерфейс запущен$(NC)"
	@echo "$(YELLOW)🌐 Доступен по адресу: http://localhost$(NC)"
	@echo "$(YELLOW)📡 API доступен по адресу: http://localhost:8080$(NC)"

.PHONY: web-up-minimal
web-up-minimal: ## Запустить минимальную версию веб-интерфейса
	@echo "$(BLUE)🚀 Запускаем минимальный веб-интерфейс...$(NC)"
	@echo "$(YELLOW)⚠️  Минимальная версия для слабых серверов$(NC)"
	@# Сначала убеждаемся что основной сервер запущен
	@cd $(AMNEZIA_DIR) && make up
	@# Затем запускаем минимальный веб-интерфейс
	@docker compose -f docker-compose.minimal.yml up -d
	@echo "$(GREEN)✅ Минимальный веб-интерфейс запущен$(NC)"
	@echo "$(YELLOW)🌐 Доступен по адресу: http://localhost:3000$(NC)"
	@echo "$(YELLOW)📡 API доступен по адресу: http://localhost:8080$(NC)"

.PHONY: web-down
web-down: ## Остановить веб-интерфейс
	@echo "$(BLUE)🛑 Остановка веб-интерфейса...$(NC)"
	@docker compose -f $(COMPOSE_WEB) down
	@echo "$(GREEN)✅ Веб-интерфейс остановлен$(NC)"

.PHONY: web-down-minimal
web-down-minimal: ## Остановить минимальную версию веб-интерфейса
	@echo "$(BLUE)🛑 Остановка минимального веб-интерфейса...$(NC)"
	@docker compose -f docker-compose.minimal.yml down
	@echo "$(GREEN)✅ Минимальный веб-интерфейс остановлен$(NC)"

.PHONY: web-restart
web-restart: web-down web-up ## Перезапустить веб-интерфейс

.PHONY: web-status
web-status: ## Показать статус веб-интерфейса
	@echo "$(BLUE)📊 Статус веб-интерфейса:$(NC)"
	@docker compose -f $(COMPOSE_WEB) ps

.PHONY: web-logs
web-logs: ## Показать логи веб-интерфейса
	@echo "$(BLUE)📄 Логи веб-интерфейса:$(NC)"
	@docker compose -f $(COMPOSE_WEB) logs -f

.PHONY: web-logs-api
web-logs-api: ## Показать логи API
	@docker compose -f $(COMPOSE_WEB) logs -f amneziawg-web-api

.PHONY: web-logs-frontend
web-logs-frontend: ## Показать логи frontend
	@docker compose -f $(COMPOSE_WEB) logs -f amneziawg-web-frontend

# ============================================================================
# ПОЛНОЕ УПРАВЛЕНИЕ
# ============================================================================

.PHONY: up
up: ## Запустить весь стек (AmneziaWG + Web Interface)
	@echo "$(BLUE)🚀 Запускаем полный стек...$(NC)"
	@cd $(AMNEZIA_DIR) && make up
	@docker compose -f $(COMPOSE_WEB) up -d
	@echo "$(GREEN)✅ Полный стек запущен$(NC)"
	@echo "$(YELLOW)🌐 Веб-интерфейс: http://localhost$(NC)"
	@echo "$(YELLOW)📡 API: http://localhost:8080$(NC)"

.PHONY: down
down: ## Остановить весь стек
	@echo "$(BLUE)🛑 Остановка полного стека...$(NC)"
	@docker compose -f $(COMPOSE_WEB) down
	@cd $(AMNEZIA_DIR) && make down
	@echo "$(GREEN)✅ Полный стек остановлен$(NC)"

.PHONY: restart
restart: down up ## Перезапустить весь стек

.PHONY: status
status: ## Показать статус всех сервисов
	@echo "$(PURPLE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(PURPLE)║                    Статус всех сервисов                     ║$(NC)"
	@echo "$(PURPLE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)🔧 AmneziaWG Сервер:$(NC)"
	@cd $(AMNEZIA_DIR) && docker compose ps || echo "$(RED)Не запущен$(NC)"
	@echo ""
	@echo "$(CYAN)🌐 Веб-интерфейс:$(NC)"
	@docker compose -f $(COMPOSE_WEB) ps || echo "$(RED)Не запущен$(NC)"

.PHONY: logs
logs: ## Показать логи всех сервисов
	@echo "$(BLUE)📄 Логи всех сервисов (Ctrl+C для выхода):$(NC)"
	@docker compose -f $(COMPOSE_WEB) logs -f

# ============================================================================
# УТИЛИТЫ
# ============================================================================

.PHONY: test
test: ## Запустить тесты
	@echo "$(BLUE)🧪 Запуск тестов...$(NC)"
	@cd $(FRONTEND_DIR) && npm run lint
	@cd $(BACKEND_DIR) && go test ./...
	@echo "$(GREEN)✅ Тесты прошли$(NC)"

.PHONY: clean
clean: ## Очистить все (остановить сервисы + удалить образы)
	@echo "$(YELLOW)⚠️  Это остановит все сервисы и удалит Docker образы!$(NC)"
	@read -p "Продолжить? [y/N]: " confirm && [ "$$confirm" = "y" ]
	@docker compose -f $(COMPOSE_WEB) down -v --remove-orphans
	@docker compose -f $(COMPOSE_WEB) rmi --all || true
	@cd $(AMNEZIA_DIR) && make clean
	@echo "$(GREEN)✅ Очистка завершена$(NC)"

.PHONY: shell-api
shell-api: ## Войти в контейнер API
	@docker compose -f $(COMPOSE_WEB) exec amneziawg-web-api sh

.PHONY: shell-frontend
shell-frontend: ## Войти в контейнер frontend
	@docker compose -f $(COMPOSE_WEB) exec amneziawg-web-frontend sh

# ============================================================================
# ИНФОРМАЦИЯ
# ============================================================================

.PHONY: info
info: ## Показать информацию о проекте
	@echo "$(PURPLE)╔══════════════════════════════════════════════════════════════╗$(NC)"
	@echo "$(PURPLE)║                AmneziaWG Web Interface Info                  ║$(NC)"
	@echo "$(PURPLE)╚══════════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(CYAN)📁 Структура проекта:$(NC)"
	@echo "  • Frontend: React + TypeScript + Chakra UI v3"
	@echo "  • Backend:  Go + Gin + WebSocket"
	@echo "  • Proxy:    Nginx"
	@echo "  • Container: Docker + Docker Compose"
	@echo ""
	@echo "$(CYAN)🌐 URL сервисов:$(NC)"
	@echo "  • Web Interface: http://localhost"
	@echo "  • API:          http://localhost:8080"
	@echo "  • Frontend Dev: http://localhost:3000"
	@echo ""
	@echo "$(CYAN)📊 Функции:$(NC)"
	@echo "  • Dashboard с графиками и метриками"
	@echo "  • Управление клиентами (добавление, удаление, QR коды)"
	@echo "  • Настройки сервера и обфускации"
	@echo "  • Real-time логи через WebSocket"
	@echo "  • Responsive design для мобильных устройств"

# По умолчанию показываем справку
.DEFAULT_GOAL := help
