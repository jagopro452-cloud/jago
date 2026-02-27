# JAGO - India's Smart Mobility Platform

## Overview
JAGO is a full-stack ride-sharing admin dashboard (like Uber/Rapido for India) rebuilt from a PHP/Laravel backup as a Node.js/React application. It includes a public landing page and a comprehensive admin panel.

## Tech Stack
- **Frontend**: React + TypeScript + Vite, TanStack Query v5, Wouter routing, Shadcn/UI, Tailwind CSS
- **Backend**: Node.js + Express, Drizzle ORM
- **Database**: PostgreSQL (Replit-provisioned)

## Color Theme
- Primary blue: HSL 217 91% 55%
- Dark sidebar: HSL 224 71% 20%
- Gradient stat cards: stat-card-blue/green/amber/purple/red/cyan (defined in index.css)
- Dark mode: Full support via ThemeProvider with localStorage persistence

## Features

### Public Landing Page (`/`)
- Hero section with animated background
- Services section (Bike, Auto, Car, Parcel)
- How It Works (3-step flow)
- Features grid (Tracking, Safety, Speed, Ratings)
- CTA section + footer

### Admin Panel (`/admin/`)
Authentication: Demo mode — any credentials accepted. Stored in localStorage.

#### 14 Admin Pages:
1. **Dashboard** (`/admin/dashboard`) — Stats cards + recent trips table
2. **Trip Requests** (`/admin/trips`) — Paginated trip list with status filter + actions
3. **Customers** (`/admin/customers`) — Customer management with block/unblock
4. **Drivers** (`/admin/drivers`) — Driver partner management
5. **Vehicle Categories** (`/admin/vehicles`) — CRUD for vehicle types (Bike/Auto/Car/SUV)
6. **Zones** (`/admin/zones`) — Service zone management
7. **Fare Management** (`/admin/fares`) — Pricing rules per zone/vehicle
8. **Transactions** (`/admin/transactions`) — Financial transaction log
9. **Coupons** (`/admin/coupons`) — Coupon code CRUD with discount types
10. **Reviews** (`/admin/reviews`) — Customer/driver review viewer
11. **Blogs** (`/admin/blogs`) — Article management with WYSIWYG
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
- `client/src/components/theme-provider.tsx`: Theme context (light/dark)
- Tables were created manually via executeSql (db:push has interactive prompt issue)
