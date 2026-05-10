type RedisHealth = {
  status: "unknown" | "connected" | "degraded";
  adapterMode: "unknown" | "redis" | "memory";
  lastChangeAt: string | null;
  lastError: string | null;
};

type SocketHealth = {
  authFailures: number;
  disconnects: number;
  lastDisconnectAt: string | null;
  lastDisconnectReason: string | null;
  lastDisconnectUserType: string | null;
};

type RuntimePublish = {
  publishCount: number;
  lastPublishAt: string | null;
  lastPublisher: string | null;
  lastKeys: string[];
  failureCount: number;
  lastFailureAt: string | null;
  lastFailureMessage: string | null;
};

type ApiHealth = {
  totalRequests: number;
  errorResponses: number;
  slowRequests: number;
  lastSlowRequest: null | {
    method: string;
    path: string;
    statusCode: number;
    durationMs: number;
    at: string;
  };
};

type RideTelemetrySeverity = "info" | "warning" | "critical";
type DriverOperationalState =
  | "healthy"
  | "reconnecting"
  | "stale_tracking"
  | "weak_signal"
  | "inactive_socket"
  | "recovery_pending";

type TrackingFreshness = "healthy" | "delayed" | "stale" | "frozen";

type RideOpsAlert = {
  id: string;
  tripId: string;
  driverId: string | null;
  customerId: string | null;
  code: string;
  severity: RideTelemetrySeverity;
  message: string;
  lastKnownLocation: null | { lat: number; lng: number; heading: number; speed: number };
  lastHeartbeatAt: string | null;
  recoveryAttempts: number;
  at: string;
  details?: Record<string, unknown>;
};

type RideTelemetry = {
  tripId: string;
  refId: string | null;
  driverId: string | null;
  customerId: string | null;
  driverName: string | null;
  customerName: string | null;
  vehicleCategory: string | null;
  canonicalState: string;
  uiState: string | null;
  waitingActive: boolean;
  waitingCharge: number;
  waitingElapsedSeconds: number;
  waitingBillableSeconds: number;
  lastLifecycleAt: string | null;
  lastLocationAt: string | null;
  lastSocketHeartbeatAt: string | null;
  trackingFreshness: TrackingFreshness;
  driverOperationalState: DriverOperationalState;
  trackingQualityState: string;
  reconnectCount: number;
  recoveryCount: number;
  duplicateSuppressionCount: number;
  staleEventCount: number;
  eventOrderingViolations: number;
  recoveryState: "idle" | "recovery_in_progress" | "recovered" | "recovery_failed";
  recoverySource: string | null;
  recoverySuccess: boolean | null;
  lastRecoveryAt: string | null;
  staleDurationSeconds: number;
  unhealthyReason: string | null;
  location: null | { lat: number; lng: number; heading: number; speed: number };
  updatedAt: string;
};

const redisHealth: RedisHealth = {
  status: "unknown",
  adapterMode: "unknown",
  lastChangeAt: null,
  lastError: null,
};

const socketHealth: SocketHealth = {
  authFailures: 0,
  disconnects: 0,
  lastDisconnectAt: null,
  lastDisconnectReason: null,
  lastDisconnectUserType: null,
};

const runtimePublish: RuntimePublish = {
  publishCount: 0,
  lastPublishAt: null,
  lastPublisher: null,
  lastKeys: [],
  failureCount: 0,
  lastFailureAt: null,
  lastFailureMessage: null,
};

const apiHealth: ApiHealth = {
  totalRequests: 0,
  errorResponses: 0,
  slowRequests: 0,
  lastSlowRequest: null,
};

const rideTelemetry = new Map<string, RideTelemetry>();
const rideAlerts: RideOpsAlert[] = [];

const TRACKING_DELAYED_MS = 20_000;
const TRACKING_STALE_MS = 45_000;
const TRACKING_FROZEN_MS = 90_000;
const TELEMETRY_ACTIVE_TTL_MS = 2 * 60 * 60 * 1000;
const ALERT_HISTORY_LIMIT = 80;

