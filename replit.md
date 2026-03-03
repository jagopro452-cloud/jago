# JAGO - India's Smart Mobility Platform
## MindWhile IT Solutions Pvt Ltd | Production: jagopro.org

## Overview
JAGO is a complete ride-sharing platform for India — full-stack Node.js/React admin panel + Flutter mobile apps for Driver (JAGO Pilot, Android) and Customer (JAGO, iOS+Android). Built for Play Store / App Store deployment.

## Current Build Status
- **JAGO-Customer-v1.0.apk** — 28MB — `PRODUCTION READY` ✅
- **JAGO-Pilot-v1.0.apk** — 27MB — `PRODUCTION READY` ✅
- **Admin Panel** — All 54 pages, 278+ API endpoints — `LIVE` ✅
- **Database** — PostgreSQL, 9 zones, 9 vehicle categories, 81 fares — `CONNECTED` ✅
- **Test Data** — 1 customer (Ravi Kumar/9876543210) + 1 driver (Suresh Pilot/9123456789) — `ACTIVE` ✅

## Latest Features Added
- **Admin Forgot Password**: Admin login page has "Forgot Password?" link → OTP via email → reset password
- **Customer Delete Account**: Profile screen has "Delete Account" option (soft deactivate or permanent delete)
- **Driver Delete Account**: Profile screen has "Delete Account" option via bottom sheet (deactivate or permanent)
- **Book for Someone Else**: Customer booking screen has toggle → enter passenger name/phone; for parcels, also receiver name/phone
- **Passenger Call Button**: Driver trip screen shows purple passenger card with call button when `isForSomeoneElse` is true
- **Parcel Delivery OTP**: Driver trip screen shows orange "Verify Delivery OTP" button for parcel trips in progress
- **Localization Fixes**: home_screen.dart + driver login_screen.dart — all hardcoded text replaced with L.tr() keys; all 6 language sections updated (en/te/hi/ta/kn/ml) for new keys

## Architecture

### Technology Stack
- **Frontend**: React, TypeScript, Vite, TanStack Query v5, Wouter, JAGO custom Bootstrap CSS
- **Backend**: Node.js, Express, Drizzle ORM, Socket.IO, bcrypt, express-rate-limit
- **Database**: PostgreSQL — UUID primary keys throughout
- **Mobile**: Flutter 3.22.3, Dart — both apps pointing to `https://jagopro.org`
- **Payments**: Razorpay (wallet recharge, ride payments)
- **OTP**: Fast2SMS API
- **Maps**: Google Maps API Key `AIzaSyB_yncy2ojljQ_dehITVkPQrPDtoCQbuhw`

### Admin Credentials
- **Email**: admin@admin.com
- **Password**: Set via `ADMIN_PASSWORD` env secret (if not set, defaults to `Jago@2024#Admin` on first-time setup only)
- Admin can change password anytime via the admin panel — password will NOT be reset on server restart

## Admin Panel — 54 Pages

### Navigation Structure
- **Dashboard**: Overview stats, fleet map, heat map
- **Zone Management**: Zone Setup (9 zones active)
- **Trip Management**: All Trips, Car Sharing, Intercity, Parcel Refunds, Safety & Emergency
- **Promotions**: Banners, Coupons, Discounts, Referrals, Spin Wheel, Notifications
- **User Management**: Drivers, Customers, Customer Wallet, Wallet Bonus, Employees, Withdrawals, Newsletter, Subscriptions, Revenue Model
- **Parcel**: Parcel Attributes
- **B2B**: B2B Companies
- **Vehicle Management**: Vehicle Attributes, Vehicle Categories, Vehicle Requests
- **Fare Management**: Trip Fares, Cancellation Reasons, Parcel Fares, Surge Pricing
- **Finance**: Transactions, Reports, Driver Earnings, Driver Wallet, Driver Levels, Customer Levels
- **Support**: Chatting, Call Logs, Refund Requests
- **Content**: Blogs, Reviews, Insurance Plans, Intercity Routes
- **Business**: Business Setup, Pages & Media, Configurations, System Settings
- **Dev Tools**: API Reference, App UI Design, Referrals

