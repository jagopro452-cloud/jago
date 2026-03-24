# JAGO Pro Mobile Apps & APK Structure Analysis

**Analysis Date:** March 24, 2026  
**Status:** ⚠️ **CRITICAL VERSION MISMATCH DETECTED**

---

## 1. APK FILES & LOCATIONS

### Available APK Files

#### Release APKs Directory (`/release-apks/`)
| File | Type | Version |
|------|------|---------|
| `jago-customer-v1.0.55-release.apk` | Customer App | 1.0.55 |
| `jago-customer-v1.0.30.apk` | Customer App | 1.0.30 |
| `jago-customer-final.apk` | Customer App | Latest Release |
| `jago-customer-2026-03-15.apk` | Customer App | 2026-03-15 Build |
| `jago-pilot-v1.0.57-release.apk` | Driver App | 1.0.57 |
| `jago-pilot-v1.0.30.apk` | Driver App | 1.0.30 |
| `jago-driver-final.apk` | Driver App | Latest Release |
| `jago-driver-2026-03-15.apk` | Driver App | 2026-03-15 Build |

#### Public APKs Directory (`/public/apks/`)
| File | Type | Version |
|------|------|---------|
| `jago-customer-v1.0.31.apk` | Customer App | 1.0.31 |
| `jago-customer-v1.0.30.apk` | Customer App | 1.0.30 |
| `jago-customer-v1.0.29.apk` | Customer App | 1.0.29 |
| `jago-customer.apk` | Customer App | Current |
| `jago-pilot-v1.0.31.apk` | Driver App | 1.0.31 |
| `jago-pilot-v1.0.30.apk` | Driver App | 1.0.30 |
| `jago-pilot-v1.0.29.apk` | Driver App | 1.0.29 |
| `jago-pilot.apk` | Driver App | Current |

#### Build Outputs (`/flutter_apps/{app}/build/app/outputs/`)
- `app-release.apk` (both customer & driver) - Latest gradle build outputs
- `app-release.apk.sha1` (both) - Integrity checksums

---

## 2. APP VERSIONS & BUILD NUMBERS

### ⚠️ **VERSION MISMATCH CRITICAL ISSUE**

| Metric | Customer App | Driver App | Status |
|--------|--------------|-----------|--------|
| **pubspec.yaml Version** | `1.0.55+55` | `1.0.57+57` | ✅ Latest |
| **build.gradle versionName** | `1.0.33` | `1.0.33` | ⚠️ **OUT OF SYNC** |
| **build.gradle versionCode** | `33` | `33` | ⚠️ **OUT OF SYNC** |
| **Recommended Version** | `1.0.55+55` | `1.0.57+57` | Action Needed |

**Issue Details:**
- `pubspec.yaml` has been updated to v1.0.55 (customer) and v1.0.57 (driver)
- `android/app/build.gradle` still references v1.0.33
- **Impact:** Published APKs may not reflect the latest code changes
- **Resolution:** Update `build.gradle` `versionCode` and `versionName` to match `pubspec.yaml`

### SDK Requirements
| Setting | Value |
|---------|-------|
| **Target SDK** | 36 (Android 15) |
| **Min SDK** | 24 (Android 7.0) |
| **Compile SDK** | 36 |
| **NDK Version** | 27.0.12077973 |
| **Java Version** | 17 |
| **Kotlin JVM Target** | 17 |
| **Flutter SDK** | >= 3.24.0 |
| **Dart SDK** | >= 3.0.0 <4.0.0 |

---

## 3. API ENDPOINT CONFIGURATION

### Base URL Configuration

Both apps use the same API configuration from `lib/config/api_config.dart`:

```dart
// Production server URL
static const String _prodUrl = 'https://oyster-app-9e9cd.ondigitalocean.app';

// LAN IP for local testing only
static const String _lanDevUrl = 'http://192.168.1.11:5000';

static bool _isProd = true; // PRODUCTION BUILD
```

**Current Configuration:** ✅ Production Mode

| Config | Value | Status |
|--------|-------|--------|
| **API Base URL** | `https://oyster-app-9e9cd.ondigitalocean.app` | ✅ Live |
| **Socket.IO URL** | Same as base URL | ✅ Configured |
| **Build Time Override** | `--dart-define=API_BASE_URL=...` | ✅ Supported |
| **Development Mode** | `http://192.168.1.11:5000` | 📝 For testing only |

### Authentication Endpoints

| Endpoint | Path | Status |
|----------|------|--------|
| **Send OTP** | `/api/app/send-otp` | ✅ |
| **Verify OTP** | `/api/app/verify-otp` | ✅ |
| **Firebase Auth** | `/api/app/verify-firebase-token` | ✅ |
| **Password Login** | `/api/app/login-password` | ✅ |
| **Logout** | `/api/app/logout` | ✅ |
| **Password Reset** | `/api/app/reset-password` | ✅ |
| **Firebase Reset** | `/api/app/reset-password-firebase` | ✅ |

### Real-Time Communication

