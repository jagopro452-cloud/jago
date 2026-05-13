# JAGO End-to-End Release Checklist

Purpose: verify whether JAGO customer app, driver app, and backend are strong enough for a Rapido-style core ride flow.

This checklist is intentionally practical. If any item in the "Blocker" group fails, do not call the build production-ready.

## 1. Test Setup

- Use 2 real Android phones whenever possible.
- Install latest customer APK and driver APK.
- Confirm backend, database, OTP provider, maps key, and sockets are pointed to the same environment.
- Keep one tester as customer and one tester as driver.
- Keep one fallback driver account ready for concurrency tests.

## 2. Release Blockers

- OTP login must work on both apps.
- Customer must be able to book a ride without app crash or stuck loader.
- Driver must receive trip request in real time.
- Driver accept must sync to customer app within a few seconds.
- Arrived -> pickup OTP -> trip start flow must work without deadlock.
- Live tracking must update while trip is active.
- Trip completion and payment-close state must finish cleanly on both apps.
- App restart during active trip must restore the correct trip screen.
- Network off/on recovery must not create duplicate trips or broken state.

## 3. Happy Path Test

### 3.1 Customer Login

- Enter valid phone number.
- Request OTP.
- Enter correct OTP.
- Expected: customer lands on main home/map screen.

### 3.2 Driver Login

- Enter valid phone number.
- Request OTP.
- Enter correct OTP.
- Expected: driver lands on home/map screen and can go online.

### 3.3 Customer Booking

- Pick pickup and destination on map.
- Select vehicle category.
- Select payment mode.
- Confirm booking.
- Expected: booking is created and customer sees searching state.

### 3.4 Driver Offer

- Driver goes online before booking.
- Expected: driver receives incoming request sheet with trip details.
- Accept within timeout.
- Expected: driver moves to accepted/navigate-to-pickup state.

### 3.5 Sync Check

- Customer app must show accepted state, driver details, and live trip context.
- Driver app must show route to pickup.
- Expected: both apps show the same trip id and same stage.

### 3.6 Arrived and Pickup OTP

- Driver taps arrived.
- Customer should see arrival state and pickup OTP.
- Driver enters correct pickup OTP.
- Expected: trip moves to in-progress/on-the-way state on both apps.

### 3.7 Trip Completion

- Drive to destination.
- End trip from driver app.
- Complete payment on customer side if payment is pending.
- Expected: both apps show completed state and allow rating flow.

## 4. Centralization Checks

These confirm the system is behaving like one connected platform, not separate loose apps.

- Booking created on customer app must appear to driver via same backend flow.
- Trip accept must update both apps from centralized trip state.
- Arrived status must be reflected on both apps without manual refresh.
- OTP verification must update server trip state, not only local UI state.
- Completion must update trip history, wallet/payment state, and final ride status.

## 5. Recovery Tests

### 5.1 Customer App Kill During Active Trip

- Start a trip.
- Force close customer app.
- Reopen app.
- Expected: app restores active trip tracking screen directly.

### 5.2 Driver App Kill During Active Trip

- Start a trip.
- Force close driver app.
- Reopen app.
- Expected: app restores current active trip instead of generic home state.

### 5.3 Internet Drop Recovery

- Turn off mobile data/Wi-Fi for 10-20 seconds during:
- searching state
- accepted state
- in-progress state
- Turn internet back on.
- Expected: app reconnects and restores latest trip state without duplicate actions.

### 5.4 Concurrent Accept Test

- Broadcast one ride to two driver accounts.
- Tap accept from both drivers nearly at same time.
- Expected: only one driver gets trip, second driver receives graceful rejection.

## 6. Maps and Navigation Checks

- Customer map should load current location without white/blank map.
- Driver map should load current location and pickup path context.
- Navigate to pickup should open correctly with valid pickup coordinates.
- No zero coordinates, null coordinates, or broken map launch should be observed.

## 7. OTP Checks

- OTP request should succeed for both apps.
- Wrong OTP should be rejected gracefully.
- Correct OTP should log in or start trip correctly.
- Pickup OTP should appear on customer app and verify on driver app.
- Expected: no stale OTP state and no skipped verification state.

## 8. Payment and Wallet Checks

- Cash ride should close correctly.
- Online payment ride should not remain stuck in payment-pending forever.
- Wallet balance should update after recharge and after trip where applicable.
- Driver wallet lock behavior should be checked if negative-balance rules are enabled.

## 9. Observability Checks

- Server logs should clearly show booking, accept, arrived, OTP verify, start trip, and complete trip stages.
- No repeated 500 errors should appear during ride lifecycle.
- Socket reconnect logs should appear cleanly during network recovery tests.

## 10. Pass or Fail Rules

Mark as `PASS` only if all of the below are true:

- Both apps log in successfully.
- One full ride completes end-to-end.
- Pickup OTP flow works.
- Tracking stays in sync.
- Restart recovery works.
- Internet recovery works.
- No blocker crash or deadlock occurs.

Mark as `NOT YET STRONG ENOUGH` if any of the below happen:

- Trip gets stuck between accepted and arrived.
- Pickup OTP fails even with correct value.
- Customer and driver show different trip states.
- Active trip is lost after app restart.
- Payment-close remains stuck.
- Maps/navigation fails with valid trip data.

## 11. Honest Current Assessment

Based on current repo state:

- Build stability: yes
- Core ride lifecycle hardening: yes
- Centralized trip/socket architecture: mostly yes
- Proven by repeated real-device validation: not yet
- Rapido-exact polish and resilience: not yet

Current recommendation:

- Safe to call this build "structurally strong and testable"
- Not yet safe to call it "fully Rapido-level production-proven" until this checklist passes on real devices
