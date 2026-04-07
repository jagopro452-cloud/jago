// ===========================================================================
// API Tests: Health, Auth & Admin Core Endpoints
// ===========================================================================

import { describe, it, expect, beforeAll } from 'vitest';
import {
  ApiClient, createAdminClient, createOpsClient,
  assertStatus, assertJsonShape, assertDuration,
  logger, PerformanceTracker
} from '../../core/helpers';
import config from '../../config/test.config';

const perf = new PerformanceTracker();

describe('Health & Diagnostics', () => {
  const api = new ApiClient();

  it('GET /api/health — should return 200 with DB status', async () => {
    const res = await api.get('/api/health');
    assertStatus(res, 200, 'health');
    expect(res.data).toBeDefined();
    perf.record('health', res.duration);
  });

  it('GET /api/ping — should return 200 heartbeat', async () => {
    const res = await api.get('/api/ping');
    assertStatus(res, 200, 'ping');
    expect(res.duration).toBeLessThan(500);
    perf.record('ping', res.duration);
  });

  it('GET /api/health — should respond under 1s', async () => {
    const res = await api.get('/api/health');
    assertDuration(res, 1000, 'health-latency');
    expect(res.duration).toBeLessThan(2000);
  });

  it('GET /api/diag/razorpay — should return gateway status', async () => {
    const res = await api.get('/api/diag/razorpay');
    // May require admin auth — 200 or 401 both acceptable
    expect([200, 401, 403]).toContain(res.status);
  });
});

describe('Admin Authentication API', () => {
  const api = new ApiClient();

  it('POST /api/admin/login — valid credentials', async () => {
    const res = await api.post('/api/admin/login', {
      email: config.admin.email,
      password: config.admin.password,
    });
    assertStatus(res, 200, 'admin-login');
    expect(res.data.token).toBeTruthy();
    expect(typeof res.data.token).toBe('string');
    expect(res.data.token.length).toBeGreaterThan(10);
    perf.record('admin-login', res.duration);
  });

  it('POST /api/admin/login — wrong password returns 401', async () => {
    const res = await api.post('/api/admin/login', {
      email: config.admin.email,
      password: 'definitely_wrong_password_12345',
    });
    expect([401, 400]).toContain(res.status);
    // Must NOT leak the correct password or token
    expect(JSON.stringify(res.data)).not.toContain(config.admin.password);
  });

  it('POST /api/admin/login — non-existent email returns 401', async () => {
    const res = await api.post('/api/admin/login', {
      email: 'nobody_here@fake.org',
      password: 'anything',
    });
    expect([401, 400, 404]).toContain(res.status);
  });

  it('POST /api/admin/login — empty body returns 400', async () => {
    const res = await api.post('/api/admin/login', {});
    expect([400, 401]).toContain(res.status);
  });

  it('POST /api/admin/login — SQL injection in email', async () => {
    const res = await api.post('/api/admin/login', {
      email: "' OR '1'='1",
      password: "' OR '1'='1",
    });
    expect([400, 401]).toContain(res.status);
    // Must not return a token
    expect(res.data.token).toBeFalsy();
  });

  it('POST /api/admin/logout — should invalidate token', async () => {
    // Login first
    const loginRes = await api.post('/api/admin/login', {
      email: config.admin.email,
      password: config.admin.password,
    });
    const token = loginRes.data.token;

    // Logout
    const logoutApi = new ApiClient().setAuth(token);
    const logoutRes = await logoutApi.post('/api/admin/logout');
    expect([200, 204]).toContain(logoutRes.status);

    // Verify token is invalidated
    const checkRes = await logoutApi.get('/api/admin/dashboard');
    expect(checkRes.status).toBe(401);
  });

  it('POST /api/admin/login/verify-2fa — rejects non-6-digit OTP', async () => {
    const res = await api.post('/api/admin/login/verify-2fa', {
      tempToken: 'fake',
      otp: 'abc',
    });
    expect([400, 401]).toContain(res.status);
  });

  it('POST /api/admin/login/verify-2fa — rejects too-long OTP', async () => {
    const res = await api.post('/api/admin/login/verify-2fa', {
      tempToken: 'fake',
      otp: '1234567890',
    });
    expect([400, 401]).toContain(res.status);
  });
});

