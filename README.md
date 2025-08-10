# 🔒 AmneziaWG Docker Server

<div align="center">

**🌍 Languages: [🇷🇺 Russian](docs/ru/README.md) | [🇨🇳 Chinese](docs/zh/README.md)**

---

**Production-ready Docker solution for AmneziaWG VPN server with userspace implementation and DPI bypass**

[![GitHub Release](https://img.shields.io/github/v/release/asychin/amnezia-wg-docker?style=flat-square&logo=github)](https://github.com/asychin/amnezia-wg-docker/releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/asychin/amnezia-wg-docker?style=flat-square&logo=docker)](https://hub.docker.com/r/asychin/amnezia-wg-docker)
[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-asychin%2Famnezia--wg--docker-blue?style=flat-square&logo=docker)](https://ghcr.io/asychin/amnezia-wg-docker)
[![GitHub Stars](https://img.shields.io/github/stars/asychin/amnezia-wg-docker?style=flat-square&logo=github)](https://github.com/asychin/amnezia-wg-docker/stargazers)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

> 🍴 **Forked this repository?** Update the badges above by replacing `asychin/amnezia-wg-docker` with `yourusername/amnezia-wg-docker` in documentation files.

</div>

---

## 📖 About

This project provides a **containerized AmneziaWG VPN server** with userspace implementation. AmneziaWG is a protocol based on WireGuard that adds obfuscation capabilities to bypass DPI (Deep Packet Inspection) systems.

### Key Components:

- **amneziawg-go**: Userspace implementation (no kernel modules required)
- **amneziawg-tools**: Configuration and management utilities
- **Docker containerization**: Easy deployment and management
- **Makefile automation**: Simple commands for all operations

---

## 🌟 Features

- ✅ **AmneziaWG Userspace** - Works without kernel modules
- ✅ **DPI Bypass** - Camouflages VPN traffic as HTTPS
- ✅ **Docker Container** - Simple deployment with docker-compose
- ✅ **Auto IP Detection** - Smart public IP discovery through multiple services
- ✅ **Automatic Setup** - iptables, routing, DNS configuration
- ✅ **QR Codes** - Quick mobile client connection
- ✅ **Client Management** - Add/remove clients via Makefile commands
- ✅ **Monitoring** - Real-time logs and connection status
- ✅ **Backup/Restore** - Configuration management
- ✅ **Healthcheck** - Built-in service monitoring

---

## 🚀 Quick Start

### 1. Clone and Initialize

```bash
git clone --recursive https://github.com/asychin/amnezia-wg-docker.git
cd amnezia-wg-docker

# If you forgot --recursive:
git submodule update --init --recursive

# Initialize project (optional - will be done automatically)
make init
```

### 2. Build and Start

```bash
# Build Docker image
make build

# Start VPN server
make up

# Check status
make status
```

### 3. Add Clients

```bash
# Add client with automatic IP assignment
make client-add name=myphone

# Add client with specific IP
make client-add name=laptop ip=10.13.13.15

# Show QR code for mobile setup
make client-qr name=myphone

# Export configuration file
make client-config name=laptop > laptop.conf
```

---

## 📋 Available Commands

| Command                     | Description                              |
| --------------------------- | ---------------------------------------- |
| `make help`                 | Show all available commands              |
| `make init`                 | Initialize project (submodules + config) |
| `make build`                | Build Docker image                       |
| `make up`                   | Start VPN server                         |
| `make down`                 | Stop VPN server                          |
| `make restart`              | Restart VPN server                       |
| `make status`               | Show server status and connections       |
| `make logs`                 | View real-time logs                      |
| `make client-add name=X`    | Add new client                           |
| `make client-rm name=X`     | Remove client                            |
| `make client-qr name=X`     | Show client QR code                      |
| `make client-config name=X` | Show client configuration                |
| `make client-list`          | List all clients                         |
| `make backup`               | Create configuration backup              |
| `make clean`                | Full cleanup (stop + remove data)        |

---

## 📚 Documentation

| Document                  | Link                               |
| ------------------------- | ---------------------------------- |
| **📋 Full Documentation** | [📖 Read](docs/en/README.md)       |
| **🔄 CI/CD Pipeline**     | [🔄 Pipeline](docs/en/pipeline.md) |
| **🍴 Fork Setup**         | [🍴 Fork](docs/en/fork-setup.md)   |

---

## 🛠️ Technical Details

### Network Configuration

- **VPN Network**: `10.13.13.0/24`
- **Server IP**: `10.13.13.1`
- **Port**: `51820/udp`
- **DNS**: `8.8.8.8, 8.8.4.4`

### AmneziaWG Obfuscation Parameters

- **Junk Packet Count (Jc)**: 7
- **Junk Packet Min Size (Jmin)**: 50
- **Junk Packet Max Size (Jmax)**: 1000
- **Init Packet Junk Size**: 86
- **Response Packet Junk Size**: 574
- **Header fields**: H1=1, H2=2, H3=3, H4=4

### Requirements

- Docker with Docker Compose
- Git (for submodules)
- Root privileges (for network configuration)

---

## 🏆 Project Info

<div align="center">

> 💡 **Docker Implementation**: [@asychin](https://github.com/asychin) | **Original VPN Server**: [AmneziaWG Team](https://github.com/amnezia-vpn)

**🌟 If this project helped you, please consider giving it a star!**

[![GitHub Stars](https://img.shields.io/github/stars/asychin/amnezia-wg-docker?style=for-the-badge&logo=github)](https://github.com/asychin/amnezia-wg-docker/stargazers)

</div>

---

## 📞 Support

<div align="center">

| Platform           | Link                                                                           |
| ------------------ | ------------------------------------------------------------------------------ |
| 🐛 **Issues**      | [GitHub Issues](https://github.com/asychin/amnezia-wg-docker/issues)           |
| 💬 **Discussions** | [GitHub Discussions](https://github.com/asychin/amnezia-wg-docker/discussions) |
| 📧 **Contact**     | [Email](mailto:asychin@users.noreply.github.com)                               |

</div>

---

## 📄 License

<div align="center">

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

**Copyright © 2025 [asychin](https://github.com/asychin)**

</div>
