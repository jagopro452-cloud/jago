const BASE = process.env.SMOKE_BASE_URL || 'http://localhost:5000';

async function request(path, { method = 'GET', token, body } = {}) {
  const headers = {};
  if (token) headers.Authorization = `Bearer ${token}`;
  if (body) headers['Content-Type'] = 'application/json';

  const res = await fetch(`${BASE}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let parsed = {};
  try {
    parsed = text ? JSON.parse(text) : {};
  } catch {
    parsed = { raw: text };
  }
  return { status: res.status, body: parsed };
}

(async () => {
  const login = await request('/api/admin/login', {
    method: 'POST',
    body: {
      email: process.env.ADMIN_EMAIL || 'admin@example.com',
      password: process.env.ADMIN_PASSWORD || 'ChangeMe_Dev_Only_123!',
    },
  });

  if (login.status !== 200 || !login.body?.token) {
    console.error(JSON.stringify({ login }, null, 2));
    process.exit(1);
  }

  const token = login.body.token;
  const endpoints = [
    '/api/admin/system/live-overview',
    '/api/admin/rides/active',
    '/api/admin/rides/history',
    '/api/admin/rides/cancelled',
    '/api/admin/complaints',
    '/api/admin/drivers/pending-verification',
    '/api/admin/languages',
  ];

  const report = {};
  let hasServerError = false;

  for (const endpoint of endpoints) {
    const result = await request(endpoint, { token });
    report[endpoint] = {
      status: result.status,
      body: result.status >= 500 ? result.body : undefined,
    };
    if (result.status >= 500) hasServerError = true;
  }

  const history = await request('/api/admin/rides/history?limit=5', { token });
  report['/api/admin/rides/history?limit=5'] = {
    status: history.status,
    body: history.status >= 500 ? history.body : undefined,
  };
  if (history.status >= 500) hasServerError = true;

  const firstTripId = history.body?.items?.[0]?.id;
  if (firstTripId) {
    const routeResult = await request(`/api/admin/rides/${firstTripId}/route`, { token });
    report['/api/admin/rides/:tripId/route'] = {
      status: routeResult.status,
      body: routeResult.status >= 500 ? routeResult.body : undefined,
    };
    if (routeResult.status >= 500) hasServerError = true;

    const complaintCreate = await request('/api/admin/complaints', {
      method: 'POST',
      token,
      body: {
        tripId: firstTripId,
        complaintType: 'smoke_test',
        description: 'Smoke test complaint for protected admin API sweep',
      },
    });
    report['POST /api/admin/complaints'] = {
      status: complaintCreate.status,
      body: complaintCreate.status >= 500 ? complaintCreate.body : undefined,
    };
    if (complaintCreate.status >= 500) hasServerError = true;

    const complaintId = complaintCreate.body?.id;
    if (complaintId) {
      const complaintPatch = await request(`/api/admin/complaints/${complaintId}`, {
        method: 'PATCH',
        token,
        body: {
          status: 'resolved',
          resolutionNote: 'Smoke test resolved',
        },
      });
      report['PATCH /api/admin/complaints/:id'] = {
        status: complaintPatch.status,
        body: complaintPatch.status >= 500 ? complaintPatch.body : undefined,
      };
      if (complaintPatch.status >= 500) hasServerError = true;
    }
  }

  const logout = await request('/api/admin/logout', { method: 'POST', token });
  report['POST /api/admin/logout'] = {
    status: logout.status,
    body: logout.status >= 500 ? logout.body : undefined,
  };
  if (logout.status >= 500) hasServerError = true;

  console.log(JSON.stringify(report, null, 2));
  if (hasServerError) process.exit(1);
})();
