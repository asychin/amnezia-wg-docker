# AmneziaWG VPN Management Interface - Replit Web Application

## Overview

This Replit workspace contains a **full-stack VPN management web interface** for the AmneziaWG Docker VPN Server project. While the actual VPN server requires Docker to run, this interface provides a complete management system that can be deployed alongside the VPN server or used as a standalone demo.

**Version:** 2.0.0  
**Original Project:** [AmneziaVPN Team](https://github.com/amnezia-vpn)  
**Docker Implementation:** asychin  
**Web Interface:** React + TypeScript + shadcn/ui + Drizzle ORM

## What's Available in This Workspace

### 1. VPN Management Interface (Running)
- **URL:** Available via the Webview panel
- **Port:** 5000 (Frontend), 3001 (API)
- **Technology:** React + Vite + TypeScript + shadcn/ui
- **Purpose:** Interactive VPN client management with beautiful UI

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
├── src/                   # Frontend source (React + TypeScript)
│   ├── main.tsx          # React entry point
│   ├── App.tsx           # Main application component
│   ├── components/       # shadcn/ui components
│   │   └── ui/          # Button, Card, Dialog, Table, Badge, etc.
│   ├── api/             # API client functions
│   ├── types/           # TypeScript interfaces
│   ├── lib/             # Utilities
│   └── index.css        # Tailwind CSS styles
├── server/               # Backend API (TypeScript)
│   ├── main.ts          # API server entry point
│   ├── api.ts           # REST API routes
│   └── storage.ts       # Database operations (Drizzle ORM)
├── shared/               # Shared types and schemas
│   └── schema.ts        # Drizzle ORM database schema
├── scripts/              # VPN management scripts
│   ├── entrypoint.sh    # Container entry point
│   ├── manage-clients.sh # Client management (bash)
│   ├── healthcheck.sh   # Health monitoring
│   └── diagnose.sh      # Diagnostics
├── views/                # Legacy documentation templates
│   └── index.ejs        # Documentation page (accessible at /docs)
├── public/               # Static assets
├── clients/              # Generated VPN client configs
├── amneziawg-go/         # VPN implementation (submodule)
├── amneziawg-tools/      # CLI tools (submodule)
├── vite.config.ts        # Vite configuration
├── tailwind.config.ts    # Tailwind CSS configuration
├── drizzle.config.ts     # Drizzle ORM configuration
├── tsconfig.json         # TypeScript configuration
├── package.json          # Node.js dependencies
├── Dockerfile            # Multi-stage build
├── docker-compose.yml    # Service configuration
├── Makefile              # Management commands
└── env.example           # Configuration template
```

## Technology Stack

### Frontend (VPN Management Interface)
- **Framework:** React 19 + TypeScript
- **Build Tool:** Vite 7
- **UI Library:** shadcn/ui (Radix UI primitives)
- **Styling:** Tailwind CSS v4
- **State Management:** Tanstack Query (React Query)
- **Icons:** Lucide React

### Backend API
- **Runtime:** Node.js with tsx (TypeScript executor)
- **Framework:** Express 5
- **Language:** TypeScript
- **Database:** PostgreSQL (Replit-managed)
- **ORM:** Drizzle ORM
- **QR Codes:** qrcode library
- **Process Management:** child_process for bash scripts

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

## Features

### VPN Client Management Interface

#### 1. Dashboard
- Beautiful, modern UI with gradient background
- Shield icon branding
- Responsive card-based layout
- Real-time client list with status badges

#### 2. Client Operations
- **Add Client:** Create new VPN clients with auto-assigned or custom IP addresses
- **Delete Client:** Remove clients with confirmation dialog
- **View QR Code:** Generate and display QR codes for easy mobile setup
- **View Configuration:** Display full WireGuard configuration text
- **Sync Clients:** Synchronize filesystem clients with database

#### 3. Client Information Display
- Name and IP address
- Status badges (Active/Inactive)
- Creation date
- Quick action buttons for each client

### API Endpoints

#### Client Management
- `GET /api/clients` - List all VPN clients
- `POST /api/clients` - Create new client (body: { name, ipAddress? })
- `DELETE /api/clients/:name` - Delete client
- `GET /api/clients/:name/qr` - Get QR code as data URL
- `GET /api/clients/:name/config` - Get configuration file text
- `POST /api/sync` - Sync filesystem clients to database

### Database Schema

**vpn_clients table:**
- `id` (serial, primary key)
- `name` (varchar, unique) - Client identifier
- `ip_address` (varchar) - Assigned VPN IP
- `public_key` (varchar) - Client's public key
- `created_at` (timestamp) - Creation time
- `updated_at` (timestamp) - Last update
- `enabled` (boolean) - Active status
- `last_handshake` (timestamp, nullable) - Last connection

## Recent Changes

**2024-11-23 v2.0:** Complete VPN management interface
- Created full-stack React + TypeScript application
- Implemented REST API with Express
- Integrated PostgreSQL database with Drizzle ORM
- Added shadcn/ui component library
- Implemented client CRUD operations
- Added QR code generation
- Created beautiful responsive UI
- Configured dual-server setup (API + Frontend)
- Maintained original documentation portal (accessible at /docs)

**2024-11-23 v1.1:** Created documentation portal for Replit environment
- Added Express-based web server
- Created interactive documentation interface
- Configured workflow for port 5000
- Updated project structure for dual purpose (docs + VPN source)

## Notes

This workspace serves as:
1. A **full-stack VPN management application** - accessible via Webview
2. A **complete REST API** - for VPN client operations
3. A **PostgreSQL-backed database** - for client persistence
4. A **documentation portal** - accessible at /docs endpoint
5. A **complete source repository** - ready to deploy on a Docker-capable server

The management interface runs entirely in the browser with React, communicating with a TypeScript API backend that interfaces with VPN management scripts and PostgreSQL database.

## Support

For questions about:
- **AmneziaWG Protocol:** [AmneziaVPN GitHub](https://github.com/amnezia-vpn)
- **WireGuard:** [WireGuard Documentation](https://www.wireguard.com/)
- **Docker:** [Docker Documentation](https://docs.docker.com/)
