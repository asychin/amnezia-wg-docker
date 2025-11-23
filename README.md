# 🔐 AmneziaWG Docker Server v2.0.0

<div align="center">

**🌐 Full-Stack VPN Server with Web Management Interface**

[![Docker](https://img.shields.io/badge/Docker-Ready-2496ED?style=for-the-badge&logo=docker)](https://docker.com)
[![React](https://img.shields.io/badge/React-19-61DAFB?style=for-the-badge&logo=react)](https://react.dev)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.7-3178C6?style=for-the-badge&logo=typescript)](https://www.typescriptlang.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-336791?style=for-the-badge&logo=postgresql)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

**Production-ready VPN server with beautiful web interface, QR codes, and advanced security**

### 🎯 Installation = Docker + `./quickstart.sh`

_Web interface, API, database - everything automated!_

[🚀 Quick Start](#-quick-start) • [🎨 Web Interface](#-web-interface) • [🔐 Security](#-security) • [📖 Documentation](#-documentation)

</div>

---

## 📚 Table of Contents

1. [What's New in v2.0.0](#-whats-new-in-v200)
2. [Features](#-features)
3. [Quick Start](#-quick-start)
4. [Web Management Interface](#-web-management-interface)
5. [QR Codes & Mobile Setup](#-qr-codes--mobile-setup)
6. [Security & Authentication](#-security--authentication)
7. [API Reference](#-api-reference)
8. [Configuration](#️-configuration)
9. [Deployment](#-deployment)
10. [Troubleshooting](#-troubleshooting)
11. [Migration from v1.x](#-migration-from-v1x)

---

## ✨ What's New in v2.0.0

### 🎨 Modern Web Interface

- **React + TypeScript** - Professional single-page application
- **shadcn/ui Components** - Beautiful, accessible UI components
- **Mobile-Responsive** - Works perfectly on all devices
- **Real-time Updates** - Instant feedback with Toast notifications
- **Russian Language** - Полностью русскоязычный интерфейс

### 🛠️ Full-Stack Architecture

- **REST API** - Complete API for client management
- **PostgreSQL Database** - Persistent storage with Drizzle ORM
- **Optional Authentication** - Secure API with Bearer tokens
- **Docker Compose** - Multi-service orchestration

### 🔐 Enhanced Security

- **Dual-Layer Protection** - API authorization + nginx reverse proxy
- **Path Traversal Prevention** - Strict input validation
- **Command Injection Protection** - Sanitized script parameters
- **Race Condition Prevention** - File locking mechanisms
- **Private Key Protection** - No keys exposed via API

### 📱 QR Code Generation

- **Instant Setup** - One-click QR codes for mobile devices
- **Web Interface** - Generate and display QR codes in browser
- **API Endpoint** - Programmatic QR code access
- **Base64 Format** - Easy integration with any frontend

### 🔄 Backward Compatibility

- **100% Compatible** - All v1.x features preserved
- **Migration Guide** - Detailed upgrade instructions
- **Zero Downtime** - Upgrade without service interruption

---

## 🎯 Features

### VPN Server Features

- ⚡ **1-minute installation** - Automated setup with quickstart script
- 🐳 **Docker-based** - Runs anywhere Docker is available
- 🛡️ **DPI Bypass** - Traffic obfuscation for censorship circumvention
- 🚀 **Userspace mode** - No kernel modules required
- 📱 **QR codes** - Instant mobile client setup
- 🔄 **Auto-sync** - Filesystem to database synchronization
- 💾 **Auto backups** - Automatic configuration backups
- 🏥 **Health checks** - Built-in monitoring

### Web Interface Features

- 👥 **Client Management** - Add, delete, view VPN clients
- 📊 **Dashboard** - Beautiful overview of all clients
- 🔍 **Search & Filter** - Find clients quickly
- 📱 **QR Code Display** - Show QR codes in modal dialogs
- 📄 **Config Viewer** - View and copy configurations
- 🔔 **Notifications** - Toast alerts for all operations
- 📱 **Mobile Support** - Fully responsive design
- 🎨 **Modern UI** - Gradient backgrounds, smooth animations

### API Features

- 🔌 **RESTful API** - Standard HTTP endpoints
- 🔐 **Bearer Authentication** - Optional API_SECRET protection
- 📝 **JSON Responses** - Structured data format
- 🔄 **CORS Enabled** - Cross-origin requests supported
- 📊 **Full CRUD** - Create, Read, Update, Delete operations

---

## 🚀 Quick Start

### Prerequisites

- **Docker** 20.10+ and **Docker Compose** 2.0+
- **Git** for submodule management
- **curl** and **openssl** for setup script

### Option 1: Automated Quick Start (Recommended)

```bash
# Clone the repository with submodules
git clone --recursive https://github.com/yourusername/amnezia-wg-docker.git
cd amnezia-wg-docker

# Run automated setup
./quickstart.sh

# Access web interface
# Open http://your-server-ip:8080 in browser
```

The quickstart script will:
1. ✅ Check dependencies (Docker, Git)
2. ✅ Initialize git submodules
3. ✅ Generate secure passwords (PostgreSQL, API_SECRET)
4. ✅ Detect your public IP address
5. ✅ Build Docker images
6. ✅ Start all services (VPN, API, Database, Web)
7. ✅ Display access information

### Option 2: Manual Setup

```bash
# Clone with submodules
git clone --recursive https://github.com/yourusername/amnezia-wg-docker.git
cd amnezia-wg-docker

# Create configuration
cp env.example .env
nano .env  # Edit configuration

# Initialize and start
make init
make up

# Check status
make status
```

### First VPN Client

```bash
# Add your first client
make client-add name=john

# Show QR code for mobile setup
make client-qr name=john

# Or use web interface
# http://your-server:8080
```

---

## 🎨 Web Management Interface

### Access

Open your browser and navigate to:
```
http://your-server-ip:8080
```

Default port is **8080** (configurable via `WEB_PORT` in `.env`)

### Interface Overview

#### Dashboard
- **Header** - AmneziaWG logo and title
- **Action Buttons** - Sync and Add Client
- **Client Table** - List of all VPN clients
- **Client Actions** - QR Code, Config, Delete buttons

#### Client Information

Each client displays:
- 👤 **Name** - Unique identifier
- 🌐 **IP Address** - VPN network address
- ✅ **Status** - Active/Inactive badge
- 📅 **Created** - Creation date
- 🎬 **Actions** - Quick action buttons

### Operations

#### Add New Client

1. Click **"Добавить клиента"** button
2. Enter client name (alphanumeric, no spaces)
3. Optionally specify IP address (auto-assigned if empty)
4. Click **"Создать"**
5. Toast notification confirms success

#### View QR Code

1. Click **"QR код"** button for a client
2. QR code displays in modal dialog
3. Scan with mobile app (AmneziaVPN or WireGuard)
4. Click outside or X to close

#### View Configuration

1. Click **"Конфиг"** button for a client
2. Full configuration text displays
3. Click **"Скопировать"** to copy to clipboard
4. Use for manual setup on desktop clients

#### Delete Client

1. Click **"Удалить"** button for a client
2. Confirmation dialog appears
3. Click **"Удалить"** to confirm
4. Client is removed from server and database

#### Sync Filesystem

1. Click **"Синхронизировать"** button
2. Existing filesystem clients import to database
3. Toast notification shows sync results

---

## 📱 QR Codes & Mobile Setup

### Compatible Apps

- **AmneziaVPN** (Recommended) - [Android](https://play.google.com/store/apps/details?id=org.amnezia.vpn) | [iOS](https://apps.apple.com/app/amneziavpn/id1600529900)
- **WireGuard** - [Android](https://play.google.com/store/apps/details?id=com.wireguard.android) | [iOS](https://apps.apple.com/app/wireguard/id1441195209)

### Setup Process

1. **Generate QR Code**
   - Web: Click "QR код" button
   - CLI: `make client-qr name=john`
   - API: `GET /api/clients/john/qr`

2. **Scan with Mobile App**
   - Open AmneziaVPN or WireGuard app
   - Tap "+" → "Scan QR code"
   - Point camera at QR code
   - Import completes automatically

3. **Connect**
   - Toggle VPN switch in app
   - Connection establishes instantly
   - Enjoy secure browsing!

### Desktop Setup

Export configuration file:
```bash
# Get config file
make client-config name=john > john.conf

# Or via web interface
# Click "Конфиг" → "Скопировать" → Save to file
```

Import in WireGuard:
- **Windows/Mac**: WireGuard → Import tunnel(s) from file
- **Linux**: `wg-quick up ./john.conf`

---

## 🔐 Security & Authentication

### Security Model

AmneziaWG v2.0.0 uses **two-tier security**:

```
┌─────────────────────────────────┐
│   Web Interface (Frontend)      │
│   NO built-in authentication    │
│   Protect with nginx/firewall   │
└───────────┬─────────────────────┘
            │
            ▼
┌─────────────────────────────────┐
│   REST API (Backend)            │
│   Optional Bearer Token Auth    │
│   API_SECRET environment var    │
└───────────┬─────────────────────┘
            │
            ▼
┌─────────────────────────────────┐
│   PostgreSQL Database           │
│   Credentials in env vars       │
└─────────────────────────────────┘
```

### Operating Modes

#### 🔓 DEMO Mode (Development Only)

**Conditions:**
- `API_SECRET` not set or empty
- API accepts all requests without auth

**Use Cases:**
- Local development
- Testing
- Localhost-only access

**Risks:** ⚠️ Anyone can manage VPN clients!

#### 🔒 Production Mode (Recommended)

**Conditions:**
- `API_SECRET` set (minimum 32 characters)
- API requires `Authorization: Bearer <token>` header

**Use Cases:**
- Public servers
- VPS in the internet
- Multi-user environments

**Protection:** ✅ Prevents unauthorized access

### Setting Up API_SECRET

#### 1. Generate Secure Secret

```bash
# Generate 32-byte random secret
openssl rand -base64 32
```

#### 2. Add to .env

```bash
# Edit .env file
nano .env

# Set API_SECRET
API_SECRET=your_generated_secret_min_32_characters
```

#### 3. Restart Services

```bash
docker compose down
docker compose up -d
```

### Protecting Web Interface

**Frontend has NO authentication!** Protect with:

#### Option 1: Nginx Reverse Proxy with Basic Auth

```nginx
server {
    listen 80;
    server_name vpn.example.com;

    auth_basic "VPN Admin Panel";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

Create user:
```bash
sudo htpasswd -c /etc/nginx/.htpasswd admin
sudo systemctl reload nginx
```

#### Option 2: VPN-Only Access

```yaml
# docker-compose.yml
services:
  web:
    ports:
      - "10.13.13.1:8080:5000"  # Only accessible via VPN
```

Access at: `http://10.13.13.1:8080` (through VPN)

#### Option 3: Firewall Rules

```bash
# UFW example - allow only from specific IP
sudo ufw allow from 203.0.113.10 to any port 8080
```

### Additional Security

See **[SECURITY.md](SECURITY.md)** for:
- HTTPS setup with Let's Encrypt
- Fail2ban configuration
- Database security
- VPN traffic obfuscation
- Complete security checklist

---

## 📡 API Reference

### Base URL

```
http://your-server:8080/api
```

### Authentication

```bash
# Without API_SECRET (DEMO mode)
curl http://server:8080/api/clients

# With API_SECRET (Production)
curl -H "Authorization: Bearer YOUR_API_SECRET" \
     http://server:8080/api/clients
```

### Endpoints

#### GET /api/clients

List all VPN clients

**Response:**
```json
[
  {
    "id": 1,
    "name": "john",
    "ipAddress": "10.13.13.5",
    "enabled": true,
    "createdAt": "2024-11-23T10:30:00Z",
    "updatedAt": "2024-11-23T10:30:00Z"
  }
]
```

#### POST /api/clients

Create new VPN client

**Request:**
```json
{
  "name": "alice",
  "ipAddress": "10.13.13.10"  // optional, auto-assigned if empty
}
```

**Response:**
```json
{
  "id": 2,
  "name": "alice",
  "ipAddress": "10.13.13.10",
  "enabled": true,
  "createdAt": "2024-11-23T11:00:00Z"
}
```

#### DELETE /api/clients/:name

Delete VPN client

**Response:**
```json
{
  "message": "Client alice deleted successfully"
}
```

#### GET /api/clients/:name/qr

Get QR code as base64 data URL

**Response:**
```json
{
  "name": "john",
  "qrCode": "data:image/png;base64,iVBORw0KGgoAAAA..."
}
```

#### GET /api/clients/:name/config

Get configuration file text

**Response:**
```json
{
  "name": "john",
  "config": "[Interface]\nPrivateKey = ...\n..."
}
```

#### POST /api/sync

Sync filesystem clients to database

**Response:**
```json
{
  "message": "Sync completed",
  "added": 3,
  "updated": 1
}
```

### Error Responses

```json
{
  "error": "Client not found"
}
```

**Status Codes:**
- `200` - Success
- `201` - Created
- `400` - Bad Request
- `401` - Unauthorized (API_SECRET required)
- `404` - Not Found
- `500` - Internal Server Error

---

## ⚙️ Configuration

### Environment Variables

Create `.env` from template:
```bash
cp env.example .env
nano .env
```

#### VPN Settings

```bash
# VPN Interface
AWG_INTERFACE=awg0
AWG_PORT=51820
AWG_NET=10.13.13.0/24
AWG_SERVER_IP=10.13.13.1
AWG_DNS=8.8.8.8,8.8.4.4

# Public IP (auto-detect or manual)
SERVER_PUBLIC_IP=auto
```

#### Obfuscation Parameters

```bash
# DPI Bypass settings
AWG_JC=7          # Jitter intensity
AWG_JMIN=50       # Min junk packet size
AWG_JMAX=1000     # Max junk packet size
AWG_S1=86         # HTTPS header size 1
AWG_S2=574        # HTTPS header size 2
AWG_H1=1          # Hash function 1
AWG_H2=2          # Hash function 2
AWG_H3=3          # Hash function 3
AWG_H4=4          # Hash function 4
```

#### Web Interface

```bash
# Web UI port
WEB_PORT=8080

# PostgreSQL
POSTGRES_DB=amneziawg
POSTGRES_USER=amneziawg
POSTGRES_PASSWORD=change_to_secure_password

# Node.js environment
NODE_ENV=production
```

#### Security

```bash
# API Protection (CRITICAL for production!)
API_SECRET=your_32_plus_character_secret_here
```

Generate secure secret:
```bash
openssl rand -base64 32
```

---

## 🚢 Deployment

### Production Deployment

#### 1. Server Requirements

- **OS**: Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+)
- **Docker**: 20.10+
- **Docker Compose**: 2.0+
- **RAM**: 512 MB minimum, 1 GB recommended
- **Disk**: 5 GB free space
- **Network**: Public IP address, UDP port open

#### 2. VPS Providers

Recommended providers:
- **DigitalOcean** - $6/month droplet
- **Linode** - $5/month Nanode
- **Vultr** - $6/month instance
- **Hetzner** - €4.5/month CX11

#### 3. Deployment Steps

```bash
# 1. Connect to server
ssh root@your-server-ip

# 2. Install Docker
curl -fsSL https://get.docker.com | sh

# 3. Clone repository
git clone --recursive https://github.com/yourusername/amnezia-wg-docker.git
cd amnezia-wg-docker

# 4. Run quickstart
./quickstart.sh

# 5. Setup nginx reverse proxy (optional)
# See SECURITY.md for configuration

# 6. Setup HTTPS with Let's Encrypt
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d vpn.example.com
```

#### 4. Firewall Configuration

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 22/tcp       # SSH
sudo ufw allow 51820/udp    # VPN
sudo ufw allow 80/tcp       # HTTP
sudo ufw allow 443/tcp      # HTTPS
sudo ufw enable

# iptables (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=51820/udp
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
```

### Docker Compose Services

The stack includes:

- **postgres** - PostgreSQL 16 database
- **vpn** - AmneziaWG VPN server
- **web** - Web interface + API server

Start all:
```bash
docker compose up -d
```

View logs:
```bash
docker compose logs -f
```

### Backup & Restore

```bash
# Backup
make backup

# Restore
make restore file=amneziawg-backup-20241123-100000.tar.gz
```

---

## 🔧 Troubleshooting

### Web Interface Issues

**Problem:** Can't access web interface

**Solutions:**
```bash
# Check if service is running
docker compose ps

# Check web container logs
docker logs amneziawg-web

# Verify port is open
sudo netstat -tulpn | grep 8080

# Restart web service
docker compose restart web
```

**Problem:** API returns 401 Unauthorized

**Solution:** Check API_SECRET configuration
```bash
# View current API_SECRET
docker exec amneziawg-web printenv | grep API_SECRET

# If set, use in requests:
curl -H "Authorization: Bearer YOUR_SECRET" http://server:8080/api/clients
```

### VPN Connection Issues

**Problem:** Can't connect to VPN

**Solutions:**
```bash
# Check VPN server status
make status

# Check server logs
make logs

# Verify port is open
sudo ss -ulpn | grep 51820

# Test from client side
nc -vuz your-server-ip 51820
```

**Problem:** Connected but no internet

**Solutions:**
```bash
# Check DNS settings
docker exec amneziawg-server cat /etc/resolv.conf

# Verify IP forwarding
docker exec amneziawg-server sysctl net.ipv4.ip_forward

# Check iptables NAT rules
docker exec amneziawg-server iptables -t nat -L -n -v
```

### Database Issues

**Problem:** Database connection failed

**Solutions:**
```bash
# Check PostgreSQL status
docker logs amneziawg-db

# Verify database credentials
cat .env | grep POSTGRES

# Test connection
docker exec amneziawg-db psql -U amneziawg -c "SELECT 1;"

# Restart database
docker compose restart postgres
```

### Complete Diagnostics

```bash
# Run built-in diagnostics
docker exec amneziawg-server /app/scripts/diagnose.sh

# Full system check
make status
docker compose ps
docker compose logs --tail=50
```

---

## 🔄 Migration from v1.x

### Upgrade Process

**v1.x → v2.0.0** is fully backward compatible!

#### Step 1: Backup

```bash
# Create backup before upgrade
make backup
```

#### Step 2: Pull Updates

```bash
# Pull latest code
git pull origin main

# Update submodules
git submodule update --remote --recursive
```

#### Step 3: Update Configuration

```bash
# Add new variables to .env
cat env.example >> .env
nano .env  # Review and adjust
```

New variables:
- `WEB_PORT=8080`
- `POSTGRES_DB=amneziawg`
- `POSTGRES_USER=amneziawg`
- `POSTGRES_PASSWORD=...`
- `NODE_ENV=production`
- `API_SECRET=...`

#### Step 4: Rebuild and Restart

```bash
# Stop v1.x
make down

# Build v2.0.0
docker compose build

# Start v2.0.0
docker compose up -d
```

#### Step 5: Verify

```bash
# Check all services
docker compose ps

# Sync existing clients to database
curl -X POST http://localhost:8080/api/sync

# Test web interface
curl http://localhost:8080
```

### Breaking Changes

**None!** v2.0.0 is 100% backward compatible:
- ✅ All v1.x commands still work
- ✅ Existing configs preserved
- ✅ No manual migration needed
- ✅ Web interface is additional feature

---

## 📖 Documentation

### Complete Guides

- **[SECURITY.md](SECURITY.md)** - Security best practices, authentication setup
- **[FEATURES.md](FEATURES.md)** - Detailed feature documentation
- **[MIGRATION.md](MIGRATION.md)** - Upgrade guide from v1.x
- **[env.example](env.example)** - Configuration reference with comments

### Quick References

- **Make Commands**: `make help`
- **API Docs**: See [API Reference](#-api-reference) section
- **Troubleshooting**: See [Troubleshooting](#-troubleshooting) section

### External Resources

- **AmneziaVPN**: https://amnezia.org
- **WireGuard**: https://www.wireguard.com
- **Docker**: https://docs.docker.com

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

---

## 📜 License

MIT License - see [LICENSE](LICENSE) file

---

## 🙏 Acknowledgments

- **AmneziaVPN Team** - Original WireGuard fork with obfuscation
- **WireGuard Project** - Revolutionary VPN protocol
- **Docker Community** - Containerization platform
- **shadcn/ui** - Beautiful React components

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/amnezia-wg-docker/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/amnezia-wg-docker/discussions)
- **Security**: See [SECURITY.md](SECURITY.md) for responsible disclosure

---

<div align="center">

**Made with ❤️ for the free internet**

⭐ Star us on GitHub if this project helped you!

</div>
