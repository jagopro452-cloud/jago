# Jago Production Stabilization Issue Tracker

Date: 2026-05-25
Scope: Android customer app, Android pilot app, backend, socket, dispatch, payments, tracking, parcel.
Launch stage: Stabilization phase. No new features until P0 is closed and real-device validation passes.

## Engineering Rules

- No new UI, animation, AI, parcel module, or experimental feature work until stabilization is complete.
- No UI-only fixes for lifecycle, dispatch, auth, payment, or parcel bugs.
- Backend is the source of truth for ride, parcel, payment, dispatch, and session state.
- Frontend must never assume terminal or payment state without server confirmation.
- Every state mutation must be idempotent, transaction-safe, and observable.
- Every fix must include code review, `flutter analyze`, backend check/build where applicable, release build where applicable, and real-device regression.
- Real-device validation must use at least one customer Android device and one pilot Android device.

## Strict Fix Order

1. Socket/Auth Stabilization
2. Ride Lifecycle Stabilization
3. Dispatch Stabilization
4. Driver Registration Stabilization
5. Payment State Integrity
6. Parcel Reliability
7. UX Cleanup

## Status Legend

- Open: confirmed issue, not fixed.
- In Progress: implementation underway.
- Fixed Pending Verification: code fixed, not fully real-device verified.
- Verified: code fixed and verified by required tests.
- Blocked: cannot proceed without secret, environment, or real-device dependency.

---

## P0 - Production Blockers

### P0-001 - Stale Socket Auth and Reconnect Instability

Priority: P0
Status: Fixed Pending Verification
System: Customer app, pilot app, backend socket auth

Root cause:
Socket connections are created with the token in the initial query and are not force-recreated after token refresh. `connect()` returns early if an existing socket is connected, so a refreshed JWT is not propagated. Live logs already showed repeated socket auth failures.

Affected files:
- `flutter_apps/driver_app/lib/services/socket_service.dart`
- `flutter_apps/customer_app/lib/services/socket_service.dart`
- `flutter_apps/driver_app/lib/services/auth_service.dart`
- `flutter_apps/customer_app/lib/services/auth_service.dart`
- `server/socket.ts`

Reproduction steps:
1. Login on pilot/customer app.
2. Let access token expire or trigger refresh.
3. Keep app open or background/reopen.
4. Observe socket reconnect using old query token.
5. Check backend logs for auth failures and missed realtime events.

User impact:
Ride alerts, tracking updates, call events, cancel events, and payment events may silently stop.

Business impact:
Missed trips, driver/customer support escalations, marketplace liquidity loss, failed pilot.

Security risk:
Stale session behavior can keep invalid socket lifecycle around longer than intended.

Scalability risk:
Reconnect storms and repeated auth failures increase socket server load.

Fix strategy:
- Add a single socket auth manager per app.
- On token refresh, disconnect and recreate socket with fresh token.
- On `auth:error`, attempt one refresh, then reconnect once with backoff.
- Add duplicate-listener protection and subscription registry.
- Add socket connection correlation ID and structured reconnect metrics.
- Backend must reject invalid token and log `SOCKET_AUTH_REJECTED` with reason.

Test checklist:
- Token expiry while foreground. Pending real-device verification.
- Token expiry while background. Pending real-device verification.
- Reconnect after app kill/reopen. Pending real-device verification.
- Logout revokes socket. Code path fixed, pending real-device verification.
- Multi-device login does not leak old socket. Backend duplicate cleanup retained, pending real-device verification.
- Driver receives ride after token refresh. Pending real-device verification.
- Customer receives trip updates after token refresh. Pending real-device verification.

Implementation notes:
- Added auth-token change notifier in both Android apps so socket services are notified after login, registration, refresh-token rotation, and logout/session clear.
- Driver socket now recreates the socket with latest token instead of returning early on stale connected sockets.
- Customer socket now recreates the socket with latest token and restores active trip plus active parcel rooms after reconnect.
- Added `auth:error` recovery path that attempts one refresh and reconnects with the new token; failure disconnects instead of silently staying stale.
- Added duplicate listener guard by disposing stale sockets and binding listeners through `socket.off(event)` before `socket.on(event)`.
- Added bounded reconnect settings with jitter instead of unbounded 999-attempt reconnect storms.
- Fixed customer parcel recovery event mismatch by emitting `customer:track_parcel` and `customer:leave_parcel`, while backend keeps legacy aliases for older APKs.
- Backend socket auth now logs `SOCKET_AUTH_START`, `SOCKET_AUTH_SUCCESS`, `SOCKET_AUTH_FAIL`, `SOCKET_ROOM_JOIN`, `SOCKET_ROOM_LEAVE`, and `SOCKET_DISCONNECT` without leaking tokens.

