# APK Auto-Sync System

**Purpose**: Automatically copy latest APK files from `release-apks/` to `public/apks/` for download  
**Status**: ✅ Fully Automated (No Manual Copying Needed)

---

## 🎯 **How It Works**

### Automatic Triggers
The APK sync runs **automatically** in these scenarios:

1. **Before Build** (`npm run build`)
   - Syncs APKs before compiling code
   - Ensures latest versions are available when deployed

2. **Before Start** (`npm start`)
   - Syncs APKs before starting the server
   - Guarantees downloads work immediately after restart

3. **Manual Request** (`npm run sync-apks`)
   - Manually trigger sync anytime

---

## 📋 **What Gets Synced**

### Priority Versions (Always Synced)
- ✅ `jago-customer-v1.0.55-release.apk` (Latest Customer)
- ✅ `jago-pilot-v1.0.57-release.apk` (Latest Driver)
- ✅ `jago-customer-final.apk` (Customer Production)
- ✅ `jago-driver-final.apk` (Driver Production)

### Fallback Versions (If Newer)
- Older versions if they're updated
- Automatically detects newer files by timestamp

---

## 🔧 **Usage**

### Manual Sync (On Demand)
```bash
npm run sync-apks
```

**Output:**
```
🔄 Starting APK Auto-Sync...

📦 Found 8 APK files:

✅ Synced: jago-customer-v1.0.55-release.apk
✅ Synced: jago-pilot-v1.0.57-release.apk
✅ Synced: jago-customer-final.apk
✅ Synced: jago-driver-final.apk

✨ Sync complete! 4 files synced.

📋 Latest versions status:
   ✅ Customer v1.0.55 available
   ✅ Driver v1.0.57 available

🎉 All APKs ready for download!
```

### Automatic Sync During Build
```bash
npm run build
```

**What happens:**
1. `npm run prebuild` triggers → Syncs APKs
2. `tsx script/build.ts` runs → Builds code
3. APKs now in `public/apks/` ready for users

### Automatic Sync During Deployment
```bash
npm start
```

**What happens:**
1. `npm run prestart` triggers → Syncs APKs
2. `node dist/index.js` runs → Server starts
3. Download endpoints immediately have latest APKs

---

## 📂 **File Flow**

```
release-apks/  (Source - Where you keep release builds)
├── jago-customer-v1.0.55-release.apk
├── jago-pilot-v1.0.57-release.apk
├── jago-customer-final.apk
└── jago-driver-final.apk
    ↓ [Automatic Sync]
    ↓
public/apks/   (Destination - Where users download)
├── jago-customer-v1.0.55-release.apk
├── jago-pilot-v1.0.57-release.apk
├── jago-customer-final.apk
└── jago-driver-final.apk
    ↓ [Users access via]
    ↓
https://yourserver.com/apks/jago-customer-v1.0.55-release.apk
https://yourserver.com/apks/jago-pilot-v1.0.57-release.apk
```

---

## ✅ **Verification**

### Check If Sync Worked
```bash
# See what's in public/apks
ls public/apks/*.apk

# Should show:
# jago-customer-v1.0.55-release.apk
# jago-pilot-v1.0.57-release.apk
# jago-customer-final.apk
# jago-driver-final.apk
# (+ older versions)
```

### Test Download Links
```bash
# These should work after sync
curl -I https://yourserver.com/apks/jago-customer-v1.0.55-release.apk
curl -I https://yourserver.com/apks/jago-pilot-v1.0.57-release.apk

# Should return 200 OK
```

---

## 🚀 **Deployment Workflow**

### On Your Local Machine
```bash
# Make a new build for release
flutter build apk --release

# Copy to release-apks/
cp flutter_apps/customer_app/build/app/outputs/apk/release/app-release.apk \
   release-apks/jago-customer-v1.0.XX-release.apk

# Auto-sync happens when you build
npm run build

# APKs now available for download!
```

### On Production Server (DigitalOcean)
```bash
# Pull latest code (includes sync script)
git pull origin master

# Build automatically syncs APKs
npm run build

# Deploy (auto-syncs before start)
pm2 restart jago-pro

# APKs immediately available for download
```

---

## 🔄 **How Automatic Sync Helps**

### Before (Manual)
```bash
# You had to:
1. Copy APK manually
2. Remember to commit it
3. Manually push it
4. Hope it's in right place
5. If forgotten = broken downloads
```

### After (Automatic)
```bash
# System ensures:
1. ✅ Every build copies latest APKs
2. ✅ Every deploy updates APKs
3. ✅ No manual steps
4. ✅ Downloads always work
5. ✅ Latest versions always available
```

---

## 📊 **What Syncs And Doesn't**

### What ALWAYS Gets Synced ✅
- Latest versions matching patterns
- Files in release-apks directory
- Both customer and driver apps
- Final versions for production

### What DOESN'T Sync (Manual Only)
- Older archived versions (unless newer)
- Beta or pre-release APKs
- Development test builds
- Files outside release-apks/

---

## ⚙️ **Technical Details**

### Script Location
`script/sync-apks.js` - Node.js script runs before build/start

### How It Finds Files
1. Scans `release-apks/` directory
2. Finds all `.apk` files
3. Checks target dates in `public/apks/`
4. Copies if source is newer or missing
5. Reports status

### Error Handling
- If source file missing → Skipped (no error)
- If destination permission denied → Warns but continues
- If partially synced → Still usable

---

## 🎯 **You Don't Need To Do Anything**

After building APKs locally:

```bash
# Just run build - everything else is automatic!
npm run build

# APKs automatically synced
# Ready to deploy
# Users can download immediately
```

---

## 📞 **Troubleshooting**

### "APK sync failed"
Check permissions:
```bash
# Ensure directories exist and are writable
chmod -R 755 release-apks/
chmod -R 755 public/apks/
```

### "APK not showing in downloads"
Manually trigger sync:
```bash
npm run sync-apks
```

### "Sync says file synced but not visible"
Check path:
```bash
ls -la public/apks/
# Should show the .apk files
```

---

## ✨ **Summary**

- ✅ **Automatic**: No manual copying needed
- ✅ **Smart**: Detects which files are new
- ✅ **Safe**: Won't overwrite newer files
- ✅ **Fast**: Runs in milliseconds
- ✅ **Reliable**: Works every build/deployment
- ✅ **Zero Config**: Already set up!

**Just build and deploy - APK sync happens automatically! 🚀**

