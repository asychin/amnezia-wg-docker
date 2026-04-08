# AmneziaWG Docker Server Makefile
# VPN server with DPI bypass capabilities

# Project settings
COMPOSE_FILE := docker-compose.yml
SERVICE_NAME := amneziawg-server
PROJECT_NAME := amnezia-wg-docker
VERSION := $(shell cat VERSION 2>/dev/null || echo "unknown")

# Docker commands
DOCKER_COMPOSE := docker compose
DOCKER_EXEC := docker exec $(SERVICE_NAME)
DOCKER_LOGS := docker logs

# Read port from .env (fallback to 51820)
AWG_PORT := $(shell grep -s '^AWG_PORT=' .env | cut -d= -f2 || echo 51820)

# Colors
BLUE := \033[34m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
CYAN := \033[36m
NC := \033[0m

# Get positional arguments (for simplified syntax like: make client-add john 10.13.13.5)
# Filter out known targets to get just the arguments
CLIENT_TARGETS := client-add client-rm client-qr client-config client-vpnurl
ARGS := $(filter-out $(CLIENT_TARGETS),$(MAKECMDGOALS))
ARG1 := $(word 1,$(ARGS))
ARG2 := $(word 2,$(ARGS))

# Support both: make client-add john AND make client-add name=john
CLIENT_NAME := $(if $(name),$(name),$(ARG1))
CLIENT_IP := $(if $(ip),$(ip),$(ARG2))

# ============================================================================
# .PHONY declarations (grouped)
# ============================================================================

.PHONY: help init build rebuild up down restart reload logs status \
        client-add client-rm client-qr client-config client-list client-vpnurl \
        shell clean update backup backup-cleanup restore backup-restart backup-logs backup-verify \
        test debug monitor version config \
        autocomplete-install autocomplete-remove \
        check-compose check-container check-client-name check-env init-submodules \
        generate-obfuscation

# Default target
.DEFAULT_GOAL := help

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

check-compose:
	@$(DOCKER_COMPOSE) version > /dev/null 2>&1 || (echo "$(RED)Error: Docker Compose not installed$(NC)" && exit 1)

# Проверка контейнера через docker compose ps -q (надёжнее чем grep)
check-container:
	@if [ -z "$$($(DOCKER_COMPOSE) ps -q $(SERVICE_NAME) 2>/dev/null)" ] || \
	   [ -z "$$(docker ps -q -f name=$(SERVICE_NAME) 2>/dev/null)" ]; then \
		echo "$(RED)Error: Container $(SERVICE_NAME) is not running$(NC)"; \
		echo "$(YELLOW)Run 'make up' to start the server$(NC)"; \
		exit 1; \
	fi

check-client-name:
	@if [ -z "$(CLIENT_NAME)" ]; then \
		echo "$(RED)Error: Client name required$(NC)"; \
		echo "$(YELLOW)Usage: make client-add <name> [ip]$(NC)"; \
		echo "$(YELLOW)   or: make client-add name=<name> [ip=<ip>]$(NC)"; \
		exit 1; \
	fi

check-env:
	@if [ ! -f ".env" ]; then \
		echo "$(RED)Error: .env file not found$(NC)"; \
		echo "$(YELLOW)Run 'make init' first$(NC)"; \
		exit 1; \
	fi

init-submodules:
	@if [ ! -d "amneziawg-go/.git" ] || [ ! -d "amneziawg-tools/.git" ]; then \
		echo "$(YELLOW)Initializing git submodules...$(NC)"; \
		git submodule update --init --recursive; \
		echo "$(GREEN)Submodules initialized$(NC)"; \
	fi

# ============================================================================
# OBFUSCATION PARAMETERS
# ============================================================================

# Generate random obfuscation parameters
# Official AmneziaWG v2 parameter ranges:
# - Jc: 1-128, recommended 4-12
# - Jmin: recommended 8-50
# - Jmax: recommended 80-250 (must be < MTU 1280)
# - S1: 15-150, constraint: S1 + 56 != S2
# - S2: 15-150
# - S3: 0-1216 (Cookie packets, v2 NEW), recommended 15-150
# - S4: 0-32 (Data packets, v2 NEW)
# - H1/H2/H3/H4: unique 32-bit integers, range 5-2147483647
generate-obfuscation: check-env
	@AWG_JC=$$(shuf -i 4-12 -n 1); \
	AWG_JMIN=$$(shuf -i 8-50 -n 1); \
	AWG_JMAX=$$(shuf -i 80-250 -n 1); \
	AWG_S1=$$(shuf -i 15-150 -n 1); \
	AWG_S2=$$(shuf -i 15-150 -n 1); \
	while [ $$((AWG_S1 + 56)) -eq $$AWG_S2 ]; do \
		AWG_S2=$$(shuf -i 15-150 -n 1); \
	done; \
	AWG_S3=$$(shuf -i 15-150 -n 1); \
	AWG_S4=$$(shuf -i 0-32 -n 1); \
	AWG_H1=$$(shuf -i 5-2147483647 -n 1); \
	AWG_H2=$$(shuf -i 5-2147483647 -n 1); \
	while [ $$AWG_H2 -eq $$AWG_H1 ]; do AWG_H2=$$(shuf -i 5-2147483647 -n 1); done; \
	AWG_H3=$$(shuf -i 5-2147483647 -n 1); \
	while [ $$AWG_H3 -eq $$AWG_H1 ] || [ $$AWG_H3 -eq $$AWG_H2 ]; do AWG_H3=$$(shuf -i 5-2147483647 -n 1); done; \
	AWG_H4=$$(shuf -i 5-2147483647 -n 1); \
	while [ $$AWG_H4 -eq $$AWG_H1 ] || [ $$AWG_H4 -eq $$AWG_H2 ] || [ $$AWG_H4 -eq $$AWG_H3 ]; do AWG_H4=$$(shuf -i 5-2147483647 -n 1); done; \
	sed -i "s/^AWG_JC=.*/AWG_JC=$$AWG_JC/" .env; \
	sed -i "s/^AWG_JMIN=.*/AWG_JMIN=$$AWG_JMIN/" .env; \
	sed -i "s/^AWG_JMAX=.*/AWG_JMAX=$$AWG_JMAX/" .env; \
	sed -i "s/^AWG_S1=.*/AWG_S1=$$AWG_S1/" .env; \
	sed -i "s/^AWG_S2=.*/AWG_S2=$$AWG_S2/" .env; \
	sed -i "s/^AWG_S3=.*/AWG_S3=$$AWG_S3/" .env; \
	sed -i "s/^AWG_S4=.*/AWG_S4=$$AWG_S4/" .env; \
	sed -i "s/^AWG_H1=.*/AWG_H1=$$AWG_H1/" .env; \
	sed -i "s/^AWG_H2=.*/AWG_H2=$$AWG_H2/" .env; \
	sed -i "s/^AWG_H3=.*/AWG_H3=$$AWG_H3/" .env; \
	sed -i "s/^AWG_H4=.*/AWG_H4=$$AWG_H4/" .env; \
	echo "$(GREEN)Generated random obfuscation parameters (AWG v2):$(NC)"; \
	echo "  Jc=$$AWG_JC Jmin=$$AWG_JMIN Jmax=$$AWG_JMAX"; \
	echo "  S1=$$AWG_S1 S2=$$AWG_S2 S3=$$AWG_S3 S4=$$AWG_S4"; \
	echo "  H1=$$AWG_H1 H2=$$AWG_H2 H3=$$AWG_H3 H4=$$AWG_H4"

# ============================================================================
# HELP (unified — all targets use ## comments)
# ============================================================================

help: ## Show this help
	@echo "$(CYAN)AmneziaWG Docker Server v$(VERSION)$(NC)"
	@echo ""
	@STANDARD_STATUS="$(YELLOW)inactive$(NC)"; \
	if docker ps --filter "name=$(SERVICE_NAME)" --format "{{.Names}}" 2>/dev/null | grep -q "$(SERVICE_NAME)"; then \
		STANDARD_STATUS="$(GREEN)active$(NC)"; \
	fi; \
	echo "$(CYAN)VPN Server:$(NC) $$STANDARD_STATUS"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(CYAN)Examples:$(NC)"
	@echo "  make up                        Start VPN server"
	@echo "  make client-add john           Add client (auto IP)"
	@echo "  make client-add john 10.13.13.5  Add client (manual IP)"
	@echo "  make client-qr john            Show QR code"
	@echo "  make client-vpnurl john        Show vpn:// connection string"
	@echo "  make backup                    Create backup"

# ============================================================================
# MAIN COMMANDS
# ============================================================================

init: check-compose init-submodules ## Initialize project
	@echo "$(BLUE)Initializing project...$(NC)"
	@if [ ! -f ".env" ]; then \
		cp .env.example .env; \
		echo "$(GREEN).env file created$(NC)"; \
		$(MAKE) generate-obfuscation; \
	else \
		echo "$(YELLOW).env already exists$(NC)"; \
	fi
	@mkdir -p backups
	@echo "$(GREEN)Project initialized$(NC)"

build: check-compose init-submodules ## Build Docker image (with cache)
	@echo "$(BLUE)Building Docker image...$(NC)"
	@if [ ! -f ".env" ]; then $(MAKE) init; fi
	@$(DOCKER_COMPOSE) build
	@echo "$(GREEN)Build complete$(NC)"

rebuild: check-compose init-submodules ## Full rebuild (no cache)
	@echo "$(BLUE)Rebuilding Docker image (no cache)...$(NC)"
	@if [ ! -f ".env" ]; then $(MAKE) init; fi
	@$(DOCKER_COMPOSE) build --no-cache
	@echo "$(GREEN)Rebuild complete$(NC)"

up: check-compose init-submodules ## Start VPN server
	@echo "$(BLUE)Starting AmneziaWG server...$(NC)"
	@if [ ! -f ".env" ]; then $(MAKE) init; fi
	@$(DOCKER_COMPOSE) up -d --build
	@echo "$(GREEN)Server started$(NC)"
	@sleep 3
	@$(MAKE) status

# FIX: down is idempotent — no check-container requirement
down: check-compose ## Stop server (idempotent)
	@echo "$(BLUE)Stopping server...$(NC)"
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)Server stopped$(NC)"

# FIX: restart doesn't require running container, uses proper flow
restart: check-compose ## Restart server (full recreate)
	@echo "$(BLUE)Restarting server...$(NC)"
	@$(DOCKER_COMPOSE) down 2>/dev/null || true
	@if [ ! -f ".env" ]; then $(MAKE) init; fi
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Server restarted$(NC)"

reload: check-compose check-container ## Quick restart (without recreating container)
	@echo "$(BLUE)Reloading server...$(NC)"
	@$(DOCKER_COMPOSE) restart
	@echo "$(GREEN)Server reloaded$(NC)"

logs: check-compose ## View logs (Ctrl+C to exit)
	@$(DOCKER_LOGS) -f $(SERVICE_NAME) 2>/dev/null || echo "$(YELLOW)Container not running$(NC)"

status: check-compose ## Show server status
	@echo "$(CYAN)Container status:$(NC)"
	@$(DOCKER_COMPOSE) ps || echo "$(RED)Container not running$(NC)"
	@echo ""
	@if [ -n "$$(docker ps -q -f name=$(SERVICE_NAME) 2>/dev/null)" ]; then \
		echo "$(CYAN)AmneziaWG interface:$(NC)"; \
		$(DOCKER_EXEC) awg show awg0 2>/dev/null || echo "$(YELLOW)Interface not available$(NC)"; \
		echo ""; \
		echo "$(CYAN)Active connections:$(NC)"; \
		$(DOCKER_EXEC) awg show awg0 latest-handshakes 2>/dev/null || echo "$(YELLOW)No active connections$(NC)"; \
	fi

version: ## Show project version
	@echo "$(CYAN)AmneziaWG Docker Server$(NC) v$(VERSION)"

config: check-env ## Show current configuration
	@echo "$(CYAN)Current configuration (.env):$(NC)"
	@echo ""
	@grep -v '^\s*#' .env | grep -v '^\s*$$' | while IFS='=' read -r key value; do \
		echo "  $(GREEN)$$key$(NC) = $$value"; \
	done

monitor: check-compose check-container ## Monitor server (live stats)
	@echo "$(CYAN)Monitoring AmneziaWG server (Ctrl+C to exit)...$(NC)"
	@while true; do \
		clear; \
		echo "$(CYAN)=== AmneziaWG Monitor ($(shell date '+%H:%M:%S')) ===$(NC)"; \
		echo ""; \
		$(DOCKER_EXEC) awg show awg0 2>/dev/null || echo "$(YELLOW)Interface not available$(NC)"; \
		echo ""; \
		echo "$(CYAN)Container stats:$(NC)"; \
		docker stats $(SERVICE_NAME) --no-stream --format "  CPU: {{.CPUPerc}}  MEM: {{.MemUsage}}" 2>/dev/null; \
		sleep 5; \
	done

# ============================================================================
# CLIENT MANAGEMENT
# ============================================================================

client-add: check-compose check-container check-client-name ## Add client: client-add <name> [ip]
	@if [ -z "$(CLIENT_IP)" ]; then \
		$(DOCKER_EXEC) /app/scripts/manage-clients.sh add $(CLIENT_NAME); \
	else \
		$(DOCKER_EXEC) /app/scripts/manage-clients.sh add $(CLIENT_NAME) $(CLIENT_IP); \
	fi
	@echo "$(GREEN)Client $(CLIENT_NAME) added$(NC)"

client-rm: check-compose check-container check-client-name ## Remove client: client-rm <name>
	@echo "$(YELLOW)Warning: This will permanently delete client '$(CLIENT_NAME)' and their keys!$(NC)"
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ] || (echo "$(YELLOW)Cancelled$(NC)" && exit 1)
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh remove $(CLIENT_NAME)
	@echo "$(GREEN)Client $(CLIENT_NAME) removed$(NC)"

client-qr: check-compose check-container check-client-name ## Show QR code: client-qr <name>
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh qr $(CLIENT_NAME)

client-config: check-compose check-container check-client-name ## Show config: client-config <name>
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh show $(CLIENT_NAME)

client-list: check-compose check-container ## List all clients
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh list

client-vpnurl: check-compose check-container check-client-name ## Show vpn:// URI: client-vpnurl <name>
	@$(DOCKER_EXEC) /app/scripts/generate-vpn-uri.sh $(CLIENT_NAME)

# ============================================================================
# UTILITIES
# ============================================================================

shell: check-compose check-container ## Enter container shell
	@docker exec -it $(SERVICE_NAME) /bin/bash

# FIX: clean only removes project resources, not system-wide
clean: check-compose ## Full cleanup (stop + remove project data)
	@echo "$(YELLOW)Warning: This will delete all server and client data!$(NC)"
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ]
	@$(DOCKER_COMPOSE) down -v --rmi local --remove-orphans 2>/dev/null || true
	@rm -rf config/ clients/
	@echo "$(GREEN)Cleanup complete$(NC)"