Verification:
- `flutter analyze` passed in `flutter_apps/driver_app`.
- `flutter analyze` passed in `flutter_apps/customer_app`.
- `npm run check` passed.
- Production build passed via direct build steps: migration safety check, Vite build, esbuild server bundle, APK sync.
- `flutter build apk --release` passed in `flutter_apps/driver_app`.
- `flutter build apk --release` passed in `flutter_apps/customer_app`.
- Latest APK aliases updated in `public/apks` and `dist/public/apks`.
- `git diff --check` passed with line-ending warnings only.
- Real-device test blocked: no Android devices were attached according to `adb devices`.

---

### P0-002 - Pilot Online State Can Lie

Priority: P0
Status: Open
System: Pilot app, backend online status, dispatch

Root cause:
The pilot app updates `_isOnline` optimistically and starts location, heatmap, idle timer, and parcel polling before backend and socket confirmation. Network/backend failures are swallowed with a testing comment.

Affected files:
- `flutter_apps/driver_app/lib/screens/home/home_screen.dart`
- `flutter_apps/driver_app/lib/services/socket_service.dart`
- `server/routes.ts`
- `server/socket.ts`

Reproduction steps:
1. Disable internet or use weak network.
2. Tap Online.
3. App shows online and starts local timers.
4. Backend may never mark driver online.
5. Customer booking does not reach driver.

User impact:
Pilot believes they are online but receives no rides.

Business impact:
False supply, booking failures, no-driver screens, driver churn.

Security risk:
Weak state trust on client-side online status.

Scalability risk:
Extra polling and location posts from clients not actually online.

Fix strategy:
- Remove forced testing online behavior.
- Backend/socket ACK must be required before UI shows online.
- If backend update fails, rollback UI and stop timers.
- Add explicit online state: `offline`, `connecting`, `online`, `failed`.
- Store backend-authoritative online status on app resume.

Test checklist:
- Online with no internet.
- Online with expired token.
- Online with backend 500.
- Online on weak network.
- Offline while socket disconnected.
- App kill/reopen should restore server online status, not stale local state.

---

### P0-003 - Active Trip Recovery Misses Payment and Some Active States

Priority: P0
Status: Open
System: Pilot app, customer app, backend active trip APIs

Root cause:
Pilot recovery and backend active-trip endpoint only include `driver_assigned`, `accepted`, `arrived`, and `on_the_way`. `payment_pending` is excluded. Customer active trip and active booking also exclude `payment_pending`.

Affected files:
- `flutter_apps/driver_app/lib/screens/home/home_screen.dart`
- `flutter_apps/driver_app/lib/screens/trip/trip_screen.dart`
- `flutter_apps/customer_app/lib/screens/tracking/tracking_screen.dart`
- `server/routes.ts`

Reproduction steps:
1. Complete trip where wallet/online payment remains pending.
2. Kill pilot/customer app.
3. Reopen app.
4. Active trip screen may not restore.

User impact:
Driver/customer can lose the ride/payment screen while backend still has unresolved state.

Business impact:
Ghost trips, unsettled payments, support intervention.

Security risk:
Users may attempt new bookings while old payment is unresolved.

Scalability risk:
Orphaned trips accumulate and require cleanup jobs.

Fix strategy:
- Define backend canonical active states.
- Include `PAYMENT_PENDING` in recovery where payment action is still needed.
- Frontend must render payment-pending as a distinct state, not completed.
- Recovery endpoint must return cleanup instructions for terminal states.

Test checklist:
- App kill during accepted, arrived, on_the_way, payment_pending.
- Customer app kill during searching and payment_pending.
- Driver app kill during cash collection.
- App reopen after backend terminal transition.

---

### P0-004 - Driver Local Cancel Clears Trip Even When Backend Rejects

Priority: P0
Status: Open
System: Pilot app, backend cancellation

Root cause:
Pilot `_cancelTrip()` catches and ignores HTTP errors, then clears active trip, location timers, socket tracking, and navigates home regardless of backend result.

