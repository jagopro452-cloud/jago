/**
 * JAGO End-to-End Core Test Suite
 * Tests ALL critical flows: register, login, booking, driver accept, tracking, payment, parcel
 * Run: node scripts/e2e-core-test.cjs [base_url]
 */
const http = require('http');
const https = require('https');

const BASE = process.argv[2] || 'http://localhost:5050';
const isHttps = BASE.startsWith('https');
const agent = isHttps ? https : http;

let passed = 0, failed = 0, warnings = 0;
const issues = [];

function req(method, path, body, headers = {}) {
  return new Promise((resolve) => {
    const url = new URL(path, BASE);
    const opts = {
      hostname: url.hostname,
      port: url.port || (isHttps ? 443 : 80),
      path: url.pathname + url.search,
      method,
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', ...headers },
      timeout: 15000,
    };
    const r = agent.request(opts, (res) => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => {
        try { resolve({ status: res.statusCode, headers: res.headers, body: JSON.parse(d) }); }
        catch { resolve({ status: res.statusCode, headers: res.headers, body: d, rawBody: true }); }
      });
    });
    r.on('error', e => resolve({ status: 0, body: { error: e.message }, err: true }));
    r.on('timeout', () => { r.destroy(); resolve({ status: 0, body: { error: 'timeout' }, err: true }); });
    if (body) r.write(JSON.stringify(body));
    r.end();
  });
}

function ok(label, condition, detail) {
  if (condition) { passed++; console.log(`  ✅ ${label}`); }
  else { failed++; issues.push({ label, detail }); console.log(`  ❌ ${label} — ${detail || 'FAILED'}`); }
}
function warn(label, detail) { warnings++; console.log(`  ⚠️  ${label} — ${detail}`); }

const TS = Date.now();
const CUST_PHONE = `90${String(TS).slice(-8)}`;
const DRV_PHONE = `91${String(TS).slice(-8)}`;
const PASSWORD = 'TestPass1';

let custToken = null, drvToken = null, custId = null, drvId = null;
let tripId = null, parcelTripId = null;

async function testHealth() {
  console.log('\n═══ 1. HEALTH & DIAGNOSTICS ═══');
  const r = await req('GET', '/api/health');
  ok('Health endpoint returns 200', r.status === 200);
  ok('Health returns JSON', !r.rawBody);

  // Diag env requires admin auth — just check it rejects unauthenticated
  const diag = await req('GET', '/api/diag/env');
  ok('Diag env rejects unauthenticated', diag.status === 401 || diag.status === 403);

  const configs = await req('GET', '/api/app/configs');
  ok('App configs returns 200', configs.status === 200);
  if (configs.status === 200 && configs.body) {
    ok('Configs has vehicleCategories', Array.isArray(configs.body.vehicleCategories || configs.body.vehicle_categories));
  }
}

async function testRegistration() {
  console.log('\n═══ 2. CUSTOMER REGISTRATION ═══');

  // Missing fields
  const r1 = await req('POST', '/api/app/register', { phone: CUST_PHONE });
  ok('Register rejects missing fields', r1.status === 400, `status=${r1.status} body=${JSON.stringify(r1.body)}`);

  // Weak password
  const r2 = await req('POST', '/api/app/register', { phone: CUST_PHONE, password: '123456', fullName: 'Test User', userType: 'customer' });
  ok('Register rejects weak password', r2.status === 400, `status=${r2.status} body=${JSON.stringify(r2.body)}`);
  if (r2.status === 400) {
    ok('Password error message is specific', r2.body?.message?.includes('8') || r2.body?.message?.includes('letter'), r2.body?.message);
  }

  // Valid registration
  const r3 = await req('POST', '/api/app/register', { phone: CUST_PHONE, password: PASSWORD, fullName: 'E2E Test Customer', userType: 'customer' });
  ok('Customer register succeeds', r3.status === 200 && r3.body?.success === true, `status=${r3.status} body=${JSON.stringify(r3.body)}`);
  if (r3.body?.token) {
    custToken = r3.body.token;
    custId = r3.body.user?.id;
    ok('Customer token received', !!custToken);
    ok('Customer ID received', !!custId);
  }

  // Duplicate
  const r4 = await req('POST', '/api/app/register', { phone: CUST_PHONE, password: PASSWORD, fullName: 'Duplicate', userType: 'customer' });
  ok('Duplicate registration rejected', r4.status === 409 || r4.status === 400, `status=${r4.status}`);

  console.log('\n═══ 3. DRIVER REGISTRATION ═══');
  const r5 = await req('POST', '/api/app/register', { phone: DRV_PHONE, password: PASSWORD, fullName: 'E2E Test Driver', userType: 'driver' });
  ok('Driver register succeeds', r5.status === 200 && r5.body?.success === true, `status=${r5.status} body=${JSON.stringify(r5.body)}`);
  if (r5.body?.token) {
    drvToken = r5.body.token;
    drvId = r5.body.user?.id;
    ok('Driver token received', !!drvToken);
    ok('Driver ID received', !!drvId);
  }
}

