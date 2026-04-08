# AmneziaWG Docker Server

A containerized VPN server with DPI bypass capabilities. Based on AmneziaWG v2 protocol for traffic obfuscation.

## Features

- One-minute installation with automated setup
- DPI bypass through traffic obfuscation (AmneziaWG v2 — S1/S2/S3/S4)
- Userspace mode (no kernel modules required)
- QR code and vpn:// URI generation for mobile clients
- Automatic backups with sidecar service
- Built-in health checks and monitoring

## Quick Start

```bash
# Clone with submodules
git clone --recursive https://github.com/asychin/amnezia-wg-docker.git
cd amnezia-wg-docker

# Start server
make up

# Add a client (automatically shows QR + vpn:// URI)
make client-add john

# Show QR code for mobile
make client-qr john

# Show vpn:// URI for AmneziaVPN import
make client-vpnurl john
```

If you forgot `--recursive` when cloning:
```bash
git submodule update --init --recursive
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
| `make reload` | Reload configuration (without restart) |
| `make status` | Show server status |
| `make logs` | View logs |
| `make build` | Build Docker image (with cache) |
| `make rebuild` | Rebuild Docker image (no cache) |

### Client Management

| Command | Description |
|---------|-------------|
| `make client-add john` | Add client |
| `make client-add john 10.13.13.5` | Add client with specific IP |
| `make client-rm john` | Remove client |
| `make client-qr john` | Show QR code |
| `make client-config john` | Show configuration |
| `make client-vpnurl john` | Show vpn:// URI |
| `make client-list` | List all clients |

### Backup and Restore

| Command | Description |
|---------|-------------|
| `make backup` | Create manual backup |
| `make restore file=backups/file.tar.gz` | Restore from backup |
| `make backup-cleanup` | Remove old backups |
| `make backup-verify file=backups/file.tar.gz` | Verify backup integrity |

### Utilities

| Command | Description |
|---------|-------------|
| `make shell` | Enter container shell |
| `make debug` | Show diagnostics |
| `make test` | Test server connectivity |
| `make clean` | Full cleanup (removes all data) |
| `make version` | Show version |

## Configuration

Copy `.env.example` to `.env` and edit as needed. Key settings:

| Variable | Default | Description |
|----------|---------|-------------|
| `AWG_PORT` | 51820 | UDP port (use 443 or 53 to mimic HTTPS/DNS) |
| `AWG_NET` | 10.13.13.0/24 | VPN network |
| `AWG_DNS` | 8.8.8.8,8.8.4.4 | DNS servers for clients |
| `SERVER_PUBLIC_IP` | auto | Server public IP (auto-detected) |

### Obfuscation Parameters (AmneziaWG v2)

These are randomly generated on first `make init`:

| Variable | Range | Description |
|----------|-------|-------------|
| `AWG_JC` | 4-12 | Junk packet count |
| `AWG_JMIN` | 8-50 | Min junk packet size |
| `AWG_JMAX` | 80-250 | Max junk packet size |
| `AWG_S1` | 15-150 | Junk data size for init packets |
| `AWG_S2` | 15-150 | Junk data size for response packets |
| `AWG_S3` | 0-1216 | Junk data size for cookie packets **(v2 NEW)** |
| `AWG_S4` | 0-32 | Junk data size for data packets **(v2 NEW)** |
| `AWG_H1-H4` | 5-2147483647 | Magic header values (unique 32-bit integers) |

Note: S1 and S2 are constrained so that `S1 + 56 != S2` to ensure different packet sizes.

## Scheduled Backups

Backups run automatically as a sidecar container in docker-compose:

```bash
# Manual backup
make backup

# Restore
make restore file=backups/amneziawg-20240101-120000.tar.gz
```

Configure in `.env`:
- `BACKUP_INTERVAL` - Backup interval (default: 24h)
- `BACKUP_KEEP` - Number of backups to keep (default: 10)

## Mobile Setup

1. Install AmneziaVPN ([Android](https://play.google.com/store/apps/details?id=org.amnezia.vpn) / [iOS](https://apps.apple.com/app/amneziavpn/id1600529900))
2. **Option 1 (QR code):** `make client-qr <name>` → scan the QR code
3. **Option 2 (vpn:// URI):** `make client-vpnurl <name>` → copy the string and paste into the app
4. Connect

## File Structure

```
amnezia-wg-docker/
├── config/           # Server configuration
├── clients/          # Client configurations
├── backups/          # Backup archives
├── scripts/          # Runtime scripts
│   ├── common.sh     # Shared library (logging, validation, IP detection)
│   ├── entrypoint.sh # Container entrypoint
│   ├── manage-clients.sh # Client management
│   ├── generate-vpn-uri.sh # vpn:// URI generation
│   ├── backup.sh     # Automatic backups
│   ├── healthcheck.sh # Health checks
│   └── diagnose.sh   # Diagnostics
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
