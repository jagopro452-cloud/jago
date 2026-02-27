# JAGO Logistics & Mobility Platform

## Overview
JAGO, a product of Mindwhile IT Solutions Pvt Ltd, is a comprehensive Laravel 12 (PHP 8.2) based logistics and mobility platform for parcel delivery and ride-sharing. It offers a full suite of management functionalities, including an admin panel and landing page, leveraging modern web and mobile technologies. The project aims to become a leading urban mobility and logistics provider, offering efficient and user-friendly services.

## User Preferences
- Prefer iterative development with clear communication before major changes.
- Laravel PHP for backend/web. Flutter for mobile apps (source code only - build locally).
- Drivers are called "Pilots" in JAGO branding.
- Pilot app: Android only. User app: Android + iOS.
- JAGO brand colors: Primary #2563EB, Dark #1E3A8A, Scaffold #1D4ED8, Accents #93C5FD, #BFDBFE, #EFF6FF
- No web preview / web app simulation.

## System Architecture
The JAGO platform is built on Laravel 12.49.0 with PHP 8.2 and PostgreSQL, including PostGIS for spatial queries, optimized for Replit. A Python proxy server handles requests, managing PHP session cookies and serving static assets. The architecture is modular, comprising 16 distinct modules (User, Fare, Zone, Vehicle, Promotion, Business, Auth, Parcel, Trip, Chatting, Review, Gateways, Transaction, Blog, AI).

**Key Architectural & Design Decisions:**
- **Server Architecture:** Python proxy (port 5000) forwards to Laravel (port 8080), handling session management and static file serving.
- **Branding & UI/UX:** Consistent use of "JAGO" and "Pilot" with a specific blue color palette and Google Fonts Poppins. The Admin Panel features an "Ultra-premium v4.0 redesign" with extensive CSS customization for buttons, cards, tables, forms, and full dark mode support. Flutter apps (User + Pilot) feature "Rapido/Ola-level premium UI" with glassmorphism, gradient elements, enhanced themes, and JAGO branding.
- **Performance:** Production-optimized with database-backed sessions/cache/queues, PHP OPcache JIT, zlib compression, Python proxy with connection pooling, gzip compression, LRU static file cache, and 228 database indexes.
- **Transaction Safety:** All wallet operations use `lockForUpdate()` to prevent race conditions.
- **Automated Backups:** Daily database backup with compression and 7-day retention.
- **Payment Logic:** Robust algorithms for coupon application, VAT/commission precedence, and transaction integrity.
- **Interactive Maps:** Leaflet.js with CartoDB tiles, custom markers, and deterministic Bezier route lines across 7 screens.
- **Pilot Management:** Negative balance auto-lock and a commission-based subscription model.
- **In-App Calling:** WebRTC-based system with number masking and database-polling signaling.
- **Spin Wheel:** Post-ride reward system with weighted probability, earning caps, and admin configuration.
- **Dual Car Sharing (City + Outstation):** Direction-aware route matching, OTP verification, seat recycling, configurable shared discount per zone. Dual-type system (city intracity + outstation intercity) with auto-detection based on configurable distance threshold (default 30km). Per-type commission rates, GST rates, max detour distances. Sharing fare profiles (zone+vehicle+type-specific pricing). Festival offers with scheduling, usage limits, 3 discount types (percentage/flat/per-seat), atomic usage counting with lockForUpdate. Admin CRUD for festival offers and fare profiles. Flutter User App: type selection screen with glassmorphism, offer banners with countdown timers. Flutter Pilot App: sharing type badges on ride cards.
- **Spatial Data Handling:** PostGIS geometry(Polygon) type for zones.
- **Driver Overcharge Protection:** Customer reporting API with auto-block thresholds.
- **Notification Sounds:** Differentiated notification sounds for parcel and passenger requests.
- **Vehicle-to-Driver Routing:** Advanced driver matching filters by vehicle category, service type, and pilot status.
- **Ride Continuity:** Automatic driver availability updates and ride resume status endpoint.
- **Mutually Exclusive Earning Models:** Admin configurable commission or subscription model for ride pilots, with separate commission for parcel.
- **Parcel Delivery Enhancements:** Time-based pricing and receiver OTP verification.
- **Corporate & B2B Plans:** Support for corporate accounts with plan tiers, employee linking, and credit limits.
- **Service Type Separation (Car/Bike/Auto/Parcel):** Three distinct vehicle category types (car, motor_bike, auto) with independent fare setup per type. Admin trip list filterable by service type. Fare setup view groups categories by type with color-coded badges. API responses include service_type and vehicle_category_name for Flutter app differentiation.
- **Service Toggles:** Admin can globally enable/disable car sharing and auto helper services.
- **Special Discount Programs:** Senior citizen and student discounts, prioritized over corporate discounts.
- **Outstation Service:** Configurable minimum distance threshold and fare multiplier.
- **Fare Calculation Integration:** Discounts and outstation multipliers systematically applied.
- **Intelligent Ride Dispatch Cascade:** Scheduled command (`ride:dispatch-cascade`) to progressively expand search radius and dispatch notifications.
- **Pickup Charge & Waiting Fee System:** Configurable pickup charge, waiting fee, driver arrival tracking, and distance-based cancellation logic.
- **Security Hardening:** Tightened CORS, session security, CSRF protection, API rate limiting, and security headers.
- **Production Resilience:** PHP watchdog, graceful proxy server handling, capped session memory, request retry with backoff, and comprehensive API exception handling.
- **Vendor Tracker Removal:** All vendor-specific trackers and branding removed, updated to JAGO/Mindwhile IT Solutions.
- **Legal Compliance:** India-specific About Us, Privacy Policy, Terms & Conditions.
- **Flutter App Optimization:** Memory leak prevention, optimized image loading, notification deduplication, and production timeout config.
- **Indian Localization:** Hindi (हिन्दी) and Telugu (తెలుగు) language support in User and Driver apps.
- **GST Invoice UI:** User app screen to view GST tax invoices with itemized amounts and CGST/SGST breakdown.
- **Overcharge Reporting UI:** User app screen for customers to report driver overcharges.
- **Driver Performance Integration:** Driver app leaderboard displaying performance tiers based on a composite score.
- **Live Speedometer:** Real-time GPS speed display on Driver app map screen with color-coded indicators.
- **Real-Time Movement Optimization:** Smooth marker animation with interpolation on both user and driver apps, optimized location polling and bearing transitions.
- **Automated Fraud Detection:** GPS spoofing, repeated route, fare anomaly, short trip abuse, and rapid consecutive trip detection.
- **GST Invoice Generation:** Indian GST-compliant invoices with HSN/SAC codes and CGST/SGST split.
- **Ride Analytics API:** Overview, peak hours, popular routes, revenue trends, and cancellation analysis with zone filtering and date ranges.
- **Smart ETA Calculation:** Haversine distance with road multiplier, historical speed data, and time-of-day awareness.

