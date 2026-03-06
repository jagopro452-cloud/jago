import express from "express";

const app = express();
const port = Number(process.env.GATEWAY_PORT || 7000);
const monolithBaseUrl = process.env.MONOLITH_BASE_URL || "http://localhost:5000";
const matchingServiceUrl = process.env.MATCHING_SERVICE_URL || "http://localhost:7101";
const tripServiceUrl = process.env.TRIP_SERVICE_URL || "http://localhost:7102";
const locationServiceUrl = process.env.LOCATION_SERVICE_URL || "http://localhost:7103";
const aiAssistantServiceUrl = process.env.AI_ASSISTANT_SERVICE_URL || "http://localhost:7104";

app.use(express.json());

function authHeaders(req: express.Request) {
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  const auth = req.headers.authorization;
  if (typeof auth === "string" && auth.trim()) headers.Authorization = auth;
  return headers;
}

async function proxyJson(req: express.Request, res: express.Response, upstreamUrl: string, method = "POST", body?: any) {
  try {
    const upstream = await fetch(upstreamUrl, {
      method,
      headers: authHeaders(req),
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    const text = await upstream.text();
    let parsed: any = {};
    try {
      parsed = text ? JSON.parse(text) : {};
    } catch {
      parsed = { raw: text };
    }
    res.status(upstream.status).json(parsed);
  } catch (error: any) {
    res.status(502).json({ message: "Upstream unavailable", detail: error?.message || "unknown" });
  }
}

app.get("/health", (_req, res) => {
  res.json({
    service: "gateway-service",
    status: "ok",
    monolithBaseUrl,
    services: {
      matchingServiceUrl,
      tripServiceUrl,
      locationServiceUrl,
      aiAssistantServiceUrl,
    },
    timestamp: new Date().toISOString(),
  });
});

app.get("/v1/health/all", async (_req, res) => {
  const checks = [
    ["gateway", Promise.resolve({ status: 200, body: { status: "ok" } })],
    ["monolith", fetch(`${monolithBaseUrl}/api/health`).then(async (r) => ({ status: r.status, body: await r.json().catch(() => ({})) })).catch((e) => ({ status: 503, body: { message: e?.message || "unreachable" } }))],
    ["matching", fetch(`${matchingServiceUrl}/health`).then(async (r) => ({ status: r.status, body: await r.json().catch(() => ({})) })).catch((e) => ({ status: 503, body: { message: e?.message || "unreachable" } }))],
    ["trip", fetch(`${tripServiceUrl}/health`).then(async (r) => ({ status: r.status, body: await r.json().catch(() => ({})) })).catch((e) => ({ status: 503, body: { message: e?.message || "unreachable" } }))],
    ["location", fetch(`${locationServiceUrl}/health`).then(async (r) => ({ status: r.status, body: await r.json().catch(() => ({})) })).catch((e) => ({ status: 503, body: { message: e?.message || "unreachable" } }))],
    ["ai", fetch(`${aiAssistantServiceUrl}/health`).then(async (r) => ({ status: r.status, body: await r.json().catch(() => ({})) })).catch((e) => ({ status: 503, body: { message: e?.message || "unreachable" } }))],
  ] as const;

  const settled = await Promise.all(checks.map(async ([name, p]) => ({ name, ...(await p) })));
  const overall = settled.every((x) => x.status < 400) ? "ok" : "degraded";
  res.json({ status: overall, services: settled, ts: new Date().toISOString() });
});

app.post("/v1/auth/otp/send", async (req, res) => {
  await proxyJson(req, res, `${monolithBaseUrl}/api/app/send-otp`, "POST", req.body);
});

app.post("/v1/auth/otp/verify", async (req, res) => {
  await proxyJson(req, res, `${monolithBaseUrl}/api/app/verify-otp`, "POST", req.body);
});

// Unified booking estimate API for bike/auto/car/parcel/intercity/hyperlocal.
app.post("/v1/bookings/estimate", async (req, res) => {
  const { serviceType } = req.body || {};
  if (!serviceType) return res.status(400).json({ message: "serviceType is required" });

  if (["bike", "auto", "car", "parcel", "hyperlocal"].includes(String(serviceType))) {
    await proxyJson(req, res, `${monolithBaseUrl}/api/app/customer/estimate-fare`, "POST", req.body);
    return;
  }

  if (String(serviceType) === "intercity") {
    await proxyJson(req, res, `${monolithBaseUrl}/api/intercity-routes`, "GET");
    return;
  }

  if (String(serviceType) === "car_sharing") {
    await proxyJson(req, res, `${monolithBaseUrl}/api/app/customer/car-sharing/rides`, "GET");
    return;
  }

  res.status(400).json({ message: `Unsupported serviceType: ${serviceType}` });
});

// Unified booking creation API that maps service types to existing monolith APIs.
app.post("/v1/bookings", async (req, res) => {
  const { serviceType } = req.body || {};
  if (!serviceType) return res.status(400).json({ message: "serviceType is required" });

  if (["bike", "auto", "car", "parcel", "hyperlocal"].includes(String(serviceType))) {
    await proxyJson(req, res, `${monolithBaseUrl}/api/app/customer/book-ride`, "POST", req.body);
    return;
  }

  if (String(serviceType) === "intercity") {
    await proxyJson(req, res, `${monolithBaseUrl}/api/app/customer/intercity-book`, "POST", req.body);
    return;
  }

  if (String(serviceType) === "car_sharing") {
    await proxyJson(req, res, `${monolithBaseUrl}/api/app/customer/car-sharing/book`, "POST", req.body);
    return;
  }

  res.status(400).json({ message: `Unsupported serviceType: ${serviceType}` });
});

app.post("/v1/dispatch/match", async (req, res) => {
  await proxyJson(req, res, `${matchingServiceUrl}/internal/matching/request`, "POST", req.body);
});

app.get("/v1/trips/:tripId/track", async (req, res) => {
  const { tripId } = req.params;
  await proxyJson(req, res, `${monolithBaseUrl}/api/app/customer/track-trip/${tripId}`, "GET");
});

app.post("/v1/voice/parse", async (req, res) => {
  await proxyJson(req, res, `${aiAssistantServiceUrl}/internal/voice/intent`, "POST", req.body);
});

app.listen(port, () => {
  console.log(`[gateway-service] listening on ${port}`);
});
