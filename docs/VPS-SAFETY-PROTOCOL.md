# VPS Safety Protocol for Claude

**VPS Host:** `tak-vps-contabo`
**Purpose:** Prevent accidental damage during deployment and testing

## Claude's Rules of Engagement

### ✅ SAFE - Can Do Without Asking

**Read-Only Operations:**
- `ls`, `cat`, `less`, `head`, `tail` - View files
- `docker ps`, `docker logs` - Check container status
- `docker compose ps` - Check service status
- `systemctl status` - Check service status
- `df -h`, `free -m`, `uptime` - System info
- `git status`, `git log`, `git diff` - Git inspection
- `curl <url>` - Test endpoints
- `dig`, `ping` - Network diagnostics
- `find`, `grep` - Search operations

**Safe Docker Operations:**
- `docker compose logs` - View logs only
- `docker inspect` - Inspect containers
- `docker stats` - View resource usage

### ⚠️ CAUTIOUS - Must Explain Before Doing

**Deployment Operations:**
- `docker compose up -d` - Start services (will explain which services)
- `docker compose restart <service>` - Restart specific service (will specify which)
- `docker compose pull` - Pull image updates (will show what's updating)
- `git pull` - Update repository (will show what's changing)

**Before executing, I will:**
1. Explain what the command does
2. Show current state
3. Explain expected outcome
4. Wait for your confirmation

### 🛑 FORBIDDEN - Must Ask Permission First

**Destructive Operations:**
- `docker compose down` - Stops ALL services
- `docker compose down -v` - Deletes volumes (DATA LOSS)
- `rm -rf` - Delete files/directories
- `docker system prune` - Delete unused containers/images
- `git reset --hard` - Discard local changes
- `git push --force` - Force push (can break things)
- `systemctl stop` - Stop system services
- `reboot`, `shutdown` - System restart/shutdown
- Any command with `sudo` that modifies files
- Database operations (drop, truncate, etc.)
- Firewall changes (`ufw`, `iptables`)

### 📋 Standard Operating Procedure

#### Phase 1: Initial Inspection (Read-Only)
```bash
# I will first assess the current state
ssh tak-vps-contabo "
    echo '=== System Info ==='
    uname -a
    uptime

    echo '=== Disk Space ==='
    df -h

    echo '=== TAK Server Status ==='
    cd /opt/tak-server/infra 2>/dev/null && docker compose -f docker-compose.prod.yml ps || echo 'Not deployed yet'

    echo '=== Running Containers ==='
    docker ps
"
```

#### Phase 2: Propose Changes
Before making ANY changes, I will:
1. Show you the current state
2. Explain what I want to change
3. Show the exact commands I'll run
4. Wait for your approval

Example:
```
Current state: TAK server not running
Proposed action: Deploy TAK server with Caddy
Commands I will run:
  1. cd /opt/tak-server/infra
  2. cp .env.example .env (if .env doesn't exist)
  3. docker compose -f docker-compose.prod.yml up -d

Proceed? (yes/no)
```

#### Phase 3: Execute with Monitoring
After approval:
1. Run commands one at a time
2. Check output after each step
3. Report any errors immediately
4. Stop if anything unexpected happens

#### Phase 4: Verify
After changes:
1. Check service status
2. Run health checks
3. Verify logs show no errors
4. Report results to you

## Rollback Plan

Before making changes, I will identify the rollback procedure:

| Change | Rollback |
|--------|----------|
| `docker compose up -d` | `docker compose down` |
| `git pull` | `git reset --hard <previous-commit>` |
| File edits | Keep backup: `cp file file.bak` |
| Service restart | Note previous state, restart again if needed |

## Emergency Stop

If you say **"STOP"** or **"ABORT"**, I will:
1. Immediately stop current operations
2. Not run any pending commands
3. Report what was done so far
4. Wait for your instructions

## Backup Before Major Changes

Before deploying or updating, I will verify backups exist:
```bash
# Check for backup script/cron
ls -la /opt/backups/

# If no backups, create one
docker compose -f docker-compose.prod.yml exec db pg_dump -U postgres > backup-$(date +%Y%m%d-%H%M%S).sql
```

## Testing Strategy

### Prefer Local Testing First
When possible, test commands locally (on your Mac) before running on VPS:
```bash
# Test locally first
cd infra
docker compose -f docker-compose.prod.yml config  # Validate syntax

# Then run on VPS
ssh tak-vps-contabo "cd /opt/tak-server/infra && docker compose -f docker-compose.prod.yml config"
```

### Use Dry-Run When Available
```bash
# Example: Test what would be pulled
docker compose pull --dry-run

# Example: Test what would be deleted
git clean -n  # -n = dry run
```

## What If Something Breaks?

If I accidentally cause an issue:

1. **I will immediately tell you** what happened
2. **I will show you** the error messages
3. **I will propose** a fix or rollback
4. **I will wait** for your approval before attempting fix
5. **I will not** try to hide or fix errors without telling you

## Your Override

You can always:
- Tell me to stop
- Tell me to skip safety checks (if you're certain)
- Give me explicit permission for normally-forbidden commands
- Ask me to explain anything I'm about to do

## Summary

**My Promise:**
- I will be **transparent** about every action
- I will **explain** before executing
- I will **never** run destructive commands without permission
- I will **stop** immediately if you say so

**Your Control:**
- You have **final say** on all operations
- You can **override** any restriction
- You can **stop** me at any time

---

**Do you approve this protocol?** If yes, I'll follow these rules strictly. If you want to modify anything, let me know.
