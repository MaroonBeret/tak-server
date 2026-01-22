# Deployment Workflow

**Status:** Phase 1 - Manual Feature Branch Deployment
**Last Updated:** 2026-01-22

## Current Situation

- **Single Environment:** Production VPS only (no staging/dev)
- **Live TAK Server:** Already running for 4 months at `/root/tak-server`
- **No CI/CD:** Currently manual deployment

## Deployment Options Analysis

### Option 1: Manual Feature Branch Pull (Current)

**Workflow:**
```bash
# Local development
git checkout -b feature/new-feature
# ... make changes ...
git commit -m "feat: description"
git push -u origin feature/new-feature

# VPS deployment
ssh tak-vps-contabo
cd /root/tak-server
git fetch origin
git checkout feature/new-feature
git pull origin feature/new-feature
cd infra
./scripts/deploy.sh
```
IMPORTANT: dont put a `Co-Authored-By: ` line in the git commit!

**Pros:**
- ✅ Simple, no infrastructure needed
- ✅ Full control over when deployment happens
- ✅ Can inspect changes before deploying
- ✅ Easy rollback (git checkout previous branch/commit)
- ✅ Works immediately

**Cons:**
- ❌ Manual SSH required
- ❌ No automation
- ❌ Human error possible

**Safety:** ⭐⭐⭐⭐⭐ (highest - human reviews every step)

---

### Option 2: GitHub Actions with Manual Trigger

**Workflow:**
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production
on:
  workflow_dispatch:  # Manual trigger only
    inputs:
      branch:
        description: 'Branch to deploy'
        required: true
        default: 'main'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to VPS
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /root/tak-server
            git fetch origin
            git checkout ${{ github.event.inputs.branch }}
            git pull
            cd infra
            docker compose -f docker-compose.prod.yml up -d --build
```

**Pros:**
- ✅ One-click deployment from GitHub UI
- ✅ Deployment history tracked
- ✅ Can add pre-deployment checks
- ✅ Secrets managed by GitHub
- ✅ Still manual trigger (no auto-deploy)

**Cons:**
- ❌ Requires SSH key in GitHub secrets
- ❌ No direct visibility into deployment (need to check logs separately)
- ❌ Slightly more complex setup

**Safety:** ⭐⭐⭐⭐ (manual trigger prevents accidents)

---

### Option 3: GitHub Actions with Auto-Deploy on Merge

**Workflow:**
```yaml
on:
  push:
    branches: [main]  # Auto-deploy when merged to main
```

**Pros:**
- ✅ Fully automated
- ✅ Deployment happens immediately after merge

**Cons:**
- ❌ Auto-deploys to production (risky with no staging)
- ❌ Bad merge = instant production breakage
- ❌ Need robust testing before merge

**Safety:** ⭐⭐ (dangerous without staging environment)

---

### Option 4: Watchtower (Docker Auto-Update)

**Workflow:**
```yaml
# Add to docker-compose.prod.yml
watchtower:
  image: containrrr/watchtower
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
  command: --interval 300  # Check every 5 minutes
```

**Pros:**
- ✅ Automatically updates Docker images
- ✅ No GitHub Actions needed

**Cons:**
- ❌ Only works for image updates (not config changes)
- ❌ Auto-updates can break things
- ❌ Not suitable for our custom code (we're not pushing images)

**Safety:** ⭐⭐ (auto-updates risky)

---

### Option 5: Webhook-Based Deployment

**Workflow:**
- Server runs webhook listener
- GitHub sends webhook on push
- Server pulls and redeploys

**Pros:**
- ✅ Fast deployment
- ✅ Automated

**Cons:**
- ❌ Requires webhook service on VPS
- ❌ Security concerns (exposed endpoint)
- ❌ Overkill for small project

**Safety:** ⭐⭐⭐ (depends on webhook security)

---

## Recommendation for Phase 1

### Use: **Option 1 (Manual Feature Branch Pull)**

**Why:**
1. **No staging environment** - We need human verification before production changes
2. **Single VPS** - Any mistake affects production immediately
3. **Learning phase** - We're still proving the concept
4. **Simplicity** - No additional infrastructure

**Workflow we'll use:**

```bash
# 1. Local development (on Mac)
git checkout -b feature/my-feature
# ... make changes ...
git add .
git commit -m "feat: description"
git push -u origin feature/my-feature