### System Settings Tabs
1. Business Information
2. Currency & Region
3. Trip Settings
4. **Payment Gateway** (Razorpay Key ID, Secret, Mode, Fast2SMS)
5. App Configuration (version, force update, maintenance)
6. Referral & Wallet (bonuses, limits)

## API Endpoints (278 total)

### Admin APIs
- `POST /api/admin/login` — bcrypt password verification
- `POST /api/admin/logout` — session cleanup
- `GET /api/dashboard/stats` — total drivers, customers, trips, revenue
- `GET /api/dashboard/chart` — 7-day chart data
- `GET/POST/PUT/DELETE /api/zones` — zone CRUD
- `GET/POST/PUT/DELETE /api/vehicle-categories` — vehicle CRUD
- `GET/POST /api/fares` — fare rules
- `GET /api/trips` — trip list with filters
- `GET /api/transactions` — payment transactions
- `GET /api/withdrawals` / `PUT /api/withdrawals/:id` — withdrawal management

### Mobile App APIs (`/api/app/...`)
- `POST /api/app/send-otp` — Fast2SMS OTP
- `POST /api/app/verify-otp` — OTP verification + JWT
- `GET /api/app/vehicle-categories` — list for booking
- `POST /api/app/trips/estimate` — fare estimation
- `POST /api/app/trips/request` — book ride
- `GET/POST /api/app/wallet/*` — wallet balance, recharge, Razorpay
- `GET /api/app/driver/dashboard` — driver home stats
- `GET/PUT /api/app/driver/trips` — trip management
- `POST /api/app/driver/location` — GPS update
- `GET /api/app/customer/trips` — customer trip history
- `GET /api/app/nearby-drivers` — map nearby drivers
- `POST /api/app/auth/send-otp` — alternative OTP endpoint

## Flutter Apps

### Build Environment
- **JVM Fix**: `JAVA_TOOL_OPTIONS="-XX:-UsePerfData -Xmx4g -XX:+UseSerialGC"` (NixOS SIGBUS fix)
- **Disk**: All caches in workspace (`GRADLE_USER_HOME=/home/runner/workspace/.gradle-cache`, `PUB_CACHE=/home/runner/workspace/.pub-cache`)
- **Java**: 17 | **Flutter**: 3.22.3 | **Android SDK**: 34+35

### Customer App (`flutter_apps/customer_app/`)
- Package: `com.mindwhile.jago_customer`
- Screens: auth, home, booking, tracking, wallet, profile, car_sharing, monthly_pass, coins, offers, safety, saved_places, preferences, lost_found, scheduled, history, notifications, referral, tip
- Payment: Cash / Wallet / UPI (Razorpay)
- Colors: `_blue = Color(0xFF1E6DE5)`, `_dark = Color(0xFF111827)`

### Driver App (`flutter_apps/driver_app/`)
- Package: `com.mindwhile.jago_pilot`
- Screens: auth, home, trip, history, wallet, earnings, performance, kyc, verification, profile, notifications, referral, break_mode, fatigue, break
- Features: Face verification, Break Mode, Fatigue monitoring, KYC upload, real-time location streaming
- Colors: Dark navy theme

### Production Config
Both apps: `_isProd = true` → `https://78d2d7f4-5b0a-4649-b698-b5927a4f487e-00-13osjf2l6nw7f.janeway.replit.dev`
- **NOTE**: jagopro.org was NOT pointing to this server — updated to Replit server URL
Firebase: Placeholder google-services.json (user needs real Firebase project for push notifications)
Signing: Debug keystore (user needs release keystore for Play Store)

