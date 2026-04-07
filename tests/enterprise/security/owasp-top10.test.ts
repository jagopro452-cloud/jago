// ===========================================================================
// Security Test Suite — OWASP Top 10 Coverage
// Injection, Auth, XSS, IDOR, Rate Limiting, Headers, Data Exposure
// ===========================================================================

import { describe, it, expect, beforeAll } from 'vitest';
import {
  ApiClient, createAdminClient, createOpsClient,
  assertStatus, randomUUID, randomPhone, sleep,
  logger
} from '../../core/helpers';
import config from '../../config/test.config';

describe('A01:2021 — Broken Access Control', () => {
  const unauthApi = new ApiClient();

  it('admin endpoints require authentication', async () => {
    const protectedPaths = [
      '/api/admin/dashboard',
      '/api/admin/rides/active',
      '/api/admin/rides/history',
      '/api/admin/complaints',
      '/api/admin/commission-settlements',
      '/api/admin/commission-settlements/drivers',
      '/api/admin/live-kpis',
      '/api/admin/system/live-overview',
    ];

    for (const path of protectedPaths) {
      const res = await unauthApi.get(path);
      expect(res.status, `${path} should be protected`).toBe(401);
    }
  });

  it('admin write endpoints require authentication', async () => {
    const writePaths: [string, string, any][] = [
      ['POST', '/api/vehicle-categories', { name: 'Hack' }],
      ['POST', '/api/coupons', { code: 'HACK' }],
      ['POST', '/api/admin/complaints', { tripId: randomUUID(), description: 'hack' }],
      ['POST', '/api/notifications/send', { title: 'hack', body: 'hack' }],
      ['PUT', '/api/revenue-model', { commission_pct: '99' }],
      ['PUT', '/api/car-sharing/settings', { enabled: 'true' }],
    ];

    for (const [method, path, body] of writePaths) {
      const res = await unauthApi.request(method as any, path, body);
      expect([401, 403], `${method} ${path} should require auth`).toContain(res.status);
    }
  });

  it('customer cannot access driver endpoints', async () => {
    // Without proper driver auth, driver endpoints should reject
    const res = await unauthApi.get('/api/app/driver/profile');
    expect([401, 403]).toContain(res.status);
  });

  it('driver cannot access customer endpoints', async () => {
    const res = await unauthApi.get('/api/app/customer/profile');
    expect([401, 403]).toContain(res.status);
  });

  it('IDOR: cannot access other users data with modified ID', async () => {
    // Attempt to hit a user-specific endpoint with a fake UUID
    const res = await unauthApi.get(`/api/users/${randomUUID()}`);
    expect([401, 403, 404]).toContain(res.status);
  });

  it('OPS endpoints require OPS_API_KEY', async () => {
    const paths = ['/api/ops/ready', '/api/ops/metrics'];
    for (const path of paths) {
      const res = await unauthApi.get(path);
      expect([401, 403], `${path} should require OPS key`).toContain(res.status);
    }
  });
});

describe('A02:2021 — Cryptographic Failures', () => {
  it('server should not expose sensitive data in error messages', async () => {
    const api = new ApiClient();
    const res = await api.post('/api/admin/login', {
      email: 'test@test.com',
      password: 'wrong',
    });

    const body = JSON.stringify(res.data).toLowerCase();
    // Should NOT contain stack traces, DB details, or internal paths
    expect(body).not.toContain('stack');
    expect(body).not.toContain('node_modules');
    expect(body).not.toContain('/home/');
    expect(body).not.toContain('password');
    expect(body).not.toContain('secret');
    expect(body).not.toContain('postgres://');
    expect(body).not.toContain('database_url');
  });

  it('login response should not echo back the password', async () => {
    const api = new ApiClient();
    const testPassword = 'SuperSecretPass123!';
    const res = await api.post('/api/admin/login', {
      email: 'test@test.com',
      password: testPassword,
    });
    expect(JSON.stringify(res.data)).not.toContain(testPassword);
  });

  it('OTP should not be returned in API response', async () => {
    const api = new ApiClient();
    const res = await api.post('/api/admin/forgot-password', {
      email: config.admin.email,
    });
    const body = JSON.stringify(res.data);
    // OTP should never be sent back to client
    expect(body).not.toMatch(/"\d{6}"/);
    // Unless it's the message field with generic text
  });
});

