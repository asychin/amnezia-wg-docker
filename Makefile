# AmneziaWG Docker Server Makefile
# VPN server with DPI bypass capabilities

# Project settings
COMPOSE_FILE := docker-compose.yml
SERVICE_NAME := amneziawg-server
PROJECT_NAME := amnezia-wg-docker

# Docker commands
DOCKER_COMPOSE := docker compose
DOCKER_EXEC := docker exec $(SERVICE_NAME)
DOCKER_LOGS := docker logs

# Colors
BLUE := \033[34m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
CYAN := \033[36m
NC := \033[0m

# Get positional arguments (for simplified syntax like: make client-add john 10.13.13.5)
# Filter out known targets to get just the arguments
CLIENT_TARGETS := client-add client-rm client-qr client-config
ARGS := $(filter-out $(CLIENT_TARGETS),$(MAKECMDGOALS))
ARG1 := $(word 1,$(ARGS))
ARG2 := $(word 2,$(ARGS))

# Support both: make client-add john AND make client-add name=john
CLIENT_NAME := $(if $(name),$(name),$(ARG1))
CLIENT_IP := $(if $(ip),$(ip),$(ARG2))

# Helper functions
.PHONY: check-compose check-container check-client-name init-submodules check-autocomplete

check-compose:
	@$(DOCKER_COMPOSE) version > /dev/null 2>&1 || (echo "$(RED)Error: Docker Compose not installed$(NC)" && exit 1)

check-container:
	@if ! $(DOCKER_COMPOSE) ps | grep -q "$(SERVICE_NAME).*Up"; then \
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

check-autocomplete:
	@if ! grep -q "amneziawg-autocomplete.bash" "$$HOME/.bashrc" 2>/dev/null; then \
		echo "$(YELLOW)Tip: Autocomplete not configured. Install with: make autocomplete-install$(NC)"; \
		echo ""; \
	fi

init-submodules:
	@if [ ! -d "amneziawg-go/.git" ] || [ ! -d "amneziawg-tools/.git" ]; then \
		echo "$(YELLOW)Initializing git submodules...$(NC)"; \
		git submodule update --init --recursive; \
		echo "$(GREEN)Submodules initialized$(NC)"; \
	fi

# Generate random obfuscation parameters
generate-obfuscation:
	@AWG_JC=$$(shuf -i 3-10 -n 1); \
	AWG_JMIN=$$(shuf -i 40-80 -n 1); \
	AWG_JMAX=$$(shuf -i 500-1000 -n 1); \
	AWG_S1=$$(shuf -i 50-100 -n 1); \
	AWG_S2=$$(shuf -i 100-200 -n 1); \
	H_VALUES=$$(shuf -i 1-4 -n 4 | tr '\n' ' '); \
	AWG_H1=$$(echo $$H_VALUES | cut -d' ' -f1); \
	AWG_H2=$$(echo $$H_VALUES | cut -d' ' -f2); \
	AWG_H3=$$(echo $$H_VALUES | cut -d' ' -f3); \
	AWG_H4=$$(echo $$H_VALUES | cut -d' ' -f4); \
	sed -i "s/^AWG_JC=.*/AWG_JC=$$AWG_JC/" .env; \
	sed -i "s/^AWG_JMIN=.*/AWG_JMIN=$$AWG_JMIN/" .env; \
	sed -i "s/^AWG_JMAX=.*/AWG_JMAX=$$AWG_JMAX/" .env; \
	sed -i "s/^AWG_S1=.*/AWG_S1=$$AWG_S1/" .env; \
	sed -i "s/^AWG_S2=.*/AWG_S2=$$AWG_S2/" .env; \
	sed -i "s/^AWG_H1=.*/AWG_H1=$$AWG_H1/" .env; \
	sed -i "s/^AWG_H2=.*/AWG_H2=$$AWG_H2/" .env; \
	sed -i "s/^AWG_H3=.*/AWG_H3=$$AWG_H3/" .env; \
	sed -i "s/^AWG_H4=.*/AWG_H4=$$AWG_H4/" .env; \
	echo "$(GREEN)Generated random obfuscation parameters:$(NC)"; \
	echo "  Jc=$$AWG_JC Jmin=$$AWG_JMIN Jmax=$$AWG_JMAX"; \
	echo "  S1=$$AWG_S1 S2=$$AWG_S2"; \
	echo "  H1=$$AWG_H1 H2=$$AWG_H2 H3=$$AWG_H3 H4=$$AWG_H4"

# ============================================================================
# HELP
# ============================================================================

.PHONY: help
help: check-autocomplete ## Show this help
	@echo "$(CYAN)AmneziaWG Docker Server$(NC)"
	@echo ""
	@echo "$(CYAN)Main commands:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-18s$(NC) %s\n", $$1, $$2}' | \
		grep -E "^  (init|build|up|down|restart|status|logs) " | head -7
	@echo ""
	@echo "$(CYAN)Site-to-site VPN (access to server's local network):$(NC)"
	@echo "  $(GREEN)init-s2s$(NC)           Initialize for site-to-site VPN"
	@echo "  $(GREEN)up-s2s$(NC)             Start server (host network mode)"
	@echo "  $(GREEN)down-s2s$(NC)           Stop site-to-site server"
	@echo "  $(GREEN)status-s2s$(NC)         Show site-to-site server status"
	@echo ""
	@echo "$(CYAN)Client management:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-18s$(NC) %s\n", $$1, $$2}' | \
		grep -E "(client-)"
	@echo ""
	@echo "$(CYAN)Utilities:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-18s$(NC) %s\n", $$1, $$2}' | \
		grep -E "(shell|clean|update|backup|restore|debug|test)"
	@echo ""
	@echo "$(CYAN)Examples:$(NC)"
	@echo "  make up                      Start VPN server (standard)"
	@echo "  make up-s2s                  Start VPN server (site-to-site)"
	@echo "  make client-add john         Add client (simple)"
	@echo "  make client-add john 10.13.13.5  Add client with IP"
	@echo "  make client-qr john          Show QR code"
	@echo "  make backup                  Create backup"

