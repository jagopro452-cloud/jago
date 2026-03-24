# Phase 2 Routes Integration Guide

## Overview

This guide shows the **EXACT LOCATIONS** in `server/routes.ts` where hardening functions should be integrated. 

**File:** `server/routes.ts` (9200+ lines)

---

## 🎯 Integration Points

### 1. Post /api/app/customer/book-ride (Line ~9155)

**ADD THESE BEFORE trip_requests INSERT:**

```typescript
// At line ~9170 (before INSERT into trip_requests)

import { checkBookingRateLimit, detectBookingFraud, checkCustomerBans } from "./hardening-routes";

if (req.method === 'POST' && req.path === '/api/app/customer/book-ride') {
  // ─── VALIDATION: Rate Limit ───
  const rateCheck = await checkBookingRateLimit(customerId, 20); // Max 20 bookings/hour
  if (!rateCheck.allowed) {
    return res.status(429).json({ error: rateCheck.reason });
  }
  
  // ─── VALIDATION: Fraud Detection ───
  const fraudCheck = await detectBookingFraud(customerId, pickupLat, pickupLng);
  if (fraudCheck.isFraudulent) {
    return res.status(400).json({ error: fraudCheck.reason });
  }
  
  // ─── VALIDATION: Check Bans ───
  const banCheck = await checkCustomerBans(customerId);
  if (banCheck.banned) {
    return res.status(403).json({ 
      error: banCheck.reason,
      banUntil: banCheck.until,
    });
  }
  
  // ─── Proceed with trip creation ───
  // ... existing INSERT into trip_requests ...
}
```

**Location in code:**
```
server/routes.ts
├─ Line ~9150: POST /api/app/customer/book-ride endpoint
├─ Line ~9200: UUID validation
├─ Line ~9250: Service activation gate
├─ Line ~9300: HERE → ADD HARDENING CHECKS
├─ Line ~9350: trip_requests INSERT
└─ Line ~9500: Response sent to customer
```

---

### 2. POST /api/app/driver/accept-trip (Line ~7826)

**ADD THESE AFTER trip acceptance UPDATE:**

```typescript
// At line ~7880 (after UPDATE trip_requests SET driver_id)

import { notifyCustomerWithDriver, setupTripTimeoutHandlers } from "./hardening-routes";

// ... existing trip claim logic ...

// Atomically claim the trip
const claimed = await rawDb.execute(rawSql`
  UPDATE trip_requests SET driver_id=${userId}::uuid, current_status='accepted'
  WHERE id=${tripId}::uuid AND current_status IN ('searching','driver_assigned')
  RETURNING id
`);

if (claimed.rows.length) {
  // ─── NEW: Notify customer with driver details ───
  const driverR = await rawDb.execute(rawSql`
    SELECT full_name, phone FROM users WHERE id=${userId}::uuid
  `);
  const driver = driverR.rows[0] as any;
  
  // Get driver rating
  const ratingR = await rawDb.execute(rawSql`
    SELECT avg_rating FROM driver_details WHERE user_id=${userId}::uuid
  `);
  const driverRating = (ratingR.rows[0] as any)?.avg_rating || 4.5;
  
  // ─── HARDENING: Notify customer + setup timeout handlers ───
  await notifyCustomerWithDriver(
    trip.customer_id,
    userId,
    tripId,
    driver.full_name,
    driver.phone,
    driverRating
  );
  
  await setupTripTimeoutHandlers(tripId, trip.customer_id, userId);
  
  // ─── HARDENING: Trigger driver ping verification (in background) ───
  // This is automatic in dispatch.ts, but ensure it's called:
  const { onDriverAccepted } = require('./dispatch');
  // Note: dispatch.ts already handles this in onDriverAccepted()
  
  socket.emit('driver:accept_trip_ok', { tripId });
}
```

**Location in code:**
```
server/routes.ts
├─ Line ~7826: POST /api/app/driver/accept-trip endpoint  
├─ Line ~7880: Trip claim UPDATE SQL
├─ Line ~7920: HERE → ADD CUSTOMER NOTIFICATION + TIMEOUT SETUP
├─ Line ~7950: Response sent to driver
└─ Line ~8000: End of endpoint
```

---

### 3. POST /api/app/driver/complete-trip (Line ~8177)

**ADD THESE IN SETTLEMENT SECTION:**

```typescript
// At line ~8250 (inside settlement/revenue logic)

import { validateFareAccuracy, notifyTripCompletion } from "./hardening-routes";

// ... existing fare capping ...

const actualFare = req.body.actualFare || estimatedFare;

// ─── HARDENING: Validate fare accuracy and refund if over-charged ───
const fareValidation = await validateFareAccuracy(
  tripId,
  estimatedFare,
  actualFare,
  trip.customer_id
);

let finalFare = fareValidation.refundRequired 
  ? (actualFare - fareValidation.refundAmount) 
  : actualFare;

// ─── Proceed with settlement using finalFare ───
// ... existing settlement logic ...

// After settlement completes:

// ─── HARDENING: Notify customer of completion ───
await notifyTripCompletion(
  trip.customer_id,
  tripId,
  finalFare,
  trip.payment_method,
  driverName
);

// ─── Emit socket event ───
io.to(`user:${trip.customer_id}`).emit('trip:completed', {
  tripId,
  finalFare,
  rating_requested: true,
});
```

