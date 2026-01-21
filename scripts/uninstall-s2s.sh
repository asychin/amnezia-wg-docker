#!/bin/bash
# Uninstall script for AmneziaWG Native S2S Mode
# Removes systemd service and cleans up

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"; }
error() { echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"; }

# Check root
if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env for configuration
AWG_INTERFACE=${AWG_INTERFACE:-awg0}
if [ -f "$PROJECT_DIR/.env" ]; then
    set -a
    source "$PROJECT_DIR/.env"
    set +a
fi

log "=== Uninstalling AmneziaWG Native S2S ==="

# Stop and disable systemd service
if systemctl is-active --quiet amneziawg-s2s 2>/dev/null; then
    log "Stopping amneziawg-s2s service..."
    systemctl stop amneziawg-s2s
fi

if systemctl is-enabled --quiet amneziawg-s2s 2>/dev/null; then
    log "Disabling amneziawg-s2s service..."
    systemctl disable amneziawg-s2s
fi

# Remove systemd service file
if [ -f /etc/systemd/system/amneziawg-s2s.service ]; then
    log "Removing systemd service file..."
    rm -f /etc/systemd/system/amneziawg-s2s.service
    systemctl daemon-reload
    log "Systemd service removed"
else
    warn "Systemd service file not found"
fi

# Stop any running amneziawg-go process
if [ -f /var/run/amneziawg/${AWG_INTERFACE}.pid ]; then
    AWG_PID=$(cat /var/run/amneziawg/${AWG_INTERFACE}.pid)
    if kill -0 $AWG_PID 2>/dev/null; then
        log "Stopping amneziawg-go process..."
        kill $AWG_PID 2>/dev/null || true
        sleep 2
    fi
    rm -f /var/run/amneziawg/${AWG_INTERFACE}.pid
fi

# Remove socket
rm -f /var/run/amneziawg/${AWG_INTERFACE}.sock 2>/dev/null || true

# Remove interface if exists
if ip link show ${AWG_INTERFACE} &>/dev/null; then
    log "Removing interface ${AWG_INTERFACE}..."
    ip link del ${AWG_INTERFACE} 2>/dev/null || true
fi

# Clean up PID directory
rmdir /var/run/amneziawg 2>/dev/null || true

log ""
log "=== Uninstallation Complete ==="
log ""
log "Note: The following were NOT removed:"
log "  - AmneziaWG binaries (/usr/local/bin/amneziawg-go, awg)"
log "  - Configuration files ($PROJECT_DIR/config/)"
log "  - Client files ($PROJECT_DIR/clients/)"
log "  - IP forwarding settings in /etc/sysctl.conf"
log ""
log "To remove binaries manually:"
log "  rm -f /usr/local/bin/amneziawg-go"
log "  rm -f /usr/local/bin/awg"
log ""
log "You can still use Docker mode with 'make up' or 'make up-s2s'"
