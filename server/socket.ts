import { Server as SocketIOServer, Socket } from "socket.io";
import type { Server as HttpServer } from "http";
import { db as rawDb } from "./db";
import { sql as rawSql } from "drizzle-orm";
import { notifyDriverNewRide, notifyCustomerDriverAccepted, notifyCustomerTripCompleted, notifyTripCancelled } from "./fcm";
import {
  recordWaypoint,
  getTripWaypoints,
  clearTripWaypoints,
  checkRouteDeviation,
  checkAbnormalStop,
  checkSpeedAnomaly,
} from "./ai";
import { parseEnv } from "./config/env";

export let io: SocketIOServer;

// Track connected sockets: userId → socketId
const driverSockets = new Map<string, string>();
const customerSockets = new Map<string, string>();

function camelize(obj: any): any {
  if (!obj || typeof obj !== "object") return obj;
  return Object.fromEntries(
    Object.entries(obj).map(([k, v]) => [
      k.replace(/_([a-z])/g, (_, c) => c.toUpperCase()),
      v,
    ])
  );
}

async function persistSafetyAlert(alert: any, driverId: string) {
  try {
    await rawDb.execute(rawSql`
      INSERT INTO ai_safety_alerts (trip_id, driver_id, alert_type, severity, message, lat, lng)
      VALUES (
        ${alert.tripId}::uuid,
        ${driverId}::uuid,
        ${alert.type},
        ${alert.severity},
        ${alert.message},
        ${alert.lat || 0},
        ${alert.lng || 0}
      )
    `);
  } catch (e: any) {
    console.error("[AI-SAFETY] Failed to persist alert:", e.message);
  }
}

