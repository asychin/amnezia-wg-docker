#!/bin/bash
# Stop script for AmneziaWG Native S2S Mode
# Called by systemd service on stop

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"; }
error() { echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"; }

# Get configuration from environment or defaults
AWG_INTERFACE=${AWG_INTERFACE:-awg0}
AWG_NET=${AWG_NET:-10.13.13.0/24}
SERVER_SUBNET=${SERVER_SUBNET:-}
OUT_INTERFACE=${OUT_INTERFACE:-}

log "=== Stopping AmneziaWG S2S Server ==="

# Determine output interface
if [ -z "$OUT_INTERFACE" ]; then
    OUT_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [ -z "$OUT_INTERFACE" ]; then
        OUT_INTERFACE="eth0"
    fi
fi

# Stop amneziawg-go process
if [ -f /var/run/amneziawg/${AWG_INTERFACE}.pid ]; then
    AWG_PID=$(cat /var/run/amneziawg/${AWG_INTERFACE}.pid)
    if kill -0 $AWG_PID 2>/dev/null; then
        log "Stopping amneziawg-go (PID: $AWG_PID)..."
        kill $AWG_PID 2>/dev/null || true
        sleep 2
        # Force kill if still running
        if kill -0 $AWG_PID 2>/dev/null; then
            warn "Process still running, force killing..."
            kill -9 $AWG_PID 2>/dev/null || true
        fi
    fi
    rm -f /var/run/amneziawg/${AWG_INTERFACE}.pid
    log "Process stopped"
else
    warn "PID file not found"
fi

# Remove socket
rm -f /var/run/amneziawg/${AWG_INTERFACE}.sock 2>/dev/null || true

# Remove interface
if ip link show ${AWG_INTERFACE} &>/dev/null; then
    log "Removing interface ${AWG_INTERFACE}..."
    ip link del ${AWG_INTERFACE} 2>/dev/null || true
    log "Interface removed"
else
    warn "Interface ${AWG_INTERFACE} not found"
fi

# Clean up iptables rules (optional - comment out if you want to keep rules)
cleanup_iptables() {
    log "Cleaning up iptables rules..."
    
    # Remove NAT rule
    iptables -t nat -D POSTROUTING -s ${AWG_NET} -o $OUT_INTERFACE -j MASQUERADE 2>/dev/null || true
    
    # Remove S2S NAT rule
    if [ -n "$SERVER_SUBNET" ]; then
        iptables -t nat -D POSTROUTING -s ${AWG_NET} -d ${SERVER_SUBNET} -j MASQUERADE 2>/dev/null || true
        iptables -D FORWARD -s ${AWG_NET} -d ${SERVER_SUBNET} -j ACCEPT 2>/dev/null || true
        iptables -D FORWARD -s ${SERVER_SUBNET} -d ${AWG_NET} -j ACCEPT 2>/dev/null || true
    fi
    
    # Remove forward rules
    iptables -D FORWARD -i ${AWG_INTERFACE} -j ACCEPT 2>/dev/null || true
    iptables -D FORWARD -o ${AWG_INTERFACE} -j ACCEPT 2>/dev/null || true
    
    # Note: We don't remove MSS clamping rule as it might be used by other services
    
    log "iptables cleanup complete"
}

# Uncomment to clean up iptables on stop
# cleanup_iptables

log "=== AmneziaWG S2S Server Stopped ==="
exit 0
