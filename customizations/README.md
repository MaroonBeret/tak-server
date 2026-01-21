# AK as a Service Customizations

This directory contains custom scripts and code for the AK as a Service implementation.

## Current Phase: Phase 1 (QR Enrollment POC)

### Available Scripts

#### generate-qr.sh

**Purpose:** Generate QR codes for ATAK and iTAK enrollment

**Location:** `scripts/generate-qr.sh`

**Usage:**
```bash
cd scripts
./generate-qr.sh [username] [password]
```

**What it does:**
1. Creates user in TAK Server via UserManager.jar
2. Generates ATAK QR code (tak:// URI format)
3. Generates iTAK QR code (connection string format)
4. Outputs QR images to `./qr-codes/` directory

**Examples:**
```bash
# Generate with random password
./generate-qr.sh alice

# Generate with specific password
./generate-qr.sh bob SecurePass123

# With custom domain (via environment variable)
TAK_DOMAIN=tak.example.com ./generate-qr.sh charlie
```

**Output:**
```
qr-codes/
├── qr-atak-alice.png    # Scan with Android camera → ATAK auto-enrolls
└── qr-itak-alice.png    # Scan with iOS camera → iTAK opens, prompts for credentials
```

**Requirements:**
- `qrencode` command (optional, script works without it but only outputs URIs)
  - macOS: `brew install qrencode`
  - Ubuntu: `apt install qrencode`
- Running TAK Server with UserManager available
- Docker access to TAK container

## Future Phases

### Phase 2: Provisioning API & Captain Portal

**Planned structure:**
```
customizations/
├── provisioning-api/           # [Phase 2]
│   ├── app.py                  # FastAPI application
│   ├── schema.sql              # SQLite schema
│   ├── requirements.txt
│   └── Dockerfile
├── captain-portal/             # [Phase 2]
│   ├── index.html
│   └── app.js
└── scripts/
    ├── generate-qr.sh          # [Current]
    └── admin-cli.sh            # [Phase 2]
```

**Phase 2 features:**
- SQLite database for events, teams, members, invites
- REST API for invite management
- Web portal for team captains
- Automated TAK group assignment
- Invite expiration and revocation

## Development Guidelines

### Adding New Scripts

1. Place in appropriate subdirectory
2. Make executable: `chmod +x script.sh`
3. Include usage comment header
4. Add to this README
5. Update `.gitignore` if needed

### Testing Scripts Locally

```bash
# Start TAK server locally first
cd ../
docker compose up -d

# Then run custom scripts
cd customizations/scripts
./generate-qr.sh testuser
```

## Documentation

- **Project overview:** `../docs/AK-AS-A-SERVICE.md`
- **Operations guide:** `../docs/runbook.md`
- **Implementation status:** `../docs/IMPLEMENTATION-STATUS.md`
