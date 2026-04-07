// ===========================================================================
// JagoPro Enterprise Test Suite — Global Configuration
// ===========================================================================

export const config = {
  // ── Server ────────────────────────────────────────────────────────────────
  baseUrl: process.env.TEST_BASE_URL || 'http://localhost:5000',
  wsUrl: process.env.TEST_WS_URL || 'ws://localhost:5000',

  // ── Admin Credentials ─────────────────────────────────────────────────────
  admin: {
    email: process.env.TEST_ADMIN_EMAIL || 'kiranatmakuri518@gmail.com',
    password: process.env.TEST_ADMIN_PASSWORD || 'admin123',
  },

  // ── OPS Key ───────────────────────────────────────────────────────────────
  opsKey: process.env.OPS_API_KEY || process.env.TEST_OPS_KEY || '',

  // ── Razorpay Test Keys ────────────────────────────────────────────────────
  razorpay: {
    keyId: process.env.RAZORPAY_KEY_ID || process.env.TEST_RAZORPAY_KEY_ID || '',
    keySecret: process.env.RAZORPAY_KEY_SECRET || process.env.TEST_RAZORPAY_KEY_SECRET || '',
    webhookSecret: process.env.RAZORPAY_WEBHOOK_SECRET || process.env.TEST_RAZORPAY_WEBHOOK_SECRET || '',
  },

  // ── Timeouts ──────────────────────────────────────────────────────────────
  timeouts: {
    api: 10_000,
    socket: 15_000,
    page: 30_000,
    navigation: 60_000,
    payment: 30_000,
  },

  // ── Test Data ─────────────────────────────────────────────────────────────
  testData: {
    customer: {
      phone: '9999900001',
      name: 'Test Customer',
      email: 'test.customer@jagopro.org',
    },
    driver: {
      phone: '9999900002',
      name: 'Test Driver',
      email: 'test.driver@jagopro.org',
    },
    locations: {
      pickup: { lat: 17.385044, lng: 78.486671, address: 'Hyderabad Central' },
      dropoff: { lat: 17.440081, lng: 78.348915, address: 'Hitec City' },
      outstation: { lat: 15.8281, lng: 78.0373, address: 'Kurnool' },
    },
  },

  // ── Retry Policy ──────────────────────────────────────────────────────────
  retry: {
    api: 2,
    e2e: 1,
    flaky: 3,
  },

  // ── Reporting ─────────────────────────────────────────────────────────────
  reports: {
    dir: 'tests/enterprise/reports',
    screenshots: 'tests/enterprise/screenshots',
    videos: 'tests/enterprise/videos',
  },

  // ── k6 Load Defaults ─────────────────────────────────────────────────────
  load: {
    vus: parseInt(process.env.K6_VUS || '100'),
    duration: process.env.K6_DURATION || '5m',
    thresholds: {
      http_req_duration_p95: 500,   // 95th percentile < 500ms
      http_req_duration_p99: 2000,  // 99th percentile < 2s
      http_req_failed_rate: 0.01,   // < 1% error rate
    },
  },

  // ── Mobile (Appium) ──────────────────────────────────────────────────────
  appium: {
    host: process.env.APPIUM_HOST || 'http://localhost:4723',
    android: {
      platformName: 'Android',
      automationName: 'UiAutomator2',
      customerApp: 'flutter_apps/customer_app/build/app/outputs/flutter-apk/app-release.apk',
      driverApp: 'flutter_apps/driver_app/build/app/outputs/flutter-apk/app-release.apk',
    },
    ios: {
      platformName: 'iOS',
      automationName: 'XCUITest',
    },
  },
} as const;

export type TestConfig = typeof config;
export default config;
