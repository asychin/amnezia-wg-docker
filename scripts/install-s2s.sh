#!/bin/bash
# Native S2S Installation Script for AmneziaWG
# Installs AmneziaWG directly on the host system (without Docker)
# This avoids Docker iptables conflicts that cause connection drops in S2S mode

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"; }
error() { echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"; }

# Check root
if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root"
    exit 1
fi

# Get script directory (where the project is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

log "Project directory: $PROJECT_DIR"

# Load .env file
if [ -f "$PROJECT_DIR/.env" ]; then
    log "Loading configuration from .env..."
    set -a
    source "$PROJECT_DIR/.env"
    set +a
else
    error ".env file not found. Run 'make init-s2s' first."
    exit 1
fi

# Configuration from .env
AWG_INTERFACE=${AWG_INTERFACE:-awg0}
AWG_PORT=${AWG_PORT:-51820}
AWG_NET=${AWG_NET:-10.13.13.0/24}
AWG_SERVER_IP=${AWG_SERVER_IP:-10.13.13.1}
AWG_DNS=${AWG_DNS:-8.8.8.8,8.8.4.4}
AWG_JC=${AWG_JC:-7}
AWG_JMIN=${AWG_JMIN:-50}
AWG_JMAX=${AWG_JMAX:-1000}
AWG_S1=${AWG_S1:-86}
AWG_S2=${AWG_S2:-574}
AWG_H1=${AWG_H1:-991285757}
AWG_H2=${AWG_H2:-1439803238}
AWG_H3=${AWG_H3:-2097387803}
AWG_H4=${AWG_H4:-863921769}
SERVER_SUBNET=${SERVER_SUBNET:-}
SERVER_INTERFACE=${SERVER_INTERFACE:-}

log "=== AmneziaWG Native S2S Installation ==="
log "Interface: $AWG_INTERFACE"
log "Port: $AWG_PORT"
log "VPN Network: $AWG_NET"
log "Server IP: $AWG_SERVER_IP"
if [ -n "$SERVER_SUBNET" ]; then
    log "Server Subnet (S2S): $SERVER_SUBNET"
fi

# Check if amneziawg-go is installed
check_amneziawg_installed() {
    if command -v amneziawg-go &>/dev/null && command -v awg &>/dev/null; then
        log "AmneziaWG tools already installed"
        return 0
    fi
    return 1
}

# Install AmneziaWG from source
install_amneziawg() {
    log "Installing AmneziaWG tools..."
    
    # Check for Go
    if ! command -v go &>/dev/null; then
        log "Installing Go..."
        apt-get update
        apt-get install -y golang-go
    fi
    
    # Check Go version
    GO_VERSION=$(go version | grep -oP 'go\d+\.\d+' | head -1)
    log "Go version: $GO_VERSION"
    
    # Install dependencies
    log "Installing dependencies..."
    apt-get update
    apt-get install -y git make gcc qrencode iptables iproute2
    
    # Build amneziawg-go from submodule
    if [ -d "$PROJECT_DIR/amneziawg-go" ]; then
        log "Building amneziawg-go from submodule..."
        cd "$PROJECT_DIR/amneziawg-go"
        make
        cp amneziawg-go /usr/local/bin/
        chmod +x /usr/local/bin/amneziawg-go
        log "amneziawg-go installed to /usr/local/bin/"
    else
        error "amneziawg-go submodule not found. Run 'git submodule update --init --recursive'"
        exit 1
    fi
    
    # Build amneziawg-tools from submodule
    if [ -d "$PROJECT_DIR/amneziawg-tools" ]; then
        log "Building amneziawg-tools from submodule..."
        cd "$PROJECT_DIR/amneziawg-tools/src"
        make
        make install
        log "awg tools installed"
    else
        error "amneziawg-tools submodule not found. Run 'git submodule update --init --recursive'"
        exit 1
    fi
    
    cd "$PROJECT_DIR"
}

# Generate server keys if not exist
generate_keys() {
    log "Checking server keys..."
    
    mkdir -p "$PROJECT_DIR/config"
    chmod 750 "$PROJECT_DIR/config"
    
    if [ ! -f "$PROJECT_DIR/config/server_private.key" ]; then
        log "Generating server private key..."
        awg genkey > "$PROJECT_DIR/config/server_private.key"
        chmod 600 "$PROJECT_DIR/config/server_private.key"
    fi
    
    if [ ! -f "$PROJECT_DIR/config/server_public.key" ]; then
        log "Generating server public key..."
        awg pubkey < "$PROJECT_DIR/config/server_private.key" > "$PROJECT_DIR/config/server_public.key"
    fi
    
    SERVER_PRIVATE_KEY=$(cat "$PROJECT_DIR/config/server_private.key" | tr -d '\n')
    SERVER_PUBLIC_KEY=$(cat "$PROJECT_DIR/config/server_public.key" | tr -d '\n')
    
    log "Server keys ready"
}

# Get public IP
get_public_ip() {
    if [ "$SERVER_PUBLIC_IP" = "auto" ] || [ -z "$SERVER_PUBLIC_IP" ]; then
        log "Detecting public IP..."
        
        # Try ip route first
        local_ip=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || true)
        if [ -n "$local_ip" ] && ! echo "$local_ip" | grep -qE '^(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.|127\.)'; then
            SERVER_PUBLIC_IP="$local_ip"
            log "Public IP detected via route: $SERVER_PUBLIC_IP"
            return
        fi
        
        # Try external services
        for service in "http://eth0.me" "https://ipv4.icanhazip.com" "https://api.ipify.org"; do
            ip=$(curl -4 -s --connect-timeout 5 "$service" 2>/dev/null | tr -d '[:space:]')
            if echo "$ip" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'; then
                SERVER_PUBLIC_IP="$ip"
                log "Public IP detected via $service: $SERVER_PUBLIC_IP"
                return
            fi
        done
        
        error "Could not detect public IP. Set SERVER_PUBLIC_IP in .env"
        exit 1
    else
        log "Using configured public IP: $SERVER_PUBLIC_IP"
    fi
}