## Recent Changes
- **2026-02-17:** Subscription model activated with GST integration. earning_model set to 'subscription', platform_fee_amount=₹20 per ride. Subscription purchase API deducts plan price + GST (18%) from wallet with lockForUpdate atomicity. Plans API returns GST breakdown. Three default plans seeded: Daily ₹49 (15 rides), Weekly ₹299 (100 rides), Monthly ₹999 (unlimited). Admin subscription page shows current earning model badge, per-ride fee breakdown, plan prices with GST, activate/deactivate toggle per plan. Trip list and details pages show "Admin Share" column with platform fee amount. Admin can toggle between commission and subscription models in Business Settings with immediate cache update. Per-ride platform fee (₹20 + GST) deducted from pilot wallet via DriverWalletService into negative balance if needed.
- **2026-02-17:** Rapido-style negative balance auto-lock/unlock system. DriverWalletService with deductPlatformFee (DB transaction + lockForUpdate atomicity), rechargeWallet, checkAndAutoLock, checkAndAutoUnlock, adminManualUnlock, getWalletStatus (warning threshold at 80%). Auto-lock triggers when wallet_balance < -negative_balance_limit (default ₹200). Auto-unlock on wallet recharge and admin cash collect. Push notifications for lock/unlock events. Driver API: GET wallet-status, POST wallet-recharge endpoints. Admin panel: unlock button in driver details for negative-balance-locked pilots, red ₹ badge in driver list. DriverResource transformer includes is_negative_balance_locked, wallet_balance, negative_balance_limit. Config API returns negative_balance_limit for Flutter apps.
- **2026-02-17:** Production-readiness hardening pass. Critical bug fixes: (1) `coordiante` typo fixed in TripRequestController + TripRequestService causing crash on intermediate coordinate routing, (2) `$response()` → `response()` fix in cancellation error handler preventing stuck rides, (3) PaymentController wrapped in try/catch with DB::rollBack() for transaction safety - notifications moved post-commit, (4) sendDeviceNotification now guards against null FCM tokens while still saving in-app notifications, (5) businessConfig null safety added across controllers. Data seeding: 3 withdraw methods (Bank Transfer/UPI/PayTM), 6 safety precautions, 10 safety alert reasons, 2 notification templates (driver_arrived/trip_accepted), 3 RBAC roles (Admin Manager/Operations Manager/Finance Manager).
- **2026-02-17:** Porter-style vehicle selection for parcel service (full stack). Backend: Added vehicle_category_id to parcel_fares table enabling per-vehicle-type fare rates per zone. New vehicle categories: Tata Ace, Mini Truck, Pickup Truck (alongside existing Parcel Bike, Parcel Auto). Admin parcel fare page now requires selecting vehicle type before setting fares. New API endpoint `GET /api/customer/parcel/vehicle-types?zone_id=X` returns available vehicles with fares. Trip fare calculation supports vehicle_category_id for parcel bookings. Flutter User App: New Porter-style vehicle selection screen (VehicleTypeSelectionWidget) with animated cards, fare display, check-circle selection. New ParcelVehicleType model + repository/service/controller layer. Parcel booking flow updated: info → fare → vehicle selection → finding rider. Flutter Pilot App: Trip card now shows specific vehicle category name (e.g. "Tata Ace") instead of generic "Parcel" label for parcel rides.
- **2026-02-17:** Full application audit completed. Fixed notification system (re-seeded 82 firebase_push_notifications with correct types). Fixed HasUuid trait bug. Fixed vehicle documents null safety. Added NotificationRepairSeeder. Blog settings data added. Dynamic_values populated for all notifications. Service type separation (Car/Bike/Auto) completed with API updates.