**Location in code:**
```
server/routes.ts
├─ Line ~8177: POST /api/app/driver/complete-trip endpoint
├─ Line ~8220: OTP verification
├─ Line ~8250: HERE → ADD FARE VALIDATION
├─ Line ~8300: Revenue settlement
├─ Line ~8350: HERE → ADD COMPLETION NOTIFICATION
└─ Line ~8450: Response sent
```

---

### 4. POST /api/app/driver/cancel-trip (Line ~8449)

**ADD HARDENING FOR DRIVER CANCELLATION:**

```typescript
// At line ~8480 (inside cancel logic)

import { recordDriverCancellation, notifyTripCancellation } from "./hardening-routes";

// ... existing validation ...

const reason = req.body.reason || 'Driver cancelled';

// ─── HARDENING: Record driver cancellation (may trigger no-show) ───
const isNoShow = await recordDriverCancellation(
  tripId,
  userId,
  trip.customer_id,
  reason
);

// ─── HARDENING: Notify customer ───
await notifyTripCancellation(
  trip.customer_id,
  userId,
  tripId,
  'driver',
  reason
);

// ─── Refund customer ───
if (trip.payment_status === 'paid') {
  // Razorpay refund logic
}

// ─── Socket notification ───
io.to(`user:${trip.customer_id}`).emit('trip:cancelled', {
  tripId,
  cancelledBy: 'driver',
  reason: reason,
});
```

**Location in code:**
```
server/routes.ts
├─ Line ~8449: POST /api/app/driver/cancel-trip endpoint
├─ Line ~8480: HERE → ADD NO-SHOW RECORDING + NOTIFICATION
├─ Line ~8520: Trip status UPDATE
└─ Line ~8600: Reassignment logic
```

---

### 5. POST /api/app/customer/cancel-trip (Line ~9612)

**ADD HARDENING FOR CUSTOMER CANCELLATION:**

```typescript
// At line ~9650 (inside cancel logic)

import { recordCustomerCancellation, notifyTripCancellation } from "./hardening-routes";

const reason = req.body.reason || 'Customer cancelled';

// ─── HARDENING: Apply cancel penalties if applicable ───
const penalty = await recordCustomerCancellation(
  tripId,
  customerId,
  reason
);

if (penalty.penaltyApplied) {
  // Notify customer about penalty
  res.json({
    ...restOfResponse,
    penaltyApplied: true,
    penaltyAmount: penalty.penaltyAmount,
    message: `Trip cancelled. ₹${penalty.penaltyAmount} penalty charged.`,
  });
}

// ─── HARDENING: Notify customer and driver ───
await notifyTripCancellation(
  customerId,
  trip.driver_id,
  tripId,
  'customer',
  reason
);

// ─── Refund customer ───
const refundAmount = trip.estimated_fare;
// ... existing Razorpay/wallet refund ...

// ─── Socket notification ───
io.to(`trip:${tripId}`).emit('trip:cancelled', {
  tripId,
  cancelledBy: 'customer',
  refundAmount: refundAmount,
});
```

**Location in code:**
```
server/routes.ts
├─ Line ~9612: POST /api/app/customer/cancel-trip endpoint
├─ Line ~9650: HERE → ADD PENALTY + NOTIFICATION
├─ Line ~9700: Refund logic
└─ Line ~9750: Response sent
```

---

### 6. POST /api/app/customer/trip/{id}/boost-fare (NEW ENDPOINT)

**ADD THIS NEW ENDPOINT AFTER cancel-trip:**

```typescript
// New endpoint: POST /api/app/customer/trip/:id/boost-fare
// Location: After POST /api/app/customer/cancel-trip (around line 9750)

import { boostFareOffer } from "./hardening-routes";

app.post("/api/app/customer/trip/:id/boost-fare", authenticateCustomer, async (req, res) => {
  try {
    const { id: tripId } = req.params;
    const { boostPercentage } = req.body;
    const customerId = req.userId;
    
    // Validate boost percentage (10-50%)
    if (!boostPercentage || boostPercentage < 0.1 || boostPercentage > 0.5) {
      return res.status(400).json({ error: 'Boost must be 10-50%' });
    }
    
    // ─── HARDENING: Apply boost fare ───
    const result = await boostFareOffer(tripId, customerId, boostPercentage);
    
    if (!result.success) {
      return res.status(400).json({ error: result.error });
    }
    
    // ─── Notify drivers of fare increase ───
    // Trigger re-dispatch or notify nearby drivers
    const trip = await rawDb.execute(rawSql`
      SELECT pickup_lat, pickup_lng FROM trip_requests WHERE id=${tripId}::uuid
    `);
    
    const t = trip.rows[0] as any;
    io.to(`drivers_nearby:${t.pickup_lat}:${t.pickup_lng}`).emit('trip:fare_boosted', {
      tripId,
      newFare: result.newFare,
    });
    
    return res.json({
      success: true,
      newFare: result.newFare,
      message: 'Fare boosted! More drivers will see your trip.',
    });
  } catch (e: any) {
    res.status(500).json({ error: e.message });
  }
});
```

