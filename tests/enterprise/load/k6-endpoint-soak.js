// ===========================================================================
// k6 Targeted Endpoint Soak Test
// Specific high-traffic endpoint performance baselines
// ===========================================================================
// Usage: k6 run tests/enterprise/load/k6-endpoint-soak.js

import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Rate } from 'k6/metrics';

const BASE_URL = __ENV.TEST_BASE_URL || 'http://localhost:5000';

// Per-endpoint metrics
const metrics = {};
const endpoints = [
  { path: '/api/health', name: 'health' },
  { path: '/api/ping', name: 'ping' },
  { path: '/api/vehicle-categories', name: 'vehicles' },
  { path: '/api/cancellation-reasons', name: 'cancel_reasons' },
  { path: '/api/app/banners', name: 'banners' },
  { path: '/api/app/popular-locations', name: 'popular_locations' },
];

for (const ep of endpoints) {
  metrics[ep.name] = {
    duration: new Trend(`${ep.name}_duration`, true),
    errors: new Rate(`${ep.name}_errors`),
  };
}

export const options = {
  scenarios: {
    soak: {
      executor: 'constant-vus',
      vus: 50,
      duration: '10m',
    },
  },
  thresholds: {
    health_duration: ['p(95)<200'],
    ping_duration: ['p(95)<100'],
    vehicles_duration: ['p(95)<500'],
    health_errors: ['rate<0.01'],
    ping_errors: ['rate<0.01'],
  },
};

export default function () {
  const ep = endpoints[__ITER % endpoints.length];
  const m = metrics[ep.name];

  const res = http.get(`${BASE_URL}${ep.path}`, {
    tags: { name: ep.name },
  });

  m.duration.add(res.timings.duration);

  const ok = check(res, {
    [`${ep.name}: status 200`]: (r) => r.status === 200,
    [`${ep.name}: response < 2s`]: (r) => r.timings.duration < 2000,
  });

  if (!ok) m.errors.add(1);

  sleep(0.5 + Math.random());
}
