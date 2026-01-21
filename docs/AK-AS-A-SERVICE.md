# AK as a Service

**Status:** Phase 1 Implementation Complete
**Version:** 2.0 (Risk-Aware Refinement)

## Overview

AK as a Service productizes TAK server for Dutch airsoft teams with QR-based field onboarding and captain-managed team isolation.

### Key Features
- **QR Code Enrollment:** Players scan QR code → instant connection (no ZIP files)
- **Dual Client Support:** Works with both ATAK (Android) and iTAK (iOS)
- **Team Isolation:** Teams see only their own members' positions
- **Trusted TLS:** Let's Encrypt certificates via Caddy reverse proxy
- **Simple Operations:** One-command deployment and user management

## Architecture

```
Internet
    │
    ├─[443/HTTPS]─→ Caddy (Let's Encrypt TLS)
    │                   │
    │                   └─→ TAK Server :8446 (enrollment API, admin UI)
    │
    └─[8089/CoT-TLS]─→ TAK Server (direct, client uses enrolled cert)
```

### Components
- **Caddy:** Reverse proxy with automatic Let's Encrypt TLS
- **TAK Server:** Core TAK functionality (database, API, CoT routing)
- **QR Generator:** Script to create enrollment QR codes

### Why Caddy?
Let's Encrypt certificate renewal automation is simpler with Caddy than manipulating TAK's JKS keystore. Caddy handles HTTPS externally; TAK keeps its internal self-signed cert.

## Phase 1: Proof of Concept (Current)

**Goal:** Prove QR enrollment works reliably

### Deliverables
✅ Docker Compose with Caddy + TAK
✅ Caddyfile for reverse proxy
✅ QR code generation script
✅ Deployment automation
✅ Test result template
✅ Operations runbook

### Acceptance Criteria
- [ ] ATAK user scans QR → connects in <60 seconds
- [ ] iTAK user scans QR → connects in <90 seconds
- [ ] No TLS trust errors
- [ ] Certificate enrollment enabled
- [ ] Let's Encrypt working

## Quick Start

### Prerequisites
- Ubuntu VPS with Docker & Docker Compose
- Domain `tak.karabastactical.nl` pointing to VPS
- Ports 80, 443, 8089 open

### Installation

```bash
# 1. Clone repository
git clone https://github.com/MaroonBeret/tak-server.git
cd tak-server/infra

# 2. Configure environment
cp .env.example .env
nano .env  # Set POSTGRES_PASSWORD and other values

# 3. Deploy
./scripts/deploy.sh
# Choose option 1: Build and start

# 4. Enable certificate enrollment
# Open: https://tak.karabastactical.nl/Marti/security
# Enable "Certificate Enrollment" option

# 5. Generate test QR codes
cd ../customizations/scripts
./generate-qr.sh testuser
```

### Testing

Follow the test protocol in `docs/phase1-results.md`:
1. Scan ATAK QR with Android device
2. Scan iTAK QR with iOS device
3. Verify connection indicators
4. Document results

## Usage

### Generate QR Codes for New User

```bash
cd customizations/scripts
./generate-qr.sh username [password]
```

Output:
- `qr-codes/qr-atak-username.png` - For ATAK users
- `qr-codes/qr-itak-username.png` - For iTAK users
- Credentials printed to console

### QR Code Formats

**ATAK (5.1+):**
```
tak://enroll?host=tak.karabastactical.nl&port=443&username=user&password=pass&name=KarabasTAK
```
- Fully automatic enrollment
- Scan → tap → connected

**iTAK:**
```
KarabasTAK,tak.karabastactical.nl,8089,SSL
```
- Opens iTAK with server configured
- User enters credentials manually
- Still achieves "scan to connect" UX

## Operations

See `docs/runbook.md` for detailed operations guide.

### Common Tasks

**View logs:**
```bash
cd infra
docker compose -f docker-compose.prod.yml logs -f
```

**Restart services:**
```bash
cd infra
docker compose -f docker-compose.prod.yml restart
```

**Check status:**
```bash
cd infra
docker compose -f docker-compose.prod.yml ps
```

**Health check:**
```bash
curl https://tak.karabastactical.nl/health
```

## Phase 2 Roadmap (Future)

**Goal:** Captain-managed teams with automated provisioning

### Planned Features
- SQLite database for events/teams/invites
- Provisioning API (FastAPI)
- Captain web portal
- Automatic TAK group assignment
- Invite expiration and revocation
- 10+ concurrent users tested

### Not in Phase 2
- Payment integration (Phase 3)
- Multi-event isolation (Phase 3)
- Advanced analytics (Phase 3)

## Risk Mitigations

### Risk A: QR Compatibility
- **Issue:** ATAK and iTAK use different QR formats
- **Solution:** Generate both formats; label clearly for users
- **Impact:** Minimal - iTAK users type credentials once

### Risk B: TLS Trust
- **Issue:** Self-signed certs cause "identity could not be verified"
- **Solution:** Caddy with Let's Encrypt for enrollment endpoint
- **Impact:** Zero - devices trust Let's Encrypt natively

### Risk C: Team Isolation
- **Issue:** Will TAK groups truly prevent cross-team visibility?
- **Solution:** Research confirms groups provide PLI isolation
- **Validation:** Phase 2 includes specific isolation testing

## Repository Structure

```
tak-server/
├── infra/                              # Production infrastructure
│   ├── docker-compose.prod.yml         # Caddy + TAK + DB
│   ├── .env.example                    # Environment template
│   ├── caddy/
│   │   └── Caddyfile                   # Reverse proxy config
│   └── scripts/
│       └── deploy.sh                   # Deployment helper
├── customizations/                     # Custom code
│   └── scripts/
│       └── generate-qr.sh              # QR generator
└── docs/
    ├── AK-AS-A-SERVICE.md              # This file
    ├── phase1-results.md               # Test results template
    └── runbook.md                      # Operations guide
```

## Development Workflow

### Upstream Sync
```bash
# Add upstream remote (done once)
git remote add upstream https://github.com/Cloud-RF/tak-server.git

# Fetch upstream changes
git fetch upstream

# Merge upstream updates
git merge upstream/main
```

### Customization Strategy
- Keep upstream TAK files unchanged
- All custom code in `infra/` and `customizations/`
- Easy to sync with upstream updates

## Contributing

This is a productization of the upstream [Cloud-RF/tak-server](https://github.com/Cloud-RF/tak-server) project.

### Guidelines
1. Keep customizations isolated in `infra/` and `customizations/`
2. Don't modify core TAK configuration files
3. Document all changes in this file or runbook
4. Test on staging before production

## License

See [LICENSE](../LICENSE) file. This project builds on the upstream TAK server project.

## Support

- **Documentation:** See `docs/runbook.md`
- **Issues:** https://github.com/MaroonBeret/tak-server/issues
- **Email:** ops@karabastactical.nl

## Credits

Built on [Cloud-RF/tak-server](https://github.com/Cloud-RF/tak-server) Docker distribution.