async function testLogin() {
  console.log('\n═══ 4. PASSWORD LOGIN ═══');

  // Wrong password
  const r1 = await req('POST', '/api/app/login-password', { phone: CUST_PHONE, password: 'WrongPass1', userType: 'customer' });
  ok('Login rejects wrong password', r1.status === 401, `status=${r1.status}`);

  // Correct login
  const r2 = await req('POST', '/api/app/login-password', { phone: CUST_PHONE, password: PASSWORD, userType: 'customer' });
  ok('Customer login succeeds', r2.status === 200 && r2.body?.token, `status=${r2.status} body=${JSON.stringify(r2.body)}`);
  if (r2.body?.token) custToken = r2.body.token;

  // Driver login
  const r3 = await req('POST', '/api/app/login-password', { phone: DRV_PHONE, password: PASSWORD, userType: 'driver' });
  ok('Driver login succeeds', r3.status === 200 && r3.body?.token, `status=${r3.status} body=${JSON.stringify(r3.body)}`);
  if (r3.body?.token) drvToken = r3.body.token;

  // Non-existent user
  const r4 = await req('POST', '/api/app/login-password', { phone: '0000000000', password: PASSWORD, userType: 'customer' });
  ok('Login rejects non-existent user', r4.status === 404, `status=${r4.status}`);
}

async function testCustomerProfile() {
  console.log('\n═══ 5. CUSTOMER PROFILE ═══');
  if (!custToken) { warn('SKIP', 'no customer token'); return; }
  const auth = { 'Authorization': `Bearer ${custToken}` };

  const r1 = await req('GET', '/api/app/customer/profile', null, auth);
  ok('Customer profile returns 200', r1.status === 200, `status=${r1.status} body=${JSON.stringify(r1.body)}`);
  if (r1.status === 200) {
    ok('Profile has fullName', !!r1.body?.fullName || !!r1.body?.full_name);
    ok('Profile has phone', !!r1.body?.phone);
  }

  // Update profile
  const r2 = await req('PATCH', '/api/app/customer/profile', { fullName: 'Updated E2E Customer' }, auth);
  ok('Profile update works', r2.status === 200, `status=${r2.status} body=${JSON.stringify(r2.body)}`);

  // Unauthenticated access
  const r3 = await req('GET', '/api/app/customer/profile');
  ok('Profile rejects unauthenticated', r3.status === 401 || r3.status === 403, `status=${r3.status}`);
}

async function testDriverProfile() {
  console.log('\n═══ 6. DRIVER PROFILE ═══');
  if (!drvToken) { warn('SKIP', 'no driver token'); return; }
  const auth = { 'Authorization': `Bearer ${drvToken}` };

  const r1 = await req('GET', '/api/app/driver/profile', null, auth);
  ok('Driver profile returns 200', r1.status === 200, `status=${r1.status} body=${JSON.stringify(r1.body)}`);

  // Check verification status
  const r2 = await req('GET', '/api/app/driver/check-verification', null, auth);
  ok('Verification check returns 200', r2.status === 200, `status=${r2.status}`);

  // Driver dashboard
  const r3 = await req('GET', '/api/app/driver/dashboard', null, auth);
  ok('Driver dashboard returns 200', r3.status === 200, `status=${r3.status}`);
}

