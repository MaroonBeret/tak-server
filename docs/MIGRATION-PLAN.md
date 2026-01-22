# Migration Plan: Phase 1 Deployment

**Date:** 2026-01-22
**Current State:** TAK Server running from `/root/tak-server-original` (4 months)
**Target State:** TAK Server running from `/root/tak-server` with Phase 1 features

## Current Installation Audit

### Location
- **Old deployment:** `/root/tak-server-original`
- **Running containers:** `tak-server-tak-1`, `tak-server-db-1` (Up 4 months)

### Critical Data Identified

| Data Type | Location | Size | Critical? |
|-----------|----------|------|-----------|
| User certificates | `/root/tak-server-original/tak/certs/files/` | 2 users | ✅ YES |
| TAK configs | `/root/tak-server-original/tak/CoreConfig.xml` | 4.8KB | ✅ YES |
| User auth | `/root/tak-server-original/tak/UserAuthenticationFile.xml` | 453B | ✅ YES |
| Database | Docker volume `tak-server_db_data` | 4KB | ✅ YES |
| Logs | `/root/tak-server-original/tak/logs/` | Unknown | ⚠️ Nice to have |
| Mission packages | `.dp.zip` files in certs/files/ | 2 files | ✅ YES |

### User Data
- **user1**: Certificate package exists
- **user2**: Certificate package exists

## Migration Strategy

### Approach: Clone New + Copy Data + Cutover

**Why this approach:**
- ✅ Original installation remains untouched (backup)
- ✅ Can rollback easily
- ✅ All user data preserved
- ✅ Minimal downtime
- ✅ Clean separation

### Step-by-Step Migration

#### Phase 1: Preparation (Read-Only)
```bash
# 1. Clone new repository
cd /root
git clone https://github.com/MaroonBeret/tak-server.git tak-server

# 2. Checkout feature branch
cd tak-server
git checkout feature/phase1-qr-enrollment

# 3. Verify structure
ls -la infra/
ls -la customizations/
```

**Verification:**
- [ ] New directory exists: `/root/tak-server`
- [ ] Feature branch checked out
- [ ] `infra/`, `customizations/`, `docs/` directories present

#### Phase 2: Copy User Data
```bash
# 1. Copy entire TAK directory (preserves all data)
cp -r /root/tak-server-original/tak /root/tak-server/tak

# 2. Verify copy
ls -la /root/tak-server/tak/certs/files/*.zip
cat /root/tak-server/tak/CoreConfig.xml | head -10
```

**Verification:**
- [ ] User certificates present: `user1`, `user2`
- [ ] CoreConfig.xml exists
- [ ] UserAuthenticationFile.xml exists
- [ ] TAK directory size matches (~577MB)

#### Phase 3: Configure New Deployment
```bash
cd /root/tak-server/infra

# 1. Create .env from current config
cp .env.example .env

# 2. Set configuration
nano .env
# Set:
#   POSTGRES_PASSWORD=<same as before or new>
#   TAK_DOMAIN=tak.karabastactical.nl
#   ADMIN_EMAIL=ops@karabastactical.nl
```

**Verification:**
- [ ] `.env` file created
- [ ] Configuration values set

#### Phase 4: Cutover (Service Interruption)
```bash
# 1. Stop old deployment
cd /root/tak-server-original
docker compose down

# This will:
# - Stop tak-server-tak-1
# - Stop tak-server-db-1
# - Preserve tak-server_db_data volume
# - Preserve all data in tak/ directory

# 2. Start new deployment
cd /root/tak-server/infra
./scripts/deploy.sh
# Choose option 1: Build and start

# This will:
# - Start new Caddy container (Let's Encrypt)
# - Start new TAK container (with Phase 1 features)
# - Start new DB container (reusing tak-server_db_data)
# - Serve on ports 443 (Caddy), 8089 (TAK CoT)
```

**Expected downtime:** 2-5 minutes (time to stop old + start new)

**Verification:**
- [ ] All 3 services running (tak, db, caddy)
- [ ] Health check passes: `curl https://tak.karabastactical.nl/health`
- [ ] Caddy has Let's Encrypt cert
- [ ] No errors in logs