const SLOW_REQUEST_MS = 1500;

function nowIso() {
  return new Date().toISOString();
}

function parseIsoMs(value: string | null | undefined): number | null {
  if (!value) return null;
  const ts = Date.parse(value);
  return Number.isFinite(ts) ? ts : null;
}

function ensureRideTelemetry(tripId: string): RideTelemetry {
  const existing = rideTelemetry.get(tripId);
  if (existing) return existing;
  const next: RideTelemetry = {
    tripId,
    refId: null,
    driverId: null,
    customerId: null,
    driverName: null,
    customerName: null,
    vehicleCategory: null,
    canonicalState: "requested",
    uiState: null,
    waitingActive: false,
    waitingCharge: 0,
    waitingElapsedSeconds: 0,
    waitingBillableSeconds: 0,
    lastLifecycleAt: null,
    lastLocationAt: null,
    lastSocketHeartbeatAt: null,
    trackingFreshness: "healthy",
    driverOperationalState: "healthy",
    trackingQualityState: "healthy",
    reconnectCount: 0,
    recoveryCount: 0,
    duplicateSuppressionCount: 0,
    staleEventCount: 0,
    eventOrderingViolations: 0,
    recoveryState: "idle",
    recoverySource: null,
    recoverySuccess: null,
    lastRecoveryAt: null,
    staleDurationSeconds: 0,
    unhealthyReason: null,
    location: null,
    updatedAt: nowIso(),
  };
  rideTelemetry.set(tripId, next);
  return next;
}

function recomputeRideHealth(entry: RideTelemetry) {
  const now = Date.now();
  const lastLocationMs = parseIsoMs(entry.lastLocationAt);
  const lastHeartbeatMs = parseIsoMs(entry.lastSocketHeartbeatAt);
  const freshestMs = Math.max(lastLocationMs || 0, lastHeartbeatMs || 0);
  const ageMs = freshestMs > 0 ? now - freshestMs : TRACKING_FROZEN_MS + 1;
  entry.staleDurationSeconds = freshestMs > 0 ? Math.max(0, Math.floor(ageMs / 1000)) : 0;

  if (!lastLocationMs && !lastHeartbeatMs) {
    entry.trackingFreshness = "frozen";
    entry.driverOperationalState = "inactive_socket";
    entry.trackingQualityState = "inactive_socket";
    entry.unhealthyReason = "No active telemetry heartbeat";
    return;
  }

  if (ageMs >= TRACKING_FROZEN_MS) {
    entry.trackingFreshness = "frozen";
    entry.driverOperationalState =
      entry.recoveryState === "recovery_in_progress" ? "recovery_pending" : "inactive_socket";
    entry.trackingQualityState = "frozen";
    entry.unhealthyReason = "Driver tracking is frozen";
    return;
  }

  if (ageMs >= TRACKING_STALE_MS) {
    entry.trackingFreshness = "stale";
    entry.driverOperationalState = "stale_tracking";
    entry.trackingQualityState = "stale_tracking";
    entry.unhealthyReason = "Driver tracking is stale";
    return;
  }

  if (ageMs >= TRACKING_DELAYED_MS) {
    entry.trackingFreshness = "delayed";
    entry.driverOperationalState =
      entry.recoveryState === "recovery_in_progress" ? "reconnecting" : "weak_signal";
    entry.trackingQualityState = "weak_signal";
    entry.unhealthyReason = "Driver tracking is delayed";
    return;
  }

  entry.trackingFreshness = "healthy";
  entry.driverOperationalState =
    entry.recoveryState === "recovery_in_progress"
      ? "reconnecting"
      : entry.recoveryState === "recovered"
        ? "healthy"
        : "healthy";
  entry.trackingQualityState = "healthy";
  entry.unhealthyReason = null;
}

