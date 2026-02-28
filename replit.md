# JAGO - India's Smart Mobility Platform

## Overview
JAGO is a full-stack ride-sharing admin dashboard (like Uber/Rapido for India) rebuilt from a PHP/Laravel backup as a Node.js/React application. It includes a public landing page and a comprehensive admin panel with JAGO-original design system.

## Tech Stack
- **Frontend**: React + TypeScript + Vite, TanStack Query v5, Wouter routing, custom JAGO CSS design system
- **Backend**: Node.js + Express, Drizzle ORM
- **Database**: PostgreSQL (Replit-provisioned)
- **Icons**: Bootstrap Icons (CDN) — bi-* classes, loaded in index.html
- **Font**: Open Sans (Google Fonts)

## Design System (JAGO Original)
All admin panel styling uses custom JAGO CSS classes in `client/src/index.css`:
- `--bs-primary: #2563EB` (blue), `--bs-body-bg: #F1F5F9`
- `.jago-aside` — white sidebar (background #fff), 270px wide
- `.aside-user-profile` — blue (#2563EB) user profile box in sidebar
- `.jago-header` — white sticky header, 60px
- `.jago-stat-card` — dashboard stat cards
- `.jago-card` / `.jago-card-header` — content cards
- `.jago-table` — data tables with header uppercase styling
- `.jago-badge` — status badges (badge-completed, badge-ongoing, badge-pending, badge-cancelled, badge-active, badge-inactive, badge-primary)
- `.btn-jago-primary` / `.btn-jago-outline` / `.btn-jago-danger` / `.btn-jago-sm` — buttons
- `.jago-input` / `.jago-label` — form inputs
- `.jago-page-header` — page title + breadcrumb row
- `.jago-empty` — empty state component
- `.jago-stats-grid` — responsive stats grid
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
Tables: users, trips, vehicle_categories, zones, trip_fares, coupons, reviews, blogs, business_settings, cancellation_reasons, transactions, withdrawal_requests, admins

## API Routes
- `GET /api/dashboard/stats` — Dashboard statistics
- `GET/POST /api/trips` — Trips CRUD + pagination + status filter
- `PATCH /api/trips/:id/status` — Update trip status
- `GET/POST /api/users` — Users list (filter by userType: customer|driver)
- `PATCH /api/users/:id/status` — Block/unblock user
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

## Seeded Data
- 5 Indian customers (Ravi Kumar, Priya Sharma, Arjun Reddy, Meera Nair, Suresh Babu)
- 5 drivers
- 7 trips across Hyderabad (completed, ongoing, cancelled, pending)
- 4 zones (Hyderabad Central, Hitec City, Gachibowli, Secunderabad)
- 5 vehicle categories (Bike, Auto, Car, SUV, Parcel Bike)
- Fare rules, coupons, reviews, blogs, settings

## Architecture Notes
- `shared/schema.ts`: Drizzle schema with UUID primary keys (varchar with gen_random_uuid())
- `server/storage.ts`: DatabaseStorage class handles all CRUD
- `server/routes.ts`: Thin Express routes using storage interface
- `client/index.html`: Bootstrap Icons CDN only (no Bootstrap CSS — conflicts with Tailwind)
- `client/src/index.css`: Full JAGO design system with CSS custom properties
- Tables created via executeSql (db:push has interactive prompt issue in Replit)
- No Shadcn/Tailwind classes in admin pages — pure JAGO CSS for authentic look
