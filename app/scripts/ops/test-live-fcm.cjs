#!/usr/bin/env node
const crypto = require("crypto");
const { execFileSync } = require("child_process");
const { Client } = require("pg");

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--app-id") args.appId = argv[++i];
    else if (arg === "--driver-id") args.driverId = argv[++i];
    else if (arg === "--url") args.url = argv[++i];
    else {
      console.error(`Unknown argument: ${arg}`);
      process.exit(1);
    }
  }
  return args;
}

function getEnv(app, key) {
  const envs = app?.spec?.services?.[0]?.envs || [];
  return envs.find((entry) => entry.key === key)?.value || "";
}

function tokenHash(token) {
  return crypto.createHash("sha256").update(token).digest("hex").slice(0, 12);
}

(async () => {
  const args = parseArgs(process.argv);
  const appId = args.appId || process.env.DO_APP_ID;
  if (!appId) throw new Error("--app-id or DO_APP_ID is required");

  const raw = execFileSync("doctl", ["apps", "get", appId, "-o", "json"], { encoding: "utf8" });
  const parsed = JSON.parse(raw);
  const app = Array.isArray(parsed) ? parsed[0] : parsed;
  let databaseUrl = getEnv(app, "DATABASE_URL");
  const opsKey = getEnv(app, "OPS_API_KEY") || process.env.OPS_API_KEY;
  if (!databaseUrl || !opsKey) throw new Error("DATABASE_URL or OPS_API_KEY missing from app spec");

  // Diagnostic client only. DigitalOcean managed DB CA is not installed locally.
  databaseUrl = databaseUrl.replace(/[?&]sslmode=[^&]*/g, "");
  const client = new Client({ connectionString: databaseUrl, ssl: { rejectUnauthorized: false } });
  await client.connect();
  const result = await client.query(
    `
      SELECT ud.user_id, u.full_name, u.phone, ud.updated_at, ud.fcm_token
      FROM user_devices ud
      JOIN users u ON u.id = ud.user_id
      WHERE u.user_type = $1
        AND ud.fcm_token IS NOT NULL
        AND length(ud.fcm_token) > 20
      ORDER BY
        CASE WHEN ud.user_id::text = $2 THEN 0 ELSE 1 END,
        ud.updated_at DESC
      LIMIT 1
    `,
    ["driver", args.driverId || ""],
  );
  await client.end();

  if (!result.rows.length) throw new Error("No driver FCM token found");
  const row = result.rows[0];
  const endpoint = args.url || "https://jagopro.org/internal/test-fcm";
  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "x-ops-key": opsKey,
    },
    body: JSON.stringify({ token: row.fcm_token }),
  });
  const bodyText = await response.text();
  let body;
  try {
    body = JSON.parse(bodyText);
  } catch {
    body = { raw: bodyText.slice(0, 200) };
  }

  console.log(JSON.stringify({
    driverId: row.user_id,
    driverName: row.full_name,
    phoneLast4: String(row.phone || "").slice(-4),
    tokenUpdatedAt: row.updated_at,
    tokenHash: tokenHash(row.fcm_token),
    httpStatus: response.status,
    response: body,
  }, null, 2));
})().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