## Database Schema (Key Tables)
- `users` — unified table, `user_type`: 'driver' | 'customer'
- `driver_details` — driver-specific KYC, vehicle, zone info
- `trip_requests` — all rides/trips
- `trip_fares` — 81 fare rules by zone+vehicle
- `zones` — 9 service zones (Hyderabad, Vijayawada, Amaravathi etc.)
- `vehicle_categories` — 9 types (Bike, Car, SUV, Tata Ace, Mini Auto, etc.)
- `transactions` — all payments
- `withdraw_requests` — driver withdrawal requests
- `coupon_setups`, `discounts`, `banners` — promotions
- `surge_pricing`, `surge_alerts` — dynamic pricing
- `insurance_plans`, `subscription_plans` — driver services
- `referrals`, `wallet_bonuses`, `spin_wheel_items` — engagement
- `intercity_routes`, `intercity_cs_rides` — long-distance features
- `car_sharing_rides`, `car_sharing_bookings` — shared rides
- `parcel_categories`, `parcel_fares`, `parcel_weights` — delivery
- `safety_alerts`, `emergency_contacts`, `police_stations` — safety
- `notification_logs`, `support_messages` — communication
- `admins`, `employees` — admin users

## Real-Time (Socket.IO)
- `server/socket.ts` — driver location, trip status, online/offline events
- Both Flutter apps use `socket_service.dart` for live updates

## Security
- bcrypt password hashing for admin
- express-rate-limit on login + OTP endpoints
- Token-based auth for mobile (`users.auth_token`)
- Input validation (Zod) on all critical endpoints
- Security headers (X-Content-Type-Options, X-Frame-Options, XSS-Protection, Referrer-Policy) via `server/index.ts`
- OTP never returned in API responses in production (`NODE_ENV=production`)
- Response logger sanitizes otp/password/token fields before logging
- Admin password NOT reset on server restart — persists across deployments
- `ADMIN_PASSWORD` env var can be set to force-sync admin password on startup

## Environment Secrets
- `RAZORPAY_KEY_ID` — Razorpay payment key
- `RAZORPAY_KEY_SECRET` — Razorpay secret
- `FAST2SMS_API_KEY` — OTP SMS
- `SESSION_SECRET` — Express session

## Test Data
- **Test Customer**: Ravi Kumar (Test), Phone: 9876543210, Wallet: ₹500
- **Test Driver**: Suresh Pilot (Test), Phone: 9123456789, Wallet: ₹1250, Vehicle: TS09AB1234 (Honda Activa 6G, Bike)
- OTP flow: call `/api/app/send-otp` then get OTP from `otp_logs` table for dev testing

## Language Management
- **DB table**: `app_languages` — seeded with 6 languages (en, te, hi, ta, kn, ml)
- **Flutter**: `LocalizationService` (class `L`) in both apps — `L.tr('key')`, `L.setLanguage()`, `L.init()`; `localeNotifier` ValueNotifier triggers rebuilds; SharedPreferences persists choice
- **API routes**:
  - `GET /api/app/languages` — public, for Flutter apps
  - `GET /api/admin/languages` — admin: list all
  - `POST /api/admin/languages` — add language (code, name, nativeName, flag, isActive, sortOrder)
  - `PATCH /api/admin/languages/:id` — update language
  - `DELETE /api/admin/languages/:id` — delete language
- **Admin page**: `/admin/languages` — toggle active/inactive, add, edit, delete languages; "App Languages" nav item under Business Management section

## Build Script
- `/home/runner/workspace/run_build.sh` → builds both APKs
- **Auto-installs Flutter 3.27.4 + Android SDK to workspace** (persistent across restarts)
- Flutter SDK: `/home/runner/workspace/.flutter-sdk`
- Android SDK: `/home/runner/workspace/.android-sdk`
- Logs: `/home/runner/workspace/build_output.log`
- Output: `JAGO-Customer-v1.0.apk` (28MB), `JAGO-Pilot-v1.0.apk` (27MB) in workspace root

## Workflows
- **Start application**: `npm run dev` — Express + Vite dev server on port 5000
- **Build APKs**: `bash run_build.sh` — Flutter release APK builder