# Create server configuration
create_server_config() {
    log "Creating server configuration..."
    
    CONFIG_FILE="$PROJECT_DIR/config/${AWG_INTERFACE}.conf"
    
    cat > "$CONFIG_FILE" << EOF
[Interface]
ListenPort = ${AWG_PORT}
PrivateKey = ${SERVER_PRIVATE_KEY}

# AmneziaWG obfuscation parameters
Jc = ${AWG_JC}
Jmin = ${AWG_JMIN}
Jmax = ${AWG_JMAX}
S1 = ${AWG_S1}
S2 = ${AWG_S2}
H1 = ${AWG_H1}
H2 = ${AWG_H2}
H3 = ${AWG_H3}
H4 = ${AWG_H4}

EOF
    
    # Add existing clients
    if [ -d "$PROJECT_DIR/clients" ]; then
        for client_file in "$PROJECT_DIR/clients"/*.conf; do
            if [ -f "$client_file" ]; then
                client_name=$(basename "$client_file" .conf)
                public_key_file="$PROJECT_DIR/clients/${client_name}_public.key"
                
                if [ -f "$public_key_file" ]; then
                    public_key=$(cat "$public_key_file")
                    client_ip=$(grep "^Address" "$client_file" | cut -d'=' -f2 | tr -d ' ' | cut -d'/' -f1)
                    
                    cat >> "$CONFIG_FILE" << EOF

[Peer]
# ${client_name}
PublicKey = ${public_key}
AllowedIPs = ${client_ip}/32
EOF
                    log "Added client: $client_name ($client_ip)"
                fi
            fi
        done
    fi
    
    log "Server configuration created: $CONFIG_FILE"
}

# Create systemd service
create_systemd_service() {
    log "Creating systemd service..."
    
    # Determine output interface for NAT
    OUT_INTERFACE="${SERVER_INTERFACE:-}"
    if [ -z "$OUT_INTERFACE" ]; then
        OUT_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
        if [ -z "$OUT_INTERFACE" ]; then
            OUT_INTERFACE="eth0"
        fi
    fi
    
    cat > /etc/systemd/system/amneziawg-s2s.service << EOF
[Unit]
Description=AmneziaWG S2S VPN Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment=WG_PROCESS_FOREGROUND=1
Environment=AWG_INTERFACE=${AWG_INTERFACE}
Environment=AWG_PORT=${AWG_PORT}
Environment=AWG_NET=${AWG_NET}
Environment=AWG_SERVER_IP=${AWG_SERVER_IP}
Environment=SERVER_SUBNET=${SERVER_SUBNET}
Environment=OUT_INTERFACE=${OUT_INTERFACE}
Environment=PROJECT_DIR=${PROJECT_DIR}

ExecStartPre=/bin/bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
ExecStartPre=/bin/bash -c 'echo 1 > /proc/sys/net/ipv4/conf/all/src_valid_mark'
ExecStart=${PROJECT_DIR}/scripts/start-s2s.sh
ExecStop=${PROJECT_DIR}/scripts/stop-s2s.sh

Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    
    log "Systemd service created: /etc/systemd/system/amneziawg-s2s.service"
    
    # Reload systemd
    systemctl daemon-reload
    log "Systemd daemon reloaded"
}

# Enable IP forwarding permanently
enable_ip_forwarding() {
    log "Enabling IP forwarding..."
    
    # Enable now
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo 1 > /proc/sys/net/ipv4/conf/all/src_valid_mark
    
    # Make permanent
    if ! grep -q "net.ipv4.ip_forward=1" /etc/sysctl.conf; then
        echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    fi
    if ! grep -q "net.ipv4.conf.all.src_valid_mark=1" /etc/sysctl.conf; then
        echo "net.ipv4.conf.all.src_valid_mark=1" >> /etc/sysctl.conf
    fi
    
    sysctl -p >/dev/null 2>&1 || true
    log "IP forwarding enabled"
}

# Main installation
main() {
    log "Starting native S2S installation..."
    
    # Check and install AmneziaWG
    if ! check_amneziawg_installed; then
        install_amneziawg
    fi
    
    # Generate keys
    generate_keys
    
    # Get public IP
    get_public_ip
    
    # Create server config
    create_server_config
    
    # Enable IP forwarding
    enable_ip_forwarding
    
    # Create systemd service
    create_systemd_service
    
    log ""
    log "=== Installation Complete ==="
    log ""
    log "To start the S2S VPN server:"
    log "  sudo systemctl start amneziawg-s2s"
    log ""
    log "To enable auto-start on boot:"
    log "  sudo systemctl enable amneziawg-s2s"
    log ""
    log "To check status:"
    log "  sudo systemctl status amneziawg-s2s"
    log "  awg show ${AWG_INTERFACE}"
    log ""
    log "To add clients, use:"
    log "  make client-add <name>"
    log ""
    if [ -n "$SERVER_SUBNET" ]; then
        log "S2S Mode: Clients will have access to $SERVER_SUBNET"
    fi
}

main "$@"