**Socket.IO Integration:** ✅ Configured
- Client Library: `socket_io_client: ^2.0.3+1`
- Base URL: Same as API endpoint
- Events Supported:
  - Trip assignment & status
  - Driver location tracking
  - Real-time notifications
  - Chat messaging
  - WebRTC signaling for voice/video calls
  - Payment notifications

### Core Service Endpoints

**Customer App:**
- `GET /api/app/customer/profile` - User profile
- `GET /api/app/customer/home-data` - Home screen data
- `GET /api/app/nearby-drivers` - Driver discovery
- `GET /api/app/track/{tripId}` - Trip tracking

**Driver App:**
- `GET /api/app/driver/profile` - Driver profile
- `POST /api/app/driver/location` - Location updates
- `POST /api/app/driver/online-status` - Online/offline status
- `GET /api/app/driver/heatmap` - Activity heatmap

---

## 4. CRITICAL DEPENDENCIES

### Core Libraries

| Library | Version | Purpose |
|---------|---------|---------|
| **http** | ^1.2.0 | HTTP API calls |
| **socket_io_client** | ^2.0.3+1 | Real-time communication |
| **google_maps_flutter** | ^2.6.0 | Map integration |
| **geolocator** | ^13.0.0 | Location services |
| **firebase_core** | ^3.6.0 | Firebase integration |
| **firebase_auth** | ^5.3.0 | Authentication |
| **firebase_messaging** | ^15.1.3 | Push notifications |
| **razorpay_flutter** | ^1.3.6 | Payment processing |

### Specialized Features

| Feature | Library | Driver Only? |
|---------|---------|-------------|
| **Navigation** | google_maps_flutter | No (both) |
| **Camera** | camera: ^0.10.5+9 | ✅ Yes |
| **Voice/Video** | flutter_webrtc: ^0.12.11 | No (both) |
| **Speech to Text** | speech_to_text: ^7.3.0 | Customer only |
| **Text to Speech** | flutter_tts: ^4.0.2 | No (both) |
| **Payment** | razorpay_flutter: ^1.3.6 | No (both) |
| **Push Notifications** | firebase_messaging: ^15.1.3 | No (both) |
| **OTP Input** | pin_code_fields: ^8.0.1 | No (both) |

---

## 5. BUILD & SIGNING CONFIGURATION

### Application IDs
| App | Package Name | Status |
|-----|--------------|--------|
| **Customer** | `com.mindwhile.jago_customer` | ✅ Correct |
| **Driver** | `com.mindwhile.jago_pilot` | ✅ Correct |

### Code Signing

**Keystore Details:**
```
Location: flutter_apps/jago-release-key.jks
Key Alias: jago
Key Password: jago2024release
Store Password: jago2024release
Store File Path: ../../../jago-release-key.jks (relative to android/)
```

**Status:** ✅ Properly configured in `key.properties`

### Release Build Configuration

**Build Types:**
```gradle
release {
    signingConfig keystorePropertiesFile.exists() ? signingConfigs.release : signingConfigs.debug
    minifyEnabled true        // ProGuard obfuscation
    shrinkResources true      // Remove unused resources
    proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
}
```

**Status:** ✅ Production-ready

---

## 6. PERMISSIONS ANALYSIS

### Customer App Permissions

**Location Services:**
- `ACCESS_FINE_LOCATION` - GPS location
- `ACCESS_COARSE_LOCATION` - Approximate location
- `ACCESS_BACKGROUND_LOCATION` - Background tracking

**Hardware Access:**
- `CAMERA` - Photo/profile picture
- `RECORD_AUDIO` - Voice calls/messages
- `CALL_PHONE` - Direct calling

**System Permissions:**
- `INTERNET` - API connectivity
- `POST_NOTIFICATIONS` - Push notifications
- `VIBRATE` - Haptic feedback
- `FOREGROUND_SERVICE` - Background location service

**Status:** ✅ Appropriate for ride-sharing app

### Driver App Permissions

**Additional Permissions:**
- `FOREGROUND_SERVICE_LOCATION` - Explicit location service
- `USE_FULL_SCREEN_INTENT` - Full-screen notifications for ride requests
- `SYSTEM_ALERT_WINDOW` - System alerts
- `SCHEDULE_EXACT_ALARM` - Precise notification timing
- `WAKE_LOCK` - Prevent sleep during active trip

**Status:** ✅ Enhanced for driver requirements

---

## 7. BUILD CONFIGURATION ISSUES

### 🔴 **Critical Issues**

#### 1. Version Mismatch
**Severity:** HIGH  
**Description:** `pubspec.yaml` versions don't match `build.gradle` versions
- pubspec.yaml shows v1.0.55 (customer), v1.0.57 (driver)
- build.gradle shows v1.0.33 for both
- Published APKs may contain outdated version info

**Fix Required:**
```gradle
// In android/app/build.gradle
defaultConfig {
    versionCode 55        // Update from 33
    versionName "1.0.55"  // Update from 1.0.33 (customer)
}

// For driver app:
defaultConfig {
    versionCode 57        // Update from 33
    versionName "1.0.57"  // Update from 1.0.33
}
```

