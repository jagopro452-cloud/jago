# JAGO - India's Smart Mobility Platform

## Overview
JAGO is a comprehensive ride-sharing platform designed for the Indian market, featuring a full-stack Node.js/React admin panel and Flutter mobile applications for both drivers (JAGO Pilot) and customers (JAGO). The platform aims to provide a robust, scalable, and feature-rich solution for urban mobility, covering various services like bike rides, auto rides, car rides, parcel delivery, cargo, and intercity travel. It is built for deployment on major app stores. The business vision is to capture a significant share of the Indian ride-hailing and logistics market by offering a localized and efficient service.

## User Preferences
I want iterative development.
I prefer detailed explanations.
Do not make changes to the folder `Z`.
Do not make changes to the file `Y`.

## System Architecture

### Technology Stack
- **Frontend (Admin Panel)**: React, TypeScript, Vite, TanStack Query v5, Wouter, custom Bootstrap CSS.
- **Backend**: Node.js, Express, Drizzle ORM, Socket.IO for real-time communication, bcrypt for password hashing, express-rate-limit for security.
- **Database**: PostgreSQL with UUID primary keys.
- **Mobile**: Flutter 3.22.3, Dart for both customer and driver applications.
- **UI/UX Design**: Rapido-style premium UI with #FF6B35 (JAGO orange), #060D1E (deep navy), #0D1B3E (surface), #FFD700 (gold). Both apps support full dark/light mode. Driver home has floating top bar, pulsing LIVE banner, gradient ONLINE/OFFLINE pill, performance stats. Customer home has greeting chip (Good Morning/etc pill), bold 24px name, orange fare in recent trips, gradient "Repeat →" buttons. Booking screen has gradient check badge (28px) on selected vehicle, dynamic options counter.
- **Current Build**: v1.0.17+17. Both APKs ~56MB. Build script auto-resets Flutter git state before driver build to prevent corruption after customer build. v1.0.17 adds: gradient-accent stat cards on driver home (tappable, navigate to Earnings/Trips/Wallet), ordinal suffix fix, colored gradient grid service cards on customer home (each service has distinct accent color), in-app trip chat relay via socket (driver↔customer sendChatMessage), socket services updated with onChatMessage stream.

### Core Features & Implementations
- **Driver Onboarding & Verification**: A 6-step registration flow for drivers including basic info, password, driving license details, vehicle details, vehicle documents, and a selfie. Documents are uploaded as base64 images. A verification system with pending and rejection screens, and an admin panel for document approval/rejection with FCM push notifications.
- **Revenue Models**: Drivers can choose between a Commission Model (15% per ride) or a Subscription Model (pay upfront, keep 100%). Subscription plans are configurable (e.g., 7-day, 15-day, 30-day).
- **Multi-Vehicle Selection**: Customer app displays all available vehicle options (Bike, Auto, Car, Parcel, Cargo, Intercity) with fare, distance, and ETA, allowing selection and automatic application of discounts.
- **Real-Time Tracking & Communication**: Socket.IO is used for real-time driver location updates, trip status, and online/offline events. WebRTC is integrated for call signaling between drivers and passengers.
- **Wallet & Payments**: Integrated with Razorpay for wallet recharges and ride payments. Security measures are in place to prevent duplicate payments.
- **Account Management**: Features for both customer and driver account deletion (soft deactivate or permanent delete). Admin panel includes comprehensive user management for drivers, customers, employees, and subscriptions.
- **Localization**: Supports multiple languages (en, te, hi, ta, kn, ml) with a robust localization service within the Flutter apps and an admin interface for managing app languages.
- **Security**: Implements bcrypt for admin password hashing, rate limiting, token-based authentication for mobile apps, input validation using Zod, and security headers.
- **Admin Panel**: Comprehensive dashboard with fleet map, heat map, zone management, trip management, promotions, user management, parcel attributes, B2B, vehicle management, fare management, finance, support, content, and business settings.

## External Dependencies
- **Payments**: Razorpay (for wallet recharge and ride payments).
- **OTP Service**: Fast2SMS API (for sending one-time passwords).
- **Maps**: Google Maps API Key (for location services and navigation).
- **Real-time Communication**: Socket.IO (for live updates and WebRTC signaling).
- **Push Notifications**: Firebase (placeholder integrated; requires user's Firebase project for full functionality).