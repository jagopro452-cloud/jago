# JAGO Flutter Apps - Setup Guide
## MindWhile IT Solutions Pvt Ltd

---

## Apps Overview

| App | Package | Description |
|-----|---------|-------------|
| `driver_app/` | JAGO Pilot | Driver App |
| `customer_app/` | JAGO | Customer App |

---

## Prerequisites

1. Flutter SDK 3.0+ → https://docs.flutter.dev/get-started/install
2. Android Studio / VS Code with Flutter plugin
3. Google Maps API Key (see below)
4. Firebase project (optional for FCM notifications)

---

## Step 1: Google Maps API Key

1. Go to https://console.cloud.google.com
2. Create a project → Enable "Maps SDK for Android" and "Maps SDK for iOS"
3. Create an API key → Restrict to your app's package name
4. Replace `YOUR_GOOGLE_MAPS_API_KEY` in:
   - `driver_app/android/app/src/main/AndroidManifest.xml`
   - `customer_app/android/app/src/main/AndroidManifest.xml`
   - `driver_app/lib/config/api_config.dart` (googleMapsApiKey constant)
   - `customer_app/lib/config/api_config.dart` (googleMapsApiKey constant)

---

## Step 2: Production vs Development

In `lib/config/api_config.dart`:
- Production URL: `https://jagopro.org` (used by default)
- Dev URL: `http://10.0.2.2:5000` (for Android emulator)

To switch to dev mode, comment out `ApiConfig.useProduction()` in `main.dart`.

---

## Step 3: Driver App Setup

```bash
cd driver_app
flutter pub get
flutter run
```

### Driver App Screens:
- Splash → Login (OTP) → Home (Map + Online Toggle)
- Incoming Trip Sheet (Accept/Decline with 30s timer)
- Trip Flow: Go to Pickup → Arrived → Verify OTP → Complete
- Wallet (Balance + Transactions + Withdrawal request)
- Earnings (Today / Week / Month / All)
- Trip History
- Profile (Rating, Stats, Logout)

---

## Step 4: Customer App Setup

```bash
cd customer_app
flutter pub get
flutter run
```

### Customer App Screens:
- Splash → Login (OTP) → Home (Map + Search bar)
- Booking (Select destination on map → Choose vehicle → Payment → Book)
- Tracking (Live driver tracking + OTP display + Cancel)
- Rating Screen (Rate driver after completion)
- Wallet (Balance + Recharge)
- Trip History
- Saved Places (Home/Work/Other)
- Profile (Stats + Menu)

---

## Step 5: Build APK (Release)

```bash
# Driver App
cd driver_app
flutter build apk --release

# Customer App
cd customer_app
flutter build apk --release
```

APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

---

## API Integration

Both apps connect to the JAGO backend:
- Base URL: `https://jagopro.org/api/app/`
- Auth: Bearer token (stored locally after OTP login)
- OTP sent via SMS to driver/customer phone

### Driver App APIs Used:
- POST `/send-otp` - Send OTP
- POST `/verify-otp` - Login
- GET `/driver/profile` - Profile
- PATCH `/driver/online-status` - Go Online/Offline
- POST `/driver/location` - Update GPS location (every 5s)
- GET `/driver/incoming-trip` - Poll for new trips (every 5s)
- POST `/driver/accept-trip` - Accept trip
- POST `/driver/arrived` - Mark arrived at pickup
- POST `/driver/verify-pickup-otp` - Verify customer OTP
- POST `/driver/complete-trip` - Complete trip
- GET `/driver/wallet` - Wallet balance + history
- GET `/driver/earnings?period=today` - Earnings stats

### Customer App APIs Used:
- POST `/send-otp` - Send OTP
- POST `/verify-otp` - Login
- GET `/customer/profile` - Profile
- POST `/customer/estimate-fare` - Get fare estimates
- POST `/customer/book-ride` - Book a ride
- GET `/customer/active-trip` - Check for active trip
- GET `/customer/track-trip/:id` - Track driver location
- POST `/customer/cancel-trip` - Cancel trip
- POST `/customer/rate-driver` - Rate driver
- GET `/customer/wallet` - Wallet balance
- POST `/customer/wallet/recharge` - Add money
- GET/POST/DELETE `/customer/saved-places` - Manage saved places
- POST `/customer/apply-coupon` - Apply discount coupon

---

## Contact

- Email: info@jagopro.org
- Website: https://jagopro.org
- Company: MindWhile IT Solutions Pvt Ltd
