# AmneziaWG Docker Server

A containerized VPN server with DPI bypass capabilities. Based on AmneziaWG protocol for traffic obfuscation.

## Features

- One-minute installation with automated setup
- DPI bypass through traffic obfuscation
- Userspace mode (no kernel modules required)
- QR code generation for mobile clients
- Automatic backups with scheduled backup service
- Built-in health checks and monitoring

## Quick Start

```bash
# Clone with submodules
git clone --recursive https://github.com/asychin/amnezia-wg-docker.git
cd amnezia-wg-docker

# Start server
make up

# Add a client
make client-add john

# Show QR code for mobile
make client-qr john
```

If you forgot `--recursive` when cloning:
```bash
git submodule update --init --recursive
```

## VPN Scenarios

This project supports two VPN scenarios:

### Scenario 1: Standard VPN (default)

All client traffic goes through the VPN server. Use this for accessing blocked websites or protecting your traffic.

```bash
make init    # Standard initialization
make up      # Start server
```

Client configuration uses `AllowedIPs = 0.0.0.0/0` to route all traffic through VPN.

### Scenario 2: Site-to-Site VPN

VPN clients can access devices in the server's local network. Use this when you need to access servers, printers, or other devices on the VPN server's LAN.

S2S mode runs natively on the host (without Docker) for stable connections:

```bash
make init-s2s        # Initialize S2S configuration (prompts for local subnet)
make install-s2s     # Install S2S mode (compiles AmneziaWG, creates systemd service)
make start-s2s       # Start the server
make enable-s2s      # Enable auto-start on boot
```

S2S commands:
- `make install-s2s` - Install S2S mode (compiles AmneziaWG, creates systemd service)
- `make uninstall-s2s` - Uninstall S2S mode
- `make start-s2s` - Start S2S server
- `make stop-s2s` - Stop S2S server
- `make restart-s2s` - Restart S2S server
- `make status-s2s` - Show S2S status
- `make logs-s2s` - View S2S logs
- `make enable-s2s` - Enable auto-start on boot
- `make disable-s2s` - Disable auto-start

**Configuration**

During `init-s2s`, you'll be asked for the server's local network subnet (e.g., `192.168.1.0/24`). The script will:
- Set `SERVER_SUBNET` to your local network
- Configure `AllowedIPs` to include the local subnet
- Enable masquerading for local network access

You can also configure manually in `.env`:
```bash
SERVER_SUBNET=192.168.1.0/24
ALLOWED_IPS=192.168.1.0/24,10.13.13.0/24
```

## Requirements

- Docker 20.10+
- Docker Compose 2.0+
- Git

## Commands

### Main Commands

| Command | Description |
|---------|-------------|
| `make up` | Start VPN server |
| `make down` | Stop server |
| `make restart` | Restart server |
| `make status` | Show server status |
| `make logs` | View logs |
| `make build` | Build Docker image |

### Client Management

| Command | Description |
|---------|-------------|
| `make client-add john` | Add client (simple syntax) |
| `make client-add john 10.13.13.5` | Add client with specific IP |
| `make client-add name=john ip=10.13.13.5` | Add client (key=value syntax) |
| `make client-rm john` | Remove client |
| `make client-qr john` | Show QR code |
| `make client-config john` | Show configuration |
| `make client-list` | List all clients |

### Backup and Restore

| Command | Description |
|---------|-------------|
| `make backup` | Create manual backup |
| `make restore file=backups/file.tar.gz` | Restore from backup |
| `make backup-start` | Start scheduled backup service |
| `make backup-stop` | Stop scheduled backup service |
| `make backup-cleanup` | Remove old backups (keep last 10) |

### Utilities

| Command | Description |
|---------|-------------|
| `make shell` | Enter container shell |
| `make debug` | Show debug information |
| `make test` | Test server connectivity |
| `make clean` | Full cleanup (removes all data) |
| `make autocomplete-install` | Install bash autocomplete |

## Configuration

Copy `.env.example` to `.env` and edit as needed. Key settings:

| Variable | Default | Description |
|----------|---------|-------------|
| `AWG_PORT` | 51820 | UDP port (use 443 or 53 to mimic HTTPS/DNS) |
| `AWG_NET` | 10.13.13.0/24 | VPN network |
| `AWG_DNS` | 8.8.8.8,8.8.4.4 | DNS servers for clients |
| `SERVER_PUBLIC_IP` | auto | Server public IP (auto-detected) |

### Obfuscation Parameters

These are randomly generated on first `make init`:

| Variable | Range | Description |
|----------|-------|-------------|
| `AWG_JC` | 4-12 | Junk packet count |
| `AWG_JMIN` | 8-50 | Min junk packet size |
| `AWG_JMAX` | 80-250 | Max junk packet size |
| `AWG_S1` | 15-150 | Junk data size for init packets |
| `AWG_S2` | 15-150 | Junk data size for response packets |
| `AWG_H1-H4` | 5-2147483647 | Magic header values (unique 32-bit integers) |

Note: S1 and S2 are constrained so that `S1 + 56 != S2` to ensure different packet sizes.

## Scheduled Backups

Start the backup sidecar container for automatic backups:

```bash
make backup-start
```

Configure in `.env`:
- `BACKUP_INTERVAL` - Backup interval (default: 24h)
- `BACKUP_KEEP` - Number of backups to keep (default: 10)

## Mobile Setup

1. Install AmneziaVPN app ([Android](https://play.google.com/store/apps/details?id=org.amnezia.vpn) / [iOS](https://apps.apple.com/app/amneziavpn/id1600529900))
2. Run `make client-qr <name>` to display QR code
3. Scan QR code with the app
4. Connect

## File Structure

```
amnezia-wg-docker/
├── config/           # Server configuration
├── clients/          # Client configurations
├── backups/          # Backup archives
├── scripts/          # Runtime scripts
├── amneziawg-go/     # Go implementation (submodule)
└── amneziawg-tools/  # CLI tools (submodule)
```

## Troubleshooting

Check server status:
```bash
make status
make debug
make test
```

View logs:
```bash
make logs
```

Common issues:
- Port already in use: Change `AWG_PORT` in `.env`
- Submodules missing: Run `git submodule update --init --recursive`
- Container not starting: Check `make debug` output

## Documentation

- [Security Guide](SECURITY.md)
- [Migration Guide](MIGRATION.md)
- [CI/CD Pipeline](PIPELINE.md)

## License

MIT License - see [LICENSE](LICENSE)

## Credits

- [AmneziaVPN Team](https://github.com/amnezia-vpn) - Original AmneziaWG protocol
- Docker implementation by [@asychin](https://github.com/asychin)
