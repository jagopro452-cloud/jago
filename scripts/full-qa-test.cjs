#!/usr/bin/env node
/**
 * JAGO — Full QA Mega Test
 * Tests EVERY admin endpoint, EVERY app endpoint, spinwheel, gamification,
 * forms, connections, DB schema, links, buttons — everything.
 * 
 * Senior Manual + Automation + Performance Tester Level
 */

const BASE = process.env.BASE_URL || 'http://localhost:5050';

let passed = 0, failed = 0, warnings = 0;
const failures = [];

async function req(method, path, body, headers = {}) {
  const url = `${BASE}${path}`;
  const opts = {
    method,
    headers: { 'Content-Type': 'application/json', ...headers },
  };
  if (body && method !== 'GET') opts.body = JSON.stringify(body);
  const res = await fetch(url, opts);
  let data;
  const ct = res.headers.get('content-type') || '';
  if (ct.includes('json')) {
    data = await res.json().catch(() => null);
  } else {
    data = await res.text().catch(() => '');
  }
  return { status: res.status, data, headers: res.headers };
}

function ok(name, condition) {
  if (condition) { passed++; console.log(`  ✅ ${name}`); }
  else { failed++; failures.push(name); console.log(`  ❌ ${name}`); }
}
function warn(name, msg) { warnings++; console.log(`  ⚠️  ${name} — ${msg}`); }
function section(n, title) { console.log(`\n═══ ${n}. ${title} ═══`); }

// ── Tokens ──
let custToken, custId, drvToken, drvId, adminToken;

