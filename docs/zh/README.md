# 🔒 AmneziaWG Docker Server - 完整指南

<div align="center">

**生产就绪的 AmneziaWG VPN 服务器 Docker 解决方案，支持 DPI 绕过功能**

[![GitHub Release](https://img.shields.io/github/v/release/asychin/amnezia-wg-docker?style=flat-square&logo=github)](../../releases)
[![Docker Pulls](https://img.shields.io/docker/pulls/asychin/amnezia-wg-docker?style=flat-square&logo=docker)](https://hub.docker.com/r/asychin/amnezia-wg-docker)
[![GitHub Container Registry](https://img.shields.io/badge/ghcr.io-asychin%2Famnezia--wg--docker-blue?style=flat-square&logo=docker)](https://ghcr.io/asychin/amnezia-wg-docker)
[![GitHub Stars](https://img.shields.io/github/stars/asychin/amnezia-wg-docker?style=flat-square&logo=github)](../../stargazers)

> 🍴 **分叉了此仓库？** 将上面徽章中的 `asychin/amnezia-wg-docker` 替换为 `yourusername/amnezia-wg-docker`。

**🌍 语言: [🇺🇸 English](../en/README.md) | [🇷🇺 Русский](../ru/README.md) | [🇨🇳 中文](../zh/README.md)**

</div>

---

## 🌟 特性

- ✅ **AmneziaWG 用户空间** - 无需内核模块即可运行
- ✅ **DPI 绕过** - 将 VPN 流量伪装成 HTTPS
- ✅ **Docker 容器** - 简单部署
- ✅ **自动 IP 检测** - 通过 8 个服务智能发现公网 IP
- ✅ **自动配置** - iptables、路由、DNS 配置
- ✅ **二维码** - 快速客户端连接
- ✅ **客户端管理** - 通过 Makefile 添加/删除
- ✅ **监控** - 日志和连接状态

---

## 🚀 快速开始

### 1. 克隆并包含子模块

```bash
git clone --recursive https://github.com/asychin/amnezia-wg-docker.git
cd amnezia-wg-docker

# 如果忘记了 --recursive:
git submodule update --init --recursive
```

### 2. 启动服务器

```bash
# 构建和启动
make build
make up

# 检查状态
make status
```

### 3. 获取客户端配置

```bash
# 显示第一个客户端的二维码
make client-qr client1

# 创建新客户端
make client-add name=myclient ip=10.13.13.10
```

---

## 📋 系统要求

- **Docker** >= 20.10
- **Docker Compose** >= 1.29
- **Linux** 主机支持 TUN/TAP
- **特权模式** 或访问 `/dev/net/tun`

### ⚠️ 重要: TUN 设备

AmneziaWG 需要访问 TUN 接口。确保：

1. **TUN 模块已加载:**
   ```bash
   # 检查模块
   lsmod | grep tun
   
   # 如果需要加载
   sudo modprobe tun
   ```

2. **TUN 设备存在:**
   ```bash
   # 检查设备
   ls -la /dev/net/tun
   
   # 如果需要创建
   sudo mkdir -p /dev/net
   sudo mknod /dev/net/tun c 10 200
   sudo chmod 666 /dev/net/tun
   ```

3. **Docker 使用正确的标志运行** (见部署章节)

### Docker 安装 (Ubuntu/Debian)

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装 Docker
sudo apt install -y docker.io docker-compose

# 将用户添加到 docker 组
sudo usermod -aG docker $USER
newgrp docker

# 验证安装
docker --version
docker-compose --version
```

---

## ⚙️ 配置

### 环境变量 (.env)

创建 `.env` 文件或编辑 `env.example`:

```bash
# 主要设置
AWG_INTERFACE=awg0
AWG_PORT=51820
AWG_NET=10.13.13.0/24
AWG_SERVER_IP=10.13.13.1
AWG_DNS=8.8.8.8,8.8.4.4

# 公网 IP (如果未指定则自动检测)
# SERVER_PUBLIC_IP=YOUR_SERVER_IP

# 客户端设置
CLIENTS_SUBNET=10.13.13.0/24
ALLOWED_IPS=0.0.0.0/0

# AmneziaWG DPI 绕过混淆参数
AWG_JC=7
AWG_JMIN=50
AWG_JMAX=1000
AWG_S1=86
AWG_S2=574
AWG_H1=1
AWG_H2=2
AWG_H3=3
AWG_H4=4

# 额外设置
# AWG_DISABLE_IPTABLES=true  # 禁用 iptables (适用于 CI/CD 或受限环境)
```

### 混淆参数设置

混淆参数将 VPN 流量伪装成常规 HTTPS:

- **Jc** (7) - 抖动强度
- **Jmin/Jmax** (50/1000) - "垃圾"数据包的最小/最大大小
- **S1/S2** (86/574) - 用于伪装的标头大小
- **H1-H4** (1/2/3/4) - 混淆的哈希函数

---

## 🛠️ 管理

### Makefile 命令

```bash
# 基本命令
make build          # 构建容器
make up             # 启动服务器
make down           # 停止服务器
make restart        # 重启
make logs           # 查看日志
make status         # 服务器和连接状态

# 客户端管理
make client-add name=client2 ip=10.13.13.3   # 添加客户端
make client-rm name=client2                   # 删除客户端
make client-qr name=client1                   # 显示二维码
make client-list                              # 列出客户端

# 调试
make shell          # 进入容器
make clean          # 清理 (停止 + 删除数据)
```

### 手动客户端管理

```bash
# 进入容器
docker-compose exec amneziawg-server bash

# 添加客户端
/app/scripts/manage-clients.sh add myclient 10.13.13.5

# 删除客户端
/app/scripts/manage-clients.sh remove myclient

# 显示状态
awg show awg0
```

### 🚀 Bash 自动补全

为方便使用，包含了 make 命令的自动补全:

```bash
# 在当前会话中加载
source amneziawg-autocomplete.bash

# 永久安装
echo "source $(pwd)/amneziawg-autocomplete.bash" >> ~/.bashrc
```

**功能:**
- 🎯 所有 `make` 命令的自动补全
- 👥 客户端名称和 IP 地址
- 🚀 快速函数: `awg_add_client`, `awg_qr`, `awg_status`

```bash
# 示例 (按 TAB)
make client-add name=<TAB>     # 客户端名称
make client-qr name=<TAB>      # 现有客户端
awg_add_client mobile          # 快速添加
awg_help                       # 自动补全帮助
```

---

## 🚀 部署

### 方法1: Docker Compose (推荐)

```bash
# 使用 docker-compose 快速启动
make build && make up

# 检查状态
make status
```

Docker Compose 已在 `docker-compose.yml` 中配置了正确参数:
- `privileged: true` - 完整容器权限
- `devices: - /dev/net/tun` - 访问 TUN 设备
- `cap_add: [NET_ADMIN, SYS_MODULE]` - 网络功能

### 方法2: Docker run (手动)

```bash
# 构建镜像
docker build -t amneziawg-server .

# 使用必要权限运行
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

### 方法3: 云提供商

对于 **VPS/VDS** 服务器 (DigitalOcean, Vultr, Hetzner 等):

```bash
# 确保 TUN 模块可用
lsmod | grep tun || sudo modprobe tun

# 如果需要创建 TUN 设备
sudo mkdir -p /dev/net
sudo mknod /dev/net/tun c 10 200
sudo chmod 666 /dev/net/tun

# 正常启动
make build && make up
```

### ⚠️ TUN 故障排除

如果遇到错误 `CreateTUN("awg0") failed; /dev/net/tun does not exist`:

1. **检查主机上的 TUN 可用性:**
   ```bash
   ls -la /dev/net/tun
   cat /dev/net/tun  # 应该返回 "cat: /dev/net/tun: File descriptor in bad state"
   ```

2. **对于不使用特权的 Docker (不推荐):**
   ```bash
   # 添加到 docker-compose.yml 或 docker run:
   --cap-add=NET_ADMIN --device=/dev/net/tun
   ```

3. **对于 Podman 或其他运行时:**
   ```bash
   # 在您的运行时使用类似标志
   podman run --privileged --device=/dev/net/tun ...
   ```

---

## 📱 客户端连接

### Android/iOS (AmneziaVPN)

1. 安装 [AmneziaVPN](https://amnezia.org/)
2. 获取二维码: `make client-qr name=client1`
3. 在应用中扫描二维码
4. 连接!

### 桌面 (AmneziaWG 客户端)

1. 下载配置:
   ```bash
   docker-compose exec amneziawg-server cat /app/clients/client1.conf > client1.conf
   ```
2. 与兼容客户端一起使用

### 客户端配置示例

```ini
[Interface]
PrivateKey = <客户端私钥>
Address = 10.13.13.2/32
DNS = 8.8.8.8

[Peer]
PublicKey = <服务器公钥>
Endpoint = 203.0.113.123:51820        # 自动检测的 IP
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25

# AmneziaWG 混淆参数
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

## 🔧 架构

### 组件

```
┌─────────────────────────────────────────┐
│             Docker Container            │
│  ┌─────────────────────────────────────┐ │
│  │         amneziawg-go               │ │  ← 用户空间 VPN
│  │         (进程 PID)                  │ │
│  └─────────────────────────────────────┘ │
│  ┌─────────────────────────────────────┐ │
│  │         amneziawg-tools            │ │  ← 管理工具
│  │         (awg, awg-quick)           │ │
│  └─────────────────────────────────────┘ │
│  ┌─────────────────────────────────────┐ │
│  │         iptables rules             │ │  ← NAT 和防火墙
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
              │
              │ 51820/UDP
              ▼
        [ 互联网 ]
              │
              ▼
     [ VPN 客户端 ]
```

### 网络图

```
客户端 (10.13.13.2) ──┐
                      │
客户端 (10.13.13.3) ──┤
                      │    VPN 隧道       ┌─ 互联网
                      ├───────────────────┤
客户端 (10.13.13.4) ──┤                   └─ 网站/服务
                      │
客户端 (10.13.13.5) ──┘
                 
        VPN 网络: 10.13.13.0/24
        服务器: 10.13.13.1
        端口: 51820/UDP
```

---

## 🌐 自动公网 IP 检测

### 智能外部 IP 地址发现

系统自动确定服务器的公网 IP 地址，用于创建正确的客户端配置。这解决了在云中或 NAT 后面部署时 VPN 无法工作的问题。

### 支持的服务

自动检测按优先级顺序使用可靠的外部服务:

1. **https://eth0.me** - 快速可靠的服务
2. **https://ipv4.icanhazip.com** - 流行的备用服务
3. **https://api.ipify.org** - IP 检测的 JSON API
4. **https://checkip.amazonaws.com** - 官方 AWS 服务
5. **https://ipinfo.io/ip** - 详细地理信息
6. **https://ifconfig.me/ip** - 经典 Unix 服务
7. **http://whatismyip.akamai.com** - 来自 CDN 提供商 Akamai
8. **http://i.pn** - 极简快速

### 配置

```bash
# 在 .env 文件中设置以下值之一:

# 1. 自动检测 (推荐)
SERVER_PUBLIC_IP=auto

# 2. 特定 IP 地址
SERVER_PUBLIC_IP=203.0.113.123

# 3. 空值 = 自动检测
SERVER_PUBLIC_IP=
```

### IP 检测过程

```bash
# 创建客户端时您将在日志中看到:
[INFO] 自动确定公网 IP...
[INFO] 尝试服务: https://eth0.me
[INFO] ✅ 公网 IP 已确定: 203.0.113.123 (通过 https://eth0.me)
```

### 错误处理

当所有服务都不可用时，系统:
- ⚠️ 显示警告
- 📝 显示手动设置说明
- 🔧  设置特殊端点以识别问题

```bash
# 在所有服务失败的情况下:
[WARN] ⚠️ 无法自动确定公网 IP!
[WARN] 使用回退 IP。必须在 .env 文件中指定正确的 IP:
[WARN] echo 'SERVER_PUBLIC_IP=YOUR_PUBLIC_IP' > .env
```

### IP 地址验证

系统验证接收到的 IP 地址:
- ✅ IPv4 格式正确性
- ✅ 有效范围 (1-255.0-255.0-255.0-255)
- ✅ 排除无效地址

### 性能

- ⚡ **超时**: 每个服务 10-15 秒
- 🔄 **尝试**: 最多 8 个不同服务
- 💾 **缓存**: IP 在会话中用于所有客户端

---

## 🛡️ 安全

### 防火墙

确保只开放必要的端口:

```bash
# UFW (Ubuntu)
sudo ufw allow 51820/udp
sudo ufw enable

# iptables
sudo iptables -A INPUT -p udp --dport 51820 -j ACCEPT
```

### SSL/TLS

AmneziaWG 使用强大的加密:
- **ChaCha20Poly1305** - 对称加密
- **Curve25519** - 密钥交换
- **BLAKE2s** - 哈希

### 密钥

- 自动生成加密强密钥
- 私钥以 600 权限存储
- 定期密钥轮换 (推荐)

---

## 🔍 监控和诊断

### 查看状态

```bash
# 一般状态
make status

# 详细信息
docker-compose exec amneziawg-server awg show awg0

# 活跃连接
docker-compose exec amneziawg-server awg show awg0 latest-handshakes
```

### 日志

```bash
# 实时
make logs

# 最后 100 行
docker-compose logs --tail=100 amneziawg-server

# 带时间戳的日志
docker-compose logs -t amneziawg-server
```

### 问题诊断

```bash
# 检查进程
docker-compose exec amneziawg-server ps aux | grep amneziawg

# 检查接口
docker-compose exec amneziawg-server ip addr show awg0

# 检查路由
docker-compose exec amneziawg-server ip route

# 检查 iptables
docker-compose exec amneziawg-server iptables -L -n
```

---

## 🚨 故障排除

### 容器无法启动

```bash
# 检查镜像
docker images | grep amneziawg

# 重新构建
make clean
make build
```

### 客户端无法连接

1. **检查防火墙:**
   ```bash
   sudo ufw status
   sudo iptables -L INPUT | grep 51820
   ```

2. **检查公网 IP:**
   ```bash
   curl ifconfig.me
   ```

3. **检查端口:**
   ```bash
   sudo netstat -ulnp | grep 51820
   ```

### 通过 VPN 无法上网

1. **检查 IP 转发:**
   ```bash
   cat /proc/sys/net/ipv4/ip_forward  # 应该是 1
   ```

2. **检查 NAT 规则:**
   ```bash
   docker-compose exec amneziawg-server iptables -t nat -L
   ```

### DPI 阻止连接

1. **更改混淆参数:**
   ```bash
   # 在 .env 文件中更改:
   AWG_JC=9
   AWG_JMIN=75
   AWG_JMAX=1200
   AWG_S1=96
   AWG_S2=684
   ```

2. **更改端口:**
   ```bash
   AWG_PORT=443  # HTTPS 端口
   # 或
   AWG_PORT=53   # DNS 端口
   ```

---

## 📚 额外资源

### 官方文档

- [AmneziaVPN](https://docs.amnezia.org/)
- [AmneziaWG](https://docs.amnezia.org/en/documentation/amnezia-wg/)
- [WireGuard](https://www.wireguard.com/)

### 仓库

- [amneziawg-go](https://github.com/amnezia-vpn/amneziawg-go) - 用户空间实现
- [amneziawg-tools](https://github.com/amnezia-vpn/amneziawg-tools) - 管理工具
- [amneziawg-linux-kernel-module](https://github.com/amnezia-vpn/amneziawg-linux-kernel-module) - 内核模块

### 社区

- [Telegram 频道](https://t.me/amnezia_vpn)
- [GitHub Issues](https://github.com/amnezia-vpn/amnezia-client/issues)

---

## 👨‍💻 Docker 实现作者

这个 AmneziaWG 的 Docker 实现由 [@asychin](https://github.com/asychin) 创建。

**🔗 联系作者:**
- **GitHub:** [@asychin](https://github.com/asychin)
- **Telegram:** [@BlackSazha](https://t.me/BlackSazha)
- **Email:** moloko@skofey.com
- **Website:** [cheza.dev](https://cheza.dev)

**⚠️ 重要:**
- 主要的 AmneziaWG VPN 服务器由 [Amnezia VPN 团队](https://github.com/amnezia-vpn) 开发
- 此实现仅包含 Docker 容器化和管理脚本
- 有关 VPN 服务器问题，请联系 [原始开发者](https://github.com/amnezia-vpn/amneziawg-go)

---

## 🤝 参与贡献

### 项目结构

```
amneziawg-docker/
├── .gitmodules              # Git 子模块
├── amneziawg-go/           # 子模块: 用户空间实现
├── amneziawg-tools/        # 子模块: 管理工具
├── scripts/                # 容器脚本
│   ├── entrypoint.sh       # 主要启动脚本
│   ├── manage-clients.sh   # 客户端管理
│   ├── post-up.sh         # 接口启动后脚本
│   └── post-down.sh       # 接口关闭后脚本
├── Dockerfile              # 容器镜像
├── docker-compose.yml      # 服务配置
├── Makefile               # 管理工具
├── env.example            # 环境变量示例
└── README.md              # 此文档
```

### 更新子模块

```bash
# 更新所有子模块
git submodule update --remote

# 更新特定子模块
git submodule update --remote amneziawg-go
```

---

## 📄 许可证

此项目在 MIT 许可证下分发。详情请参见 [LICENSE](../../LICENSE) 文件。

**注意:** AmneziaWG 组件可能有自己的许可证:
- amneziawg-go: MIT License
- amneziawg-tools: GPL-2.0 License

---

## ⚠️ 免责声明

此软件按"原样"提供。作者不对使用造成的任何后果负责。用户必须遵守其管辖区的法律。

**记住:** VPN 不保证 100% 匿名。使用额外的安全措施。