# FIX: update creates backup before updating
update: check-compose init-submodules ## Update submodules and rebuild (auto-backup)
	@echo "$(BLUE)Updating project...$(NC)"
	@echo "$(BLUE)Creating safety backup before update...$(NC)"
	@$(MAKE) backup 2>/dev/null || echo "$(YELLOW)Backup skipped (no data yet)$(NC)"
	@git submodule update --remote --recursive
	@$(DOCKER_COMPOSE) down 2>/dev/null || true
	@$(DOCKER_COMPOSE) build
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Update complete$(NC)"

backup: ## Create backup in backups/ folder
	@mkdir -p backups
	@BACKUP_FILE="backups/amneziawg-$$(date +%Y%m%d-%H%M%S).tar.gz"; \
	echo "$(BLUE)Creating backup...$(NC)"; \
	FILES=""; \
	[ -d config/ ] && FILES="$$FILES config/"; \
	[ -d clients/ ] && FILES="$$FILES clients/"; \
	[ -f .env ] && FILES="$$FILES .env"; \
	[ -f VERSION ] && FILES="$$FILES VERSION"; \
	[ -f docker-compose.yml ] && FILES="$$FILES docker-compose.yml"; \
	if [ -z "$$FILES" ]; then \
		echo "$(YELLOW)Nothing to backup$(NC)"; \
		exit 0; \
	fi; \
	tar -czf "$$BACKUP_FILE" $$FILES; \
	if [ -f "$$BACKUP_FILE" ] && tar -tzf "$$BACKUP_FILE" >/dev/null 2>&1; then \
		SIZE=$$(du -h "$$BACKUP_FILE" | cut -f1); \
		echo "$(GREEN)Backup created: $$BACKUP_FILE ($$SIZE)$(NC)"; \
	else \
		echo "$(RED)Backup failed or archive is corrupted$(NC)"; \
		rm -f "$$BACKUP_FILE"; \
		exit 1; \
	fi