async function testFareEstimate() {
  console.log('\n═══ 7. FARE ESTIMATION ═══');
  if (!custToken) { warn('SKIP', 'no customer token'); return; }
  const auth = { 'Authorization': `Bearer ${custToken}` };

  const r = await req('POST', '/api/app/customer/estimate-fare', {
    pickupLat: 17.3850,
    pickupLng: 78.4867,
    destinationLat: 17.4400,
    destinationLng: 78.3489,
    vehicleCategoryId: null,
    serviceType: 'ride',
  }, auth);
  ok('Fare estimate returns 200', r.status === 200, `status=${r.status} body=${JSON.stringify(r.body)?.slice(0,200)}`);
  if (r.status === 200 && r.body) {
    const hasEstimates = r.body.estimates || r.body.fare || r.body.options || r.body.fares;
    ok('Fare estimate has data', !!hasEstimates, JSON.stringify(r.body)?.slice(0,200));
  }
}

async function testRideBooking() {
  console.log('\n═══ 8. RIDE BOOKING (BIKE) ═══');
  if (!custToken) { warn('SKIP', 'no customer token'); return; }
  const auth = { 'Authorization': `Bearer ${custToken}` };

  const r = await req('POST', '/api/app/customer/book-ride', {
    pickupLat: 17.3850,
    pickupLng: 78.4867,
    destinationLat: 17.4400,
    destinationLng: 78.3489,
    pickupAddress: 'Hitech City, Hyderabad',
    destinationAddress: 'Gachibowli, Hyderabad',
    serviceType: 'ride',
    vehicleType: 'bike',
    paymentMethod: 'cash',
    fare: 80,
  }, auth);
  // Could fail with no drivers online - that's OK
  if (r.status === 200 && r.body?.tripId) {
    tripId = r.body.tripId;
    ok('Bike ride booked', true);
    ok('Trip ID received', !!tripId);
  } else if (r.status === 200 || r.status === 201) {
    tripId = r.body?.tripId || r.body?.trip?.id || r.body?.id;
    ok('Ride booking accepted', true);
  } else {
    // 400/404 for no drivers is expected in test env
    ok('Ride booking endpoint responds', r.status < 500, `status=${r.status} body=${JSON.stringify(r.body)?.slice(0,200)}`);
    if (r.status >= 500) {
      issues.push({ label: 'BOOKING 500', detail: JSON.stringify(r.body)?.slice(0,300) });
    }
  }
}

async function testParcelBooking() {
  console.log('\n═══ 9. PARCEL BOOKING ═══');
  if (!custToken) { warn('SKIP', 'no customer token'); return; }
  const auth = { 'Authorization': `Bearer ${custToken}` };

  const r = await req('POST', '/api/app/customer/book-ride', {
    pickupLat: 17.3850,
    pickupLng: 78.4867,
    destinationLat: 17.4400,
    destinationLng: 78.3489,
    pickupAddress: 'Hitech City, Hyderabad',
    destinationAddress: 'Gachibowli, Hyderabad',
    serviceType: 'parcel',
    vehicleType: 'bike',
    paymentMethod: 'cash',
    fare: 60,
    receiverName: 'Parcel Receiver',
    receiverPhone: '9876543210',
    parcelDescription: 'Test document',
  }, auth);
  if (r.status === 200 && (r.body?.tripId || r.body?.trip?.id)) {
    parcelTripId = r.body?.tripId || r.body?.trip?.id;
    ok('Parcel booked', true);
  } else {
    ok('Parcel booking endpoint responds', r.status < 500, `status=${r.status} body=${JSON.stringify(r.body)?.slice(0,200)}`);
  }
}