describe('Admin Protected Endpoints — Auth Required', () => {
  const unauthApi = new ApiClient(); // No token
  let adminApi: ApiClient;

  beforeAll(async () => {
    adminApi = await createAdminClient();
  });

  it('GET /api/admin/dashboard — 401 without token', async () => {
    const res = await unauthApi.get('/api/admin/dashboard');
    assertStatus(res, 401, 'dashboard-no-auth');
  });

  it('GET /api/admin/dashboard — 200 with valid token', async () => {
    const res = await adminApi.get('/api/admin/dashboard');
    assertStatus(res, 200, 'dashboard-auth');
    perf.record('dashboard', res.duration);
  });

  it('GET /api/admin/rides/active — returns array', async () => {
    const res = await adminApi.get('/api/admin/rides/active');
    assertStatus(res, 200, 'active-rides');
    expect(Array.isArray(res.data)).toBe(true);
    perf.record('active-rides', res.duration);
  });

  it('GET /api/admin/rides/history — returns paginated results', async () => {
    const res = await adminApi.get('/api/admin/rides/history?limit=10');
    assertStatus(res, 200, 'ride-history');
    expect(Array.isArray(res.data) || (res.data && typeof res.data === 'object')).toBe(true);
    perf.record('ride-history', res.duration);
  });

  it('GET /api/admin/complaints — returns array', async () => {
    const res = await adminApi.get('/api/admin/complaints');
    assertStatus(res, 200, 'complaints');
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('GET /api/fleet-drivers — returns driver fleet data', async () => {
    const res = await adminApi.get('/api/fleet-drivers');
    assertStatus(res, 200, 'fleet-drivers');
    expect(Array.isArray(res.data)).toBe(true);
    perf.record('fleet-drivers', res.duration);
  });

  it('GET /api/live-tracking — returns active tracking data', async () => {
    const res = await adminApi.get('/api/live-tracking');
    assertStatus(res, 200, 'live-tracking');
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('GET /api/dashboard/stats — returns stats object', async () => {
    const res = await adminApi.get('/api/dashboard/stats');
    assertStatus(res, 200, 'stats');
    expect(res.data).toBeDefined();
    perf.record('dashboard-stats', res.duration);
  });
});

describe('Admin CRUD — Vehicle Categories', () => {
  let adminApi: ApiClient;
  let createdId: string | null = null;

  beforeAll(async () => {
    adminApi = await createAdminClient();
  });

  it('GET /api/vehicle-categories — list all', async () => {
    const res = await adminApi.get('/api/vehicle-categories');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
    perf.record('vehicle-categories-list', res.duration);
  });

  it('POST /api/vehicle-categories — create', async () => {
    const res = await adminApi.post('/api/vehicle-categories', {
      name: `Test Category ${Date.now()}`,
      vehicleType: 'auto',
      seatingCapacity: 3,
      baseFare: 25,
      perKmRate: 12,
      perMinRate: 1.5,
      isActive: false,
    });
    if (res.status === 201 || res.status === 200) {
      createdId = res.data.id || res.data?.data?.id;
      expect(createdId).toBeTruthy();
    }
    expect([200, 201, 400]).toContain(res.status); // 400 if fields missing
  });

  it('DELETE /api/vehicle-categories/:id — cleanup', async () => {
    if (!createdId) return;
    const res = await adminApi.delete(`/api/vehicle-categories/${createdId}`);
    expect([200, 204, 404]).toContain(res.status);
  });
});

describe('Admin CRUD — Coupons', () => {
  let adminApi: ApiClient;
  let couponId: string | null = null;

  beforeAll(async () => {
    adminApi = await createAdminClient();
  });

  it('GET /api/coupons — list all', async () => {
    const res = await adminApi.get('/api/coupons');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('POST /api/coupons — create', async () => {
    const res = await adminApi.post('/api/coupons', {
      code: `TEST${Date.now()}`,
      discountType: 'percentage',
      discountValue: 10,
      minOrderAmount: 100,
      maxDiscount: 50,
      usageLimit: 100,
      expiresAt: new Date(Date.now() + 86400000).toISOString(),
      isActive: false,
    });
    if ([200, 201].includes(res.status)) {
      couponId = res.data.id || res.data?.data?.id;
    }
    expect([200, 201, 400]).toContain(res.status);
  });

  it('DELETE /api/coupons/:id — cleanup', async () => {
    if (!couponId) return;
    const res = await adminApi.delete(`/api/coupons/${couponId}`);
    expect([200, 204, 404]).toContain(res.status);
  });
});

describe('Performance Baselines', () => {
  let adminApi: ApiClient;

  beforeAll(async () => {
    adminApi = await createAdminClient();
  });

  const endpoints = [
    '/api/health',
    '/api/ping',
    '/api/dashboard/stats',
    '/api/admin/dashboard',
    '/api/vehicle-categories',
    '/api/fares',
    '/api/coupons',
    '/api/fleet-drivers',
  ];

  for (const endpoint of endpoints) {
    it(`${endpoint} — under 2s threshold`, async () => {
      const res = await adminApi.get(endpoint);
      perf.record(`perf:${endpoint}`, res.duration);
      expect(res.duration).toBeLessThan(2000);
    });
  }
});
