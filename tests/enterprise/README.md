# JagoPro Enterprise Test Suite

## Architecture

```
tests/enterprise/
├── config/
│   └── test.config.ts           # Global config (URLs, creds, thresholds)
├── core/
│   ├── helpers.ts               # ApiClient, assertions, data generators
│   ├── setup.ts                 # Global beforeAll/afterAll
│   └── socket-client.ts         # Socket.IO test wrapper
├── api/
│   ├── admin-core.test.ts       # Admin auth, CRUD, dashboard (~25 tests)
│   ├── app-endpoints.test.ts    # App endpoints, validation (~25 tests)
│   └── settings-config.test.ts  # Settings, pricing, zones (~20 tests)
├── web/
│   ├── playwright.config.ts     # Multi-browser config
│   ├── pages/                   # Page Object Models (5 POMs)
│   ├── fixtures/                # Playwright test fixtures
│   └── tests/
│       ├── auth.spec.ts         # Login, session, rate-limit (8 tests)
│       ├── dashboard.spec.ts    # KPIs, charts, mobile (8 tests)
│       └── user-management.spec.ts
├── mobile/
│   ├── appium-framework.ts      # Base pages, capabilities, scenarios
│   ├── customer-app.test.ts     # Customer app E2E
│   └── driver-app.test.ts       # Driver app E2E
├── socket/
│   └── realtime.test.ts         # Auth, events, messaging, calls (~15 tests)
├── payment/
│   └── payment-gateway.test.ts  # Razorpay, webhooks, idempotency (~25 tests)
├── security/
│   └── owasp-top10.test.ts      # OWASP Top 10 coverage (~30 tests)
├── load/
│   ├── k6-load-test.js          # 10K user ramp (smoke/load/stress/spike)
│   ├── k6-socket-test.js        # WebSocket connection stress
│   └── k6-endpoint-soak.js      # Endpoint soak test
└── reports/                     # Auto-generated reports
```

## Test Count Summary

| Suite | Tests | Tool |
|-------|-------|------|
| API (admin, app, settings) | ~70 | Vitest |
| Web E2E (auth, dashboard, users) | ~21 | Playwright |
| Socket.IO real-time | ~15 | Vitest |
| Payment gateway | ~25 | Vitest |
| Security (OWASP Top 10) | ~30 | Vitest |
| Mobile (customer + driver) | ~20 | Appium |
| Load tests | 4 scenarios | k6 |
| **Total** | **~181+** | |

## Quick Start

```bash
# Run API tests
npm run test:api

# Run admin panel E2E (requires Playwright browsers)
npx playwright install --with-deps
npm run test:web

# Run admin panel E2E in headed mode (visible browser)
npm run test:web:headed

# Run socket tests
npm run test:socket

# Run payment tests
npm run test:payment

# Run security tests
npm run test:security

# Run all Vitest enterprise tests
npm run test:enterprise

# Run everything (existing + enterprise)
npm run test:all

# k6 load tests (requires k6 installed)
npm run test:load           # Full 10K user ramp test
npm run test:load:soak      # Endpoint soak test
npm run test:load:socket    # WebSocket stress test
```

## CI/CD

GitHub Actions workflow at `.github/workflows/enterprise-tests.yml`:
- **On PR/push**: Unit + API + Security + Web E2E
- **Nightly (2 AM IST)**: Full suite including k6 load tests
- **Manual**: Select specific suite via workflow_dispatch

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TEST_BASE_URL` | Server base URL | `http://localhost:5000` |
| `TEST_ADMIN_EMAIL` | Admin email | `admin@jagopro.org` |
| `TEST_ADMIN_PASSWORD` | Admin password | `admin123` |
| `TEST_OPS_KEY` | OPS API key | from env |
| `TEST_RAZORPAY_KEY_ID` | Razorpay test key | from env |
| `K6_VUS` | k6 virtual users | `100` |
| `K6_DURATION` | k6 test duration | `5m` |
| `APPIUM_HOST` | Appium server | `http://localhost:4723` |

## Reports

- Playwright HTML: `tests/enterprise/reports/playwright/`
- Playwright screenshots/videos: saved on test failure
- k6 JSON: `tests/enterprise/reports/k6/`
- Vitest JSON: `test-results/`
- CI artifacts: uploaded per job in GitHub Actions