function pushRideAlert(
  entry: RideTelemetry,
  code: string,
  severity: RideTelemetrySeverity,
  message: string,
  details?: Record<string, unknown>,
) {
  const latest = rideAlerts[0];
  if (latest && latest.tripId === entry.tripId && latest.code === code) {
    return;
  }
  rideAlerts.unshift({
    id: `${entry.tripId}:${code}:${Date.now()}`,
    tripId: entry.tripId,
    driverId: entry.driverId,
    customerId: entry.customerId,
    code,
    severity,
    message,
    lastKnownLocation: entry.location,
    lastHeartbeatAt: entry.lastSocketHeartbeatAt || entry.lastLocationAt,
    recoveryAttempts: entry.recoveryCount,
    at: nowIso(),
    details,
  });
  if (rideAlerts.length > ALERT_HISTORY_LIMIT) {
    rideAlerts.length = ALERT_HISTORY_LIMIT;
  }
}

function finalizeRideTelemetry(entry: RideTelemetry) {
  recomputeRideHealth(entry);
  if (entry.trackingFreshness === "stale") {
    pushRideAlert(entry, "stale_tracking", "warning", "Ride tracking is stale");
  } else if (entry.trackingFreshness === "frozen") {
    pushRideAlert(entry, "frozen_tracking", "critical", "Ride tracking is frozen");
  }
  if (entry.reconnectCount >= 3) {
    pushRideAlert(entry, "reconnect_storm", "warning", "Repeated reconnects detected");
  }
}

function trimInactiveRideTelemetry() {
  const now = Date.now();
  for (const [tripId, entry] of Array.from(rideTelemetry.entries())) {
    const updatedAtMs = parseIsoMs(entry.updatedAt) || 0;
    const terminal = ["completed", "cancelled_by_user", "cancelled_by_driver", "cancelled_by_admin", "expired", "failed"]
      .includes(entry.canonicalState);
    if (terminal && updatedAtMs > 0 && now - updatedAtMs > TELEMETRY_ACTIVE_TTL_MS) {
      rideTelemetry.delete(tripId);
    }
  }
}

export function noteRedisHealthy(adapterMode: RedisHealth["adapterMode"]) {
  redisHealth.status = "connected";
  redisHealth.adapterMode = adapterMode;
  redisHealth.lastChangeAt = nowIso();
  redisHealth.lastError = null;
}

export function noteRedisDegraded(message: string, adapterMode: RedisHealth["adapterMode"] = "memory") {
  redisHealth.status = "degraded";
  redisHealth.adapterMode = adapterMode;
  redisHealth.lastChangeAt = nowIso();
  redisHealth.lastError = message;
}

export function noteSocketAuthFailure() {
  socketHealth.authFailures += 1;
}

export function noteSocketDisconnect(reason: string, userType: string) {
  socketHealth.disconnects += 1;
  socketHealth.lastDisconnectAt = nowIso();
  socketHealth.lastDisconnectReason = reason;
  socketHealth.lastDisconnectUserType = userType;
}

export function noteRuntimeConfigPublish(keys: string[], publisher?: string | null) {
  runtimePublish.publishCount += 1;
  runtimePublish.lastPublishAt = nowIso();
  runtimePublish.lastPublisher = publisher || null;
  runtimePublish.lastKeys = keys.slice(0, 50);
}

export function noteRuntimeConfigFailure(message: string, publisher?: string | null) {
  runtimePublish.failureCount += 1;
  runtimePublish.lastFailureAt = nowIso();
  runtimePublish.lastFailureMessage = message;
  if (publisher) {
    runtimePublish.lastPublisher = publisher;
  }
}

export function recordApiRequest(method: string, path: string, statusCode: number, durationMs: number) {
  apiHealth.totalRequests += 1;
  if (statusCode >= 500) {
    apiHealth.errorResponses += 1;
  }
  if (durationMs >= SLOW_REQUEST_MS) {
    apiHealth.slowRequests += 1;
    apiHealth.lastSlowRequest = {
      method,
      path,
      statusCode,
      durationMs,
      at: nowIso(),
    };
  }
}

