import { db as rawDb } from "../db";
import { sql as rawSql } from "drizzle-orm";
import {
  appendTripStatus,
  logRideLifecycleEvent,
} from "../realtime-ops";

export type CancelActorType = "customer" | "driver" | "admin" | "system";

export interface CancelTripInput {
  tripId: string;
  actor: {
    id: string;
    type: CancelActorType;
  };
  reason?: string;
  source: "rest" | "socket" | "internal" | "admin";
}

export interface CancelTripResult {
  ok: true;
  idempotent: boolean;
  action: "cancelled" | "reassigned";
  trip: Record<string, any>;
  existingTrip: Record<string, any>;
  previousStatus: string;
}

export class CancelTripError extends Error {
  status: number;
  code: string;
  currentStatus?: string;

  constructor(status: number, code: string, message: string, currentStatus?: string) {
    super(message);
    this.status = status;
    this.code = code;
    this.currentStatus = currentStatus;
  }
}

const CANCELLABLE_STATES = new Set([
  "searching",
  "driver_assigned",
  "accepted",
  "arrived",
  "arriving",
]);

const FINAL_STATES = new Set(["completed", "cancelled"]);

function normalizeStatus(status: unknown): string {
  return String(status || "").trim().toLowerCase();
}

function publicMessageFor(status: string): string {
  if (FINAL_STATES.has(status)) return "Trip already ended";
  return "Cannot cancel after ride has started";
}

export async function cancelTrip(input: CancelTripInput): Promise<CancelTripResult> {
  const tripId = String(input.tripId || "").trim();
  const actorId = String(input.actor?.id || "").trim();
  const actorType = input.actor?.type;
  const reason = String(input.reason || `${actorType} cancelled`).trim();

  if (!tripId || !actorId || !actorType) {
    throw new CancelTripError(400, "INVALID_CANCEL_REQUEST", "Invalid cancellation request");
  }

  console.log(
    `[CANCEL_REQUESTED] trip=${tripId} actor=${actorType}:${actorId} source=${input.source}`,
  );

  const outcome = await rawDb.transaction(async (tx) => {
    const accessClause =
      actorType === "customer"
        ? rawSql`AND customer_id=${actorId}::uuid`
        : actorType === "driver"
          ? rawSql`AND driver_id=${actorId}::uuid`
          : rawSql``;

    const tripR = await tx.execute(rawSql`
      SELECT *
      FROM trip_requests
      WHERE id=${tripId}::uuid
        ${accessClause}
      FOR UPDATE
    `);

    if (!tripR.rows.length) {
      console.warn(`[CANCEL_REJECTED] trip=${tripId} actor=${actorType}:${actorId} reason=not_found_or_forbidden`);
      throw new CancelTripError(404, "TRIP_NOT_FOUND", "Trip not found or not cancellable by this user");
    }

    const existingTrip = tripR.rows[0] as any;
    const previousStatus = normalizeStatus(existingTrip.current_status);

    if (previousStatus === "cancelled") {
      console.log(`[CANCEL_ALLOWED] trip=${tripId} actor=${actorType}:${actorId} idempotent=true status=cancelled`);
      return {
        ok: true as const,
        idempotent: true,
        action: "cancelled" as const,
        trip: existingTrip,
        existingTrip,
        previousStatus,
      };
    }

    if (!CANCELLABLE_STATES.has(previousStatus)) {
      console.warn(
        `[CANCEL_REJECTED] trip=${tripId} actor=${actorType}:${actorId} status=${previousStatus}`,
      );
      throw new CancelTripError(409, "TRIP_CANCEL_FORBIDDEN", publicMessageFor(previousStatus), previousStatus);
    }

    console.log(`[CANCEL_ALLOWED] trip=${tripId} actor=${actorType}:${actorId} status=${previousStatus}`);

    if (actorType === "driver") {
      const updated = await tx.execute(rawSql`
        UPDATE trip_requests
        SET current_status='searching',
            driver_id=NULL,
            pickup_otp=NULL,
            driver_accepted_at=NULL,
            driver_arriving_at=NULL,
            cancel_reason=${reason},
            cancelled_by='driver',
            rejected_driver_ids = array_append(COALESCE(rejected_driver_ids,'{}'), ${actorId}::uuid),
            offered_driver_id=NULL,
            offer_expires_at=NULL,
            offer_payload=NULL,
            updated_at=NOW()
        WHERE id=${tripId}::uuid
        RETURNING *
      `);
      await tx.execute(rawSql`
        UPDATE users
        SET current_trip_id=NULL
        WHERE id=${actorId}::uuid
          AND current_trip_id=${tripId}::uuid
      `);
      return {
        ok: true as const,
        idempotent: false,
        action: "reassigned" as const,
        trip: updated.rows[0] as any,
        existingTrip,
        previousStatus,
      };
    }

    const updated = await tx.execute(rawSql`
      UPDATE trip_requests
      SET current_status='cancelled',
          cancelled_by=${actorType},
          cancel_reason=${reason},
          offered_driver_id=NULL,
          offer_expires_at=NULL,
          offer_payload=NULL,
          updated_at=NOW()
      WHERE id=${tripId}::uuid
      RETURNING *
    `);

    await tx.execute(rawSql`
      UPDATE users
      SET current_trip_id=NULL
      WHERE current_trip_id=${tripId}::uuid
    `);

    return {
      ok: true as const,
      idempotent: false,
      action: "cancelled" as const,
      trip: updated.rows[0] as any,
      existingTrip,
      previousStatus,
    };
  });

  const { cancelDispatch } = await import("../dispatch");
  cancelDispatch(tripId);
  await appendTripStatus(
    tripId,
    outcome.action === "reassigned" ? "requested" : "trip_cancelled",
    actorType,
    reason,
  ).catch((error: any) => console.error(`[CANCEL_AUDIT] appendTripStatus failed trip=${tripId}: ${error?.message || error}`));
  await logRideLifecycleEvent(
    tripId,
    outcome.action === "reassigned" ? "driver_reassigned" : "trip_cancelled",
    actorId,
    actorType,
    { reason, source: input.source, previousStatus: outcome.previousStatus },
  ).catch((error: any) => console.error(`[CANCEL_AUDIT] lifecycle failed trip=${tripId}: ${error?.message || error}`));

  console.log(
    `[CANCEL_COMPLETED] trip=${tripId} actor=${actorType}:${actorId} previous=${outcome.previousStatus} action=${outcome.action} idempotent=${outcome.idempotent}`,
  );
  return outcome;
}
