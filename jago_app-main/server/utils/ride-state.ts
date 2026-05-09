export const CANONICAL_RIDE_STATES = [
  "requested",
  "driver_assigned",
  "driver_accepting",
  "accepted",
  "heading_to_pickup",
  "arrived",
  "waiting",
  "otp_pending",
  "otp_verified",
  "in_progress",
  "heading_to_destination",
  "completed",
  "cancelled_by_user",
  "cancelled_by_driver",
  "cancelled_by_admin",
  "expired",
  "failed",
] as const;

export type CanonicalRideState = (typeof CANONICAL_RIDE_STATES)[number];

const CANONICAL_SET = new Set<string>(CANONICAL_RIDE_STATES);

export function isCanonicalRideState(value: unknown): value is CanonicalRideState {
  return typeof value === "string" && CANONICAL_SET.has(value);
}

export function getCanonicalRideState(trip: any, opts?: { waitingGraceSeconds?: number }): CanonicalRideState {
  const raw = String(trip?.currentStatus || trip?.current_status || "requested").trim().toLowerCase();
  const cancelledBy = String(trip?.cancelledBy || trip?.cancelled_by || "").trim().toLowerCase();
  const waitingGraceSeconds = opts?.waitingGraceSeconds ?? 180;
  const arrivedAt = trip?.arrivedAt || trip?.arrived_at;
  const rideStartedAt = trip?.rideStartedAt || trip?.ride_started_at;
  const completedAt = trip?.completedAt || trip?.completed_at || trip?.rideEndedAt || trip?.ride_ended_at;

  if (isCanonicalRideState(raw)) return raw;

  switch (raw) {
    case "pending":
    case "searching":
      return "requested";
    case "driver_assigned":
      return "driver_assigned";
    case "accepted":
      return "heading_to_pickup";
    case "arrived": {
      if (!arrivedAt) return "arrived";
      const elapsedSeconds = Math.max(0, Math.floor((Date.now() - new Date(arrivedAt).getTime()) / 1000));
      if (elapsedSeconds >= waitingGraceSeconds) return "waiting";
      return "otp_pending";
    }
    case "on_the_way":
    case "ongoing":
      return rideStartedAt ? "in_progress" : "otp_verified";
    case "payment_pending":
      return "completed";
    case "completed":
      return completedAt ? "completed" : "heading_to_destination";
    case "expired":
      return "expired";
    case "failed":
      return "failed";
    case "cancelled":
      if (cancelledBy === "customer" || cancelledBy === "user") return "cancelled_by_user";
      if (cancelledBy === "driver") return "cancelled_by_driver";
      if (cancelledBy === "admin") return "cancelled_by_admin";
      return "failed";
    default:
      return "failed";
  }
}

export function toLegacyRideStatus(input: string): string {
  const normalized = String(input || "").trim().toLowerCase();
  if (isCanonicalRideState(normalized)) {
    switch (normalized) {
      case "requested":
        return "searching";
      case "driver_assigned":
        return "driver_assigned";
      case "driver_accepting":
      case "accepted":
      case "heading_to_pickup":
        return "accepted";
      case "arrived":
      case "waiting":
      case "otp_pending":
        return "arrived";
      case "otp_verified":
      case "in_progress":
      case "heading_to_destination":
        return "on_the_way";
      case "completed":
        return "completed";
      case "cancelled_by_user":
      case "cancelled_by_driver":
      case "cancelled_by_admin":
        return "cancelled";
      case "expired":
        return "expired";
      case "failed":
      default:
        return "failed";
    }
  }
  return normalized;
}

export function buildRideLifecycleMeta(trip: any, opts?: { waitingGraceSeconds?: number; waitingChargePerMin?: number }) {
  const canonicalState = getCanonicalRideState(trip, { waitingGraceSeconds: opts?.waitingGraceSeconds });
  const arrivedAtRaw = trip?.arrivedAt || trip?.arrived_at;
  const waitingGraceSeconds = opts?.waitingGraceSeconds ?? 180;
  const waitingChargePerMin = Number(opts?.waitingChargePerMin || trip?.waitingChargePerMin || trip?.waiting_charge_per_min || 0);
  const arrivedAt = arrivedAtRaw ? new Date(arrivedAtRaw) : null;
  const waitingElapsedSeconds = arrivedAt ? Math.max(0, Math.floor((Date.now() - arrivedAt.getTime()) / 1000)) : 0;
  const waitingBillableSeconds = Math.max(0, waitingElapsedSeconds - waitingGraceSeconds);
  const waitingCharge = waitingChargePerMin > 0
    ? Number(((waitingBillableSeconds / 60) * waitingChargePerMin).toFixed(2))
    : 0;

  return {
    canonicalState,
    lifecycle: {
      canonicalState,
      waiting: {
        active: canonicalState === "waiting" || canonicalState === "otp_pending",
        arrivedAt: arrivedAt ? arrivedAt.toISOString() : null,
        graceSeconds: waitingGraceSeconds,
        elapsedSeconds: waitingElapsedSeconds,
        billableSeconds: waitingBillableSeconds,
        waitingChargePerMin,
        waitingCharge,
      },
      paymentPending: String(trip?.currentStatus || trip?.current_status || "").trim().toLowerCase() === "payment_pending",
    },
  };
}

export function canTransitionRideState(previous: string, next: string): boolean {
  const from = getCanonicalRideState({ current_status: toLegacyRideStatus(previous) });
  const to = getCanonicalRideState({ current_status: toLegacyRideStatus(next) });
  const allowed: Record<CanonicalRideState, CanonicalRideState[]> = {
    requested: ["driver_assigned", "driver_accepting", "accepted", "cancelled_by_user", "cancelled_by_admin", "expired", "failed"],
    driver_assigned: ["driver_accepting", "accepted", "cancelled_by_user", "cancelled_by_admin", "expired", "failed"],
    driver_accepting: ["accepted", "cancelled_by_user", "cancelled_by_admin", "expired", "failed"],
    accepted: ["heading_to_pickup", "arrived", "cancelled_by_user", "cancelled_by_driver", "cancelled_by_admin", "failed"],
    heading_to_pickup: ["arrived", "cancelled_by_user", "cancelled_by_driver", "cancelled_by_admin", "failed"],
    arrived: ["waiting", "otp_pending", "otp_verified", "cancelled_by_user", "cancelled_by_driver", "cancelled_by_admin", "failed"],
    waiting: ["otp_pending", "otp_verified", "cancelled_by_user", "cancelled_by_driver", "cancelled_by_admin", "failed"],
    otp_pending: ["otp_verified", "cancelled_by_user", "cancelled_by_driver", "cancelled_by_admin", "failed"],
    otp_verified: ["in_progress", "heading_to_destination", "cancelled_by_user", "cancelled_by_driver", "cancelled_by_admin", "failed"],
    in_progress: ["heading_to_destination", "completed", "cancelled_by_admin", "failed"],
    heading_to_destination: ["completed", "cancelled_by_admin", "failed"],
    completed: [],
    cancelled_by_user: [],
    cancelled_by_driver: [],
    cancelled_by_admin: [],
    expired: [],
    failed: [],
  };

  if (from === to) return true;
  return allowed[from]?.includes(to) ?? false;
}
