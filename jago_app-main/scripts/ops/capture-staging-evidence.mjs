import fs from "fs/promises";
import path from "path";

function arg(name) {
  const match = process.argv.find((item) => item.startsWith(`${name}=`));
  return match ? match.slice(name.length + 1) : undefined;
}

const baseUrl = arg("--base-url") || process.env.BASE_URL;
const opsKey = arg("--ops-key") || process.env.OPS_API_KEY;
const adminToken = arg("--admin-token") || process.env.ADMIN_BEARER_TOKEN;
const outputDir = arg("--output-dir") || process.env.OUTPUT_DIR || path.join("docs", "audit", "evidence", new Date().toISOString().slice(0, 10));

if (!baseUrl) {
  console.error("Missing --base-url=<url> or BASE_URL");
  process.exit(1);
}

if (!opsKey) {
  console.error("Missing --ops-key=<key> or OPS_API_KEY");
  process.exit(1);
}

async function capture(name, url, headers = {}) {
  const startedAt = Date.now();
  const response = await fetch(url, { headers });
  const bodyText = await response.text();
  let body;
  try {
    body = bodyText ? JSON.parse(bodyText) : null;
  } catch {
    body = { raw: bodyText };
  }

  return {
    name,
    url,
    status: response.status,
    ok: response.ok,
    durationMs: Date.now() - startedAt,
    capturedAt: new Date().toISOString(),
    body,
  };
}

async function main() {
  await fs.mkdir(outputDir, { recursive: true });

  const adminHeaders = adminToken
    ? { Authorization: `Bearer ${adminToken}` }
    : null;

  const probes = await Promise.all([
    capture("health", `${baseUrl}/api/health`),
    capture("ready", `${baseUrl}/api/ops/ready`, { "x-ops-key": opsKey }),
    capture("metrics", `${baseUrl}/api/ops/metrics`, { "x-ops-key": opsKey }),
    capture("env", `${baseUrl}/api/health/env`),
    ...(adminHeaders ? [
      capture("admin-system-health", `${baseUrl}/api/admin/system-health`, adminHeaders),
      capture("admin-ride-telemetry", `${baseUrl}/api/admin/ride-telemetry`, adminHeaders),
      capture("admin-vehicle-status", `${baseUrl}/api/admin/vehicle-status`, adminHeaders),
    ] : []),
  ]);

  const summary = {
    baseUrl,
    capturedAt: new Date().toISOString(),
    adminTelemetryCaptured: Boolean(adminHeaders),
    probes,
  };

  const file = path.join(outputDir, "staging-evidence.json");
  await fs.writeFile(file, JSON.stringify(summary, null, 2));

  const markdownLines = [
    "# Staging Evidence Capture",
    "",
    `- Base URL: \`${baseUrl}\``,
    `- Captured At: \`${summary.capturedAt}\``,
    `- Admin Telemetry Included: \`${summary.adminTelemetryCaptured}\``,
    "",
    "## Probe Results",
    "",
    ...probes.map((probe) => `- \`${probe.name}\`: status=${probe.status}, ok=${probe.ok}, duration=${probe.durationMs}ms`),
    "",
    "## Next Manual Attachments",
    "",
    "- Device screenshots for driver/customer reconnect recovery flows",
    "- Admin operations board screenshots during reconnect/stale/frozen scenarios",
    "- Redis interruption start/end timestamps and recovery notes",
    "- Runtime config propagation proof",
  ];
  const markdownFile = path.join(outputDir, "staging-evidence.md");
  await fs.writeFile(markdownFile, `${markdownLines.join("\n")}\n`);

  for (const probe of probes) {
    console.log(`${probe.name}: status=${probe.status} duration=${probe.durationMs}ms`);
  }
  console.log(`Evidence written to ${file}`);
  console.log(`Evidence summary written to ${markdownFile}`);
}

main().catch((error) => {
  console.error("Failed to capture staging evidence:", error?.message || error);
  process.exit(1);
});