export function setupSocket(httpServer: HttpServer) {
  const env = parseEnv();
  const socketAllowedOrigins = (env.SOCKET_ALLOWED_ORIGINS || "*")
    .split(",")
    .map((v) => v.trim())
    .filter(Boolean);

  io = new SocketIOServer(httpServer, {
    cors: {
      origin: socketAllowedOrigins.length === 1 ? socketAllowedOrigins[0] : socketAllowedOrigins,
      methods: ["GET", "POST"],
    },
    transports: ["websocket", "polling"],
  });

  io.on("connection", (socket: Socket) => {
    const userId = socket.handshake.query.userId as string;
    const userType = socket.handshake.query.userType as string; // 'driver' | 'customer'

    if (!userId) {
      socket.disconnect();
      return;
    }

    // Join personal room
    socket.join(`user:${userId}`);

    if (userType === "driver") {
      driverSockets.set(userId, socket.id);
      socket.join(`drivers`);
      console.log(`[SOCKET] Driver ${userId} connected`);

      // ── Driver: send location update ───────────────────────────────────────
      socket.on("driver:location", async (data: { lat: number; lng: number; heading?: number; speed?: number }) => {
        try {
          const { lat, lng, heading = 0, speed = 0 } = data;
          await rawDb.execute(rawSql`
            UPDATE driver_locations
            SET lat=${lat}, lng=${lng}, heading=${heading}, speed=${speed}, updated_at=NOW()
            WHERE driver_id=${userId}::uuid
          `);
          const tripR = await rawDb.execute(rawSql`
            SELECT current_trip_id FROM users WHERE id=${userId}::uuid
          `);
          const tripId = (tripR.rows[0] as any)?.current_trip_id;
          if (tripId) {
            io.to(`trip:${tripId}`).emit("driver:location_update", { lat, lng, heading, speed, tripId });

            recordWaypoint(tripId, lat, lng, speed);

            const speedAlert = checkSpeedAnomaly(speed, tripId, lat, lng);
            if (speedAlert) {
              persistSafetyAlert(speedAlert, userId);
              io.to(`trip:${tripId}`).emit("safety:alert", speedAlert);
            }

            const waypoints = getTripWaypoints(tripId);
            const stopAlert = checkAbnormalStop(waypoints, tripId);
            if (stopAlert) {
              persistSafetyAlert(stopAlert, userId);
              io.to(`trip:${tripId}`).emit("safety:alert", stopAlert);
            }

            if (waypoints.length % 10 === 0) {
              try {
                const tripData = await rawDb.execute(rawSql`
                  SELECT pickup_lat, pickup_lng, destination_lat, destination_lng, current_status
                  FROM trip_requests WHERE id=${tripId}::uuid
                `);
                if (tripData.rows.length) {
                  const t = tripData.rows[0] as any;
                  if (t.current_status === 'on_the_way' && t.destination_lat && t.destination_lng) {
                    const devAlert = checkRouteDeviation(
                      lat, lng,
                      Number(t.pickup_lat), Number(t.pickup_lng),
                      Number(t.destination_lat), Number(t.destination_lng),
                      tripId
                    );
                    if (devAlert) {
                      persistSafetyAlert(devAlert, userId);
                      io.to(`trip:${tripId}`).emit("safety:alert", devAlert);
                    }
                  }
                }
              } catch {}
            }
          }
        } catch (e: any) {
          console.error("[SOCKET] driver:location error:", e.message);
        }
      });

      // ── Driver: go online/offline ──────────────────────────────────────────
      socket.on("driver:online", async (data: { isOnline: boolean; lat?: number; lng?: number }) => {
        try {
          const { isOnline, lat, lng } = data;
          await rawDb.execute(rawSql`
            UPDATE driver_locations SET is_online=${isOnline}, updated_at=NOW()
            WHERE driver_id=${userId}::uuid
          `);
          if (lat && lng) {
            await rawDb.execute(rawSql`
              UPDATE driver_locations SET lat=${lat}, lng=${lng} WHERE driver_id=${userId}::uuid
            `);
          }
          socket.emit("driver:online_ack", { isOnline });
          console.log(`[SOCKET] Driver ${userId} ${isOnline ? "online" : "offline"}`);

          // If driver just came online, check for searching trips nearby
          if (isOnline && lat && lng) {
            await notifyDriverNearbyTrips(userId, lat, lng);
          }
        } catch (e: any) {
          console.error("[SOCKET] driver:online error:", e.message);
        }
      });

      // ── Driver: accept trip ────────────────────────────────────────────────
      socket.on("driver:accept_trip", async (data: { tripId: string }) => {
        try {
          const { tripId } = data;
          // Verify trip is still in searching/driver_assigned state
          const tripR = await rawDb.execute(rawSql`
            SELECT t.*, u.full_name as customer_name, u.fcm_token as customer_fcm,
              dd.vehicle_category_id, dl.lat as driver_lat, dl.lng as driver_lng
            FROM trip_requests t
            JOIN users u ON u.id = t.customer_id
            LEFT JOIN driver_details dd ON dd.user_id=${userId}::uuid
            LEFT JOIN driver_locations dl ON dl.driver_id=${userId}::uuid
            WHERE t.id=${tripId}::uuid AND t.current_status IN ('searching','driver_assigned')
          `);
          if (!tripR.rows.length) {
            socket.emit("driver:accept_trip_error", { message: "Trip no longer available" });
            return;
          }
          const trip = camelize(tripR.rows[0]) as any;

          // Atomically claim the trip — only if still available (prevents race condition)
          const claimed = await rawDb.execute(rawSql`
            UPDATE trip_requests SET driver_id=${userId}::uuid, current_status='accepted', driver_accepted_at=NOW(), updated_at=NOW()
            WHERE id=${tripId}::uuid
              AND current_status IN ('searching','driver_assigned')
              AND (driver_id IS NULL OR driver_id=${userId}::uuid)
            RETURNING id
          `);
          if (!claimed.rows.length) {
            socket.emit("driver:accept_trip_error", { message: "Trip was already accepted by another pilot" });
            return;
          }
          await rawDb.execute(rawSql`
            UPDATE users SET current_trip_id=${tripId}::uuid WHERE id=${userId}::uuid
          `);

          // Get driver info
          const driverR = await rawDb.execute(rawSql`
            SELECT full_name, phone, rating, profile_photo FROM users WHERE id=${userId}::uuid
          `);
          const driver = camelize(driverR.rows[0]) as any;

          // Notify customer via socket
          io.to(`user:${trip.customerId}`).emit("trip:driver_assigned", {
            tripId,
            driver: {
              id: userId,
              fullName: driver.fullName,
              phone: driver.phone,
              rating: driver.rating,
              photo: driver.profilePhoto,
              lat: trip.driverLat,
              lng: trip.driverLng,
            },
          });

          // Notify all other nearby drivers that the trip has been taken
          try {
            const nearbyDrivers = await rawDb.execute(rawSql`
              SELECT dl.driver_id FROM driver_locations dl
              JOIN users u ON u.id = dl.driver_id
              WHERE u.is_online = true AND u.id != ${userId}::uuid
                AND ((dl.lat - ${trip.pickupLat || 0})*(dl.lat - ${trip.pickupLat || 0}) + (dl.lng - ${trip.pickupLng || 0})*(dl.lng - ${trip.pickupLng || 0})) < 0.1
            `);
            for (const row of nearbyDrivers.rows) {
              const dId = (row as any).driver_id;
              io.to(`user:${dId}`).emit("trip:request_taken", { tripId });
            }
          } catch {}

          // FCM fallback (customer may be in background)
          try {
            const custDevR = await rawDb.execute(rawSql`
              SELECT fcm_token FROM user_devices WHERE user_id=${trip.customerId}::uuid AND fcm_token IS NOT NULL LIMIT 1
            `);
            const custFcm = (custDevR.rows[0] as any)?.fcm_token;
            if (custFcm) {
              notifyCustomerDriverAccepted({
                fcmToken: custFcm,
                driverName: driver.fullName,
                tripId,
              }).catch(() => {});
            }
          } catch {}

          socket.emit("driver:accept_trip_ok", { tripId, trip });
          console.log(`[SOCKET] Driver ${userId} accepted trip ${tripId}`);
        } catch (e: any) {
          console.error("[SOCKET] driver:accept_trip error:", e.message);
          socket.emit("driver:accept_trip_error", { message: e.message });
        }
      });

      // ── Driver: update trip status ─────────────────────────────────────────
      socket.on("driver:trip_status", async (data: { tripId: string; status: string; otp?: string }) => {
        try {
          const { tripId, status, otp } = data;
          const allowed = ["accepted", "arrived", "on_the_way", "completed", "cancelled"];
          if (!allowed.includes(status)) {
            socket.emit("error", { message: "Invalid status" });
            return;
          }

          if (status === "on_the_way") {
            await rawDb.execute(rawSql`
              UPDATE trip_requests SET current_status=${status}, ride_started_at=NOW(), updated_at=NOW()
              WHERE id=${tripId}::uuid
            `);
          } else if (status === "completed") {
            await rawDb.execute(rawSql`
              UPDATE trip_requests SET current_status=${status}, completed_at=NOW(), updated_at=NOW()
              WHERE id=${tripId}::uuid
            `);
          } else {
            await rawDb.execute(rawSql`
              UPDATE trip_requests SET current_status=${status}, updated_at=NOW()
              WHERE id=${tripId}::uuid
            `);
          }

          if (status === "completed" || status === "cancelled") {
            await rawDb.execute(rawSql`UPDATE users SET current_trip_id=NULL WHERE id=${userId}::uuid`);
          }

          // Get customer id + fare for FCM
          const tripR = await rawDb.execute(rawSql`SELECT customer_id, estimated_fare, actual_fare FROM trip_requests WHERE id=${tripId}::uuid`);
          if (tripR.rows.length) {
            const customerId = (tripR.rows[0] as any).customer_id;
            const fare = (tripR.rows[0] as any).actual_fare || (tripR.rows[0] as any).estimated_fare || 0;
            // Socket notify (foreground)
            io.to(`user:${customerId}`).emit("trip:status_update", { tripId, status, otp });
            io.to(`trip:${tripId}`).emit("trip:status_update", { tripId, status, otp });
            // FCM fallback (background) for key status changes
            if (status === "completed" || status === "cancelled") {
              try {
                const custDevR = await rawDb.execute(rawSql`
                  SELECT fcm_token FROM user_devices WHERE user_id=${customerId}::uuid AND fcm_token IS NOT NULL LIMIT 1
                `);
                const custFcm = (custDevR.rows[0] as any)?.fcm_token;
                if (custFcm) {
                  if (status === "completed") {
                    notifyCustomerTripCompleted({ fcmToken: custFcm, fare: Number(fare), tripId }).catch(() => {});
                  } else {
                    notifyTripCancelled({ fcmToken: custFcm, cancelledBy: "driver", tripId }).catch(() => {});
                  }
                }
              } catch {}
            }
          }

          socket.emit("driver:trip_status_ok", { tripId, status });
          console.log(`[SOCKET] Trip ${tripId} status → ${status}`);
        } catch (e: any) {
          console.error("[SOCKET] driver:trip_status error:", e.message);
        }
      });

    } else if (userType === "customer") {
      customerSockets.set(userId, socket.id);
      console.log(`[SOCKET] Customer ${userId} connected`);

      // ── Customer: join trip room for tracking ──────────────────────────────
      socket.on("customer:track_trip", (data: { tripId: string }) => {
        socket.join(`trip:${data.tripId}`);
        console.log(`[SOCKET] Customer ${userId} tracking trip ${data.tripId}`);
      });

      // ── Customer: cancel trip ──────────────────────────────────────────────
      socket.on("customer:cancel_trip", async (data: { tripId: string }) => {
        try {
          const { tripId } = data;
          const tripR = await rawDb.execute(rawSql`
            SELECT driver_id FROM trip_requests
            WHERE id=${tripId}::uuid AND customer_id=${userId}::uuid AND current_status NOT IN ('completed','cancelled')
          `);
          if (!tripR.rows.length) {
            socket.emit("error", { message: "Trip not found or already ended" });
            return;
          }
          const driverId = (tripR.rows[0] as any).driver_id;
          await rawDb.execute(rawSql`
            UPDATE trip_requests SET current_status='cancelled', updated_at=NOW() WHERE id=${tripId}::uuid
          `);
          if (driverId) {
            await rawDb.execute(rawSql`UPDATE users SET current_trip_id=NULL WHERE id=${driverId}::uuid`);
            io.to(`user:${driverId}`).emit("trip:cancelled", { tripId, cancelledBy: "customer" });
          }
          socket.emit("trip:cancelled", { tripId, cancelledBy: "customer" });
        } catch (e: any) {
          console.error("[SOCKET] customer:cancel_trip error:", e.message);
        }
      });
    }

    // ── In-app trip chat relay + DB persistence ──────────────────────────────
    socket.on("trip:send_message", async (data: { tripId: string; message: string; senderName: string; senderType: string }) => {
      try {
        const { tripId, message, senderName, senderType } = data;
        if (!tripId || !message?.trim()) return;

        const now = new Date();

        // Persist to DB first
        await rawDb.execute(rawSql`
          INSERT INTO trip_messages (trip_id, sender_id, sender_type, sender_name, message, created_at)
          VALUES (${tripId}::uuid, ${userId}::uuid, ${senderType || 'customer'}, ${senderName || ''}, ${message.trim()}, ${now.toISOString()})
        `);

        // Then relay to all participants in the trip room
        io.to(`trip:${tripId}`).emit("trip:new_message", {
          from: userId,
          senderType: senderType || 'customer',
          senderName: senderName || '',
          message: message.trim(),
          timestamp: now.toISOString(),
        });
      } catch (e: any) {
        console.error("[SOCKET] trip:send_message error:", e.message);
      }
    });

    // ── Load chat history on reconnect ────────────────────────────────────────
    socket.on("trip:get_messages", async (data: { tripId: string }) => {
      try {
        const { tripId } = data;
        if (!tripId) return;

        const rows = await rawDb.execute(rawSql`
          SELECT id, trip_id, sender_id, sender_type, sender_name, message, created_at
          FROM trip_messages
          WHERE trip_id = ${tripId}::uuid
          ORDER BY created_at ASC
          LIMIT 200
        `);

        socket.emit("trip:message_history", {
          tripId,
          messages: rows.rows.map((r: any) => ({
            id: r.id,
            from: r.sender_id,
            senderType: r.sender_type,
            senderName: r.sender_name,
            message: r.message,
            timestamp: r.created_at instanceof Date ? r.created_at.toISOString() : r.created_at,
          })),
        });
      } catch (e: any) {
        console.error("[SOCKET] trip:get_messages error:", e.message);
      }
    });

    // ── In-app call signaling (WebRTC relay) ──────────────────────────────────
    // Validates that an active trip exists between caller and target before relaying

    socket.on("call:initiate", async (data: { targetUserId: string; tripId: string; callerName: string }) => {
      try {
        const { targetUserId, tripId, callerName } = data;
        // Verify active trip between the two users
        const tripR = await rawDb.execute(rawSql`
          SELECT id FROM trip_requests
          WHERE id=${tripId}::uuid
            AND current_status IN ('accepted','arrived','on_the_way')
            AND (customer_id=${userId}::uuid OR driver_id=${userId}::uuid)
            AND (customer_id=${targetUserId}::uuid OR driver_id=${targetUserId}::uuid)
          LIMIT 1
        `);
        if (!tripR.rows.length) {
          socket.emit("call:error", { message: "No active trip. Calling not allowed." });
          return;
        }
        io.to(`user:${targetUserId}`).emit("call:incoming", {
          callerId: userId, callerName, tripId,
        });
        console.log(`[CALL] ${userId} calling ${targetUserId} for trip ${tripId}`);
      } catch (e: any) {
        socket.emit("call:error", { message: "Call initiation failed" });
      }
    });

    socket.on("call:offer", (data: { targetUserId: string; sdp: any }) => {
      io.to(`user:${data.targetUserId}`).emit("call:offer", { callerId: userId, sdp: data.sdp });
    });

    socket.on("call:answer", (data: { targetUserId: string; sdp: any }) => {
      io.to(`user:${data.targetUserId}`).emit("call:answer", { callerId: userId, sdp: data.sdp });
    });

    socket.on("call:ice", (data: { targetUserId: string; candidate: any }) => {
      io.to(`user:${data.targetUserId}`).emit("call:ice", { from: userId, candidate: data.candidate });
    });

    socket.on("call:end", (data: { targetUserId: string }) => {
      io.to(`user:${data.targetUserId}`).emit("call:ended", { by: userId });
      console.log(`[CALL] Call ended by ${userId}`);
    });

    socket.on("call:reject", (data: { targetUserId: string }) => {
      io.to(`user:${data.targetUserId}`).emit("call:rejected", { by: userId });
    });

    socket.on("disconnect", () => {
      driverSockets.delete(userId);
      customerSockets.delete(userId);
      console.log(`[SOCKET] ${userType} ${userId} disconnected`);
    });
  });

  console.log("[SOCKET] Socket.IO initialized");
  return io;
}

