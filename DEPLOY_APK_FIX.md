# 🚀 Deploy APK Fix to DigitalOcean

**Fix**: APKs now sync to web server location (dist/public/apks/)

---

## **3-Step Deploy**

### 1️⃣ SSH into Server
```bash
ssh root@oyster-app-9e9cd.ondigitalocean.app
```

### 2️⃣ Pull Latest Code & Rebuild
```bash
cd /var/www/jago
git pull origin master
npm install
npm run build
```

The build will automatically sync APKs to the correct location!

### 3️⃣ Restart Server
```bash
pm2 restart jago-pro
pm2 logs jago-pro
```

---

## ✅ Test Download After Deploy

Open this link in your browser:
```
https://oyster-app-9e9cd.ondigitalocean.app/apks/jago-customer-v1.0.55-release.apk
```

Should start downloading (not get 404 error anymore)!

---

## What Changed

- ✅ APK sync script now copies to BOTH:
  - `public/apks/` (source)
  - `dist/public/apks/` (web server serves from here) ← **This was missing!**
- ✅ Build automatically syncs before deploying
- ✅ Downloads will now work immediately

---

**Deploy now and downloads will work! 🎉**