---

## ✅ Integration Checklist

### Import Statements (Add at top of routes.ts)
```typescript
import { 
  sendNotificationWithFailsafe,
  logInfo, logWarn, logError, logCritical,
  recordNoShow,
  loadHardeningSettings,
  autoTimeoutStuckTrips,
  cleanupStaleOutstationRides,
  startHardeningJobs,
} from "./hardening";

import {
  checkBookingRateLimit,
  detectBookingFraud,
  checkCustomerBans,
  notifyCustomerWithDriver,
  setupTripTimeoutHandlers,
  validateFareAccuracy,
  notifyTripCompletion,
  recordDriverCancellation,
  recordCustomerCancellation,
  notifyTripCancellation,
  getTripStatusForCustomer,
  boostFareOffer,
} from "./hardening-routes";
```

### Changes Summary
- [ ] Import all hardening functions
- [ ] Add booking validation (rate limit, fraud, bans)
- [ ] Add driver notification after acceptance
- [ ] Setup timeout handlers on acceptance
- [ ] Validate fare accuracy on completion
- [ ] Notify customer on completion
- [ ] Record driver cancellations (no-show tracking)
- [ ] Record customer cancellations (penalty tracking)
- [ ] Notify both parties on cancellation
- [ ] Create new boost-fare endpoint
- [ ] Test all endpoints locally

### Testing Each Integration
```bash
# 1. Test booking with rate limit
curl -X POST http://localhost:5000/api/app/customer/book-ride \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"pickupLat": 17.38, "pickupLng": 78.48, ...}'

# 2. Test driver acceptance
curl -X POST http://localhost:5000/api/app/driver/accept-trip \
  -H "Authorization: Bearer $DRIVER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tripId": "..."}'

# 3. Test boost fare
curl -X POST http://localhost:5000/api/app/customer/trip/TRIP_ID/boost-fare \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"boostPercentage": 0.2}'
```

---

## 🔧 Error Handling Patterns

All integrations should follow this pattern:

```typescript
try {
  // Call hardening function
  const result = await hardeningFunction(...);
  
  // Handle success
  if (result.success) {
    // Continue with business logic
  } else {
    // Return error to client
    return res.status(400).json({ error: result.error });
  }
} catch (e: any) {
  // Log error
  await logError('ROUTE-INTEGRATION', `Failed at point: ${e.message}`, {
    userId: customerId,
    tripId,
    context: 'specific_operation',
  });
  
  // Return safe error message
  return res.status(500).json({ error: 'Internal error' });
}
```

---

## 📊 Expected Behavior After Integration

### Booking Flow
1. Rate limit checked ✓
2. Fraud detection applied ✓
3. Ban status verified ✓
4. Trip created ✓
5. Driver search initiated ✓

### Acceptance Flow
1. Trip atomically claimed ✓
2. Driver verified online (5-sec ping) ✓
3. Customer notified instantly ✓
4. Timeout handlers setup ✓
5. Socket rooms joined ✓

### Completion Flow
1. OTP verified ✓
2. Fare validated (capped at 1.5x) ✓
3. Revenue settled ✓
4. Customer notified ✓
5. Rating requested ✓

### Cancellation Flow
1. Cancel reason recorded ✓
2. No-show penalty applied (if applicable) ✓
3. Refund processed ✓
4. Both parties notified ✓
5. Trip reassigned (if driver cancelled) ✓

---

## ⚠️ Common Integration Errors

### Error: "Module not found: hardening-routes"
**Fix:** Ensure both `server/hardening.ts` and `server/hardening-routes.ts` exist and are imported correctly.

### Error: "ReferenceError: $1 is not defined"
**Fix:** Check that all variables used in `rawSql` template literals are properly defined.

### Error: "Timeout: setupTripTimeoutHandlers never completes"
**Fix:** The function should return quickly. If it's slow, move the database update to async callback.

### Error: "Customer not notified after acceptance"
**Fix:** Check that FCM token exists in `user_devices` table. Verify Firebase credentials are valid.

---

**Next Steps:**
1. Apply all integrations from this guide to routes.ts
2. Run TypeScript check: `npm run check`
3. Test each endpoint locally
4. Run real device tests
5. Commit integrated code to `Phase 2 Routes Integration` commit
