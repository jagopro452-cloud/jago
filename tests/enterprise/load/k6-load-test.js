// ===========================================================================
// k6 Load Test — JagoPro Platform
// Simulates 10K concurrent users across all critical paths
// ===========================================================================
// Usage: k6 run tests/enterprise/load/k6-load-test.js
// With options: k6 run --vus 1000 --duration 5m tests/enterprise/load/k6-load-test.js

import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend, Counter } from 'k6/metrics';

// ── Custom Metrics ──────────────────────────────────────────────────────────
const errorRate = new Rate('errors');
const loginDuration = new Trend('login_duration', true);
const dashboardDuration = new Trend('dashboard_duration', true);
const vehicleCategoriesDuration = new Trend('vehicle_categories_duration', true);
const healthDuration = new Trend('health_duration', true);
const activeRidesDuration = new Trend('active_rides_duration', true);
const fleetDriversDuration = new Trend('fleet_drivers_duration', true);
const statsDuration = new Trend('stats_duration', true);
const apiCalls = new Counter('api_calls');

// ── Configuration ───────────────────────────────────────────────────────────
const BASE_URL = __ENV.TEST_BASE_URL || 'http://localhost:5000';
const ADMIN_EMAIL = __ENV.TEST_ADMIN_EMAIL || 'kiranatmakuri518@gmail.com';
const ADMIN_PASSWORD = __ENV.TEST_ADMIN_PASSWORD || 'admin123';

export const options = {
  // ── Scenario: Ramp to 10K users ─────────────────────────────────────────
  scenarios: {
    // Smoke test: quick validation
    smoke: {
      executor: 'constant-vus',
      vus: 5,
      duration: '30s',
      startTime: '0s',
      tags: { test_type: 'smoke' },
    },

    // Load test: gradual ramp-up
    load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 100 },    // Warm up
        { duration: '3m', target: 500 },    // Normal load
        { duration: '3m', target: 1000 },   // Peak load
        { duration: '2m', target: 2000 },   // High load
        { duration: '1m', target: 500 },    // Cool down
        { duration: '30s', target: 0 },     // Ramp down
      ],
      startTime: '30s',
      tags: { test_type: 'load' },
    },

    // Stress test: push to breaking point
    stress: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 3000 },
        { duration: '3m', target: 5000 },
        { duration: '2m', target: 8000 },
        { duration: '2m', target: 10000 },   // 10K target
        { duration: '1m', target: 0 },
      ],
      startTime: '11m',
      tags: { test_type: 'stress' },
    },

    // Spike test: sudden burst
    spike: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '10s', target: 5000 },  // Instant spike
        { duration: '1m', target: 5000 },   // Hold
        { duration: '10s', target: 0 },     // Drop
      ],
      startTime: '22m',
      tags: { test_type: 'spike' },
    },
  },

  // ── Thresholds ──────────────────────────────────────────────────────────
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<2000'],     // 95th < 500ms, 99th < 2s
    http_req_failed: ['rate<0.01'],                      // <1% error rate
    errors: ['rate<0.05'],                               // <5% app errors
    login_duration: ['p(95)<1000'],                       // Login < 1s p95
    dashboard_duration: ['p(95)<2000'],                   // Dashboard < 2s p95
    vehicle_categories_duration: ['p(95)<500'],            // Vehicles < 500ms p95
    health_duration: ['p(95)<200'],                        // Health < 200ms p95
  },
};

// ── Helper: Admin Login ─────────────────────────────────────────────────────
function adminLogin() {
  const payload = JSON.stringify({
    email: ADMIN_EMAIL,
    password: ADMIN_PASSWORD,
  });

  const res = http.post(`${BASE_URL}/api/admin/login`, payload, {
    headers: { 'Content-Type': 'application/json' },
    tags: { name: 'admin_login' },
  });

  loginDuration.add(res.timings.duration);
  apiCalls.add(1);

  check(res, {
    'login: status 200': (r) => r.status === 200,
    'login: has token': (r) => {
      try { return !!JSON.parse(r.body).token; } catch { return false; }
    },
  }) || errorRate.add(1);

  try {
    return JSON.parse(res.body).token;
  } catch {
    return null;
  }
}

// ── Helper: Authenticated GET ───────────────────────────────────────────────
function authGet(token, path, metric, checkName) {
  const res = http.get(`${BASE_URL}${path}`, {
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    tags: { name: checkName },
  });

  if (metric) metric.add(res.timings.duration);
  apiCalls.add(1);

  check(res, {
    [`${checkName}: status 200`]: (r) => r.status === 200,
    [`${checkName}: body not empty`]: (r) => r.body && r.body.length > 2,
  }) || errorRate.add(1);

  return res;
}