#### 2. Gradle Build Heap Dumps
**Severity:** MEDIUM  
**Description:** Heap memory dump files found in android directories
- `customer_app/android/build/java_pid*.hprof`
- `driver_app/android/build/hs_err_pid*.log`

**Issue:** Indicates past build failures due to memory issues

**Fix:** 
- Clean build outputs: `flutter clean`
- Increase gradle heap: Update `gradle.properties`
```properties
org.gradle.jvmargs=-Xmx2048m -XX:MaxMetaspaceSize=512m
```

### ⚠️ **Warnings**

#### Lint Configuration
Both apps have `checkReleaseBuilds false` and `abortOnError false`, which masks potential issues.

**Recommended Setting:**
```gradle
lint {
    abortOnError true
    checkReleaseBuilds true
    warningsSeverity = "error"  // Strict mode
}
```

---

## 8. RELEASE READINESS ASSESSMENT

### ✅ **Ready for Production**

| Aspect | Status | Details |
|--------|--------|---------|
| **API Endpoints** | ✅ | Correctly configured for DigitalOcean backend |
| **Firebase Integration** | ✅ | Auth, messaging, and crashlytics enabled |
| **Code Signing** | ✅ | Keystore properly configured |
| **Permissions** | ✅ | Appropriate and documented |
| **Dependencies** | ✅ | All latest stable versions |
| **Minification** | ✅ | ProGuard enabled for release builds |

### ⚠️ **Actions Required Before Release**

| Priority | Issue | Action |
|----------|-------|--------|
| 🔴 **CRITICAL** | Version mismatch | Update `build.gradle` versionCode/versionName |
| 🟡 **HIGH** | Heap dump files | Run `flutter clean` and rebuild |
| 🟡 **HIGH** | Lint configuration | Enable strict lint checking |
| 🟢 **MEDIUM** | No iOS build config found | Verify iOS support or document Android-only |

---

## 9. DEPLOYMENT COMMANDS

### Build Release APKs

**Customer App:**
```bash
cd flutter_apps/customer_app
flutter clean
flutter pub get
flutter build apk --release \
  --dart-define=API_BASE_URL=https://oyster-app-9e9cd.ondigitalocean.app
```

**Driver App:**
```bash
cd flutter_apps/driver_app
flutter clean
flutter pub get
flutter build apk --release \
  --dart-define=API_BASE_URL=https://oyster-app-9e9cd.ondigitalocean.app
```

### Build with Custom Signing

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://oyster-app-9e9cd.ondigitalocean.app \
  --signing-key=flutter_apps/jago-release-key.jks \
  --signing-key-password=jago2024release \
  --signing-key-alias=jago \
  --signing-key-alias-password=jago2024release
```

### Expected Output Locations
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/apk/release/app-release.apk`

---

## 10. APP STORE REQUIREMENTS

### Google Play Store Metadata

| Requirement | Customer App | Driver App | Status |
|-------------|--------------|-----------|--------|
| **Package Name** | com.mindwhile.jago_customer | com.mindwhile.jago_pilot | ✅ |
| **App Name** | JAGO Pro | JAGO Pro Pilot | ✅ |
| **Icon** | @mipmap/ic_launcher | @mipmap/ic_launcher | ✅ |
| **Min API Level** | 24 (Android 7.0) | 24 (Android 7.0) | ✅ |
| **Target API Level** | 36 (Android 15) | 36 (Android 15) | ✅ |
| **64-bit Support** | Required by NDK | Required by NDK | ✅ |
| **Privacy Policy URL** | Required | Required | ⚠️ Check manifest |
| **Permissions Justification** | Location, Camera | Location, Camera | ⚠️ Required for upload |

---

## 11. SUMMARY

### Current Status
- ✅ **APK files exist** in multiple locations with version history
- ✅ **API integration** properly configured for live backend
- ✅ **Firebase** fully integrated for auth and notifications
- ✅ **Socket.IO** configured for real-time features
- ✅ **Code signing** properly configured
- ⚠️ **Version mismatch** between pubspec.yaml and build.gradle
- ⚠️ **Build artifacts** indicate past memory issues (heap dumps)

### Immediate Actions (Before Release)
1. **Fix version mismatch** in `build.gradle` (HIGH PRIORITY)
2. **Clean build artifacts** with `flutter clean`
3. **Rebuild APKs** with correct version numbers
4. **Enable strict lint checking** for quality assurance
5. **Test against live API endpoint** https://oyster-app-9e9cd.ondigitalocean.app
6. **Verify all features** on real devices (API calls, location, socket connections)

### Deployment Pipeline
```
1. Fix versions in build.gradle
2. Run flutter clean
3. Build release APK for both apps
4. Sign APKs with jago-release-key.jks
5. Test on physical devices
6. Upload to Play Store pre-release
7. Conduct beta testing (48 hours minimum)
8. Monitor crashlytics for issues
9. Proceed with full release
```

**Estimated Time to Release:** 2-3 days (after version fixes)

