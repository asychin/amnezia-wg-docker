# 🔒 AmneziaWG Docker Server - Complete Guide

<div align="center">

**Production-ready Docker solution for AmneziaWG VPN server with DPI bypass capabilities**

[![GitHub Release](https://img.shields.io/github/v/release/asychin/amnezia-wg-docker?style=flat-square&logo=github)](../../releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/asychin/amnezia-wg-docker?style=flat-square&logo=docker)](https://hub.docker.com/r/asychin/amnezia-wg-docker)
[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-asychin/amnezia--wg--docker-blue?style=flat-square&logo=docker)](../../pkgs/container/amnezia-wg-docker)
[![GitHub Stars](https://img.shields.io/github/stars/asychin/amnezia-wg-docker?style=flat-square&logo=github)](../../stargazers)

> 🍴 **Forked this repository?** Update the badges above by replacing `asychin/amnezia-wg-docker` with `yourusername/amnezia-wg-docker` in documentation files.

**🌍 Languages: [🇺🇸 English](../en/README.md) | [🇷🇺 Русский](../ru/README.md) | [🇨🇳 中文](../zh/README.md)**

</div>

---

## 🌟 Features

- ✅ **AmneziaWG Userspace** - Works without kernel modules
- ✅ **DPI Bypass** - Camouflages VPN traffic as HTTPS
- ✅ **Docker Container** - Simple deployment
- ✅ **Auto IP Detection** - Smart public IP discovery through 8 services
- ✅ **Automatic Setup** - iptables, routing, DNS configuration
- ✅ **QR Codes** - Quick client connection
- ✅ **Client Management** - Add/remove via Makefile
- ✅ **Monitoring** - Logs and connection status

---

## 🚀 Quick Start

### 1. Clone with Submodules

```bash
git clone --recursive https://github.com/asychin/amnezia-wg-docker.git
cd amnezia-wg-docker

# If you forgot --recursive:
git submodule update --init --recursive
```

### 2. Start Server

```bash
# Build and start
make build
make up

# Check status
make status
```

### 3. Get Client Configuration

```bash
# Show QR code for the first client
make client-qr client1

# Create new client
make client-add name=myclient ip=10.13.13.10
```

---

## 📋 Requirements

- **Docker** >= 20.10
- **Docker Compose** >= 1.29
- **Linux** host with TUN/TAP support
- **Privileged mode** or access to `/dev/net/tun`

### ⚠️ Important: TUN Device

AmneziaWG requires access to the TUN interface. Make sure:

1. **TUN module is loaded:**
   ```bash
   # Check module
   lsmod | grep tun
   
   # Load if needed
   sudo modprobe tun
   ```

2. **TUN device exists:**
   ```bash
   # Check device
   ls -la /dev/net/tun
   
   # Create if needed
   sudo mkdir -p /dev/net
   sudo mknod /dev/net/tun c 10 200
   sudo chmod 666 /dev/net/tun
   ```

3. **Docker runs with correct flags** (see deployment section)

### Docker Installation (Ubuntu/Debian)

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify installation
docker --version
docker-compose --version
```

---

## ⚙️ Configuration

### Environment Variables (.env)

Create `.env` file or edit `env.example`:

```bash
# Main settings
AWG_INTERFACE=awg0
AWG_PORT=51820
AWG_NET=10.13.13.0/24
AWG_SERVER_IP=10.13.13.1
AWG_DNS=8.8.8.8,8.8.4.4

# Public IP (auto-detected if not specified)
# SERVER_PUBLIC_IP=YOUR_SERVER_IP

# Client settings
CLIENTS_SUBNET=10.13.13.0/24
ALLOWED_IPS=0.0.0.0/0

# AmneziaWG obfuscation parameters for DPI bypass
AWG_JC=7
AWG_JMIN=50
AWG_JMAX=1000
AWG_S1=86
AWG_S2=574
AWG_H1=1
AWG_H2=2
AWG_H3=3
AWG_H4=4

# Additional settings
# AWG_DISABLE_IPTABLES=true  # Disable iptables (for CI/CD or restricted environments)
```

### Obfuscation Parameters Setup

Obfuscation parameters disguise VPN traffic as regular HTTPS:

- **Jc** (7) - Jitter intensity
- **Jmin/Jmax** (50/1000) - Min/max size of "junk" packets
- **S1/S2** (86/574) - Header sizes for masking
- **H1-H4** (1/2/3/4) - Hash functions for obfuscation

---

## 🛠️ Management

### Makefile Commands

```bash
# Basic commands
make build          # Build container
make up             # Start server
make down           # Stop server
make restart        # Restart
make logs           # View logs
make status         # Server and connection status

# Client management
make client-add name=client2 ip=10.13.13.3   # Add client
make client-rm name=client2                   # Remove client
make client-qr name=client1                   # Show QR code
make client-list                              # List clients

# Debugging
make shell          # Enter container
make clean          # Cleanup (stop + remove data)
```

### Manual Client Management

```bash
# Enter container
docker-compose exec amneziawg-server bash

# Add client
/app/scripts/manage-clients.sh add myclient 10.13.13.5

# Remove client
/app/scripts/manage-clients.sh remove myclient

# Show status
awg show awg0
```

### 🚀 Bash Autocomplete

For convenience, autocomplete for make commands is included:

```bash
# Load in current session
source amneziawg-autocomplete.bash

# Install permanently
echo "source $(pwd)/amneziawg-autocomplete.bash" >> ~/.bashrc
```

**Features:**
- 🎯 Autocompletion for all `make` commands
- 👥 Client names and IP addresses
- 🚀 Quick functions: `awg_add_client`, `awg_qr`, `awg_status`

```bash
# Examples (press TAB)
make client-add name=<TAB>     # Client names
make client-qr name=<TAB>      # Existing clients
awg_add_client mobile          # Quick add
awg_help                       # Autocomplete help
```

---

## 🚀 Deployment

### Method 1: Docker Compose (Recommended)

```bash
# Quick start with docker-compose
make build && make up

# Check status
make status
```

Docker Compose is already configured with correct parameters in `docker-compose.yml`:
- `privileged: true` - Full container privileges
- `devices: - /dev/net/tun` - Access to TUN device
- `cap_add: [NET_ADMIN, SYS_MODULE]` - Network capabilities

### Method 2: Docker Run (Manual)

```bash
# Build image
docker build -t amneziawg-server .

# Run with necessary privileges
docker run -d \
  --name amneziawg-server \
  --privileged \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --device=/dev/net/tun \
  --sysctl net.ipv4.ip_forward=1 \
  -p 51820:51820/udp \
  -v $(pwd)/config:/app/config \
  -v $(pwd)/clients:/app/clients \
  -e SERVER_PUBLIC_IP=YOUR_SERVER_IP \
  amneziawg-server
```

### Method 3: Cloud Providers

For **VPS/VDS** servers (DigitalOcean, Vultr, Hetzner, etc.):

```bash
# Ensure TUN module is available
lsmod | grep tun || sudo modprobe tun

# Create TUN device if needed
sudo mkdir -p /dev/net
sudo mknod /dev/net/tun c 10 200
sudo chmod 666 /dev/net/tun

# Launch as usual
make build && make up
```

### ⚠️ TUN Troubleshooting

If you get error `CreateTUN("awg0") failed; /dev/net/tun does not exist`:

1. **Check TUN availability on host:**
   ```bash
   ls -la /dev/net/tun
   cat /dev/net/tun  # should return "cat: /dev/net/tun: File descriptor in bad state"
   ```

2. **For Docker without privileges (not recommended):**
   ```bash
   # Add to docker-compose.yml or docker run:
   --cap-add=NET_ADMIN --device=/dev/net/tun
   ```

3. **For Podman or other runtimes:**
   ```bash
   # Use similar flags with your runtime
   podman run --privileged --device=/dev/net/tun ...
   ```

---

## 📱 Client Connection

### Android/iOS (AmneziaVPN)

1. Install [AmneziaVPN](https://amnezia.org/)
2. Get QR code: `make client-qr name=client1`
3. Scan QR code in the app
4. Connect!

### Desktop (AmneziaWG Client)

1. Download configuration:
   ```bash
   docker-compose exec amneziawg-server cat /app/clients/client1.conf > client1.conf
   ```
2. Use with compatible client

### Example Client Configuration

```ini
[Interface]
PrivateKey = <client_private_key>
Address = 10.13.13.2/32
DNS = 8.8.8.8

[Peer]
PublicKey = <server_public_key>
Endpoint = 203.0.113.123:51820        # Auto-detected IP
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25

# AmneziaWG obfuscation parameters
Jc = 7
Jmin = 50
Jmax = 1000
S1 = 86
S2 = 574
H1 = 1
H2 = 2
H3 = 3
H4 = 4
```

---

## 🔧 Architecture

### Components

```
┌─────────────────────────────────────────┐
│             Docker Container            │
│  ┌─────────────────────────────────────┐ │
│  │         amneziawg-go               │ │  ← Userspace VPN
│  │         (Process PID)               │ │
│  └─────────────────────────────────────┘ │
│  ┌─────────────────────────────────────┐ │
│  │         amneziawg-tools            │ │  ← Management utils
│  │         (awg, awg-quick)           │ │
│  └─────────────────────────────────────┘ │
│  ┌─────────────────────────────────────┐ │
│  │         iptables rules             │ │  ← NAT and firewall
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
              │
              │ 51820/UDP
              ▼
        [ Internet ]
              │
              ▼
     [ VPN Clients ]
```

### Network Diagram

```
Client (10.13.13.2) ──┐
                       │
Client (10.13.13.3) ──┤
                       │    VPN Tunnel      ┌─ Internet
                       ├────────────────────┤
Client (10.13.13.4) ──┤                    └─ Websites/Services
                       │
Client (10.13.13.5) ──┘
                 
        VPN Network: 10.13.13.0/24
        Server: 10.13.13.1
        Port: 51820/UDP
```

---

## 🌐 Automatic Public IP Detection

### Smart External IP Address Discovery

The system automatically determines the server's public IP address for creating correct client configurations. This solves the problem of non-working VPN when deploying in the cloud or behind NAT.

### Supported Services

Auto-detection uses reliable external services in priority order:

1. **https://eth0.me** - Fast and reliable service
2. **https://ipv4.icanhazip.com** - Popular backup service
3. **https://api.ipify.org** - JSON API for IP detection
4. **https://checkip.amazonaws.com** - Official AWS service
5. **https://ipinfo.io/ip** - Detailed geo-information
6. **https://ifconfig.me/ip** - Classic Unix service
7. **http://whatismyip.akamai.com** - From CDN provider Akamai
8. **http://i.pn** - Minimalist and fast

### Configuration

```bash
# In .env file set one of the values:

# 1. Auto-detection (recommended)
SERVER_PUBLIC_IP=auto

# 2. Specific IP address
SERVER_PUBLIC_IP=203.0.113.123

# 3. Empty value = auto-detection
SERVER_PUBLIC_IP=
```

### IP Detection Process

```bash
# When creating a client you'll see in logs:
[INFO] Determining public IP automatically...
[INFO] Trying service: https://eth0.me
[INFO] ✅ Public IP determined: 203.0.113.123 (via https://eth0.me)
```

### Error Handling

When all services are unavailable, the system:
- ⚠️ Shows warning
- 📝 Displays manual setup instructions
- 🔧 Sets special endpoint for problem identification

```bash
# In case of all services failure:
[WARN] ⚠️ Failed to determine public IP automatically!
[WARN] Using fallback IP. MANDATORY to specify correct IP in .env file:
[WARN] echo 'SERVER_PUBLIC_IP=YOUR_PUBLIC_IP' > .env
```

### IP Address Validation

The system validates received IP addresses:
- ✅ IPv4 format correctness
- ✅ Valid ranges (1-255.0-255.0-255.0-255)
- ✅ Exclusion of invalid addresses

### Performance

- ⚡ **Timeouts**: 10-15 seconds per service
- 🔄 **Attempts**: Up to 8 different services
- 💾 **Caching**: IP used for all clients in session

---

## 🛡️ Security

### Firewall

Make sure only the necessary port is open:

```bash
# UFW (Ubuntu)
sudo ufw allow 51820/udp
sudo ufw enable

# iptables
sudo iptables -A INPUT -p udp --dport 51820 -j ACCEPT
```

### SSL/TLS

AmneziaWG uses robust encryption:
- **ChaCha20Poly1305** - Symmetric encryption
- **Curve25519** - Key exchange
- **BLAKE2s** - Hashing

### Keys

- Automatic generation of cryptographically strong keys
- Private keys stored with 600 permissions
- Regular key rotation (recommended)

---

## 🔍 Monitoring and Diagnostics

### View Status

```bash
# General status
make status

# Detailed information
docker-compose exec amneziawg-server awg show awg0

# Active connections
docker-compose exec amneziawg-server awg show awg0 latest-handshakes
```

### Logs

```bash
# Real-time
make logs

# Last 100 lines
docker-compose logs --tail=100 amneziawg-server

# Logs with timestamps
docker-compose logs -t amneziawg-server
```

### Problem Diagnostics

```bash
# Check process
docker-compose exec amneziawg-server ps aux | grep amneziawg

# Check interface
docker-compose exec amneziawg-server ip addr show awg0

# Check routes
docker-compose exec amneziawg-server ip route

# Check iptables
docker-compose exec amneziawg-server iptables -L -n
```

---

## 🚨 Troubleshooting

### Container Won't Start

```bash
# Check image
docker images | grep amneziawg

# Rebuild
make clean
make build
```

### Clients Can't Connect

1. **Check firewall:**
   ```bash
   sudo ufw status
   sudo iptables -L INPUT | grep 51820
   ```

2. **Check public IP:**
   ```bash
   curl ifconfig.me
   ```

3. **Check port:**
   ```bash
   sudo netstat -ulnp | grep 51820
   ```

### No Internet Through VPN

1. **Check IP forwarding:**
   ```bash
   cat /proc/sys/net/ipv4/ip_forward  # should be 1
   ```

2. **Check NAT rules:**
   ```bash
   docker-compose exec amneziawg-server iptables -t nat -L
   ```

### DPI Blocks Connection

1. **Change obfuscation parameters:**
   ```bash
   # In .env file change:
   AWG_JC=9
   AWG_JMIN=75
   AWG_JMAX=1200
   AWG_S1=96
   AWG_S2=684
   ```

2. **Change port:**
   ```bash
   AWG_PORT=443  # HTTPS port
   # or
   AWG_PORT=53   # DNS port
   ```

---

## 📚 Additional Resources

### Official Documentation

- [AmneziaVPN](https://docs.amnezia.org/)
- [AmneziaWG](https://docs.amnezia.org/en/documentation/amnezia-wg/)
- [WireGuard](https://www.wireguard.com/)

### Repositories

- [amneziawg-go](https://github.com/amnezia-vpn/amneziawg-go) - Userspace implementation
- [amneziawg-tools](https://github.com/amnezia-vpn/amneziawg-tools) - Management utilities
- [amneziawg-linux-kernel-module](https://github.com/amnezia-vpn/amneziawg-linux-kernel-module) - Kernel module

### Community

- [Telegram Channel](https://t.me/amnezia_vpn)
- [GitHub Issues](https://github.com/amnezia-vpn/amnezia-client/issues)

---

## 👨‍💻 Docker Implementation Author

This Docker implementation of AmneziaWG was created by [@asychin](https://github.com/asychin).

**🔗 Contact Author:**
- **GitHub:** [@asychin](https://github.com/asychin)
- **Telegram:** [@BlackSazha](https://t.me/BlackSazha)
- **Email:** moloko@skofey.com
- **Website:** [cheza.dev](https://cheza.dev)

**⚠️ Important:**
- The main AmneziaWG VPN server was developed by [Amnezia VPN team](https://github.com/amnezia-vpn)
- This implementation contains only Docker containerization and management scripts
- For VPN server questions, contact [original developers](https://github.com/amnezia-vpn/amneziawg-go)

---

## 🤝 Contributing

### Project Structure

```
amneziawg-docker/
├── .gitmodules              # Git submodules
├── amneziawg-go/           # Submodule: userspace implementation
├── amneziawg-tools/        # Submodule: management utilities
├── scripts/                # Container scripts
│   ├── entrypoint.sh       # Main startup script
│   ├── manage-clients.sh   # Client management
│   ├── post-up.sh         # Post-interface-up script
│   └── post-down.sh       # Post-interface-down script
├── Dockerfile              # Container image
├── docker-compose.yml      # Service configuration
├── Makefile               # Management utilities
├── env.example            # Environment variables example
└── README.md              # This documentation
```

### Updating Submodules

```bash
# Update all submodules
git submodule update --remote

# Update specific submodule
git submodule update --remote amneziawg-go
```

---

## 📄 License

This project is distributed under the MIT License. See [LICENSE](../../LICENSE) file for details.

**Notice:** AmneziaWG components may have their own licenses:
- amneziawg-go: MIT License
- amneziawg-tools: GPL-2.0 License

---

## ⚠️ Disclaimer

This software is provided "as is". Authors are not responsible for any consequences of use. Users must comply with laws of their jurisdiction.

**Remember:** VPN doesn't guarantee 100% anonymity. Use additional security measures.