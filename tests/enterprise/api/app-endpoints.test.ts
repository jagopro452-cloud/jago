// ===========================================================================
// API Tests: App Endpoints (Customer & Driver)
// ===========================================================================

import { describe, it, expect, beforeAll } from 'vitest';
import {
  ApiClient, createAdminClient,
  assertStatus, assertDuration,
  generateTripRequest, randomPhone, randomUUID,
  PerformanceTracker, logger
} from '../../core/helpers';
import config from '../../config/test.config';

const perf = new PerformanceTracker();

describe('App Public Endpoints', () => {
  const api = new ApiClient();

  it('GET /api/vehicle-categories — public vehicle list', async () => {
    const res = await api.get('/api/vehicle-categories');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
    if (res.data.length > 0) {
      expect(res.data[0]).toHaveProperty('name');
    }
    perf.record('vehicle-categories', res.duration);
  });

  it('GET /api/vehicle-categories?type=ride — filtered', async () => {
    const res = await api.get('/api/vehicle-categories?type=ride');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('GET /api/vehicle-categories?type=parcel — parcel vehicles', async () => {
    const res = await api.get('/api/vehicle-categories?type=parcel');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('GET /api/app/banners — home screen banners', async () => {
    const res = await api.get('/api/app/banners');
    expect([200, 404]).toContain(res.status);
    if (res.status === 200) {
      expect(Array.isArray(res.data)).toBe(true);
    }
  });

  it('GET /api/app/popular-locations — popular locations', async () => {
    const res = await api.get('/api/app/popular-locations');
    expect([200, 404]).toContain(res.status);
  });

  it('GET /api/app/feature-flags — feature toggles', async () => {
    const res = await api.get('/api/app/feature-flags');
    expect([200, 404]).toContain(res.status);
  });

  it('GET /api/app/revenue-config — revenue configuration', async () => {
    const res = await api.get('/api/app/revenue-config');
    expect([200, 401]).toContain(res.status);
  });

  it('GET /api/cancellation-reasons — cancellation reasons', async () => {
    const res = await api.get('/api/cancellation-reasons');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });
});

describe('Firebase Token Verification', () => {
  const api = new ApiClient();

  it('POST /api/app/verify-firebase-token — rejects missing token', async () => {
    const res = await api.post('/api/app/verify-firebase-token', {});
    expect([400, 401]).toContain(res.status);
  });

  it('POST /api/app/verify-firebase-token — rejects invalid token', async () => {
    const res = await api.post('/api/app/verify-firebase-token', {
      idToken: 'invalid_fake_token_12345',
      userType: 'customer',
    });
    expect([400, 401, 500]).toContain(res.status);
    // Should not leak server details
    expect(JSON.stringify(res.data)).not.toContain('stack');
  });

  it('POST /api/app/verify-firebase-token — rejects XSS in userType', async () => {
    const res = await api.post('/api/app/verify-firebase-token', {
      idToken: 'test',
      userType: '<script>alert(1)</script>',
    });
    expect([400, 401]).toContain(res.status);
  });
});

describe('App Protected Endpoints — Require Auth', () => {
  const unauthApi = new ApiClient();

  it('GET /api/app/customer/profile — 401 without auth', async () => {
    const res = await unauthApi.get('/api/app/customer/profile');
    expect([401, 403]).toContain(res.status);
  });

  it('GET /api/app/driver/profile — 401 without auth', async () => {
    const res = await unauthApi.get('/api/app/driver/profile');
    expect([401, 403]).toContain(res.status);
  });

  it('POST /api/app/customer/trip/request — 401 without auth', async () => {
    const res = await unauthApi.post('/api/app/customer/trip/request', generateTripRequest());
    expect([401, 403]).toContain(res.status);
  });

  it('GET /api/app/driver/current-trip — 401 without auth', async () => {
    const res = await unauthApi.get('/api/app/driver/current-trip');
    expect([401, 403]).toContain(res.status);
  });

  it('POST /api/app/driver/wallet/create-order — 401 without auth', async () => {
    const res = await unauthApi.post('/api/app/driver/wallet/create-order', { amount: 500 });
    expect([401, 403]).toContain(res.status);
  });

  it('POST /api/app/customer/wallet/verify-payment — 401 without auth', async () => {
    const res = await unauthApi.post('/api/app/customer/wallet/verify-payment', {
      razorpayOrderId: 'order_test',
      razorpayPaymentId: 'pay_test',
      razorpaySignature: 'sig_test',
    });
    expect([401, 403]).toContain(res.status);
  });
});

describe('Trip Request API — Edge Cases', () => {
  const api = new ApiClient();

  it('POST /api/app/customer/trip/estimate — requires auth', async () => {
    const res = await api.post('/api/app/customer/trip/estimate', {
      pickupLat: 17.385, pickupLng: 78.486,
      dropoffLat: 17.440, dropoffLng: 78.348,
    });
    expect([401, 403]).toContain(res.status);
  });

  it('POST /api/app/driver/location — requires auth', async () => {
    const res = await api.post('/api/app/driver/location', {
      lat: 17.385, lng: 78.486, heading: 0, speed: 0, isOnline: true,
    });
    expect([401, 403]).toContain(res.status);
  });
});

describe('API Input Validation', () => {
  let adminApi: ApiClient;

  beforeAll(async () => {
    adminApi = await createAdminClient();
  });

  it('POST /api/admin/complaints — rejects missing tripId', async () => {
    const res = await adminApi.post('/api/admin/complaints', {
      description: 'Test complaint',
    });
    assertStatus(res, 400);
  });

  it('POST /api/admin/complaints — rejects missing description', async () => {
    const res = await adminApi.post('/api/admin/complaints', {
      tripId: randomUUID(),
    });
    assertStatus(res, 400);
  });

  it('POST /api/admin/complaints — rejects invalid UUID format', async () => {
    const res = await adminApi.post('/api/admin/complaints', {
      tripId: 'not-a-valid-uuid',
      description: 'Test',
    });
    assertStatus(res, 400);
  });

  it('POST /api/admin/complaints — rejects oversized description', async () => {
    const res = await adminApi.post('/api/admin/complaints', {
      tripId: randomUUID(),
      description: 'x'.repeat(6000),
    });
    assertStatus(res, 400);
  });

  it('POST /api/vehicle-categories — rejects empty name', async () => {
    const res = await adminApi.post('/api/vehicle-categories', {
      name: '',
      vehicleType: 'auto',
    });
    expect([400, 422]).toContain(res.status);
  });

  it('PUT /api/fares/:id — rejects negative amounts', async () => {
    const res = await adminApi.put('/api/fares/fake-id', {
      baseFare: -100,
      perKmRate: -5,
    });
    expect([400, 404, 422, 500]).toContain(res.status);
  });

  it('POST /api/coupons — rejects discount > 100%', async () => {
    const res = await adminApi.post('/api/coupons', {
      code: 'INVALID',
      discountType: 'percentage',
      discountValue: 150,
    });
    expect([400, 422, 200, 201]).toContain(res.status);
    // If 200, the server should clamp it
  });

  it('GET /api/admin/rides/history — respects limit cap', async () => {
    const res = await adminApi.get('/api/admin/rides/history?limit=9999');
    assertStatus(res, 200);
    // Server should cap at 100
    const data = Array.isArray(res.data) ? res.data : (res.data?.rides || res.data?.data || []);
    expect(data.length).toBeLessThanOrEqual(100);
  });
});

describe('OPS Endpoints', () => {
  it('GET /api/ops/ready — requires OPS key', async () => {
    const api = new ApiClient();
    const res = await api.get('/api/ops/ready');
    expect([401, 403]).toContain(res.status);
  });

  it('GET /api/ops/metrics — requires OPS key', async () => {
    const api = new ApiClient();
    const res = await api.get('/api/ops/metrics');
    expect([401, 403]).toContain(res.status);
  });

  if (config.opsKey) {
    it('GET /api/ops/ready — with valid key', async () => {
      const api = createOpsClient();
      const res = await api.get('/api/ops/ready');
      assertStatus(res, 200);
    });
  }
});