## Application Audit Status

### Working Features (Backend + Admin Panel)
- User/Driver registration, login, authentication (JWT + session)
- Admin dashboard with role-based access control
- Ride booking flow (create, accept, start, complete, cancel)
- Parcel booking flow with OTP verification
- Fare management (trip fares + parcel fares per zone)
- Vehicle category management (Car, Bike, Auto types)
- Driver approval and verification workflow
- Wallet system with lockForUpdate() for concurrency
- Commission calculation (ride + parcel)
- Coupon/discount system
- Chat messaging system
- Review/rating system
- Cancellation logic with reasons
- Refund management
- Safety alerts
- Blog management
- Corporate B2B plans
- Car sharing (city + outstation)
- Festival offers with atomic usage counting
- Notification system (5 types: regular trip, scheduled trip, parcel, driver registration, others)
- WebRTC calling with number masking
- Ride analytics API
- Fraud detection system
- GST invoice generation
- Spin wheel rewards
- Send push notifications to users

### Requires External Setup (User Must Configure)
- **Firebase:** Server key + FCM config needed for push notifications to mobile apps
- **Payment Gateways:** API keys needed (Razorpay, PayPal, Stripe, etc.) via Admin > Business Settings
- **Google Maps API:** API key for geocoding, directions, places autocomplete
- **SMS Gateway:** Twilio/MSG91 config for OTP and SMS notifications
- **Flutter Apps:** Must update `baseUrl` in `AppConstants.dart` to production domain, then build locally with Flutter SDK

### Flutter App Feature Coverage (804 Dart files)
**User App:** Auth, ride booking, parcel booking, car sharing, payment, wallet, chat, notifications, referral, coupons, spin wheel, safety, profile, trip history, refund requests, address management, GST invoices, overcharge reporting, live tracking, multi-language (EN/HI/TE)
**Pilot App:** Auth, ride management, parcel delivery, chat, earnings, wallet, face verification, help & support, leaderboard, speedometer, notifications, multi-language

## External Dependencies
- **Database:** PostgreSQL with PostGIS
- **Framework:** Laravel 12 (PHP 8.2)
- **Proxy:** Python 3
- **Mobile Apps:** Flutter (build locally)
- **Mapping Library:** Leaflet.js with CartoDB tiles
- **Firebase:** Required for push notifications (configure via Admin Panel)
- **Payment Gateways:** Razorpay/Stripe/PayPal (configure API keys via Admin Panel)
- **Maps API:** Google Maps (configure API key via Admin Panel)