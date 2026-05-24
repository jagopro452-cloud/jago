import { db as rawDb } from "../db";
import { sql as rawSql } from "drizzle-orm";
import {
  isDriverEligibleForDispatch,
  resolveDispatchRequirementsFromTrip,
} from "../dispatch-eligibility";

type RecoveryValidationInput = {
  driverId: string;
  tripId: string;
  source: string;
  requireCurrentOffer?: boolean;
  clearInvalidOffer?: boolean;
};

type RecoveryValidationResult = {
  ok: boolean;
  reason?: string;
};

async function clearOfferIfOwned(tripId: string, driverId: string): Promise<void> {
  await rawDb.execute(rawSql`
    UPDATE trip_requests
    SET offered_driver_id=NULL,
        offer_expires_at=NULL,
        offer_payload=NULL,
        updated_at=NOW()
    WHERE id=${tripId}::uuid
      AND offered_driver_id=${driverId}::uuid
  `).catch(() => undefined);
}

function logRecoveryReject(
  event: "RECOVERY_TRIP_REJECTED" | "RECOVERY_CATEGORY_MISMATCH" | "RECOVERY_STALE_TRIP_BLOCKED",
  meta: Record<string, unknown>,
): void {
  const tripId = typeof meta.tripId === "string" ? meta.tripId : null;
  console.warn(`[${event}] ${JSON.stringify({
    ts: new Date().toISOString(),
    bookingTraceId: meta.bookingTraceId || tripId,
    ...meta,
  })}`);
}

export async function validateRecoveryTripOffer(
  input: RecoveryValidationInput,
): Promise<RecoveryValidationResult> {
  const { driverId, tripId, source, requireCurrentOffer = false, clearInvalidOffer = false } = input;
  const tripR = await rawDb.execute(rawSql`
    SELECT id, current_status, driver_id, vehicle_category_id, offered_driver_id, offer_expires_at, trip_type
    FROM trip_requests
    WHERE id=${tripId}::uuid
    LIMIT 1
  `).catch(() => ({ rows: [] as any[] }));

  if (!tripR.rows.length) {
    logRecoveryReject("RECOVERY_TRIP_REJECTED", { source, tripId, driverId, reason: "trip_not_found" });
    return { ok: false, reason: "trip_not_found" };
  }

  const trip = tripR.rows[0] as any;
  const status = String(trip.current_status || "");
  if (status !== "searching" || trip.driver_id) {
    logRecoveryReject("RECOVERY_STALE_TRIP_BLOCKED", {
      source,
      tripId,
      driverId,
      status,
      assignedDriverId: trip.driver_id || null,
    });
    return { ok: false, reason: "stale_trip" };
  }

  const offeredDriverId = trip.offered_driver_id ? String(trip.offered_driver_id) : "";
  const offerExpiresAt = trip.offer_expires_at ? new Date(trip.offer_expires_at).getTime() : 0;
  const offerActive = offeredDriverId === driverId && offerExpiresAt > Date.now();
  if (requireCurrentOffer && !offerActive) {
    logRecoveryReject("RECOVERY_STALE_TRIP_BLOCKED", {
      source,
      tripId,
      driverId,
      reason: "offer_not_current",
      offeredDriverId: offeredDriverId || null,
      offerExpiresAt: trip.offer_expires_at || null,
    });
    return { ok: false, reason: "offer_not_current" };
  }

  if (!trip.vehicle_category_id) {
    logRecoveryReject("RECOVERY_CATEGORY_MISMATCH", {
      source,
      tripId,
      driverId,
      reason: "missing_vehicle_category",
    });
    if (clearInvalidOffer) await clearOfferIfOwned(tripId, driverId);
    return { ok: false, reason: "missing_vehicle_category" };
  }

  const requirements = await resolveDispatchRequirementsFromTrip(tripId, tripId);
  if (!requirements) {
    logRecoveryReject("RECOVERY_TRIP_REJECTED", { source, tripId, driverId, reason: "requirements_missing" });
    if (clearInvalidOffer) await clearOfferIfOwned(tripId, driverId);
    return { ok: false, reason: "requirements_missing" };
  }

  const eligibility = await isDriverEligibleForDispatch(driverId, requirements);
  if (!eligibility.eligible) {
    const reason = eligibility.reason || "not_eligible";
    const event =
      reason === "vehicle_category_mismatch" ||
      reason === "service_not_enabled" ||
      reason === "parcel_not_enabled" ||
      reason === "pool_not_enabled" ||
      reason === "outstation_not_enabled" ||
      reason === "intercity_not_enabled"
        ? "RECOVERY_CATEGORY_MISMATCH"
        : "RECOVERY_TRIP_REJECTED";
    logRecoveryReject(event, {
      source,
      tripId,
      driverId,
      reason,
      tripType: requirements.tripType,
      platformServiceKey: requirements.platformServiceKey,
      vehicleCategoryId: requirements.vehicleCategoryId,
    });
    if (clearInvalidOffer) await clearOfferIfOwned(tripId, driverId);
    return { ok: false, reason };
  }

  return { ok: true };
}
