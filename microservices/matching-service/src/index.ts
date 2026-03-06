import express from "express";

const app = express();
const port = Number(process.env.MATCHING_PORT || 7101);
const defaultAcceptanceSeconds = Math.max(8, Number(process.env.DISPATCH_ACCEPTANCE_SECONDS || 20));

app.use(express.json());

type CandidateInput = {
  driverId: string;
  distanceKm?: number;
  rating?: number;
  acceptanceRate?: number;
  activeTrips?: number;
  isOnline?: boolean;
};

const dispatchState = new Map<string, {
  createdAt: number;
  acceptanceDeadlineEpochMs: number;
  selectedDriverId?: string;
  candidates: Array<{ driverId: string; score: number; distanceKm: number; etaMinutes: number }>;
}>();

function computeDriverScore(input: CandidateInput): number {
  const distanceKm = Math.max(0, Number(input.distanceKm || 99));
  const rating = Math.max(1, Math.min(5, Number(input.rating || 4)));
  const acceptanceRate = Math.max(0, Math.min(1, Number(input.acceptanceRate ?? 0.6)));
  const activeTrips = Math.max(0, Number(input.activeTrips || 0));

  // Weighted scoring for low-latency dispatch and load balancing.
  const distanceScore = Math.max(0, 100 - distanceKm * 18);
  const ratingScore = rating * 16;
  const reliabilityScore = acceptanceRate * 20;
  const loadPenalty = activeTrips * 8;
  return Math.max(0, Number((distanceScore + ratingScore + reliabilityScore - loadPenalty).toFixed(2)));
}

function toEtaMinutes(distanceKm: number, avgSpeedKmph = 25): number {
  if (!Number.isFinite(distanceKm) || distanceKm <= 0) return 1;
  return Math.max(1, Math.round((distanceKm / avgSpeedKmph) * 60));
}

function evaluateFraudSignals(serviceType: string, candidates: CandidateInput[]) {
  if (candidates.length === 0) {
    return {
      riskScore: 70,
      reason: "No eligible online drivers in 3-5 km dispatch ring",
      action: "review",
    };
  }
  const suspicious = candidates.filter((c) => Number(c.distanceKm || 99) < 0.05);
  if (suspicious.length >= 4) {
    return {
      riskScore: 55,
      reason: `Clustered candidate anomaly detected for ${serviceType}`,
      action: "challenge_otp",
    };
  }
  return { riskScore: 5, reason: "normal", action: "allow" };
}

app.get("/health", (_req, res) => {
  res.json({
    service: "matching-service",
    status: "ok",
    activeDispatchRequests: dispatchState.size,
    timestamp: new Date().toISOString(),
  });
});

app.post("/internal/matching/request", (req, res) => {
  const {
    requestId,
    serviceType = "car",
    pickupLat,
    pickupLng,
    radiusKm = 5,
    minRadiusKm = 3,
    limit = 5,
    candidates = [],
  } = req.body || {};

  const now = Date.now();
  const normalizedCandidates: CandidateInput[] = Array.isArray(candidates) ? candidates : [];
  const eligible = normalizedCandidates
    .filter((c) => c && c.driverId)
    .filter((c) => c.isOnline !== false)
    .filter((c) => Number(c.distanceKm || 99) >= Number(minRadiusKm || 0) ? Number(c.distanceKm || 99) <= Number(radiusKm || 5) : true);

  const ranked = eligible
    .map((c) => {
      const distanceKm = Number(c.distanceKm || 99);
      const etaMinutes = toEtaMinutes(distanceKm);
      return {
        driverId: c.driverId,
        score: computeDriverScore(c),
        distanceKm,
        etaMinutes,
      };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, Math.max(1, Number(limit || 5)));

  const selectedDriverId = ranked[0]?.driverId;
  const acceptanceDeadlineEpochMs = now + defaultAcceptanceSeconds * 1000;
  const effectiveRequestId = String(requestId || `req_${now}`);

  dispatchState.set(effectiveRequestId, {
    createdAt: now,
    acceptanceDeadlineEpochMs,
    selectedDriverId,
    candidates: ranked,
  });

  const fraud = evaluateFraudSignals(serviceType, eligible);

  res.json({
    request: { requestId: effectiveRequestId, serviceType, pickupLat, pickupLng, radiusKm, minRadiusKm, limit },
    candidates: ranked,
    selectedDriverId,
    acceptanceDeadlineEpochMs,
    dispatchTtlSeconds: defaultAcceptanceSeconds,
    strategy: "distance_rating_load_balanced_v1",
    fraud,
  });
});

app.post("/internal/matching/request/:requestId/accept", (req, res) => {
  const { requestId } = req.params;
  const { driverId } = req.body || {};
  const state = dispatchState.get(requestId);
  if (!state) return res.status(404).json({ message: "Dispatch request not found" });
  if (Date.now() > state.acceptanceDeadlineEpochMs) return res.status(409).json({ message: "Dispatch acceptance window expired" });
  if (!driverId) return res.status(400).json({ message: "driverId is required" });

  state.selectedDriverId = String(driverId);
  dispatchState.set(requestId, state);
  res.json({ accepted: true, requestId, selectedDriverId: state.selectedDriverId });
});

app.get("/internal/matching/request/:requestId", (req, res) => {
  const { requestId } = req.params;
  const state = dispatchState.get(requestId);
  if (!state) return res.status(404).json({ message: "Dispatch request not found" });
  res.json({ requestId, ...state, now: Date.now() });
});

app.listen(port, () => {
  console.log(`[matching-service] listening on ${port}`);
});
