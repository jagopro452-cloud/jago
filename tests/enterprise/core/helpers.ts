// ===========================================================================
// JagoPro — API Client & Test Helpers
// Reusable HTTP client with auth, logging, retries, and assertions
// ===========================================================================

import config from '../config/test.config';

// ── Types ───────────────────────────────────────────────────────────────────

interface ApiResponse<T = any> {
  status: number;
  data: T;
  headers: Record<string, string>;
  duration: number;
}

interface RequestOptions {
  headers?: Record<string, string>;
  timeout?: number;
  retries?: number;
  logBody?: boolean;
}

type HttpMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';

// ── Logger ──────────────────────────────────────────────────────────────────

const LOG_LEVELS = { DEBUG: 0, INFO: 1, WARN: 2, ERROR: 3 } as const;
const LOG_LEVEL = LOG_LEVELS[(process.env.TEST_LOG_LEVEL as keyof typeof LOG_LEVELS) || 'INFO'];

export const logger = {
  debug: (...args: any[]) => LOG_LEVEL <= 0 && console.log('[DEBUG]', new Date().toISOString(), ...args),
  info: (...args: any[]) => LOG_LEVEL <= 1 && console.log('[INFO]', new Date().toISOString(), ...args),
  warn: (...args: any[]) => LOG_LEVEL <= 2 && console.warn('[WARN]', new Date().toISOString(), ...args),
  error: (...args: any[]) => LOG_LEVEL <= 3 && console.error('[ERROR]', new Date().toISOString(), ...args),
  api: (method: string, path: string, status: number, duration: number) =>
    LOG_LEVEL <= 1 && console.log(`[API] ${method} ${path} → ${status} (${duration}ms)`),
};

// ── API Client ──────────────────────────────────────────────────────────────

export class ApiClient {
  private baseUrl: string;
  private defaultHeaders: Record<string, string> = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  constructor(baseUrl?: string) {
    this.baseUrl = baseUrl || config.baseUrl;
  }

  setAuth(token: string): this {
    this.defaultHeaders['Authorization'] = `Bearer ${token}`;
    return this;
  }

  setOpsKey(key: string): this {
    this.defaultHeaders['X-Ops-Key'] = key;
    return this;
  }

  clearAuth(): this {
    delete this.defaultHeaders['Authorization'];
    delete this.defaultHeaders['X-Ops-Key'];
    return this;
  }

  async request<T = any>(
    method: HttpMethod,
    path: string,
    body?: any,
    options: RequestOptions = {}
  ): Promise<ApiResponse<T>> {
    const url = `${this.baseUrl}${path}`;
    const timeout = options.timeout || config.timeouts.api;
    const maxRetries = options.retries ?? 0;
    const headers = { ...this.defaultHeaders, ...options.headers };

    let lastError: Error | null = null;

    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), timeout);
      const start = performance.now();

      try {
        const fetchOptions: RequestInit = {
          method,
          headers,
          signal: controller.signal,
        };
        if (body && method !== 'GET') {
          fetchOptions.body = JSON.stringify(body);
        }

        const response = await fetch(url, fetchOptions);
        const duration = Math.round(performance.now() - start);
        clearTimeout(timer);

        let data: T;
        const contentType = response.headers.get('content-type') || '';
        if (contentType.includes('application/json')) {
          data = await response.json() as T;
        } else {
          data = (await response.text()) as unknown as T;
        }

        logger.api(method, path, response.status, duration);

        const responseHeaders: Record<string, string> = {};
        response.headers.forEach((value, key) => { responseHeaders[key] = value; });

        return { status: response.status, data, headers: responseHeaders, duration };
      } catch (err: any) {
        clearTimeout(timer);
        lastError = err;
        if (attempt < maxRetries) {
          logger.warn(`Retry ${attempt + 1}/${maxRetries} for ${method} ${path}: ${err.message}`);
          await sleep(1000 * (attempt + 1));
        }
      }
    }

    throw lastError || new Error(`Request failed: ${method} ${path}`);
  }

  // Convenience methods
  get<T = any>(path: string, opts?: RequestOptions) { return this.request<T>('GET', path, undefined, opts); }
  post<T = any>(path: string, body?: any, opts?: RequestOptions) { return this.request<T>('POST', path, body, opts); }
  put<T = any>(path: string, body?: any, opts?: RequestOptions) { return this.request<T>('PUT', path, body, opts); }
  patch<T = any>(path: string, body?: any, opts?: RequestOptions) { return this.request<T>('PATCH', path, body, opts); }
  delete<T = any>(path: string, opts?: RequestOptions) { return this.request<T>('DELETE', path, undefined, opts); }
}

// ── Auth Helpers ────────────────────────────────────────────────────────────

let cachedAdminToken: string | null = null;

export async function getAdminToken(client?: ApiClient): Promise<string> {
  if (cachedAdminToken) return cachedAdminToken;

  const api = client || new ApiClient();
  const res = await api.post('/api/admin/login', {
    email: config.admin.email,
    password: config.admin.password,
  });

  if (res.status !== 200 || !res.data.token) {
    throw new Error(`Admin login failed: ${res.status} ${JSON.stringify(res.data)}`);
  }

  cachedAdminToken = res.data.token;
  return cachedAdminToken!;
}

export function clearAdminToken() {
  cachedAdminToken = null;
}

export async function createAdminClient(): Promise<ApiClient> {
  const client = new ApiClient();
  const token = await getAdminToken(client);
  client.setAuth(token);
  return client;
}

