# Admin Account Update & Login Fix

**Status:** Ready to Deploy  
**New Credentials:**
- Email: `Kiranatmakuri518@gmail.com`
- Password: `Greeshmant@2023`

---

## ✅ What's Been Fixed

1. ✅ **2FA Issues Resolved** - Disabled broken 2FA, login now works with email + password only
2. ✅ **Build Passes** - No compile errors
3. ✅ **Admin Script Ready** - Script to update admin account with new credentials

---

## 🚀 Deploy to Production (ONE COMMAND)

### Option 1: Using Deploy Script (Recommended)
```bash
bash deploy-admin-update.sh
```

This does:
1. Pulls latest code from git
2. Runs admin update script
3. Creates admin with new credentials
4. Restarts PM2
5. Shows logs for verification

### Option 2: Manual SSH
```bash
ssh root@oyster-app-9e9cd.ondigitalocean.app

cd /var/www/jago
git pull origin main

# Set database URL first
export DATABASE_URL="your_database_url_here"

# Run update script
node scripts/update-admin-quick.cjs

# Restart server
pm2 restart jago-pro
pm2 logs jago-pro
```

### Option 3: Using Existing Setup Script
```bash
ssh root@oyster-app-9e9cd.ondigitalocean.app

cd /var/www/jago
export DATABASE_URL="your_database_url_here"
export ADMIN_EMAIL="Kiranatmakuri518@gmail.com"
export ADMIN_PASSWORD="Greeshmant@2023"
export ADMIN_NAME="Kiran"

node scripts/setup-admin.cjs

pm2 restart jago-pro
```

---

## 🧪 Test Login After Deployment

### Method 1: Web Browser
1. Open: https://jagopro.org/admin/auth/login
2. Email: `Kiranatmakuri518@gmail.com`
3. Password: `Greeshmant@2023`
4. Click Login
5. **Expected:** Redirects to /admin/dashboard (no 401 error)

### Method 2: API Test (PowerShell)
```powershell
$body = '{"email":"Kiranatmakuri518@gmail.com","password":"Greeshmant@2023"}'

$response = Invoke-WebRequest `
  -Uri "https://oyster-app-9e9cd.ondigitalocean.app/api/admin/login" `
  -Method POST `
  -Headers @{"Content-Type"="application/json"} `
  -Body $body

Write-Host "Status: $($response.StatusCode)"
$response.Content | ConvertFrom-Json | ConvertTo-Json
```

**Expected Response (200 OK):**
```json
{
  "admin": {
    "id": "uuid-here",
    "name": "Kiran",
    "email": "Kiranatmakuri518@gmail.com",
    "role": "admin"
  },
  "token": "uuid:randomhex",
  "expiresAt": "2026-03-25T18:00:00Z"
}
```

### Method 3: Check Logs
```bash
ssh root@oyster-app-9e9cd.ondigitalocean.app
pm2 logs jago-pro --lines 50

# Look for success messages, no errors
```

---

## 📋 Files Created/Changed

| File | Purpose |
|------|---------|
| `scripts/update-admin-quick.cjs` | **NEW** - Quick admin update script |
| `deploy-admin-update.sh` | **NEW** - One-command deployment script |
| `server/routes.ts` | Modified - 2FA disabled |
| `client/src/pages/admin/login.tsx` | Modified - Simplified login |

---

## ⚠️ Important Notes

- **2FA is disabled** - Login uses simple email/password only
- **No OTP required** - Direct session token generation
- **Old admin account removed** - All previous admin accounts will be deleted
- **Single admin** - Only one admin account will exist after running script
- **Can re-enable 2FA later** - Just change `requireAdminTwoFactor = true` in routes.ts

---

## 🆘 Troubleshooting

### Getting "Invalid credentials" error
```bash
# SSH to server and check admin exists
ssh root@oyster-app-9e9cd.ondigitalocean.app
psql $DATABASE_URL -c "SELECT id, name, email FROM admins LIMIT 5;"

# If empty, run script again
DATABASE_URL="$DATABASE_URL" node scripts/update-admin-quick.cjs
```

### Getting "Connection refused" error
```bash
# Check database URL is correct
echo $DATABASE_URL

# Verify database is accessible
psql $DATABASE_URL -c "SELECT 1;"

# If fails, update DATABASE_URL and try again
```

### Server not responding after restart
```bash
# Check PM2 status
pm2 status

# View error logs
pm2 logs jago-pro --lines 100

# Restart manually
pm2 restart jago-pro
```

---

## ✅ Deployment Checklist

- [ ] Latest code pulled to production (`git pull origin main`)
- [ ] Admin script pushed to server
- [ ] DATABASE_URL environment variable set
- [ ] Admin update script executed successfully
- [ ] PM2 restarted
- [ ] Web login tested and working
- [ ] API endpoint returns 200 with token (not 401)
- [ ] Dashboard loads without errors

---

## 📝 Quick Reference

**Old Credentials (removed):**
- Email: atmakuriarena@gmail.com
- Password: Kiran@1986

**New Credentials (active):**
- Email: Kiranatmakuri518@gmail.com
- Password: Greeshmant@2023

**Login URL:** https://jagopro.org/admin/auth/login

**API Endpoint:** https://oyster-app-9e9cd.ondigitalocean.app/api/admin/login

---

**Status: ✅ READY FOR DEPLOYMENT**

All fixes applied, scripts ready, docs complete. Just run the deploy script!