backup-cleanup: ## Remove old backups (keep last 10)
	@echo "$(BLUE)Cleaning up old backups...$(NC)"
	@if [ -d backups ]; then \
		cd backups && \
		BACKUP_COUNT=$$(ls amneziawg-*.tar.gz 2>/dev/null | wc -l); \
		if [ $$BACKUP_COUNT -gt 10 ]; then \
			ls -t amneziawg-*.tar.gz | tail -n +11 | xargs rm -f; \
			echo "$(GREEN)Removed $$((BACKUP_COUNT - 10)) old backups$(NC)"; \
		else \
			echo "$(YELLOW)Backup count ($$BACKUP_COUNT) within limit$(NC)"; \
		fi; \
	else \
		echo "$(YELLOW)No backups directory$(NC)"; \
	fi

# FIX: restore creates safety backup before overwriting
restore: ## Restore from backup (file=PATH)
	@if [ -z "$(file)" ]; then \
		echo "$(RED)Error: Specify file path$(NC)"; \
		echo "$(YELLOW)Example: make restore file=backups/amneziawg-20240101-120000.tar.gz$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f "$(file)" ]; then \
		echo "$(RED)Error: File $(file) not found$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Validating archive...$(NC)"
	@tar -tzf $(file) >/dev/null 2>&1 || (echo "$(RED)Error: Archive is corrupted$(NC)" && exit 1)
	@echo "$(BLUE)Creating safety backup before restore...$(NC)"
	@$(MAKE) backup 2>/dev/null || echo "$(YELLOW)Safety backup skipped (no existing data)$(NC)"
	@echo "$(BLUE)Restoring from $(file)...$(NC)"
	@$(DOCKER_COMPOSE) down 2>/dev/null || true
	@tar -xzf $(file)
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Restore complete$(NC)"