Affected files:
- `flutter_apps/driver_app/lib/screens/trip/trip_screen.dart`
- `server/services/cancel-trip.ts`
- `server/routes.ts`

Reproduction steps:
1. Start ride.
2. Attempt driver cancel after backend-forbidden state.
3. Backend returns 409.
4. Pilot app still exits trip locally.

User impact:
Pilot sees no trip while customer/backend still show active trip.

Business impact:
Ghost trip, stuck customer, payout/cancellation corruption.

Security risk:
Client can hide active obligation from driver UI.

Scalability risk:
Requires manual reconciliation at scale.

Fix strategy:
- Only cleanup local trip after backend success or idempotent terminal response.
- On 409, refresh active trip and keep pilot on correct screen.
- Show exact state message.
- Add cancel mutation correlation ID.

Test checklist:
- Cancel before accept timeout.
- Cancel after arrived.
- Cancel after OTP/start.
- Cancel after completion.
- Network failure during cancel.

---

### P0-005 - Customer Cancel Sends Duplicate Socket and REST Mutations

Priority: P0
Status: Open
System: Customer app, backend cancellation, socket

Root cause:
Customer cancel emits socket cancel first, then sends REST cancel. Even if backend service is idempotent, client creates duplicate mutation paths and race windows.

Affected files:
- `flutter_apps/customer_app/lib/screens/tracking/tracking_screen.dart`
- `flutter_apps/customer_app/lib/services/socket_service.dart`
- `server/socket.ts`
- `server/routes.ts`
- `server/services/cancel-trip.ts`

Reproduction steps:
1. Customer taps cancel while driver accepts or arrives.
2. Socket event and REST request both race.
3. Observe duplicated state events or inconsistent UI.

User impact:
Cancelled/active screens can flicker or show stale data.

Business impact:
Wrong fees, bad driver experience, customer support tickets.

Security risk:
Replay-like duplicate mutations.

Scalability risk:
Duplicate cancellation work under peak traffic.

Fix strategy:
- Customer uses one authoritative cancel API mutation.
- Socket is broadcast-only for server results.
- Add idempotency key per cancel action.
- Server emits one canonical cancel/reassign event.

Test checklist:
- Cancel during searching.
- Cancel while offer is active.
- Cancel after driver assigned.
- Cancel while driver arrives.
- Double tap cancel.
- Network retry after timeout.

---

### P0-006 - Dispatch Still Depends on Process Memory

Priority: P0
Status: Open
System: Backend dispatch, Redis, socket

Root cause:
`activeDispatches = new Map()` remains central for offer ownership, accept validation, current offered driver, status, and timers. Redis exists but is not the only authority.

Affected files:
- `server/dispatch.ts`
- `server/dispatch-store.ts`
- `server/socket.ts`
- `server/routes.ts`

Reproduction steps:
1. Create booking.
2. Offer is sent to pilot.
3. Restart backend during offer.
4. Pilot accepts or app polls pending offer.
5. Offer ownership can be lost or inconsistent.

User impact:
Ride alert may disappear, accept can fail, or stale offer may remain.

Business impact:
Missed bookings and wrong trip acceptance behavior.

Security risk:
Accept validation can depend on server instance memory.

Scalability risk:
Horizontal scaling remains unsafe.

Fix strategy:
- Move current offer, queue index, offered drivers, rejected drivers, expiry, and phase to Redis/DB.
- All accept checks read Redis/DB, not local map.
- Timers must be recoverable from Redis TTL or scheduled recovery.
- Process memory may cache only, never decide ownership.

Test checklist:
- Server restart during offer.
- Two backend instances.
- Accept after offer expiry.
- Driver reject then next driver offer.
- Redis reconnect.
- Duplicate accept race.

---

### P0-007 - Dispatch Continues When DB Status Check Fails

Priority: P0
Status: Open
System: Backend dispatch

Root cause:
`dispatchNextDriver()` catches DB status check failure and continues dispatch with comment "trip might still be valid". This is fail-open behavior.

Affected files:
- `server/dispatch.ts`

Reproduction steps:
1. Trigger transient DB error during dispatch status validation.
2. Dispatch continues without verifying trip is still searchable.

User impact:
Driver can receive stale/cancelled/changed trip offer.

Business impact:
Wrong alerts, bad acceptance flow, ghost offer support cases.

Security risk:
Unverified state mutation path.

