#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const routesFile = path.join(__dirname, '../server/routes.ts');
let content = fs.readFileSync(routesFile, 'utf8');

console.log('Starting Phase 2 hardening integration...\n');

// ============================================================================
// 1. CHECK IMPORTS ARE ADDED
// ============================================================================
if (!content.includes('checkBookingRateLimit')) {
  console.log('❌ Hardening imports not found in routes.ts');
  process.exit(1);
}
console.log('✅ Hardening imports verified\n');

// ============================================================================
// 2. ADD BOOKING VALIDATION (book-ride endpoint)
// ============================================================================
console.log('Integration Point 1: POST /api/app/customer/book-ride');

const bookingValidationCode = `      // -- HARDENING: Pre-booking validations --
      try {
        // Check rate limit (max 20 bookings/hour per customer)
        const rateCheck = await checkBookingRateLimit(customer.id, 20);
        if (!rateCheck.allowed) {
          return res.status(429).json({ error: rateCheck.reason, code: "RATE_LIMIT_EXCEEDED" });
        }

        // Check for fraud patterns (detects rapid same-location bookings)
        const fraudCheck = await detectBookingFraud(customer.id, validPickupCoords.lat, validPickupCoords.lng);
        if (fraudCheck.isFraudulent) {
          return res.status(400).json({ error: fraudCheck.reason, code: "FRAUD_DETECTED" });
        }

        // Check customer bans or locks
        const banCheck = await checkCustomerBans(customer.id);
        if (banCheck.banned) {
          return res.status(403).json({ 
            error: banCheck.reason, 
            code: "CUSTOMER_BANNED",
            banUntil: banCheck.until 
          });
        }
      } catch (hardeningErr: any) {
        // Log but don't block on hardening errors (fail-open)
        log.warn('HARDENING-BOOKING-VALIDATION', hardeningErr.message);
      }

      `;

// Use flexible regex to find and replace the delivery OTP section
const bookRideRegex = /const deliveryOtpVal = \(tripType === 'parcel' \|\| tripType === 'delivery'\)[^]*?\/\/ Always start as 'searching'/;
if (bookRideRegex.test(content)) {
  content = content.replace(
    bookRideRegex,
    `const deliveryOtpVal = (tripType === 'parcel' || tripType === 'delivery') ? Math.floor(1000 + Math.random() * 9000).toString() : null;

      ${bookingValidationCode}
      // Always start as 'searching'`
  );
  console.log('  ✅ Added booking validation checks\n');
} else {
  console.log('  ⚠️  Book-ride insertion point not found with standard patterns\n');
}

// ============================================================================
// 3. ADD DRIVER ACCEPTANCE NOTIFICATIONS (accept-trip endpoint)
// ============================================================================
console.log('Integration Point 2: POST /api/app/driver/accept-trip');

const acceptNotificationCode = `      // Notify dispatch engine – clears timers and notifies other drivers
      onDriverAccepted(tripId, driver.id);

      // -- HARDENING: Notify customer with driver details + setup timeouts --
      try {
        const driverName = driver.fullName || "Pilot";
        const driverPhone = driver.phone || "";
        const driverRating = driver.avgRating || 4.5;
        
        const tripData = camelize(r.rows[0]) as any;
        
        // Notify customer with multi-channel notification
        await notifyCustomerWithDriver(
          tripData.customerId,
          driver.id,
          tripData.id,
          driverName,
          driverPhone,
          driverRating
        );
        
        // Setup timeout handlers (2-min timeout if customer doesn't start ride)
        await setupTripTimeoutHandlers(tripData.id, tripData.customerId, driver.id);
      } catch (hardeningErr: any) {
        log.warn('HARDENING-ACCEPT', hardeningErr.message);
      }`;

// Look for the onDriverAccepted call and modify the following section
const acceptRegex = /onDriverAccepted\(tripId, driver\.id\);\s+const tripData = camelize\(r\.rows\[0\]\) as any;/;
if (acceptRegex.test(content)) {
  content = content.replace(acceptRegex, acceptNotificationCode);
  console.log('  ✅ Added accept-trip notifications and timeout setup\n');
} else {
  console.log('  ⚠️  Accept-trip insertion point not found\n');
}

// ============================================================================
// 4. SAVE MODIFIED FILE
// ============================================================================
fs.writeFileSync(routesFile, content, 'utf8');
console.log('✅ ROUTES.TS MODIFICATION COMPLETE\n');
console.log('Changes made:');
console.log('  1. ✅ Added hardening imports (already done via editor)');
console.log('  2. ⚠️  Booking validation (needs manual review)');
console.log('  3. ⚠️  Accept-trip notifications (needs manual review)');
console.log('\nNext steps:');
console.log('  1. Manually review PHASE_2_ROUTES_INTEGRATION.md for other endpoints');
console.log('  2. Add  notifications to complete-trip (line 8191)');
console.log('  3. Add no-show recording to driver cancel-trip');
console.log('  4. Add penalties to customer cancel-trip (line 9626)');
console.log('  5. Create new boost-fare endpoint');
console.log('  6. Run: npm run check');
console.log('  7. Test endpoints locally\n');