# ============================================================================
# MAIN COMMANDS
# ============================================================================

.PHONY: init
init: check-compose init-submodules ## Initialize project (standard VPN mode)
	@echo "$(BLUE)Initializing project...$(NC)"
	@if [ ! -f ".env" ]; then \
		cp .env.example .env; \
		echo "$(GREEN).env file created$(NC)"; \
		$(MAKE) generate-obfuscation; \
	else \
		echo "$(YELLOW).env already exists$(NC)"; \
	fi
	@mkdir -p backups
	@echo "$(GREEN)Project initialized (standard mode)$(NC)"

.PHONY: init-s2s
init-s2s: check-compose init-submodules ## Initialize for site-to-site VPN (access to server's local network)
	@echo "$(BLUE)Initializing project for site-to-site VPN...$(NC)"
	@if [ -f ".env" ]; then \
		echo "$(YELLOW).env already exists. Remove it first or edit manually.$(NC)"; \
		exit 1; \
	fi
	@cp .env.example .env
	@echo "$(GREEN).env file created$(NC)"
	@$(MAKE) generate-obfuscation
	@echo ""
	@echo "$(CYAN)Site-to-site configuration:$(NC)"
	@read -p "Enter server's local network subnet (e.g., 192.168.1.0/24): " subnet; \
	if [ -n "$$subnet" ]; then \
		sed -i "s|^# SERVER_SUBNET=.*|SERVER_SUBNET=$$subnet|" .env; \
		sed -i "s|^ALLOWED_IPS=.*|ALLOWED_IPS=$$subnet,10.13.13.0/24|" .env; \
		echo "$(GREEN)SERVER_SUBNET=$$subnet$(NC)"; \
		echo "$(GREEN)ALLOWED_IPS=$$subnet,10.13.13.0/24$(NC)"; \
	else \
		echo "$(YELLOW)No subnet entered, using defaults$(NC)"; \
	fi
	@mkdir -p backups
	@echo ""
	@echo "$(GREEN)Project initialized for site-to-site mode$(NC)"
	@echo "$(YELLOW)Run 'make up' to start the server$(NC)"

.PHONY: build
build: check-compose init-submodules ## Build Docker image
	@echo "$(BLUE)Building Docker image...$(NC)"
	@if [ ! -f ".env" ]; then $(MAKE) init; fi
	@$(DOCKER_COMPOSE) build --no-cache
	@echo "$(GREEN)Build complete$(NC)"

.PHONY: up
up: check-compose init-submodules ## Start VPN server (bridge network)
	@echo "$(BLUE)Starting AmneziaWG server...$(NC)"
	@if [ ! -f ".env" ]; then $(MAKE) init; fi
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Server started$(NC)"
	@sleep 3
	@$(MAKE) status

