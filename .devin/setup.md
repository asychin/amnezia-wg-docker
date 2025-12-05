# AmneziaWG v2.0 - Devin Setup Notes

## Quick Start (Full Stack Mode)

### 1. Start the server
```bash
cd /home/ubuntu/repos/amnezia-wg-docker
docker compose --profile web up -d --build
```

### 2. Expose web interface via cloudflared (for remote testing)
```bash
# Install cloudflared if not present
which cloudflared || (curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb && sudo dpkg -i cloudflared.deb && rm cloudflared.deb)

# Start quick tunnel for web interface (HTTP only)
cloudflared tunnel --url http://localhost:8080
```
This will output a public URL like `https://xxx-xxx-xxx.trycloudflare.com` that the user can access from their browser.

### 3. Check status
```bash
docker ps  # Should show: amneziawg-server, amneziawg-db, amneziawg-web
docker logs amneziawg-web --tail 20  # Check web container logs
```

## Important Notes

### VPN Port (51820/UDP)
- Cloudflared only works with HTTP/HTTPS traffic
- VPN port 51820/UDP cannot be proxied through cloudflared
- For VPN testing, the user needs direct network access to the server

### Web Interface
- Local: http://localhost:8080
- Remote: Use cloudflared quick tunnel (see above)

### Architecture
- Web container uses Docker exec to call VPN container scripts
- Docker socket is mounted in web container for this purpose
- Database schema is auto-created on startup

## Services
| Container | Port | Description |
|-----------|------|-------------|
| amneziawg-server | 51820/UDP | VPN server |
| amneziawg-db | 5432 (internal) | PostgreSQL database |
| amneziawg-web | 8080 | Web interface + API |