backup-verify: ## Verify integrity of latest backup
	@LATEST=$$(ls -t backups/amneziawg-*.tar.gz 2>/dev/null | head -1); \
	if [ -z "$$LATEST" ]; then \
		echo "$(RED)No backups found$(NC)"; \
		exit 1; \
	fi; \
	echo "$(BLUE)Verifying: $$LATEST$(NC)"; \
	if tar -tzf "$$LATEST" >/dev/null 2>&1; then \
		echo "$(GREEN)Archive OK$(NC)"; \
		echo "$(CYAN)Contents:$(NC)"; \
		tar -tzf "$$LATEST" | head -20; \
	else \
		echo "$(RED)Archive CORRUPTED$(NC)"; \
		exit 1; \
	fi

backup-restart: ## Restart backup service
	@echo "$(BLUE)Restarting backup service...$(NC)"
	@mkdir -p backups
	@$(DOCKER_COMPOSE) restart backup 2>/dev/null || $(DOCKER_COMPOSE) up -d backup
	@echo "$(GREEN)Backup service restarted$(NC)"
	@echo "$(YELLOW)Interval: $${BACKUP_INTERVAL:-24h}, Keep: $${BACKUP_KEEP:-10} backups$(NC)"

backup-logs: ## View backup service logs
	@$(DOCKER_COMPOSE) logs -f backup

