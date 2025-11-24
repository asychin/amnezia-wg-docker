# AmneziaWG VPN Management Interface - Replit Web Application

## Overview
This project provides a full-stack web interface for managing AmneziaWG Docker VPN servers. It offers a user-friendly way to control VPN clients, generate configurations, and monitor server status. While the VPN server itself requires a Docker-capable environment for deployment, this workspace demonstrates the complete management interface as a standalone application. The core purpose is to simplify VPN client management for the AmneziaWG VPN server, offering a modern, interactive dashboard with features like DPI bypass, quick setup, QR code generation, and health monitoring. The business vision is to provide a robust and easy-to-use VPN solution, enhancing digital privacy and security with broad market potential for individuals and small businesses seeking secure and uncensored internet access.

**v2.0.0 is 100% backward compatible with v1.x** - VPN runs standalone by default, web interface is optional via `--profile web`.

### Recent Changes (Nov 24, 2025)
- ✅ **100% Backward Compatibility Restored**: VPN runs independently by default
- ✅ **Docker Compose Profiles**: PostgreSQL and Web only start with `--profile web`
- ✅ **VPN Independence**: Removed PostgreSQL dependency from VPN service
- ✅ **New Makefile Commands**:
  - `make up` → VPN-only (v1.x compatible)
  - `make up-web` → Full stack (VPN + Web + PostgreSQL)
- ✅ **Documentation Created**:
  - BACKWARD_COMPATIBILITY.md (12KB) - Complete compatibility guide
  - docker-compose.minimal.yml (2.6KB) - Explicit VPN-only mode
  - MAKEFILE_V2.md (6.8KB) - Web interface commands
- ✅ **Updated Documentation**: MIGRATION.md, README.md with deployment modes
- ✅ **Dockerfile.web Fixed**: Corrected heredoc syntax error (line 40)
- ✅ **quickstart.sh Improved**: Fixed sed syntax error in API_SECRET generation (line 142)
- ✅ **quickstart.sh Improved**: Better submodules validation (checks real files, not just .git dirs)
- ✅ **Documentation Consolidated**: Removed 3 extra docs (SUBMODULES_FIX, BACKWARD_COMPATIBILITY, MAKEFILE_V2), merged into README
- ✅ **README Updated**: Added prominent warnings about --recursive flag and submodules troubleshooting

## User Preferences
I prefer simple language and direct answers. I like to work iteratively, so please suggest small changes and ask for my approval before implementing major ones. I appreciate detailed explanations, especially for complex technical concepts. Do not make changes to the `amneziawg-go/` or `amneziawg-tools/` folders.

## System Architecture
The system comprises a React-based frontend and a Node.js/Express backend.

**UI/UX Decisions:**
The frontend utilizes React 19 with TypeScript, Vite 7 for building, and `shadcn/ui` (built on Radix UI primitives) for a modern, responsive, and visually appealing interface. Styling is managed with Tailwind CSS v4, and icons are provided by Lucide React. The dashboard features a clean, card-based layout with a gradient background and real-time client status badges.

**Technical Implementations:**
- **Frontend:** Built with React, TypeScript, Vite, `shadcn/ui`, Tailwind CSS, Tanstack Query for state management.
- **Backend:** Developed with Node.js and `tsx` for TypeScript execution, using Express 5 for REST API endpoints. It interacts with VPN management scripts via `child_process` and manages data persistence with Drizzle ORM.
- **Database:** PostgreSQL is used for storing VPN client information.
- **VPN Server (external deployment):** Uses `amneziawg-go` (Go 1.24) for the core VPN functionality and `amneziawg-tools` (C) for utilities, packaged in a Docker container based on Ubuntu 22.04.

**Feature Specifications:**
- **Dashboard:** Modern UI, responsive design, real-time client list with status.
- **Client Operations:** Add, delete, view QR codes, view configurations, and synchronize clients.
- **API Endpoints:**
    - `GET /api/clients`: List all VPN clients.
    - `POST /api/clients`: Create a new client.
    - `DELETE /api/clients/:name`: Delete a client.
    - `GET /api/clients/:name/qr`: Get QR code data URL.
    - `GET /api/clients/:name/config`: Get configuration text.
    - `POST /api/sync`: Sync filesystem clients to database.

**System Design Choices:**
- **Containerization:** The entire application (frontend, backend, and database) is containerized using Docker and Docker Compose for easy deployment and scalability.
- **Microservices-like separation:** Although co-located in this workspace, the frontend and backend are distinct services, allowing for flexible deployment.
- **Database Schema:** A `vpn_clients` table stores client details including name, IP address, public key, creation/update timestamps, enabled status, and last handshake.
- **Security:** Includes path traversal and command injection protection, race condition prevention with file locking, secure file permissions, and elimination of private key exposure in API responses.

## External Dependencies
- **PostgreSQL:** Used as the primary database for storing VPN client data.
- **amneziawg-go (Git Submodule):** The Go-based VPN server implementation.
- **amneziawg-tools (Git Submodule):** C-based command-line utilities for VPN management.
- **Docker:** Core technology for containerization and deployment of the VPN server and its management interface.
- **Vite:** Frontend build tool.
- **shadcn/ui:** UI component library.
- **Tailwind CSS:** Utility-first CSS framework.
- **Tanstack Query:** For data fetching, caching, and state management in React.
- **Lucide React:** Icon library.
- **Express:** Backend web framework for Node.js.
- **Drizzle ORM:** TypeScript ORM for database interaction.
- **qrcode library:** For generating QR codes.