# 🔒 AmneziaWG Docker Server

<div align="center">

**🌍 Languages: [🇷🇺 Russian](docs/ru/README.md) | [🇨🇳 Chinese](docs/zh/README.md)**

---

**Production-ready solution for running AmneziaWG VPN server in Docker container with DPI bypass support**

[![GitHub Release](https://img.shields.io/github/v/release/asychin/amnezia-wg-docker?style=flat-square&logo=github)](https://github.com/asychin/amnezia-wg-docker/releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/asychin/amnezia-wg-docker?style=flat-square&logo=docker)](https://hub.docker.com/r/asychin/amnezia-wg-docker)
[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-asychin%2Famnezia--wg--docker-blue?style=flat-square&logo=docker)](https://ghcr.io/asychin/amnezia-wg-docker)
[![GitHub Stars](https://img.shields.io/github/stars/asychin/amnezia-wg-docker?style=flat-square&logo=github)](https://github.com/asychin/amnezia-wg-docker/stargazers)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

> 🍴 **Forked this repository?** Update the badges above by replacing `asychin/amnezia-wg-docker` with `yourusername/amnezia-wg-docker` in documentation files.

</div>

---

## 📖 What is AmneziaWG?

**AmneziaWG** is a modern VPN protocol based on WireGuard that adds **DPI (Deep Packet Inspection) bypass capabilities**. Unlike traditional VPN protocols that can be easily detected and blocked by firewalls, AmneziaWG disguises VPN traffic as regular HTTPS connections, making it virtually undetectable.

### 🎯 Why This Docker Implementation?

This project provides a **complete containerized solution** for running your own AmneziaWG VPN server with zero configuration headaches:

- **🔒 Privacy-First**: Run your own VPN server, no third-party trust required
- **🌐 Bypass Censorship**: Works in countries with strict internet censorship 
- **🐳 Docker-Ready**: One command deployment with automatic configuration
- **📱 Multi-Device**: Generate QR codes for instant client setup
- **⚡ High Performance**: Userspace implementation, no kernel modules needed
- **🛡️ Secure by Default**: Modern cryptography with traffic obfuscation

### 🌍 Perfect For:

- **Developers** who need secure connections while working remotely
- **Digital Nomads** accessing geo-restricted content while traveling  
- **Privacy Enthusiasts** wanting full control over their VPN infrastructure
- **Organizations** needing to bypass corporate/government firewalls
- **Anyone** in countries with internet restrictions (China, Iran, Russia, etc.)

---

## 💡 Use Cases & Examples

### 🌏 Bypass Internet Censorship
```bash
# Set up VPN server in a free country
make up
# Connect from restricted location
make client-add name=phone
# Scan QR code - browse freely!
```

### 🏢 Secure Remote Work
```bash
# Company server setup
make up EXTERNAL_IP=your-office-ip
# Add employee devices
make client-add name=employee1
make client-add name=laptop-employee1
```

### 🌍 Travel & Geo-Restrictions
```bash
# Deploy on cloud server in target country
make up
# Access local content from anywhere
make client-show name=travel-device
```

### 🔒 Privacy-Focused Browsing
```bash
# Personal privacy server
make up
# Route all traffic through VPN
make client-add name=personal-laptop
```

---

## 🚀 Quick Start

<div align="center">

### 🐳 One-line installation

```bash
git clone --recursive https://github.com/asychin/amnezia-wg-docker.git && cd amnezia-wg-docker && make build && make up
```

**That's it! Your VPN server is running.** Get client configs with: `make client-add name=myphone`

</div>

---

## 📚 Documentation

### 📖 Documentation

| Document | Link |
|----------|------|
| **📋 Full Documentation** | [📖 Read](docs/en/README.md) |
| **🔄 CI/CD Pipeline** | [🔄 Pipeline](docs/en/pipeline.md) |
| **🍴 Fork Setup** | [🍴 Fork](docs/en/fork-setup.md) |

---

## ✨ Key Features & Capabilities

### 🛡️ Advanced Security
- **🔐 AmneziaWG Protocol**: Next-generation WireGuard with traffic obfuscation
- **🌐 DPI Evasion**: Disguises VPN traffic as regular HTTPS to bypass firewalls
- **🔒 Userspace Implementation**: No kernel modules required, safer and more portable
- **🛡️ Modern Cryptography**: ChaCha20, Poly1305, Curve25519, BLAKE2s
- **🚫 No Logs**: Your traffic and connection data are never stored

### 🚀 Easy Deployment
- **🐳 Full Docker Stack**: Everything containerized with docker-compose
- **⚡ One-Command Setup**: `make up` and you're running in under 2 minutes
- **🎯 Auto Configuration**: Automatically detects your server's public IP
- **🔧 Smart Networking**: Handles iptables, routing, and DNS automatically
- **📦 All-in-One**: Server + web interface + client configs in one package

### 📱 Client Management
- **📱 QR Code Generation**: Instant mobile device setup
- **👥 Multi-Client Support**: Add unlimited devices with unique configs
- **🎛️ Easy Management**: Simple Makefile commands for all operations
- **📋 Config Export**: Download .conf files for any WireGuard client
- **🔄 Bulk Operations**: Add/remove multiple clients efficiently

### 📊 Monitoring & Control
- **📈 Real-time Status**: Live connection monitoring and bandwidth stats
- **📋 Connection Logs**: See who's connected and data usage
- **🌐 Web Interface**: Browser-based management (optional)
- **🔍 Debug Tools**: Built-in diagnostics and troubleshooting
- **📊 Bandwidth Monitoring**: Track data usage per client

### 🌍 Global Compatibility
- **🌏 Works Everywhere**: Tested in China, Iran, Russia, UAE, and more
- **📡 Multiple Ports**: Supports custom ports and protocols
- **🔀 Protocol Flexibility**: HTTP/HTTPS masquerading options
- **🌐 IPv4/IPv6 Support**: Dual-stack networking ready
- **⚡ High Performance**: Optimized for speed and low latency

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

| Platform | Link |
|----------|------|
| 🐛 **Issues** | [GitHub Issues](https://github.com/asychin/amnezia-wg-docker/issues) |
| 💬 **Discussions** | [GitHub Discussions](https://github.com/asychin/amnezia-wg-docker/discussions) |
| 📧 **Contact** | [Email](mailto:asychin@users.noreply.github.com) |

</div>

---

## 📄 License

<div align="center">

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

**Copyright © 2024 [asychin](https://github.com/asychin)**

</div>
