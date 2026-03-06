const BASE = process.env.SMOKE_BASE_URL || "http://localhost:5000";

async function getJson(path, headers = {}) {
  const res = await fetch(`${BASE}${path}`, { headers });
  const text = await res.text();
  let body = {};
  try { body = text ? JSON.parse(text) : {}; } catch { body = { raw: text }; }
  return { status: res.status, body };
}

async function postJson(path, payload, headers = {}) {
  const res = await fetch(`${BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", ...headers },
    body: JSON.stringify(payload),
  });
  const text = await res.text();
  let body = {};
  try { body = text ? JSON.parse(text) : {}; } catch { body = { raw: text }; }
  return { status: res.status, body };
}

(async () => {
  const report = {};

  report.health = await getJson("/api/health");
  report.adminProtected = await getJson("/api/admin/system/live-overview");

  const opsKey = process.env.OPS_API_KEY || "";
  report.opsReady = await getJson("/api/ops/ready", { "x-ops-key": opsKey });
  report.opsMetrics = await getJson("/api/ops/metrics", { "x-ops-key": opsKey });

  report.adminLogin = await postJson("/api/admin/login", {
    email: process.env.ADMIN_EMAIL || "admin@admin.com",
    password: process.env.ADMIN_PASSWORD || "",
  });

  let adminToken = report.adminLogin.body?.token;
  if (!adminToken && report.adminLogin.status === 202 && report.adminLogin.body?.requiresTwoFactor) {
    const otp = report.adminLogin.body?.otp;
    if (otp) {
      const verify = await postJson("/api/admin/login/verify-2fa", {
        email: process.env.ADMIN_EMAIL || "admin@admin.com",
        otp,
      });
      report.admin2faVerify = verify;
      adminToken = verify.body?.token;
    }
  }

  if (adminToken) {
    report.adminActiveRides = await getJson("/api/admin/rides/active", { Authorization: `Bearer ${adminToken}` });
  }

  console.log(JSON.stringify(report, null, 2));

  if (report.health.status !== 200) process.exit(1);
  if (report.adminProtected.status !== 401) process.exit(1);
})();