.PHONY: up-s2s
up-s2s: check-compose init-submodules ## Start VPN server in site-to-site mode (host network)
	@echo "$(BLUE)Starting AmneziaWG server in site-to-site mode...$(NC)"
	@if [ ! -f ".env" ]; then $(MAKE) init-s2s; fi
	@docker compose -f docker-compose.s2s.yml up -d
	@echo "$(GREEN)Server started in site-to-site mode (host network)$(NC)"
	@sleep 3
	@$(MAKE) status-s2s

.PHONY: down-s2s
down-s2s: check-compose ## Stop site-to-site server
	@echo "$(BLUE)Stopping site-to-site server...$(NC)"
	@docker compose -f docker-compose.s2s.yml down
	@echo "$(GREEN)Server stopped$(NC)"

.PHONY: status-s2s
status-s2s: check-compose ## Show site-to-site server status
	@echo "$(CYAN)Container status (site-to-site mode):$(NC)"
	@docker compose -f docker-compose.s2s.yml ps || echo "$(RED)Container not running$(NC)"
	@echo ""
	@if docker compose -f docker-compose.s2s.yml ps | grep -q "Up"; then \
		echo "$(CYAN)AmneziaWG interface:$(NC)"; \
		$(DOCKER_EXEC) awg show awg0 2>/dev/null || echo "$(YELLOW)Interface not available$(NC)"; \
		echo ""; \
		echo "$(CYAN)Active connections:$(NC)"; \
		$(DOCKER_EXEC) awg show awg0 latest-handshakes 2>/dev/null || echo "$(YELLOW)No active connections$(NC)"; \
	fi

.PHONY: down
down: check-compose check-container ## Stop server
	@echo "$(BLUE)Stopping server...$(NC)"
	@$(DOCKER_COMPOSE) down
	@echo "$(GREEN)Server stopped$(NC)"

.PHONY: restart
restart: check-compose check-container ## Restart server
	@echo "$(BLUE)Restarting server...$(NC)"
	@$(DOCKER_COMPOSE) down
	@sleep 2
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Server restarted$(NC)"

.PHONY: logs
logs: check-compose check-container ## View logs (Ctrl+C to exit)
	@$(DOCKER_LOGS) -f $(SERVICE_NAME)

.PHONY: status
status: check-compose ## Show server status
	@echo "$(CYAN)Container status:$(NC)"
	@$(DOCKER_COMPOSE) ps || echo "$(RED)Container not running$(NC)"
	@echo ""
	@if $(DOCKER_COMPOSE) ps | grep -q "Up"; then \
		echo "$(CYAN)AmneziaWG interface:$(NC)"; \
		$(DOCKER_EXEC) awg show awg0 2>/dev/null || echo "$(YELLOW)Interface not available$(NC)"; \
		echo ""; \
		echo "$(CYAN)Active connections:$(NC)"; \
		$(DOCKER_EXEC) awg show awg0 latest-handshakes 2>/dev/null || echo "$(YELLOW)No active connections$(NC)"; \
	fi

# ============================================================================
# CLIENT MANAGEMENT
# ============================================================================

.PHONY: client-add
client-add: check-compose check-container check-client-name ## Add client: client-add <name> [ip]
	@if [ -z "$(CLIENT_IP)" ]; then \
		$(DOCKER_EXEC) /app/scripts/manage-clients.sh add $(CLIENT_NAME); \
	else \
		$(DOCKER_EXEC) /app/scripts/manage-clients.sh add $(CLIENT_NAME) $(CLIENT_IP); \
	fi
	@echo "$(GREEN)Client $(CLIENT_NAME) added$(NC)"

.PHONY: client-rm
client-rm: check-compose check-container check-client-name ## Remove client: client-rm <name>
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh remove $(CLIENT_NAME)
	@echo "$(GREEN)Client $(CLIENT_NAME) removed$(NC)"

.PHONY: client-qr
client-qr: check-compose check-container check-client-name ## Show QR code: client-qr <name>
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh qr $(CLIENT_NAME)

.PHONY: client-config
client-config: check-compose check-container check-client-name ## Show config: client-config <name>
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh show $(CLIENT_NAME)

.PHONY: client-list
client-list: check-compose check-container ## List all clients
	@$(DOCKER_EXEC) /app/scripts/manage-clients.sh list

# ============================================================================
# UTILITIES
# ============================================================================

.PHONY: shell
shell: check-compose check-container ## Enter container shell
	@docker exec -it $(SERVICE_NAME) /bin/bash

