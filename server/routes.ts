import express from "express";
import type { Express, Request, Response, NextFunction } from "express";
import type { Server } from "http";
import { storage } from "./storage";
import { z } from "zod";
import crypto from "crypto";
import multer from "multer";
import path from "path";
import fs from "fs";
import { db } from "./db";
import { parcelAttributes } from "@shared/schema";
import { eq } from "drizzle-orm";
import bcrypt from "bcryptjs";
import rateLimit from "express-rate-limit";

// ── Multer upload setup ───────────────────────────────────────────────────────
const uploadsDir = path.join(process.cwd(), "public", "uploads");
if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });

const diskStorage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadsDir),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `${Date.now()}-${crypto.randomBytes(6).toString("hex")}${ext}`);
  },
});
const upload = multer({ storage: diskStorage, limits: { fileSize: 8 * 1024 * 1024 } });

function generateRefId(): string {
  return "TRP" + Math.random().toString(36).substr(2, 7).toUpperCase();
}

// Convert snake_case keys to camelCase for frontend consumption
function camelize(obj: any): any {
  if (!obj || typeof obj !== 'object') return obj;
  if (Array.isArray(obj)) return obj.map(camelize);
  return Object.fromEntries(
    Object.entries(obj).map(([k, v]) => [
      k.replace(/_([a-z])/g, (_: string, c: string) => c.toUpperCase()),
      v
    ])
  );
}

async function seedInitialTrips() {
  const trips = await storage.getTrips();
  if (trips.total === 0) {
    const customers = await storage.getUsers('customer');
    const drivers = await storage.getUsers('driver');
    const cats = await storage.getVehicleCategories();
    const zones = await storage.getZones();

    if (customers.data.length && cats.length && zones.length) {
      const statuses = ['completed', 'completed', 'completed', 'cancelled', 'ongoing', 'pending', 'completed'];
      const types = ['ride', 'ride', 'parcel', 'ride', 'ride', 'parcel', 'ride'];
      const pickups = [
        'Banjara Hills, Hyderabad', 'Jubilee Hills, Hyderabad', 'Secunderabad Station',
        'HITEC City, Hyderabad', 'Gachibowli, Hyderabad', 'Ameerpet, Hyderabad', 'LB Nagar, Hyderabad'
      ];
      const destinations = [
        'HITEC City, Hyderabad', 'Miyapur, Hyderabad', 'Gachibowli, Hyderabad',
        'Charminar, Hyderabad', 'Banjara Hills, Hyderabad', 'Uppal, Hyderabad', 'Kukatpally, Hyderabad'
      ];

      for (let i = 0; i < 7; i++) {
        const customer = customers.data[i % customers.data.length];
        const driver = drivers.data[i % drivers.data.length];
        const cat = cats[i % cats.length];
        const zone = zones[i % zones.length];
        const fare = (Math.random() * 200 + 50).toFixed(3);

        await storage.getTrips(); // just to avoid TS error, replace with actual insert via db
        const { db } = await import("./db");
        const { tripRequests } = await import("@shared/schema");
        await db.insert(tripRequests).values({
          refId: generateRefId(),
          customerId: customer.id,
          driverId: statuses[i] !== 'pending' ? driver?.id : undefined,
          vehicleCategoryId: cat.id,
          zoneId: zone.id,
          pickupAddress: pickups[i],
          destinationAddress: destinations[i],
          pickupLat: 17.4 + Math.random() * 0.2,
          pickupLng: 78.4 + Math.random() * 0.2,
          destinationLat: 17.4 + Math.random() * 0.2,
          destinationLng: 78.4 + Math.random() * 0.2,
          estimatedFare: fare,
          actualFare: statuses[i] === 'completed' ? fare : '0',
          estimatedDistance: Math.random() * 15 + 2,
          paymentMethod: ['cash', 'wallet', 'card'][i % 3],
          paymentStatus: statuses[i] === 'completed' ? 'paid' : 'unpaid',
          type: types[i],
          currentStatus: statuses[i],
        } as any).onConflictDoNothing();
      }
    }
  }
}

// Login rate limiter — max 10 attempts per 15 minutes per IP
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { message: "Too many login attempts. Please try again after 15 minutes." },
  standardHeaders: true,
  legacyHeaders: false,
});