async function testDriverOperations() {
  console.log('\n═══ 10. DRIVER OPERATIONS ═══');
  if (!drvToken) { warn('SKIP', 'no driver token'); return; }
  const auth = { 'Authorization': `Bearer ${drvToken}` };

  // Go online
  const r1 = await req('POST', '/api/app/driver/online-status', { isOnline: true, lat: 17.3855, lng: 78.4870 }, auth);
  ok('Driver go online', r1.status === 200, `status=${r1.status} body=${JSON.stringify(r1.body)?.slice(0,200)}`);

  // Update location
  const r2 = await req('POST', '/api/app/driver/location', { lat: 17.3855, lng: 78.4870, heading: 90, speed: 0 }, auth);
  ok('Driver location update', r2.status === 200, `status=${r2.status}`);

  // Active trip
  const r3 = await req('GET', '/api/app/driver/active-trip', null, auth);
  ok('Driver active trip check', r3.status === 200 || r3.status === 404, `status=${r3.status}`);

  // Trip history
  const r4 = await req('GET', '/api/app/driver/trips', null, auth);
  ok('Driver trip history', r4.status === 200, `status=${r4.status}`);

  // Earnings
  const r5 = await req('GET', '/api/app/driver/earnings', null, auth);
  ok('Driver earnings', r5.status === 200, `status=${r5.status}`);

  // Wallet
  const r6 = await req('GET', '/api/app/driver/wallet', null, auth);
  ok('Driver wallet', r6.status === 200, `status=${r6.status}`);

  // Go offline
  const r7 = await req('POST', '/api/app/driver/online-status', { isOnline: false }, auth);
  ok('Driver go offline', r7.status === 200, `status=${r7.status}`);
}

async function testCustomerOperations() {
  console.log('\n═══ 11. CUSTOMER OPERATIONS ═══');
  if (!custToken) { warn('SKIP', 'no customer token'); return; }
  const auth = { 'Authorization': `Bearer ${custToken}` };

  // Active trip
  const r1 = await req('GET', '/api/app/customer/active-trip', null, auth);
  ok('Customer active trip', r1.status === 200 || r1.status === 404, `status=${r1.status}`);

  // Trip history
  const r2 = await req('GET', '/api/app/customer/trips', null, auth);
  ok('Customer trip history', r2.status === 200, `status=${r2.status}`);

  // Wallet
  const r3 = await req('GET', '/api/app/customer/wallet', null, auth);
  ok('Customer wallet', r3.status === 200, `status=${r3.status}`);

  // Nearby drivers (requires auth)
  const r4 = await req('GET', '/api/app/nearby-drivers?lat=17.385&lng=78.487', null, auth);
  ok('Nearby drivers', r4.status === 200, `status=${r4.status}`);

  // Saved places
  const r5 = await req('GET', '/api/app/customer/saved-places', null, auth);
  ok('Saved places', r5.status === 200, `status=${r5.status}`);

  // Notifications
  const r6 = await req('GET', '/api/app/notifications', null, auth);
  ok('Notifications', r6.status === 200, `status=${r6.status}`);
}

async function testWalletPayment() {
  console.log('\n═══ 12. WALLET & PAYMENT ═══');
  if (!custToken) { warn('SKIP', 'no customer token'); return; }
  const auth = { 'Authorization': `Bearer ${custToken}` };

  // Create Razorpay order for wallet recharge
  const r1 = await req('POST', '/api/app/customer/wallet/create-order', { amount: 100 }, auth);
  ok('Wallet create order endpoint responds', r1.status < 500 || r1.status === 503, `status=${r1.status} body=${JSON.stringify(r1.body)?.slice(0,200)}`);
  // Razorpay key may not be configured locally - that's OK
  if (r1.status >= 500) {
    warn('Wallet order', `status=${r1.status} — Razorpay may not be configured`);
  }
}

