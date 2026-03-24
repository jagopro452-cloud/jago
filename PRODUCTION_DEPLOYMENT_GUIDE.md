# 🚀 PRODUCTION DEPLOYMENT GUIDE
**DO NOT STOP UNTIL LIVE SERVER MATCHES LOCAL CODE**

**Server:** oyster-app-9e9cd.ondigitalocean.app  
**Repository:** https://github.com/jagopro452-cloud/jago.git  
**Latest Commit:** f0d9a20 (Add complete honest admin system audit)

---

## ⚠️ PRE-DEPLOYMENT CHECKLIST

Before deploying, verify locally:

```bash
cd c:\Users\kiran\Downloads\jago-main

# 1. Verify latest code is pulled
git status
# Expected: nothing to commit, working tree clean

# 2. Verify latest commit
git log --oneline -1
# Expected: f0d9a20 Add complete honest admin system audit

# 3. Verify build passes
npm run build
# Expected: exit code 0, no errors

# 4. Verify admin script exists and has correct credentials
cat scripts/update-admin-quick.cjs | grep -A2 "adminEmail\|adminPassword"
# Expected:
# const adminEmail = 'Kiranatmakuri518@gmail.com';
# const adminPassword = 'Greeshmant@2023';

# 5. Verify 2FA disabled
grep -n "if (false)" server/routes.ts | grep "2FA"
# Expected: line 3081 with "if (false) { // 2FA DISABLED"
```

---

## 🔑 STEP 1: SSH INTO PRODUCTION SERVER

```bash
# From your local machine:
ssh deploy@oyster-app-9e9cd.ondigitalocean.app

# You should see:
# deploy@oyster-app-9e9cd:~$
```

**Troubleshooting:**
- If SSH fails: Check you have the private key in `~/.ssh/id_rsa`
- If permission denied: Contact DigitalOcean support

---

## 📥 STEP 2: PULL LATEST CODE

```bash
cd /app

# Show current commit before pulling
echo "=== CURRENT CODE BEFORE PULL ==="
git log --oneline -1

# Pull latest code
git pull origin master

# Show new commit after pulling
echo "=== LATEST CODE AFTER PULL ==="
git log --oneline -1
# Expected: f0d9a20 Add complete honest admin system audit

# Verify no conflicts
git status
# Expected: nothing to commit, working tree clean
```

**Expected Output:**
```
=== CURRENT CODE BEFORE PULL ===
[current commit hash] ...

Updating [old commit]..f0d9a20
Fast-forward
 ADMIN_HONEST_COMPLETE_AUDIT.md      | 459 ++++++++++++
 FINAL_VERIFICATION_REPORT.md        | 513 +++++++++++++
 ... [other files]

=== LATEST CODE AFTER PULL ===
f0d9a20 Add complete honest admin system audit
$ nothing to commit, working tree clean
```

---

## 📦 STEP 3: INSTALL DEPENDENCIES

```bash
cd /app

# Show Node version (should be 16+ or 18+)
node --version

# Install dependencies
npm install

# This may take 1-2 minutes...
# Expected output:
# added X packages in Xs
```

**If npm install fails:**
- Run: `npm cache clean --force`
- Then retry: `npm install`

---

## 🗄️ STEP 4: RUN DATABASE MIGRATIONS

```bash
cd /app

# Show current database status
echo "=== CHECKING DATABASE ==="
echo $DATABASE_URL | head -c 50
# Should show: postgresql://... (don't show full URL for security)

# Run migrations
npm run migrate

# Expected output:
# [db] Running migrations from: /app/migrations
# [db] Migrations applied OK — all tables ready
# No errors should appear
```

**If migration fails:**
- Check DATABASE_URL is set: `echo $DATABASE_URL`
- Verify Neon/PostgreSQL is accessible
- Check migrations folder exists: `ls -la migrations/`

---

## 👤 STEP 5: EXECUTE ADMIN UPDATE SCRIPT