export function createOpsClient(): ApiClient {
  return new ApiClient().setOpsKey(config.opsKey);
}

// ── Assertion Helpers ───────────────────────────────────────────────────────

export function assertStatus(res: ApiResponse, expected: number, context?: string) {
  if (res.status !== expected) {
    const msg = context ? `[${context}] ` : '';
    throw new Error(
      `${msg}Expected status ${expected}, got ${res.status}. Body: ${JSON.stringify(res.data).slice(0, 500)}`
    );
  }
}

export function assertJsonShape(data: any, requiredKeys: string[], context?: string) {
  const missing = requiredKeys.filter(k => !(k in data));
  if (missing.length) {
    const msg = context ? `[${context}] ` : '';
    throw new Error(`${msg}Missing keys: ${missing.join(', ')}. Got: ${Object.keys(data).join(', ')}`);
  }
}

export function assertArrayNotEmpty(data: any[], context?: string) {
  if (!Array.isArray(data) || data.length === 0) {
    const msg = context ? `[${context}] ` : '';
    throw new Error(`${msg}Expected non-empty array, got: ${JSON.stringify(data).slice(0, 200)}`);
  }
}

export function assertDuration(res: ApiResponse, maxMs: number, context?: string) {
  if (res.duration > maxMs) {
    const msg = context ? `[${context}] ` : '';
    logger.warn(`${msg}Slow response: ${res.duration}ms (threshold: ${maxMs}ms)`);
  }
}

// ── Utility Functions ───────────────────────────────────────────────────────

export function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

export function randomPhone(): string {
  return '99999' + String(Math.floor(10000 + Math.random() * 90000));
}

export function randomEmail(): string {
  return `test.${Date.now()}.${Math.random().toString(36).slice(2, 6)}@jagopro.test`;
}

export function randomUUID(): string {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, c => {
    const r = (Math.random() * 16) | 0;
    return (c === 'x' ? r : (r & 0x3) | 0x8).toString(16);
  });
}

export function formatRupees(paise: number): string {
  return `₹${(paise / 100).toFixed(2)}`;
}

// ── Test Data Generators ────────────────────────────────────────────────────

export function generateCustomer(overrides?: Partial<any>) {
  return {
    phone: randomPhone(),
    full_name: `Test Customer ${Date.now()}`,
    email: randomEmail(),
    user_type: 'customer',
    ...overrides,
  };
}

export function generateDriver(overrides?: Partial<any>) {
  return {
    phone: randomPhone(),
    full_name: `Test Driver ${Date.now()}`,
    email: randomEmail(),
    user_type: 'driver',
    vehicle_number: `TS${String(Math.floor(10 + Math.random() * 90))}AB${String(Math.floor(1000 + Math.random() * 9000))}`,
    vehicle_model: 'Test Vehicle',
    ...overrides,
  };
}

export function generateTripRequest(overrides?: Partial<any>) {
  return {
    pickupLat: config.testData.locations.pickup.lat,
    pickupLng: config.testData.locations.pickup.lng,
    pickupAddress: config.testData.locations.pickup.address,
    dropoffLat: config.testData.locations.dropoff.lat,
    dropoffLng: config.testData.locations.dropoff.lng,
    dropoffAddress: config.testData.locations.dropoff.address,
    vehicleCategoryId: null,
    paymentMethod: 'cash',
    ...overrides,
  };
}

export function generateRazorpaySignature(orderId: string, paymentId: string, secret: string): string {
  const crypto = require('crypto');
  return crypto.createHmac('sha256', secret)
    .update(`${orderId}|${paymentId}`)
    .digest('hex');
}

// ── Performance Tracker ─────────────────────────────────────────────────────

export class PerformanceTracker {
  private metrics: Map<string, number[]> = new Map();

  record(name: string, durationMs: number) {
    if (!this.metrics.has(name)) this.metrics.set(name, []);
    this.metrics.get(name)!.push(durationMs);
  }

  percentile(name: string, p: number): number {
    const values = this.metrics.get(name)?.sort((a, b) => a - b);
    if (!values?.length) return 0;
    const idx = Math.ceil((p / 100) * values.length) - 1;
    return values[Math.max(0, idx)];
  }

  summary(): Record<string, { count: number; avg: number; p50: number; p95: number; p99: number; max: number }> {
    const result: Record<string, any> = {};
    for (const [name, values] of this.metrics) {
      const sorted = [...values].sort((a, b) => a - b);
      result[name] = {
        count: sorted.length,
        avg: Math.round(sorted.reduce((a, b) => a + b, 0) / sorted.length),
        p50: sorted[Math.floor(sorted.length * 0.5)],
        p95: sorted[Math.floor(sorted.length * 0.95)],
        p99: sorted[Math.floor(sorted.length * 0.99)],
        max: sorted[sorted.length - 1],
      };
    }
    return result;
  }

  print() {
    console.log('\n━━━ Performance Summary ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    for (const [name, stats] of Object.entries(this.summary())) {
      console.log(
        `  ${name.padEnd(35)} │ n=${String(stats.count).padStart(5)} │ avg=${String(stats.avg).padStart(5)}ms │ p95=${String(stats.p95).padStart(5)}ms │ p99=${String(stats.p99).padStart(5)}ms │ max=${String(stats.max).padStart(5)}ms`
      );
    }
    console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }
}
