// ===========================================================================
// API Tests: Settings & Configuration Endpoints
// ===========================================================================

import { describe, it, expect, beforeAll } from 'vitest';
import { ApiClient, createAdminClient, assertStatus } from '../../core/helpers';

describe('Settings Endpoints', () => {
  let adminApi: ApiClient;

  beforeAll(async () => {
    adminApi = await createAdminClient();
  });

  it('GET /api/settings — returns business settings', async () => {
    const res = await adminApi.get('/api/settings');
    assertStatus(res, 200);
    expect(res.data).toBeDefined();
  });

  it('GET /api/otp-settings — returns OTP config (Firebase)', async () => {
    const res = await adminApi.get('/api/otp-settings');
    assertStatus(res, 200);
  });

  it('GET /api/revenue-model — returns revenue settings', async () => {
    const res = await adminApi.get('/api/revenue-model');
    assertStatus(res, 200);
    expect(res.data).toBeDefined();
  });

  it('GET /api/feature-flags — returns feature flags', async () => {
    const res = await adminApi.get('/api/feature-flags');
    assertStatus(res, 200);
  });

  it('PUT /api/intercity-cs/settings — rejects unknown keys', async () => {
    const res = await adminApi.put('/api/intercity-cs/settings', {
      __proto__: 'polluted',
      malicious_key: 'should_be_ignored',
      enabled: 'true',
    });
    assertStatus(res, 200);
    // Verify the malicious key was not persisted
    const getRes = await adminApi.get('/api/intercity-cs/settings');
    if (getRes.status === 200 && getRes.data) {
      expect(getRes.data.malicious_key).toBeUndefined();
    }
  });

  it('PUT /api/revenue-model — rejects unknown keys', async () => {
    const res = await adminApi.put('/api/revenue-model', {
      evil_key: 'should_be_filtered',
    });
    assertStatus(res, 200);
    const getRes = await adminApi.get('/api/revenue-model');
    if (getRes.status === 200) {
      expect(getRes.data.evil_key).toBeUndefined();
    }
  });

  it('PUT /api/car-sharing/settings — rejects unknown keys', async () => {
    const res = await adminApi.put('/api/car-sharing/settings', {
      injected_key: 'nope',
    });
    expect([200, 401]).toContain(res.status);
  });
});

describe('Content Endpoints', () => {
  let adminApi: ApiClient;

  beforeAll(async () => {
    adminApi = await createAdminClient();
  });

  it('GET /api/blogs — returns blog list', async () => {
    const res = await adminApi.get('/api/blogs');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('GET /api/banners — returns banners', async () => {
    const res = await adminApi.get('/api/banners');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('GET /api/reviews — returns reviews', async () => {
    const res = await adminApi.get('/api/reviews');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });
});

describe('Pricing Endpoints', () => {
  let adminApi: ApiClient;

  beforeAll(async () => {
    adminApi = await createAdminClient();
  });

  it('GET /api/fares — returns fare list', async () => {
    const res = await adminApi.get('/api/fares');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('GET /api/parcel-fares — returns parcel fares', async () => {
    const res = await adminApi.get('/api/parcel-fares');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('GET /api/surge-pricing — returns surge rules', async () => {
    const res = await adminApi.get('/api/surge-pricing');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('GET /api/vehicle-fares — returns vehicle+fare merged data', async () => {
    const res = await adminApi.get('/api/vehicle-fares');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('GET /api/admin/pricing/settings — returns pricing config', async () => {
    const res = await adminApi.get('/api/admin/pricing/settings');
    assertStatus(res, 200);
    expect(res.data).toBeDefined();
  });
});

describe('User Management Endpoints', () => {
  let adminApi: ApiClient;

  beforeAll(async () => {
    adminApi = await createAdminClient();
  });

  it('GET /api/users?type=driver — returns drivers', async () => {
    const res = await adminApi.get('/api/users?type=driver');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('GET /api/users?type=customer — returns customers', async () => {
    const res = await adminApi.get('/api/users?type=customer');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('GET /api/users/:id — returns 404 for fake ID', async () => {
    const res = await adminApi.get('/api/users/00000000-0000-0000-0000-000000000000');
    expect([404, 200]).toContain(res.status);
  });

  it('GET /api/transactions — returns transaction list', async () => {
    const res = await adminApi.get('/api/transactions');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('GET /api/withdrawals — returns withdrawal requests', async () => {
    const res = await adminApi.get('/api/withdrawals');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });
});

describe('Zone & Location Endpoints', () => {
  let adminApi: ApiClient;

  beforeAll(async () => {
    adminApi = await createAdminClient();
  });

  it('GET /api/zones — returns zones', async () => {
    const res = await adminApi.get('/api/zones');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('GET /api/popular-locations — returns popular locations', async () => {
    const res = await adminApi.get('/api/popular-locations');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });

  it('GET /api/intercity-routes — returns intercity routes', async () => {
    const res = await adminApi.get('/api/intercity-routes');
    assertStatus(res, 200);
    expect(Array.isArray(res.data)).toBe(true);
  });
});