```bash
cd /app

# Run the admin update script
echo "=== UPDATING ADMIN CREDENTIALS ==="
DATABASE_URL="$DATABASE_URL" node scripts/update-admin-quick.cjs

# Expected output:
# 🔧 Updating admin account...
# 
# 🔐 Hashing password with bcrypt...
# 🗑️ Removing old admin accounts...
# 👤 Creating new admin account...
# ✅ Admin created:
# 
#    ID:    [UUID]
#    Name:  Kiran
#    Email: Kiranatmakuri518@gmail.com
#    Role:  admin
# 
# ✅ Ready to login!
# 
# 📝 Use these credentials:
#    Email:    Kiranatmakuri518@gmail.com
#    Password: Greeshmant@2023
```

**If script fails:**
- Check DATABASE_URL: `echo $DATABASE_URL`
- Verify bcrypt module installed: `npm list bcrypt`
- Check admin table exists: `psql $DATABASE_URL -c "SELECT * FROM admins LIMIT 1"`

---

## 🔄 STEP 6: RESTART SERVER

```bash
cd /app

# Show current PM2 processes
pm2 list

# Stop old processes (if any)
pm2 stop all

# Clear old processes
pm2 delete all

# Start fresh
pm2 start dist/index.js --name "jago-api" --instances max

# Or if using ecosystem.config.cjs:
pm2 start ecosystem.config.cjs

# Show status
pm2 list

# Expected output:
# ┌────┬──────────┬──────┬──────┬─────┬
# │ id │ name     │ mode │ ↺    │ memory │
# ├────┼──────────┼──────┼──────┼──────┤
# │ 0  │ jago-api │ fork │ 0    │ 45.2MB │
# └────┴──────────┴──────┴──────┴────────┘

# Show logs (exit with Ctrl+C)
pm2 logs jago-api --lines 50

# Expected: No error messages, server listening on port
```

**If PM2 restart fails:**
- Check dist folder exists: `ls -la dist/`
- Verify build ran: `npm run build`
- Check port 5000 is available: `netstat -tulpn | grep 5000`

---

## ✅ STEP 7: VERIFY DEPLOYMENT

### 7A. Check Server is Running

```bash
# Check if port 5000 is listening
curl -i http://localhost:5000/api/health

# Expected output:
# HTTP/1.1 200 OK
# {"status":"ok"}
```

### 7B. Test Admin Login (LOCAL on server)

```bash
# Test login endpoint
curl -X POST http://localhost:5000/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "Kiranatmakuri518@gmail.com",
    "password": "Greeshmant@2023"
  }'

# Expected output (200 OK, NOT 202):
# HTTP/1.1 200 OK
# {
#   "admin": {
#     "id": "[UUID]",
#     "name": "Kiran",
#     "email": "Kiranatmakuri518@gmail.com",
#     "role": "admin"
#   },
#   "token": "...[long token]...",
#   "expiresAt": "2026-03-25T..."
# }
```

**What NOT to expect:**
```
❌ HTTP 202 Accepted (means 2FA is still running)
❌ "requiresTwoFactor": true (means 2FA not disabled)
❌ HTTP 401 Unauthorized (means password wrong or admin not found)
❌ HTTP 500 Internal Server Error (means database error)
```

### 7C. Verify Database Was Updated

```bash
# Check admin in database
psql $DATABASE_URL -c "SELECT id, name, email, role, is_active FROM admins LIMIT 1;"

# Expected output:
#                    id                 | name  |               email               | role  | is_active
# ───────────────────────────────────────────────┼──────────┼──────────────────────────────────────┼───────┼───────────
#  [a UUID]                            | Kiran | Kiranatmakuri518@gmail.com        | admin | t
```

### 7D. Check Logs for Errors

