# TAK Server Production Infrastructure

This directory contains the production deployment configuration for AK as a Service.

## Quick Deploy

```bash
# 1. Configure environment
cp .env.example .env
nano .env  # Set POSTGRES_PASSWORD, TAK_DOMAIN, ADMIN_EMAIL

# 2. Deploy
./scripts/deploy.sh
# Choose option 1: Build and start

# 3. Enable certificate enrollment
# Open: https://tak.karabastactical.nl/Marti/security
# Toggle "Certificate Enrollment" ON
```

## Directory Structure

```
infra/
├── docker-compose.prod.yml    # Main compose file (db + tak + caddy)
├── .env.example               # Environment template
├── caddy/
│   └── Caddyfile             # Reverse proxy config (Let's Encrypt)
└── scripts/
    └── deploy.sh             # Deployment helper
```

## Services

### Database (db)
- PostgreSQL for TAK Server
- Persisted in `db_data` volume
- Internal network only

### TAK Server (tak)
- TAK Server with enrollment API
- Ports:
  - `8089` - CoT TLS (exposed)
  - `8446` - Admin HTTPS (internal only)

### Caddy (caddy)
- Reverse proxy with Let's Encrypt
- Ports:
  - `443` - HTTPS (proxies to TAK:8446)
  - `80` - HTTP (ACME challenge only)
- Auto-renews certificates every 90 days

## Configuration

### Required Environment Variables

Copy `.env.example` to `.env` and set:

| Variable | Description | Example |
|----------|-------------|---------|
| `POSTGRES_PASSWORD` | Database password | `super_secure_password_123` |
| `TAK_SERVER_VERSION` | TAK release version | `5.5-RELEASE-58` |
| `TAK_DOMAIN` | Your domain | `tak.karabastactical.nl` |
| `ADMIN_EMAIL` | Let's Encrypt email | `ops@karabastactical.nl` |

### Prerequisites

- Docker and Docker Compose installed
- Domain pointed to server IP
- Ports 80, 443, 8089 open in firewall

## Common Operations

### Deploy/Update
```bash
./scripts/deploy.sh
```

### View Logs
```bash
docker compose -f docker-compose.prod.yml logs -f [service]
```

### Check Status
```bash
docker compose -f docker-compose.prod.yml ps
```

### Restart Service
```bash
docker compose -f docker-compose.prod.yml restart [service]
```

### Stop All
```bash
docker compose -f docker-compose.prod.yml down
```

## Health Checks

```bash
# Service health
curl https://tak.karabastactical.nl/health

# Certificate info
curl -vI https://tak.karabastactical.nl/health 2>&1 | grep -A 5 "SSL"

# Enrollment API
curl -k https://tak.karabastactical.nl/Marti/api/tls/config
```

## Troubleshooting

See `../docs/runbook.md` for detailed troubleshooting guide.

### Quick Fixes

**Services won't start:**
```bash
docker compose -f docker-compose.prod.yml logs
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d --build
```

**Certificate issues:**
```bash
docker compose -f docker-compose.prod.yml logs caddy
docker compose -f docker-compose.prod.yml restart caddy
```

**Database connection errors:**
```bash
docker compose -f docker-compose.prod.yml restart db
```

## Documentation

- **Full guide:** `../docs/AK-AS-A-SERVICE.md`
- **Operations:** `../docs/runbook.md`
- **Test protocol:** `../docs/phase1-results.md`
- **Status:** `../docs/IMPLEMENTATION-STATUS.md`
