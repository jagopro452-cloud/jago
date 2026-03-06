const BASE = process.env.LOAD_BASE_URL || "http://127.0.0.1:5001";
const TOTAL_REQUESTS = Number(process.env.LOAD_TOTAL_REQUESTS || 400);
const CONCURRENCY = Number(process.env.LOAD_CONCURRENCY || 40);
const PATHS = ["/api/health", "/api/intercity-routes"];

async function requestPath(path) {
  const started = Date.now();
  try {
    const res = await fetch(`${BASE}${path}`);
    const ms = Date.now() - started;
    return { ok: res.ok, status: res.status, ms, path, error: null };
  } catch (error) {
    const ms = Date.now() - started;
    return { ok: false, status: 0, ms, path, error: String(error?.message || error) };
  }
}

async function worker(id, queue, out) {
  while (queue.length) {
    const item = queue.shift();
    if (!item) break;
    const result = await requestPath(item.path);
    out.push(result);
  }
}

function percentile(values, p) {
  if (!values.length) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const idx = Math.min(sorted.length - 1, Math.floor((p / 100) * sorted.length));
  return sorted[idx];
}

(async () => {
  const queue = [];
  for (let i = 0; i < TOTAL_REQUESTS; i += 1) {
    queue.push({ path: PATHS[i % PATHS.length] });
  }

  const out = [];
  const started = Date.now();
  const workers = Array.from({ length: CONCURRENCY }, (_, i) => worker(i, queue, out));
  await Promise.all(workers);
  const elapsed = Date.now() - started;

  const okCount = out.filter((r) => r.ok).length;
  const failCount = out.length - okCount;
  const latencies = out.map((r) => r.ms);
  const grouped = out.reduce((acc, r) => {
    const key = `${r.path}:${r.status}`;
    acc[key] = (acc[key] || 0) + 1;
    return acc;
  }, {});

  const summary = {
    baseUrl: BASE,
    totalRequests: out.length,
    concurrency: CONCURRENCY,
    durationMs: elapsed,
    requestsPerSecond: Number((out.length / (elapsed / 1000)).toFixed(2)),
    successRate: Number(((okCount / out.length) * 100).toFixed(2)),
    failureRate: Number(((failCount / out.length) * 100).toFixed(2)),
    latencyMs: {
      min: Math.min(...latencies),
      p50: percentile(latencies, 50),
      p90: percentile(latencies, 90),
      p95: percentile(latencies, 95),
      p99: percentile(latencies, 99),
      max: Math.max(...latencies),
      avg: Number((latencies.reduce((a, b) => a + b, 0) / latencies.length).toFixed(2)),
    },
    statusBreakdown: grouped,
    sampleFailures: out.filter((r) => !r.ok).slice(0, 5),
  };

  console.log(JSON.stringify(summary, null, 2));

  if (failCount > 0) process.exit(2);
})();