# 2. Deploy to VPS
ssh tak-vps-contabo
cd /root/tak-server

# 3. Switch remote to your fork
git remote set-url origin https://github.com/MaroonBeret/tak-server.git
git fetch origin

# 4. Checkout feature branch
git checkout feature/my-feature
git pull origin feature/my-feature

# 5. Inspect changes
git log --oneline -5
git diff main..feature/my-feature

# 6. Deploy
cd infra
./scripts/deploy.sh
# Choose option: 1 (Build and start) or 2 (Pull and restart)

# 7. Verify
docker compose -f docker-compose.prod.yml ps
docker compose -f docker-compose.prod.yml logs -f

# 8. Test
curl https://tak.karabastactical.nl/health
```

**Rollback procedure:**
```bash
ssh tak-vps-contabo
cd /root/tak-server
git checkout main  # or previous branch
cd infra
./scripts/deploy.sh
```

---

## Future: Moving to GitHub Actions (Phase 2+)

Once we're confident and have tested Phase 1, we can add:

### Phase 2 Deployment Automation

```yaml
# .github/workflows/deploy-feature.yml
name: Deploy Feature Branch
on:
  workflow_dispatch:
    inputs:
      branch:
        description: 'Feature branch to deploy'
        required: true
        type: string

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production  # Requires approval
    steps:
      - name: Deploy to VPS
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.VPS_HOST }}
          username: ${{ secrets.VPS_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            set -e
            cd /root/tak-server

            # Backup current state
            CURRENT_BRANCH=$(git branch --show-current)
            echo "Current branch: $CURRENT_BRANCH"

            # Pull and checkout
            git fetch origin
            git checkout ${{ inputs.branch }}
            git pull origin ${{ inputs.branch }}

            # Deploy
            cd infra
            docker compose -f docker-compose.prod.yml up -d --build

            # Health check
            sleep 10
            curl -f https://tak.karabastactical.nl/health || (
              echo "Health check failed, rolling back"
              git checkout $CURRENT_BRANCH
              docker compose -f docker-compose.prod.yml up -d
              exit 1
            )
```

**Setup required:**
```bash
# 1. Generate deploy key on VPS
ssh tak-vps-contabo "ssh-keygen -t ed25519 -f ~/.ssh/github_deploy -N ''"

# 2. Add private key to GitHub Secrets
# GitHub → Settings → Secrets → Actions → New secret
# Name: SSH_PRIVATE_KEY
# Value: (paste private key from VPS)

# 3. Add other secrets
# VPS_HOST: <VPS_IP>
# VPS_USER: root
```

---

## Safety Measures for Any Deployment Method

### Pre-Deployment Checklist
- [ ] Changes committed to feature branch
- [ ] Feature branch pushed to GitHub
- [ ] Local tests passed (if applicable)
- [ ] Reviewed git diff between branches
- [ ] Identified rollback procedure

### Post-Deployment Verification
- [ ] All containers running: `docker compose ps`
- [ ] Health check passes: `curl https://tak.karabastactical.nl/health`
- [ ] No errors in logs: `docker compose logs --tail=50`
- [ ] Services accessible (TAK admin UI, CoT port)
- [ ] Certificate valid (if Caddy changes made)

### Rollback Criteria
Deploy rollback if ANY of these occur:
- ❌ Services fail to start
- ❌ Health check fails
- ❌ Errors in logs
- ❌ Users cannot connect
- ❌ Certificate issues

---

## Current VPS Git Setup (Needs Update)

**Current state:**
```bash
# VPS currently points to upstream
cd /root/tak-server
git remote -v
# origin  https://github.com/Cloud-RF/tak-server.git
```

**Needs to be:**
```bash
# VPS should point to our fork
git remote set-url origin https://github.com/MaroonBeret/tak-server.git
git remote add upstream https://github.com/Cloud-RF/tak-server.git
```

**Action required:**
```bash
ssh tak-vps-contabo "cd /root/tak-server && git remote set-url origin https://github.com/MaroonBeret/tak-server.git && git remote add upstream https://github.com/Cloud-RF/tak-server.git && git remote -v"
```

---

## Decision

**For Phase 1:** Manual deployment (Option 1)

**Ready to implement?** Yes - workflow documented above

**Next step:** Fix VPS git remotes, then deploy feature branch

**Future consideration:** GitHub Actions with manual trigger (Option 2) after Phase 1 proves stable
