#!/bin/bash
# Start script for AmneziaWG Native S2S Mode
# Called by systemd service

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
AWG_PORT=${AWG_PORT:-51820}
AWG_NET=${AWG_NET:-10.13.13.0/24}
AWG_SERVER_IP=${AWG_SERVER_IP:-10.13.13.1}
SERVER_SUBNET=${SERVER_SUBNET:-}
OUT_INTERFACE=${OUT_INTERFACE:-}

# Get project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${PROJECT_DIR:-$(dirname "$SCRIPT_DIR")}"

CONFIG_FILE="$PROJECT_DIR/config/${AWG_INTERFACE}.conf"

log "=== Starting AmneziaWG S2S Server ==="
log "Interface: $AWG_INTERFACE"
log "Port: $AWG_PORT"
log "VPN Network: $AWG_NET"
log "Server IP: $AWG_SERVER_IP"
if [ -n "$SERVER_SUBNET" ]; then
    log "Server Subnet (S2S): $SERVER_SUBNET"
fi

# Determine output interface
if [ -z "$OUT_INTERFACE" ]; then
    OUT_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [ -z "$OUT_INTERFACE" ]; then
        OUT_INTERFACE="eth0"
    fi
fi
log "Output interface: $OUT_INTERFACE"

# Check if interface already exists
if ip link show ${AWG_INTERFACE} &>/dev/null; then
    warn "Interface ${AWG_INTERFACE} already exists, removing..."
    ip link del ${AWG_INTERFACE} 2>/dev/null || true
fi

# Clean up old socket
rm -f /var/run/amneziawg/${AWG_INTERFACE}.sock 2>/dev/null || true

# Check config file
if [ ! -f "$CONFIG_FILE" ]; then
    error "Config file not found: $CONFIG_FILE"
    error "Run 'make install-s2s' first"
    exit 1
fi

# Setup iptables rules
setup_iptables() {
    log "Setting up iptables rules..."
    
    # NAT for VPN clients to access internet
    if ! iptables -t nat -C POSTROUTING -s ${AWG_NET} -o $OUT_INTERFACE -j MASQUERADE 2>/dev/null; then
        iptables -t nat -A POSTROUTING -s ${AWG_NET} -o $OUT_INTERFACE -j MASQUERADE
        log "NAT rule added (VPN -> internet)"
    fi
    
    # Site-to-site: NAT for VPN clients to access local network
    if [ -n "$SERVER_SUBNET" ]; then
        if ! iptables -t nat -C POSTROUTING -s ${AWG_NET} -d ${SERVER_SUBNET} -j MASQUERADE 2>/dev/null; then
            iptables -t nat -A POSTROUTING -s ${AWG_NET} -d ${SERVER_SUBNET} -j MASQUERADE
            log "NAT rule added (VPN -> local network $SERVER_SUBNET)"
        fi
        
        # Forward rules for S2S traffic
        if ! iptables -C FORWARD -s ${AWG_NET} -d ${SERVER_SUBNET} -j ACCEPT 2>/dev/null; then
            iptables -A FORWARD -s ${AWG_NET} -d ${SERVER_SUBNET} -j ACCEPT
            log "FORWARD rule added (VPN -> local network)"
        fi
        
        if ! iptables -C FORWARD -s ${SERVER_SUBNET} -d ${AWG_NET} -j ACCEPT 2>/dev/null; then
            iptables -A FORWARD -s ${SERVER_SUBNET} -d ${AWG_NET} -j ACCEPT
            log "FORWARD rule added (local network -> VPN)"
        fi
    fi
    
    # Forward rules for VPN interface
    if ! iptables -C FORWARD -i ${AWG_INTERFACE} -j ACCEPT 2>/dev/null; then
        iptables -A FORWARD -i ${AWG_INTERFACE} -j ACCEPT
        log "FORWARD rule added (incoming)"
    fi
    
    if ! iptables -C FORWARD -o ${AWG_INTERFACE} -j ACCEPT 2>/dev/null; then
        iptables -A FORWARD -o ${AWG_INTERFACE} -j ACCEPT
        log "FORWARD rule added (outgoing)"
    fi
    
    # MSS clamping to prevent PMTUD Black Hole
    if ! iptables -t mangle -C FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu 2>/dev/null; then
        iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
        log "MSS clamping rule added"
    fi
    
    log "iptables setup complete"
}

# Start amneziawg-go
start_interface() {
    log "Starting amneziawg-go for interface ${AWG_INTERFACE}..."
    
    # Start amneziawg-go in background
    export WG_PROCESS_FOREGROUND=1
    amneziawg-go ${AWG_INTERFACE} &
    AWG_PID=$!
    
    # Save PID
    mkdir -p /var/run/amneziawg
    echo $AWG_PID > /var/run/amneziawg/${AWG_INTERFACE}.pid
    
    # Wait for interface to be created
    sleep 3
    
    # Check if process is running and interface exists
    if ! kill -0 $AWG_PID 2>/dev/null; then
        error "amneziawg-go process failed to start"
        exit 1
    fi
    
    if ! ip link show ${AWG_INTERFACE} &>/dev/null; then
        error "Interface ${AWG_INTERFACE} was not created"
        exit 1
    fi
    
    log "amneziawg-go started (PID: $AWG_PID)"
    
    # Configure interface
    log "Configuring interface..."
    
    # Apply configuration
    awg setconf ${AWG_INTERFACE} ${CONFIG_FILE}
    
    # Bring up interface and assign IP
    ip link set ${AWG_INTERFACE} up
    ip addr add ${AWG_SERVER_IP}/${AWG_NET##*/} dev ${AWG_INTERFACE} 2>/dev/null || true
    
    # Set MTU to prevent fragmentation issues
    ip link set ${AWG_INTERFACE} mtu 1280
    
    log "Interface ${AWG_INTERFACE} configured"
}

# Cleanup function
cleanup() {
    log "Received shutdown signal..."
    
    # Stop amneziawg-go
    if [ -f /var/run/amneziawg/${AWG_INTERFACE}.pid ]; then
        AWG_PID=$(cat /var/run/amneziawg/${AWG_INTERFACE}.pid)
        if kill -0 $AWG_PID 2>/dev/null; then
            log "Stopping amneziawg-go (PID: $AWG_PID)..."
            kill $AWG_PID
        fi
        rm -f /var/run/amneziawg/${AWG_INTERFACE}.pid
    fi
    
    # Remove socket
    rm -f /var/run/amneziawg/${AWG_INTERFACE}.sock 2>/dev/null || true
    
    # Remove interface
    if ip link show ${AWG_INTERFACE} &>/dev/null; then
        log "Removing interface ${AWG_INTERFACE}..."
        ip link del ${AWG_INTERFACE} 2>/dev/null || true
    fi
    
    log "Cleanup complete"
    exit 0
}

# Handle signals
trap cleanup SIGTERM SIGINT

# Main
main() {
    # Setup iptables
    setup_iptables
    
    # Start interface
    start_interface
    
    log "=== AmneziaWG S2S Server Started ==="
    awg show ${AWG_INTERFACE} 2>/dev/null || true
    
    # Keep running and monitor
    while true; do
        sleep 30
        
        # Check if process is still running
        if [ -f /var/run/amneziawg/${AWG_INTERFACE}.pid ]; then
            AWG_PID=$(cat /var/run/amneziawg/${AWG_INTERFACE}.pid)
            if ! kill -0 $AWG_PID 2>/dev/null; then
                warn "amneziawg-go process died, restarting..."
                start_interface
            fi
        else
            warn "PID file not found, restarting..."
            start_interface
        fi
    done
}

main "$@"
