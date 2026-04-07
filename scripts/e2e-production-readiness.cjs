/* Production-readiness smoke checks for API gates and ops endpoints. */
const fs = require("fs");
const path = require("path");

const baseUrl = process.env.SMOKE_BASE_URL || "http://localhost:5000";
const requiredEnvKeys = [
  "DATABASE_URL",
  "ADMIN_PASSWORD",
  "GOOGLE_MAPS_API_KEY",
  "OPS_API_KEY",
  "SOCKET_ALLOWED_ORIGINS",
];

async function check(name, fn) {
  try {
    await fn();
    console.log(`[PASS] ${name}`);
    return true;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.error(`[FAIL] ${name}: ${message}`);
    return false;
  }
}

function loadEnvFile(fileName) {
  const filePath = path.resolve(process.cwd(), fileName);
  if (!fs.existsSync(filePath)) {
    return;
  }

  const text = fs.readFileSync(filePath, "utf8");
  for (const rawLine of text.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) {
      continue;
    }
    const eq = line.indexOf("=");
    if (eq === -1) {
      continue;
    }
    const key = line.slice(0, eq).trim();
    if (!key || process.env[key]) {
      continue;
    }
    let value = line.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    process.env[key] = value;
  }
}

async function getJson(path, options = {}) {
  const timeoutMs = options.timeoutMs || 5000;
  const { timeoutMs: _unused, ...fetchOptions } = options;

  let timer = null;
  const timeoutPromise = new Promise((_, reject) => {
    timer = setTimeout(() => {
      reject(new Error(`request timed out after ${timeoutMs}ms`));
    }, timeoutMs);
  });

  const response = await Promise.race([fetch(`${baseUrl}${path}`, fetchOptions), timeoutPromise]);
  if (timer) {
    clearTimeout(timer);
  }
  const text = await response.text();
  let body = null;
  try {
    body = JSON.parse(text);
  } catch {
    body = text;
  }
  return { response, body };
}

(async () => {
  loadEnvFile(".env.production");
  loadEnvFile(".env");

  const results = [];
  let apiReachable = true;

  results.push(
    await check("required production env keys are present", async () => {
      const missing = requiredEnvKeys.filter((k) => !process.env[k] || !String(process.env[k]).trim());
      if (missing.length) {
        throw new Error(`missing env keys: ${missing.join(", ")}`);
      }
    })
  );

  results.push(
    await check("health endpoint", async () => {
      const { response, body } = await getJson("/api/health");
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      if (!body || body.status !== "ok") {
        throw new Error("status is not ok");
      }
    })
  );

  if (!results[results.length - 1]) {
    apiReachable = false;
  }

  results.push(
    await check("admin API blocks unauthenticated access", async () => {
      if (!apiReachable) {
        throw new Error("skipped because health check failed");
      }
      const { response } = await getJson("/api/admin/live-kpis");
      if (response.status !== 401) {
        throw new Error(`expected 401, got ${response.status}`);
      }
    })
  );

  results.push(
    await check("ops readiness endpoint", async () => {
      if (!apiReachable) {
        throw new Error("skipped because health check failed");
      }
      const opsKey = process.env.OPS_API_KEY;
      if (!opsKey) {
        throw new Error("OPS_API_KEY not configured");
      }
      const { response, body } = await getJson("/api/ops/ready", {
        headers: { "x-ops-key": opsKey },
      });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      if (!body || body.status !== "ready") {
        throw new Error("status is not ready");
      }
    })
  );

  results.push(
    await check("ops metrics endpoint", async () => {
      if (!apiReachable) {
        throw new Error("skipped because health check failed");
      }
      const opsKey = process.env.OPS_API_KEY;
      if (!opsKey) {
        throw new Error("OPS_API_KEY not configured");
      }
      const { response, body } = await getJson("/api/ops/metrics", {
        headers: { "x-ops-key": opsKey },
      });
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }
      if (!body || typeof body.uptimeSeconds !== "number") {
        throw new Error("uptimeSeconds missing from metrics payload");
      }
    })
  );

  const passCount = results.filter(Boolean).length;
  const total = results.length;
  console.log(`\nProduction smoke result: ${passCount}/${total} checks passed`);
  if (passCount !== total) {
    process.exitCode = 1;
  }
})();