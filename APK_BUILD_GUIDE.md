# 📱 APK BUILD GUIDE - Calendar/Expiry Fixes

**Latest Code Update:** March 24, 2026 - Commit ff5d282  
**Changes:** Calendar date picker fixes + Expiry date validation

---

## 🚀 Quick Build Commands (for Dev Team)

### Prerequisites Check
```bash
flutter --version        # Should be >= 3.x
flutter doctor          # Verify all dependencies
```

### Build Customer App APK
```bash
cd flutter_apps/customer_app
flutter clean           # Clean previous builds
flutter pub get         # Get dependencies
flutter build apk --release  # Build release APK
# Output: build/app/outputs/apk/release/app-release.apk
```

**Copy to downloads:**
```bash
cp build/app/outputs/apk/release/app-release.apk ../../public/apks/jago-customer-v1.0.56-release.apk
```

---

### Build Driver App APK  
```bash
cd flutter_apps/driver_app
flutter clean
flutter pub get
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk
```

**Copy to downloads:**
```bash
cp build/app/outputs/apk/release/app-release.apk ../../public/apks/jago-driver-v1.0.58-release.apk
```

---

## 🔧 What Changed (In These APKs)

### ✅ Driver App Fixes
**File:** `flutter_apps/driver_app/lib/screens/auth/register_screen.dart`

**License Expiry Date Picker:**
- ❌ **OLD:** Could only select past dates (broken for registration)
- ✅ **NEW:** Can select today → 10 years in future (correct for licenses)

**Expiry Status Display:**
- ✅ Shows "EXPIRED", "Expires in X days", etc.
- ✅ Color-coded: Red=expired, Orange=urgent, Green=valid
- ✅ Smart formatting: "2 weeks" instead of "14 days"

**Date of Birth Picker:**
- ✅ Separate logic for DOB vs Expiry dates
- ✅ DOB: Only past dates (1940-18 years ago)
- ✅ Expiry: Only future dates (today-10 years)

---

### ✅ Customer App Fixes
**File:** `flutter_apps/customer_app/lib/screens/offers/offers_screen.dart`

**Offer Expiry Display:**
- ❌ **OLD:** Only showed "Expires in 14 days" (basic)
- ✅ **NEW:** Smart formatting with color coding:
  - Expired offers → Red "EXPIRED"
  - Today → Orange "Expires today!"
  - < 7 days → Orange "Expires in 3 days"
  - < 30 days → Yellow "Expires in 2 weeks"
  - < 1 year → Green "Expires in 3 months"
  - > 1 year → Green "Expires in 2 years"

**Edge Cases Fixed:**
- ✅ No crash if expiry date missing
- ✅ No crash if date format invalid
- ✅ Proper null safety checks
- ✅ Graceful error handling

---

## 📋 Version Numbers

**Update to:**
- **Customer App:** v1.0.56 (from v1.0.55)
- **Driver/Pilot App:** v1.0.58 (from v1.0.57)

**Update in pubspec.yaml:**
```yaml
version: 1.0.56+56  # for customer app
version: 1.0.58+58  # for driver/pilot app
```

---

## 🔐 Signing (Production Release)

If building for Play Store:

```bash
flutter build apk --release --verbose \
  --sign-build \
  --android-key-store=true \
  --key-identifier=jago
```

**Using keystore file:**
```bash
# If key not already configured:
flutter build apk --release \
  --keystore-path=/path/to/jago-release-key.jks \
  --keystore-password=<PASSWORD> \
  --key-password=<PASSWORD> \
  --key-alias=jago
```

---

## ✅ Testing Before Upload

### Install on devices:
```bash
# For Customer App
adb install build/app/outputs/apk/release/app-release.apk

# Test:
# 1. Go to Registration
# 2. Try selecting license expiry date
# 3. Verify: Can select future dates (not past)
# 4. Verify: Shows expiry status with color

# For Offers:
# 1. Go to Offers tab
# 2. Check expiry tags: Color should match urgency
# 3. Verify: Expired offers show in Red
```

---

## 📤 After Building - Upload to Downloads

```bash
# Copy to public/apks (web server folder)
cp -r flutter_apps/customer_app/build/app/outputs/apk/release/app-release.apk \
      public/apks/jago-customer-v1.0.56-release.apk

cp -r flutter_apps/driver_app/build/app/outputs/apk/release/app-release.apk \
      public/apks/jago-driver-v1.0.58-release.apk

# Also copy as "final" for download button
cp public/apks/jago-customer-v1.0.56-release.apk \
   public/apks/jago-customer-final.apk

cp public/apks/jago-driver-v1.0.58-release.apk \
   public/apks/jago-driver-final.apk
```

---

## 🐛 Common Build Issues

**Issue:** "Flutter not found"
```bash
# Add to PATH or use full path
export PATH="$PATH:/path/to/flutter/bin"
flutter --version
```

**Issue:** "Android license not accepted"
```bash
flutter doctor --android-licenses
# Say 'y' to all prompts
```

**Issue:** "SDK compile version mismatch"
```bash
# Update compileSdkVersion in android/app/build.gradle
android {
    compileSdk 34  // Update to latest
}
```

**Issue:** "Keystore not found"
```bash
# Keystore is here:
ls -la flutter_apps/jago-release-key.jks
```

---

## 📊 File Sizes (Expected)

- Customer APK: ~85-90 MB
- Driver/Pilot APK: ~85-90 MB
- With fixes: Should be similar size

If significantly larger, check:
- No debug code left
- Assets not duplicated
- Unused packages removed

---

## ✅ Checklist Before Release

- [ ] Code merged from main branch (commit: ff5d282)
- [ ] Flutter clean build done
- [ ] versioning updated in pubspec.yaml
- [ ] Signed with release keystore
- [ ] Tested on physical device (not just emulator)
- [ ] License expiry picker works (can select future dates)
- [ ] Offer expiry colors display correctly
- [ ] No crashes in registration flow
- [ ] No crashes in offers screen
- [ ] APK size is reasonable (~85-90 MB)
- [ ] Uploaded to public/apks/
- [ ] Renamed to jago-customer-v1.0.56-release.apk format
- [ ] Also copied as jago-customer-final.apk

---

## 🔄 Deploy to Server

After uploading APKs:

```bash
# Copy to web server
scp public/apks/*.apk root@oyster-app-9e9cd.ondigitalocean.app:/var/www/public/apks/

# Or use rsync
rsync -avz public/apks/ root@server:/var/www/public/apks/

# Verify on server
ssh root@server
ls -la /var/www/public/apks/
# Should show new v1.0.56 and v1.0.58 files
```

---

## 📞 Support

If build fails:
1. Run `flutter doctor` first
2. Check Android SDK version (should be >= 33)
3. Clear caches: `flutter clean && flutter pub get`
4. Check git status: `git log --oneline -1` (should be ff5d282)
5. Try on clean machine if local environment corrupted

---

**Status:** Ready for dev team to build 🚀
