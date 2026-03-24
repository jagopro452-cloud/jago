# Fix DigitalOcean Connection Issues

## Status: ✅ Configuration Valid
All environment variables, migrations, and endpoints are properly configured.

## If Connection Still Failing

### Step 1: Verify DigitalOcean App Platform Status
1. Go to https://cloud.digitalocean.com/apps
2. Find your app: **jago-platform**
3. Check the deployment status:
   - Should show "Running" with green indicator
   - Check if latest deployment succeeded or failed in "Deployments" tab

### Step 2: Check App Logs
1. In DigitalOcean dashboard: App → Runtime logs
2. Look for these successful messages:
   ```
   [db] Migrations applied OK — all tables ready
   serving on port 8080
   [Socket.IO] Redis adapter connected
   ```

3. If you see errors like:
   - `ECONNREFUSED` → Database connection timeout
   - `Error: jwt malformed` → Authentication issue
   - `TIMEOUT waiting for connection` → Pool exhausted

### Step 3: Trigger a Redeploy
1. **Method A:** Push latest code to master branch
   ```bash
   git push origin master
   ```
   This auto-triggers redeploy (via "deploy_on_push: true" in app.yaml)

2. **Method B:** Manual redeploy in DigitalOcean
   - App → Deployments tab
   - Click "Redeploy Now" button

### Step 4: Reset Database (if migrations fail)
Once app is running:
```bash
# Replace YOUR_ADMIN_RESET_KEY with value from .do/app.yaml
curl "https://oyster-app-9e9cd.ondigitalocean.app/api/ops/init-db?key=JagoReset2026"
```

### Step 5: Verify Health Endpoint
```bash
curl https://oyster-app-9e9cd.ondigitalocean.app/api/health
```

Should return:
```json
{
  "status": "ok",
  "db": "connected",
  "ts": "2026-03-24T..."
}
```

## Common Issues & Fixes

### Issue: "Database connection timeout"
**Fix:** The Neon PostgreSQL connection might be slow to initialize
- Increase `connectionTimeoutMillis` in server/db.ts (currently 10000ms)
- Check Neon dashboard for pool exhaustion
- Restart the DigitalOcean app deployment

### Issue: "Redis unavailable"
**Fix:** App will fallback to in-memory adapter, but doesn't affect basic functionality
- Check REDIS_URL environment variable is set correctly
- Redis should be provisioned automatically via app.yaml

### Issue: "Migrations applying but then failing"
**Fix:** Database tables might be out of sync
- Use `/api/ops/init-db?key=ADMIN_RESET_KEY` to reset and reinit
- This drops all tables and re-creates from migrations

### Issue: "Port 8080 not responding"
**Fix:** App might be crashing on startup
- Check Runtime logs in DigitalOcean
- Verify all environment variables are set (not truncated)
- Check DATABASE_URL format is correct

## Deployment Script

If you want to force redeploy from command line:

```bash
# 1. Ensure all changes are committed
git status

# 2. Push to master (triggers auto-deploy)
git push origin master

# 3. Monitor deployment
# Go to: https://cloud.digitalocean.com/apps/jago-platform/deployments

# 4. Once deployed, test health
curl https://oyster-app-9e9cd.ondigitalocean.app/api/health
```

## Emergency: Quick Rollback

If new deployment breaks something:
1. Go to App → Deployments
2. Find previous working deployment
3. Click "Rollback to this deployment"

## Support Resources

- DigitalOcean App Platform Logs: https://cloud.digitalocean.com/apps/jago-platform/runtime-logs
- Check database status: Contact Neon support or check https://console.neon.tech
- Redis status: Should auto-provision with DigitalOcean app
- Monitor errors: Firebase Crashlytics dashboard
