# Brutal E2E Phase Runbook

Date: 2026-04-07

## Phase 0 Setup

1. Start backend:
   - npm run dev
2. Keep DB live watch open:
   - node scripts/ops/watch-trip.js
   - or for one trip: node scripts/ops/watch-trip.js <tripId>
3. Observe logs:
   - API trace logs include reqTrace and resTrace in server/index.ts
   - DB-backed trip lifecycle traces emit as:
     - [TRIP-TRACE] from API routes
     - [SOCKET-TRACE] from socket handlers

Expected trace fields in logs:
- tripId
- status
- driverId
- customerId
- createdAt
- acceptedAt
- arrivedAt
- startedAt
- completedAt

## Phase 1 Golden Flow (GF-01)

1. Customer books ride.
2. Driver receives request.
3. Driver accepts.
4. Driver marks arrived.
5. Wait 2-3 mins.
6. Driver starts trip.
7. Driver completes trip.
8. Payment update.

Pass checks:
- SEARCHING -> ACCEPTED -> ARRIVED -> ONGOING(on_the_way) -> COMPLETED
- arrivedAt present after arrived action
- waitingCharge > 0 after delay and completion
- final fare from server includes waiting charge

Where to verify:
- [TRIP-TRACE] logs
- watch-trip output
- API response pricing block on complete-trip

## Phase 2 Race Conditions

### RC-01 Double Accept

Method:
- Trigger accept from two drivers at same time.

Pass:
- One accept succeeds.
- Other gets already assigned/unavailable error.

Why this should hold:
- Atomic UPDATE with status guard in API and socket handlers.

### RC-02 Cancel vs Accept Clash

Method:
- Trigger customer cancel and driver accept nearly same time.

Pass:
- Either cancel wins cleanly, or accept wins and cancel is rejected.
- No ghost trip state.

### RC-03 Reconnect Restore

Method:
- Accept trip on driver app, kill app, reopen.

Pass:
- Active trip restored via active-trip endpoint or rejoin event.

## Phase 3 Realtime and Socket Reliability

### RT-01 Driver Movement

Method:
- Send continuous location updates from driver app.

Pass:
- Customer receives driver:location_update updates.
- No stale/frozen marker in active trip.

### RT-02 Network Drop

Method:
- Drop network for 30 seconds, reconnect.

Pass:
- Driver reconnects, trip room rejoin works.
- Status does not reset.

## Phase 4 Payment Reality

### PAY-01 Success
- Complete trip and verify payment success flow.
- Expect payment status: paid/paid_online/wallet_paid.

### PAY-02 Failure
- Simulate failed payment.
- Expect payment failed/pending with retry path.

### PAY-03 Webhook Delay
- Delay webhook processing.
- Expect eventual consistent status update.
- No duplicate charge.

## Phase 5 Security Abuse

### SEC-01 Promo Abuse
- Send fake promoDiscount from client.
- Expect server ignores client-side discount and only applies validated coupon.

### SEC-02 Nearby Drivers Spam
- Hit nearby-drivers endpoint repeatedly.
- Expect auth + rate limit controls.

### SEC-03 Weak Password
- Try weak password (<8, no number/letter mix).
- Expect rejection.

## Phase 6 Edge Cases

### EC-01 Driver never starts
- Accept but do not start.
- Verify timeout/handling behavior and no indefinite stuck state.

### EC-02 Customer no-show
- Arrive and wait.
- Verify waiting charge accrues after first free minute.

### EC-03 App killed mid-trip
- Kill customer + driver apps and reopen.
- Verify trip state restore and no duplicate trip creation.

## Scoring Template

- 90-100: Ready for beta
- 70-89: Fix critical gaps
- <70: Not deployable

Suggested scoring model:
- GF-01: 25 points
- Race (RC-01..03): 25 points
- Realtime (RT-01..02): 15 points
- Payment (PAY-01..03): 15 points
- Security (SEC-01..03): 10 points
- Edge cases (EC-01..03): 10 points

Total: 100