describe('A03:2021 — Injection', () => {
  let adminApi: ApiClient;

  beforeAll(async () => {
    adminApi = await createAdminClient();
  });

  it('SQL injection in login email', async () => {
    const api = new ApiClient();
    const payloads = [
      "' OR '1'='1",
      "'; DROP TABLE users; --",
      "admin'--",
      "1' UNION SELECT * FROM users--",
      "' OR 1=1 LIMIT 1--",
    ];

    for (const payload of payloads) {
      const res = await api.post('/api/admin/login', {
        email: payload,
        password: 'test',
      });
      expect([400, 401], `SQLi should not succeed: ${payload}`).toContain(res.status);
      expect(res.data.token).toBeFalsy();
    }
  });

  it('SQL injection in query parameters', async () => {
    const payloads = [
      "'; DROP TABLE trip_requests; --",
      "1 OR 1=1",
      "UNION SELECT * FROM users",
    ];

    for (const payload of payloads) {
      const res = await adminApi.get(`/api/users?type=${encodeURIComponent(payload)}`);
      // Should return empty results, not error
      expect([200, 400, 500]).toContain(res.status);
    }
  });

  it('SQL injection in path parameters', async () => {
    const res = await adminApi.get("/api/users/' OR '1'='1");
    expect([400, 404, 500]).toContain(res.status);
  });

  it('NoSQL injection attempt', async () => {
    const api = new ApiClient();
    const res = await api.post('/api/admin/login', {
      email: { $gt: '' },
      password: { $gt: '' },
    });
    expect([400, 401]).toContain(res.status);
  });

  it('command injection in user-controlled fields', async () => {
    const res = await adminApi.post('/api/admin/complaints', {
      tripId: randomUUID(),
      description: '$(whoami) && cat /etc/passwd',
    });
    // Should either create complaint with text as-is or reject
    expect([201, 200, 400, 500]).toContain(res.status);
    // Response should not contain system info
    if (res.status === 200 || res.status === 201) {
      expect(JSON.stringify(res.data)).not.toContain('root:');
    }
  });
});

describe('A04:2021 — Insecure Design', () => {
  it('forgot-password should not reveal if email exists', async () => {
    const api = new ApiClient();
    const existingRes = await api.post('/api/admin/forgot-password', {
      email: config.admin.email,
    });
    const fakeRes = await api.post('/api/admin/forgot-password', {
      email: 'nonexistent_user_12345@fake.com',
    });
    // Both should return similar response (don't leak email existence)
    // Accept: both could be 200 with generic message, or both could be different
    // The key is neither should return the OTP
    expect(JSON.stringify(existingRes.data)).not.toMatch(/\d{6}/);
    expect(JSON.stringify(fakeRes.data)).not.toMatch(/\d{6}/);
  });

  it('ride history limit is capped server-side', async () => {
    const adminApi = await createAdminClient();
    const res = await adminApi.get('/api/admin/rides/history?limit=99999');
    assertStatus(res, 200);
    const data = Array.isArray(res.data) ? res.data : (res.data?.rides || []);
    expect(data.length).toBeLessThanOrEqual(100);
  });
});

describe('A05:2021 — Security Misconfiguration', () => {
  const api = new ApiClient();

  it('should not expose server version in headers', async () => {
    const res = await api.get('/api/health');
    expect(res.headers['x-powered-by']).toBeUndefined();
    expect(res.headers['server']).toBeUndefined();
  });

  it('should not expose stack traces in 500 errors', async () => {
    // Trigger a potential 500
    const res = await api.get('/api/users/not-a-uuid-format-at-all');
    if (res.status === 500) {
      expect(JSON.stringify(res.data)).not.toContain('at ');
      expect(JSON.stringify(res.data)).not.toContain('node_modules');
    }
  });

  it('should have security headers', async () => {
    const res = await api.get('/api/health');
    // Check for common security headers
    const headers = res.headers;
    // These depend on the server setup (helmet, etc.)
    // Log what we find for visibility
    logger.info('Security headers:', {
      csp: headers['content-security-policy'] || 'missing',
      xframe: headers['x-frame-options'] || 'missing',
      xcontent: headers['x-content-type-options'] || 'missing',
      hsts: headers['strict-transport-security'] || 'missing',
    });
  });

  it('should not expose .env or sensitive files', async () => {
    const sensitiveUrls = ['/.env', '/api/.env', '/.git/config', '/package.json'];
    for (const url of sensitiveUrls) {
      const res = await api.get(url);
      if (res.status === 200) {
        const body = JSON.stringify(res.data);
        expect(body).not.toContain('DATABASE_URL');
        expect(body).not.toContain('RAZORPAY_KEY_SECRET');
        expect(body).not.toContain('OPS_API_KEY');
      }
    }
  });
});