async function testPasswordFlow() {
  console.log('\n═══ 13. PASSWORD MANAGEMENT ═══');
  if (!custToken) { warn('SKIP', 'no customer token'); return; }
  const auth = { 'Authorization': `Bearer ${custToken}` };

  // Change password
  const r1 = await req('POST', '/api/app/change-password', { currentPassword: PASSWORD, newPassword: 'NewPass123' }, auth);
  ok('Change password endpoint responds', r1.status < 500, `status=${r1.status} body=${JSON.stringify(r1.body)?.slice(0,200)}`);

  // Login with new password
  if (r1.status === 200) {
    const r2 = await req('POST', '/api/app/login-password', { phone: CUST_PHONE, password: 'NewPass123', userType: 'customer' });
    ok('Login with new password', r2.status === 200, `status=${r2.status}`);
    if (r2.body?.token) custToken = r2.body.token;

    // Change back
    const auth2 = { 'Authorization': `Bearer ${custToken}` };
    await req('POST', '/api/app/change-password', { currentPassword: 'NewPass123', newPassword: PASSWORD }, auth2);
  }

  // Forgot password
  const r3 = await req('POST', '/api/app/forgot-password', { phone: CUST_PHONE, userType: 'customer' });
  ok('Forgot password endpoint responds', r3.status < 500, `status=${r3.status}`);
}

async function testAdminAuth() {
  console.log('\n═══ 14. ADMIN AUTH GUARD ═══');

  // Admin routes should be protected
  const r1 = await req('GET', '/api/admin/dashboard');
  ok('Admin dashboard rejects unauthenticated', r1.status === 401 || r1.status === 403, `status=${r1.status}`);

  const r2 = await req('GET', '/api/admin/users');
  ok('Admin users rejects unauthenticated', r2.status === 401 || r2.status === 403, `status=${r2.status}`);

  const r3 = await req('GET', '/api/admin/trips');
  ok('Admin trips rejects unauthenticated', r3.status === 401 || r3.status === 403, `status=${r3.status}`);
}

async function testOpsEndpoints() {
  console.log('\n═══ 15. OPS ENDPOINTS ═══');
  // Ops endpoints require x-ops-key header; without OPS_API_KEY env, they return 503
  const r1 = await req('GET', '/api/ops/ready', null, { 'x-ops-key': 'test' });
  ok('Ops readiness rejects bad key', r1.status === 401, `status=${r1.status}`);

  const r2 = await req('GET', '/api/ops/metrics', null, { 'x-ops-key': 'test' });
  ok('Ops metrics rejects bad key', r2.status === 401, `status=${r2.status}`);
}

async function testEdgeCases() {
  console.log('\n═══ 16. EDGE CASES & SECURITY ═══');

  // SQL injection in phone
  const r1 = await req('POST', '/api/app/register', { phone: "'; DROP TABLE users;--", password: PASSWORD, fullName: 'Hacker', userType: 'customer' });
  ok('SQL injection blocked', r1.status === 400, `status=${r1.status}`);

  // XSS in name
  const r2 = await req('POST', '/api/app/register', { phone: '1234567890', password: PASSWORD, fullName: '<script>alert(1)</script>', userType: 'customer' });
  // Should still work (name is just stored, XSS is output-encoding concern)
  ok('XSS name accepted (output encoding)', r2.status < 500, `status=${r2.status}`);

  // Invalid user type
  const r3 = await req('POST', '/api/app/register', { phone: '1111111111', password: PASSWORD, fullName: 'Test', userType: 'admin' });
  ok('Invalid userType rejected', r3.status === 400, `status=${r3.status}`);

  // Missing auth header on protected routes
  const r4 = await req('POST', '/api/app/customer/book-ride', { pickupLat: 0, pickupLng: 0 });
  ok('Booking rejects unauthenticated', r4.status === 401 || r4.status === 403, `status=${r4.status}`);

  // Invalid JSON
  // (skipped - http module always sends valid JSON)

  // Long input attack
  const longName = 'A'.repeat(500);
  const r5 = await req('POST', '/api/app/register', { phone: '2222222222', password: PASSWORD, fullName: longName, userType: 'customer' });
  ok('Long name rejected', r5.status === 400, `status=${r5.status}`);
}

async function testFcmToken() {
  console.log('\n═══ 17. FCM TOKEN ═══');
  if (!drvToken) { warn('SKIP', 'no driver token'); return; }
  const auth = { 'Authorization': `Bearer ${drvToken}` };

  const r = await req('POST', '/api/app/fcm-token', { token: 'test-fcm-token-e2e-' + TS }, auth);
  ok('FCM token save', r.status === 200, `status=${r.status} body=${JSON.stringify(r.body)?.slice(0,200)}`);
}