Scalability risk:
DB instability amplifies dispatch corruption.

Fix strategy:
- Fail closed on DB check failure.
- Pause session, persist failure reason, retry with backoff.
- Do not offer to any driver until trip status is verified.

Test checklist:
- Simulated DB timeout.
- Simulated DB connection reset.
- Trip cancelled while DB check retries.
- Dispatch resumes only after status is confirmed.

---

### P0-008 - Payment Pending Is Rendered as Completed

Priority: P0
Status: Open
System: Customer app, payment lifecycle

Root cause:
Customer tracking `_normalizeTripStatus()` converts `payment_pending` to `completed`, collapsing unresolved payment into terminal completion.

Affected files:
- `flutter_apps/customer_app/lib/screens/tracking/tracking_screen.dart`
- `server/routes.ts`
- `server/socket.ts`

Reproduction steps:
1. Complete ride with pending payment.
2. Server emits payment pending.
3. Customer app normalizes it as completed.

User impact:
Customer sees completion while payment action remains.

Business impact:
Unpaid trips, wallet confusion, settlement disputes.

Security risk:
Payment bypass perception and stale active booking risk.

Scalability risk:
Payment reconciliation volume increases.

Fix strategy:
- Keep `payment_pending` as distinct UI and backend state.
- Lock new bookings until payment is resolved or explicitly allowed by business rule.
- Add payment retry/recovery route and UI.

Test checklist:
- Wallet insufficient balance.
- Online payment pending.
- Razorpay failure then retry.
- App kill/reopen during payment pending.

---

### P0-009 - APK Default Production URL Points to Old Backend

Priority: P0
Status: Open
System: Customer app, pilot app, release build

Root cause:
Both Flutter apps default `_prodUrl` to an old DigitalOcean URL. Correct production domain depends on build-time `API_BASE_URL`.

Affected files:
- `flutter_apps/driver_app/lib/config/api_config.dart`
- `flutter_apps/customer_app/lib/config/api_config.dart`
- release scripts

Reproduction steps:
1. Build APK without `--dart-define=API_BASE_URL=https://jagopro.org`.
2. Install APK.
3. App calls old backend.

User impact:
Login, registration, booking, maps health, and runtime config can fail.

Business impact:
Wrong APK distributed to users breaks production.

Security risk:
Users may send tokens to an unintended backend domain if old host is compromised/reused.

Scalability risk:
Operational confusion across app versions.

Fix strategy:
- Replace default prod URL with current production domain or fail build if missing.
- Add build-time environment validation.
- Release artifact manifest must record API URL and build date.

Test checklist:
- Build without dart define fails or uses correct prod.
- Build with prod dart define passes.
- APK smoke test confirms `/api/health` on correct host.

---

## P1 - Severe Issues

### P1-001 - Driver Registration Password Validation Mismatch

Priority: P1
Status: Open
System: Pilot registration

Root cause:
Flutter accepts six-character passwords while backend requires stronger password policy.

Affected files:
- `flutter_apps/driver_app/lib/screens/auth/register_screen.dart`
- `server/routes.ts`

Reproduction steps:
1. Register pilot with six-character weak password.
2. Flutter accepts form.
3. Backend rejects registration.

User impact:
Registration submit fails after user followed app instructions.

Business impact:
Pilot onboarding drop-off.

Fix strategy:
- Share password policy text and regex between app/backend.
- Validate before submit.
- Return structured backend validation error.

Test checklist:
- Weak password rejected before submit.
- Strong password accepted.
- Error message matches backend policy.

---

### P1-002 - Registration Uses Stale Token Path

Priority: P1
Status: Open
System: Pilot registration, auth

Root cause:
Registration submit checks only if an auth token string exists. It does not verify the session before deciding to skip account registration and PATCH registration data.

Affected files:
- `flutter_apps/driver_app/lib/screens/auth/register_screen.dart`
- `flutter_apps/driver_app/lib/services/auth_service.dart`
- `server/routes.ts`

Reproduction steps:
1. Keep expired token in local storage.
2. Open registration and submit.
3. App PATCHes registration endpoint with invalid token.

User impact:
Registration fails with unclear 401 or partial progress.

Business impact:
Drivers cannot onboard reliably.

Fix strategy:
- Before using existing token, call `/api/app/me` or equivalent session validation.
- If invalid, clear session and perform registration/login flow.
- Make onboarding idempotent.

