# AmneziaWG Docker VPN Server - Replit Documentation Portal

## Overview

This Replit workspace contains a **documentation portal** for the AmneziaWG Docker VPN Server project. The actual VPN server cannot run in the Replit environment due to technical limitations, but this portal provides comprehensive documentation and setup instructions.

**Version:** 1.1.0  
**Original Project:** [AmneziaVPN Team](https://github.com/amnezia-vpn)  
**Docker Implementation:** asychin

## What's Available in This Workspace

### 1. Documentation Portal (Running)
- **URL:** Available via the Webview panel
- **Port:** 5000
- **Technology:** Node.js + Express + EJS
- **Purpose:** Interactive documentation and setup guide

### 2. Complete Project Files
- `Dockerfile` - Multi-stage Docker build configuration
- `docker-compose.yml` - Service composition
- `Makefile` - Management commands
- `scripts/` - Automation scripts (entrypoint, client management, health checks)
- `env.example` - Configuration template
- `amneziawg-go/` - Git submodule for Go implementation
- `amneziawg-tools/` - Git submodule for CLI utilities

## Important Limitations

### ❌ Cannot Run in Replit

The AmneziaWG VPN server **cannot run in this environment** because it requires:

1. **Docker Support** - Replit doesn't support Docker containers
2. **TUN/TAP Devices** - VPN needs kernel-level network device creation
3. **NET_ADMIN Capability** - Privileged network operations not available
4. **iptables Access** - NAT and routing configuration requires system access
5. **Kernel Modules** - VPN protocols need direct kernel interaction

### ✅ What This Portal Provides

- Complete project documentation
- Setup instructions for proper deployment
- Configuration examples and best practices
- Command reference
- Architecture overview
- Deployment recommendations

## Deployment Options

To actually deploy this VPN server, you need a server with Docker support:

### Recommended Options:
1. **VPS Providers** - DigitalOcean, Linode, Vultr, AWS Lightsail
2. **Cloud Platforms** - Google Cloud, Azure, Oracle Cloud
3. **Self-Hosted** - Home server, Raspberry Pi, any Linux machine with Docker

### Quick Deploy (on a Docker-capable server):
```bash
git clone --recursive https://github.com/yourusername/amnezia-wg-docker.git
cd amnezia-wg-docker
make up
```

## Project Structure

```
amnezia-wg-docker/
├── server.js              # Documentation portal server
├── views/                 # EJS templates
│   └── index.ejs         # Main documentation page
├── public/               # Static assets
│   └── css/
│       └── style.css     # Styles
├── amneziawg-go/         # VPN implementation (submodule)
├── amneziawg-tools/      # CLI tools (submodule)
├── scripts/              # Automation scripts
│   ├── entrypoint.sh    # Container entry point
│   ├── manage-clients.sh # Client management
│   ├── healthcheck.sh   # Health monitoring
│   └── diagnose.sh      # Diagnostics
├── Dockerfile           # Multi-stage build
├── docker-compose.yml   # Service configuration
├── Makefile            # Management commands
└── env.example         # Configuration template
```

## Technology Stack

### Documentation Portal
- **Backend:** Node.js + Express
- **Template Engine:** EJS
- **Frontend:** Vanilla JavaScript + CSS

### VPN Server (for deployment elsewhere)
- **Core:** amneziawg-go (Go 1.24)
- **Tools:** amneziawg-tools (C)
- **Container:** Docker + Ubuntu 22.04
- **Automation:** Bash scripts + Makefile

## Key Features of AmneziaWG

1. **DPI Bypass** - Traffic obfuscation to avoid censorship
2. **Userspace Mode** - No kernel modules required
3. **Quick Setup** - 1-minute deployment with `make up`
4. **QR Codes** - Easy mobile configuration
5. **Auto Backups** - Configuration protection
6. **Health Monitoring** - Built-in diagnostics

## Usage Instructions

### In This Replit Workspace:
- View the documentation portal in the Webview panel
- Explore the project files and structure
- Review the configuration examples
- Learn about deployment options

### For Actual VPN Deployment:
1. Get a VPS or server with Docker installed
2. Clone this repository with submodules
3. Run `make up` to start the server
4. Add clients with `make client-add name=username`
5. Generate QR codes with `make client-qr name=username`

## Configuration

The VPN server is configured via environment variables in the `.env` file:

### Core Settings:
- `AWG_INTERFACE` - Interface name (default: awg0)
- `AWG_PORT` - UDP port (default: 51820)
- `AWG_NET` - VPN subnet (default: 10.13.13.0/24)
- `SERVER_PUBLIC_IP` - Auto-detected or manual

### Obfuscation Parameters:
- `AWG_JC` - Jitter intensity (3-15)
- `AWG_JMIN/JMAX` - Junk packet sizes
- `AWG_S1/S2` - Header sizes for HTTPS simulation
- `AWG_H1-H4` - Hash functions

## Common Commands (for deployed server)

```bash
make up           # Start VPN server
make down         # Stop server
make restart      # Restart server
make status       # View status
make logs         # View logs
make client-add   # Add client
make client-qr    # Show QR code
make backup       # Backup configs
```

## Resources

- **Documentation Portal:** Running in this workspace
- **Source Files:** All available in this Replit
- **README.md:** Comprehensive project documentation
- **env.example:** Configuration template with explanations

## Recent Changes

**2024-11-23:** Created documentation portal for Replit environment
- Added Express-based web server
- Created interactive documentation interface
- Configured workflow for port 5000
- Updated project structure for dual purpose (docs + VPN source)

## Notes

This workspace serves as both:
1. An **interactive documentation portal** - accessible via Webview
2. A **complete source repository** - ready to deploy on a Docker-capable server

The documentation portal runs on Node.js and showcases all features, while the actual VPN components (Docker, Go binaries, scripts) are available for deployment elsewhere.

## Support

For questions about:
- **AmneziaWG Protocol:** [AmneziaVPN GitHub](https://github.com/amnezia-vpn)
- **WireGuard:** [WireGuard Documentation](https://www.wireguard.com/)
- **Docker:** [Docker Documentation](https://docs.docker.com/)
