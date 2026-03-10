import express from "express";

const app = express();
const port = Number(process.env.LOCATION_PORT || 7103);
const STREAM_INTERVAL_MS = Math.max(2000, Number(process.env.LOCATION_STREAM_INTERVAL_MS || 2500));

app.use(express.json());

type DriverLocation = {
  driverId: string;
  lat: number;
  lng: number;
  heading?: number;
  speedKmph?: number;
  ts: string;
};

const driverLocations = new Map<string, DriverLocation>();
const locationSubscribers = new Set<express.Response>();

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const toRad = (x: number) => (x * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  return R * (2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
}

function toEtaMinutes(distanceKm: number, avgSpeedKmph = 25): number {
  if (!Number.isFinite(distanceKm) || distanceKm <= 0) return 1;
  return Math.max(1, Math.round((distanceKm / avgSpeedKmph) * 60));
}

setInterval(() => {
  if (locationSubscribers.size === 0) return;
  const payload = JSON.stringify({
    type: "location_snapshot",
    ts: new Date().toISOString(),
    drivers: Array.from(driverLocations.values()),
  });
  for (const client of locationSubscribers) {
    client.write(`event: location\n`);
    client.write(`data: ${payload}\n\n`);
  }
}, STREAM_INTERVAL_MS);

app.get("/health", (_req, res) => {
  res.json({
    service: "location-service",
    status: "ok",
    activeDrivers: driverLocations.size,
    streamSubscribers: locationSubscribers.size,
    streamIntervalMs: STREAM_INTERVAL_MS,
    timestamp: new Date().toISOString(),
  });
});

app.post("/internal/location/driver/update", (req, res) => {
  const { driverId, lat, lng, speedKmph, heading } = req.body || {};
  if (!driverId || !Number.isFinite(Number(lat)) || !Number.isFinite(Number(lng))) {
    return res.status(400).json({ message: "driverId, lat and lng are required" });
  }

  const next: DriverLocation = {
    driverId: String(driverId),
    lat: Number(lat),
    lng: Number(lng),
    speedKmph: Number(speedKmph || 0),
    heading: Number(heading || 0),
    ts: new Date().toISOString(),
  };
  driverLocations.set(next.driverId, next);

  res.json({
    accepted: true,
    ...next,
    note: "Driver location cached in-memory (Redis adapter plug-in ready).",
  });
});

app.get("/internal/location/driver/nearby", (req, res) => {
  const { lat, lng, radiusKm = 5 } = req.query;
  const qLat = Number(lat);
  const qLng = Number(lng);
  const qRadiusKm = Number(radiusKm || 5);
  if (!Number.isFinite(qLat) || !Number.isFinite(qLng)) {
    return res.status(400).json({ message: "lat and lng are required" });
  }
  const drivers = Array.from(driverLocations.values())
    .map((d) => {
      const distanceKm = haversineKm(qLat, qLng, d.lat, d.lng);
      return {
        ...d,
        distanceKm: Number(distanceKm.toFixed(3)),
        etaMinutes: toEtaMinutes(distanceKm),
      };
    })
    .filter((d) => d.distanceKm <= qRadiusKm)
    .sort((a, b) => a.distanceKm - b.distanceKm);

  res.json({ lat: qLat, lng: qLng, radiusKm: qRadiusKm, count: drivers.length, drivers });
});

app.get("/internal/location/stream", (_req, res) => {
  res.setHeader("Content-Type", "text/event-stream");
  res.setHeader("Cache-Control", "no-cache");
  res.setHeader("Connection", "keep-alive");
  res.flushHeaders?.();

  locationSubscribers.add(res);
  res.write(`event: ready\n`);
  res.write(`data: ${JSON.stringify({ message: "location stream active", ts: new Date().toISOString() })}\n\n`);

  const keepAlive = setInterval(() => {
    res.write(`event: ping\n`);
    res.write(`data: ${Date.now()}\n\n`);
  }, 15000);

  res.on("close", () => {
    clearInterval(keepAlive);
    locationSubscribers.delete(res);
  });
});

app.get("/internal/location/demand-zones", (_req, res) => {
  // Lightweight synthetic demand feed for driver positioning UI.
  const zones = [
    { zoneId: "city_centre", lat: 16.5062, lng: 80.648, city: "Vijayawada", demandScore: 0.91, surgeMultiplier: 1.4, recommendation: "High ride probability in next 20 mins" },
    { zoneId: "railway_station", lat: 16.5174, lng: 80.6305, city: "Vijayawada", demandScore: 0.84, surgeMultiplier: 1.25, recommendation: "Move near station pickup gate" },
    { zoneId: "it_hub", lat: 17.4435, lng: 78.3772, city: "Hyderabad", demandScore: 0.88, surgeMultiplier: 1.35, recommendation: "Peak office outbound demand" },
  ];
  res.json({ ts: new Date().toISOString(), zones });
});

app.listen(port, () => {
  console.log(`[location-service] listening on ${port}`);
});
