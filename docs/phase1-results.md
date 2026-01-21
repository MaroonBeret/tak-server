# Phase 1 Test Results

**Date:** TBD
**Tester:** TBD
**TAK Server Version:** TBD
**Domain:** tak.karabastactical.nl

## Test Summary

Phase 1 Objective: Validate that a user can scan a QR code and connect to TAK server without importing a zip file.

### Pass/Fail Criteria
- [ ] ATAK 5.1+ user scans QR → enrolled and connected in <60 seconds
- [ ] iTAK user scans QR → prompted for credentials → connected in <90 seconds
- [ ] No "identity could not be verified" error on either platform
- [ ] Certificate enrollment enabled in TAK server
- [ ] Caddy with Let's Encrypt working on tak.karabastactical.nl

## Test 1: ATAK Enrollment (Android)

**Device:** TBD
**ATAK Version:** TBD
**Network:** TBD (WiFi/Mobile)

| Step | Action | Expected Result | Actual Result | Status |
|------|--------|----------------|---------------|--------|
| 1 | Install fresh ATAK from Play Store | App installed | | |
| 2 | Generate QR: `./generate-qr.sh testuser1` | QR PNG files created | | |
| 3 | Open phone camera, scan ATAK QR | Camera detects tak:// link | | |
| 4 | Tap link | ATAK opens, shows enrollment prompt | | |
| 5 | Tap "Enroll" | Spinner, then success | | |
| 6 | Check connection indicator | Green, connected to server | | |
| 7 | Record total time | PASS: <60 seconds | | |

**Total Time:** TBD
**Notes:** TBD

## Test 2: iTAK Enrollment (iOS)

**Device:** TBD
**iTAK Version:** TBD
**Network:** TBD (WiFi/Mobile)

| Step | Action | Expected Result | Actual Result | Status |
|------|--------|----------------|---------------|--------|
| 1 | Install fresh iTAK from App Store | App installed | | |
| 2 | Open iOS camera, scan iTAK QR | Camera detects text | | |
| 3 | Tap notification | iTAK opens, shows server add dialog | | |
| 4 | Enter username/password from script output | Credentials accepted | | |
| 5 | Tap "Connect" | Spinner, then success | | |
| 6 | Check connection indicator | Green, connected to server | | |
| 7 | Record total time | PASS: <90 seconds | | |

**Total Time:** TBD
**Notes:** TBD

## Test 3: TLS Trust Verification

| Step | Action | Expected Result | Actual Result | Status |
|------|--------|----------------|---------------|--------|
| 1 | On Android, attempt enrollment | No "identity could not be verified" error | | |
| 2 | On iOS, attempt enrollment | No SSL warning dialogs | | |
| 3 | Check browser: https://tak.karabastactical.nl/health | Valid Let's Encrypt cert, no warnings | | |

**Browser Test:**
- Certificate Issuer: TBD
- Certificate Valid Until: TBD
- Browser: TBD

## Test 4: Field Simulation

| Step | Action | Expected Result | Actual Result | Status |
|------|--------|----------------|---------------|--------|
| 1 | Disable WiFi on test device | Mobile data only | | |
| 2 | Attempt full enrollment | Completes successfully | | |
| 3 | Move to marginal signal area | PLI still transmits | | |

**Network Conditions:** TBD
**Signal Strength:** TBD

## Infrastructure Verification

### DNS Configuration
```bash
$ dig tak.karabastactical.nl
# Output: TBD
```

### Caddy Health Check
```bash
$ curl https://tak.karabastactical.nl/health
# Output: TBD
```

### TAK Server Status
```bash
$ docker compose -f infra/docker-compose.prod.yml ps
# Output: TBD
```

### Certificate Enrollment Status
- TAK Admin UI Accessed: [ ] Yes [ ] No
- Certificate Enrollment Enabled: [ ] Yes [ ] No
- Screenshot: TBD

## Issues Encountered

### Issue 1
**Description:** TBD
**Impact:** TBD
**Resolution:** TBD

## Conclusion

**Overall Status:** [ ] PASS [ ] FAIL

**Decision:**
- [ ] Proceed to Phase 2
- [ ] Iterate on Phase 1 (specify changes needed)
- [ ] Re-evaluate approach

**Lessons Learned:** TBD

**Next Steps:** TBD

---

**Signed:**
**Date:**