```bash
# Show last 100 lines of logs
pm2 logs jago-api --lines 100

# Look for errors like:
# ❌ [db] MIGRATION FAILED
# ❌ Error: UPDATE admins failed
# ❌ Cannot read property of undefined
# ❌ ECONNREFUSED

# If you see errors, scroll up and note the exact error message
```

---

## 🌐 STEP 8: TEST FROM BROWSER (LOCAL MACHINE)

On your computer (NOT on the server):

### Open Admin Login Page
```
URL: https://jagopro.org/admin/auth/login
```

**Expected:**
- Page loads without errors
- Login form visible
- No browser console errors

### Submit Login

```
Email:    Kiranatmakuri518@gmail.com
Password: Greeshmant@2023
Click: Login
```

**Expected:**
- Form submits (shows loading spinner briefly)
- Redirects to dashboard: https://jagopro.org/admin/dashboard
- Session token stored in localStorage
- Dashboard loads with data

**If login fails:**

Open DevTools (F12) → Network tab:

```
Look for POST /api/admin/login
Check response:
- Status: Should be 200 (NOT 202)
- Body: Should have "token" field
- Check for error message in response
```

### Verify No 2FA Screen

```
After login, you should NOT see:
❌ "Enter OTP"
❌ "Check your phone for OTP"
❌ "Verification code sent"

You SHOULD see:
✅ Admin dashboard
✅ Drivers list
✅ Trips analytics
```

---

## 🔍 STEP 9: COMPREHENSIVE VERIFICATION

### Check All Admin Functions

1. **Dashboard loads:** https://jagopro.org/admin/dashboard
2. **Drivers tab:** https://jagopro.org/admin/drivers
3. **Trips tab:** https://jagopro.org/admin/trips
4. **Settings:** https://jagopro.org/admin/settings

All should load without saying "Unauthorized" or "401".

### Check API Endpoints

```bash
# From server, test key endpoints (replace TOKEN with actual token from login test above)

TOKEN="[token from login response above]"

# Test driver list
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:5000/api/admin/drivers

# Test trips
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:5000/api/admin/trips

# Test settings
curl -H "Authorization: Bearer $TOKEN" \
  http://localhost:5000/api/admin/settings

# All should return 200 OK
```

### Check No Old Data

```bash
# Verify OLD admin is deleted
psql $DATABASE_URL -c "
  SELECT email FROM admins WHERE email NOT LIKE '%Kiranatmakuri%';
"

# Expected: No rows returned (all old admins deleted)

# Verify ONLY new admin exists
psql $DATABASE_URL -c "
  SELECT email, role FROM admins;
"

# Expected: Only one row with Kiranatmakuri518@gmail.com
```

---

## 📊 STEP 10: FINAL VERIFICATION CHECKLIST

Complete all checks and mark as ✅:

```
DEPLOYMENT VERIFICATION CHECKLIST
═════════════════════════════════════════════════════════════════════

[ ] Code Deployment
    [ ] git pull origin master succeeded
    [ ] git log shows f0d9a20 as latest commit
    [ ] No uncommitted changes (git status clean)

[ ] Dependencies
    [ ] npm install completed successfully
    [ ] node_modules directory exists
    [ ] All required packages installed

[ ] Database
    [ ] DATABASE_URL environment variable set
    [ ] psql connection works (can reach database)
    [ ] Migrations ran without errors
    [ ] admins table exists with correct schema

[ ] Admin Account
    [ ] Admin update script executed successfully
    [ ] Old admin accounts deleted
    [ ] New admin created: Kiranatmakuri518@gmail.com
    [ ] Password hashed with bcrypt 12
    [ ] role = 'admin', is_active = true

[ ] Server
    [ ] PM2 processes started (pm2 list shows running)
    [ ] Port 5000 listening (curl http://localhost:5000/api/health returns 200)
    [ ] No PM2 errors in logs

[ ] 2FA
    [ ] if (false) guard confirmed in code at line 3081
    [ ] Login returns 200 OK (NOT 202)
    [ ] No "requiresTwoFactor" in response
    [ ] No OTP screen appears

[ ] Frontend Login
    [ ] Admin login page loads: https://jagopro.org/admin/auth/login
    [ ] Login succeeds with new credentials
    [ ] Redirects to dashboard: https://jagopro.org/admin/dashboard
    [ ] No "Unauthorized" errors
    [ ] Session token in localStorage

[ ] Dashboard
    [ ] Dashboard page loads completely
    [ ] All tabs visible (Drivers, Trips, Settings, etc.)
    [ ] No 401 errors in browser console
    [ ] Data loads (drivers list shows drivers, etc.)

[ ] APIs
    [ ] /api/admin/drivers returns 200 OK
    [ ] /api/admin/trips returns 200 OK
    [ ] /api/admin/settings returns 200 OK
    [ ] All endpoints accept Bearer token

[ ] Production Ready
    [ ] No old credentials anywhere
    [ ] No old admin account in database
    [ ] All new code deployed and running
    [ ] Logs show no errors
    [ ] Health check passes (/api/health)
```

