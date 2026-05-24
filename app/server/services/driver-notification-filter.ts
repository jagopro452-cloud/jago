import {
  isDriverEligibleForDispatch,
  resolveDispatchRequirementsFromTrip,
  type DispatchRequirements,
} from "../dispatch-eligibility";

type FilterLogEvent =
  | "DRIVER_FILTER_REJECT"
  | "POOL_DISPATCH_REJECT"
  | "OUTSTATION_CATEGORY_REJECT"
  | "WRONG_CATEGORY_NOTIFICATION_BLOCKED";

type ValidateDriverTripNotificationInput = {
  driverId: string;
  tripId: string;
  source: string;
  requirements?: DispatchRequirements | null;
};

type ValidateDriverTripNotificationResult = {
  ok: boolean;
  reason?: string;
  requirements?: DispatchRequirements | null;
};

function logFilterReject(event: FilterLogEvent, meta: Record<string, unknown>): void {
  console.warn(`[${event}] ${JSON.stringify(meta)}`);
}

function classifyReject(requirements: DispatchRequirements | null | undefined, reason: string): FilterLogEvent {
  if (
    requirements?.platformServiceKey === "outstation_pool" ||
    requirements?.dispatchServiceType === "outstation_pool" ||
    reason === "outstation_not_enabled"
  ) {
    return "OUTSTATION_CATEGORY_REJECT";
  }
  if (
    requirements?.platformServiceKey === "city_pool" ||
    requirements?.dispatchServiceType === "city_pool" ||
    reason === "pool_not_enabled" ||
    reason === "seat_capacity_low"
  ) {
    return "POOL_DISPATCH_REJECT";
  }
  return "DRIVER_FILTER_REJECT";
}

export async function validateDriverTripNotificationTarget(
  input: ValidateDriverTripNotificationInput,
): Promise<ValidateDriverTripNotificationResult> {
  const requirements = input.requirements || await resolveDispatchRequirementsFromTrip(input.tripId);
  if (!requirements) {
    const meta = {
      source: input.source,
      driverId: input.driverId,
      tripId: input.tripId,
      reason: "requirements_missing",
    };
    logFilterReject("DRIVER_FILTER_REJECT", meta);
    logFilterReject("WRONG_CATEGORY_NOTIFICATION_BLOCKED", meta);
    return { ok: false, reason: "requirements_missing", requirements: null };
  }

  if (!requirements.vehicleCategoryId) {
    const meta = {
      source: input.source,
      driverId: input.driverId,
      tripId: input.tripId,
      reason: "missing_vehicle_category",
      platformServiceKey: requirements.platformServiceKey,
      dispatchServiceType: requirements.dispatchServiceType,
    };
    logFilterReject("DRIVER_FILTER_REJECT", meta);
    logFilterReject("WRONG_CATEGORY_NOTIFICATION_BLOCKED", meta);
    return { ok: false, reason: "missing_vehicle_category", requirements };
  }

  const eligibility = await isDriverEligibleForDispatch(input.driverId, requirements);
  if (!eligibility.eligible) {
    const reason = eligibility.reason || "not_eligible";
    const meta = {
      source: input.source,
      driverId: input.driverId,
      tripId: input.tripId,
      reason,
      vehicleCategoryId: requirements.vehicleCategoryId,
      vehicleCategoryKey: requirements.vehicleCategoryKey,
      platformServiceKey: requirements.platformServiceKey,
      dispatchServiceType: requirements.dispatchServiceType,
      requiresParcel: requirements.requiresParcel,
      requiresPool: requirements.requiresPool,
      requiresOutstation: requirements.requiresOutstation,
      requiresIntercity: requirements.requiresIntercity,
      driverVehicleCategoryId: eligibility.profile?.vehicleCategoryId || null,
      driverServices: eligibility.profile?.serviceEligibility || [],
    };
    logFilterReject(classifyReject(requirements, reason), meta);
    logFilterReject("WRONG_CATEGORY_NOTIFICATION_BLOCKED", meta);
    return { ok: false, reason, requirements };
  }

  return { ok: true, requirements };
}