// ── Helper: Public GET ──────────────────────────────────────────────────────
function publicGet(path, metric, checkName) {
  const res = http.get(`${BASE_URL}${path}`, {
    headers: { 'Content-Type': 'application/json' },
    tags: { name: checkName },
  });

  if (metric) metric.add(res.timings.duration);
  apiCalls.add(1);

  check(res, {
    [`${checkName}: status 200`]: (r) => r.status === 200,
  }) || errorRate.add(1);

  return res;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MAIN TEST FUNCTION
// ═══════════════════════════════════════════════════════════════════════════════

export default function () {
  // Each VU simulates a mixed user journey

  // ── 1. Health Check (all users hit this) ────────────────────────────────
  group('Health Check', () => {
    publicGet('/api/health', healthDuration, 'health');
  });

  sleep(0.5);

  // ── 2. Public Endpoints (customer app simulation) ───────────────────────
  group('Customer App — Public Data', () => {
    publicGet('/api/vehicle-categories', vehicleCategoriesDuration, 'vehicle_categories');
    sleep(0.3);
    publicGet('/api/app/banners', null, 'banners');
    sleep(0.3);
    publicGet('/api/cancellation-reasons', null, 'cancellation_reasons');
    sleep(0.3);
    publicGet('/api/app/popular-locations', null, 'popular_locations');
  });

  sleep(0.5);

  // ── 3. Admin Panel Simulation (20% of VUs) ─────────────────────────────
  if (__VU % 5 === 0) {
    group('Admin Panel', () => {
      const token = adminLogin();
      if (!token) return;

      sleep(0.5);
      authGet(token, '/api/admin/dashboard', dashboardDuration, 'dashboard');
      sleep(0.3);
      authGet(token, '/api/admin/rides/active', activeRidesDuration, 'active_rides');
      sleep(0.3);
      authGet(token, '/api/fleet-drivers', fleetDriversDuration, 'fleet_drivers');
      sleep(0.3);
      authGet(token, '/api/dashboard/stats', statsDuration, 'stats');
      sleep(0.3);
      authGet(token, '/api/admin/live-kpis', null, 'live_kpis');
      sleep(0.3);
      authGet(token, '/api/vehicle-categories', null, 'admin_vehicles');
      sleep(0.3);
      authGet(token, '/api/fares', null, 'fares');
      sleep(0.3);
      authGet(token, '/api/coupons', null, 'coupons');
      sleep(0.3);
      authGet(token, '/api/admin/complaints', null, 'complaints');
      sleep(0.3);
      authGet(token, '/api/transactions', null, 'transactions');
    });
  }

  // ── 4. Driver App Simulation (30% of VUs) ──────────────────────────────
  if (__VU % 3 === 0) {
    group('Driver App — Location Updates', () => {
      // Simulate driver sending location (unauthenticated — will get 401 which is expected)
      const locationPayload = JSON.stringify({
        lat: 17.385 + (Math.random() * 0.1 - 0.05),
        lng: 78.486 + (Math.random() * 0.1 - 0.05),
        heading: Math.random() * 360,
        speed: Math.random() * 60,
        isOnline: true,
      });

      const res = http.post(`${BASE_URL}/api/app/driver/location`, locationPayload, {
        headers: { 'Content-Type': 'application/json' },
        tags: { name: 'driver_location' },
      });
      apiCalls.add(1);

      // 401 is expected (no auth token in load test) — we measure latency
      check(res, {
        'driver_location: responds quickly': (r) => r.timings.duration < 1000,
      });
    });
  }

  sleep(1 + Math.random() * 2); // Random think time 1-3s
}

// ═══════════════════════════════════════════════════════════════════════════════
//  LIFECYCLE HOOKS
// ═══════════════════════════════════════════════════════════════════════════════

export function setup() {
  // Pre-flight health check
  const res = http.get(`${BASE_URL}/api/health`);
  if (res.status !== 200) {
    throw new Error(`Server not healthy: ${res.status}`);
  }
  console.log(`✓ Server healthy at ${BASE_URL}`);
  return { baseUrl: BASE_URL };
}

export function teardown(data) {
  console.log(`✓ Load test complete against ${data.baseUrl}`);
}

export function handleSummary(data) {
  return {
    'tests/enterprise/reports/k6/summary.json': JSON.stringify(data, null, 2),
    stdout: textSummary(data, { indent: '  ', enableColors: true }),
  };
}

// k6 built-in: textSummary is available in the k6 runtime
function textSummary(data, opts) {
  // Fallback: return JSON if textSummary not available
  try {
    const { textSummary: ts } = require('https://jslib.k6.io/k6-summary/0.0.1/index.js');
    return ts(data, opts);
  } catch {
    return JSON.stringify(data.metrics, null, 2);
  }
}