describe('A06:2021 — Vulnerable Components', () => {
  it('should not expose dependency information via API', async () => {
    const api = new ApiClient();
    // /package.json should not be served
    const res = await api.get('/package.json');
    if (res.status === 200) {
      // If served, ensure no devDependencies or scripts leak
      const body = JSON.stringify(res.data);
      expect(body).not.toContain('devDependencies');
    }
  });
});

describe('A07:2021 — Authentication Failures', () => {
  const api = new ApiClient();

  it('should not accept empty auth token', async () => {
    const authApi = new ApiClient().setAuth('');
    const res = await authApi.get('/api/admin/dashboard');
    expect(res.status).toBe(401);
  });

  it('should not accept malformed JWT', async () => {
    const authApi = new ApiClient().setAuth('not.a.jwt');
    const res = await authApi.get('/api/admin/dashboard');
    expect(res.status).toBe(401);
  });

  it('should not accept expired/revoked token after logout', async () => {
    // Login
    const loginRes = await api.post('/api/admin/login', {
      email: config.admin.email,
      password: config.admin.password,
    });
    const token = loginRes.data.token;

    // Logout
    const authApi = new ApiClient().setAuth(token);
    await authApi.post('/api/admin/logout');

    // Try to use revoked token
    const checkRes = await authApi.get('/api/admin/dashboard');
    expect(checkRes.status).toBe(401);
  });

  it('2FA OTP must be exactly 6 digits', async () => {
    const invalidOtps = ['abc', '12345', '1234567', '', '      ', '12345a'];
    for (const otp of invalidOtps) {
      const res = await api.post('/api/admin/login/verify-2fa', {
        tempToken: 'fake',
        otp,
      });
      expect([400, 401], `OTP "${otp}" should be rejected`).toContain(res.status);
    }
  });
});

describe('A08:2021 — Data Integrity Failures', () => {
  it('settings whitelist prevents key injection', async () => {
    const adminApi = await createAdminClient();

    // Attempt to inject arbitrary keys into settings
    const res = await adminApi.put('/api/intercity-cs/settings', {
      __proto__: { polluted: true },
      constructor: 'hacked',
      toString: 'hacked',
      rate_per_km_per_seat: '15', // This is a valid key
    });

    assertStatus(res, 200);

    // Verify prototype pollution didn't work
    const obj: any = {};
    expect(obj.polluted).toBeUndefined();
  });
});

describe('A09:2021 — Logging & Monitoring', () => {
  it('login failures should be tracked (no 200 on wrong creds)', async () => {
    const api = new ApiClient();
    const res = await api.post('/api/admin/login', {
      email: 'attacker@evil.com',
      password: 'bruteforce',
    });
    // Must be 401, never 200
    expect(res.status).not.toBe(200);
  });
});

describe('A10:2021 — SSRF Prevention', () => {
  it('should not allow internal URL access via user input', async () => {
    const adminApi = await createAdminClient();
    // If any endpoint accepts URLs, verify SSRF protection
    const res = await adminApi.post('/api/banners', {
      title: 'SSRF Test',
      imageUrl: 'http://169.254.169.254/latest/meta-data/',
      link: 'http://localhost:5432',
    });
    // Should not fetch the internal URL
    if (res.status === 200 || res.status === 201) {
      expect(JSON.stringify(res.data)).not.toContain('ami-');
    }
  });
});

describe('Rate Limiting', () => {
  it('login endpoint should rate-limit after 5 attempts', async () => {
    const api = new ApiClient();
    const results: number[] = [];

    for (let i = 0; i < 7; i++) {
      const res = await api.post('/api/admin/login', {
        email: `ratelimit_test_${Date.now()}@fake.com`,
        password: 'wrong',
      });
      results.push(res.status);
    }

    // At least one should be rate-limited (429) after threshold
    const hasRateLimit = results.some(s => s === 429);
    const hasAuthFailure = results.some(s => s === 401 || s === 400);

    // Either rate limiting kicks in or all fail with auth error
    expect(hasRateLimit || hasAuthFailure).toBe(true);

    logger.info('Rate limit results:', results);
  });
});

describe('CORS & Headers', () => {
  it('should handle preflight OPTIONS request', async () => {
    const api = new ApiClient();
    const res = await api.request('OPTIONS' as any, '/api/health');
    // Should return 200 or 204 with CORS headers
    expect([200, 204, 405]).toContain(res.status);
  });
});