# FIX: test reads port from .env instead of hardcoded 51820
test: check-compose ## Test server connectivity
	@echo "$(BLUE)Testing AmneziaWG server...$(NC)"
	@echo ""
	@echo "$(CYAN)1. Container check:$(NC)"
	@if [ -n "$$(docker ps -q -f name=$(SERVICE_NAME) 2>/dev/null)" ]; then \
		echo "$(GREEN)  Container running$(NC)"; \
	else \
		echo "$(RED)  Container not running$(NC)"; \
	fi
	@echo ""
	@echo "$(CYAN)2. Interface check:$(NC)"
	@$(DOCKER_EXEC) ip link show awg0 >/dev/null 2>&1 && echo "$(GREEN)  Interface awg0 active$(NC)" || echo "$(RED)  Interface awg0 inactive$(NC)"
	@echo ""
	@echo "$(CYAN)3. Port check ($(AWG_PORT)/udp):$(NC)"
	@$(DOCKER_EXEC) ss -ulnp 2>/dev/null | grep -q ":$(AWG_PORT) " && echo "$(GREEN)  Port $(AWG_PORT) listening$(NC)" || echo "$(RED)  Port $(AWG_PORT) not listening$(NC)"

debug: check-compose ## Show debug information
	@echo "$(CYAN)Docker version:$(NC)"
	@docker --version
	@$(DOCKER_COMPOSE) version
	@echo ""
	@echo "$(CYAN)Container status:$(NC)"
	@$(DOCKER_COMPOSE) ps
	@echo ""
	@echo "$(CYAN)Recent logs:$(NC)"
	@$(DOCKER_LOGS) --tail=20 $(SERVICE_NAME) 2>/dev/null || echo "$(YELLOW)Logs not available$(NC)"
	@echo ""
	@echo "$(CYAN)Network interfaces:$(NC)"
	@$(DOCKER_EXEC) ip addr show 2>/dev/null || echo "Container not available"

