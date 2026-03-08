import { log } from "./index";

let admin: any = null;
let fcmInitialized = false;

// ── Initialize Firebase Admin ────────────────────────────────────────────────
function initFirebase() {
  if (fcmInitialized) return;
  fcmInitialized = true;

  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;
  if (!serviceAccountJson) {
    log("[FCM] FIREBASE_SERVICE_ACCOUNT_KEY not set — push notifications disabled", "fcm");
    return;
  }

  try {
    const firebaseAdmin = require("firebase-admin");
    const serviceAccount = JSON.parse(serviceAccountJson);
    firebaseAdmin.initializeApp({
      credential: firebaseAdmin.credential.cert(serviceAccount),
    });
    admin = firebaseAdmin;
    log("[FCM] Firebase Admin initialized successfully", "fcm");
  } catch (e: any) {
    log(`[FCM] Init failed: ${e.message}`, "fcm");
  }
}

// ── Get Firebase Admin instance (for token verification) ─────────────────────
export function getFirebaseAdmin(): any {
  initFirebase();
  return admin;
}

// ── Send single FCM notification ─────────────────────────────────────────────
export async function sendFcmNotification(opts: {
  fcmToken: string;
  title: string;
  body: string;
  data?: Record<string, string>;
  sound?: string;
  channelId?: string;
}): Promise<boolean> {
  initFirebase();
  if (!admin) return false;

  try {
    const message = {
      token: opts.fcmToken,
      notification: {
        title: opts.title,
        body: opts.body,
      },
      data: opts.data || {},
      android: {
        priority: "high" as const,
        notification: {
          sound: opts.sound || "trip_alert",
          channelId: opts.channelId || "trip_alerts",
          priority: "max" as const,
          defaultVibrateTimings: false,
          vibrateTimingsMillis: [0, 500, 200, 500, 200, 500],
        },
      },
      apns: {
        headers: {
          "apns-priority": "10",
        },
        payload: {
          aps: {
            sound: opts.sound || "trip_alert.wav",
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    await admin.messaging().send(message);
    log(`[FCM] Sent to ${opts.fcmToken.substring(0, 20)}... — ${opts.title}`, "fcm");
    return true;
  } catch (e: any) {
    log(`[FCM] Send failed: ${e.message}`, "fcm");
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
  estimatedFare: number;
  tripId: string;
}) {
  if (!opts.fcmToken) return;
  return sendFcmNotification({
    fcmToken: opts.fcmToken,
    title: "🚗 New Ride Request!",
    body: `${opts.customerName} — ${opts.pickupAddress} — ₹${opts.estimatedFare}`,
    sound: "trip_alert",
    channelId: "trip_alerts",
    data: {
      type: "new_trip",
      tripId: opts.tripId,
      customerName: opts.customerName,
      pickupAddress: opts.pickupAddress,
      estimatedFare: String(opts.estimatedFare),
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
    body: `Fare: ₹${opts.fare}. Thank you for riding with JAGO!`,
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