// ── Notify nearby online drivers of a new searching trip ─────────────────────
export async function notifyNearbyDriversNewTrip(
  tripId: string,
  pickupLat: number,
  pickupLng: number,
  vehicleCategoryId?: string,
  excludeDriverIds: string[] = []
) {
  if (!io) return;
  try {
    const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const safeIds = excludeDriverIds.filter((id) => uuidRe.test(id));
    const excludeClause = safeIds.length > 0
      ? rawSql`AND u.id NOT IN (${rawSql.raw(safeIds.map((id) => `'${id}'::uuid`).join(","))})`
      : rawSql``;

    const drivers = await rawDb.execute(rawSql`
      SELECT u.id, dl.lat, dl.lng
      FROM users u
      JOIN driver_locations dl ON dl.driver_id = u.id
      JOIN driver_details dd ON dd.user_id = u.id
      WHERE u.user_type='driver' AND u.is_active=true AND u.is_locked=false
        AND dl.is_online=true AND u.current_trip_id IS NULL AND u.verification_status='approved'
        ${vehicleCategoryId ? rawSql`AND dd.vehicle_category_id = ${vehicleCategoryId}::uuid` : rawSql``}
        ${excludeClause}
        AND ((dl.lat - ${Number(pickupLat)})*(dl.lat - ${Number(pickupLat)}) + (dl.lng - ${Number(pickupLng)})*(dl.lng - ${Number(pickupLng)})) < 0.06
      ORDER BY ((dl.lat - ${Number(pickupLat)})*(dl.lat - ${Number(pickupLat)}) + (dl.lng - ${Number(pickupLng)})*(dl.lng - ${Number(pickupLng)})) ASC
      LIMIT 10
    `);

    const tripR = await rawDb.execute(rawSql`
      SELECT t.*, u.full_name as customer_name
      FROM trip_requests t JOIN users u ON u.id=t.customer_id
      WHERE t.id=${tripId}::uuid
    `);
    if (!tripR.rows.length) return;
    const trip = camelize(tripR.rows[0]) as any;

    // Get driver FCM tokens for background push
    const driverIds = drivers.rows.map((r: any) => r.id);
    let fcmMap: Record<string, string> = {};
    if (driverIds.length > 0) {
      const devRes = await rawDb.execute(rawSql`
        SELECT user_id, fcm_token FROM user_devices
        WHERE user_id = ANY(${driverIds}::uuid[]) AND fcm_token IS NOT NULL
      `);
      for (const r of devRes.rows) {
        fcmMap[(r as any).user_id] = (r as any).fcm_token;
      }
    }

    for (const row of drivers.rows) {
      const driverId = (row as any).id;
      const payload = {
        tripId,
        refId: trip.refId,
        customerName: trip.customerName,
        pickupAddress: trip.pickupAddress,
        destinationAddress: trip.destinationAddress,
        pickupLat: trip.pickupLat,
        pickupLng: trip.pickupLng,
        estimatedFare: trip.estimatedFare,
        estimatedDistance: trip.estimatedDistance,
        paymentMethod: trip.paymentMethod,
        tripType: trip.tripType,
      };
      // Socket (foreground) + FCM (background)
      io.to(`user:${driverId}`).emit("trip:new_request", payload);
      const fcmToken = fcmMap[driverId];
      if (fcmToken) {
        notifyDriverNewRide({
          fcmToken,
          driverName: '',
          customerName: trip.customerName,
          pickupAddress: trip.pickupAddress,
          estimatedFare: trip.estimatedFare,
          tripId,
        }).catch(() => {});
      }
    }
    console.log(`[SOCKET] New trip ${tripId} notified to ${drivers.rows.length} nearby drivers`);
  } catch (e: any) {
    console.error("[SOCKET] notifyNearbyDriversNewTrip error:", e.message);
  }
}

