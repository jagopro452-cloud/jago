import express from "express";

const app = express();
const port = Number(process.env.TRIP_PORT || 7102);

app.use(express.json());

type TripState = "requested" | "matched" | "driver_assigned" | "arrived" | "otp_verified" | "in_progress" | "completed" | "cancelled";

type TripRecord = {
  tripId: string;
  serviceType: string;
  state: TripState;
  pickupOtp?: string;
  deliveryOtp?: string;
  assignedDriverId?: string;
  createdAt: string;
  updatedAt: string;
  events: Array<{ at: string; event: string; meta?: any }>;
};

const trips = new Map<string, TripRecord>();

function nowIso() {
  return new Date().toISOString();
}

function pushEvent(trip: TripRecord, event: string, meta?: any) {
  trip.events.push({ at: nowIso(), event, meta });
  trip.updatedAt = nowIso();
}

function createOtp() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

app.get("/health", (_req, res) => {
  res.json({ service: "trip-service", status: "ok", activeTrips: trips.size, timestamp: new Date().toISOString() });
});

app.post("/internal/trips", (req, res) => {
  const { tripId, serviceType = "car", assignedDriverId } = req.body || {};
  if (!tripId) return res.status(400).json({ message: "tripId is required" });
  const existing = trips.get(String(tripId));
  if (existing) return res.status(409).json({ message: "Trip already exists", trip: existing });

  const trip: TripRecord = {
    tripId: String(tripId),
    serviceType: String(serviceType),
    state: assignedDriverId ? "driver_assigned" : "requested",
    pickupOtp: createOtp(),
    deliveryOtp: ["parcel", "hyperlocal"].includes(String(serviceType)) ? createOtp() : undefined,
    assignedDriverId: assignedDriverId ? String(assignedDriverId) : undefined,
    createdAt: nowIso(),
    updatedAt: nowIso(),
    events: [],
  };
  pushEvent(trip, "trip_created", { assignedDriverId: trip.assignedDriverId });
  trips.set(trip.tripId, trip);
  res.status(201).json({ trip });
});

app.post("/internal/trips/:tripId/start", (req, res) => {
  const { tripId } = req.params;
  const { pickupOtp, driverId } = req.body || {};
  const trip = trips.get(tripId);
  if (!trip) return res.status(404).json({ message: "Trip not found" });
  if (!["driver_assigned", "arrived", "otp_verified"].includes(trip.state)) {
    return res.status(409).json({ message: `Trip cannot start from state ${trip.state}` });
  }
  if (!pickupOtp || String(pickupOtp) !== String(trip.pickupOtp)) {
    return res.status(400).json({ message: "Invalid pickup OTP" });
  }
  if (driverId && trip.assignedDriverId && String(driverId) !== String(trip.assignedDriverId)) {
    return res.status(403).json({ message: "Driver does not own this trip" });
  }

  trip.state = "in_progress";
  pushEvent(trip, "trip_started", { driverId: driverId || trip.assignedDriverId });
  res.json({
    tripId,
    accepted: true,
    pickupOtpRequired: true,
    status: "in_progress",
    ts: nowIso(),
  });
});

app.post("/internal/trips/:tripId/complete", (req, res) => {
  const { tripId } = req.params;
  const { actualFare, deliveryOtp } = req.body || {};
  const trip = trips.get(tripId);
  if (!trip) return res.status(404).json({ message: "Trip not found" });
  if (trip.state !== "in_progress") {
    return res.status(409).json({ message: `Trip cannot complete from state ${trip.state}` });
  }
  if (trip.deliveryOtp && String(deliveryOtp || "") !== String(trip.deliveryOtp)) {
    return res.status(400).json({ message: "Invalid delivery OTP" });
  }

  trip.state = "completed";
  pushEvent(trip, "trip_completed", { actualFare: Number(actualFare || 0) });
  res.json({
    tripId,
    completed: true,
    actualFare: Number(actualFare || 0),
    status: "completed",
  });
});

app.post("/internal/trips/:tripId/arrive", (req, res) => {
  const { tripId } = req.params;
  const trip = trips.get(tripId);
  if (!trip) return res.status(404).json({ message: "Trip not found" });
  if (!["driver_assigned", "matched"].includes(trip.state)) {
    return res.status(409).json({ message: `Trip cannot mark arrived from ${trip.state}` });
  }
  trip.state = "arrived";
  pushEvent(trip, "driver_arrived");
  res.json({ tripId, status: trip.state });
});

app.post("/internal/trips/:tripId/cancel", (req, res) => {
  const { tripId } = req.params;
  const { reason, cancelledBy } = req.body || {};
  const trip = trips.get(tripId);
  if (!trip) return res.status(404).json({ message: "Trip not found" });
  if (["completed", "cancelled"].includes(trip.state)) {
    return res.status(409).json({ message: `Trip already ${trip.state}` });
  }
  trip.state = "cancelled";
  pushEvent(trip, "trip_cancelled", { reason, cancelledBy });
  res.json({ tripId, status: trip.state });
});

app.get("/internal/trips/:tripId", (req, res) => {
  const { tripId } = req.params;
  const trip = trips.get(tripId);
  if (!trip) return res.status(404).json({ message: "Trip not found" });
  res.json({ trip });
});

app.listen(port, () => {
  console.log(`[trip-service] listening on ${port}`);
});