export function getOpsSnapshot() {
  return {
    redis: { ...redisHealth },
    socket: { ...socketHealth },
    runtimeConfig: { ...runtimePublish },
    api: {
      ...apiHealth,
      slowThresholdMs: SLOW_REQUEST_MS,
    },
  };
}

export function noteRideLifecycle(payload: any, eventType = "lifecycle") {
  const tripId = String(payload?.tripId || payload?.id || "").trim();
  if (!tripId) return;
  const entry = ensureRideTelemetry(tripId);
  entry.refId = payload?.refId?.toString?.() || entry.refId;
  entry.driverId = payload?.driverId?.toString?.() || entry.driverId;
  entry.customerId = payload?.customerId?.toString?.() || entry.customerId;
  entry.driverName = payload?.driverName?.toString?.() || entry.driverName;
  entry.customerName = payload?.customerName?.toString?.() || entry.customerName;
  entry.vehicleCategory = payload?.vehicleName?.toString?.() || entry.vehicleCategory;
  entry.canonicalState = String(payload?.canonicalState || entry.canonicalState);
  entry.uiState = payload?.uiState?.toString?.() || entry.uiState;
  entry.waitingActive = payload?.lifecycle?.waiting?.active === true;
  entry.waitingCharge = Number(payload?.lifecycle?.waiting?.waitingCharge || 0);
  entry.waitingElapsedSeconds = Number(payload?.lifecycle?.waiting?.elapsedSeconds || 0);
  entry.waitingBillableSeconds = Number(payload?.lifecycle?.waiting?.billableSeconds || 0);
  entry.lastLifecycleAt = payload?.serverTimestamp?.toString?.() || nowIso();
  entry.lastSocketHeartbeatAt = entry.lastLifecycleAt;
  entry.updatedAt = nowIso();
  if (eventType === "recovered") {
    entry.recoveryState = "recovered";
    entry.recoverySuccess = true;
  }
  finalizeRideTelemetry(entry);
  trimInactiveRideTelemetry();
}

export function noteRideTracking(event: {
  tripId: string;
  driverId?: string | null;
  customerId?: string | null;
  lat: number;
  lng: number;
  heading?: number;
  speed?: number;
  serverTimestamp?: string;
}) {
  const tripId = String(event.tripId || "").trim();
  if (!tripId) return;
  const entry = ensureRideTelemetry(tripId);
  entry.driverId = event.driverId || entry.driverId;
  entry.customerId = event.customerId || entry.customerId;
  entry.location = {
    lat: event.lat,
    lng: event.lng,
    heading: Number(event.heading || 0),
    speed: Number(event.speed || 0),
  };
  entry.lastLocationAt = event.serverTimestamp || nowIso();
  entry.lastSocketHeartbeatAt = entry.lastLocationAt;
  entry.updatedAt = nowIso();
  finalizeRideTelemetry(entry);
}

export function noteRideRecovery(event: {
  tripId: string;
  source: string;
  success?: boolean;
  driverId?: string | null;
  customerId?: string | null;
}) {
  const tripId = String(event.tripId || "").trim();
  if (!tripId) return;
  const entry = ensureRideTelemetry(tripId);
  entry.driverId = event.driverId || entry.driverId;
  entry.customerId = event.customerId || entry.customerId;
  entry.recoveryCount += 1;
  entry.recoverySource = event.source;
  entry.recoveryState = event.success === false ? "recovery_failed" : "recovered";
  entry.recoverySuccess = event.success !== false;
  entry.lastRecoveryAt = nowIso();
  entry.lastSocketHeartbeatAt = entry.lastRecoveryAt;
  entry.updatedAt = nowIso();
  if (event.success === false) {
    pushRideAlert(entry, "recovery_failed", "critical", "Ride recovery failed");
  }
  finalizeRideTelemetry(entry);
}

