# AmneziaWG Docker Server

Self-hosted VPN server based on AmneziaWG protocol with web management interface.

AmneziaWG is a modified WireGuard protocol with DPI (Deep Packet Inspection) obfuscation capabilities, designed to bypass network censorship and VPN blocking.

## Features

**VPN Server**
- AmneziaWG protocol with DPI obfuscation
- Automatic key generation and client management
- QR code generation for mobile clients
- One-time config download with ZIP bundle (config + QR code)

**Web Interface (v2.0)**
- Modern React dashboard with real-time statistics
- Client management with search and sorting
- Dark mode support
- Migration tools from v1.x
- Responsive design for mobile devices

**Infrastructure**
- Docker-based deployment
- PostgreSQL database for metadata storage
- Automatic backups with retention policy
- Bash autocomplete for all commands

## Quick Start

```bash
# Clone repository
git clone https://github.com/asychin/amnezia-wg-docker.git
cd amnezia-wg-docker

# Initialize and start full stack (VPN + Web + PostgreSQL)
make init
make up

# Add a client
make client-add name=myphone

# Get QR code
make client-qr name=myphone
```

Web interface will be available at http://localhost:8080

## Requirements

- Docker Engine 20.10+
- Docker Compose v2.0+
- Linux host with kernel 5.6+ (for WireGuard support)
- UDP port 51820 open for VPN traffic
- TCP port 8080 open for web interface (optional)

## Installation

### Option 1: Full Stack (Recommended)

Deploys VPN server, web interface, and PostgreSQL database:

```bash
make up
```

### Option 2: VPN Only

For minimal deployment without web interface (compatible with v1.x):

```bash
make up-vpn
```

## Configuration

Copy the example environment file and customize:

```bash
cp env.example .env
```

Key configuration options:

| Variable | Default | Description |
|----------|---------|-------------|
| `WG_HOST` | auto-detect | Public IP or domain for VPN |
| `WG_PORT` | 51820 | UDP port for WireGuard |
| `WG_DEFAULT_DNS` | 1.1.1.1 | DNS server for clients |
| `WG_ALLOWED_IPS` | 0.0.0.0/0 | Allowed IP ranges |
| `WG_PERSISTENT_KEEPALIVE` | 25 | Keepalive interval (seconds) |
| `DATABASE_URL` | postgres://... | PostgreSQL connection string |

### AmneziaWG Obfuscation Parameters

These parameters enable DPI bypass:

| Variable | Default | Description |
|----------|---------|-------------|
| `JC` | 4 | Junk packet count |
| `JMIN` | 40 | Minimum junk packet size |
| `JMAX` | 70 | Maximum junk packet size |
| `S1` | 0 | Init packet junk size |
| `S2` | 0 | Response packet junk size |
| `H1` | 1 | Init packet header |
| `H2` | 2 | Response packet header |
| `H3` | 3 | Cookie packet header |
| `H4` | 4 | Transport packet header |

## Client Management

### Add Client

```bash
# Auto-assign IP
make client-add name=laptop

# Specify IP
make client-add name=phone ip=10.13.13.5
```

### List Clients

```bash
make client-list
```

### Get Configuration

```bash
# Show QR code in terminal
make client-qr name=laptop

# Show text config
make client-config name=laptop
```

### Remove Client

```bash
make client-rm name=laptop
```

## Web Interface

The web interface provides a modern dashboard for managing VPN clients.

### Features

- **Dashboard**: Overview of server status, client statistics, and quick actions
- **Clients**: List, search, sort, add, and remove VPN clients
- **Settings**: Migration tools, database management, system information
- **Dark Mode**: Toggle between light and dark themes

### One-Time Config Download

For security, client configurations can be downloaded only once. The download includes:
- WireGuard configuration file (.conf)
- QR code image (.png)
- Installation instructions (README.txt)

After download, the config buttons are hidden and only statistics are shown.

## Database

PostgreSQL stores client metadata (name, IP, public key, timestamps). Private keys are stored only in files, never in the database.

### Database Commands

```bash
# View PostgreSQL logs
make db-logs

# Connect to database
make db-psql

# Backup database
make db-backup

# Restore database
make db-restore file=backups/db/backup.sql
```

## Backups

Automatic backups are created before potentially destructive operations.

### Backup Structure

```
backups/
  files/    # Config files, client keys, .env
  db/       # PostgreSQL dumps
```

### Manual Backup

```bash
make backup
```

### Restore

```bash
make restore file=backups/files/amneziawg-backup-20241205.tar.gz
```

### Cleanup Old Backups

```bash
make backup-cleanup
```

## Monitoring

### Server Status

```bash
make status
```

### View Logs

```bash
# VPN server logs
make logs

# Web interface logs
make web-logs

# Database logs
make db-logs

# All services
make stack-logs
```

### Real-time Monitoring

```bash
make monitor
```

## Migration from v1.x

If upgrading from v1.x (file-based configuration):

1. Start the full stack: `make up`
2. Open web interface: http://localhost:8080
3. Go to Settings > Migration
4. Click "Sync" to import existing clients

Existing configuration files are preserved.

## Troubleshooting

### Server won't start

```bash
# Check Docker status
docker ps -a

# View detailed logs
make debug
```

### Clients can't connect

1. Verify UDP port 51820 is open in firewall
2. Check server logs: `make logs`
3. Verify client config matches server settings

### Web interface not accessible

```bash
# Check web service status
make web-status

# View web logs
make web-logs
```

### Database connection issues

```bash
# Check database status
make db-status

# View database logs
make db-logs
```

## Security Considerations

- Private keys are stored only in files, not in the database
- One-time config download prevents config reuse
- Database contains only metadata (no secrets)
- Automatic backups protect against data loss
- All traffic is encrypted with WireGuard protocol

## Development

### Local Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

### Build for Production

```bash
npm run build
```

### Type Checking

```bash
npx tsc --noEmit
```

## Command Reference

Run `make` or `make help` to see all available commands:

**Stack Management**
- `make up` - Start full stack (VPN + Web + PostgreSQL)
- `make up-vpn` - Start VPN only
- `make down` - Stop all services
- `make restart` - Restart services
- `make status` - Show status

**Client Management**
- `make client-add name=X` - Add client
- `make client-rm name=X` - Remove client
- `make client-qr name=X` - Show QR code
- `make client-config name=X` - Show config
- `make client-list` - List all clients

**Web Interface**
- `make web-logs` - View web logs
- `make web-status` - Check web status
- `make web-restart` - Restart web service

**Database**
- `make db-logs` - View database logs
- `make db-psql` - Connect to PostgreSQL
- `make db-backup` - Backup database
- `make db-restore file=X` - Restore database

**Maintenance**
- `make backup` - Create backup
- `make restore file=X` - Restore from backup
- `make update` - Update and rebuild
- `make clean` - Remove all data

## License

MIT License

## Credits

- **Docker Implementation**: [asychin](https://github.com/asychin)
- **AmneziaWG Protocol**: [Amnezia VPN Team](https://github.com/amnezia-vpn)
- **WireGuard**: [Jason A. Donenfeld](https://www.wireguard.com/)
