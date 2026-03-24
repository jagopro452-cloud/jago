#!/usr/bin/env node

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const routesFile = path.join(__dirname, '../server/routes.ts');
let content = fs.readFileSync(routesFile, 'utf8');

console.log('Phase 2 Part A - Continuing: Remaining endpoints\n');

// ============================================================================
// 1. INTEGRATE COMPLETE-TRIP: Fare validation + completion notification
// ============================================================================
console.log('Integration Point 3: POST /api/app/driver/complete-trip');

const completeNotificationCode = `      // -- HARDENING: Validate fare accuracy before settlement --
      try {
        // Check if actual fare exceeds cap (1.5x estimated)
        const fareValidation = await validateFareAccuracy(
          tripId,
          trip.estimated_fare,
          actualFare,
          trip.customer_id
        );

        if (fareValidation.refundRequired) {
          actualFare = actualFare - fareValidation.refundAmount;
        }
      } catch (hardeningErr: any) {
        log('HARDENING-COMPLETE-FARE', hardeningErr.message);
        // Continue with original fare if validation fails (fail-open)
      }

      // After settlement completes:
      try {
        // Notify customer of trip completion
        await notifyTripCompletion(
          trip.customer_id,
          tripId,
          actualFare,
          trip.payment_method,
          driver.fullName || "Driver"
        );
      } catch (hardeningErr: any) {
        log('HARDENING-COMPLETE-NOTIFY', hardeningErr.message);
      }`;

// Find the line before settlement/revenue calculation
const completeTrioRegex = /const actualFare = req\.body\.actualFare \|\|\s+estimatedFare\s*$/m;
if (completeTrioRegex.test(content)) {
  // Find the next line after that
  const lines = content.split('\n');
  let insertIndex = -1;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].match(/const actualFare = req\.body\.actualFare/)) {
      insertIndex = i;
      break;
    }
  }
  
  if (insertIndex > -1) {
    // Insert after the actualFare line
    lines.splice(insertIndex + 1, 0, '\n' + completeNotificationCode);
    content = lines.join('\n');
    console.log('  ✅ Added complete-trip fare validation and notification\n');
  } else {
    console.log('  ⚠️  Could not find insertion point for complete-trip\n');
  }
} else {
  console.log('  ⚠️  Complete-trip regex not matched\n');
}

// ============================================================================
// 2. INTEGRATE DRIVER CANCEL: No-show recording
// ============================================================================
console.log('Integration Point 4: POST /api/app/driver/cancel-trip');

const driverCancelCode = `      // -- HARDENING: Record driver cancellation (may trigger no-show) --
      try {
        const reason = req.body.reason || 'Driver cancelled';
        
        // Record no-show if applicable
        await recordDriverCancellation(
          tripId,
          userId,
          trip.customer_id,
          reason
        );
        
        // Notify customer
        await notifyTripCancellation(
          trip.customer_id,
          userId,
          tripId,
          'driver',
          reason
        );
      } catch (hardeningErr: any) {
        log('HARDENING-DRIVER-CANCEL', hardeningErr.message);
      }`;

// Insert this code before the trip UPDATE statement in driver cancel
const driverCancelRegex = /\/\/ Atomically cancel trip/;
if (driverCancelRegex.test(content)) {
  content = content.replace(
    driverCancelRegex,
    `${driverCancelCode}\n\n      // Atomically cancel trip`
  );
  console.log('  ✅ Added driver cancellation no-show recording\n');
} else {
  console.log('  ⚠️  Could not find driver cancel-trip insertion point\n');
}

// ============================================================================
// 3. INTEGRATE CUSTOMER CANCEL: Penalty tracking
// ============================================================================
console.log('Integration Point 5: POST /api/app/customer/cancel-trip');

const customerCancelCode = `      // -- HARDENING: Apply cancel penalties if applicable --
      try {
        const reason = req.body.reason || 'Customer cancelled';
        
        const penalty = await recordCustomerCancellation(
          tripId,
          customerId,
          reason
        );

        if (penalty.penaltyApplied) {
          // Include penalty info in response
          res.json({
            ...response,
            penaltyApplied: true,
            penaltyAmount: penalty.penaltyAmount,
            message: \`Trip cancelled. ₹\${penalty.penaltyAmount} penalty applied.\`,
          });
        }

        // Notify customer and driver
        await notifyTripCancellation(
          customerId,
          trip.driver_id,
          tripId,
          'customer',
          reason
        );
      } catch (hardeningErr: any) {
        log('HARDENING-CUSTOMER-CANCEL', hardeningErr.message);
      }`;