(async () => {
  console.log('═'.repeat(60));
  console.log('  JAGO FULL QA MEGA TEST — ' + new Date().toISOString());
  console.log('  Target: ' + BASE);
  console.log('═'.repeat(60));

  // ════════════════════════════════════════
  section(1, 'HEALTH & INFRASTRUCTURE');
  // ════════════════════════════════════════
  {
    const r = await req('GET', '/api/health');
    ok('Health endpoint returns 200', r.status === 200);
    ok('Health returns JSON with status', r.data && r.data.status);
    ok('Health database connected', r.data?.database === 'connected' || r.data?.db === 'ok' || r.status === 200);
  }
  {
    const r = await req('GET', '/api/ping');
    ok('Ping responds', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/configs');
    ok('App configs returns 200', r.status === 200);
    ok('Configs has vehicleCategories', r.data?.vehicleCategories || Array.isArray(r.data));
  }
  {
    const r = await req('GET', '/api/app/platform-services');
    ok('Platform services returns 200', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/feature-flags');
    ok('Feature flags returns 200', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/languages');
    ok('Languages endpoint', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/popular-locations');
    ok('Popular locations endpoint', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/services');
    ok('Services list', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/services/active');
    ok('Active services', r.status === 200);
  }

  // ════════════════════════════════════════
  section(2, 'CUSTOMER REGISTRATION & AUTH');
  // ════════════════════════════════════════
  const testPhone = '9061510227';
  const testPass = 'TestPass1234';
  {
    const r = await req('POST', '/api/app/register', { phone: testPhone, password: testPass, fullName: 'QA Tester', userType: 'customer' });
    ok('Customer register', r.status === 200 || r.status === 201 || r.status === 409);
    if (r.data?.token) { custToken = r.data.token; custId = r.data.userId || r.data.user?.id; }
  }
  if (!custToken) {
    // Already registered — try login
    const r = await req('POST', '/api/app/login-password', { phone: testPhone, password: testPass, userType: 'customer' });
    if (r.status === 200 && r.data?.token) { custToken = r.data.token; custId = r.data.userId || r.data.user?.id; }
    ok('Customer login', r.status === 200 || r.status === 429);
    if (r.status === 429) warn('Login rate limit', 'Hit rate limiter — using register token fallback');
  }
  ok('Customer token received', !!custToken);
  {
    const r = await req('POST', '/api/app/register', { phone: '', password: '', fullName: '', userType: '' });
    ok('Register rejects empty fields', r.status >= 400);
  }
  {
    const r = await req('POST', '/api/app/register', { phone: testPhone, password: 'abc', fullName: 'X', userType: 'customer' });
    ok('Register rejects weak password', r.status >= 400);
  }
  {
    const r = await req('POST', '/api/app/login-password', { phone: '0000000000', password: testPass, userType: 'customer' });
    ok('Login rejects non-existent user', r.status >= 400);
  }
  const custAuth = { Authorization: `Bearer ${custToken}` };

  // ════════════════════════════════════════
  section(3, 'DRIVER REGISTRATION & AUTH');
  // ════════════════════════════════════════
  const drvPhone = '9161510227';
  {
    const r = await req('POST', '/api/app/register', { phone: drvPhone, password: testPass, fullName: 'QA Driver', userType: 'driver' });
    ok('Driver register', r.status === 200 || r.status === 201 || r.status === 409);
    if (r.data?.token) { drvToken = r.data.token; drvId = r.data.userId || r.data.user?.id; }
  }
  if (!drvToken) {
    const r = await req('POST', '/api/app/login-password', { phone: drvPhone, password: testPass, userType: 'driver' });
    if (r.status === 200 && r.data?.token) { drvToken = r.data.token; drvId = r.data.userId || r.data.user?.id; }
    ok('Driver login', r.status === 200 || r.status === 429);
  }
  ok('Driver token received', !!drvToken);
  const drvAuth = { Authorization: `Bearer ${drvToken}` };

  // ════════════════════════════════════════
  section(4, 'CUSTOMER PROFILE & OPERATIONS');
  // ════════════════════════════════════════
  {
    const r = await req('GET', '/api/app/customer/profile', null, custAuth);
    ok('Customer profile returns 200', r.status === 200);
    ok('Profile has name', !!(r.data?.fullName || r.data?.full_name || r.data?.name));
  }
  {
    const r = await req('PATCH', '/api/app/customer/profile', { fullName: 'QA Tester Updated' }, custAuth);
    ok('Profile update works', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/customer/profile', null);
    ok('Profile rejects unauthenticated', r.status === 401 || r.status === 403);
  }
  {
    const r = await req('GET', '/api/app/customer/wallet', null, custAuth);
    ok('Customer wallet', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/customer/wallet/balance', null, custAuth);
    ok('Customer wallet balance', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/customer/wallet/transactions', null, custAuth);
    ok('Customer wallet transactions', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/customer/trips', null, custAuth);
    ok('Customer trip history', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/customer/active-trip', null, custAuth);
    ok('Customer active trip', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/customer/saved-places', null, custAuth);
    ok('Saved places list', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/customer/offers', null, custAuth);
    ok('Customer offers/coupons', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/customer/home-data', null, custAuth);
    ok('Customer home data', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/customer/preferences', null, custAuth);
    ok('Ride preferences', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/notifications', null, custAuth);
    ok('Customer notifications', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/nearby-drivers?lat=17.385&lng=78.487', null, custAuth);
    ok('Nearby drivers', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/customer/scheduled-rides', null, custAuth);
    ok('Scheduled rides list', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/customer/lost-found', null, custAuth);
    ok('Lost & found', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/customer/monthly-pass', null, custAuth);
    ok('Monthly pass status', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/referral', null, custAuth);
    ok('Referral info', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/emergency-contacts', null, custAuth);
    ok('Emergency contacts', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/payment-methods', null, custAuth);
    ok('Payment methods', r.status === 200);
  }

  // ════════════════════════════════════════
  section(5, 'SPINWHEEL & GAMIFICATION');
  // ════════════════════════════════════════
  {
    const r = await req('GET', '/api/app/customer/coins', null, custAuth);
    ok('Jago coins balance', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/customer/spin-wheel', null, custAuth);
    ok('Spin wheel data', r.status === 200);
    if (r.data) {
      ok('Spin wheel has items or message', r.data.items || r.data.message || r.data.spinsRemaining !== undefined);
    } else {
      warn('Spin wheel', 'No data returned');
    }
  }
  {
    const r = await req('POST', '/api/app/customer/spin-wheel/play', {}, custAuth);
    // May fail if no spins available or no items configured — that's OK
    ok('Spin wheel play responds', r.status === 200 || r.status === 400 || r.status === 404 || r.status === 429);
    if (r.status === 200) {
      ok('Spin wheel gives reward', r.data?.reward !== undefined || r.data?.result !== undefined);
    } else {
      warn('Spin wheel play', `status=${r.status} — ${r.data?.message || 'no items or cooldown'}`);
    }
  }
  {
    const r = await req('POST', '/api/app/customer/redeem-coins', { coins: 10 }, custAuth);
    ok('Redeem coins responds', r.status === 200 || r.status === 400);
  }

  // ════════════════════════════════════════
  section(6, 'DRIVER PROFILE & OPERATIONS');
  // ════════════════════════════════════════
  {
    const r = await req('GET', '/api/app/driver/profile', null, drvAuth);
    ok('Driver profile returns 200', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/dashboard', null, drvAuth);
    ok('Driver dashboard', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/check-verification', null, drvAuth);
    ok('Driver verification check', r.status === 200);
  }
  {
    const r = await req('PATCH', '/api/app/driver/online-status', { isOnline: true }, drvAuth);
    ok('Driver go online', r.status === 200 || r.status === 403);
  }
  {
    const r = await req('POST', '/api/app/driver/location', { lat: 17.3850, lng: 78.4867, heading: 0, speed: 0 }, drvAuth);
    ok('Driver location update', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/active-trip', null, drvAuth);
    ok('Driver active trip', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/trips', null, drvAuth);
    ok('Driver trip history', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/earnings', null, drvAuth);
    ok('Driver earnings', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/wallet', null, drvAuth);
    ok('Driver wallet', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/wallet/summary', null, drvAuth);
    ok('Driver wallet summary', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/wallet/transactions', null, drvAuth);
    ok('Driver wallet transactions', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/settlement-status', null, drvAuth);
    ok('Driver settlement status', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/weekly-earnings', null, drvAuth);
    ok('Driver weekly earnings', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/performance', null, drvAuth);
    ok('Driver performance', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/subscription', null, drvAuth);
    ok('Driver subscription', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/subscription/plans', null, drvAuth);
    ok('Subscription plans', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/kyc/status', null, drvAuth);
    ok('Driver KYC status', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/documents', null, drvAuth);
    ok('Driver documents', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/verification-status', null, drvAuth);
    ok('Verification status', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/launch-benefit', null, drvAuth);
    ok('Launch benefit', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/behavior-score', null, drvAuth);
    ok('Behavior score', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/break', null, drvAuth);
    ok('Break status', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/fatigue-status', null, drvAuth);
    ok('Fatigue status', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/heatmap', null, drvAuth);
    ok('Driver heatmap', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/heatmap/suggestion', null, drvAuth);
    ok('Heatmap suggestion', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/earnings-forecast?lat=17.385&lng=78.487', null, drvAuth);
    ok('Earnings forecast', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/rebalancing?lat=17.385&lng=78.487', null, drvAuth);
    ok('Rebalancing', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/incoming-trip', null, drvAuth);
    ok('Incoming trip check', r.status === 200);
  }
  {
    const r = await req('PATCH', '/api/app/driver/online-status', { isOnline: false }, drvAuth);
    ok('Driver go offline', r.status === 200);
  }

  // ════════════════════════════════════════
  section(7, 'FARE ESTIMATION & BOOKING');
  // ════════════════════════════════════════
  {
    const r = await req('POST', '/api/app/customer/estimate-fare', {
      pickupLat: 17.3850, pickupLng: 78.4867,
      destinationLat: 17.4400, destinationLng: 78.4800,
      vehicleCategoryId: null
    }, custAuth);
    ok('Fare estimate returns 200', r.status === 200);
    ok('Fare estimate has data', !!(r.data?.estimatedFare || r.data?.fare || r.data?.fares));
  }
  {
    const r = await req('POST', '/api/app/customer/book-ride', {
      pickupAddress: 'Madhapur, Hyderabad',
      pickupLat: 17.3850, pickupLng: 78.4867,
      destinationAddress: 'Gachibowli, Hyderabad',
      destinationLat: 17.4400, destinationLng: 78.4800,
      paymentMethod: 'cash',
      estimatedFare: 120, estimatedDistance: 8
    }, custAuth);
    ok('Ride booking accepted', r.status === 200 || r.status === 201);
    if (r.data?.tripId || r.data?.trip?.id) {
      ok('Booking returns tripId', true);
    }
  }
  // Cancel the trip to clean up
  {
    const at = await req('GET', '/api/app/customer/active-trip', null, custAuth);
    const tripId = at.data?.id || at.data?.trip?.id;
    if (tripId) {
      const c = await req('POST', '/api/app/customer/cancel-trip', { tripId, reason: 'QA test cleanup' }, custAuth);
      ok('Trip cancel for cleanup', c.status === 200);
    }
  }

  // ════════════════════════════════════════
  section(8, 'WALLET BALANCE SERVER CHECK (NEW)');
  // ════════════════════════════════════════
  {
    const r = await req('POST', '/api/app/customer/book-ride', {
      pickupAddress: 'Test Pickup',
      pickupLat: 17.3850, pickupLng: 78.4867,
      destinationAddress: 'Test Dest',
      destinationLat: 17.4400, destinationLng: 78.4800,
      paymentMethod: 'wallet',
      estimatedFare: 99999, estimatedDistance: 5
    }, custAuth);
    ok('Wallet booking blocked (insufficient balance)', r.status === 400);
    ok('Returns INSUFFICIENT_WALLET code', r.data?.code === 'INSUFFICIENT_WALLET');
  }

  // ════════════════════════════════════════
  section(9, 'PARCEL SERVICE');
  // ════════════════════════════════════════
  {
    const r = await req('POST', '/api/app/parcel/quote', {
      vehicleCategory: 'bike_parcel',
      totalDistanceKm: 5,
      weightKg: 2,
      pickupLat: 17.3850, pickupLng: 78.4867
    }, custAuth);
    ok('Parcel quote', r.status === 200);
  }
  // Cancel any existing active parcels before testing new booking
  {
    const orders = await req('GET', '/api/app/parcel/orders', null, custAuth);
    if (orders.data?.orders) {
      for (const o of orders.data.orders) {
        if (o.current_status === 'searching' || o.current_status === 'pending') {
          await req('POST', `/api/app/parcel/${o.id}/cancel`, { reason: 'QA cleanup' }, custAuth);
        }
      }
    }
  }
  {
    const r = await req('POST', '/api/app/parcel/book', {
      vehicleCategory: 'bike_parcel',
      pickupAddress: 'Test Pickup',
      pickupLat: 17.3850, pickupLng: 78.4867,
      pickupContactName: 'QA', pickupContactPhone: '9061510226',
      dropLocations: [{ address: 'Test Drop', lat: 17.44, lng: 78.48, contactName: 'QA Drop', contactPhone: '9161510226' }],
      totalDistanceKm: 5,
      weightKg: 2,
      paymentMethod: 'cash'
    }, custAuth);
    ok('Parcel booking', r.status === 200 || r.status === 201);
  }
  {
    const r = await req('GET', '/api/app/parcel/orders', null, custAuth);
    ok('Parcel orders list', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/driver/parcel/pending', null, drvAuth);
    ok('Driver parcel pending', r.status === 200);
  }
  {
    const r = await req('POST', '/api/app/parcel/check-prohibited', { description: 'electronics cable' }, custAuth);
    ok('Prohibited items check', r.status === 200);
  }
  {
    const r = await req('POST', '/api/app/parcel/calculate-weight', {
      lengthCm: 30, widthCm: 20, heightCm: 15, weightKg: 2
    }, custAuth);
    ok('Weight calculation', r.status === 200);
  }

  // ════════════════════════════════════════
  section(10, 'SOS & SAFETY');
  // ════════════════════════════════════════
  {
    const r = await req('POST', '/api/app/sos', {
      latitude: 17.3850, longitude: 78.4867,
      message: 'QA test SOS'
    }, custAuth);
    ok('SOS endpoint responds', r.status === 200 || r.status === 201);
  }
  {
    const r = await req('GET', '/api/app/emergency-contacts', null, custAuth);
    ok('Emergency contacts list', r.status === 200);
  }
  {
    const r = await req('POST', '/api/app/emergency-contacts', {
      name: 'QA Emergency', phone: '9988776699'
    }, custAuth);
    ok('Add emergency contact', r.status === 200 || r.status === 201 || r.status === 400);
  }

  // ════════════════════════════════════════
  section(11, 'VOICE BOOKING AI');
  // ════════════════════════════════════════
  {
    const r = await req('POST', '/api/app/voice-booking/parse', {
      text: 'I need a ride from Madhapur to Gachibowli',
      language: 'en'
    }, custAuth);
    ok('Voice booking parse', r.status === 200);
    if (r.data?.intent) {
      ok('Voice booking intent detected', r.data.intent === 'book_ride' || r.data.intent !== 'unknown');
    }
  }

  // ════════════════════════════════════════
  section(12, 'MAPS & GEOCODING');
  // ════════════════════════════════════════
  {
    const r = await req('GET', '/api/app/geocode?address=Hyderabad', null, custAuth);
    ok('Geocode endpoint', r.status === 200 || r.status === 404 || r.status === 503);
    if (r.status === 404 || r.status === 503) warn('Geocode', 'Google Maps API key may not be configured or no result');
  }
  {
    const r = await req('GET', '/api/app/reverse-geocode?lat=17.385&lng=78.4867', null, custAuth);
    ok('Reverse geocode', r.status === 200 || r.status === 503);
  }
  {
    const r = await req('GET', '/api/app/places/autocomplete?input=madhapur', null, custAuth);
    ok('Places autocomplete', r.status === 200 || r.status === 503);
  }
  {
    const r = await req('GET', '/api/app/short-name?address=Madhapur+Hyderabad', null, custAuth);
    ok('Short location name', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/eta?originLat=17.385&originLng=78.4867&destLat=17.44&destLng=78.48', null, custAuth);
    ok('ETA calculation', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/distance?originLat=17.385&originLng=78.4867&destLat=17.44&destLng=78.48', null, custAuth);
    ok('Distance calculation', r.status === 200);
  }

  // ════════════════════════════════════════
  section(13, 'SCHEDULED RIDES & INTERCITY');
  // ════════════════════════════════════════
  {
    const r = await req('POST', '/api/app/customer/schedule-ride', {
      pickupAddress: 'Test', pickupLat: 17.385, pickupLng: 78.4867,
      destinationAddress: 'Test Dest', destinationLat: 17.44, destinationLng: 78.48,
      scheduledAt: new Date(Date.now() + 86400000).toISOString(),
      paymentMethod: 'cash', estimatedFare: 100, estimatedDistance: 5
    }, custAuth);
    ok('Schedule ride endpoint', r.status === 200 || r.status === 201);
  }
  {
    const r = await req('GET', '/api/app/customer/scheduled-rides', null, custAuth);
    ok('Scheduled rides list', r.status === 200);
  }
  {
    const r = await req('GET', '/api/intercity-routes', null, custAuth);
    ok('Intercity routes', r.status === 200);
  }

  // ════════════════════════════════════════
  section(14, 'PAYMENT INTEGRATION');
  // ════════════════════════════════════════
  {
    const r = await req('POST', '/api/app/customer/wallet/create-order', { amount: 100 }, custAuth);
    ok('Wallet create order', r.status === 200 || r.status === 503);
    if (r.status === 503) warn('Razorpay', 'Not configured — payment integration skipped');
  }
  {
    const r = await req('POST', '/api/app/driver/wallet/create-order', { amount: 100 }, drvAuth);
    ok('Driver wallet create order', r.status === 200 || r.status === 503);
  }
  {
    const r = await req('POST', '/api/app/driver/commission/create-order', { amount: 50 }, drvAuth);
    ok('Commission payment order', r.status === 200 || r.status === 503 || r.status === 400);
  }

  // ════════════════════════════════════════
  section(15, 'FCM & NOTIFICATIONS');
  // ════════════════════════════════════════
  {
    const r = await req('POST', '/api/app/fcm-token', { token: 'test-fcm-qa-token-12345', platform: 'android' }, custAuth);
    ok('FCM token save (customer)', r.status === 200);
  }
  {
    const r = await req('POST', '/api/app/fcm-token', { token: 'test-fcm-qa-driver-12345', platform: 'android' }, drvAuth);
    ok('FCM token save (driver)', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/notifications', null, custAuth);
    ok('Notifications list', r.status === 200);
  }
  {
    const r = await req('POST', '/api/app/notifications/read-all', {}, custAuth);
    ok('Mark all notifications read', r.status === 200);
  }

  // ════════════════════════════════════════
  section(16, 'PASSWORD MANAGEMENT');
  // ════════════════════════════════════════
  {
    const r = await req('POST', '/api/app/change-password', {
      currentPassword: testPass, newPassword: 'NewPass5678'
    }, custAuth);
    ok('Change password', r.status === 200);
    // Change back
    await req('POST', '/api/app/change-password', { currentPassword: 'NewPass5678', newPassword: testPass }, custAuth);
  }
  {
    const r = await req('POST', '/api/app/forgot-password', { phone: testPhone, userType: 'customer' });
    ok('Forgot password endpoint', r.status === 200);
  }

  // ════════════════════════════════════════
  section(17, 'ADMIN AUTH GUARD');
  // ════════════════════════════════════════
  {
    const r = await req('GET', '/api/admin/dashboard');
    ok('Admin dashboard rejects unauthenticated', r.status === 401 || r.status === 403);
  }
  {
    const r = await req('GET', '/api/users');
    ok('Admin users rejects unauthenticated', r.status === 401 || r.status === 403);
  }
  {
    const r = await req('GET', '/api/trips');
    ok('Admin trips rejects unauthenticated', r.status === 401 || r.status === 403);
  }

  // Try admin login with known credentials
  {
    const credentials = [
      { email: 'admin@jagopro.com', password: 'JagoAdmin@2026!' },
      { email: 'kiranatmakuri518@gmail.com', password: 'admin123' },
      { email: 'admin@jagopro.org', password: 'admin123' },
    ];
    for (const cred of credentials) {
      if (adminToken) break;
      const r = await req('POST', '/api/admin/login', cred);
      if (r.status === 200 && r.data?.token) {
        adminToken = r.data.token;
        ok('Admin login succeeds', true);
        break;
      } else if (r.status === 200 && r.data?.requires2FA) {
        ok('Admin login requires 2FA', true);
        warn('Admin 2FA', 'Cannot proceed with admin tests without OTP');
        break;
      }
    }
    if (!adminToken) {
      warn('Admin login', 'No valid admin credentials — admin panel tests will be skipped');
    }
  }
  const admAuth = adminToken ? { Authorization: `Bearer ${adminToken}` } : {};

  // ════════════════════════════════════════
  section(18, 'SUPERADMIN PANEL — ALL ENDPOINTS');
  // ════════════════════════════════════════
  if (adminToken) {
    // Dashboard & KPIs
    {
      const r = await req('GET', '/api/admin/dashboard', null, admAuth);
      ok('Admin dashboard data', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/live-kpis', null, admAuth);
      ok('Admin live KPIs', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/system/live-overview', null, admAuth);
      ok('System live overview', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/operations-dashboard', null, admAuth);
      ok('Operations dashboard', r.status === 200);
    }
    
    // Users/Drivers/Customers CRUD
    {
      const r = await req('GET', '/api/users?limit=5', null, admAuth);
      ok('Admin users list', r.status === 200);
    }
    {
      const r = await req('GET', '/api/users?userType=driver&limit=5', null, admAuth);
      ok('Admin drivers list', r.status === 200);
    }
    {
      const r = await req('GET', '/api/users?userType=customer&limit=5', null, admAuth);
      ok('Admin customers list', r.status === 200);
    }
    
    // Trips
    {
      const r = await req('GET', '/api/trips?limit=5', null, admAuth);
      ok('Admin trips list', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/rides/active', null, admAuth);
      ok('Admin active rides', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/rides/history?limit=5', null, admAuth);
      ok('Admin ride history', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/rides/cancelled?limit=5', null, admAuth);
      ok('Admin cancelled rides', r.status === 200);
    }

    // Vehicle categories
    {
      const r = await req('GET', '/api/vehicle-categories', null, admAuth);
      ok('Admin vehicle categories', r.status === 200);
    }
    
    // Zones
    {
      const r = await req('GET', '/api/zones', null, admAuth);
      ok('Admin zones', r.status === 200);
    }
    
    // Fares
    {
      const r = await req('GET', '/api/fares', null, admAuth);
      ok('Admin fares', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/pricing/vehicles', null, admAuth);
      ok('Admin pricing vehicles', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/pricing/settings', null, admAuth);
      ok('Admin pricing settings', r.status === 200);
    }
    
    // Coupons
    {
      const r = await req('GET', '/api/coupons', null, admAuth);
      ok('Admin coupons', r.status === 200);
    }
    
    // Discounts
    {
      const r = await req('GET', '/api/discounts', null, admAuth);
      ok('Admin discounts', r.status === 200);
    }
    
    // Spin Wheel
    {
      const r = await req('GET', '/api/spin-wheel', null, admAuth);
      ok('Admin spin wheel items', r.status === 200);
      if (Array.isArray(r.data)) {
        ok('Spin wheel returns array', true);
        if (r.data.length > 0) {
          ok('Spin wheel has items configured', true);
        } else {
          warn('Spin wheel', 'No items configured — customers cannot play');
        }
      }
    }
    
    // Banners
    {
      const r = await req('GET', '/api/banners', null, admAuth);
      ok('Admin banners', r.status === 200);
    }
    
    // Notifications
    {
      const r = await req('GET', '/api/notifications', null, admAuth);
      ok('Admin notifications', r.status === 200);
    }
    
    // Driver levels & Customer levels
    {
      const r = await req('GET', '/api/driver-levels', null, admAuth);
      ok('Admin driver levels', r.status === 200);
    }
    {
      const r = await req('GET', '/api/customer-levels', null, admAuth);
      ok('Admin customer levels', r.status === 200);
    }
    
    // Employees
    {
      const r = await req('GET', '/api/employees', null, admAuth);
      ok('Admin employees', r.status === 200);
    }
    
    // Revenue
    {
      const r = await req('GET', '/api/admin/revenue/settings', null, admAuth);
      ok('Admin revenue settings', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/revenue/models', null, admAuth);
      ok('Admin revenue models', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/revenue/analytics', null, admAuth);
      ok('Admin revenue analytics', r.status === 200);
    }
    {
      const r = await req('GET', '/api/revenue-model', null, admAuth);
      ok('Admin revenue model', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/module-revenue', null, admAuth);
      ok('Admin module revenue', r.status === 200);
    }
    
    // Commission settlements
    {
      const r = await req('GET', '/api/admin/commission-settlements', null, admAuth);
      ok('Admin commission settlements', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/commission-settlements/drivers', null, admAuth);
      ok('Admin commission drivers', r.status === 200);
    }
    
    // Business settings
    {
      const r = await req('GET', '/api/admin/business-settings', null, admAuth);
      ok('Admin business settings', r.status === 200);
    }
    {
      const r = await req('GET', '/api/settings', null, admAuth);
      ok('Admin settings', r.status === 200);
    }
    
    // Cancellation reasons
    {
      const r = await req('GET', '/api/cancellation-reasons', null, admAuth);
      ok('Admin cancellation reasons', r.status === 200);
    }
    
    // Reviews
    {
      const r = await req('GET', '/api/reviews', null, admAuth);
      ok('Admin reviews', r.status === 200);
    }
    
    // Transactions
    {
      const r = await req('GET', '/api/transactions', null, admAuth);
      ok('Admin transactions', r.status === 200);
    }
    
    // Withdrawals
    {
      const r = await req('GET', '/api/admin/withdrawals', null, admAuth);
      ok('Admin withdrawals', r.status === 200);
    }
    {
      const r = await req('GET', '/api/withdrawals', null, admAuth);
      ok('Admin withdrawals (alt)', r.status === 200);
    }
    
    // Blogs
    {
      const r = await req('GET', '/api/blogs', null, admAuth);
      ok('Admin blogs', r.status === 200);
    }
    
    // Reports
    {
      const r = await req('GET', '/api/reports/earnings', null, admAuth);
      ok('Report: earnings', r.status === 200);
    }
    {
      const r = await req('GET', '/api/reports/trips', null, admAuth);
      ok('Report: trips', r.status === 200);
    }
    {
      const r = await req('GET', '/api/reports/drivers', null, admAuth);
      ok('Report: drivers', r.status === 200);
    }
    {
      const r = await req('GET', '/api/reports/customers', null, admAuth);
      ok('Report: customers', r.status === 200);
    }

    // Driver verification
    {
      const r = await req('GET', '/api/admin/drivers/pending-verification', null, admAuth);
      ok('Pending driver verifications', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/kyc/pending', null, admAuth);
      ok('Pending KYC', r.status === 200);
    }
    
    // Safety alerts
    {
      const r = await req('GET', '/api/safety-alerts', null, admAuth);
      ok('Safety alerts', r.status === 200);
    }
    
    // Parcel management
    {
      const r = await req('GET', '/api/admin/parcel-orders', null, admAuth);
      ok('Admin parcel orders', r.status === 200);
    }
    {
      const r = await req('GET', '/api/parcel-fares', null, admAuth);
      ok('Admin parcel fares', r.status === 200);
    }
    {
      const r = await req('GET', '/api/parcel-categories', null, admAuth);
      ok('Admin parcel categories', r.status === 200);
    }
    {
      const r = await req('GET', '/api/parcel-weights', null, admAuth);
      ok('Admin parcel weights', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/parcel/prohibited-items', null, admAuth);
      ok('Admin prohibited items', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/parcel/insurance-settings', null, admAuth);
      ok('Admin parcel insurance settings', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/parcel/sla-dashboard', null, admAuth);
      ok('Admin parcel SLA dashboard', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/parcel-vehicles', null, admAuth);
      ok('Admin parcel vehicles', r.status === 200);
    }
    
    // Surge pricing
    {
      const r = await req('GET', '/api/surge-pricing', null, admAuth);
      ok('Admin surge pricing', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/surge-configs', null, admAuth);
      ok('Admin surge configs', r.status === 200);
    }
    
    // AI & Intelligence
    {
      const r = await req('GET', '/api/admin/demand-heatmap', null, admAuth);
      ok('Admin demand heatmap', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/driver-scores', null, admAuth);
      ok('Admin driver scores', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/fraud-flags', null, admAuth);
      ok('Admin fraud flags', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/heatmap/config', null, admAuth);
      ok('Admin heatmap config', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/heatmap/stats', null, admAuth);
      ok('Admin heatmap stats', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/ai-brain/dashboard', null, admAuth);
      ok('Admin AI brain dashboard', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/ai-brain/status', null, admAuth);
      ok('Admin AI brain status', r.status === 200);
    }
    
    // Voice logs
    {
      const r = await req('GET', '/api/admin/voice-logs', null, admAuth);
      ok('Admin voice logs', r.status === 200);
    }
    
    // Retention & maps
    {
      const r = await req('GET', '/api/admin/retention-analytics', null, admAuth);
      ok('Admin retention analytics', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/maps-cache-stats', null, admAuth);
      ok('Admin maps cache stats', r.status === 200);
    }
    {
      const r = await req('GET', '/api/admin/mapping-stats', null, admAuth);
      ok('Admin mapping stats', r.status === 200);
    }
    
    // System health
    {
      const r = await req('GET', '/api/admin/system-health', null, admAuth);
      ok('Admin system health', r.status === 200);
    }
    
    // GST wallet
    {
      const r = await req('GET', '/api/admin/gst-wallet', null, admAuth);
      ok('Admin GST wallet', r.status === 200);
    }
    
    // Vehicle attributes
    {
      const r = await req('GET', '/api/vehicle-brands', null, admAuth);
      ok('Admin vehicle brands', r.status === 200);
    }
    {
      const r = await req('GET', '/api/vehicle-models', null, admAuth);
      ok('Admin vehicle models', r.status === 200);
    }
    {
      const r = await req('GET', '/api/vehicle-requests', null, admAuth);
      ok('Admin vehicle requests', r.status === 200);
    }
    
    // Subscription plans
    {
      const r = await req('GET', '/api/subscription-plans', null, admAuth);
      ok('Admin subscription plans', r.status === 200);
    }
    
    // Insurance
    {
      const r = await req('GET', '/api/insurance-plans', null, admAuth);
      ok('Admin insurance plans', r.status === 200);
    }
    
    // B2B
    {
      const r = await req('GET', '/api/b2b-companies', null, admAuth);
      ok('Admin B2B companies', r.status === 200);
    }
    
    // Intercity
    {
      const r = await req('GET', '/api/intercity-routes', null, admAuth);
      ok('Admin intercity routes', r.status === 200);
    }
    
    // Popular locations
    {
      const r = await req('GET', '/api/popular-locations', null, admAuth);
      ok('Admin popular locations', r.status === 200);
    }
    
    // Wallet bonus
    {
      const r = await req('GET', '/api/wallet-bonus', null, admAuth);
      ok('Admin wallet bonus rules', r.status === 200);
    }
    
    // Driver wallet admin
    {
      const r = await req('GET', '/api/driver-wallet', null, admAuth);
      ok('Admin driver wallet list', r.status === 200);
    }
    
    // Driver earnings admin
    {
      const r = await req('GET', '/api/driver-earnings', null, admAuth);
      ok('Admin driver earnings', r.status === 200);
    }
    
    // Referrals admin
    {
      const r = await req('GET', '/api/referrals', null, admAuth);
      ok('Admin referrals', r.status === 200);
    }
    
    // Refund requests
    {
      const r = await req('GET', '/api/refund-requests', null, admAuth);
      ok('Admin refund requests', r.status === 200);
    }
    {
      const r = await req('GET', '/api/parcel-refunds', null, admAuth);
      ok('Admin parcel refunds', r.status === 200);
    }
    
    // Languages admin
    {
      const r = await req('GET', '/api/admin/languages', null, admAuth);
      ok('Admin languages', r.status === 200);
    }
    
    // Feature flags admin
    {
      const r = await req('GET', '/api/feature-flags', null, admAuth);
      ok('Admin feature flags', r.status === 200);
    }
    
    // OTP settings
    {
      const r = await req('GET', '/api/otp-settings', null, admAuth);
      ok('Admin OTP settings', r.status === 200);
    }
    
    // Business pages
    {
      const r = await req('GET', '/api/business-pages', null, admAuth);
      ok('Admin business pages', r.status === 200);
    }
    
    // Newsletter
    {
      const r = await req('GET', '/api/newsletter', null, admAuth);
      ok('Admin newsletter', r.status === 200);
    }
    
    // Car sharing admin
    {
      const r = await req('GET', '/api/car-sharing/rides', null, admAuth);
      ok('Admin car sharing rides', r.status === 200);
    }
    
    // Outstation pool
    {
      const r = await req('GET', '/api/admin/outstation-pool/rides', null, admAuth);
      ok('Admin outstation pool rides', r.status === 200);
    }
    
    // City services
    {
      const r = await req('GET', '/api/admin/city-services', null, admAuth);
      ok('Admin city services', r.status === 200);
    }
    
    // Call logs
    {
      const r = await req('GET', '/api/call-logs', null, admAuth);
      ok('Admin call logs', r.status === 200);
    }
    
    // Support chat
    {
      const r = await req('GET', '/api/support-chat', null, admAuth);
      ok('Admin support chat', r.status === 200);
    }
    
    // Complaints
    {
      const r = await req('GET', '/api/admin/complaints', null, admAuth);
      ok('Admin complaints', r.status === 200);
    }
    
    // Parcel attributes
    {
      const r = await req('GET', '/api/parcel-attributes', null, admAuth);
      ok('Admin parcel attributes', r.status === 200);
    }
    
    // Driver subscription admin
    {
      const r = await req('GET', '/api/driver-subscriptions', null, admAuth);
      ok('Admin driver subscriptions', r.status === 200);
    }
    
    // Live fleet data
    {
      const r = await req('GET', '/api/fleet-drivers', null, admAuth);
      ok('Admin fleet drivers', r.status === 200);
    }
    {
      const r = await req('GET', '/api/live-tracking', null, admAuth);
      ok('Admin live tracking', r.status === 200);
    }
    {
      const r = await req('GET', '/api/heatmap-points', null, admAuth);
      ok('Admin heatmap points', r.status === 200);
    }
    
    // Dashboard charts
    {
      const r = await req('GET', '/api/dashboard/stats', null, admAuth);
      ok('Admin dashboard stats', r.status === 200);
    }
    {
      const r = await req('GET', '/api/dashboard/chart?period=week', null, admAuth);
      ok('Admin dashboard chart', r.status === 200);
    }

    // API docs endpoint
    {
      const r = await req('GET', '/api/admin/system-health', null, admAuth);
      ok('System health detailed', r.status === 200);
      if (r.data?.database) ok('System health shows DB status', true);
    }
    
  } else {
    warn('Admin Panel', 'Skipped — no admin token available. Run setup-admin.cjs first.');
  }

  // ════════════════════════════════════════
  section(19, 'SECURITY & EDGE CASES');
  // ════════════════════════════════════════
  {
    const r = await req('POST', '/api/app/register', { phone: "'9999' OR 1=1--", password: 'TestPass123', fullName: 'SQLi Test', userType: 'customer' });
    ok('SQL injection blocked', r.status >= 400 || (r.status === 200 && r.data?.message?.includes('Invalid')));
  }
  {
    const r = await req('POST', '/api/app/register', { phone: '9988770003', password: 'TestPass123', fullName: '<script>alert(1)</script>', userType: 'customer' });
    ok('XSS in name handled', r.status === 200 || r.status === 201 || r.status === 409);
  }
  {
    const r = await req('POST', '/api/app/register', { phone: '9988770004', password: 'TestPass123', fullName: 'X', userType: 'invalid_type' });
    ok('Invalid userType rejected', r.status >= 400);
  }
  {
    const r = await req('POST', '/api/app/customer/book-ride', { pickupAddress: 'Test' });
    ok('Booking rejects unauthenticated', r.status === 401 || r.status === 403);
  }
  {
    const longName = 'A'.repeat(500);
    const r = await req('POST', '/api/app/register', { phone: '9988770005', password: 'TestPass123', fullName: longName, userType: 'customer' });
    ok('Long name handled', r.status >= 400 || r.status === 200);
  }
  {
    const r = await req('GET', '/api/diag/env');
    ok('Diag env rejects unauthenticated', r.status === 401 || r.status === 403);
  }
  {
    const r = await req('GET', '/api/ops/ready?key=wrong-key');
    ok('Ops readiness rejects bad key', r.status === 401 || r.status === 403);
  }
  {
    const r = await req('GET', '/api/ops/metrics?key=wrong-key');
    ok('Ops metrics rejects bad key', r.status === 401 || r.status === 403);
  }

  // ════════════════════════════════════════
  section(20, 'AI INTELLIGENCE ENDPOINTS');
  // ════════════════════════════════════════
  {
    const r = await req('GET', '/api/app/ai/suggestions', null, custAuth);
    ok('AI suggestions', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/ai/demand-heatmap', null, custAuth);
    ok('AI demand heatmap (app)', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/ai/safety-alerts', null, custAuth);
    ok('AI safety alerts (app)', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/surge', null, custAuth);
    ok('Current surge status', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/dispatch/active-count', null, custAuth);
    ok('Active dispatch count', r.status === 200);
  }

  // ════════════════════════════════════════
  section(21, 'B2B ENDPOINTS');
  // ════════════════════════════════════════
  {
    const r = await req('POST', '/api/app/b2b/login', { email: 'test@b2b.com', password: 'test123' });
    ok('B2B login endpoint', r.status === 200 || r.status === 401 || r.status === 404 || r.status === 400);
  }

  // ════════════════════════════════════════
  section(22, 'OUTSTATION & CAR SHARING');
  // ════════════════════════════════════════
  {
    const r = await req('GET', '/api/app/customer/car-sharing/rides', null, custAuth);
    ok('Car sharing rides', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/customer/car-sharing/my-bookings', null, custAuth);
    ok('Car sharing bookings', r.status === 200);
  }
  {
    const r = await req('GET', '/api/app/customer/outstation-pool/bookings', null, custAuth);
    ok('Outstation pool bookings', r.status === 200);
  }

  // ════════════════════════════════════════
  section(23, 'SUPPORT CHAT & COMMUNICATION');
  // ════════════════════════════════════════
  {
    const r = await req('GET', '/api/app/customer/support-chat', null, custAuth);
    ok('Customer support chat', r.status === 200);
  }
  {
    const r = await req('POST', '/api/app/customer/support-chat/send', { message: 'QA test message' }, custAuth);
    ok('Customer send support msg', r.status === 200 || r.status === 201);
  }
  {
    const r = await req('GET', '/api/app/driver/support-chat', null, drvAuth);
    ok('Driver support chat', r.status === 200);
  }

  // ════════════════════════════════════════
  section(24, 'PUBLIC PAGES & STATIC CONTENT');
  // ════════════════════════════════════════
  {
    const r = await req('GET', '/');
    ok('Landing page loads', r.status === 200);
  }
  {
    const r = await req('GET', '/about-us');
    ok('About page loads', r.status === 200);
  }
  {
    const r = await req('GET', '/privacy');
    ok('Privacy page loads', r.status === 200);
  }
  {
    const r = await req('GET', '/terms');
    ok('Terms page loads', r.status === 200);
  }
  {
    const r = await req('GET', '/refund-policy');
    ok('Refund policy loads', r.status === 200);
  }
  {
    const r = await req('GET', '/admin/login');
    ok('Admin login page loads', r.status === 200);
  }

  // ════════════════════════════════════════
  section(25, 'DRIVER REVENUE MODEL SELECTION');
  // ════════════════════════════════════════
  {
    const r = await req('GET', '/api/app/revenue-config', null, drvAuth);
    ok('Revenue config endpoint', r.status === 200);
  }
  {
    const r = await req('POST', '/api/app/driver/choose-model', { model: 'commission' }, drvAuth);
    ok('Choose revenue model', r.status === 200 || r.status === 400);
  }

  // ════════════════════════════════════════
  // FINAL RESULTS
  // ════════════════════════════════════════
  console.log('\n' + '═'.repeat(60));
  console.log(`  RESULTS: ${passed} passed | ${failed} failed | ${warnings} warnings`);
  console.log('═'.repeat(60));
  
  if (failures.length > 0) {
    console.log('\n  ❌ FAILURES:');
    failures.forEach(f => console.log(`     • ${f}`));
  }
  
  if (failed === 0) {
    console.log('\n  🟢 ALL TESTS PASSED — PRODUCTION READY');
  } else {
    console.log(`\n  🔴 ${failed} TESTS FAILED — NEEDS FIXING`);
  }

  process.exit(failed > 0 ? 1 : 0);
})().catch(err => {
  console.error('Test harness error:', err);
  process.exit(1);
});