// ── When driver comes online, check for searching trips nearby ────────────────
async function notifyDriverNearbyTrips(driverId: string, lat: number, lng: number) {
  if (!io) return;
  try {
    const driverProfile = await rawDb.execute(rawSql`
      SELECT dd.vehicle_category_id
      FROM driver_details dd
      WHERE dd.user_id=${driverId}::uuid
      LIMIT 1
    `);
    const driverVehicleCategoryId = (driverProfile.rows[0] as any)?.vehicle_category_id || null;

    const trips = await rawDb.execute(rawSql`
      SELECT t.*, u.full_name as customer_name
      FROM trip_requests t JOIN users u ON u.id=t.customer_id
      WHERE t.current_status='searching'
        AND t.driver_id IS NULL
        AND NOT (${driverId}::uuid = ANY(COALESCE(t.rejected_driver_ids, '{}'::uuid[])))
        ${driverVehicleCategoryId ? rawSql`AND t.vehicle_category_id = ${driverVehicleCategoryId}::uuid` : rawSql``}
        AND ((t.pickup_lat - ${lat})*(t.pickup_lat - ${lat}) + (t.pickup_lng - ${lng})*(t.pickup_lng - ${lng})) < 0.06
      LIMIT 3
    `);
    for (const row of trips.rows) {
      const trip = camelize(row) as any;
      io.to(`user:${driverId}`).emit("trip:new_request", {
        tripId: trip.id,
        refId: trip.refId,
        customerName: trip.customerName,
        pickupAddress: trip.pickupAddress,
        destinationAddress: trip.destinationAddress,
        pickupLat: trip.pickupLat,
        pickupLng: trip.pickupLng,
        estimatedFare: trip.estimatedFare,
        estimatedDistance: trip.estimatedDistance,
        paymentMethod: trip.paymentMethod,
      });
    }
  } catch (e: any) {
    console.error("[SOCKET] notifyDriverNearbyTrips error:", e.message);
  }
}