#### Phase 5: Verify User Data
```bash
# 1. Check user certificates still exist
docker exec tak-server-tak-1 ls -la /opt/tak/certs/files/

# 2. Check if users can authenticate
# Test with existing user1/user2 credentials

# 3. Check logs for errors
docker compose -f /root/tak-server/infra/docker-compose.prod.yml logs
```

**Verification:**
- [ ] User certificates accessible
- [ ] Existing users can connect (if credentials known)
- [ ] No database migration errors

## Rollback Procedure

**If something goes wrong:**

```bash
# 1. Stop new deployment
cd /root/tak-server/infra
docker compose -f docker-compose.prod.yml down

# 2. Restart old deployment
cd /root/tak-server-original
docker compose up -d

# 3. Verify
docker ps
curl http://<VPS_IP>:8443  # Old TAK admin UI
```

**Rollback time:** ~2 minutes

## Data Preservation Guarantees

### What's Preserved Automatically
- ✅ Database content (shared volume)
- ✅ User certificates (copied to new location)
- ✅ TAK configurations (copied to new location)
- ✅ Mission packages (copied with TAK directory)

### What Requires Manual Copy
- Nothing - the `cp -r` of the TAK directory preserves everything

### What's Not Preserved
- Old container logs (not needed, containers recreated)
- Old deployment directory (kept as backup at `/root/tak-server-original`)

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Data loss during copy | Low | High | Verify copy before stopping old deployment |
| Database incompatibility | Low | Medium | TAK version same (5.4), schema should match |
| Port conflicts | Low | Low | Stop old before starting new |
| Let's Encrypt rate limit | Low | Medium | Caddy handles this automatically |
| Users can't reconnect | Medium | High | Copy user certs, test with known user |
| Config mismatch | Low | Medium | CoreConfig.xml copied from working system |

## Testing Checklist

### After Migration
- [ ] All 3 containers running
- [ ] Health endpoint responds: `curl https://tak.karabastactical.nl/health`
- [ ] TAK admin UI accessible: `https://tak.karabastactical.nl/Marti`
- [ ] Let's Encrypt certificate valid (check in browser)
- [ ] User certificates exist in new deployment
- [ ] Existing users can connect (if credentials available)
- [ ] QR code generator works: `cd customizations/scripts && ./generate-qr.sh testuser`
- [ ] New user can enroll via QR code

### Phase 1 Specific Tests
- [ ] Certificate enrollment enabled in TAK admin UI
- [ ] ATAK QR code generated successfully
- [ ] iTAK QR code generated successfully
- [ ] Test ATAK enrollment with real device
- [ ] Test iTAK enrollment with real device

## Timeline Estimate

| Phase | Time | Downtime? |
|-------|------|-----------|
| Clone repo | 2 min | No |
| Copy TAK data | 5 min | No |
| Configure .env | 2 min | No |
| Stop old + Start new | 5 min | **YES** |
| Verify + Test | 10 min | No |
| **Total** | **24 min** | **5 min** |

## Decision Point

**Before proceeding, confirm:**
- [ ] Downtime window acceptable (5 minutes)
- [ ] Backup strategy acceptable (keep old deployment directory)
- [ ] Understand rollback procedure
- [ ] Ready to test with real devices after deployment

## Post-Migration

### Cleanup (Optional, do later)
```bash
# After confirming new deployment stable for 1+ week:
# Stop old containers (if somehow still running)
cd /root/tak-server-original
docker compose down

# Keep directory as backup
# Do NOT delete /root/tak-server-original yet
```

### Monitoring
```bash
# Watch logs
docker compose -f /root/tak-server/infra/docker-compose.prod.yml logs -f

# Check resource usage
docker stats

# Check disk space
df -h
```

## Questions Before Migration

1. **Do you know the credentials for user1/user2?** (To test they can still connect)
2. **Is there a maintenance window or can we do this anytime?**
3. **Do you have ATAK/iTAK devices ready to test after migration?**
4. **Any other data I haven't identified that needs preservation?**

---

**Ready to proceed?** I'll execute this step-by-step with verification at each phase.