export function noteRideReconnect(event: {
  tripId?: string | null;
  driverId?: string | null;
  source: string;
}) {
  const tripId = String(event.tripId || "").trim();
  if (!tripId) return;
  const entry = ensureRideTelemetry(tripId);
  entry.driverId = event.driverId || entry.driverId;
  entry.reconnectCount += 1;
  entry.recoveryState = "recovery_in_progress";
  entry.recoverySource = event.source;
  entry.lastSocketHeartbeatAt = nowIso();
  entry.updatedAt = nowIso();
  finalizeRideTelemetry(entry);
}

export function noteRideSocketAnomaly(event: {
  tripId?: string | null;
  driverId?: string | null;
  type: "duplicate_suppressed" | "stale_event" | "ordering_violation";
}) {
  const tripId = String(event.tripId || "").trim();
  if (!tripId) return;
  const entry = ensureRideTelemetry(tripId);
  entry.driverId = event.driverId || entry.driverId;
  if (event.type === "duplicate_suppressed") entry.duplicateSuppressionCount += 1;
  if (event.type === "stale_event") entry.staleEventCount += 1;
  if (event.type === "ordering_violation") entry.eventOrderingViolations += 1;
  entry.updatedAt = nowIso();
  finalizeRideTelemetry(entry);
}

export function noteRideRouteFailure(event: {
  tripId?: string | null;
  driverId?: string | null;
  customerId?: string | null;
  code: string;
  message: string;
  severity?: RideTelemetrySeverity;
  canonicalState?: string | null;
  details?: Record<string, unknown>;
}) {
  const tripId = String(event.tripId || "").trim();
  if (!tripId) return;
  const entry = ensureRideTelemetry(tripId);
  entry.driverId = event.driverId || entry.driverId;
  entry.customerId = event.customerId || entry.customerId;
  entry.updatedAt = nowIso();
  if (event.canonicalState) {
    entry.canonicalState = String(event.canonicalState);
  }
  entry.unhealthyReason = event.message;
  pushRideAlert(
    entry,
    event.code,
    event.severity || "warning",
    event.message,
    event.details,
  );
  finalizeRideTelemetry(entry);
}

export function getRideTelemetrySnapshot() {
  trimInactiveRideTelemetry();
  const rides = Array.from(rideTelemetry.values())
    .map((entry) => {
      finalizeRideTelemetry(entry);
      return { ...entry };
    })
    .sort((a, b) => {
      const aTs = parseIsoMs(a.updatedAt) || 0;
      const bTs = parseIsoMs(b.updatedAt) || 0;
      return bTs - aTs;
    });

  const summary = {
    activeRides: rides.filter((ride) =>
      !["completed", "cancelled_by_user", "cancelled_by_driver", "cancelled_by_admin", "expired", "failed"].includes(ride.canonicalState)
    ).length,
    waitingRides: rides.filter((ride) => ride.waitingActive).length,
    reconnectingRides: rides.filter((ride) => ride.driverOperationalState === "reconnecting").length,
    recoveryPendingRides: rides.filter((ride) => ride.driverOperationalState === "recovery_pending").length,
    staleTrackingRides: rides.filter((ride) => ["stale", "frozen"].includes(ride.trackingFreshness)).length,
    weakSignalRides: rides.filter((ride) => ride.driverOperationalState === "weak_signal").length,
    criticalAlerts: rideAlerts.filter((alert) => alert.severity === "critical").length,
    warningAlerts: rideAlerts.filter((alert) => alert.severity === "warning").length,
  };

  return {
    generatedAt: nowIso(),
    thresholds: {
      delayedMs: TRACKING_DELAYED_MS,
      staleMs: TRACKING_STALE_MS,
      frozenMs: TRACKING_FROZEN_MS,
    },
    summary,
    rides,
    alerts: rideAlerts.slice(0, 30),
  };
}
