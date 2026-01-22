# Claude Code Context: TAK as a Service

**Last Updated:** 2026-01-22
**Current Phase:** Phase 1 - QR Enrollment POC
**Status:** Implementation complete, ready for deployment testing

## Project Overview

### What This Is
Productization of TAK Server for Dutch airsoft community ("Karabas Tactical"). Players scan QR codes to instantly join team-based tactical awareness system during airsoft games.

### The Problem We're Solving
- Current TAK onboarding requires downloading/importing .zip certificate files (complex)
- Players need instant "scan QR → see team on map" experience
- Teams need isolation (Team A can't see Team B's positions)
- Field captains need self-service team management

### Our Solution
- **Phase 1:** QR code enrollment with Let's Encrypt TLS (no zip files)
- **Phase 2:** Captain portal + automated team provisioning
- **Phase 3:** Payment integration + multi-event support

## Architecture

### Production Stack
```
Internet
    │
    ├─[443/HTTPS]─→ Caddy (Let's Encrypt TLS)
    │                   │
    │                   └─→ TAK Server :8446 (enrollment API, admin UI)
    │
    └─[8089/CoT-TLS]─→ TAK Server (direct, client has cert after enrollment)
```

### Key Components
1. **Caddy:** Reverse proxy with automatic Let's Encrypt renewal
2. **TAK Server:** Core tactical awareness server (upstream: Cloud-RF/tak-server)
3. **PostgreSQL:** TAK's database
4. **QR Generator:** Bash script creating ATAK and iTAK enrollment QR codes

### Why Caddy vs JKS Manipulation?
Let's Encrypt certificates expire every 90 days. Caddy auto-renews. Manipulating TAK's Java keystore (JKS) with Let's Encrypt certs is complex and error-prone. Caddy keeps it simple.

## Repository Structure

```
tak-server/
├── infra/                           # Production infrastructure (our code)
│   ├── docker-compose.prod.yml      # Caddy + TAK + DB
│   ├── caddy/Caddyfile              # Reverse proxy config
│   ├── .env.example                 # Environment template
│   └── scripts/deploy.sh            # Deployment automation
│
├── customizations/                  # Custom scripts (our code)
│   └── scripts/generate-qr.sh       # QR code generator
│
├── docs/                            # Documentation (our code)
│   ├── AK-AS-A-SERVICE.md          # Project overview
│   ├── IMPLEMENTATION-STATUS.md     # Deployment checklist
│   ├── runbook.md                   # Operations guide
│   └── phase1-results.md            # Test protocol
│
├── docker/                          # Upstream TAK Dockerfiles
├── scripts/                         # Upstream TAK scripts
├── CoreConfig.xml                   # Upstream TAK config
├── docker-compose.yml               # Upstream development compose
└── CLAUDE.md                        # This file
```

### Upstream vs Customization Strategy
- **Don't modify:** `docker/`, `scripts/`, `CoreConfig.xml`, `docker-compose.yml`
- **Our code lives in:** `infra/`, `customizations/`, `docs/`
- **Why:** Easy to `git merge upstream/main` without conflicts

## Current Phase: Phase 1

### Objective
Prove that QR code enrollment works reliably (no zip file imports).

### Acceptance Criteria
- [ ] ATAK user scans QR → enrolled and connected in <60 seconds
- [ ] iTAK user scans QR → enters credentials → connected in <90 seconds
- [ ] No "identity could not be verified" TLS errors
- [ ] Certificate enrollment enabled in TAK admin UI
- [ ] Let's Encrypt working on `tak.karabastactical.nl`

### Phase 1 Deliverables (Complete)
- ✅ Docker Compose with Caddy
- ✅ Caddyfile configuration
- ✅ QR generation script (dual format: ATAK + iTAK)
- ✅ Deployment automation
- ✅ Documentation (runbook, test protocol, guides)

### What's NOT in Phase 1
- ❌ Captain portal (Phase 2)
- ❌ Team database (Phase 2)
- ❌ Invite expiration/revocation (Phase 2)
- ❌ Automated group assignment (Phase 2)
- ❌ Payment integration (Phase 3)

## Key Technical Decisions

### 1. QR Code Formats

**ATAK (Android):**
```
tak://enroll?host=tak.karabastactical.nl&port=443&username=user&password=pass&name=KarabasTAK
```
- Fully automatic enrollment
- Requires ATAK 5.1+

**iTAK (iOS):**
```
KarabasTAK,tak.karabastactical.nl,8089,SSL
```
- Opens iTAK with server configured
- User manually enters credentials
- Still achieves "scan to connect" UX

### 2. Team Isolation (Phase 2)
TAK groups provide true PLI (Position Location Information) isolation:
- Each team gets a TAK group (e.g., `TeamAlpha`, `TeamBravo`)
- Members have `In+Out` roles for their team group only
- Group members see only their teammates' positions

### 3. Port Strategy
- **443:** Caddy HTTPS → TAK enrollment API
- **8089:** Direct CoT TLS (clients use enrolled cert)
- **8446:** TAK admin UI (only via Caddy proxy, not directly exposed)