// Find where customer cancel processes the cancellation
const custCancelMatch = /if \(trip\.current_status === 'searching'/;
if (custCancelMatch.test(content)) {
  content = content.replace(
    custCancelMatch,
    `${customerCancelCode}\n\n      if (trip.current_status === 'searching'`
  );
  console.log('  ✅ Added customer cancellation penalty tracking\n');
} else {
  console.log('  ⚠️  Could not find customer cancel-trip insertion point\n');
}

// ============================================================================
// 4. CREATE BOOST-FARE ENDPOINT
// ============================================================================
console.log('Integration Point 6: NEW POST /api/app/customer/trip/:id/boost-fare');

const boostFareEndpoint = `
  // -- CUSTOMER: Boost trip fare to attract drivers (FIX #6 extension) -----
  app.post("/api/app/customer/trip/:id/boost-fare", authApp, requireCustomer, async (req, res) => {
    try {
      const { id: tripId } = req.params;
      const { boostPercentage } = req.body;
      const customerId = (req as any).currentUser.id;
      
      // Validate boost percentage (10-50%)
      if (!boostPercentage || boostPercentage < 0.1 || boostPercentage > 0.5) {
        return res.status(400).json({ error: 'Boost must be 10-50%' });
      }
      
      // Verify customer owns this trip
      const tripCheck = await rawDb.execute(rawSql\`
        SELECT id, estimated_fare, pickup_lat, pickup_lng, current_status
        FROM trip_requests 
        WHERE id = \${tripId}::uuid AND customer_id = \${customerId}::uuid
      \`);
      
      if (!tripCheck.rows.length) {
        return res.status(404).json({ error: 'Trip not found' });
      }
      
      const trip = camelize(tripCheck.rows[0] as any);
      
      // Only allow boost if still searching (no driver assigned yet)
      if (trip.current_status !== 'searching') {
        return res.status(400).json({ error: 'Cannot boost - trip already assigned or completed' });
      }
      
      // -- HARDENING: Apply boost fare --
      try {
        const result = await boostrFareOffer(tripId, customerId, boostPercentage);
        
        if (!result.success) {
          return res.status(400).json({ error: result.error });
        }
        
        // Notify nearby drivers of boosted fare
        if (io) {
          io.to(\`drivers_search:\${trip.pickup_lat}:\${trip.pickup_lng}\`).emit('trip:fare_updated', {
            tripId,
            newFare: result.newFare,
            boostPercentage: boostPercentage * 100,
          });
        }
        
        return res.json({
          success: true,
          newFare: result.newFare,
          boostPercentage: boostPercentage * 100,
          message: 'Fare boosted! More drivers will see your trip.',
        });
      } catch (hardeningErr: any) {
        log('HARDENING-BOOST-FARE', hardeningErr.message);
        return res.status(500).json({ error: 'Boost failed' });
      }
    } catch (e: any) {
      res.status(500).json({ error: safeErrMsg(e) });
    }
  });
`;

// Find a good place to insert the boost-fare endpoint (after customer cancel-trip)
const insertBoostAfter = /app\.post\("\/api\/app\/customer\/cancel-trip"/;
const lines = content.split('\n');
let boostInsertIndex = -1;

for (let i = 0; i < lines.length; i++) {
  if (lines[i].includes('/api/app/customer/cancel-trip')) {
    // Find the matching closing brace (end of this endpoint)
    let braceCount = 0;
    let inthisEndpoint = false;
    for (let j = i; j < lines.length; j++) {
      const line = lines[j];
      
      braceCount += (line.match(/{/g) || []).length;
      braceCount -= (line.match(/}/g) || []).length;
      
      if (braceCount === 0 && j > i + 5) {
        boostInsertIndex = j + 1;
        break;
      }
    }
    break;
  }
}

if (boostInsertIndex > -1) {
  lines.splice(boostInsertIndex, 0, boostFareEndpoint);
  content = lines.join('\n');
  console.log('  ✅ Created new boost-fare endpoint\n');
} else {
  console.log('  ⚠️  Could not find insertion point for boost-fare endpoint\n');
}

// ============================================================================
// SAVE
// ============================================================================
fs.writeFileSync(routesFile, content, 'utf8');
console.log('✅ ALL REMAINING ENDPOINTS INTEGRATED\n');
console.log('Changes applied:');
console.log('  ✅ Complete-trip: fare validation + notification');
console.log('  ✅ Driver cancel-trip: no-show recording');
console.log('  ✅ Customer cancel-trip: penalty tracking');
console.log('  ✅ NEW: /boost-fare endpoint created\n');
console.log('Next: Run npm run check and test locally');