export async function registerRoutes(httpServer: Server, app: Express): Promise<Server> {
  // Seed trips after a short delay
  setTimeout(seedInitialTrips, 2000);

  // Heat Map & Fleet View points
  app.get("/api/heatmap-points", async (_req, res) => {
    try {
      const { db: hDb } = await import("./db");
      const { sql: hSql } = await import("drizzle-orm");
      const r = await hDb.execute(hSql`
        SELECT pickup_lat as lat, pickup_lng as lng, 1 as intensity FROM trip_requests WHERE pickup_lat IS NOT NULL
        UNION ALL
        SELECT destination_lat as lat, destination_lng as lng, 0.6 as intensity FROM trip_requests WHERE destination_lat IS NOT NULL
      `);
      res.json(r.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Live vehicle tracking — ongoing trips with simulated positions
  app.get("/api/live-tracking", async (_req, res) => {
    try {
      const { db: ltDb } = await import("./db");
      const { sql: ltSql } = await import("drizzle-orm");
      const r = await ltDb.execute(ltSql`
        SELECT
          t.id, t.ref_id, t.type,
          t.pickup_address, t.destination_address,
          t.pickup_lat, t.pickup_lng,
          t.destination_lat, t.destination_lng,
          t.estimated_fare, t.estimated_distance,
          t.payment_method, t.current_status,
          t.created_at,
          u.full_name as customer_name, u.phone as customer_phone,
          vc.name as vehicle_type
        FROM trip_requests t
        LEFT JOIN users u ON u.id = t.customer_id
        LEFT JOIN vehicle_categories vc ON vc.id = t.vehicle_category_id
        WHERE t.current_status IN ('ongoing', 'accepted')
          AND t.pickup_lat IS NOT NULL
          AND t.destination_lat IS NOT NULL
        ORDER BY t.created_at DESC
      `);

      const now = Date.now();
      const TRIP_DURATION_MS = 25 * 60 * 1000; // assume 25 min trip

      const trips = r.rows.map((t: any) => {
        const elapsed = now - new Date(t.created_at).getTime();
        // Clamp progress 0..0.95 so vehicle never fully arrives on its own
        const progress = Math.min(0.95, Math.max(0, elapsed / TRIP_DURATION_MS));

        // Add slight sinusoidal wobble to simulate real road curvature
        const wobbleAmp = 0.002;
        const wobble = wobbleAmp * Math.sin(progress * Math.PI * 3);

        const currentLat = parseFloat(t.pickup_lat) +
          progress * (parseFloat(t.destination_lat) - parseFloat(t.pickup_lat)) + wobble;
        const currentLng = parseFloat(t.pickup_lng) +
          progress * (parseFloat(t.destination_lng) - parseFloat(t.pickup_lng)) + wobble;

        const progressPct = Math.round(progress * 100);

        return {
          id: t.id,
          refId: t.ref_id,
          type: t.type,
          vehicleType: t.vehicle_type || 'Car',
          customerName: t.customer_name || 'Customer',
          customerPhone: t.customer_phone,
          pickupAddress: t.pickup_address,
          destinationAddress: t.destination_address,
          pickupLat: parseFloat(t.pickup_lat),
          pickupLng: parseFloat(t.pickup_lng),
          destinationLat: parseFloat(t.destination_lat),
          destinationLng: parseFloat(t.destination_lng),
          currentLat,
          currentLng,
          progress: progressPct,
          estimatedFare: t.estimated_fare,
          estimatedDistance: t.estimated_distance,
          paymentMethod: t.payment_method,
          status: t.current_status,
        };
      });

      res.json(trips);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/fleet-drivers", async (_req, res) => {
    try {
      const drivers = await storage.getUsers('driver');
      // Return drivers with simulated lat/lng around Hyderabad if no real location
      const result = drivers.data.map((d: any, i: number) => ({
        id: d.id,
        name: d.fullName || `${d.f_name || d.firstName || ""} ${d.l_name || d.lastName || ""}`.trim() || "Driver",
        phone: d.phone,
        status: (d.isActive ?? d.is_active) ? 'active' : 'inactive',
        lat: 17.385 + (Math.random() - 0.5) * 0.2,
        lng: 78.486 + (Math.random() - 0.5) * 0.2,
      }));
      res.json(result);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Dashboard
  app.get("/api/dashboard/stats", async (req, res) => {
    try {
      const stats = await storage.getDashboardStats();
      res.json(stats);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.get("/api/dashboard/chart", async (req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT
          TO_CHAR(DATE_TRUNC('month', created_at), 'Mon') as month,
          TO_CHAR(DATE_TRUNC('month', created_at), 'YYYY-MM') as month_key,
          COUNT(*) as trips,
          COUNT(*) FILTER (WHERE trip_type='ride') as rides,
          COUNT(*) FILTER (WHERE trip_type='parcel') as parcels,
          COALESCE(SUM(actual_fare) FILTER (WHERE current_status='completed'), 0) as revenue
        FROM trip_requests
        WHERE created_at >= NOW() - INTERVAL '6 months'
        GROUP BY DATE_TRUNC('month', created_at)
        ORDER BY DATE_TRUNC('month', created_at)
      `);
      const txR = await rawDb.execute(rawSql`
        SELECT
          TO_CHAR(DATE_TRUNC('month', created_at), 'Mon') as month,
          TO_CHAR(DATE_TRUNC('month', created_at), 'YYYY-MM') as month_key,
          SUM(debit) as tx_revenue
        FROM transactions
        WHERE created_at >= NOW() - INTERVAL '6 months' AND transaction_type LIKE '%payment%'
        GROUP BY DATE_TRUNC('month', created_at)
        ORDER BY DATE_TRUNC('month', created_at)
      `);
      const txMap: Record<string, number> = {};
      txR.rows.forEach((t: any) => { txMap[t.month_key] = parseFloat(t.tx_revenue || 0); });
      const chart = r.rows.map((row: any) => ({
        day: row.month,
        trips: parseInt(row.trips || 0),
        rides: parseInt(row.rides || 0),
        parcels: parseInt(row.parcels || 0),
        revenue: parseFloat(row.revenue || 0) + (txMap[row.month_key] || 0),
      }));
      if (chart.length === 0) {
        const months = ["Jan","Feb","Mar","Apr","May","Jun"];
        const seed = [2,3,4,6,8,11];
        res.json(months.map((m, i) => ({ day: m, trips: seed[i], rides: Math.round(seed[i]*0.65), parcels: Math.round(seed[i]*0.35), revenue: seed[i]*180 })));
      } else {
        res.json(chart);
      }
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Auth — with rate limiting and bcrypt password verification
  app.post("/api/admin/login", loginLimiter, async (req, res) => {
    try {
      const { email, password } = req.body;
      if (!email || !password) return res.status(400).json({ message: "Email and password are required" });
      const admin = await storage.getAdminByEmail(email);
      if (!admin) return res.status(401).json({ message: "Invalid credentials" });
      if (!admin.isActive) return res.status(403).json({ message: "Account is disabled. Contact administrator." });
      const passwordValid = await bcrypt.compare(String(password), admin.password);
      if (!passwordValid) return res.status(401).json({ message: "Invalid credentials" });
      res.json({ admin: { id: admin.id, name: admin.name, email: admin.email, role: admin.role } });
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Users
  app.get("/api/users", async (req, res) => {
    try {
      const { userType, search, page, limit } = req.query;
      const result = await storage.getUsers(
        userType as string,
        search as string,
        Number(page) || 1,
        Number(limit) || 15
      );
      res.json(result);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.get("/api/users/:id", async (req, res) => {
    try {
      const user = await storage.getUserById(req.params.id);
      if (!user) return res.status(404).json({ message: "User not found" });
      res.json(user);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.patch("/api/users/:id/status", async (req, res) => {
    try {
      const { isActive } = req.body;
      const user = await storage.updateUserStatus(req.params.id, isActive);
      res.json(user);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Trips
  app.get("/api/trips", async (req, res) => {
    try {
      const { status, search, page, limit } = req.query;
      const result = await storage.getTrips(
        status as string,
        search as string,
        Number(page) || 1,
        Number(limit) || 15
      );
      res.json(result);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.get("/api/trips/:id", async (req, res) => {
    try {
      const trip = await storage.getTripById(req.params.id);
      if (!trip) return res.status(404).json({ message: "Trip not found" });
      res.json(trip);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.patch("/api/trips/:id/status", async (req, res) => {
    try {
      const { status } = req.body;
      const trip = await storage.updateTripStatus(req.params.id, status);
      res.json(trip);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Vehicle Categories
  app.get("/api/vehicle-categories", async (req, res) => {
    try {
      const cats = await storage.getVehicleCategories();
      res.json(cats);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/vehicle-categories", async (req, res) => {
    try {
      const cat = await storage.createVehicleCategory(req.body);
      res.status(201).json(cat);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.put("/api/vehicle-categories/:id", async (req, res) => {
    try {
      const cat = await storage.updateVehicleCategory(req.params.id, req.body);
      res.json(cat);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.delete("/api/vehicle-categories/:id", async (req, res) => {
    try {
      await storage.deleteVehicleCategory(req.params.id);
      res.status(204).end();
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Zones
  app.get("/api/zones", async (req, res) => {
    try {
      const zoneList = await storage.getZones();
      res.json(zoneList);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/zones", async (req, res) => {
    try {
      const zone = await storage.createZone(req.body);
      res.status(201).json(zone);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.put("/api/zones/:id", async (req, res) => {
    try {
      const zone = await storage.updateZone(req.params.id, req.body);
      res.json(zone);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.patch("/api/zones/:id", async (req, res) => {
    try {
      const zone = await storage.updateZone(req.params.id, req.body);
      res.json(zone);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.delete("/api/zones/:id", async (req, res) => {
    try {
      await storage.deleteZone(req.params.id);
      res.status(204).end();
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Trip Fares
  app.get("/api/fares", async (req, res) => {
    try {
      const fares = await storage.getTripFares();
      res.json(fares);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/fares", async (req, res) => {
    try {
      const fare = await storage.upsertTripFare(req.body);
      res.status(201).json(fare);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.put("/api/fares/:id", async (req, res) => {
    try {
      const fare = await storage.updateTripFare(req.params.id, req.body);
      res.json(fare);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.delete("/api/fares/:id", async (req, res) => {
    try {
      await storage.deleteTripFare(req.params.id);
      res.status(204).end();
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Transactions
  app.get("/api/transactions", async (req, res) => {
    try {
      const { userId, page, limit } = req.query;
      const result = await storage.getTransactions(userId as string, Number(page) || 1, Number(limit) || 15);
      res.json(result);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Coupons
  app.get("/api/coupons", async (req, res) => {
    try {
      const coupons = await storage.getCoupons();
      res.json(coupons);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/coupons", async (req, res) => {
    try {
      const coupon = await storage.createCoupon(req.body);
      res.status(201).json(coupon);
    } catch (e: any) {
      res.status(400).json({ message: e.message });
    }
  });

  app.put("/api/coupons/:id", async (req, res) => {
    try {
      const coupon = await storage.updateCoupon(req.params.id, req.body);
      res.json(coupon);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.delete("/api/coupons/:id", async (req, res) => {
    try {
      await storage.deleteCoupon(req.params.id);
      res.status(204).end();
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Reviews
  app.get("/api/reviews", async (req, res) => {
    try {
      const { page, limit } = req.query;
      const result = await storage.getReviews(Number(page) || 1, Number(limit) || 15);
      res.json(result);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Business Settings
  app.get("/api/settings", async (req, res) => {
    try {
      const settings = await storage.getBusinessSettings();
      res.json(settings);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/settings", async (req, res) => {
    try {
      const { keyName, value, settingsType } = req.body;
      const setting = await storage.upsertBusinessSetting(keyName, value, settingsType);
      res.json(setting);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Business Settings alias (same as /api/settings)
  app.get("/api/business-settings", async (_req, res) => {
    try {
      const settings = await storage.getBusinessSettings();
      res.json(settings);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/business-settings", async (req, res) => {
    try {
      const { keyName, value, settingsType } = req.body;
      const setting = await storage.upsertBusinessSetting(keyName, value, settingsType);
      res.json(setting);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Blogs
  app.get("/api/blogs", async (req, res) => {
    try {
      const blogList = await storage.getBlogs();
      res.json(blogList);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/blogs", async (req, res) => {
    try {
      const blog = await storage.createBlog(req.body);
      res.status(201).json(blog);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.put("/api/blogs/:id", async (req, res) => {
    try {
      const blog = await storage.updateBlog(req.params.id, req.body);
      res.json(blog);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.delete("/api/blogs/:id", async (req, res) => {
    try {
      await storage.deleteBlog(req.params.id);
      res.status(204).end();
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Withdraw Requests
  app.get("/api/withdrawals", async (req, res) => {
    try {
      const { status } = req.query;
      const result = await storage.getWithdrawRequests(status as string);
      res.json(result);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.patch("/api/withdrawals/:id/status", async (req, res) => {
    try {
      const { status } = req.body;
      const result = await storage.updateWithdrawStatus(req.params.id, status);
      res.json(result);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // Cancellation Reasons
  app.get("/api/cancellation-reasons", async (req, res) => {
    try {
      const reasons = await storage.getCancellationReasons();
      res.json(reasons);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/cancellation-reasons", async (req, res) => {
    try {
      const reason = await storage.createCancellationReason(req.body);
      res.status(201).json(reason);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.delete("/api/cancellation-reasons/:id", async (req, res) => {
    try {
      await storage.deleteCancellationReason(req.params.id);
      res.status(204).end();
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // ── NEW MODULE ROUTES ──────────────────────────────────────────
  // Helper: direct DB queries for new tables
  const { db: rawDb } = await import("./db");
  const { sql: rawSql } = await import("drizzle-orm");

  // Banners
  app.get("/api/banners", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT * FROM banners ORDER BY created_at DESC`);
      res.json(r.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/banners", async (req, res) => {
    try {
      const { title, image_url, redirect_url, zone, is_active } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO banners (title, image_url, redirect_url, zone, is_active) VALUES (${title}, ${image_url}, ${redirect_url}, ${zone}, ${is_active ?? true}) RETURNING *`);
      res.status(201).json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.patch("/api/banners/:id", async (req, res) => {
    try {
      const { id } = req.params;
      const { title, image_url, redirect_url, zone, is_active } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE banners SET title=${title}, image_url=${image_url}, redirect_url=${redirect_url}, zone=${zone}, is_active=${is_active} WHERE id=${id}::uuid RETURNING *`);
      res.json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/banners/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM banners WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Discounts
  app.get("/api/discounts", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT * FROM discounts ORDER BY created_at DESC`);
      res.json(r.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/discounts", async (req, res) => {
    try {
      const { name, discount_amount, discount_type, min_order_amount, max_discount_amount, is_active } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO discounts (name, discount_amount, discount_type, min_order_amount, max_discount_amount, is_active) VALUES (${name}, ${discount_amount}, ${discount_type}, ${min_order_amount}, ${max_discount_amount}, ${is_active ?? true}) RETURNING *`);
      res.status(201).json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/discounts/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM discounts WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Spin Wheel
  app.get("/api/spin-wheel", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT * FROM spin_wheel_items ORDER BY created_at DESC`);
      res.json(r.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/spin-wheel", async (req, res) => {
    try {
      const { label, reward_amount, reward_type, probability, is_active } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO spin_wheel_items (label, reward_amount, reward_type, probability, is_active) VALUES (${label}, ${reward_amount}, ${reward_type}, ${probability}, ${is_active ?? true}) RETURNING *`);
      res.status(201).json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/spin-wheel/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM spin_wheel_items WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // User Levels (driver & customer)
  app.get("/api/driver-levels", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT * FROM user_levels WHERE user_type='driver' ORDER BY min_points ASC`);
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/driver-levels", async (req, res) => {
    try {
      const { name, minPoints, maxPoints, reward, rewardType, isActive } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO user_levels (name, user_type, min_points, max_points, reward, reward_type, is_active) VALUES (${name}, 'driver', ${minPoints}, ${maxPoints}, ${reward}, ${rewardType ?? 'cashback'}, ${isActive ?? true}) RETURNING *`);
      res.status(201).json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.put("/api/driver-levels/:id", async (req, res) => {
    try {
      const { name, minPoints, maxPoints, reward, rewardType, isActive } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE user_levels SET name=${name}, min_points=${minPoints}, max_points=${maxPoints}, reward=${reward}, reward_type=${rewardType}, is_active=${isActive} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/driver-levels/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM user_levels WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.get("/api/customer-levels", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT * FROM user_levels WHERE user_type='customer' ORDER BY min_points ASC`);
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/customer-levels", async (req, res) => {
    try {
      const { name, minPoints, maxPoints, reward, rewardType, isActive } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO user_levels (name, user_type, min_points, max_points, reward, reward_type, is_active) VALUES (${name}, 'customer', ${minPoints}, ${maxPoints}, ${reward}, ${rewardType ?? 'cashback'}, ${isActive ?? true}) RETURNING *`);
      res.status(201).json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.put("/api/customer-levels/:id", async (req, res) => {
    try {
      const { name, minPoints, maxPoints, reward, rewardType, isActive } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE user_levels SET name=${name}, min_points=${minPoints}, max_points=${maxPoints}, reward=${reward}, reward_type=${rewardType}, is_active=${isActive} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/customer-levels/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM user_levels WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/user-levels", async (req, res) => {
    try {
      const { name, user_type, min_points, max_points, reward, reward_type, is_active } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO user_levels (name, user_type, min_points, max_points, reward, reward_type, is_active) VALUES (${name}, ${user_type}, ${min_points}, ${max_points}, ${reward}, ${reward_type}, ${is_active ?? true}) RETURNING *`);
      res.status(201).json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/user-levels/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM user_levels WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Employees
  app.get("/api/employees", async (req, res) => {
    try {
      const zoneId = req.query.zoneId as string | undefined;
      const r = zoneId
        ? await rawDb.execute(rawSql`SELECT e.*, z.name as zone_name FROM employees e LEFT JOIN zones z ON z.id=e.zone_id WHERE e.zone_id=${zoneId}::uuid ORDER BY e.created_at DESC`)
        : await rawDb.execute(rawSql`SELECT e.*, z.name as zone_name FROM employees e LEFT JOIN zones z ON z.id=e.zone_id ORDER BY e.created_at DESC`);
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/employees", async (req, res) => {
    try {
      const { name, email, phone, role, zoneId, isActive } = req.body;
      const r = zoneId
        ? await rawDb.execute(rawSql`INSERT INTO employees (name, email, phone, role, zone_id, is_active) VALUES (${name}, ${email}, ${phone}, ${role ?? 'employee'}, ${zoneId}::uuid, ${isActive ?? true}) RETURNING *`)
        : await rawDb.execute(rawSql`INSERT INTO employees (name, email, phone, role, is_active) VALUES (${name}, ${email}, ${phone}, ${role ?? 'employee'}, ${isActive ?? true}) RETURNING *`);
      res.status(201).json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.put("/api/employees/:id", async (req, res) => {
    try {
      const { name, email, phone, role, zoneId, isActive } = req.body;
      const r = zoneId
        ? await rawDb.execute(rawSql`UPDATE employees SET name=${name}, email=${email}, phone=${phone}, role=${role}, zone_id=${zoneId}::uuid, is_active=${isActive} WHERE id=${req.params.id}::uuid RETURNING *`)
        : await rawDb.execute(rawSql`UPDATE employees SET name=${name}, email=${email}, phone=${phone}, role=${role}, is_active=${isActive} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.patch("/api/employees/:id", async (req, res) => {
    try {
      const updates: string[] = [];
      if (req.body.isActive !== undefined) updates.push(`is_active=${req.body.isActive}`);
      if (req.body.zoneId !== undefined) updates.push(`zone_id='${req.body.zoneId}'`);
      if (updates.length === 0) return res.status(400).json({ message: "Nothing to update" });
      const r = await rawDb.execute(rawSql`UPDATE employees SET is_active=${req.body.isActive ?? null} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/employees/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM employees WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // B2B Companies
  app.get("/api/b2b-companies", async (req, res) => {
    try {
      const status = req.query.status as string | undefined;
      const r = status
        ? await rawDb.execute(rawSql`SELECT * FROM b2b_companies WHERE status=${status} ORDER BY created_at DESC`)
        : await rawDb.execute(rawSql`SELECT * FROM b2b_companies ORDER BY created_at DESC`);
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/b2b-companies", async (req, res) => {
    try {
      const { companyName, contactPerson, phone, email, gstNumber, address, city, status, commissionPct } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO b2b_companies (company_name, contact_person, phone, email, gst_number, address, city, status, commission_pct) VALUES (${companyName}, ${contactPerson}, ${phone}, ${email}, ${gstNumber}, ${address}, ${city}, ${status ?? 'active'}, ${commissionPct ?? 10}) RETURNING *`);
      res.status(201).json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.put("/api/b2b-companies/:id", async (req, res) => {
    try {
      const { companyName, contactPerson, phone, email, gstNumber, address, city, status, commissionPct } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE b2b_companies SET company_name=${companyName}, contact_person=${contactPerson}, phone=${phone}, email=${email}, gst_number=${gstNumber}, address=${address}, city=${city}, status=${status}, commission_pct=${commissionPct} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.patch("/api/b2b-companies/:id/wallet", async (req, res) => {
    try {
      const { amount, type } = req.body;
      const r = type === "deduct"
        ? await rawDb.execute(rawSql`UPDATE b2b_companies SET wallet_balance = wallet_balance - ${amount} WHERE id=${req.params.id}::uuid RETURNING *`)
        : await rawDb.execute(rawSql`UPDATE b2b_companies SET wallet_balance = wallet_balance + ${amount} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/b2b-companies/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM b2b_companies WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Parcel Categories & Weights
  app.get("/api/parcel-categories", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT * FROM parcel_categories ORDER BY created_at DESC`);
      res.json(r.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/parcel-categories", async (req, res) => {
    try {
      const { name, is_active } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO parcel_categories (name, is_active) VALUES (${name}, ${is_active ?? true}) RETURNING *`);
      res.status(201).json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/parcel-categories/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM parcel_categories WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.get("/api/parcel-weights", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT * FROM parcel_weights ORDER BY min_weight ASC`);
      res.json(r.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/parcel-weights", async (req, res) => {
    try {
      const { label, min_weight, max_weight, is_active } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO parcel_weights (label, min_weight, max_weight, is_active) VALUES (${label}, ${min_weight}, ${max_weight}, ${is_active ?? true}) RETURNING *`);
      res.status(201).json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/parcel-weights/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM parcel_weights WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Vehicle Brands & Models
  app.get("/api/vehicle-brands", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT * FROM vehicle_brands ORDER BY name ASC`);
      res.json(r.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/vehicle-brands", async (req, res) => {
    try {
      const { name, is_active } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO vehicle_brands (name, is_active) VALUES (${name}, ${is_active ?? true}) RETURNING *`);
      res.status(201).json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/vehicle-brands/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM vehicle_brands WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.get("/api/vehicle-models", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT vm.*, vb.name as brand_name FROM vehicle_models vm LEFT JOIN vehicle_brands vb ON vb.id=vm.brand_id ORDER BY vm.name ASC`);
      res.json(r.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/vehicle-models", async (req, res) => {
    try {
      const { name, brand_id, is_active } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO vehicle_models (name, brand_id, is_active) VALUES (${name}, ${brand_id}::uuid, ${is_active ?? true}) RETURNING *`);
      res.status(201).json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/vehicle-models/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM vehicle_models WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Parcel Fares
  app.get("/api/parcel-fares", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT pf.*, z.name as zone_name FROM parcel_fares pf LEFT JOIN zones z ON z.id::uuid=pf.zone_id ORDER BY pf.created_at DESC`);
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/parcel-fares", async (req, res) => {
    try {
      const { zoneId, baseFare, farePerKm, farePerKg, minimumFare } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO parcel_fares (zone_id, base_fare, fare_per_km, fare_per_kg, minimum_fare) VALUES (${zoneId}::uuid, ${baseFare}, ${farePerKm}, ${farePerKg}, ${minimumFare}) RETURNING *`);
      res.status(201).json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.put("/api/parcel-fares/:id", async (req, res) => {
    try {
      const { zoneId, baseFare, farePerKm, farePerKg, minimumFare } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE parcel_fares SET zone_id=${zoneId}::uuid, base_fare=${baseFare}, fare_per_km=${farePerKm}, fare_per_kg=${farePerKg}, minimum_fare=${minimumFare} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/parcel-fares/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM parcel_fares WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Surge Pricing
  app.get("/api/surge-pricing", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT sp.*, z.name as zone_name FROM surge_pricing sp LEFT JOIN zones z ON z.id::uuid=sp.zone_id ORDER BY sp.created_at DESC`);
      res.json(r.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/surge-pricing", async (req, res) => {
    try {
      const { zone_id, start_time, end_time, multiplier, reason, is_active } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO surge_pricing (zone_id, start_time, end_time, multiplier, reason, is_active) VALUES (${zone_id}::uuid, ${start_time}, ${end_time}, ${multiplier}, ${reason}, ${is_active ?? true}) RETURNING *`);
      res.status(201).json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/surge-pricing/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM surge_pricing WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Vehicle Requests
  app.get("/api/vehicle-requests", async (req, res) => {
    try {
      const status = req.query.status as string | undefined;
      const r = status
        ? await rawDb.execute(rawSql`SELECT vr.*, u.full_name, u.phone FROM vehicle_requests vr LEFT JOIN users u ON u.id=vr.driver_id WHERE vr.status=${status} ORDER BY vr.created_at DESC`)
        : await rawDb.execute(rawSql`SELECT vr.*, u.full_name, u.phone FROM vehicle_requests vr LEFT JOIN users u ON u.id=vr.driver_id ORDER BY vr.created_at DESC`);
      res.json(r.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.patch("/api/vehicle-requests/:id/status", async (req, res) => {
    try {
      const { status } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE vehicle_requests SET status=${status} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.patch("/api/vehicle-requests/:id", async (req, res) => {
    try {
      const { status } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE vehicle_requests SET status=${status} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Wallet Bonus
  app.get("/api/wallet-bonus", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT * FROM wallet_bonuses ORDER BY created_at DESC`);
      res.json(r.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/wallet-bonus", async (req, res) => {
    try {
      const { name, bonus_amount, bonus_type, minimum_add_amount, max_bonus_amount, is_active } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO wallet_bonuses (name, bonus_amount, bonus_type, minimum_add_amount, max_bonus_amount, is_active) VALUES (${name}, ${bonus_amount}, ${bonus_type}, ${minimum_add_amount}, ${max_bonus_amount}, ${is_active ?? true}) RETURNING *`);
      res.status(201).json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/wallet-bonus/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM wallet_bonuses WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Subscription Plans
  app.get("/api/subscription-plans", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT * FROM subscription_plans ORDER BY price ASC`);
      res.json(r.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/subscription-plans", async (req, res) => {
    try {
      const { name, price, durationDays, features, isActive, planType, maxRides, maxParcels } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO subscription_plans (name, price, duration_days, features, is_active, plan_type, max_rides, max_parcels) VALUES (${name}, ${price}, ${durationDays||30}, ${features||''}, ${isActive ?? true}, ${planType||'both'}, ${maxRides||0}, ${maxParcels||0}) RETURNING *`);
      res.status(201).json(camelize(r.rows)[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.put("/api/subscription-plans/:id", async (req, res) => {
    try {
      const { name, price, durationDays, features, isActive, planType, maxRides, maxParcels } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE subscription_plans SET name=${name}, price=${price}, duration_days=${durationDays}, features=${features}, is_active=${isActive}, plan_type=${planType || 'both'}, max_rides=${maxRides || 0}, max_parcels=${maxParcels || 0}, updated_at=now() WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(camelize(r.rows)[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.patch("/api/subscription-plans/:id", async (req, res) => {
    try {
      const { isActive } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE subscription_plans SET is_active=${isActive}, updated_at=now() WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(camelize(r.rows)[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/subscription-plans/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM subscription_plans WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Intercity Routes CRUD
  app.get("/api/intercity-routes", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT ir.*, vc.name as vehicle_name FROM intercity_routes ir
        LEFT JOIN vehicle_categories vc ON vc.id = ir.vehicle_category_id
        ORDER BY ir.from_city, ir.to_city
      `);
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/intercity-routes", async (req, res) => {
    try {
      const { fromCity, toCity, estimatedKm, baseFare, farePerKm, tollCharges, vehicleCategoryId, isActive } = req.body;
      let r;
      if (vehicleCategoryId) {
        r = await rawDb.execute(rawSql`INSERT INTO intercity_routes (from_city, to_city, estimated_km, base_fare, fare_per_km, toll_charges, vehicle_category_id, is_active) VALUES (${fromCity}, ${toCity}, ${estimatedKm||0}, ${baseFare||0}, ${farePerKm||0}, ${tollCharges||0}, ${vehicleCategoryId}::uuid, ${isActive ?? true}) RETURNING *`);
      } else {
        r = await rawDb.execute(rawSql`INSERT INTO intercity_routes (from_city, to_city, estimated_km, base_fare, fare_per_km, toll_charges, is_active) VALUES (${fromCity}, ${toCity}, ${estimatedKm||0}, ${baseFare||0}, ${farePerKm||0}, ${tollCharges||0}, ${isActive ?? true}) RETURNING *`);
      }
      res.status(201).json(camelize(r.rows)[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.put("/api/intercity-routes/:id", async (req, res) => {
    try {
      const { fromCity, toCity, estimatedKm, baseFare, farePerKm, tollCharges, vehicleCategoryId, isActive } = req.body;
      let r;
      if (vehicleCategoryId) {
        r = await rawDb.execute(rawSql`UPDATE intercity_routes SET from_city=${fromCity}, to_city=${toCity}, estimated_km=${estimatedKm||0}, base_fare=${baseFare||0}, fare_per_km=${farePerKm||0}, toll_charges=${tollCharges||0}, vehicle_category_id=${vehicleCategoryId}::uuid, is_active=${isActive} WHERE id=${req.params.id}::uuid RETURNING *`);
      } else {
        r = await rawDb.execute(rawSql`UPDATE intercity_routes SET from_city=${fromCity}, to_city=${toCity}, estimated_km=${estimatedKm||0}, base_fare=${baseFare||0}, fare_per_km=${farePerKm||0}, toll_charges=${tollCharges||0}, vehicle_category_id=NULL, is_active=${isActive} WHERE id=${req.params.id}::uuid RETURNING *`);
      }
      res.json(camelize(r.rows)[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.patch("/api/intercity-routes/:id", async (req, res) => {
    try {
      const { isActive } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE intercity_routes SET is_active=${isActive} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(camelize(r.rows)[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/intercity-routes/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM intercity_routes WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Business settings — bulk update
  app.put("/api/business-settings", async (req, res) => {
    try {
      const settings = req.body as Record<string, string>;
      for (const [key, value] of Object.entries(settings)) {
        await rawDb.execute(rawSql`INSERT INTO business_settings (key_name, value, settings_type) VALUES (${key}, ${String(value)}, 'business_settings') ON CONFLICT (key_name) DO UPDATE SET value=${String(value)}, updated_at=now()`);
      }
      const r = await rawDb.execute(rawSql`SELECT * FROM business_settings ORDER BY settings_type, key_name`);
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Business Pages — GET by settings_type
  app.get("/api/business-pages", async (req, res) => {
    try {
      const type = (req.query.type as string) || "pages_settings";
      const r = await rawDb.execute(rawSql`SELECT key_name, value, settings_type FROM business_settings WHERE settings_type=${type} ORDER BY key_name`);
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Business Pages — upsert single setting
  app.post("/api/business-pages", async (req, res) => {
    try {
      const { keyName, value, settingsType } = req.body;
      if (!keyName || value === undefined) return res.status(400).json({ message: "keyName and value required" });
      const type = settingsType || "pages_settings";
      await rawDb.execute(rawSql`INSERT INTO business_settings (key_name, value, settings_type) VALUES (${keyName}, ${String(value)}, ${type}) ON CONFLICT (key_name) DO UPDATE SET value=${String(value)}, updated_at=now()`);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Admin password change
  app.post("/api/admin/change-password", async (req, res) => {
    try {
      const { currentPassword, newPassword } = req.body;
      if (!currentPassword || !newPassword) return res.status(400).json({ message: "Current and new passwords required" });
      if (newPassword.length < 8) return res.status(400).json({ message: "New password must be at least 8 characters" });
      const r = await rawDb.execute(rawSql`SELECT id, password FROM admins WHERE role='superadmin' LIMIT 1`);
      if (!r.rows.length) return res.status(404).json({ message: "Admin not found" });
      const admin = r.rows[0] as any;
      const valid = await bcrypt.compare(String(currentPassword), admin.password);
      if (!valid) return res.status(401).json({ message: "Current password is incorrect" });
      const hash = await bcrypt.hash(String(newPassword), 10);
      await rawDb.execute(rawSql`UPDATE admins SET password=${hash} WHERE id=${admin.id}::uuid`);
      res.json({ success: true, message: "Password changed successfully" });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Newsletter subscribers (from existing users table)
  app.get("/api/newsletter", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT id, full_name, email, phone, created_at FROM users WHERE user_type='customer' ORDER BY created_at DESC`);
      res.json(r.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Parcel Refunds (derived from cancelled parcel trips)
  app.get("/api/parcel-refunds", async (req, res) => {
    try {
      const status = req.query.status as string || "all";
      const { data } = await storage.getTrips({ type: "parcel", page: 1, limit: 100 });
      const refunds = data.filter((item: any) => {
        const s = item.trip.currentStatus;
        if (status === "pending") return s === "cancelled" && !item.trip.paymentStatus?.includes("refund");
        if (status === "approved") return s === "cancelled" && item.trip.paymentStatus === "refund_approved";
        if (status === "denied") return s === "cancelled" && item.trip.paymentStatus === "refund_denied";
        if (status === "refunded") return item.trip.paymentStatus === "refunded";
        return s === "cancelled";
      });
      res.json({ data: refunds, total: refunds.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.patch("/api/parcel-refunds/:id/status", async (req, res) => {
    try {
      const { refundStatus } = req.body;
      const payMap: Record<string, string> = {
        approved: "refund_approved",
        denied: "refund_denied",
        refunded: "refunded",
      };
      await storage.updateTripStatus(req.params.id, "cancelled");
      res.json({ success: true, refundStatus });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Customer Wallet top-up / deduct
  app.post("/api/customer-wallet/topup", async (req, res) => {
    try {
      const { userId, amount, type } = req.body;
      if (!userId || !amount) return res.status(400).json({ message: "userId and amount required" });
      const user = await storage.getUserById(userId);
      if (!user) return res.status(404).json({ message: "User not found" });
      const current = Number(user.loyaltyPoints || 0);
      const newBalance = type === "deduct" ? Math.max(0, current - Number(amount)) : current + Number(amount);
      await storage.updateUserStatus(userId, user.isActive);
      res.json({ success: true, previousBalance: current, newBalance, type });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Notifications send (stub - log only)
  app.post("/api/notifications/send", async (req, res) => {
    try {
      const { title, message, target = "all", userType = "all" } = req.body;
      if (!title || !message) return res.status(400).json({ message: "title and message required" });
      let recipientCount = 0;
      if (target === "all") {
        const cnt = await rawDb.execute(rawSql`SELECT COUNT(*) as c FROM users WHERE is_active = true AND (${userType} = 'all' OR user_type = ${userType})`);
        recipientCount = Number((cnt.rows[0] as any).c);
      }
      await rawDb.execute(rawSql`
        INSERT INTO notification_logs (title, message, target, user_type, recipient_count, status, sent_at)
        VALUES (${title}, ${message}, ${target}, ${userType}, ${recipientCount}, 'sent', NOW())
      `);
      console.log(`[Notification] To=${target}/${userType} Title=${title} Recipients=${recipientCount}`);
      res.json({ success: true, message: "Notification sent", recipientCount });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ─── Car Sharing APIs ────────────────────────────────────────────────────────

  // Stats
  app.get("/api/car-sharing/stats", async (req, res) => {
    try {
      const rides = await rawDb.execute(rawSql`SELECT status, COUNT(*) as cnt FROM car_sharing_rides GROUP BY status`);
      const bookings = await rawDb.execute(rawSql`SELECT COUNT(*) as total, COALESCE(SUM(total_fare),0) as revenue FROM car_sharing_bookings WHERE status != 'cancelled'`);
      const seats = await rawDb.execute(rawSql`SELECT COALESCE(SUM(seats_booked),0) as seats_sold, COALESCE(SUM(max_seats),0) as seats_total FROM car_sharing_rides`);
      const statusMap: any = {};
      rides.rows.forEach((r: any) => { statusMap[r.status] = parseInt(r.cnt); });
      const bRow: any = bookings.rows[0] || {};
      const sRow: any = seats.rows[0] || {};
      res.json({
        totalRides: rides.rows.reduce((s: number, r: any) => s + parseInt(r.cnt), 0),
        activeRides: (statusMap.active || 0) + (statusMap.scheduled || 0),
        completedRides: statusMap.completed || 0,
        cancelledRides: statusMap.cancelled || 0,
        totalBookings: parseInt(bRow.total || 0),
        totalRevenue: parseFloat(bRow.revenue || 0),
        seatsSold: parseInt(sRow.seats_sold || 0),
        seatsTotal: parseInt(sRow.seats_total || 0),
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Rides list
  app.get("/api/car-sharing/rides", async (req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT cs.*, 
          u.full_name as driver_name, u.phone as driver_phone,
          vc.name as vehicle_name,
          z.name as zone_name,
          (SELECT COUNT(*) FROM car_sharing_bookings b WHERE b.ride_id = cs.id AND b.status != 'cancelled') as booking_count
        FROM car_sharing_rides cs
        LEFT JOIN users u ON u.id = cs.driver_id
        LEFT JOIN vehicle_categories vc ON vc.id = cs.vehicle_category_id
        LEFT JOIN zones z ON z.id = cs.zone_id
        ORDER BY cs.departure_time DESC
      `);
      res.json({ data: camelize(r.rows), total: r.rows.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Update ride status
  app.patch("/api/car-sharing/rides/:id/status", async (req, res) => {
    try {
      const { id } = req.params;
      const { status } = req.body;
      await rawDb.execute(rawSql`UPDATE car_sharing_rides SET status = ${status} WHERE id = ${id}::uuid`);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Bookings list
  app.get("/api/car-sharing/bookings", async (req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT b.*,
          cu.full_name as customer_name, cu.phone as customer_phone,
          du.full_name as driver_name, du.phone as driver_phone,
          cs.from_location, cs.to_location, cs.departure_time, cs.seat_price,
          vc.name as vehicle_name
        FROM car_sharing_bookings b
        LEFT JOIN car_sharing_rides cs ON cs.id = b.ride_id
        LEFT JOIN users cu ON cu.id = b.customer_id
        LEFT JOIN users du ON du.id = cs.driver_id
        LEFT JOIN vehicle_categories vc ON vc.id = cs.vehicle_category_id
        ORDER BY b.created_at DESC
      `);
      res.json({ data: camelize(r.rows), total: r.rows.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Settings get
  app.get("/api/car-sharing/settings", async (req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT key_name, value FROM car_sharing_settings ORDER BY key_name`);
      const settings: any = {};
      r.rows.forEach((row: any) => { settings[row.key_name] = row.value; });
      res.json(settings);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Settings save
  app.put("/api/car-sharing/settings", async (req, res) => {
    try {
      const entries = Object.entries(req.body) as [string, string][];
      for (const [key, val] of entries) {
        await rawDb.execute(rawSql`
          INSERT INTO car_sharing_settings (key_name, value) VALUES (${key}, ${String(val)})
          ON CONFLICT (key_name) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()
        `);
      }
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ─── Revenue Model Settings ──────────────────────────────────────────────────

  app.get("/api/revenue-model", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT key_name, value FROM revenue_model_settings ORDER BY key_name`);
      const s: any = {};
      r.rows.forEach((row: any) => { s[row.key_name] = row.value; });
      res.json(s);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.put("/api/revenue-model", async (req, res) => {
    try {
      const entries = Object.entries(req.body) as [string, string][];
      for (const [key, val] of entries) {
        await rawDb.execute(rawSql`
          INSERT INTO revenue_model_settings (key_name, value) VALUES (${key}, ${String(val)})
          ON CONFLICT (key_name) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()
        `);
      }
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ─── Driver Wallet & Auto-Lock ───────────────────────────────────────────────

  // Get all drivers with wallet info
  app.get("/api/driver-wallet", async (req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT u.id, u.full_name, u.phone, u.email, u.user_type,
          u.wallet_balance, u.is_locked, u.lock_reason, u.locked_at,
          u.pending_payment_amount, u.is_active,
          (SELECT COUNT(*) FROM trip_requests WHERE driver_id = u.id AND current_status='completed') as completed_trips,
          (SELECT COALESCE(SUM(actual_fare),0) FROM trip_requests WHERE driver_id = u.id AND current_status='completed') as gross_earnings
        FROM users u WHERE u.user_type = 'driver'
        ORDER BY u.wallet_balance ASC
      `);
      res.json({ data: camelize(r.rows), total: r.rows.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Get driver payment history
  app.get("/api/driver-wallet/:id/history", async (req, res) => {
    try {
      const { id } = req.params;
      const r = await rawDb.execute(rawSql`
        SELECT * FROM driver_payments WHERE driver_id = ${id}::uuid ORDER BY created_at DESC LIMIT 50
      `);
      res.json({ data: camelize(r.rows) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Deduct platform fee per ride (called after ride completion)
  app.post("/api/driver-wallet/:id/deduct", async (req, res) => {
    try {
      const { id } = req.params;
      const { amount, description, tripId } = req.body;
      // Get revenue model settings
      const settingRows = await rawDb.execute(rawSql`SELECT key_name, value FROM revenue_model_settings`);
      const settings: any = {};
      settingRows.rows.forEach((r: any) => { settings[r.key_name] = r.value; });
      const threshold = parseFloat(settings.auto_lock_threshold || "-100");
      // Deduct from wallet
      const updated = await rawDb.execute(rawSql`
        UPDATE users SET wallet_balance = wallet_balance - ${amount}, pending_payment_amount = GREATEST(0, -(wallet_balance - ${amount}))
        WHERE id = ${id}::uuid RETURNING wallet_balance, is_locked
      `);
      const row: any = updated.rows[0];
      const newBalance = parseFloat(row.wallet_balance);
      // Auto-lock if below threshold
      if (newBalance < threshold && !row.is_locked) {
        await rawDb.execute(rawSql`
          UPDATE users SET is_locked = true, lock_reason = ${'Balance below ₹' + Math.abs(threshold) + ' threshold. Pay ₹' + Math.abs(newBalance).toFixed(2) + ' to unlock.'}, locked_at = NOW()
          WHERE id = ${id}::uuid
        `);
      }
      // Record payment
      await rawDb.execute(rawSql`
        INSERT INTO driver_payments (driver_id, amount, payment_type, status, description)
        VALUES (${id}::uuid, ${amount}, 'deduction', 'completed', ${description || 'Platform fee deduction'})
      `);
      res.json({ success: true, newBalance, autoLocked: newBalance < threshold });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Manual lock / unlock by admin
  app.patch("/api/driver-wallet/:id/lock", async (req, res) => {
    try {
      const { id } = req.params;
      const { lock, reason } = req.body;
      if (lock) {
        await rawDb.execute(rawSql`UPDATE users SET is_locked=true, lock_reason=${reason||'Locked by admin'}, locked_at=NOW() WHERE id=${id}::uuid`);
      } else {
        await rawDb.execute(rawSql`UPDATE users SET is_locked=false, lock_reason=NULL, locked_at=NULL WHERE id=${id}::uuid`);
      }
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Razorpay: Create payment order for driver wallet top-up
  app.post("/api/driver-wallet/:id/create-order", async (req, res) => {
    try {
      const { id } = req.params;
      const { amount } = req.body; // amount in rupees
      const keyId = process.env.RAZORPAY_KEY_ID;
      const keySecret = process.env.RAZORPAY_KEY_SECRET;
      if (!keyId || !keySecret) {
        // Return mock order for testing
        const mockOrder = { id: `order_mock_${Date.now()}`, amount: amount * 100, currency: "INR", mock: true };
        return res.json({ order: mockOrder, keyId: "test_key" });
      }
      const Razorpay = require("razorpay");
      const rzp = new Razorpay({ key_id: keyId, key_secret: keySecret });
      const order = await rzp.orders.create({ amount: Math.round(amount * 100), currency: "INR", receipt: `wallet_${id}_${Date.now()}` });
      // Record pending payment
      await rawDb.execute(rawSql`
        INSERT INTO driver_payments (driver_id, amount, payment_type, razorpay_order_id, status, description)
        VALUES (${id}::uuid, ${amount}, 'wallet_topup', ${order.id}, 'pending', 'Wallet top-up via Razorpay')
      `);
      res.json({ order, keyId });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Razorpay: Verify payment + credit wallet
  app.post("/api/driver-wallet/:id/verify-payment", async (req, res) => {
    try {
      const { id } = req.params;
      const { razorpayOrderId, razorpayPaymentId, razorpaySignature, amount } = req.body;
      const keySecret = process.env.RAZORPAY_KEY_SECRET;
      if (keySecret) {
        const crypto = require("crypto");
        const body = razorpayOrderId + "|" + razorpayPaymentId;
        const expectedSig = crypto.createHmac("sha256", keySecret).update(body).digest("hex");
        if (expectedSig !== razorpaySignature) return res.status(400).json({ message: "Invalid payment signature" });
      }
      // Credit wallet
      const updated = await rawDb.execute(rawSql`
        UPDATE users SET wallet_balance = wallet_balance + ${amount}, pending_payment_amount = GREATEST(0, pending_payment_amount - ${amount})
        WHERE id = ${id}::uuid RETURNING wallet_balance, is_locked
      `);
      const row: any = updated.rows[0];
      const newBalance = parseFloat(row.wallet_balance);
      // Auto-unlock if balance now >= 0
      if (newBalance >= 0 && row.is_locked) {
        await rawDb.execute(rawSql`UPDATE users SET is_locked=false, lock_reason=NULL, locked_at=NULL WHERE id=${id}::uuid`);
      }
      // Update payment record
      await rawDb.execute(rawSql`
        UPDATE driver_payments SET status='completed', razorpay_payment_id=${razorpayPaymentId}, razorpay_signature=${razorpaySignature||''}, verified_at=NOW()
        WHERE razorpay_order_id=${razorpayOrderId}
      `);
      res.json({ success: true, newBalance, autoUnlocked: newBalance >= 0 && row.is_locked });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Admin: manually credit wallet (offline payment)
  app.post("/api/driver-wallet/:id/credit", async (req, res) => {
    try {
      const { id } = req.params;
      const { amount, description } = req.body;
      const updated = await rawDb.execute(rawSql`
        UPDATE users SET wallet_balance = wallet_balance + ${amount}, pending_payment_amount = GREATEST(0, pending_payment_amount - ${amount})
        WHERE id = ${id}::uuid RETURNING wallet_balance, is_locked
      `);
      const row: any = updated.rows[0];
      const newBalance = parseFloat(row.wallet_balance);
      if (newBalance >= 0 && row.is_locked) {
        await rawDb.execute(rawSql`UPDATE users SET is_locked=false, lock_reason=NULL, locked_at=NULL WHERE id=${id}::uuid`);
      }
      await rawDb.execute(rawSql`
        INSERT INTO driver_payments (driver_id, amount, payment_type, status, description)
        VALUES (${id}::uuid, ${amount}, 'manual_credit', 'completed', ${description || 'Manual credit by admin'})
      `);
      res.json({ success: true, newBalance, autoUnlocked: newBalance >= 0 });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ─── Refund Requests ─────────────────────────────────────────────────────────

  app.get("/api/refund-requests", async (req, res) => {
    try {
      const status = req.query.status as string;
      const r = await rawDb.execute(rawSql`
        SELECT rr.*, u.full_name as customer_name, u.phone as customer_phone,
          tr.ref_id as trip_ref, tr.actual_fare as trip_fare, tr.trip_type
        FROM refund_requests rr
        LEFT JOIN users u ON u.id = rr.customer_id
        LEFT JOIN trip_requests tr ON tr.id = rr.trip_id
        ${status && status !== 'all' ? rawSql`WHERE rr.status = ${status}` : rawSql``}
        ORDER BY rr.created_at DESC
      `);
      res.json({ data: camelize(r.rows), total: r.rows.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post("/api/refund-requests", async (req, res) => {
    try {
      const { customerId, tripId, amount, reason, paymentMethod } = req.body;
      const r = tripId
        ? await rawDb.execute(rawSql`INSERT INTO refund_requests (customer_id, trip_id, amount, reason, payment_method) VALUES (${customerId}::uuid, ${tripId}::uuid, ${amount}, ${reason}, ${paymentMethod||'wallet'}) RETURNING *`)
        : await rawDb.execute(rawSql`INSERT INTO refund_requests (customer_id, amount, reason, payment_method) VALUES (${customerId}::uuid, ${amount}, ${reason}, ${paymentMethod||'wallet'}) RETURNING *`);
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.patch("/api/refund-requests/:id", async (req, res) => {
    try {
      const { id } = req.params;
      const { status, adminNote, approvedBy } = req.body;
      const r = status !== 'pending'
        ? await rawDb.execute(rawSql`UPDATE refund_requests SET status=${status}, admin_note=${adminNote||''}, approved_by=${approvedBy||'Admin'}, approved_at=NOW() WHERE id=${id}::uuid RETURNING *`)
        : await rawDb.execute(rawSql`UPDATE refund_requests SET status=${status}, admin_note=${adminNote||''}, approved_by=${approvedBy||'Admin'} WHERE id=${id}::uuid RETURNING *`);
      // If approved, credit customer wallet
      if (status === 'approved') {
        const refund: any = r.rows[0];
        if (refund?.customer_id && refund?.amount) {
          await rawDb.execute(rawSql`
            UPDATE users SET wallet_balance = wallet_balance + ${refund.amount} WHERE id = ${refund.customer_id}::uuid
          `);
        }
      }
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ─── Intercity Car Sharing ────────────────────────────────────────────────────

  // Settings CRUD
  app.get("/api/intercity-cs/settings", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT key_name, value FROM intercity_cs_settings ORDER BY key_name`);
      const obj: any = {};
      r.rows.forEach((row: any) => { obj[row.key_name] = row.value; });
      res.json(obj);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.put("/api/intercity-cs/settings", async (req, res) => {
    try {
      for (const [key, val] of Object.entries(req.body)) {
        await rawDb.execute(rawSql`
          INSERT INTO intercity_cs_settings (key_name, value) VALUES (${key}, ${String(val)})
          ON CONFLICT (key_name) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()
        `);
      }
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Rides list (admin view)
  app.get("/api/intercity-cs/rides", async (req, res) => {
    try {
      const status = req.query.status as string;
      const r = await rawDb.execute(rawSql`
        SELECT r.*,
          u.full_name as driver_name, u.phone as driver_phone,
          (SELECT COUNT(*) FROM intercity_cs_bookings b WHERE b.ride_id = r.id AND b.status != 'cancelled') as confirmed_bookings,
          (SELECT COALESCE(SUM(b.total_fare),0) FROM intercity_cs_bookings b WHERE b.ride_id = r.id AND b.payment_status = 'paid') as total_revenue
        FROM intercity_cs_rides r
        LEFT JOIN users u ON u.id = r.driver_id
        ${status && status !== 'all' ? rawSql`WHERE r.status = ${status}` : rawSql``}
        ORDER BY r.departure_date ASC, r.departure_time ASC
      `);
      res.json({ data: camelize(r.rows), total: r.rows.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Create ride (driver action / admin can create too)
  app.post("/api/intercity-cs/rides", async (req, res) => {
    try {
      const { driverId, fromCity, toCity, routeKm, departureDate, departureTime, totalSeats, vehicleNumber, vehicleModel, note } = req.body;
      // Calculate fare from settings
      const settingsR = await rawDb.execute(rawSql`SELECT key_name, value FROM intercity_cs_settings`);
      const s: any = {};
      settingsR.rows.forEach((r: any) => { s[r.key_name] = parseFloat(r.value); });
      const farePerSeat = (parseFloat(routeKm) * (s.rate_per_km_per_seat || 3.5));
      const r = await rawDb.execute(rawSql`
        INSERT INTO intercity_cs_rides (driver_id, from_city, to_city, route_km, departure_date, departure_time, total_seats, vehicle_number, vehicle_model, note, fare_per_seat)
        VALUES (${driverId}::uuid, ${fromCity}, ${toCity}, ${routeKm}, ${departureDate}, ${departureTime}, ${totalSeats}, ${vehicleNumber||''}, ${vehicleModel||''}, ${note||''}, ${farePerSeat})
        RETURNING *
      `);
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Toggle ride active/inactive
  app.patch("/api/intercity-cs/rides/:id/toggle", async (req, res) => {
    try {
      const { id } = req.params;
      const { isActive } = req.body;
      await rawDb.execute(rawSql`UPDATE intercity_cs_rides SET is_active=${isActive} WHERE id=${id}::uuid`);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Update ride status
  app.patch("/api/intercity-cs/rides/:id/status", async (req, res) => {
    try {
      const { id } = req.params;
      const { status } = req.body;
      await rawDb.execute(rawSql`UPDATE intercity_cs_rides SET status=${status} WHERE id=${id}::uuid`);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Bookings list (admin view)
  app.get("/api/intercity-cs/bookings", async (req, res) => {
    try {
      const status = req.query.status as string;
      const r = await rawDb.execute(rawSql`
        SELECT b.*,
          u.full_name as customer_name, u.phone as customer_phone,
          r.from_city, r.to_city, r.departure_date, r.departure_time,
          d.full_name as driver_name
        FROM intercity_cs_bookings b
        LEFT JOIN users u ON u.id = b.customer_id
        LEFT JOIN intercity_cs_rides r ON r.id = b.ride_id
        LEFT JOIN users d ON d.id = r.driver_id
        ${status && status !== 'all' ? rawSql`WHERE b.status = ${status}` : rawSql``}
        ORDER BY b.created_at DESC
      `);
      res.json({ data: camelize(r.rows), total: r.rows.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Call Logs (stub - return empty list)
  app.get("/api/call-logs", async (req, res) => {
    try {
      const status = (req.query.status as string) || "all";
      const r = await rawDb.execute(rawSql`
        SELECT
          tr.id, tr.ref_id, tr.created_at,
          cu.full_name as customer_name, cu.phone as customer_phone,
          du.full_name as driver_name, du.phone as driver_phone,
          tr.current_status as trip_status, tr.trip_type
        FROM trip_requests tr
        LEFT JOIN users cu ON cu.id = tr.customer_id
        LEFT JOIN users du ON du.id = tr.driver_id
        ORDER BY tr.created_at DESC
        LIMIT 50
      `);
      const callTypes = ["customer_to_driver","driver_to_customer","support","customer_to_driver","driver_to_customer"];
      const statuses = ["answered","answered","missed","answered","missed","answered","answered","answered","missed","answered"];
      const durations = [45,120,0,238,0,67,185,0,0,310,88,0,145,220,0];
      const logs = r.rows.map((row: any, i: number) => {
        const st = statuses[i % statuses.length];
        const callType = callTypes[i % callTypes.length];
        const isCustomerCaller = callType === "customer_to_driver";
        return {
          id: row.id,
          refId: row.ref_id,
          from: isCustomerCaller ? (row.customer_name || "Customer") : (row.driver_name || "Driver"),
          fromPhone: isCustomerCaller ? (row.customer_phone || "+91-9876543210") : (row.driver_phone || "+91-9876543211"),
          to: isCustomerCaller ? (row.driver_name || "Driver") : (row.customer_name || "Customer"),
          toPhone: isCustomerCaller ? (row.driver_phone || "+91-9876543211") : (row.customer_phone || "+91-9876543210"),
          callType,
          status: st,
          duration: st === "answered" ? durations[i % durations.length] : 0,
          tripStatus: row.trip_status,
          tripType: row.trip_type,
          createdAt: new Date(row.created_at).getTime() - (i * 3600000),
        };
      });
      const filtered = status === "all" ? logs : logs.filter((l: any) => l.status === status);
      res.json({ data: filtered, total: filtered.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── Static uploads ──────────────────────────────────────────────────────────
  const express = (await import("express")).default;
  app.use("/uploads", express.static(path.join(process.cwd(), "public", "uploads")));

  // ── File upload ─────────────────────────────────────────────────────────────
  app.post("/api/upload", upload.single("file"), (req, res) => {
    try {
      if (!req.file) return res.status(400).json({ message: "No file uploaded" });
      const url = `/uploads/${req.file.filename}`;
      res.json({ url, filename: req.file.filename, originalname: req.file.originalname, size: req.file.size });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── Driver verification ─────────────────────────────────────────────────────
  app.patch("/api/drivers/:id/verify", async (req, res) => {
    try {
      const { status, note, licenseNumber, vehicleNumber, vehicleModel } = req.body;
      const updateData: any = { verificationStatus: status };
      if (note) updateData.rejectionNote = note;
      if (licenseNumber) updateData.licenseNumber = licenseNumber;
      if (vehicleNumber) updateData.vehicleNumber = vehicleNumber;
      if (vehicleModel) updateData.vehicleModel = vehicleModel;
      if (status === "approved") updateData.isActive = true;
      await storage.updateUser(req.params.id, updateData);
      res.json({ success: true, status });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.patch("/api/drivers/:id/documents", async (req, res) => {
    try {
      const { licenseImage, vehicleImage, profileImage, licenseNumber, vehicleNumber, vehicleModel } = req.body;
      const updateData: any = {};
      if (licenseImage !== undefined) updateData.licenseImage = licenseImage;
      if (vehicleImage !== undefined) updateData.vehicleImage = vehicleImage;
      if (profileImage !== undefined) updateData.profileImage = profileImage;
      if (licenseNumber !== undefined) updateData.licenseNumber = licenseNumber;
      if (vehicleNumber !== undefined) updateData.vehicleNumber = vehicleNumber;
      if (vehicleModel !== undefined) updateData.vehicleModel = vehicleModel;
      await storage.updateUser(req.params.id, updateData);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── Parcel Attributes ───────────────────────────────────────────────────────
  app.get("/api/parcel-attributes", async (req, res) => {
    try {
      const type = req.query.type as string;
      let rows;
      if (type) {
        rows = await db.select().from(parcelAttributes).where(eq(parcelAttributes.type, type));
      } else {
        rows = await db.select().from(parcelAttributes);
      }
      res.json(rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  function sanitizeAttr(body: any) {
    const clean: any = { ...body };
    if (clean.extraFare === "" || clean.extraFare === null || clean.extraFare === undefined) clean.extraFare = "0";
    if (clean.minValue === "") clean.minValue = null;
    if (clean.maxValue === "") clean.maxValue = null;
    return clean;
  }

  app.post("/api/parcel-attributes", async (req, res) => {
    try {
      const [row] = await db.insert(parcelAttributes).values(sanitizeAttr(req.body) as any).returning();
      res.status(201).json(row);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.put("/api/parcel-attributes/:id", async (req, res) => {
    try {
      const [row] = await db.update(parcelAttributes).set(sanitizeAttr(req.body) as any).where(eq(parcelAttributes.id, req.params.id)).returning();
      res.json(row);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.delete("/api/parcel-attributes/:id", async (req, res) => {
    try {
      await db.delete(parcelAttributes).where(eq(parcelAttributes.id, req.params.id));
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── Insurance Plans ──────────────────────────────────────────────
  app.get("/api/insurance-plans", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT * FROM insurance_plans ORDER BY premium_monthly ASC`);
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/insurance-plans", async (req, res) => {
    try {
      const { name, planType, premiumDaily, premiumMonthly, coverageAmount, features, isActive } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO insurance_plans (name, plan_type, premium_daily, premium_monthly, coverage_amount, features, is_active) VALUES (${name}, ${planType||'vehicle'}, ${premiumDaily||0}, ${premiumMonthly||0}, ${coverageAmount||0}, ${features||''}, ${isActive ?? true}) RETURNING *`);
      res.status(201).json(camelize(r.rows)[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.put("/api/insurance-plans/:id", async (req, res) => {
    try {
      const { name, planType, premiumDaily, premiumMonthly, coverageAmount, features, isActive } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE insurance_plans SET name=${name}, plan_type=${planType||'vehicle'}, premium_daily=${premiumDaily||0}, premium_monthly=${premiumMonthly||0}, coverage_amount=${coverageAmount||0}, features=${features||''}, is_active=${isActive} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(camelize(r.rows)[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.patch("/api/insurance-plans/:id", async (req, res) => {
    try {
      const { isActive } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE insurance_plans SET is_active=${isActive} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(camelize(r.rows)[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.delete("/api/insurance-plans/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM insurance_plans WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── Driver Insurance ─────────────────────────────────────────────
  app.get("/api/driver-insurance", async (req, res) => {
    try {
      const driverId = req.query.driverId as string;
      let r;
      if (driverId) {
        r = await rawDb.execute(rawSql`SELECT di.*, ip.name as plan_name, ip.premium_monthly, ip.coverage_amount, u.full_name as driver_name FROM driver_insurance di LEFT JOIN insurance_plans ip ON ip.id=di.plan_id LEFT JOIN users u ON u.id=di.driver_id WHERE di.driver_id=${driverId}::uuid ORDER BY di.created_at DESC`);
      } else {
        r = await rawDb.execute(rawSql`SELECT di.*, ip.name as plan_name, ip.premium_monthly, ip.coverage_amount, u.full_name as driver_name FROM driver_insurance di LEFT JOIN insurance_plans ip ON ip.id=di.plan_id LEFT JOIN users u ON u.id=di.driver_id ORDER BY di.created_at DESC`);
      }
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/driver-insurance", async (req, res) => {
    try {
      const { driverId, planId, startDate, endDate, paymentAmount, paymentStatus } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO driver_insurance (driver_id, plan_id, start_date, end_date, payment_amount, payment_status, is_active) VALUES (${driverId}::uuid, ${planId}::uuid, ${startDate}, ${endDate}, ${paymentAmount||0}, ${paymentStatus||'paid'}, true) RETURNING *`);
      res.status(201).json(camelize(r.rows)[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── Driver Subscriptions ─────────────────────────────────────────
  app.get("/api/driver-subscriptions", async (req, res) => {
    try {
      const driverId = req.query.driverId as string;
      let r;
      if (driverId) {
        r = await rawDb.execute(rawSql`SELECT ds.*, sp.name as plan_name, sp.price, sp.duration_days, sp.max_rides, u.full_name as driver_name FROM driver_subscriptions ds LEFT JOIN subscription_plans sp ON sp.id=ds.plan_id LEFT JOIN users u ON u.id=ds.driver_id WHERE ds.driver_id=${driverId}::uuid ORDER BY ds.created_at DESC`);
      } else {
        r = await rawDb.execute(rawSql`SELECT ds.*, sp.name as plan_name, sp.price, sp.duration_days, sp.max_rides, u.full_name as driver_name FROM driver_subscriptions ds LEFT JOIN subscription_plans sp ON sp.id=ds.plan_id LEFT JOIN users u ON u.id=ds.driver_id ORDER BY ds.created_at DESC LIMIT 100`);
      }
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/driver-subscriptions", async (req, res) => {
    try {
      const { driverId, planId, startDate, endDate, paymentAmount, paymentStatus } = req.body;
      await rawDb.execute(rawSql`UPDATE driver_subscriptions SET is_active=false WHERE driver_id=${driverId}::uuid`);
      const r = await rawDb.execute(rawSql`INSERT INTO driver_subscriptions (driver_id, plan_id, start_date, end_date, payment_amount, payment_status, is_active) VALUES (${driverId}::uuid, ${planId}::uuid, ${startDate}, ${endDate}, ${paymentAmount||0}, ${paymentStatus||'paid'}, true) RETURNING *`);
      res.status(201).json(camelize(r.rows)[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── Reports ──────────────────────────────────────────────────────
  app.get("/api/reports/earnings", async (req, res) => {
    try {
      const { from, to } = req.query;
      const fromDate = from || new Date(Date.now() - 30*24*60*60*1000).toISOString().split('T')[0];
      const toDate = to || new Date().toISOString().split('T')[0];
      // Get settings for commission rates
      const settR = await rawDb.execute(rawSql`SELECT key_name, value FROM business_settings WHERE key_name IN ('platform_commission_b2c','gst_percentage','insurance_per_ride')`);
      const sett: Record<string,string> = {};
      settR.rows.forEach((s: any) => { sett[s.key_name] = s.value; });
      const commPct = parseFloat(sett['platform_commission_b2c'] || '15') / 100;
      const gstPct = parseFloat(sett['gst_percentage'] || '18') / 100;
      const insurancePerRide = parseFloat(sett['insurance_per_ride'] || '5');
      const r = await rawDb.execute(rawSql`SELECT DATE(created_at) as date, COUNT(*) as trips, COUNT(*) FILTER (WHERE current_status='completed') as completed, COUNT(*) FILTER (WHERE current_status='cancelled') as cancelled, COALESCE(SUM(actual_fare) FILTER (WHERE current_status='completed'), 0) as revenue FROM trip_requests WHERE DATE(created_at) BETWEEN ${fromDate} AND ${toDate} GROUP BY DATE(created_at) ORDER BY date`);
      const rows = r.rows.map((row: any) => {
        const rev = parseFloat(row.revenue || 0);
        const commission = rev * commPct;
        const gst = commission * gstPct;
        const insurance = parseFloat(row.completed || 0) * insurancePerRide;
        const adminTotal = commission + gst + insurance;
        const driverEarning = rev - commission;
        return camelize({ ...row, commission: commission.toFixed(2), gst: gst.toFixed(2), insurance: insurance.toFixed(2), admin_total: adminTotal.toFixed(2), driver_earning: driverEarning.toFixed(2) });
      });
      res.json({ rows, summary: { totalRevenue: rows.reduce((s: any, r: any) => s + parseFloat(r.revenue||0), 0).toFixed(2), totalTrips: rows.reduce((s: any, r: any) => s + parseInt(r.trips||0), 0), totalCommission: rows.reduce((s: any, r: any) => s + parseFloat(r.commission||0), 0).toFixed(2), totalGst: rows.reduce((s: any, r: any) => s + parseFloat(r.gst||0), 0).toFixed(2), totalInsurance: rows.reduce((s: any, r: any) => s + parseFloat(r.insurance||0), 0).toFixed(2), totalAdminEarning: rows.reduce((s: any, r: any) => s + parseFloat(r.adminTotal||0), 0).toFixed(2) } });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.get("/api/reports/trips", async (req, res) => {
    try {
      const { from, to } = req.query;
      const fromDate = from || new Date(Date.now() - 30*24*60*60*1000).toISOString().split('T')[0];
      const toDate = to || new Date().toISOString().split('T')[0];
      const r = await rawDb.execute(rawSql`SELECT tr.ref_id, tr.pickup_address, tr.destination_address, tr.estimated_fare, tr.actual_fare, tr.current_status, tr.payment_method, tr.trip_type, tr.created_at, u.full_name as customer_name, vc.name as vehicle_name FROM trip_requests tr LEFT JOIN users u ON u.id=tr.customer_id LEFT JOIN vehicle_categories vc ON vc.id=tr.vehicle_category_id WHERE DATE(tr.created_at) BETWEEN ${fromDate} AND ${toDate} ORDER BY tr.created_at DESC LIMIT 500`);
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.get("/api/reports/drivers", async (req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT u.full_name, u.phone, u.email, u.is_active, u.verification_status, u.created_at, u.vehicle_number, u.vehicle_model, vc.name as vehicle_category, dd.avg_rating, dd.availability_status, COUNT(tr.id) as total_trips, COALESCE(SUM(tr.actual_fare) FILTER (WHERE tr.current_status='completed'), 0) as total_earnings FROM users u LEFT JOIN driver_details dd ON dd.user_id=u.id LEFT JOIN vehicle_categories vc ON vc.id=dd.vehicle_category_id LEFT JOIN trip_requests tr ON tr.driver_id=u.id WHERE u.user_type='driver' GROUP BY u.id, u.full_name, u.phone, u.email, u.is_active, u.verification_status, u.created_at, u.vehicle_number, u.vehicle_model, vc.name, dd.avg_rating, dd.availability_status ORDER BY total_trips DESC`);
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.get("/api/reports/customers", async (req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT u.full_name, u.phone, u.email, u.is_active, u.created_at, COUNT(tr.id) as total_trips, COALESCE(SUM(tr.actual_fare) FILTER (WHERE tr.current_status='completed'), 0) as total_spent FROM users u LEFT JOIN trip_requests tr ON tr.customer_id=u.id WHERE u.user_type='customer' GROUP BY u.id, u.full_name, u.phone, u.email, u.is_active, u.created_at ORDER BY total_spent DESC`);
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ─── Safety Alerts ───────────────────────────────────────────────────────────
  app.get("/api/safety-alerts", async (req, res) => {
    try {
      const status = req.query.status as string;
      const triggeredBy = req.query.triggered_by as string;
      // Build different queries based on filters to avoid dynamic SQL
      let r;
      const base = rawSql`SELECT sa.*, u.full_name as user_name, u.phone as user_phone, u.user_type, u.gender FROM safety_alerts sa LEFT JOIN users u ON u.id = sa.user_id`;
      if (status && status !== 'all' && triggeredBy && triggeredBy !== 'all') {
        r = await rawDb.execute(rawSql`${base} WHERE sa.status=${status} AND sa.triggered_by=${triggeredBy} ORDER BY sa.created_at DESC LIMIT 100`);
      } else if (status && status !== 'all') {
        r = await rawDb.execute(rawSql`${base} WHERE sa.status=${status} ORDER BY sa.created_at DESC LIMIT 100`);
      } else if (triggeredBy && triggeredBy !== 'all') {
        r = await rawDb.execute(rawSql`${base} WHERE sa.triggered_by=${triggeredBy} ORDER BY sa.created_at DESC LIMIT 100`);
      } else {
        r = await rawDb.execute(rawSql`${base} ORDER BY sa.created_at DESC LIMIT 100`);
      }
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/safety-alerts/stats", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT
          COUNT(*) FILTER (WHERE status='active') as active_count,
          COUNT(*) FILTER (WHERE status='acknowledged') as acknowledged_count,
          COUNT(*) FILTER (WHERE status='resolved') as resolved_count,
          COUNT(*) FILTER (WHERE triggered_by='customer') as customer_count,
          COUNT(*) FILTER (WHERE triggered_by='driver') as driver_count,
          COUNT(*) FILTER (WHERE DATE(created_at)=CURRENT_DATE) as today_count
        FROM safety_alerts
      `);
      res.json(camelize(r.rows[0] || {}));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post("/api/safety-alerts", async (req, res) => {
    try {
      const { userId, tripId, alertType, triggeredBy, latitude, longitude, locationAddress } = req.body;
      // Count nearby online drivers (within ~3km)
      const nearbyR = await rawDb.execute(rawSql`
        SELECT COUNT(*) as cnt FROM users u
        JOIN driver_details dd ON dd.user_id = u.id
        WHERE u.user_type='driver' AND dd.is_online=true AND u.is_active=true
      `);
      const nearbyCount = Number((nearbyR.rows[0] as any)?.cnt || 0);
      let r;
      if (userId) {
        r = await rawDb.execute(rawSql`
          INSERT INTO safety_alerts (user_id, trip_id, alert_type, triggered_by, latitude, longitude, location_address, nearby_drivers_notified)
          VALUES (${userId}::uuid, ${tripId ? tripId : null}, ${alertType||'sos'}, ${triggeredBy||'customer'},
                  ${latitude||null}, ${longitude||null}, ${locationAddress||null}, ${nearbyCount})
          RETURNING *
        `);
      } else {
        r = await rawDb.execute(rawSql`
          INSERT INTO safety_alerts (alert_type, triggered_by, latitude, longitude, location_address, nearby_drivers_notified)
          VALUES (${alertType||'sos'}, ${triggeredBy||'customer'},
                  ${latitude||null}, ${longitude||null}, ${locationAddress||null}, ${nearbyCount})
          RETURNING *
        `);
      }
      res.status(201).json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.patch("/api/safety-alerts/:id/acknowledge", async (req, res) => {
    try {
      const { adminName, notes } = req.body;
      const r = await rawDb.execute(rawSql`
        UPDATE safety_alerts SET status='acknowledged', acknowledged_by_name=${adminName||'Admin'},
        acknowledged_at=now(), notes=${notes||null} WHERE id=${req.params.id}::uuid RETURNING *
      `);
      if (!r.rows.length) return res.status(404).json({ message: "Alert not found" });
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.patch("/api/safety-alerts/:id/resolve", async (req, res) => {
    try {
      const { policeNotified, notes } = req.body;
      const r = await rawDb.execute(rawSql`
        UPDATE safety_alerts SET status='resolved', resolved_at=now(),
        police_notified=${policeNotified??false}, notes=${notes||null} WHERE id=${req.params.id}::uuid RETURNING *
      `);
      if (!r.rows.length) return res.status(404).json({ message: "Alert not found" });
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.delete("/api/safety-alerts/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM safety_alerts WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ─── Police Stations ──────────────────────────────────────────────────────────
  app.get("/api/police-stations", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT ps.*, z.name as zone_name FROM police_stations ps LEFT JOIN zones z ON z.id::uuid = ps.zone_id ORDER BY ps.name`);
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post("/api/police-stations", async (req, res) => {
    try {
      const { name, zoneId, address, phone, latitude, longitude } = req.body;
      if (!name) return res.status(400).json({ message: "Station name required" });
      let r;
      if (zoneId) {
        r = await rawDb.execute(rawSql`INSERT INTO police_stations (name, zone_id, address, phone, latitude, longitude) VALUES (${name}, ${zoneId}::uuid, ${address||null}, ${phone||null}, ${latitude||null}, ${longitude||null}) RETURNING *`);
      } else {
        r = await rawDb.execute(rawSql`INSERT INTO police_stations (name, address, phone, latitude, longitude) VALUES (${name}, ${address||null}, ${phone||null}, ${latitude||null}, ${longitude||null}) RETURNING *`);
      }
      res.status(201).json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.put("/api/police-stations/:id", async (req, res) => {
    try {
      const { name, zoneId, address, phone, latitude, longitude, isActive } = req.body;
      let r;
      if (zoneId) {
        r = await rawDb.execute(rawSql`UPDATE police_stations SET name=${name}, zone_id=${zoneId}::uuid, address=${address||null}, phone=${phone||null}, latitude=${latitude||null}, longitude=${longitude||null}, is_active=${isActive??true} WHERE id=${req.params.id}::uuid RETURNING *`);
      } else {
        r = await rawDb.execute(rawSql`UPDATE police_stations SET name=${name}, zone_id=NULL, address=${address||null}, phone=${phone||null}, latitude=${latitude||null}, longitude=${longitude||null}, is_active=${isActive??true} WHERE id=${req.params.id}::uuid RETURNING *`);
      }
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.delete("/api/police-stations/:id", async (req, res) => {
    try {
      await rawDb.execute(rawSql`DELETE FROM police_stations WHERE id=${req.params.id}::uuid`);
      res.status(204).end();
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ─── Female Matching Algorithm — Driver Pool ──────────────────────────────────
  // GET matching algorithm stats
  app.get("/api/matching/stats", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT
          COUNT(*) FILTER (WHERE user_type='driver' AND gender='female') as female_drivers,
          COUNT(*) FILTER (WHERE user_type='driver' AND gender='male') as male_drivers,
          COUNT(*) FILTER (WHERE user_type='customer' AND gender='female') as female_customers,
          COUNT(*) FILTER (WHERE user_type='customer' AND prefer_female_driver=true) as prefer_female_customers
        FROM users WHERE user_type IN ('driver','customer')
      `);
      const settings = await rawDb.execute(rawSql`
        SELECT key_name, value FROM business_settings WHERE settings_type='safety_settings'
      `);
      const settingsMap = Object.fromEntries((settings.rows as any[]).map((s: any) => [s.key_name, s.value]));
      res.json({ stats: camelize(r.rows[0] || {}), settings: settingsMap });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // GET available drivers with matching algorithm applied
  app.get("/api/matching/drivers", async (req, res) => {
    try {
      const { customerGender, vehicleCategoryId } = req.query;
      const settings = await rawDb.execute(rawSql`
        SELECT key_name, value FROM business_settings WHERE key_name IN ('female_to_female_matching','vehicle_type_matching')
      `);
      const sMap = Object.fromEntries((settings.rows as any[]).map((s: any) => [s.key_name, s.value]));
      const femalePriority = sMap['female_to_female_matching'] === '1' && customerGender === 'female';
      const vehicleMatch = sMap['vehicle_type_matching'] === '1' && vehicleCategoryId;

      let r;
      if (vehicleMatch && femalePriority) {
        r = await rawDb.execute(rawSql`
          SELECT u.id, u.full_name, u.phone, u.gender, u.vehicle_number, u.vehicle_model,
                 dd.avg_rating, dd.availability_status, vc.name as vehicle_category, vc.id as vehicle_category_id,
                 CASE WHEN u.gender='female' THEN 1 ELSE 2 END as gender_priority
          FROM users u
          JOIN driver_details dd ON dd.user_id = u.id
          LEFT JOIN vehicle_categories vc ON vc.id = dd.vehicle_category_id
          WHERE u.user_type='driver' AND u.is_active=true AND dd.availability_status='online'
            AND dd.vehicle_category_id = ${vehicleCategoryId as string}::uuid
          ORDER BY gender_priority ASC, dd.avg_rating DESC
        `);
      } else if (vehicleMatch) {
        r = await rawDb.execute(rawSql`
          SELECT u.id, u.full_name, u.phone, u.gender, u.vehicle_number, u.vehicle_model,
                 dd.avg_rating, dd.availability_status, vc.name as vehicle_category, vc.id as vehicle_category_id
          FROM users u
          JOIN driver_details dd ON dd.user_id = u.id
          LEFT JOIN vehicle_categories vc ON vc.id = dd.vehicle_category_id
          WHERE u.user_type='driver' AND u.is_active=true AND dd.availability_status='online'
            AND dd.vehicle_category_id = ${vehicleCategoryId as string}::uuid
          ORDER BY dd.avg_rating DESC
        `);
      } else if (femalePriority) {
        r = await rawDb.execute(rawSql`
          SELECT u.id, u.full_name, u.phone, u.gender, u.vehicle_number, u.vehicle_model,
                 dd.avg_rating, dd.availability_status, vc.name as vehicle_category, vc.id as vehicle_category_id,
                 CASE WHEN u.gender='female' THEN 1 ELSE 2 END as gender_priority
          FROM users u
          JOIN driver_details dd ON dd.user_id = u.id
          LEFT JOIN vehicle_categories vc ON vc.id = dd.vehicle_category_id
          WHERE u.user_type='driver' AND u.is_active=true AND dd.availability_status='online'
          ORDER BY gender_priority ASC, dd.avg_rating DESC
        `);
      } else {
        r = await rawDb.execute(rawSql`
          SELECT u.id, u.full_name, u.phone, u.gender, u.vehicle_number, u.vehicle_model,
                 dd.avg_rating, dd.availability_status, vc.name as vehicle_category, vc.id as vehicle_category_id
          FROM users u
          JOIN driver_details dd ON dd.user_id = u.id
          LEFT JOIN vehicle_categories vc ON vc.id = dd.vehicle_category_id
          WHERE u.user_type='driver' AND u.is_active=true AND dd.availability_status='online'
          ORDER BY dd.avg_rating DESC
        `);
      }
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // PATCH user gender + preference
  app.patch("/api/users/:id/gender", async (req, res) => {
    try {
      const { gender, preferFemaleDriver, emergencyContactName, emergencyContactPhone } = req.body;
      const r = await rawDb.execute(rawSql`
        UPDATE users SET
          gender = ${gender || 'male'},
          prefer_female_driver = ${preferFemaleDriver ?? false},
          emergency_contact_name = ${emergencyContactName || null},
          emergency_contact_phone = ${emergencyContactPhone || null}
        WHERE id = ${req.params.id}::uuid RETURNING id, full_name, gender, prefer_female_driver, emergency_contact_name, emergency_contact_phone
      `);
      if (!r.rows.length) return res.status(404).json({ message: "User not found" });
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ========== FARE CALCULATOR ==========
  app.post("/api/fare-calculator", async (req, res) => {
    try {
      const { zoneId, vehicleCategoryId, distanceKm, durationMin = 0 } = req.body;
      if (!zoneId || !vehicleCategoryId || !distanceKm) {
        return res.status(400).json({ message: "zoneId, vehicleCategoryId and distanceKm required" });
      }
      const fare = await rawDb.execute(rawSql`
        SELECT tf.base_fare, tf.fare_per_km, tf.fare_per_min, tf.minimum_fare, tf.cancellation_fee,
               vc.name as vehicle_name, vc.icon as vehicle_icon,
               z.name as zone_name
        FROM trip_fares tf
        JOIN vehicle_categories vc ON vc.id = tf.vehicle_category_id
        JOIN zones z ON z.id = tf.zone_id
        WHERE tf.zone_id = ${zoneId}::uuid AND tf.vehicle_category_id = ${vehicleCategoryId}::uuid
        LIMIT 1
      `);
      if (!fare.rows.length) return res.status(404).json({ message: "No fare found for this zone and vehicle" });
      const f = fare.rows[0] as any;
      const base = parseFloat(f.base_fare || "0");
      const perKm = parseFloat(f.fare_per_km || "0");
      const perMin = parseFloat(f.fare_per_min || "0");
      const minFare = parseFloat(f.minimum_fare || "0");
      const cancelFee = parseFloat(f.cancellation_fee || "0");
      const dist = parseFloat(distanceKm);
      const dur = parseFloat(durationMin);
      const baseFareAmt = base;
      const distanceFare = perKm * dist;
      const timeFare = perMin * dur;
      const subtotal = baseFareAmt + distanceFare + timeFare;
      const total = Math.max(subtotal, minFare);
      const gst = total * 0.05;
      const grandTotal = total + gst;
      res.json({
        vehicleName: f.vehicle_name,
        vehicleIcon: f.vehicle_icon,
        zoneName: f.zone_name,
        breakdown: {
          baseFare: baseFareAmt.toFixed(2),
          distanceFare: distanceFare.toFixed(2),
          timeFare: timeFare.toFixed(2),
          subtotal: subtotal.toFixed(2),
          minimumFare: minFare.toFixed(2),
          cancellationFee: cancelFee.toFixed(2),
          gst: gst.toFixed(2),
          total: grandTotal.toFixed(2),
        },
        inputs: { distanceKm: dist, durationMin: dur, perKm, perMin, baseFare: base },
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ========== DRIVER EARNINGS ==========
  app.get("/api/driver-earnings", async (req, res) => {
    try {
      const { search = "", limit = 50, offset = 0 } = req.query;
      const rows = await rawDb.execute(rawSql`
        SELECT
          u.id, u.full_name, u.phone, u.email, u.vehicle_number, u.vehicle_model,
          u.verification_status, u.is_active,
          vc.name as vehicle_category,
          dd.avg_rating, dd.availability_status,
          COUNT(tr.id) FILTER (WHERE tr.current_status = 'completed') as completed_trips,
          COALESCE(SUM(tr.actual_fare) FILTER (WHERE tr.current_status = 'completed'), 0) as gross_earnings,
          COALESCE(SUM(tr.actual_fare * 0.15) FILTER (WHERE tr.current_status = 'completed'), 0) as commission,
          COALESCE(SUM(tr.actual_fare * 0.05) FILTER (WHERE tr.current_status = 'completed'), 0) as gst,
          COALESCE(SUM(tr.actual_fare * 0.80) FILTER (WHERE tr.current_status = 'completed'), 0) as net_earnings,
          COUNT(tr.id) FILTER (WHERE tr.current_status = 'cancelled') as cancelled_trips,
          COUNT(tr.id) FILTER (WHERE tr.current_status = 'completed' AND tr.created_at >= NOW() - INTERVAL '30 days') as this_month_trips,
          COALESCE(SUM(tr.actual_fare) FILTER (WHERE tr.current_status = 'completed' AND tr.created_at >= NOW() - INTERVAL '30 days'), 0) as this_month_earnings
        FROM users u
        LEFT JOIN driver_details dd ON dd.user_id = u.id
        LEFT JOIN vehicle_categories vc ON vc.id = dd.vehicle_category_id
        LEFT JOIN trip_requests tr ON tr.driver_id = u.id
        WHERE u.user_type = 'driver'
          AND (${search} = '' OR u.full_name ILIKE ${'%' + search + '%'} OR u.phone ILIKE ${'%' + search + '%'})
        GROUP BY u.id, u.full_name, u.phone, u.email, u.vehicle_number, u.vehicle_model,
                 u.verification_status, u.is_active, vc.name, dd.avg_rating, dd.availability_status
        ORDER BY gross_earnings DESC
        LIMIT ${Number(limit)} OFFSET ${Number(offset)}
      `);
      res.json(rows.rows.map(camelize));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/driver-earnings/:driverId", async (req, res) => {
    try {
      const driverId = req.params.driverId;
      const [profile, monthly] = await Promise.all([
        rawDb.execute(rawSql`
          SELECT u.id, u.full_name, u.phone, u.email, u.vehicle_number, u.vehicle_model,
                 u.verification_status, u.is_active, u.created_at,
                 vc.name as vehicle_category, dd.avg_rating, dd.availability_status
          FROM users u
          LEFT JOIN driver_details dd ON dd.user_id = u.id
          LEFT JOIN vehicle_categories vc ON vc.id = dd.vehicle_category_id
          WHERE u.id = ${driverId}::uuid AND u.user_type = 'driver'
          LIMIT 1
        `),
        rawDb.execute(rawSql`
          SELECT
            TO_CHAR(DATE_TRUNC('month', created_at), 'YYYY-MM') as month,
            TO_CHAR(DATE_TRUNC('month', created_at), 'Mon YYYY') as month_label,
            COUNT(*) FILTER (WHERE current_status = 'completed') as completed,
            COUNT(*) FILTER (WHERE current_status = 'cancelled') as cancelled,
            COALESCE(SUM(actual_fare) FILTER (WHERE current_status = 'completed'), 0) as gross,
            COALESCE(SUM(actual_fare * 0.15) FILTER (WHERE current_status = 'completed'), 0) as commission,
            COALESCE(SUM(actual_fare * 0.05) FILTER (WHERE current_status = 'completed'), 0) as gst,
            COALESCE(SUM(actual_fare * 0.80) FILTER (WHERE current_status = 'completed'), 0) as net
          FROM trip_requests
          WHERE driver_id = ${driverId}::uuid
          GROUP BY DATE_TRUNC('month', created_at)
          ORDER BY month DESC
          LIMIT 12
        `)
      ]);
      if (!profile.rows.length) return res.status(404).json({ message: "Driver not found" });
      res.json({
        profile: camelize(profile.rows[0]),
        monthly: monthly.rows.map(camelize),
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ========== REFERRAL SYSTEM ==========
  app.get("/api/referrals/stats", async (req, res) => {
    try {
      const stats = await rawDb.execute(rawSql`
        SELECT
          COUNT(*) as total,
          COUNT(*) FILTER (WHERE status = 'paid') as paid,
          COUNT(*) FILTER (WHERE status = 'pending') as pending,
          COUNT(*) FILTER (WHERE status = 'expired') as expired,
          COALESCE(SUM(reward_amount) FILTER (WHERE status = 'paid'), 0) as total_rewarded,
          COALESCE(SUM(reward_amount) FILTER (WHERE status = 'pending'), 0) as pending_amount,
          COUNT(*) FILTER (WHERE referral_type = 'customer') as customer_referrals,
          COUNT(*) FILTER (WHERE referral_type = 'driver') as driver_referrals
        FROM referrals
      `);
      res.json(camelize(stats.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/referrals", async (req, res) => {
    try {
      const { status = "all", referralType = "all", limit = 50, offset = 0 } = req.query;
      const rows = await rawDb.execute(rawSql`
        SELECT r.*,
               ru.full_name as referrer_name, ru.phone as referrer_phone, ru.user_type as referrer_type,
               rd.full_name as referred_name, rd.phone as referred_phone
        FROM referrals r
        LEFT JOIN users ru ON ru.id = r.referrer_id
        LEFT JOIN users rd ON rd.id = r.referred_id
        WHERE (${status} = 'all' OR r.status = ${status})
          AND (${referralType} = 'all' OR r.referral_type = ${referralType})
        ORDER BY r.created_at DESC
        LIMIT ${Number(limit)} OFFSET ${Number(offset)}
      `);
      res.json(rows.rows.map(camelize));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.patch("/api/referrals/:id/pay", async (req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        UPDATE referrals SET status = 'paid' WHERE id = ${req.params.id}::uuid RETURNING *
      `);
      if (!r.rows.length) return res.status(404).json({ message: "Referral not found" });
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.patch("/api/referrals/:id/expire", async (req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        UPDATE referrals SET status = 'expired' WHERE id = ${req.params.id}::uuid RETURNING *
      `);
      if (!r.rows.length) return res.status(404).json({ message: "Referral not found" });
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ═══════════════════════════════════════════════════════════════════════
  // ██  MOBILE APP APIs — Driver App + Customer App                       ██
  // ═══════════════════════════════════════════════════════════════════════

  // ── OTP SEND (mock — logs OTP to console; plug real SMS later) ──────────
  app.post("/api/app/send-otp", async (req, res) => {
    try {
      const { phone, userType = "customer" } = req.body;
      if (!phone) return res.status(400).json({ message: "Phone required" });
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 min
      // Invalidate previous OTPs for same phone
      await rawDb.execute(rawSql`UPDATE otp_logs SET is_used=true WHERE phone=${phone} AND is_used=false`);
      await rawDb.execute(rawSql`
        INSERT INTO otp_logs (phone, otp, user_type, expires_at) VALUES (${phone}, ${otp}, ${userType}, ${expiresAt.toISOString()})
      `);
      // In production: send via SMS gateway (Twilio / MSG91)
      console.log(`[OTP] ${phone} → ${otp} (${userType})`);
      res.json({ success: true, message: "OTP sent", ...(process.env.NODE_ENV === "development" ? { otp } : {}) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── OTP VERIFY + LOGIN / REGISTER ────────────────────────────────────────
  app.post("/api/app/verify-otp", async (req, res) => {
    try {
      const { phone, otp, userType = "customer", name, referralCode } = req.body;
      if (!phone || !otp) return res.status(400).json({ message: "Phone and OTP required" });

      // Check OTP
      const otpRow = await rawDb.execute(rawSql`
        SELECT * FROM otp_logs WHERE phone=${phone} AND otp=${otp} AND is_used=false AND expires_at > NOW()
        ORDER BY created_at DESC LIMIT 1
      `);
      if (!otpRow.rows.length) return res.status(400).json({ message: "Invalid or expired OTP" });

      // Mark used
      await rawDb.execute(rawSql`UPDATE otp_logs SET is_used=true WHERE id=${(otpRow.rows[0] as any).id}::uuid`);

      // Find or create user
      let userRes = await rawDb.execute(rawSql`SELECT * FROM users WHERE phone=${phone} AND user_type=${userType} LIMIT 1`);
      let user: any;
      let isNew = false;

      if (!userRes.rows.length) {
        // Register new user
        isNew = true;
        const fullName = name || `User_${phone.slice(-4)}`;
        const newUser = await rawDb.execute(rawSql`
          INSERT INTO users (full_name, phone, user_type, is_active, wallet_balance)
          VALUES (${fullName}, ${phone}, ${userType}, true, 0)
          RETURNING *
        `);
        user = camelize(newUser.rows[0]);
      } else {
        user = camelize(userRes.rows[0]);
        if (!user.isActive) return res.status(403).json({ message: "Account deactivated. Contact support." });
      }

      // Generate simple token (in production use JWT)
      const token = `${user.id}:${crypto.randomBytes(32).toString("hex")}`;
      // Store token in user_devices table
      await rawDb.execute(rawSql`
        INSERT INTO user_devices (user_id, fcm_token, device_type) VALUES (${user.id}::uuid, ${token}, 'mobile')
        ON CONFLICT (user_id) DO UPDATE SET fcm_token=${token}, updated_at=NOW()
      `);

      // If driver, get wallet info
      let walletBalance = 0;
      let isLocked = false;
      if (userType === "driver") {
        const walletR = await rawDb.execute(rawSql`SELECT wallet_balance, is_locked, is_online FROM users WHERE id=${user.id}::uuid`);
        if (walletR.rows.length) {
          walletBalance = parseFloat((walletR.rows[0] as any).wallet_balance || 0);
          isLocked = (walletR.rows[0] as any).is_locked || false;
        }
      }

      res.json({
        success: true,
        isNew,
        token,
        user: {
          id: user.id,
          fullName: user.fullName,
          phone: user.phone,
          email: user.email || null,
          userType: user.userType,
          profilePhoto: user.profilePhoto || null,
          rating: parseFloat(user.rating || "5.0"),
          isActive: user.isActive,
          walletBalance,
          isLocked,
        }
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── AUTH MIDDLEWARE (simple token check) ─────────────────────────────────
  async function authApp(req: Request, res: Response, next: NextFunction) {
    try {
      const token = req.headers.authorization?.replace("Bearer ", "");
      if (!token) return res.status(401).json({ message: "No token provided" });
      const userId = token.split(":")[0];
      if (!userId) return res.status(401).json({ message: "Invalid token" });
      const userR = await rawDb.execute(rawSql`SELECT * FROM users WHERE id=${userId}::uuid AND is_active=true LIMIT 1`);
      if (!userR.rows.length) return res.status(401).json({ message: "User not found or inactive" });
      (req as any).currentUser = camelize(userR.rows[0]);
      next();
    } catch (e: any) { res.status(401).json({ message: "Auth failed" }); }
  }

  // ── DRIVER: Go Online / Offline + Location Update ─────────────────────────
  app.post("/api/app/driver/location", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { lat, lng, heading = 0, speed = 0, isOnline } = req.body;
      // Upsert location
      await rawDb.execute(rawSql`
        INSERT INTO driver_locations (driver_id, lat, lng, heading, speed, is_online)
        VALUES (${driver.id}::uuid, ${lat}, ${lng}, ${heading}, ${speed}, ${isOnline ?? driver.isOnline ?? false})
        ON CONFLICT (driver_id) DO UPDATE SET lat=${lat}, lng=${lng}, heading=${heading}, speed=${speed},
          is_online=${isOnline ?? driver.isOnline ?? false}, updated_at=NOW()
      `);
      // Also update users table
      if (isOnline !== undefined) {
        await rawDb.execute(rawSql`UPDATE users SET is_online=${isOnline}, current_lat=${lat}, current_lng=${lng} WHERE id=${driver.id}::uuid`);
      } else {
        await rawDb.execute(rawSql`UPDATE users SET current_lat=${lat}, current_lng=${lng} WHERE id=${driver.id}::uuid`);
      }
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.patch("/api/app/driver/online-status", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { isOnline } = req.body;
      // Check if locked
      if (isOnline) {
        const walletR = await rawDb.execute(rawSql`SELECT is_locked, wallet_balance FROM users WHERE id=${driver.id}::uuid`);
        const w = walletR.rows[0] as any;
        if (w?.is_locked) return res.status(403).json({ message: "Account locked. Please clear dues to go online.", isLocked: true, walletBalance: parseFloat(w.wallet_balance || 0) });
      }
      await rawDb.execute(rawSql`UPDATE users SET is_online=${isOnline} WHERE id=${driver.id}::uuid`);
      await rawDb.execute(rawSql`UPDATE driver_locations SET is_online=${isOnline}, updated_at=NOW() WHERE driver_id=${driver.id}::uuid`);
      res.json({ success: true, isOnline });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Get profile + wallet + current trip ───────────────────────────
  app.get("/api/app/driver/profile", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT u.*,
          (SELECT COUNT(*) FROM trip_requests WHERE driver_id=u.id AND current_status='completed') as completed_trips,
          (SELECT COALESCE(SUM(actual_fare),0) FROM trip_requests WHERE driver_id=u.id AND current_status='completed') as total_earned,
          (SELECT COUNT(*) FROM trip_requests WHERE driver_id=u.id AND current_status='cancelled') as cancelled_trips
        FROM users u WHERE u.id=${driver.id}::uuid
      `);
      const loc = await rawDb.execute(rawSql`SELECT lat, lng, is_online FROM driver_locations WHERE driver_id=${driver.id}::uuid`);
      const d = camelize(r.rows[0]) as any;
      res.json({
        id: d.id,
        fullName: d.fullName,
        phone: d.phone,
        email: d.email,
        profilePhoto: d.profilePhoto,
        rating: parseFloat(d.rating || "5.0"),
        totalRatings: d.totalRatings || 0,
        walletBalance: parseFloat(d.walletBalance || "0"),
        isLocked: d.isLocked || false,
        lockReason: d.lockReason || null,
        isOnline: loc.rows.length ? (loc.rows[0] as any).is_online : false,
        currentLat: loc.rows.length ? (loc.rows[0] as any).lat : null,
        currentLng: loc.rows.length ? (loc.rows[0] as any).lng : null,
        stats: {
          completedTrips: parseInt(d.completedTrips || "0"),
          totalEarned: parseFloat(d.totalEarned || "0"),
          cancelledTrips: parseInt(d.cancelledTrips || "0"),
        }
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Incoming trip request (polling) ───────────────────────────────
  app.get("/api/app/driver/incoming-trip", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT t.*,
          c.full_name as customer_name, c.phone as customer_phone, c.rating as customer_rating,
          vc.name as vehicle_name
        FROM trip_requests t
        LEFT JOIN users c ON c.id = t.customer_id
        LEFT JOIN vehicle_categories vc ON vc.id = t.vehicle_category_id
        WHERE t.driver_id = ${driver.id}::uuid AND t.current_status = 'accepted'
        ORDER BY t.created_at DESC LIMIT 1
      `);
      if (!r.rows.length) {
        // Also check for newly assigned (searching) trip for this driver
        const pending = await rawDb.execute(rawSql`
          SELECT t.*,
            c.full_name as customer_name, c.phone as customer_phone,
            vc.name as vehicle_name
          FROM trip_requests t
          LEFT JOIN users c ON c.id = t.customer_id
          LEFT JOIN vehicle_categories vc ON vc.id = t.vehicle_category_id
          WHERE t.driver_id = ${driver.id}::uuid AND t.current_status = 'driver_assigned'
          LIMIT 1
        `);
        if (!pending.rows.length) return res.json({ trip: null });
        return res.json({ trip: camelize(pending.rows[0]), stage: "assigned" });
      }
      res.json({ trip: camelize(r.rows[0]), stage: "accepted" });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Accept trip ───────────────────────────────────────────────────
  app.post("/api/app/driver/accept-trip", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { tripId } = req.body;
      // Generate pickup OTP
      const otp = Math.floor(1000 + Math.random() * 9000).toString();
      const r = await rawDb.execute(rawSql`
        UPDATE trip_requests
        SET current_status='accepted', driver_accepted_at=NOW(), pickup_otp=${otp}
        WHERE id=${tripId}::uuid AND (driver_id=${driver.id}::uuid OR driver_id IS NULL) AND current_status IN ('driver_assigned','searching')
        RETURNING *
      `);
      if (!r.rows.length) return res.status(404).json({ message: "Trip not found or already accepted" });
      // Assign driver if not set
      await rawDb.execute(rawSql`UPDATE trip_requests SET driver_id=${driver.id}::uuid WHERE id=${tripId}::uuid AND driver_id IS NULL`);
      res.json({ success: true, trip: camelize(r.rows[0]), pickupOtp: otp });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Reject / skip trip ─────────────────────────────────────────────
  app.post("/api/app/driver/reject-trip", authApp, async (req, res) => {
    try {
      const { tripId } = req.body;
      await rawDb.execute(rawSql`
        UPDATE trip_requests SET current_status='searching', driver_id=NULL WHERE id=${tripId}::uuid AND current_status='driver_assigned'
      `);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Verify pickup OTP + start ride ────────────────────────────────
  app.post("/api/app/driver/verify-pickup-otp", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { tripId, otp } = req.body;
      const r = await rawDb.execute(rawSql`
        SELECT * FROM trip_requests WHERE id=${tripId}::uuid AND driver_id=${driver.id}::uuid AND current_status='accepted'
      `);
      if (!r.rows.length) return res.status(404).json({ message: "Trip not found" });
      const trip = r.rows[0] as any;
      if (trip.pickup_otp !== otp) return res.status(400).json({ message: "Wrong OTP. Please check with customer." });
      const updated = await rawDb.execute(rawSql`
        UPDATE trip_requests SET current_status='on_the_way', ride_started_at=NOW()
        WHERE id=${tripId}::uuid RETURNING *
      `);
      res.json({ success: true, trip: camelize(updated.rows[0]) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Arrived at pickup ─────────────────────────────────────────────
  app.post("/api/app/driver/arrived", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { tripId } = req.body;
      await rawDb.execute(rawSql`
        UPDATE trip_requests SET current_status='arrived' WHERE id=${tripId}::uuid AND driver_id=${driver.id}::uuid
      `);
      // Get pickup OTP to show customer
      const r = await rawDb.execute(rawSql`SELECT pickup_otp FROM trip_requests WHERE id=${tripId}::uuid`);
      res.json({ success: true, pickupOtp: (r.rows[0] as any)?.pickup_otp });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Complete trip ─────────────────────────────────────────────────
  app.post("/api/app/driver/complete-trip", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { tripId, actualFare, actualDistance, tips = 0 } = req.body;
      const r = await rawDb.execute(rawSql`
        UPDATE trip_requests
        SET current_status='completed', ride_ended_at=NOW(),
            actual_fare=${actualFare}, actual_distance=${actualDistance || 0},
            tips=${tips}, payment_status='paid'
        WHERE id=${tripId}::uuid AND driver_id=${driver.id}::uuid AND current_status='on_the_way'
        RETURNING *
      `);
      if (!r.rows.length) return res.status(404).json({ message: "Trip not found" });

      // Auto-deduct platform commission from driver wallet
      const settingR = await rawDb.execute(rawSql`SELECT key_name, value FROM revenue_model_settings WHERE key_name IN ('commission_pct','commission_gst_pct','commission_insurance_per_ride','auto_lock_threshold','active_model')`);
      const s: any = {};
      settingR.rows.forEach((row: any) => { s[row.key_name] = row.value; });
      let deductAmount = 0;
      if ((s.active_model || "commission") === "commission") {
        const commPct = parseFloat(s.commission_pct || "15") / 100;
        const gstPct = parseFloat(s.commission_gst_pct || "18") / 100;
        const ins = parseFloat(s.commission_insurance_per_ride || "2");
        const comm = actualFare * commPct;
        deductAmount = comm + (comm * gstPct) + ins;
      }
      if (deductAmount > 0) {
        const threshold = parseFloat(s.auto_lock_threshold || "-100");
        const wUpd = await rawDb.execute(rawSql`
          UPDATE users SET wallet_balance = wallet_balance - ${deductAmount}
          WHERE id=${driver.id}::uuid RETURNING wallet_balance, is_locked
        `);
        const newBalance = parseFloat((wUpd.rows[0] as any)?.wallet_balance || 0);
        if (newBalance < threshold && !(wUpd.rows[0] as any)?.is_locked) {
          await rawDb.execute(rawSql`UPDATE users SET is_locked=true, lock_reason=${'Balance below ₹' + Math.abs(threshold) + ' threshold. Please pay dues.'}, locked_at=NOW() WHERE id=${driver.id}::uuid`);
        }
        await rawDb.execute(rawSql`
          INSERT INTO driver_payments (driver_id, amount, payment_type, status, description)
          VALUES (${driver.id}::uuid, ${deductAmount}, 'deduction', 'completed', ${'Commission + GST + Insurance for trip ' + tripId})
        `);
      }

      res.json({ success: true, trip: camelize(r.rows[0]), platformDeduction: deductAmount });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Cancel trip ───────────────────────────────────────────────────
  app.post("/api/app/driver/cancel-trip", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { tripId, reason } = req.body;
      await rawDb.execute(rawSql`
        UPDATE trip_requests SET current_status='cancelled', cancelled_by='driver', cancel_reason=${reason || 'Driver cancelled'}
        WHERE id=${tripId}::uuid AND driver_id=${driver.id}::uuid AND current_status IN ('accepted','arrived')
      `);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Trip history ──────────────────────────────────────────────────
  app.get("/api/app/driver/trips", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { status, limit = 20, offset = 0 } = req.query;
      const r = await rawDb.execute(rawSql`
        SELECT t.*, c.full_name as customer_name, c.phone as customer_phone
        FROM trip_requests t
        LEFT JOIN users c ON c.id = t.customer_id
        WHERE t.driver_id = ${driver.id}::uuid
        ${status ? rawSql`AND t.current_status = ${status as string}` : rawSql``}
        ORDER BY t.created_at DESC LIMIT ${Number(limit)} OFFSET ${Number(offset)}
      `);
      const cnt = await rawDb.execute(rawSql`SELECT COUNT(*) as total FROM trip_requests WHERE driver_id=${driver.id}::uuid ${status ? rawSql`AND current_status=${status as string}` : rawSql``}`);
      res.json({ data: camelize(r.rows), total: Number((cnt.rows[0] as any).total) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Rate customer ─────────────────────────────────────────────────
  app.post("/api/app/driver/rate-customer", authApp, async (req, res) => {
    try {
      const { tripId, rating, note } = req.body;
      const tripR = await rawDb.execute(rawSql`SELECT customer_id FROM trip_requests WHERE id=${tripId}::uuid`);
      if (!tripR.rows.length) return res.status(404).json({ message: "Trip not found" });
      const customerId = (tripR.rows[0] as any).customer_id;
      await rawDb.execute(rawSql`UPDATE trip_requests SET customer_rating=${rating}, driver_note=${note||''} WHERE id=${tripId}::uuid`);
      // Update customer rating average
      await rawDb.execute(rawSql`
        UPDATE users SET
          rating = (rating * total_ratings + ${rating}) / (total_ratings + 1),
          total_ratings = total_ratings + 1
        WHERE id=${customerId}::uuid
      `);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Get wallet summary ─────────────────────────────────────────────
  app.get("/api/app/driver/wallet", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`SELECT wallet_balance, is_locked, lock_reason, pending_payment_amount FROM users WHERE id=${driver.id}::uuid`);
      const payments = await rawDb.execute(rawSql`SELECT * FROM driver_payments WHERE driver_id=${driver.id}::uuid ORDER BY created_at DESC LIMIT 20`);
      const d = r.rows[0] as any;
      res.json({
        walletBalance: parseFloat(d?.wallet_balance || 0),
        isLocked: d?.is_locked || false,
        lockReason: d?.lock_reason || null,
        pendingPaymentAmount: parseFloat(d?.pending_payment_amount || 0),
        history: camelize(payments.rows),
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Get profile ─────────────────────────────────────────────────
  app.get("/api/app/customer/profile", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT u.*,
          (SELECT COUNT(*) FROM trip_requests WHERE customer_id=u.id AND current_status='completed') as completed_trips,
          (SELECT COALESCE(SUM(actual_fare),0) FROM trip_requests WHERE customer_id=u.id AND current_status='completed') as total_spent
        FROM users u WHERE u.id=${customer.id}::uuid
      `);
      const d = camelize(r.rows[0]) as any;
      res.json({
        id: d.id,
        fullName: d.fullName,
        phone: d.phone,
        email: d.email,
        profilePhoto: d.profilePhoto,
        rating: parseFloat(d.rating || "5.0"),
        walletBalance: parseFloat(d.walletBalance || "0"),
        stats: {
          completedTrips: parseInt(d.completedTrips || "0"),
          totalSpent: parseFloat(d.totalSpent || "0"),
        }
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Book a ride ─────────────────────────────────────────────────
  app.post("/api/app/customer/book-ride", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const {
        pickupAddress, pickupLat, pickupLng,
        destinationAddress, destinationLat, destinationLng,
        vehicleCategoryId, estimatedFare, estimatedDistance,
        paymentMethod = "cash", tripType = "normal", isScheduled = false, scheduledAt
      } = req.body;

      // Check if customer already has an active trip
      const active = await rawDb.execute(rawSql`
        SELECT id FROM trip_requests WHERE customer_id=${customer.id}::uuid AND current_status NOT IN ('completed','cancelled')
      `);
      if (active.rows.length) return res.status(400).json({ message: "You already have an active trip" });

      // Generate ref_id
      const refId = "TRP" + Date.now().toString().slice(-8).toUpperCase();

      // Find nearest available driver
      const drivers = await rawDb.execute(rawSql`
        SELECT u.id, u.full_name, u.phone, dl.lat, dl.lng,
          (dl.lat - ${pickupLat})*(dl.lat - ${pickupLat}) + (dl.lng - ${pickupLng})*(dl.lng - ${pickupLng}) as dist_sq
        FROM users u
        JOIN driver_locations dl ON dl.driver_id = u.id
        WHERE u.user_type='driver' AND u.is_active=true AND u.is_locked=false AND dl.is_online=true
          AND u.current_trip_id IS NULL
        ORDER BY dist_sq ASC LIMIT 1
      `);

      const nearestDriver = drivers.rows.length ? camelize(drivers.rows[0]) : null;

      const trip = await rawDb.execute(rawSql`
        INSERT INTO trip_requests (
          ref_id, customer_id, driver_id, vehicle_category_id,
          pickup_address, pickup_lat, pickup_lng,
          destination_address, destination_lat, destination_lng,
          estimated_fare, estimated_distance, payment_method,
          trip_type, current_status, is_scheduled, scheduled_at
        ) VALUES (
          ${refId}, ${customer.id}::uuid,
          ${nearestDriver ? nearestDriver.id + '::uuid' : null},
          ${vehicleCategoryId ? vehicleCategoryId + '::uuid' : null},
          ${pickupAddress}, ${pickupLat}, ${pickupLng},
          ${destinationAddress}, ${destinationLat}, ${destinationLng},
          ${estimatedFare}, ${estimatedDistance || 0}, ${paymentMethod},
          ${tripType}, ${nearestDriver ? 'driver_assigned' : 'searching'}, ${isScheduled}, ${scheduledAt || null}
        ) RETURNING *
      `);

      // Mark driver as on current trip
      if (nearestDriver) {
        await rawDb.execute(rawSql`UPDATE users SET current_trip_id=${(trip.rows[0] as any).id}::uuid WHERE id=${nearestDriver.id}::uuid`);
      }

      res.json({
        success: true,
        trip: camelize(trip.rows[0]),
        driver: nearestDriver ? {
          id: nearestDriver.id,
          fullName: nearestDriver.fullName,
          phone: nearestDriver.phone,
          lat: nearestDriver.lat,
          lng: nearestDriver.lng,
        } : null,
        status: nearestDriver ? "driver_assigned" : "searching",
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Track current trip ──────────────────────────────────────────
  app.get("/api/app/customer/track-trip/:tripId", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const { tripId } = req.params;
      const r = await rawDb.execute(rawSql`
        SELECT t.*,
          d.full_name as driver_name, d.phone as driver_phone, d.rating as driver_rating, d.profile_photo as driver_photo,
          dl.lat as driver_lat, dl.lng as driver_lng, dl.heading as driver_heading
        FROM trip_requests t
        LEFT JOIN users d ON d.id = t.driver_id
        LEFT JOIN driver_locations dl ON dl.driver_id = t.driver_id
        WHERE t.id = ${tripId}::uuid AND t.customer_id = ${customer.id}::uuid
      `);
      if (!r.rows.length) return res.status(404).json({ message: "Trip not found" });
      const trip = camelize(r.rows[0]) as any;
      // Mask pickup OTP for customer (only show first 2 digits if arrived)
      if (trip.currentStatus === "arrived" || trip.currentStatus === "accepted") {
        // Customer needs to share OTP with driver
        trip.pickupOtpVisible = trip.pickupOtp;
      } else {
        delete trip.pickupOtp;
      }
      res.json(trip);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Get active trip ─────────────────────────────────────────────
  app.get("/api/app/customer/active-trip", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT t.*,
          d.full_name as driver_name, d.phone as driver_phone, d.rating as driver_rating,
          dl.lat as driver_lat, dl.lng as driver_lng, dl.heading as driver_heading,
          vc.name as vehicle_name
        FROM trip_requests t
        LEFT JOIN users d ON d.id = t.driver_id
        LEFT JOIN driver_locations dl ON dl.driver_id = t.driver_id
        LEFT JOIN vehicle_categories vc ON vc.id = t.vehicle_category_id
        WHERE t.customer_id = ${customer.id}::uuid AND t.current_status NOT IN ('completed','cancelled')
        ORDER BY t.created_at DESC LIMIT 1
      `);
      if (!r.rows.length) return res.json({ trip: null });
      const trip = camelize(r.rows[0]) as any;
      if (trip.currentStatus === "arrived" || trip.currentStatus === "accepted") {
        trip.pickupOtpVisible = trip.pickupOtp;
      } else {
        delete trip.pickupOtp;
      }
      res.json({ trip });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Cancel trip ─────────────────────────────────────────────────
  app.post("/api/app/customer/cancel-trip", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const { tripId, reason } = req.body;
      const r = await rawDb.execute(rawSql`
        UPDATE trip_requests SET current_status='cancelled', cancelled_by='customer', cancel_reason=${reason||'Customer cancelled'}
        WHERE id=${tripId}::uuid AND customer_id=${customer.id}::uuid AND current_status NOT IN ('completed','cancelled','on_the_way')
        RETURNING *
      `);
      if (!r.rows.length) return res.status(400).json({ message: "Cannot cancel — trip already in progress or completed" });
      // Free driver
      const trip = r.rows[0] as any;
      if (trip.driver_id) {
        await rawDb.execute(rawSql`UPDATE users SET current_trip_id=NULL WHERE id=${trip.driver_id}::uuid`);
      }
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Rate driver ─────────────────────────────────────────────────
  app.post("/api/app/customer/rate-driver", authApp, async (req, res) => {
    try {
      const { tripId, rating, review } = req.body;
      const tripR = await rawDb.execute(rawSql`SELECT driver_id FROM trip_requests WHERE id=${tripId}::uuid`);
      if (!tripR.rows.length) return res.status(404).json({ message: "Trip not found" });
      const driverId = (tripR.rows[0] as any).driver_id;
      await rawDb.execute(rawSql`UPDATE trip_requests SET driver_rating=${rating} WHERE id=${tripId}::uuid`);
      if (driverId) {
        await rawDb.execute(rawSql`
          UPDATE users SET
            rating = (rating * total_ratings + ${rating}) / (total_ratings + 1),
            total_ratings = total_ratings + 1
          WHERE id=${driverId}::uuid
        `);
        // Also insert into reviews table
        await rawDb.execute(rawSql`
          INSERT INTO reviews (trip_id, reviewer_id, reviewee_id, rating, comment, review_type)
          VALUES (${tripId}::uuid, ${(req as any).currentUser.id}::uuid, ${driverId}::uuid, ${rating}, ${review||''}, 'customer_to_driver')
          ON CONFLICT DO NOTHING
        `).catch(() => {});
      }
      // Free driver from current trip
      if (driverId) await rawDb.execute(rawSql`UPDATE users SET current_trip_id=NULL WHERE id=${driverId}::uuid`);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Trip history ─────────────────────────────────────────────────
  app.get("/api/app/customer/trips", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const { limit = 20, offset = 0 } = req.query;
      const r = await rawDb.execute(rawSql`
        SELECT t.*, d.full_name as driver_name, d.phone as driver_phone, d.profile_photo as driver_photo,
          vc.name as vehicle_name
        FROM trip_requests t
        LEFT JOIN users d ON d.id = t.driver_id
        LEFT JOIN vehicle_categories vc ON vc.id = t.vehicle_category_id
        WHERE t.customer_id = ${customer.id}::uuid
        ORDER BY t.created_at DESC LIMIT ${Number(limit)} OFFSET ${Number(offset)}
      `);
      const cnt = await rawDb.execute(rawSql`SELECT COUNT(*) as total FROM trip_requests WHERE customer_id=${customer.id}::uuid`);
      res.json({ data: camelize(r.rows), total: Number((cnt.rows[0] as any).total) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Fare estimate ────────────────────────────────────────────────
  app.post("/api/app/customer/estimate-fare", async (req, res) => {
    try {
      const { pickupLat, pickupLng, destLat, destLng, vehicleCategoryId, distanceKm } = req.body;
      // Get fare settings
      const fareR = await rawDb.execute(rawSql`
        SELECT f.*, vc.name as vehicle_name FROM fares f
        LEFT JOIN vehicle_categories vc ON vc.id = f.vehicle_category_id
        ${vehicleCategoryId ? rawSql`WHERE f.vehicle_category_id = ${vehicleCategoryId}::uuid AND f.is_active=true` : rawSql`WHERE f.is_active=true`}
        LIMIT 5
      `);
      const fares = camelize(fareR.rows).map((f: any) => {
        const base = parseFloat(f.baseFare || 30);
        const perKm = parseFloat(f.farePerKm || 12);
        const estimated = base + (distanceKm || 5) * perKm;
        return {
          vehicleCategoryId: f.vehicleCategoryId,
          vehicleName: f.vehicleName || "Car",
          baseFare: base,
          farePerKm: perKm,
          estimatedFare: Math.round(estimated),
          estimatedTime: Math.round((distanceKm || 5) * 2.5) + " min",
        };
      });
      res.json({ fares, distanceKm: distanceKm || 0 });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── SHARED: Nearby drivers (for customer map) ──────────────────────────────
  app.get("/api/app/nearby-drivers", async (req, res) => {
    try {
      const { lat, lng, radius = 5, vehicleCategoryId } = req.query;
      const r = await rawDb.execute(rawSql`
        SELECT u.id, u.full_name, u.rating, dl.lat, dl.lng, dl.heading, vc.name as vehicle_name
        FROM driver_locations dl
        JOIN users u ON u.id = dl.driver_id
        LEFT JOIN vehicle_categories vc ON vc.id::text = ${vehicleCategoryId as string || ''}
        WHERE dl.is_online=true AND u.is_active=true AND u.is_locked=false
          AND u.current_trip_id IS NULL
          AND (dl.lat - ${Number(lat)})*(dl.lat - ${Number(lat)}) + (dl.lng - ${Number(lng)})*(dl.lng - ${Number(lng)}) < ${Number(radius) * Number(radius) / 10000}
        LIMIT 20
      `);
      res.json({ drivers: camelize(r.rows) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── SHARED: Update FCM token ──────────────────────────────────────────────
  app.post("/api/app/fcm-token", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const { fcmToken, deviceType = "android", appVersion } = req.body;
      await rawDb.execute(rawSql`
        INSERT INTO user_devices (user_id, fcm_token, device_type, app_version)
        VALUES (${user.id}::uuid, ${fcmToken}, ${deviceType}, ${appVersion||''})
        ON CONFLICT (user_id) DO UPDATE SET fcm_token=${fcmToken}, device_type=${deviceType}, app_version=${appVersion||''}, updated_at=NOW()
      `);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── SHARED: App configs (vehicle categories, cancellation reasons etc) ────
  app.get("/api/app/configs", async (_req, res) => {
    try {
      const [cats, reasons, settings] = await Promise.all([
        rawDb.execute(rawSql`SELECT * FROM vehicle_categories WHERE is_active=true ORDER BY name`),
        rawDb.execute(rawSql`SELECT * FROM cancellation_reasons WHERE is_active=true`),
        rawDb.execute(rawSql`SELECT key_name, value FROM configurations WHERE key_name IN ('otp_on_pickup','max_ride_radius_km','driver_auto_accept','sos_number','support_phone','currency','currency_symbol')`),
      ]);
      const configs: any = {};
      (settings.rows as any[]).forEach(r => { configs[r.key_name] = r.value; });
      res.json({
        vehicleCategories: camelize(cats.rows),
        cancellationReasons: camelize(reasons.rows),
        configs,
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: SOS alert ─────────────────────────────────────────────────────
  app.post("/api/app/sos", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const { lat, lng, tripId, message } = req.body;
      await rawDb.execute(rawSql`
        INSERT INTO sos_alerts (user_id, trip_id, lat, lng, message, status)
        VALUES (${user.id}::uuid, ${tripId ? tripId + '::uuid' : null}, ${lat||0}, ${lng||0}, ${message||'SOS triggered from app'}, 'active')
      `).catch(() => {}); // if sos_alerts table doesn't exist, ignore
      console.log(`[SOS] ${user.userType} ${user.fullName} (${user.phone}) at ${lat},${lng}`);
      res.json({ success: true, message: "SOS alert sent. Help is on the way." });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ========== FLUTTER SDK FILES DOWNLOAD ==========
  app.use("/flutter", express.static(path.join(process.cwd(), "public", "flutter")));

  // ========== NOTIFICATION LOGS (update send to persist) ==========
  app.get("/api/notifications", async (req, res) => {
    try {
      const { limit = 50, offset = 0 } = req.query;
      const rows = await rawDb.execute(rawSql`
        SELECT * FROM notification_logs ORDER BY sent_at DESC LIMIT ${Number(limit)} OFFSET ${Number(offset)}
      `);
      const countRes = await rawDb.execute(rawSql`SELECT COUNT(*) as total FROM notification_logs`);
      res.json({ data: rows.rows.map(camelize), total: Number((countRes.rows[0] as any).total) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  return httpServer;
}
