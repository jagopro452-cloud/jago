# JAGO - India's Smart Mobility Platform

## Overview
JAGO is a full-stack ride-sharing admin dashboard (like Uber/Rapido for India) rebuilt from a PHP/Laravel backup as a Node.js/React application. It includes a public landing page and a comprehensive admin panel with JAGO-original design system.

## Tech Stack
- **Frontend**: React + TypeScript + Vite, TanStack Query v5, Wouter routing, custom JAGO CSS design system
- **Backend**: Node.js + Express, Drizzle ORM
- **Database**: PostgreSQL (Replit-provisioned)
- **Icons**: Bootstrap Icons (CDN) — bi-* classes, loaded in index.html
- **Font**: Open Sans (Google Fonts)

## Design System (JAGO Original — exact class names from backup)
All admin panel styling uses the ORIGINAL JAGO CSS class names from `attached_assets/JAGO_Backup/public/assets/admin-module/css/style.css`, implemented in `client/src/index.css`:
- CSS Variables: `--bs-primary: #2563EB` (blue), `--bs-body-bg: #F1F5F9`, Open Sans font
- **Logo**: `/jago-logo.png` — actual JAGO brand logo PNG (copied from backup: `public/assets/admin-module/img/logo.png`)
- **Favicon**: `/favicon.png` — actual JAGO favicon (copied from backup)
- Layout classes (matching original blade templates exactly):
  - `.aside` — white sidebar (background #fff), 270px wide (HTML: `<aside class="aside">`)
  - `.aside-header` — sidebar header with logo + toggle button
  - `.aside-body` — scrollable sidebar body
  - `.user-profile` — blue (#2563EB) user profile box in sidebar
  - `.main-nav` — sidebar navigation list (`<ul class="main-nav nav">`)
  - `.nav-category` — navigation section headings
  - `.toggle-menu-button` — sidebar collapse button
  - `.header` — white sticky header, 60px (`<header class="header fixed-top">`)
  - `.main-area` — main content area (`<main class="main-area">`)
  - `.main-content` — inner content padding
- Component classes:
  - `.jago-stat-card` — dashboard stat cards
  - `.jago-card` / `.jago-card-header` — content cards
  - `.jago-table` — data tables with header uppercase styling
  - `.jago-badge` — status badges (badge-completed, badge-ongoing, badge-pending, badge-cancelled, badge-active, badge-inactive, badge-primary)
  - `.btn-jago-primary` / `.btn-jago-outline` / `.btn-jago-danger` / `.btn-jago-sm` — buttons
  - `.jago-input` / `.jago-label` — form inputs
  - `.jago-page-header` — page title + breadcrumb row
- Body folded: `body.aside-folded` collapses sidebar to 70px icon-only view

## Features

### Public Landing Page (`/`)
- Hero section with animated background
- Services section (Bike, Auto, Car, Parcel)
- How It Works (3-step flow)
- Features grid (Tracking, Safety, Speed, Ratings)
- CTA section + footer

### Admin Panel (`/admin/`)
Authentication: Demo mode — any credentials accepted. Stored in localStorage.

#### 14 Admin Pages (all styled with JAGO CSS):
1. **Dashboard** (`/admin/dashboard`) — Stats grid (8 cards) + recent trips table
2. **Trip Requests** (`/admin/trips`) — Paginated trip list with status filter + actions
3. **Customers** (`/admin/customers`) — Customer management with block/unblock
4. **Drivers** (`/admin/drivers`) — Driver partner management
5. **Vehicle Categories** (`/admin/vehicles`) — CRUD for vehicle types (Bike/Auto/Car/SUV)
6. **Zones** (`/admin/zones`) — Service zone management with modal CRUD
7. **Fare Management** (`/admin/fares`) — Pricing rules per zone/vehicle
8. **Transactions** (`/admin/transactions`) — Financial transaction log
9. **Coupons** (`/admin/coupons`) — Coupon code CRUD with discount types
10. **Reviews** (`/admin/reviews`) — Customer/driver review viewer with star rating
11. **Blogs** (`/admin/blogs`) — Article management with card grid
12. **Withdrawals** (`/admin/withdrawals`) — Driver withdrawal request approvals
13. **Cancellation Reasons** (`/admin/cancellation-reasons`) — Per user-type cancel reasons
14. **Settings** (`/admin/settings`) — Business/Currency/Trip settings

## Database Schema
Tables: users, trips, vehicle_categories, zones, trip_fares, coupons, reviews, blogs, business_settings, cancellation_reasons, transactions, withdrawal_requests, admins, parcel_attributes
- users table has driver verification fields: verification_status, license_number, license_image, vehicle_image, vehicle_number, vehicle_model, rejection_note
- parcel_attributes: id, type (category/weight/size), name, icon, min_value, max_value, unit, extra_fare, is_active, created_at
- File uploads stored in public/uploads/ — served at /uploads/:filename

## API Routes
- `GET /api/dashboard/stats` — Dashboard statistics
- `GET/POST /api/trips` — Trips CRUD + pagination + status filter
- `PATCH /api/trips/:id/status` — Update trip status
- `GET/POST /api/users` — Users list (filter by userType: customer|driver)
- `PATCH /api/users/:id/status` — Block/unblock user
- `PATCH /api/users/:id` (via updateUser) — Update arbitrary user fields
- `PATCH /api/drivers/:id/verify` — Approve/reject driver ({status, note})
- `PATCH /api/drivers/:id/documents` — Update driver docs ({licenseImage, vehicleImage, profileImage, licenseNumber, vehicleNumber, vehicleModel})
- `POST /api/upload` — Multer file upload → saves to public/uploads/, returns {url}
- `GET/POST/PUT/DELETE /api/parcel-attributes` — Parcel attribute CRUD (type: category|weight|size)
- `GET/POST/PUT/DELETE /api/vehicle-categories` — Vehicle categories CRUD
- `GET/POST/PUT/DELETE /api/zones` — Zones CRUD
- `GET/POST /api/fares` — Fare rules
- `GET /api/transactions` — Transaction history
- `GET/POST/PUT/DELETE /api/coupons` — Coupon management
- `GET /api/reviews` — Reviews list
- `GET/POST/PUT/DELETE /api/blogs` — Blog articles
- `GET/PATCH /api/withdrawals` — Withdrawal requests
- `GET/POST/DELETE /api/cancellation-reasons` — Cancel reasons
- `GET/POST /api/settings` — Business settings

## Security
- Login: bcrypt password verification (bcryptjs) + express-rate-limit (10 attempts/15min per IP)
- Security headers: X-Content-Type-Options, X-Frame-Options, X-XSS-Protection, Referrer-Policy
- Admin credentials: admin@admin.com / admin123 (bcrypt hashed in DB)
- Admin password change: POST /api/admin/change-password

## New Features (Feb 2026)
- **Fare Calculator** (`/admin/fares` page bottom): Admin tool to test fare calculations — select zone + vehicle + distance + duration → shows breakdown (base fare, per km, GST, total)
- **Driver Earnings Statement** (`/admin/driver-earnings`): Per-driver earnings with gross, commission (15%), GST (5%), net payout. Monthly drill-down modal per driver
- **Referral Management** (`/admin/referrals`): Full referral CRUD with stats, status filters (pending/paid/expired), Pay button for pending referrals
- **Notifications History** (`/admin/notifications`): Sends now persist to `notification_logs` table, history shown in right panel with recipient count and time
- **Safety & Emergency** (`/admin/safety-alerts`): SOS alerts management, police stations CRUD, female-to-female matching algorithm settings

## New DB Tables (created via executeSql)
- `referrals`: referrer_id, referred_id, referral_code, referral_type, reward_amount, status
- `notification_logs`: title, message, target, user_type, recipient_count, status, sent_at
- `safety_alerts`: Full SOS alert tracking with GPS, status workflow (active→acknowledged→resolved)
- `police_stations`: Name, address, phone, GPS coordinates

## New API Routes
- `POST /api/fare-calculator` — Calculate trip fare with breakdown
- `GET /api/driver-earnings` — All driver earnings summary
- `GET /api/driver-earnings/:id` — Individual driver monthly breakdown
- `GET /api/referrals/stats` — Referral statistics
- `GET /api/referrals` — List referrals with filters
- `PATCH /api/referrals/:id/pay` — Mark referral as paid
- `PATCH /api/referrals/:id/expire` — Mark referral as expired
- `GET /api/notifications` — Notification history (from notification_logs)

## Seeded Data
- 5 Indian customers (Ravi Kumar, Priya Sharma, Arjun Reddy, Meera Nair, Suresh Babu)
- 5 drivers
- 7 trips across Hyderabad (completed, ongoing, cancelled, pending)
- 6 zones (Hyderabad Central, Hitec City, Gachibowli, Secunderabad, Test Zone HYD, Hyderabad South Zone)
- 9 vehicle categories (Bike, Auto, Car, SUV, Parcel Bike, Temo, Tata Ace, Cargo, Mini Cargo)
- 25 trip fares seeded (5 vehicle categories × 5 zones with realistic ₹ rates)
- 4 insurance plans: Basic Shield, Standard Guard, Premium Protect, Driver Health
- 10 referrals seeded (6 paid, 3 pending, 1 expired — customers and drivers)
- 6 notification_log entries seeded
- 6 SOS alerts, 6 Hyderabad police stations
- Business pages content: About Us, Privacy Policy, Terms & Conditions, Refund Policy (settings_type=pages_settings)
- Social media links (settings_type=social_settings), Landing page settings (settings_type=landing_settings)
- Coupons, reviews, blogs, subscription plans, intercity routes

## Architecture Notes
- `shared/schema.ts`: Drizzle schema with UUID primary keys (varchar with gen_random_uuid())
- `server/storage.ts`: DatabaseStorage class handles all CRUD
- `server/routes.ts`: Thin Express routes using storage interface
- `client/index.html`: Bootstrap Icons CDN only (no Bootstrap CSS — conflicts with Tailwind)
- `client/src/index.css`: Full JAGO design system with CSS custom properties
- Tables created via executeSql (db:push has interactive prompt issue in Replit)
- No Shadcn/Tailwind classes in admin pages — pure JAGO CSS for authentic look