## Common Operations

### Deploy to Production
```bash
cd infra
cp .env.example .env
nano .env  # Set POSTGRES_PASSWORD, TAK_DOMAIN, ADMIN_EMAIL
./scripts/deploy.sh  # Option 1: Build and start
```

### Generate QR Codes
```bash
cd customizations/scripts
./generate-qr.sh username [password]
# Outputs: qr-codes/qr-atak-username.png, qr-codes/qr-itak-username.png
```

### View Logs
```bash
cd infra
docker compose -f docker-compose.prod.yml logs -f [service]
```

### Manual User Management
```bash
# Create user
docker exec tak-server-tak-1 java -jar /opt/tak/utils/UserManager.jar \
    usermod -A -p "password" "username"

# Delete user
docker exec tak-server-tak-1 java -jar /opt/tak/utils/UserManager.jar \
    userdel "username"

# List users
docker exec tak-server-tak-1 java -jar /opt/tak/utils/UserManager.jar \
    userlist
```

### Health Checks
```bash
# Caddy health endpoint
curl https://tak.karabastactical.nl/health

# Check Let's Encrypt certificate
curl -vI https://tak.karabastactical.nl/health 2>&1 | grep -A 5 "SSL"

# Test enrollment API
curl -k https://tak.karabastactical.nl/Marti/api/tls/config
```

## Git Workflow

### Remotes
```bash
origin     https://github.com/MaroonBeret/tak-server.git  (our fork)
upstream   https://github.com/Cloud-RF/tak-server.git     (original)
```

### Syncing Upstream
```bash
git fetch upstream
git merge upstream/main
# Our customizations in infra/ and customizations/ won't conflict
```

### Committing
Always use co-authored commits:
```bash
git commit -m "Description

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

## VPS Details

### Requirements
- **OS:** Ubuntu 22.04 LTS
- **CPU:** 2 cores minimum
- **RAM:** 4GB minimum
- **Storage:** 20GB SSD
- **Network:** Ports 80, 443, 8089 open

### Domain
- **Production:** `tak.karabastactical.nl`
- **DNS:** Must point to VPS IP before deployment

### Access (To Be Configured)
- **SSH:** TBD (see "Helping Claude" section below)
- **User:** TBD
- **IP:** TBD

## Critical Gotchas

### 1. Certificate Enrollment Must Be Enabled Manually
After deployment, you MUST:
1. Visit `https://tak.karabastactical.nl/Marti/security`
2. Toggle "Certificate Enrollment" to ON
3. Save changes

This setting is stored in TAK's database, not `CoreConfig.xml`.

### 2. QR Code Generator Assumes Container Name
Script expects TAK container named `tak-server-tak-1` (default from docker-compose).
If container name differs, edit `customizations/scripts/generate-qr.sh`.

### 3. Port 8446 Internal Only
Port 8446 should NOT be exposed to internet. Only Caddy needs access. External users:
- Use port 443 (Caddy) for enrollment
- Use port 8089 (TAK direct) for CoT traffic

### 4. Let's Encrypt Rate Limits
Let's Encrypt has rate limits (50 certs/week per domain). Don't repeatedly test deployment. Use staging environment or DNS validation.

### 5. TAK Group Assignment (Phase 2)
Group assignment must happen AFTER user creation:
```bash
# Create user first
docker exec tak-server-tak-1 java -jar /opt/tak/utils/UserManager.jar \
    usermod -A -p "pass" "user"

# Then assign to group
docker exec tak-server-tak-1 java -jar /opt/tak/utils/UserManager.jar \
    groupmod -A "TeamAlpha" "user"
```

## Phase 2 Preview

### Planned Components
```
customizations/
├── provisioning-api/         # FastAPI + SQLite
│   ├── app.py               # Invite management, webhook for enrollment
│   ├── schema.sql           # events, teams, members, invites tables
│   └── Dockerfile
├── captain-portal/          # Static HTML + JS
│   ├── index.html          # Team management UI
│   └── app.js              # Calls provisioning API
└── scripts/
    ├── generate-qr.sh      # (existing)
    └── admin-cli.sh        # Event/team creation
```

### Phase 2 Flow
1. Admin creates event: `./admin-cli.sh event create "Sunday Game"`
2. Admin creates teams: `./admin-cli.sh team create "Alpha" "Bravo"`
3. Captain generates invite: POST `/api/invites` → returns QR code
4. Player scans QR → API webhook creates user + assigns to TAK group
5. Player sees only teammates on map

## Testing Checklist

### Before Declaring Phase 1 Complete
- [ ] VPS provisioned and accessible
- [ ] DNS `tak.karabastactical.nl` resolves to VPS IP
- [ ] Deployment successful (all 3 services running)
- [ ] Health check returns "OK"
- [ ] Browser shows valid Let's Encrypt cert
- [ ] Certificate enrollment enabled in TAK UI
- [ ] ATAK QR enrollment tested (<60s)
- [ ] iTAK QR enrollment tested (<90s)
- [ ] No TLS errors on either platform
- [ ] PLI transmission confirmed on both devices
- [ ] Results documented in `docs/phase1-results.md`

