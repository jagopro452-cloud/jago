import { log } from "./index";
import { db } from "./db";
import { sql } from "drizzle-orm";
import crypto from "crypto";
const rawDb = db;
const rawSql = sql;

let admin: any = null;
let fcmInitialized = false;
let lastFcmError: string | null = null;

function tokenHash(token: string): string {
  return crypto.createHash("sha256").update(token).digest("hex").slice(0, 12);
}

function isInvalidTokenError(error: any): boolean {
  const text = `${error?.code || ""} ${error?.message || ""}`;
  return /registration-token-not-registered|invalid-registration-token|invalid-argument|Requested entity was not found/i.test(text);
}

function isAuthError(error: any): boolean {
  const text = `${error?.code || ""} ${error?.message || ""}`;
  return /invalid_grant|Invalid JWT Signature|certificate key file has been revoked|invalid-credential|permission/i.test(text);
}

function isRetryableFcmError(error: any): boolean {
  const text = `${error?.code || ""} ${error?.message || ""}`;
  return /unavailable|internal|deadline|timeout|ECONNRESET|ETIMEDOUT/i.test(text);
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function markFcmTokenInvalid(token: string, reason: string): Promise<void> {
  if (!token) return;
  await rawDb.execute(rawSql`
    DELETE FROM user_devices
    WHERE fcm_token = ${token}
  `).catch((error: any) => {
    log(`[FCM_TOKEN_INVALID_MARK_FAILED] tokenHash=${tokenHash(token)} error=${error?.message || error}`, "fcm");
  });
  log(`[FCM_TOKEN_INVALID] tokenHash=${tokenHash(token)} reason=${reason}`, "fcm");
}

// ── Initialize Firebase Admin (env var only, no SMS fallback) ────────────────
async function initFirebaseAsync() {
  if (fcmInitialized) return;
  fcmInitialized = true;

  // Only use the explicit Admin SDK service-account JSON from production env.
  // A DB fallback can silently resurrect revoked credentials, so do not use one.
  const serviceAccountJson = (process.env.FIREBASE_SERVICE_ACCOUNT_KEY || "").trim();

  if (!serviceAccountJson) {
    lastFcmError = "FIREBASE_SERVICE_ACCOUNT_KEY is required";
    log("[FCM] Firebase service account not configured — push notifications disabled", "fcm");
    return;
  }

  try {
    const firebaseAdminModule = await import("firebase-admin");
    const firebaseAdmin: any = (firebaseAdminModule as any)?.default || firebaseAdminModule;
    // Avoid re-initializing if already done
    if (firebaseAdmin.apps.length === 0) {
      const serviceAccount = JSON.parse(serviceAccountJson);
      if (!serviceAccount.project_id || !serviceAccount.client_email || !serviceAccount.private_key) {
        throw new Error("Malformed Firebase service account");
      }
      const expectedProject = (process.env.FIREBASE_PROJECT_ID || "").trim();
      if (process.env.NODE_ENV === "production" && !expectedProject) {
        throw new Error("FIREBASE_PROJECT_ID is required in production");
      }
      if (expectedProject && serviceAccount.project_id !== expectedProject) {
        throw new Error(`Firebase project mismatch: env=${expectedProject} serviceAccount=${serviceAccount.project_id}`);
      }
      if (typeof serviceAccount.private_key === "string") {
        serviceAccount.private_key = serviceAccount.private_key.replace(/\\n/g, "\n");
      }
      firebaseAdmin.initializeApp({
        credential: firebaseAdmin.credential.cert(serviceAccount),
      });
    }
    admin = firebaseAdmin;
    lastFcmError = null;
    log("[FCM] Firebase Admin initialized successfully", "fcm");
  } catch (e: any) {
    admin = null;
    fcmInitialized = false;
    lastFcmError = e?.message || "Firebase Admin initialization failed";
    log(`[FCM] Init failed: ${e.message}`, "fcm");
  }
}

export async function validateFirebaseAdminStartup(): Promise<void> {
  await initFirebaseAsync();
  if (!admin) {
    const message = lastFcmError || "Firebase Admin not initialized";
    if (process.env.NODE_ENV === "production") {
      throw new Error(message);
    }
    log(`[FCM_STARTUP_WARNING] ${message}`, "fcm");
    return;
  }

  try {
    await admin.messaging().send({
      token: "fcm_startup_validation_token",
      data: { type: "startup_validation" },
      android: { priority: "high" },
    }, true);
    log("[FCM_STARTUP_VALIDATED] dryRun=true", "fcm");
  } catch (error: any) {
    if (isAuthError(error)) {
      admin = null;
      fcmInitialized = false;
      lastFcmError = error?.message || "Firebase auth validation failed";
      throw new Error(lastFcmError || "Firebase auth validation failed");
    }
    lastFcmError = null;
    log(`[FCM_STARTUP_VALIDATED] credentials accepted dryRunNonAuthError=${error?.code || error?.message || "unknown"}`, "fcm");
  }
}

// Sync wrapper — lazy init on first use
function initFirebase() {
  if (!fcmInitialized) {
    initFirebaseAsync().catch(() => {});
  }
}

// ── Get Firebase Admin instance (for token verification) ─────────────────────
export async function getFirebaseAdminAsync(): Promise<any> {
  await initFirebaseAsync();
  return admin;
}

export function getFirebaseAdmin(): any {
  initFirebase();
  return admin;
}

export function getLastFcmError(): string | null {
  return lastFcmError;
}

// ── Send single FCM notification ─────────────────────────────────────────────
// dataOnly=true → no `notification` key → Android wakes our background handler
// even when app is killed. REQUIRED for full-screen intent to work.
export async function sendFcmNotification(opts: {
  fcmToken: string;
  title: string;
  body: string;
  data?: Record<string, string>;
  sound?: string;
  channelId?: string;
  dataOnly?: boolean;
}): Promise<boolean> {
  if (!admin) await initFirebaseAsync();
  if (!admin) return false;

  try {
    // Always embed title+body in data so our background handler can read them
    const dataPayload: Record<string, string> = {
      title: opts.title,
      body: opts.body,
      ...(opts.data || {}),
    };

    const message: any = {
      token: opts.fcmToken,
      data: dataPayload,
      android: {
        priority: "high" as const,
        directBootOk: true,
        // For non-alert messages only: let FCM show the system notification
        ...(opts.dataOnly ? {} : {
          notification: {
            sound: opts.sound || "trip_alert",
            channelId: opts.channelId || "trip_alerts",
            priority: "max" as const,
            defaultVibrateTimings: false,
            vibrateTimingsMillis: [0, 500, 200, 500, 200, 500],
          },
        }),
      },
      apns: {
        headers: { "apns-priority": "10" },
        payload: {
          aps: {
            sound: opts.dataOnly ? undefined : (opts.sound || "trip_alert.wav"),
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    // For non-dataOnly messages, include the notification key for system display
    if (!opts.dataOnly) {
      message.notification = { title: opts.title, body: opts.body };
    }

    let attempt = 0;
    while (attempt < 3) {
      try {
        const messageId = await admin.messaging().send(message);
        lastFcmError = null;
        log(
          `[FCM_SEND_SUCCESS] tokenHash=${tokenHash(opts.fcmToken)} messageId=${messageId} title=${opts.title}${opts.dataOnly ? " dataOnly=true" : ""}`,
          "fcm",
        );
        return true;
      } catch (error: any) {
        attempt++;
        lastFcmError = error?.message || "FCM send failed";
        if (isInvalidTokenError(error)) {
          await markFcmTokenInvalid(opts.fcmToken, error?.code || error?.message || "invalid_token");
          return false;
        }
        if (isAuthError(error)) {
          admin = null;
          fcmInitialized = false;
          log(
            `[FCM_SEND_FAILURE] tokenHash=${tokenHash(opts.fcmToken)} authError=true error=${error?.message || error}`,
            "fcm",
          );
          return false;
        }
        log(
          `[FCM_SEND_FAILURE] tokenHash=${tokenHash(opts.fcmToken)} attempt=${attempt} retryable=${isRetryableFcmError(error)} error=${error?.message || error}`,
          "fcm",
        );
        if (attempt >= 3 || !isRetryableFcmError(error)) return false;
        await sleep(250 * attempt + Math.floor(Math.random() * 250));
      }
    }
    return false;
  } catch (e: any) {
    lastFcmError = e?.message || "FCM send failed";
    if (isAuthError(e)) {
      admin = null;
      fcmInitialized = false;
    }
    log(`[FCM_SEND_FAILURE] tokenHash=${tokenHash(opts.fcmToken)} error=${e.message}`, "fcm");
    return false;
  }
}

// ── Notification helpers ─────────────────────────────────────────────────────

/** 🔔 New ride alert to driver */
export async function notifyDriverNewRide(opts: {
  fcmToken: string | null;
  driverName: string;
  customerName: string;
  pickupAddress: string;
  destinationAddress?: string;
  estimatedFare: number;
  estimatedDistance?: number | string;
  tripId: string;
  bookingTraceId?: string | null;
  vehicleCategoryId?: string | null;
  vehicleCategoryName?: string | null;
  timeoutMs?: number;
}) {
  if (!opts.fcmToken) return;
  return sendFcmNotification({
    fcmToken: opts.fcmToken,
    title: "🚗 New Ride Request!",
    body: `${opts.customerName} — ${opts.pickupAddress} — ₹${opts.estimatedFare}`,
    sound: "trip_alert",
    channelId: "trip_alerts_v2",
    dataOnly: true, // background handler shows full-screen intent
    data: {
      type: "new_trip",
      tripId: opts.tripId,
      bookingTraceId: opts.bookingTraceId || opts.tripId,
      customerName: opts.customerName,
      pickupAddress: opts.pickupAddress,
      destinationAddress: opts.destinationAddress || "",
      estimatedFare: String(opts.estimatedFare),
      estimatedDistance: String(opts.estimatedDistance ?? ""),
      vehicleCategoryId: opts.vehicleCategoryId || "",
      vehicleCategoryName: opts.vehicleCategoryName || "",
      vehicleCategory: opts.vehicleCategoryName || "",
      timeoutMs: String(opts.timeoutMs ?? 40000),
    },
  });
}

/** 📦 New parcel order — notify driver (for background wake-up) */
export async function notifyDriverNewParcel(opts: {
  fcmToken: string | null;
  pickupAddress: string;
  totalFare: number;
  orderId: string;
  vehicleCategory?: string;
}) {
  if (!opts.fcmToken) return;
  const label = (opts.vehicleCategory || 'bike_parcel').replace(/_/g, ' ');
  return sendFcmNotification({
    fcmToken: opts.fcmToken,
    title: "📦 New Parcel Delivery!",
    body: `${opts.pickupAddress} — ₹${opts.totalFare} — ${label}`,
    sound: "trip_alert",
    channelId: "trip_alerts_v2",
    dataOnly: true, // background handler shows full-screen intent
    data: {
      type: "new_parcel",
      orderId: opts.orderId,
      pickupAddress: opts.pickupAddress,
      totalFare: String(opts.totalFare),
      vehicleCategory: opts.vehicleCategory || 'bike_parcel',
    },
  });
}

/** ✅ Driver accepted — notify customer */
export async function notifyCustomerDriverAccepted(opts: {
  fcmToken: string | null;
  driverName: string;
  tripId: string;
}) {
  if (!opts.fcmToken) return;
  return sendFcmNotification({
    fcmToken: opts.fcmToken,
    title: "Driver Accepted Your Ride!",
    body: `${opts.driverName} is on the way to pick you up`,
    sound: "default",
    channelId: "trip_updates",
    data: {
      type: "trip_accepted",
      tripId: opts.tripId,
      driverName: opts.driverName,
    },
  });
}

/** 📍 Driver arrived at pickup */
export async function notifyCustomerDriverArrived(opts: {
  fcmToken: string | null;
  driverName: string;
  otp: string;
  tripId: string;
}) {
  if (!opts.fcmToken) return;
  return sendFcmNotification({
    fcmToken: opts.fcmToken,
    title: "🚗 Driver Arrived!",
    body: `${opts.driverName} is waiting. Your OTP: ${opts.otp}`,
    sound: "default",
    channelId: "trip_updates",
    data: {
      type: "driver_arrived",
      tripId: opts.tripId,
      otp: opts.otp,
    },
  });
}

/** ✅ Trip completed — notify customer */
export async function notifyCustomerTripCompleted(opts: {
  fcmToken: string | null;
  fare: number;
  tripId: string;
}) {
  if (!opts.fcmToken) return;
  return sendFcmNotification({
    fcmToken: opts.fcmToken,
    title: "Trip Completed!",
    body: `Fare: ₹${opts.fare}. Thank you for riding with JAGO Pro!`,
    sound: "default",
    channelId: "trip_updates",
    data: {
      type: "trip_completed",
      tripId: opts.tripId,
      fare: String(opts.fare),
    },
  });
}

/** ❌ Trip cancelled */
export async function notifyTripCancelled(opts: {
  fcmToken: string | null;
  cancelledBy: "driver" | "customer";
  tripId: string;
}) {
  if (!opts.fcmToken) return;
  const by = opts.cancelledBy === "driver" ? "Driver" : "Customer";
  return sendFcmNotification({
    fcmToken: opts.fcmToken,
    title: "Trip Cancelled",
    body: `${by} cancelled this trip`,
    sound: "default",
    channelId: "trip_updates",
    data: {
      type: "trip_cancelled",
      tripId: opts.tripId,
      cancelledBy: opts.cancelledBy,
    },
  });
}
