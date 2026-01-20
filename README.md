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
| `AWG_JC` | 3-10 | Junk packet count |
| `AWG_JMIN` | 40-80 | Min junk packet size |
| `AWG_JMAX` | 500-1000 | Max junk packet size |
| `AWG_S1` | 50-100 | Header size modifier 1 |
| `AWG_S2` | 100-200 | Header size modifier 2 |
| `AWG_H1-H4` | 1-4 | Hash function selectors |

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