---

## 🆘 TROUBLESHOOTING

### Problem: git pull fails with "permission denied"

```bash
# Solution: Check SSH key
ssh-keygen -t ed25519
# Add public key to GitHub: https://github.com/settings/keys
```

### Problem: npm install fails

```bash
# Solution: Clear cache and retry
npm cache clean --force
npm install --verbose
```

### Problem: Database migration fails

```bash
# Check database URL
echo $DATABASE_URL

# Test database connection manually
psql "$DATABASE_URL" -c "SELECT 1;"

# If connection fails, verify:
# - DATABASE_URL is correct in DigitalOcean dashboard
# - Neon database is active and not suspended
# - IP whitelisting allows DigitalOcean server
```

### Problem: Admin update script fails

```bash
# Check admin table exists
psql "$DATABASE_URL" -c "SELECT * FROM admins LIMIT 1;"

# If table missing, run migrations first:
npm run migrate

# Then retry script:
DATABASE_URL="$DATABASE_URL" node scripts/update-admin-quick.cjs
```

### Problem: PM2 won't start

```bash
# Kill any old processes
pkill -f "node.*dist/index.js"

# Check if port 5000 is already in use
lsof -i :5000

# If port in use, kill the process:
kill -9 [PID]

# Restart PM2
pm2 start dist/index.js --name "jago-api"
```

### Problem: Login returns 401 with "Invalid credentials"

```bash
# Verify admin exists in database
psql "$DATABASE_URL" -c "
  SELECT email, role, is_active FROM admins 
  WHERE email = 'Kiranatmakuri518@gmail.com';
"

# If not found, run admin update script again:
DATABASE_URL="$DATABASE_URL" node scripts/update-admin-quick.cjs

# If password wrong, hash and update manually (expert only):
# NODE_ENV=production node -e "
# const bcrypt = require('bcryptjs');
# bcrypt.hash('Greeshmant@2023', 12).then(h => 
#   console.log('UPDATE admins SET password = \'', h, '\' WHERE email = \'Kiranatmakuri518@gmail.com\';')
# );
# "
```

### Problem: Login returns 202 "requiresTwoFactor"

```bash
# This means old code is still running

# Check if 2FA guard is in code
grep "if (false)" server/routes.ts | grep -c "2FA"
# Should return: 1

# If 0, pull latest code:
git pull origin master

# Rebuild:
npm run build

# Restart:
pm2 restart all
```

---

## ✅ SUCCESS CRITERIA

When deployment is COMPLETE and CORRECT, verify ALL of these:

1. ✅ **Code matches GitHub**
   ```bash
   git log --oneline -1
   # Shows: f0d9a20 Add complete honest admin system audit
   ```

2. ✅ **Server is running**
   ```bash
   pm2 list
   # Shows: jago-api running (green)
   ```

