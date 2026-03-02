import { Server as SocketIOServer, Socket } from "socket.io";
import type { Server as HttpServer } from "http";
import { db as rawDb } from "./db";
import { sql as rawSql } from "drizzle-orm";
import { notifyDriverNewRide, notifyCustomerDriverAccepted, notifyCustomerTripCompleted, notifyTripCancelled } from "./fcm";

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

export function setupSocket(httpServer: HttpServer) {
  io = new SocketIOServer(httpServer, {
    cors: {
      origin: "*",
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
          // Get current trip for this driver
          const tripR = await rawDb.execute(rawSql`
            SELECT current_trip_id FROM users WHERE id=${userId}::uuid
          `);
          const tripId = (tripR.rows[0] as any)?.current_trip_id;
          if (tripId) {
            // Broadcast driver location to customer tracking this trip
            io.to(`trip:${tripId}`).emit("driver:location_update", { lat, lng, heading, speed, tripId });
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

          // Assign driver
          await rawDb.execute(rawSql`
            UPDATE trip_requests SET driver_id=${userId}::uuid, current_status='driver_assigned', updated_at=NOW()
            WHERE id=${tripId}::uuid
          `);
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
          const allowed = ["accepted", "arrived", "in_progress", "completed", "cancelled"];
          if (!allowed.includes(status)) {
            socket.emit("error", { message: "Invalid status" });
            return;
          }

          if (status === "in_progress") {
            await rawDb.execute(rawSql`
              UPDATE trip_requests SET current_status=${status}, started_at=NOW(), updated_at=NOW()
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
export async function notifyNearbyDriversNewTrip(tripId: string, pickupLat: number, pickupLng: number, vehicleCategoryId?: string) {
  if (!io) return;
  try {
    const drivers = await rawDb.execute(rawSql`
      SELECT u.id, dl.lat, dl.lng
      FROM users u
      JOIN driver_locations dl ON dl.driver_id = u.id
      JOIN driver_details dd ON dd.user_id = u.id
      WHERE u.user_type='driver' AND u.is_active=true AND u.is_locked=false
        AND dl.is_online=true AND u.current_trip_id IS NULL AND u.verification_status='approved'
        ${vehicleCategoryId ? rawSql`AND dd.vehicle_category_id = ${vehicleCategoryId}::uuid` : rawSql``}
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
    const trips = await rawDb.execute(rawSql`
      SELECT t.*, u.full_name as customer_name
      FROM trip_requests t JOIN users u ON u.id=t.customer_id
      WHERE t.current_status='searching'
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
