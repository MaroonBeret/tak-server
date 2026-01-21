# AK as a Service - Operations Runbook

## Quick Reference

### Service URLs
- **TAK Server (HTTPS):** https://tak.karabastactical.nl
- **Admin UI:** https://tak.karabastactical.nl/Marti
- **Health Check:** https://tak.karabastactical.nl/health

### Key Directories
```
tak-server/
├── infra/                          # Production infrastructure
│   ├── docker-compose.prod.yml     # Main compose file
│   ├── .env                        # Environment config (not in git)
│   ├── caddy/Caddyfile            # Reverse proxy config
│   └── scripts/deploy.sh          # Deployment helper
├── customizations/                 # Custom code
│   └── scripts/generate-qr.sh     # QR code generator
└── docs/                          # Documentation
```

## Deployment

### Initial Setup

1. **Prerequisites**
   - Ubuntu VPS with Docker and Docker Compose installed
   - Domain `tak.karabastactical.nl` pointing to VPS IP
   - Ports 80, 443, 8089 open in firewall

2. **Clone and Configure**
   ```bash
   git clone https://github.com/MaroonBeret/tak-server.git
   cd tak-server/infra
   cp .env.example .env
   nano .env  # Edit configuration
   ```

3. **Deploy**
   ```bash
   ./scripts/deploy.sh
   # Select option 1: Build and start
   ```

4. **Enable Certificate Enrollment**
   - Navigate to: https://tak.karabastactical.nl/Marti
   - Login with default credentials (check TAK documentation)
   - Go to: Security → Configuration
   - Enable "Certificate Enrollment"
   - Save changes

### Updates

```bash
cd tak-server/infra
./scripts/deploy.sh
# Select option 2: Pull and restart
```

## User Management

### Create User and Generate QR Codes

```bash
cd customizations/scripts
./generate-qr.sh username [password]
```

This will:
1. Create user in TAK server
2. Generate ATAK QR code (tak:// URI)
3. Generate iTAK QR code (simple format)
4. Save QR images to `./qr-codes/` directory

### Manual User Creation

```bash
# Create user
docker exec tak-server-tak-1 java -jar /opt/tak/utils/UserManager.jar \
    usermod -A -p "password123" "username"

# Delete user
docker exec tak-server-tak-1 java -jar /opt/tak/utils/UserManager.jar \
    userdel "username"

# List users
docker exec tak-server-tak-1 java -jar /opt/tak/utils/UserManager.jar \
    userlist
```

## Monitoring

### Check Service Status

```bash
cd infra
docker compose -f docker-compose.prod.yml ps
```

### View Logs

```bash
# All services
docker compose -f docker-compose.prod.yml logs -f

# Specific service
docker compose -f docker-compose.prod.yml logs -f tak
docker compose -f docker-compose.prod.yml logs -f caddy
docker compose -f docker-compose.prod.yml logs -f db
```

### Health Checks

```bash
# Caddy health endpoint
curl https://tak.karabastactical.nl/health

# Check certificate
curl -vI https://tak.karabastactical.nl/health 2>&1 | grep -A 5 "SSL connection"

# Test enrollment endpoint
curl -k https://tak.karabastactical.nl/Marti/api/tls/config
```

## Troubleshooting

### Issue: "Identity could not be verified" on enrollment

**Cause:** TLS certificate not trusted by device

**Solution:**
1. Check Caddy logs for Let's Encrypt errors
   ```bash
   docker compose -f docker-compose.prod.yml logs caddy | grep -i error
   ```
2. Verify DNS is correct: `dig tak.karabastactical.nl`
3. Check certificate in browser: https://tak.karabastactical.nl/health
4. Restart Caddy: `docker compose -f docker-compose.prod.yml restart caddy`

### Issue: QR scan doesn't work

**ATAK:**
- Ensure ATAK version is 5.1 or higher
- Verify `tak://` URI format is correct
- Check device camera can read QR codes

**iTAK:**
- Verify server string format: `ServerName,domain.com,8089,SSL`
- Ensure credentials are entered correctly
- Check port 8089 is accessible

### Issue: Can't access admin UI

**Check Caddy reverse proxy:**
```bash
# View Caddy logs
docker compose -f docker-compose.prod.yml logs caddy

# Restart Caddy
docker compose -f docker-compose.prod.yml restart caddy

# Test TAK directly (from server)
curl -k https://localhost:8446/Marti
```

### Issue: Services won't start

```bash
# Check what's failing
docker compose -f docker-compose.prod.yml ps

# View startup logs
docker compose -f docker-compose.prod.yml logs

# Rebuild and restart
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d --build
```

### Issue: Database connection errors

```bash
# Check database status
docker compose -f docker-compose.prod.yml logs db

# Restart database
docker compose -f docker-compose.prod.yml restart db

# Access database (if needed)
docker exec -it tak-server-db-1 psql -U postgres
```

## Backup and Recovery

### Backup TAK Data

```bash
# Stop services
cd infra
docker compose -f docker-compose.prod.yml down

# Backup volumes
docker run --rm \
  -v tak-server_db_data:/data \
  -v $(pwd)/backups:/backup \
  ubuntu tar czf /backup/db-backup-$(date +%Y%m%d).tar.gz -C /data .

# Backup TAK certificates and config
tar czf backups/tak-config-$(date +%Y%m%d).tar.gz ../tak/

# Restart services
docker compose -f docker-compose.prod.yml up -d
```

### Restore from Backup

```bash
# Stop services
docker compose -f docker-compose.prod.yml down

# Restore database
docker run --rm \
  -v tak-server_db_data:/data \
  -v $(pwd)/backups:/backup \
  ubuntu tar xzf /backup/db-backup-YYYYMMDD.tar.gz -C /data

# Restore TAK config
tar xzf backups/tak-config-YYYYMMDD.tar.gz -C ..

# Restart services
docker compose -f docker-compose.prod.yml up -d
```

## Security

### Update Let's Encrypt Email

Edit `infra/caddy/Caddyfile`:
```
{
    email newemail@karabastactical.nl
}
```

Restart Caddy:
```bash
docker compose -f docker-compose.prod.yml restart caddy
```

### Rotate Database Password

1. Update `.env` file with new password
2. Update database:
   ```bash
   docker exec -it tak-server-db-1 psql -U postgres
   ALTER USER postgres PASSWORD 'new_password';
   \q
   ```
3. Restart services:
   ```bash
   docker compose -f docker-compose.prod.yml restart
   ```

### Firewall Configuration

```bash
# Allow only necessary ports
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP (ACME challenge)
ufw allow 443/tcp   # HTTPS
ufw allow 8089/tcp  # CoT TLS
ufw enable
```

## Phase 2 Additions

(To be added when Phase 2 is implemented)

- Team and event management
- Captain portal operations
- Invite lifecycle management
- Group assignment procedures

## Common Commands Reference

```bash
# Deploy
cd infra && ./scripts/deploy.sh

# Generate QR codes
cd customizations/scripts && ./generate-qr.sh username

# View logs
cd infra && docker compose -f docker-compose.prod.yml logs -f

# Restart service
cd infra && docker compose -f docker-compose.prod.yml restart [service]

# Stop all
cd infra && docker compose -f docker-compose.prod.yml down

# Start all
cd infra && docker compose -f docker-compose.prod.yml up -d
```

## Contact

**Operations:** ops@karabastactical.nl
**Issues:** https://github.com/MaroonBeret/tak-server/issues