Test checklist:
- Expired token.
- Wrong user token.
- Network failure during profile update.
- Retry after partial registration.

---

### P1-003 - Driver Vehicle Category Can Remain Null

Priority: P1
Status: Open
System: Pilot registration, dispatch eligibility

Root cause:
Backend registration update resolves category with optional row and can store null while returning success.

Affected files:
- `server/routes.ts`
- `flutter_apps/driver_app/lib/screens/auth/register_screen.dart`

Reproduction steps:
1. Submit registration with invalid/missing vehicle category.
2. Backend accepts or stores null category.
3. Driver later goes online.
4. Dispatch rejects with `driver_missing_vehicle_category`.

User impact:
Pilot can register but never receive valid trips.

Business impact:
False driver supply.

Fix strategy:
- Fail closed if category missing/inactive.
- Validate category against selected service and city.
- Add onboarding recovery state for incomplete category.

Test checklist:
- Invalid category.
- Inactive category.
- Category deleted by admin.
- Driver profile update after category fix.

---

### P1-004 - Booking Hardening Checks Fail Open

Priority: P1
Status: Open
System: Backend booking

Root cause:
Rate limit, fraud, and ban checks are wrapped in catch and logged without blocking booking if the hardening check fails.

Affected files:
- `server/routes.ts`
- `server/hardening.ts`

Reproduction steps:
1. Simulate fraud-check DB/cache error.
2. Submit booking.
3. Booking still proceeds.

User impact:
Abusive users may still book.

Business impact:
Request farming, fake demand, driver churn.

Security risk:
Fraud controls bypassed during dependency failure.

Fix strategy:
- Fail closed for ban checks and critical fraud/rate-limit checks.
- Fail safe with degraded limits only if explicitly configured.

Test checklist:
- Fraud service timeout.
- Rate-limit DB failure.
- Banned user booking.
- High-frequency booking abuse.

---

### P1-005 - Complete Trip Accepts Client Fare and Distance

Priority: P1
Status: Open
System: Payment, trip completion

Root cause:
Pilot app sends `actualFare` and `actualDistance` from local trip payload. Backend caps fare but still starts from client-provided values.

Affected files:
- `flutter_apps/driver_app/lib/screens/trip/trip_screen.dart`
- `server/routes.ts`

Reproduction steps:
1. Modify client payload or stale local trip fare.
2. Call complete-trip.
3. Backend calculates settlement using accepted value within caps.

User impact:
Fare may mismatch expected trip.

Business impact:
Revenue leakage, driver/customer disputes.

Security risk:
Fare manipulation vector.

Fix strategy:
- Backend recalculates fare and distance from server trip, route, pricing, and telemetry.
- Client may send display-only hints, never authoritative fare.

Test checklist:
- Tampered fare lower than estimate.
- Tampered fare higher but under cap.
- Stale distance.
- Coupon/surge/wallet edge cases.

---

### P1-006 - Parcel Completion Settlement Is Not Atomic

Priority: P1
Status: Open
System: Parcel, payments

Root cause:
Parcel drop OTP updates delivery progress/status, then separately updates revenue breakdown and calls settlement.

Affected files:
- `server/routes.ts`
- `server/parcel-advanced.ts`

Reproduction steps:
1. Complete final parcel drop.
2. Crash or DB failure after status update before settlement.
3. Parcel shows completed without full settlement.

User impact:
Driver earnings may not reflect completed parcel.

Business impact:
Settlement mismatch and manual finance correction.

Fix strategy:
- Wrap final drop status, revenue fields, driver earnings, settlement ledger, and lifecycle event in a single DB transaction.
- Make completion idempotent by order/drop index.

Test checklist:
- Final drop success.
- Duplicate final OTP submit.
- Crash between update and settlement.
- Multi-drop partial completion.

---

### P1-007 - Parcel Screen Disconnects Shared Pilot Socket

Priority: P1
Status: Open
System: Pilot parcel, socket lifecycle

Root cause:
`ParcelDeliveryScreen.dispose()` calls `_socket.disconnect()`, which can tear down the shared pilot socket instead of only leaving parcel room.

Affected files:
- `flutter_apps/driver_app/lib/screens/parcel/parcel_delivery_screen.dart`
- `flutter_apps/driver_app/lib/services/socket_service.dart`

Reproduction steps:
1. Start parcel delivery screen.
2. Navigate away or dispose screen.
3. Shared socket disconnects.