# ============================================================================
# AUTOCOMPLETE
# ============================================================================

autocomplete-install: ## Install bash autocomplete
	@if [ ! -f "amneziawg-autocomplete.bash" ]; then \
		echo "$(RED)Error: amneziawg-autocomplete.bash not found$(NC)"; \
		exit 1; \
	fi
	@AUTOCOMPLETE_PATH="$$(readlink -f amneziawg-autocomplete.bash)"; \
	BASHRC_PATH="$$HOME/.bashrc"; \
	if grep -q "amneziawg-autocomplete.bash" "$$BASHRC_PATH" 2>/dev/null; then \
		echo "$(YELLOW)Autocomplete already installed$(NC)"; \
	else \
		echo "" >> "$$BASHRC_PATH"; \
		echo "# AmneziaWG Autocomplete" >> "$$BASHRC_PATH"; \
		echo "source \"$$AUTOCOMPLETE_PATH\"" >> "$$BASHRC_PATH"; \
		echo "$(GREEN)Autocomplete installed$(NC)"; \
		echo "$(YELLOW)Restart terminal or run: source $$BASHRC_PATH$(NC)"; \
	fi

autocomplete-remove: ## Remove bash autocomplete
	@BASHRC_PATH="$$HOME/.bashrc"; \
	if grep -q "amneziawg-autocomplete.bash" "$$BASHRC_PATH" 2>/dev/null; then \
		grep -v "amneziawg-autocomplete.bash" "$$BASHRC_PATH" | \
		grep -v "AmneziaWG Autocomplete" > "$$BASHRC_PATH.tmp"; \
		mv "$$BASHRC_PATH.tmp" "$$BASHRC_PATH"; \
		echo "$(GREEN)Autocomplete removed$(NC)"; \
	else \
		echo "$(YELLOW)Autocomplete not found$(NC)"; \
	fi

# Catch-all for positional arguments (client names, IPs)
# Only matches targets from ARGS to avoid silently swallowing typos
$(ARG1) $(ARG2):
	@:
