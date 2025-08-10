# 🔒 AmneziaWG Docker Server - 完整指南

<div align="center">

**生产就绪的 AmneziaWG VPN 服务器 Docker 解决方案，支持用户空间实现和 DPI 绕过功能**

[![GitHub Release](https://img.shields.io/github/v/release/asychin/amnezia-wg-docker?style=flat-square&logo=github)](https://github.com/asychin/amnezia-wg-docker/releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/asychin/amnezia-wg-docker?style=flat-square&logo=docker)](https://hub.docker.com/r/asychin/amnezia-wg-docker)
[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-asychin%2Famnezia--wg--docker-blue?style=flat-square&logo=docker)](https://ghcr.io/asychin/amnezia-wg-docker)
[![GitHub Stars](https://img.shields.io/github/stars/asychin/amnezia-wg-docker?style=flat-square&logo=github)](https://github.com/asychin/amnezia-wg-docker/stargazers)

> 🍴 **分叉了此仓库？** 将上面徽章中的 `asychin/amnezia-wg-docker` 替换为 `yourusername/amnezia-wg-docker`。

**🌍 Languages: [🇺🇸 English](../../README.md) | [🇷🇺 Russian](../ru/README.md)**

</div>

---

## 📖 关于项目

此项目提供了带有用户空间实现的**容器化 AmneziaWG VPN 服务器**。AmneziaWG 是基于 WireGuard 的协议，增加了混淆功能来绕过 DPI（深度数据包检测）系统。

### 核心组件：
- **amneziawg-go**: 用户空间实现（不需要内核模块）
- **amneziawg-tools**: 配置和管理工具
- **Docker 容器化**: 简单的部署和管理
- **Makefile 自动化**: 所有操作的简单命令

---

## 🌟 特性

- ✅ **AmneziaWG 用户空间** - 无需内核模块即可运行
- ✅ **DPI 绕过** - 将 VPN 流量伪装成 HTTPS
- ✅ **Docker 容器** - 使用 docker-compose 简单部署
- ✅ **自动 IP 检测** - 通过多个服务智能发现公网 IP
- ✅ **自动配置** - iptables、路由、DNS 配置
- ✅ **二维码** - 快速移动客户端连接
- ✅ **客户端管理** - 通过 Makefile 命令添加/删除客户端
- ✅ **监控** - 实时日志和连接状态
- ✅ **备份/恢复** - 配置管理
- ✅ **健康检查** - 内置服务监控

---

## 🚀 快速开始

### 1. 克隆和初始化

```bash
git clone --recursive https://github.com/asychin/amnezia-wg-docker.git
cd amnezia-wg-docker

# 如果忘记了 --recursive:
git submodule update --init --recursive
```

### 2. 构建和启动

```bash
# 构建 Docker 镜像
make build

# 启动 VPN 服务器
make up

# 检查状态
make status
```

### 3. 添加客户端

```bash
# 添加客户端并自动分配 IP
make client-add name=myphone

# 添加客户端并指定 IP
make client-add name=laptop ip=10.13.13.15

# 显示移动设备配置的二维码
make client-qr name=myphone

# 导出配置文件
make client-config name=laptop > laptop.conf
```

---

## 📋 可用命令

| 命令 | 描述 |
|------|------|
| `make help` | 显示所有可用命令 |
| `make build` | 构建 Docker 镜像 |
| `make up` | 启动 VPN 服务器 |
| `make down` | 停止 VPN 服务器 |
| `make restart` | 重启 VPN 服务器 |
| `make status` | 显示服务器状态和连接 |
| `make logs` | 查看实时日志 |
| `make client-add name=X` | 添加新客户端 |
| `make client-rm name=X` | 删除客户端 |
| `make client-qr name=X` | 显示客户端二维码 |
| `make client-config name=X` | 显示客户端配置 |
| `make client-list` | 列出所有客户端 |
| `make backup` | 创建配置备份 |
| `make clean` | 完全清理（停止 + 删除数据） |

---

## 🛠️ 技术详情

### 网络配置
- **VPN 网络**: `10.13.13.0/24`
- **服务器 IP**: `10.13.13.1`
- **端口**: `51820/udp`
- **DNS**: `8.8.8.8, 8.8.4.4`

### AmneziaWG 混淆参数
- **垃圾包数量 (Jc)**: 7
- **垃圾包最小大小 (Jmin)**: 50
- **垃圾包最大大小 (Jmax)**: 1000
- **初始包垃圾大小**: 86
- **响应包垃圾大小**: 574
- **头部字段**: H1=1, H2=2, H3=3, H4=4

### 系统要求
- Docker 与 Docker Compose
- Git（用于子模块）
- Root 权限（用于网络配置）

---

## 📚 文档

完整文档包含在此文件中。技术细节请参考：
- **🔄 CI/CD Pipeline**: [pipeline.md](pipeline.md)
- **🍴 Fork Setup**: [fork-setup.md](../en/fork-setup.md) (English only)
- **🇺🇸 English version**: [../../README.md](../../README.md)

---

## 🏆 项目信息

<div align="center">

> 💡 **Docker 实现**: [@asychin](https://github.com/asychin) | **原始 VPN 服务器**: [AmneziaWG Team](https://github.com/amnezia-vpn)

**🌟 如果这个项目对您有帮助，请给个星！**

[![GitHub Stars](https://img.shields.io/github/stars/asychin/amnezia-wg-docker?style=for-the-badge&logo=github)](https://github.com/asychin/amnezia-wg-docker/stargazers)

</div>

---

## 📞 支持

<div align="center">

| 平台 | 链接 |
|------|------|
| 🐛 **Issues** | [GitHub Issues](https://github.com/asychin/amnezia-wg-docker/issues) |
| 💬 **讨论** | [GitHub Discussions](https://github.com/asychin/amnezia-wg-docker/discussions) |
| 📧 **联系** | [Email](mailto:asychin@users.noreply.github.com) |

</div>

---

## 📄 许可证

<div align="center">

此项目在 **MIT 许可证**下分发 - 详情请参见 [LICENSE](../../LICENSE) 文件。

**Copyright © 2024 [asychin](https://github.com/asychin)**

</div>