.PHONY: clean
clean: check-compose ## Full cleanup (stop + remove data)
	@echo "$(YELLOW)Warning: This will delete all server and client data!$(NC)"
	@read -p "Continue? [y/N]: " confirm && [ "$$confirm" = "y" ]
	@$(DOCKER_COMPOSE) down -v --remove-orphans 2>/dev/null || true
	@docker system prune -f
	@rm -rf config/ clients/
	@echo "$(GREEN)Cleanup complete$(NC)"

.PHONY: update
update: check-compose init-submodules ## Update submodules and rebuild
	@echo "$(BLUE)Updating project...$(NC)"
	@git submodule update --remote --recursive
	@$(DOCKER_COMPOSE) down 2>/dev/null || true
	@$(DOCKER_COMPOSE) build
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Update complete$(NC)"

.PHONY: backup
backup: ## Create backup in backups/ folder
	@mkdir -p backups
	@BACKUP_FILE="backups/amneziawg-$$(date +%Y%m%d-%H%M%S).tar.gz"; \
	echo "$(BLUE)Creating backup...$(NC)"; \
	tar -czf $$BACKUP_FILE config/ clients/ .env 2>/dev/null || true; \
	if [ -f "$$BACKUP_FILE" ]; then \
		echo "$(GREEN)Backup created: $$BACKUP_FILE$(NC)"; \
	else \
		echo "$(RED)Backup failed$(NC)"; \
	fi

.PHONY: backup-cleanup
backup-cleanup: ## Remove old backups (keep last 10)
	@echo "$(BLUE)Cleaning up old backups...$(NC)"
	@cd backups 2>/dev/null && \
		BACKUP_COUNT=$$(ls amneziawg-*.tar.gz 2>/dev/null | wc -l); \
		if [ $$BACKUP_COUNT -gt 10 ]; then \
			ls -t amneziawg-*.tar.gz | tail -n +11 | xargs rm -f; \
			echo "$(GREEN)Removed $$((BACKUP_COUNT - 10)) old backups$(NC)"; \
		else \
			echo "$(YELLOW)Backup count ($$BACKUP_COUNT) within limit$(NC)"; \
		fi

.PHONY: restore
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
	@echo "$(BLUE)Restoring from $(file)...$(NC)"
	@$(DOCKER_COMPOSE) down 2>/dev/null || true
	@tar -xzf $(file)
	@$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Restore complete$(NC)"

.PHONY: backup-start
backup-start: ## Start scheduled backup service
	@echo "$(BLUE)Starting backup service...$(NC)"
	@mkdir -p backups
	@$(DOCKER_COMPOSE) --profile backup up -d backup
	@echo "$(GREEN)Backup service started$(NC)"
	@echo "$(YELLOW)Interval: $${BACKUP_INTERVAL:-24h}, Keep: $${BACKUP_KEEP:-10} backups$(NC)"

.PHONY: backup-stop
backup-stop: ## Stop scheduled backup service
	@echo "$(BLUE)Stopping backup service...$(NC)"
	@$(DOCKER_COMPOSE) --profile backup stop backup 2>/dev/null || true
	@echo "$(GREEN)Backup service stopped$(NC)"

.PHONY: test
test: check-compose ## Test server connectivity
	@echo "$(BLUE)Testing AmneziaWG server...$(NC)"
	@echo ""
	@echo "$(CYAN)1. Container check:$(NC)"
	@$(DOCKER_COMPOSE) ps | grep $(SERVICE_NAME) | grep -q Up && echo "$(GREEN)Container running$(NC)" || echo "$(RED)Container not running$(NC)"
	@echo ""
	@echo "$(CYAN)2. Interface check:$(NC)"
	@$(DOCKER_EXEC) ip link show awg0 >/dev/null 2>&1 && echo "$(GREEN)Interface awg0 active$(NC)" || echo "$(RED)Interface awg0 inactive$(NC)"
	@echo ""
	@echo "$(CYAN)3. Port check:$(NC)"
	@$(DOCKER_EXEC) ss -ulnp 2>/dev/null | grep -q :51820 && echo "$(GREEN)Port 51820 listening$(NC)" || echo "$(RED)Port 51820 not listening$(NC)"

.PHONY: debug
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

.PHONY: autocomplete-install autocomplete-remove
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

# Catch-all target to allow positional arguments (prevents "No rule to make target" errors)
%:
	@:

# Default target
.DEFAULT_GOAL := help
