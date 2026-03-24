# JAGO PRO - DigitalOcean Production Deployment

**Status**: ✅ **READY TO DEPLOY**  
**Latest Build**: Built 2026-03-24  
**Latest Code**: Commit 951124b (APK inventory) + 533a032 (app versions) + all backend fixes  

---

## 🚀 **QUICK DEPLOY (3 Steps)**

### Step 1: SSH into DigitalOcean Server
```bash
ssh root@oyster-app-9e9cd.ondigitalocean.app
# Or use your server IP if different
```

### Step 2: Pull Latest Code & Build
```bash
cd /var/www/jago
git pull origin master
npm install
npm run build
```

### Step 3: Restart with PM2
```bash
pm2 restart jago-pro
pm2 logs jago-pro  # Check logs for errors
```

---

## 📋 **WHAT'S BEING DEPLOYED**

### Backend Fixes
- ✅ Password hashing: Standardized to bcrypt 12 rounds
- ✅ Database connections: 20 → 50 (production scale)
- ✅ Connection timeout: 10s → 5s (fail-fast)
- ✅ Admin login: Fixed bcrypt verification
- ✅ Diagnostic endpoints: `/api/ping`, `/api/diag/env`, `/api/diag/admin-status`

### Mobile App Versions
- ✅ Customer App: Updated to v1.0.55 (build.gradle synced)
- ✅ Driver App: Updated to v1.0.57 (build.gradle synced)

### Documentation
- ✅ APK release package created
- ✅ APK inventory with download links
- ✅ Production audit complete
- ✅ All fixes documented

---

## 🔍 **VERIFICATION AFTER DEPLOYMENT**

### 1. Health Check
```bash
curl https://oyster-app-9e9cd.ondigitalocean.app/api/health
# Should return: { "status": "ok" }
```

### 2. Admin Login Test
```bash
# Test admin login endpoint
curl -X POST https://oyster-app-9e9cd.ondigitalocean.app/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@jagopro.com",
    "password": "JagoAdmin@2026!"
  }'
```

### 3. Check Environment Variables
```bash
curl https://oyster-app-9e9cd.ondigitalocean.app/api/diag/env
# Shows what environment variables are loaded
```

### 4. Verify Admin Status
```bash
curl https://oyster-app-9e9cd.ondigitalocean.app/api/diag/admin-status
# Shows admin account info and password hash quality
```

---

## 📝 **DEPLOYMENT CHECKLIST**

**Before Deploying:**
- [ ] Backed up current database
- [ ] Noted current admin password
- [ ] Stopped accepting new user registrations (optional)
- [ ] Team notified of deployment window

**During Deployment:**
- [ ] SSH into DigitalOcean server
- [ ] Pull latest code from git
- [ ] Run npm install
- [ ] Run npm run build
- [ ] Restart PM2: `pm2 restart jago-pro`
- [ ] Monitor logs: `pm2 logs jago-pro`
- [ ] Wait 30 seconds for startup

**After Deployment:**
- [ ] Health check returns 200 OK
- [ ] Can access /api/health endpoint
- [ ] Admin login endpoint responds
- [ ] Customer API endpoints working
- [ ] Driver API endpoints working
- [ ] Websocket connections active
- [ ] Database queries executing
- [ ] No errors in PM2 logs
- [ ] Test admin panel login
- [ ] Monitor crash rate for 5 minutes

---

## 🔄 **ROLLBACK PROCEDURE (If Issues)**

If something goes wrong, quickly revert:

```bash
# View commit history
git log --oneline -10

# Revert to previous working commit
git reset --hard <commit-hash>

# Rebuild
npm install && npm run build

# Restart
pm2 restart jago-pro
```

**Previous Stable Commits:**
- ac10698 - Production fixes (before APK inventory)
- d389970 - Diagnostic endpoints (known stable)
- df5fa06 - Core fixes (baseline stable)

---

## 📊 **SERVER CONFIGURATION**

### Current Setup
```
Server: DigitalOcean App Platform
URL: https://oyster-app-9e9cd.ondigitalocean.app
Process Manager: PM2 (cluster mode, max instances)
Node Runtime: Node.js LTS
Environment: /var/www/jago/.env (must exist)
Build Command: npm run build
Start Command: pm2 start ecosystem.config.cjs
```

### Env File Required
**Location**: `/var/www/jago/.env`

```env
NODE_ENV=production
PORT=5000
DATABASE_URL=postgresql://user:password@host:5432/jago
ADMIN_EMAIL=admin@jagopro.com
JWT_SECRET=your-secret-key-here
FIREBASE_PROJECT_ID=your-firebase-project
RAZORPAY_KEY=your-razorpay-key
RAZORPAY_SECRET=your-razorpay-secret
```

⚠️ **If .env doesn't exist on server:**
1. Create it with production values
2. Ensure permissions: `chmod 600 /var/www/jago/.env`
3. Restart PM2

---

## 🔗 **RELATED DOCUMENTATION**

- [COMPLETE_PRODUCTION_FIX.md](COMPLETE_PRODUCTION_FIX.md) - All fixes detailed
- [THOROUGH_AUDIT_REPORT.md](THOROUGH_AUDIT_REPORT.md) - Full audit findings
- [APK_RELEASE_PACKAGE.md](APK_RELEASE_PACKAGE.md) - Mobile app release info
- [APK_INVENTORY_AND_DOWNLOADS.md](APK_INVENTORY_AND_DOWNLOADS.md) - APK download links

---

## 📞 **TROUBLESHOOTING**

### Issue: `npm install` fails
```bash
# Clear npm cache
npm cache clean --force
npm ci  # Clean install instead of npm install
```

### Issue: Build crashes with memory error
```bash
# Increase Node memory limit
export NODE_OPTIONS="--max-old-space-size=2048"
npm run build
```

### Issue: PM2 fails to restart
```bash
# Check if process was killed
pm2 status

# Force kill and restart
pm2 kill
pm2 start ecosystem.config.cjs --env production

# View logs
pm2 logs jago-pro
```

### Issue: Database connection timeout
```bash
# Check database connection string in .env
# Verify DATABASE_URL is correct
# Test connection:
psql $DATABASE_URL -c "SELECT 1"
```

### Issue: Admin login still not working
```bash
# Check admin table exists
psql $DATABASE_URL -c "SELECT * FROM users WHERE email='admin@jagopro.com';"

# Verify password hash uses bcrypt (starts with $2)
psql $DATABASE_URL -c "SELECT email, password FROM users WHERE email='admin@jagopro.com';"

# Expected output: $2b$12$[...rest of hash...]
```

---

## 🎯 **DEPLOYMENT COMPLETE CHECKLIST**

```
✅ Code pulled and built
✅ PM2 restarted successfully
✅ Health check passing (200 OK)
✅ Admin login endpoint working
✅ Database connected
✅ API endpoints responding
✅ WebSocket (Socket.IO) active
✅ No critical errors in logs
✅ Performance acceptable
✅ Ready for users
```

---

## 📞 **POST-DEPLOYMENT MONITORING**

Monitor for **24 hours** after deployment:

1. **CPU Usage**: Should stay <60%
2. **Memory**: Should stay <70%
3. **Error Rate**: Should stay <0.5%
4. **Response Time**: Should be <200ms median
5. **Failed Requests**: Should be <1%

View stats:
```bash
pm2 monit
```

---

**DEPLOYMENT IS READY. Execute the 3 steps above to go live! 🚀**