3. ✅ **Admin credentials are updated**
   ```bash
   psql $DATABASE_URL -c "SELECT email FROM admins;"
   # Shows: Kiranatmakuri518@gmail.com
   ```

4. ✅ **Old admin deleted**
   ```bash
   psql $DATABASE_URL -c "SELECT COUNT(*) FROM admins;"
   # Shows: 1 (only new admin)
   ```

5. ✅ **2FA disabled**
   ```bash
   curl -X POST http://localhost:5000/api/admin/login \
     -H "Content-Type: application/json" \
     -d '{"email":"Kiranatmakuri518@gmail.com","password":"Greeshmant@2023"}'
   # Returns: 200 OK with token (NOT 202)
   ```

6. ✅ **Dashboard loads**
   ```
   Browser: https://jagopro.org/admin/dashboard
   Status: Page loads, shows drivers/trips data
   ```

7. ✅ **No errors in logs**
   ```bash
   pm2 logs jago-api | grep -i error
   # Returns: No lines (no errors)
   ```

---

## 📝 DEPLOYMENT LOG TEMPLATE

Copy this and fill it out as you deploy:

```
╔═══════════════════════════════════════════════════════════════════╗
║           PRODUCTION DEPLOYMENT LOG - March 24, 2026              ║
╚═══════════════════════════════════════════════════════════════════╝

START TIME: ___:___ UTC

STEP 1: SSH
  Command: ssh deploy@oyster-app-9e9cd.ondigitalocean.app
  Status: [ ] PASS [ ] FAIL
  Note: ___________________________

STEP 2: PULL CODE
  Before commit: _________________________
  After commit:  f0d9a20 (expected)
  Status: [ ] PASS [ ] FAIL
  Note: ___________________________

STEP 3: INSTALL DEPS
  npm install status: [ ] PASS [ ] FAIL
  Note: ___________________________

STEP 4: MIGRATIONS
  Migration output: ✅ All tables ready [ ] or ❌ Error [ ]
  Status: [ ] PASS [ ] FAIL
  Note: ___________________________

STEP 5: ADMIN UPDATE
  Email created: Kiranatmakuri518@gmail.com [ ]
  Admin ID: ______________________________
  Status: [ ] PASS [ ] FAIL
  Note: ___________________________

STEP 6: RESTART
  PM2 processes active: 1 "jago-api" [ ]
  Status: [ ] PASS [ ] FAIL
  Note: ___________________________

STEP 7: VERIFY
  Health check (200 OK): [ ]
  Admin exists in DB: [ ]
  Old admin deleted: [ ]
  Status: [ ] PASS [ ] FAIL
  Note: ___________________________

STEP 8: LOGIN TEST (Browser)
  URL: https://jagopro.org/admin/auth/login
  Email: Kiranatmakuri518@gmail.com
  Result: [ ] SUCCESS [ ] FAILED
  Note: ___________________________

STEP 9: DASHBOARD
  URL: https://jagopro.org/admin/dashboard
  Data loads: [ ] YES [ ] NO
  Status: [ ] PASS [ ] FAIL
  Note: ___________________________

FINAL STATUS: [ ] COMPLETE [ ] INCOMPLETE
END TIME: ___:___ UTC
TOTAL TIME: ___ minutes

NEXT ACTIONS:
[ ] Notify team deployment complete
[ ] Update deployment tracking
[ ] Create incident ticket if issues found
```

---

## 📞 NEED HELP?

If deployment fails:

1. **Take screenshot** of error
2. **Copy exact error message**
3. **Run:** `pm2 logs jago-api --lines 200 > /tmp/deployment.log`
4. **Copy log file** to your local machine
5. **Check:** Troubleshooting section above

---

**DO NOT STOP UNTIL:**
- ✅ Code committed and pushed
- ✅ Server restarted
- ✅ Login works
- ✅ Dashboard loads
- ✅ No errors in logs

**GOOD LUCK! 🚀**