User impact:
Pilot may stop receiving realtime updates.

Business impact:
Missed requests and tracking gaps.

Fix strategy:
- Add parcel room join/leave methods.
- Screen dispose should cancel only screen subscriptions and leave room.
- Global socket lifecycle managed by session manager.

Test checklist:
- Leave parcel screen while online.
- Reopen parcel screen.
- Receive ride/parcel event after parcel screen dispose.

---

## P2 - Medium Issues

### P2-001 - Excessive Polling Load

Priority: P2
Status: Open
System: Customer app, pilot app, backend

Root cause:
Customer tracking polls every 2 seconds and pilot app performs multiple online polling paths.

Affected files:
- `flutter_apps/customer_app/lib/screens/tracking/tracking_screen.dart`
- `flutter_apps/driver_app/lib/screens/home/home_screen.dart`
- `server/routes.ts`

Reproduction steps:
1. Run many active trips.
2. Observe high active-trip/track-trip/incoming-trip request rate.

User impact:
Battery drain and network usage.

Business impact:
Higher backend cost and degraded peak performance.

Fix strategy:
- Socket-first updates.
- Adaptive polling: fast only during reconnect uncertainty, slower when socket healthy.
- Backoff on errors.

Test checklist:
- 100 simulated active customers.
- Weak network.
- Socket down fallback.

---

### P2-002 - Production Debug Logs and Token Fragments

Priority: P2
Status: Open
System: Mobile apps, backend logging

Root cause:
Debug prints remain in FCM, socket, tracking, and app startup. Customer FCM logs token prefix.

Affected files:
- `flutter_apps/customer_app/lib/services/fcm_service.dart`
- `flutter_apps/driver_app/lib/services/fcm_service.dart`
- `flutter_apps/customer_app/lib/services/socket_service.dart`
- `flutter_apps/customer_app/lib/screens/tracking/tracking_screen.dart`
- `server/dispatch.ts`
- `server/routes.ts`

Reproduction steps:
1. Run release APK with logcat.
2. Observe verbose operational logs and token prefix logs.

User impact:
None direct, but logs are noisy.

Business impact:
Harder production debugging, possible data exposure.

Security risk:
Token fragments and trip identifiers can leak into logs.

Fix strategy:
- Add production-safe logger.
- Remove token logs.
- Use correlation IDs without sensitive data.

Test checklist:
- Release logcat inspection.
- Backend log review under booking.

---

### P2-003 - Fare Fallback Rows Still Exist

Priority: P2
Status: Open
System: Customer booking

Root cause:
The old `_buildFallbackFares()` still creates unavailable fare rows. Booking is blocked, but the path remains confusing and risky if later reused.

Affected files:
- `flutter_apps/customer_app/lib/screens/booking/booking_screen.dart`

Reproduction steps:
1. Break fare API.
2. Booking screen shows fallback/unavailable state.

User impact:
Confusing "no rides available" behavior during API failure.

Business impact:
Lower conversion and support confusion.

Fix strategy:
- Remove fake fare construction entirely.
- Show server-authoritative retry/error state only.

Test checklist:
- Fare API 500.
- Fare API empty.
- Network offline.
- Retry success.

---

### P2-004 - Trip State Vocabulary Is Inconsistent

Priority: P2
Status: Open
System: Backend, customer app, pilot app, admin

Root cause:
Code uses mixed states: `searching`, `driver_assigned`, `accepted`, `arrived`, `on_the_way`, `payment_pending`, while the target state machine uses `REQUESTED`, `ASSIGNED`, `ACCEPTED`, `ARRIVING`, `STARTED`, `IN_PROGRESS`, `PAYMENT_PENDING`, `COMPLETED`, `CANCELLED`.

Affected files:
- `server/routes.ts`
- `server/socket.ts`
- `server/services/cancel-trip.ts`
- `flutter_apps/customer_app/lib/screens/tracking/tracking_screen.dart`
- `flutter_apps/driver_app/lib/screens/trip/trip_screen.dart`

Reproduction steps:
1. Move trip across accept/arrive/start/complete.
2. Compare backend status, UI status, socket status, and admin labels.

User impact:
Status confusion and stale UI.

Business impact:
Harder support and reconciliation.

Fix strategy:
- Define canonical backend enum.
- Add API adapter for old app compatibility.
- Remove frontend rank hacks after migration.

