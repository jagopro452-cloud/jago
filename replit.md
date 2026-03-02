# JAGO - India's Smart Mobility Platform

## Overview
JAGO is a full-stack ride-sharing admin dashboard and platform, akin to Uber or Rapido, specifically re-engineered for the Indian market. It was rebuilt from a PHP/Laravel application into a modern Node.js/React stack. The platform aims to provide a comprehensive solution for managing ride-sharing services, including a public-facing landing page and an extensive admin panel featuring a unique JAGO-original design system. The project encompasses robust features for customer and driver management, trip orchestration, financial transactions, and real-time functionalities through integrated Flutter mobile applications for both drivers and customers.

## User Preferences
No specific user preferences were provided in the original `replit.md` file.

## System Architecture

### Technology Stack
- **Frontend**: React, TypeScript, Vite, TanStack Query v5, Wouter for routing, custom JAGO CSS design system.
- **Backend**: Node.js, Express, Drizzle ORM.
- **Database**: PostgreSQL.
- **Mobile Applications**: Flutter for both Driver (JAGO Pilot) and Customer (JAGO) apps.

### Design System
The platform utilizes a proprietary "JAGO Original" design system, meticulously recreated from the legacy PHP/Laravel application's CSS. This ensures a consistent brand identity across the admin panel. Key elements include:
- **Branding**: JAGO brand logo and favicon.
- **Layout**: Dedicated classes for sidebar (`.aside`), header (`.header`), and main content areas, supporting responsive views including a folded sidebar (`body.aside-folded`).
- **Components**: Custom-styled cards (`.jago-stat-card`, `.jago-card`), tables (`.jago-table`), badges (`.jago-badge`), buttons (`.btn-jago-primary`), and form elements (`.jago-input`).

### Technical Implementations & Features

#### Web Platform
**Public Landing Page (`/`)**:
- Features hero section, service descriptions (Bike, Auto, Car, Parcel), a "How It Works" section, a features grid (Tracking, Safety, Speed, Ratings), CTA, and a footer.
- Includes dedicated policy pages: Privacy Policy, Terms & Conditions, About Us, and Contact Us.

**Admin Panel (`/admin/`)**:
- **Authentication**: Demo mode with any credentials accepted, stored locally.
- **Core Modules**:
    - **Dashboard**: Overview with statistics, charts, and recent activities.
    - **Trip Management**: Requests, customer and driver management, vehicle categories, zones, and fare rules.
    - **Financials**: Transactions, coupons, and driver withdrawal approvals.
    - **Content**: Reviews, blogs, and cancellation reasons.
    - **Settings**: Business, currency, and trip settings.
- **New Features (Feb 2026)**:
    - **Fare Calculator**: Admin tool for real-time fare estimations.
    - **Driver Earnings Statement**: Detailed earnings breakdown for drivers.
    - **Referral Management**: Comprehensive system for managing referrals.
    - **Notifications History**: Persistent logging and viewing of system notifications.
    - **Safety & Emergency**: SOS alerts, police station management, and female-to-female matching.

#### Mobile Applications (Flutter)
**Driver App (JAGO Pilot)**:
- **Theme**: Dark navy with blue accents.
- **Functionality**: Live GPS tracking, KYC document upload, performance metrics, face verification, **Break Mode**, **Safety & Fatigue Screen**, detailed earnings, wallet management, parcel information display during trips, and dynamic support.

**Customer App (JAGO)**:
- **Theme**: Light white with blue accents.
- **Functionality**: **JAGO Coins** loyalty program, **Monthly Pass** subscriptions, customizable ride preferences (AC, quiet, women driver), post-ride tipping, lost & found reporting, surge pricing alerts, scheduled rides, emergency contacts, saved places shortcuts, **Car Sharing**, **Parcel Booking**, and a dynamic banner carousel for offers.

### Real-Time Capabilities (Socket.IO)
- **Server (`server/socket.ts`)**: Manages real-time events for driver location updates, online/offline status, trip acceptance/cancellation, and status changes.
- **Client (`socket_service.dart`)**: Integrates real-time features into both mobile apps, enabling live driver GPS tracking, instant trip updates, and communication for critical events.

### Security
- **Authentication**: `bcrypt` for password hashing, `express-rate-limit` for brute-force protection.
- **Headers**: Implementation of standard security headers.
- **Admin Access**: Default admin credentials with hashed password and a client-side math captcha for login.
- **Mobile App Auth**: Token-based authentication stored in `users.auth_token`.
- **OTP Security**: Rate limiting and secure handling of OTPs (not logged or returned in production).
- **Input Validation**: Comprehensive validation for critical inputs (e.g., fare amounts, UUIDs, wallet recharges).

### Database Schema
- Uses Drizzle ORM with UUID primary keys.
- Key tables include `users`, `trips`, `vehicle_categories`, `zones`, `trip_fares`, `coupons`, `reviews`, `blogs`, `business_settings`, `cancellation_reasons`, `transactions`, `withdrawal_requests`, `admins`, `parcel_attributes`.
- Driver-specific fields for verification status, licensing, and vehicle details.
- New tables for `referrals`, `notification_logs`, `safety_alerts`, and `police_stations` support recent feature additions.
- File uploads are managed and served from `public/uploads/`.

## External Dependencies
- **Icons**: Bootstrap Icons (via CDN).
- **Font**: Open Sans (via Google Fonts).
- **Google Maps API**: Required for maps functionality in Flutter mobile applications.
- **Payment Gateways**: Implicitly required for wallet recharge functionality, though specific provider not mentioned.