## Troubleshooting Quick Reference

See `docs/runbook.md` for full guide.

### "Identity could not be verified"
→ Let's Encrypt cert not issued. Check Caddy logs: `docker compose -f infra/docker-compose.prod.yml logs caddy`

### QR scan doesn't work (ATAK)
→ Ensure ATAK version ≥5.1. Verify `tak://` URI format.

### QR scan doesn't work (iTAK)
→ Verify server string format: `ServerName,domain.com,8089,SSL`

### Services won't start
→ Check logs: `docker compose -f infra/docker-compose.prod.yml logs`

### Can't access admin UI
→ Check Caddy proxy: `docker compose -f infra/docker-compose.prod.yml logs caddy`

## Helping Claude Work Effectively

### For Git Operations

Claude needs git configured to create commits:

```bash
# Check current config
git config --global user.name
git config --global user.email

# Set if not configured
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### For SSH/Deployment Access

To let Claude deploy and test on VPS, provide:

1. **SSH Key Setup:**
```bash
# Option A: Use existing SSH key
cat ~/.ssh/id_rsa.pub  # Copy this to VPS authorized_keys

# Option B: Generate new key for Claude sessions
ssh-keygen -t ed25519 -f ~/.ssh/claude_tak_deploy -C "claude-deploy"
cat ~/.ssh/claude_tak_deploy.pub  # Copy to VPS
```

2. **SSH Config Entry:**
```bash
# Add to ~/.ssh/config
Host tak-prod
    HostName <VPS_IP_ADDRESS>
    User <VPS_USERNAME>
    IdentityFile ~/.ssh/claude_tak_deploy
    StrictHostKeyChecking accept-new
```

3. **Test Access:**
```bash
ssh tak-prod "uname -a"
# Should connect without password prompt
```

### Environment Variables Claude Needs

Create a `.env` file in `infra/` (not committed to git):

```bash
# infra/.env
POSTGRES_PASSWORD=<secure_password_here>
TAK_SERVER_VERSION=5.5-RELEASE-58
TAK_DOMAIN=tak.karabastactical.nl
ADMIN_EMAIL=ops@karabastactical.nl
```

### VPS Details for Claude

Once VPS is provisioned, update this section:

- **SSH Host:** `tak-prod` (configured above)
- **IP Address:** TBD
- **Username:** TBD
- **Sudo:** TBD (yes/no, password/nopasswd)

## Questions to Answer

Before Phase 1 deployment testing:

- [ ] Is VPS provisioned? (IP address, SSH access)
- [ ] Is DNS configured for `tak.karabastactical.nl`?
- [ ] Are ports 80, 443, 8089 open in firewall?
- [ ] Is Docker installed on VPS?
- [ ] Is git configured locally for commits?
- [ ] Does Claude have SSH access to VPS?

## Useful Commands for Claude

### Deployment Workflow
```bash
# 1. SSH to VPS
ssh tak-prod

# 2. Clone/update repo
cd /opt/ && git clone https://github.com/MaroonBeret/tak-server.git
cd tak-server && git pull

# 3. Deploy
cd infra
cp .env.example .env
# Edit .env with actual values
./scripts/deploy.sh

# 4. Verify
docker compose -f docker-compose.prod.yml ps
curl https://tak.karabastactical.nl/health
```

### Testing Workflow
```bash
# Generate test QR
ssh tak-prod "cd /opt/tak-server/customizations/scripts && ./generate-qr.sh testuser1"

# Download QR images (to scan with phone)
scp tak-prod:/opt/tak-server/customizations/scripts/qr-codes/*.png ./

# Monitor logs during test
ssh tak-prod "cd /opt/tak-server/infra && docker compose -f docker-compose.prod.yml logs -f"
```

## Next Session Quick Start

If you're a new Claude session picking this up:

1. **Read this entire file first**
2. **Check current status:** `docs/IMPLEMENTATION-STATUS.md`
3. **Review recent commits:** `git log --oneline -10`
4. **Check if VPS is accessible:** `ssh tak-prod "uptime"`
5. **Check deployment status:** `ssh tak-prod "cd /opt/tak-server/infra && docker compose -f docker-compose.prod.yml ps"`
6. **Ask user:** "What are we working on today?"

## Resources

- **Upstream TAK Server:** https://github.com/Cloud-RF/tak-server
- **ATAK Downloads:** https://www.civtak.org/
- **iTAK:** https://apps.apple.com/app/itak/id1561656396
- **Caddy Docs:** https://caddyserver.com/docs/
- **TAK Protocol:** https://tak.gov/

## Contact

- **Project Owner:** ops@karabastactical.nl
- **Issues:** https://github.com/MaroonBeret/tak-server/issues

---

**For Claude:** This file is your mission briefing. Everything you need to understand the project, make decisions, and execute tasks effectively is here. Update this file as the project evolves.