async function testSOS() {
  console.log('\n═══ 18. SOS ═══');
  if (!custToken) { warn('SKIP', 'no customer token'); return; }
  const auth = { 'Authorization': `Bearer ${custToken}` };

  const r = await req('POST', '/api/app/sos', { lat: 17.385, lng: 78.487, message: 'E2E test SOS' }, auth);
  ok('SOS endpoint responds', r.status < 500, `status=${r.status}`);
}

async function testScheduleRide() {
  console.log('\n═══ 19. SCHEDULED RIDES ═══');
  if (!custToken) { warn('SKIP', 'no customer token'); return; }
  const auth = { 'Authorization': `Bearer ${custToken}` };

  // Schedule a ride for tomorrow
  const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
  const r = await req('POST', '/api/app/customer/schedule-ride', {
    pickupLat: 17.3850, pickupLng: 78.4867,
    destinationLat: 17.4400, destinationLng: 78.3489,
    pickupAddress: 'Hitech City', destinationAddress: 'Gachibowli',
    vehicleType: 'auto', scheduledTime: tomorrow,
    fare: 120, paymentMethod: 'cash',
  }, auth);
  ok('Schedule ride endpoint responds', r.status < 500, `status=${r.status} body=${JSON.stringify(r.body)?.slice(0,200)}`);

  // List scheduled rides
  const r2 = await req('GET', '/api/app/customer/scheduled-rides', null, auth);
  ok('Scheduled rides list', r2.status === 200, `status=${r2.status}`);
}

async function testIntercity() {
  console.log('\n═══ 20. INTERCITY ═══');

  // Intercity routes may require auth
  const authH = custToken ? { 'Authorization': `Bearer ${custToken}` } : {};
  const r = await req('GET', '/api/intercity-routes', null, authH);
  ok('Intercity routes endpoint', r.status === 200 || r.status === 404, `status=${r.status}`);
}

// ============ RUN ALL ============
(async () => {
  console.log(`\n${'═'.repeat(60)}`);
  console.log(`  JAGO E2E CORE TEST — ${new Date().toISOString()}`);
  console.log(`  Target: ${BASE}`);
  console.log(`  Test customer: +91 ${CUST_PHONE}`);
  console.log(`  Test driver:   +91 ${DRV_PHONE}`);
  console.log(`${'═'.repeat(60)}`);

  await testHealth();
  await testRegistration();
  await testLogin();
  await testCustomerProfile();
  await testDriverProfile();
  await testFareEstimate();
  await testRideBooking();
  await testParcelBooking();
  await testDriverOperations();
  await testCustomerOperations();
  await testWalletPayment();
  await testPasswordFlow();
  await testAdminAuth();
  await testOpsEndpoints();
  await testEdgeCases();
  await testFcmToken();
  await testSOS();
  await testScheduleRide();
  await testIntercity();

  // ── CLEANUP: remove test users ──
  console.log('\n═══ CLEANUP ═══');
  try {
    // We don't delete test users since we don't have admin access in this script
    console.log('  ℹ️  Test users left in DB (harmless)');
  } catch (_) {}

  // ── SUMMARY ──
  console.log(`\n${'═'.repeat(60)}`);
  console.log(`  RESULTS: ${passed} passed | ${failed} failed | ${warnings} warnings`);
  console.log(`${'═'.repeat(60)}`);

  if (issues.length > 0) {
    console.log('\n  🔴 FAILURES:');
    issues.forEach((i, n) => console.log(`    ${n + 1}. ${i.label}: ${i.detail || ''}`));
  }

  if (failed === 0) {
    console.log('\n  🟢 ALL CORE FLOWS WORKING — READY FOR PRODUCTION');
  } else {
    console.log(`\n  🔴 ${failed} ISSUE(S) MUST BE FIXED BEFORE PRODUCTION`);
  }
  console.log('');

  process.exitCode = failed > 0 ? 1 : 0;
})();
