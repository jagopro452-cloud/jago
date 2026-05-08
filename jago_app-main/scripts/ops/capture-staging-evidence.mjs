import fs from "fs/promises";
import path from "path";

function arg(name) {
  const match = process.argv.find((item) => item.startsWith(`${name}=`));
  return match ? match.slice(name.length + 1) : undefined;
}

const baseUrl = arg("--base-url") || process.env.BASE_URL;
const opsKey = arg("--ops-key") || process.env.OPS_API_KEY;
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

  const probes = await Promise.all([
    capture("health", `${baseUrl}/api/health`),
    capture("ready", `${baseUrl}/api/ops/ready`, { "x-ops-key": opsKey }),
    capture("metrics", `${baseUrl}/api/ops/metrics`, { "x-ops-key": opsKey }),
    capture("env", `${baseUrl}/api/health/env`),
  ]);

  const summary = {
    baseUrl,
    capturedAt: new Date().toISOString(),
    probes,
  };

  const file = path.join(outputDir, "staging-evidence.json");
  await fs.writeFile(file, JSON.stringify(summary, null, 2));

  for (const probe of probes) {
    console.log(`${probe.name}: status=${probe.status} duration=${probe.durationMs}ms`);
  }
  console.log(`Evidence written to ${file}`);
}

main().catch((error) => {
  console.error("Failed to capture staging evidence:", error?.message || error);
  process.exit(1);
});