Test checklist:
- All transition paths.
- Old APK compatibility.
- Admin status rendering.

---

## P3 - Minor / UX / Maintainability

### P3-001 - Garbled Strings in UI and Logs

Priority: P3
Status: Open
System: Mobile apps, backend logs

Root cause:
Encoding corruption appears in strings and logs.

Affected files:
- Multiple Flutter screens
- `server/routes.ts`
- `server/dispatch.ts`

Reproduction steps:
1. Trigger online/offline/fare/refund/completion messages.
2. Observe garbled characters.

User impact:
Unprofessional UI and poor readability.

Business impact:
Brand quality risk.

Fix strategy:
- Normalize UTF-8 strings.
- Replace corrupted symbols with plain production copy.

Test checklist:
- Telugu/English app language paths.
- Release APK visual smoke.

---

### P3-002 - Silent Catch Blocks Hide Production Failures

Priority: P3
Status: Open
System: Mobile apps, backend

Root cause:
Many paths use `catch (_) {}` or ignore errors without telemetry.

Affected files:
- Flutter customer app
- Flutter pilot app
- `server/routes.ts`
- `server/parcel-advanced.ts`

Reproduction steps:
1. Simulate network/API/JSON errors.
2. Observe no structured error path.

User impact:
Screens fail silently or stay stale.

Business impact:
Root cause analysis is slow.

Fix strategy:
- Central error logger with screen/action/tripId.
- Convert critical silent catches to visible recovery states.

Test checklist:
- API 500.
- Non-JSON response.
- Socket error.
- Permission denied.

---

### P3-003 - Admin/Vehicle Status Fallback Can Mask Control Plane Failure

Priority: P3
Status: Open
System: Customer app, pilot app, admin controls

Root cause:
Vehicle status services use local fallback statuses when API fails.

Affected files:
- `flutter_apps/customer_app/lib/services/vehicle_status_service.dart`
- `flutter_apps/driver_app/lib/services/vehicle_status_service.dart`

Reproduction steps:
1. Disable vehicle status API.
2. App still displays fallback statuses.

User impact:
User/pilot sees services as available when control plane may be down.

Business impact:
Bookings can be attempted during admin outage.

Fix strategy:
- Fail closed for service availability.
- Show "service temporarily unavailable" if control plane cannot be reached.

Test checklist:
- Vehicle status API 500.
- Vehicle status API timeout.
- Admin disables bike/auto/cab.

---

## Required Stabilization Test Matrix

### Real Android Device Matrix

- Customer device: login, logout, token refresh, booking, cancel, tracking, payment pending, app kill/reopen.
- Pilot device: registration, login, online/offline, receive request, accept, arrive, start, complete, cancel rejection, app kill/reopen.
- Cross-device: customer booking reaches correct pilot category only.
- Weak network: airplane mode on/off, WiFi/mobile switch, server reconnect.
- GPS: permission denied, GPS off/on, stale last known location, battery saver.
- Notifications: foreground, background, killed state, sound, full-screen alert, tap resume.
- Parcel: quote, book, pending recovery, accept, pickup OTP, drop OTP, multi-drop completion.

### Backend Verification

- `npm run check`
- `npm run build`
- Dispatch restart recovery test.
- Redis down/degraded mode test.
- DB transaction rollback test for completion/cancel/parcel.
- Payment webhook idempotency test.
- Socket reconnect/auth refresh test.

### Release Verification

- `flutter analyze`
- `flutter build apk --release --dart-define=API_BASE_URL=https://jagopro.org`
- `flutter build appbundle --release --dart-define=API_BASE_URL=https://jagopro.org`
- APK install on two real devices.
- Verify build artifact manifest includes API base URL, date, git SHA, app version.

## Stabilization Exit Criteria

P0 exit requires:
- All P0 items fixed in code.
- Backend check/build passes.
- Customer and pilot analyze passes.
- Fresh APKs built from current code.
- Two real Android devices complete customer-pilot lifecycle.
- No socket auth errors during test.
- No wrong-category dispatch.
- No ghost active trip after cancel/complete/payment pending.
- Production logs show clean booking trace from create to accept/complete.

P1 exit requires:
- All severe issues fixed or explicitly accepted with owner/date.
- Registration and parcel flows pass real-device QA.
- Payment pending and settlement reconciliation verified.

Public launch is blocked until P0 and P1 exit criteria pass.
