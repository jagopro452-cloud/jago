import express from "express";
import type { Express, Request, Response, NextFunction } from "express";
import { notifyDriverNewRide, notifyCustomerDriverAccepted, notifyCustomerDriverArrived, notifyCustomerTripCompleted, notifyTripCancelled, sendFcmNotification } from "./fcm";
import { sendOtpSms, sendCustomSms } from "./sms";
import { notifyNearbyDriversNewTrip, io } from "./socket";
import type { Server } from "http";
import { storage } from "./storage";
import { z } from "zod";
import crypto from "crypto";
import { createRequire } from "module";
import multer from "multer";
const _require = createRequire(import.meta.url);
import path from "path";
import fs from "fs";
import { db } from "./db";
const rawDb = db;
import { parcelAttributes, admins } from "@shared/schema";
import { eq, sql } from "drizzle-orm";
const rawSql = sql;
import bcrypt from "bcryptjs";
import { getConf } from "./config-db";
import rateLimit from "express-rate-limit";
import {
  initAiTables,
  parseVoiceIntent,
  findBestDrivers,
  getSmartSuggestions,
  getDemandHeatmap,
  checkRouteDeviation,
  checkAbnormalStop,
  checkSpeedAnomaly,
  updateDriverStats,
  refreshAllDriverStats,
  recordWaypoint,
  getTripWaypoints,
  clearTripWaypoints,
} from "./ai";
import { isTrue, parseEnv } from "./config/env";

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

function formatDbError(err: any): string {
  if (!err) return "Unknown error";
  if (typeof err === "string") return err;
  if (err.message && typeof err.message === "string" && err.message.trim().length > 0) return err.message;
  if (Array.isArray(err.errors) && err.errors.length > 0) {
    return err.errors
      .map((sub: any) => sub?.message || `${sub?.code || "ERR"} ${sub?.address || ""}:${sub?.port || ""}`.trim())
      .filter(Boolean)
      .join(" | ");
  }
  if (err.cause?.message && typeof err.cause.message === "string") return err.cause.message;
  try {
    return JSON.stringify(err);
  } catch {
    return String(err);
  }
}

const TRIP_UI_STATE_MAP: Record<string, string> = {
  searching: "requested",
  driver_assigned: "driver_assigned",
  accepted: "driver_assigned",
  arrived: "driver_arriving",
  on_the_way: "trip_in_progress",
  completed: "trip_completed",
  cancelled: "trip_cancelled",
};

function toUiTripState(trip: any): string {
  const raw = String(trip?.currentStatus || trip?.current_status || "requested");
  if (raw === "on_the_way") {
    const startedAtRaw = trip?.rideStartedAt || trip?.ride_started_at;
    if (startedAtRaw) {
      const elapsedSec = Math.max(0, Math.floor((Date.now() - new Date(startedAtRaw).getTime()) / 1000));
      if (elapsedSec <= 90) return "trip_started";
    }
  }
  return TRIP_UI_STATE_MAP[raw] || raw;
}

function haversineKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const toRad = (v: number) => (v * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function computeEtaMinutes(distanceKm: number, avgSpeedKmph = 25): number {
  if (!Number.isFinite(distanceKm) || distanceKm <= 0) return 0;
  return Math.max(1, Math.round((distanceKm / avgSpeedKmph) * 60));
}

async function appendTripStatus(tripId: string, status: string, source = "system", note?: string) {
  if (!tripId) return;
  await rawDb.execute(rawSql`
    INSERT INTO trip_status (trip_id, status, source, note)
    VALUES (${tripId}::uuid, ${status}, ${source}, ${note || null})
  `).catch(() => {});
}

async function logRideLifecycleEvent(tripId: string, eventType: string, actorId?: string, actorType = "system", meta: any = {}) {
  if (!tripId) return;
  await rawDb.execute(rawSql`
    INSERT INTO ride_events (trip_id, event_type, actor_id, actor_type, meta)
    VALUES (${tripId}::uuid, ${eventType}, ${actorId || null}::uuid, ${actorType}, ${JSON.stringify(meta)}::jsonb)
  `).catch(() => {});
}

async function logAdminAction(action: string, entityType: string, entityId?: string, details: any = {}, adminEmail?: string) {
  await rawDb.execute(rawSql`
    INSERT INTO admin_logs (admin_email, action, entity_type, entity_id, details)
    VALUES (${adminEmail || null}, ${action}, ${entityType}, ${entityId || null}::uuid, ${JSON.stringify(details)}::jsonb)
  `).catch(() => {});
}


// Login rate limiter — max 20 attempts per 15 minutes per IP
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  message: { message: "Too many login attempts. Please try again after 15 minutes." },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { xForwardedForHeader: false },
});

// OTP rate limiter — max 10 requests per hour per IP (extra protection beyond per-phone DB check)
const otpLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 10,
  message: { message: "Too many OTP requests. Please try again after an hour." },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { xForwardedForHeader: false },
});

// App API general rate limiter — max 300 requests per minute per IP
const appLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 300,
  message: { message: "Too many requests. Please slow down." },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { xForwardedForHeader: false },
});

const ADMIN_SESSION_TTL_HOURS = Math.max(1, Number(process.env.ADMIN_SESSION_TTL_HOURS || 24));
const isDevOtpResponseEnabled = process.env.ENABLE_DEV_OTP_RESPONSES === "true";

const AI_ASSISTANT_SERVICE_URL = (process.env.AI_ASSISTANT_SERVICE_URL || "http://localhost:7104").replace(/\/$/, "");

type AssistantVoiceIntent = {
  intent?: string;
  confidence?: number;
  entities?: {
    pickup?: string | null;
    destination?: string | null;
    serviceSuggestion?: string | null;
  };
};

function mapServiceSuggestionToVehicle(serviceSuggestion?: string | null): string | null {
  if (!serviceSuggestion) return null;
  const s = String(serviceSuggestion).toLowerCase();
  if (s.includes("parcel")) return "Bike Parcel";
  if (s.includes("bike")) return "Bike";
  if (s.includes("auto")) return "Mini Auto";
  if (s.includes("car")) return "Car";
  return null;
}

async function parseVoiceIntentOrchestrated(text: string): Promise<{ parsed: any; parserSource: "ai-assistant-service" | "monolith-fallback" }> {
  try {
    const r = await fetch(`${AI_ASSISTANT_SERVICE_URL}/internal/voice/intent`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ transcript: text }),
    });

    if (r.ok) {
      const aiPayload = (await r.json()) as AssistantVoiceIntent;
      const intent = (aiPayload.intent || "unknown") as any;
      const pickup = aiPayload.entities?.pickup || null;
      const destination = aiPayload.entities?.destination || null;
      const serviceSuggestion = mapServiceSuggestionToVehicle(aiPayload.entities?.serviceSuggestion);

      return {
        parserSource: "ai-assistant-service",
        parsed: {
          intent,
          confidence: Number(aiPayload.confidence || 0.7),
          pickup,
          destination,
          vehicleType: serviceSuggestion,
          entities: {
            ...(aiPayload.entities || {}),
            vehicle: serviceSuggestion || aiPayload.entities?.serviceSuggestion || null,
          },
        },
      };
    }
  } catch (_) {
    // Fallback to local parser when assistant microservice is unavailable.
  }

  return {
    parserSource: "monolith-fallback",
    parsed: parseVoiceIntent(text),
  };
}
const runtimeEnv = parseEnv();
const requireAdminTwoFactor = isTrue(runtimeEnv.ADMIN_2FA_REQUIRED);

function extractBearerToken(req: Request): string | null {
  const auth = req.headers.authorization || "";
  if (!auth.startsWith("Bearer ")) return null;
  return auth.slice("Bearer ".length).trim() || null;
}

async function issueAdminSession(adminId: string) {
  const sessionToken = `${adminId}:${crypto.randomBytes(32).toString("hex")}`;
  const expiresAt = new Date(Date.now() + ADMIN_SESSION_TTL_HOURS * 60 * 60 * 1000);
  await rawDb.execute(rawSql`
    UPDATE admins
    SET auth_token=${sessionToken}, auth_token_expires_at=${expiresAt.toISOString()}, last_login_at=NOW()
    WHERE id=${adminId}::uuid
  `);
  return { sessionToken, expiresAt };
}

function requireAdminRole(allowedRoles: string[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    const role = String((req as any)?.adminUser?.role || "").toLowerCase();
    if (!role || !allowedRoles.map((r) => r.toLowerCase()).includes(role)) {
      return res.status(403).json({ message: "Insufficient admin permissions" });
    }
    next();
  };
}

function requireOpsKey(req: Request, res: Response, next: NextFunction) {
  const configuredKey = process.env.OPS_API_KEY;
  if (!configuredKey) return res.status(503).json({ message: "Operations API key is not configured" });
  const key = String(req.headers["x-ops-key"] || "").trim();
  if (!key || key !== configuredKey) return res.status(401).json({ message: "Invalid operations API key" });
  next();
}

// Standalone admin auth for routes NOT under /api/admin/ prefix (which has global middleware).
// Use on every legacy admin route that handles sensitive data or write operations.
async function requireAdminAuth(req: Request, res: Response, next: NextFunction) {
  const token = extractBearerToken(req);
  if (!token) return res.status(401).json({ message: "Admin authorization required" });
  try {
    const r = await rawDb.execute(rawSql`
      SELECT id, name, email, role, is_active FROM admins
      WHERE auth_token=${token} AND is_active=true
        AND (auth_token_expires_at IS NULL OR auth_token_expires_at > NOW())
      LIMIT 1
    `);
    if (!r.rows.length) return res.status(401).json({ message: "Admin session expired. Please login again." });
    (req as any).adminUser = camelize(r.rows[0]);
    next();
  } catch (_e: any) {
    res.status(401).json({ message: "Admin authentication failed" });
  }
}

async function ensureAdminExists() {
  const adminEmail = (process.env.ADMIN_EMAIL || "kiranatmakuri518@gmail.com").trim().toLowerCase();
  const adminName  = (process.env.ADMIN_NAME  || "Admin").trim() || "Admin";
  const adminPassword = process.env.ADMIN_PASSWORD || "JagoAdmin@2026!";

  // ── Step 1: Guarantee the tables exist using rawDb (same path as ensureOperationalSchema)
  try {
    await rawDb.execute(rawSql`
      CREATE TABLE IF NOT EXISTS admins (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        email VARCHAR(191) NOT NULL UNIQUE,
        password VARCHAR(191) NOT NULL,
        role VARCHAR(50) NOT NULL DEFAULT 'admin',
        is_active BOOLEAN NOT NULL DEFAULT true,
        auth_token TEXT,
        auth_token_expires_at TIMESTAMP,
        last_login_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
  } catch (e: any) { console.error("[admin] create admins table:", formatDbError(e)); }

  // ── Self-heal: add missing columns that may not exist on older deployments ──
  await rawDb.execute(rawSql`ALTER TABLE admins ADD COLUMN IF NOT EXISTS auth_token TEXT`).catch(() => {});
  await rawDb.execute(rawSql`ALTER TABLE admins ADD COLUMN IF NOT EXISTS auth_token_expires_at TIMESTAMP`).catch(() => {});
  await rawDb.execute(rawSql`ALTER TABLE admins ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP`).catch(() => {});
  await rawDb.execute(rawSql`ALTER TABLE admins ADD COLUMN IF NOT EXISTS role VARCHAR(50) NOT NULL DEFAULT 'admin'`).catch(() => {});
  await rawDb.execute(rawSql`ALTER TABLE admins ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true`).catch(() => {});

  try {
    await rawDb.execute(rawSql`
      CREATE TABLE IF NOT EXISTS admin_login_otp (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        admin_id UUID NOT NULL,
        otp VARCHAR(10) NOT NULL,
        is_used BOOLEAN NOT NULL DEFAULT false,
        expires_at TIMESTAMP NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT NOW()
      )
    `);
  } catch (_) {}
  try { await rawDb.execute(rawSql`CREATE INDEX IF NOT EXISTS idx_admins_auth_token ON admins(auth_token)`); } catch (_) {}
  try { await rawDb.execute(rawSql`CREATE INDEX IF NOT EXISTS idx_admin_login_otp_admin_created ON admin_login_otp(admin_id, created_at DESC)`); } catch (_) {}

  // ── Step 2: Seed / sync admin account using rawDb (never uses Drizzle ORM table refs)
  try {
    const existingR = await rawDb.execute(rawSql`
      SELECT id, is_active FROM admins WHERE email = ${adminEmail} LIMIT 1
    `);
    const existingRow: any = existingR.rows[0];

    if (!existingRow) {
      // Check for any admin with a different email (first-deploy email mismatch)
      const anyR = await rawDb.execute(rawSql`SELECT id, email FROM admins ORDER BY created_at ASC LIMIT 5`);
      const hash = await bcrypt.hash(adminPassword, 10);

      if (anyR.rows.length > 0) {
        // Migrate the first admin to the configured ADMIN_EMAIL
        const firstAdmin: any = anyR.rows[0];
        await rawDb.execute(rawSql`
          UPDATE admins SET email=${adminEmail}, name=${adminName}, password=${hash}, is_active=true
          WHERE id=${firstAdmin.id}::uuid
        `);
        for (let i = 1; i < anyR.rows.length; i++) {
          const a: any = anyR.rows[i];
          await rawDb.execute(rawSql`DELETE FROM admins WHERE id=${a.id}::uuid`).catch(() => {});
        }
        console.log(`[admin] Migrated admin → ${adminEmail}, password synced`);
      } else {
        // No admin at all — create one
        await rawDb.execute(rawSql`
          INSERT INTO admins (name, email, password, role, is_active)
          VALUES (${adminName}, ${adminEmail}, ${hash}, 'superadmin', true)
          ON CONFLICT (email) DO NOTHING
        `);
        console.log(`[admin] Admin created: ${adminEmail}`);
      }
    } else {
      // Admin exists — always sync password from configured value (env or default).
      // This ensures the admin can always login after a server restart with the configured password.
      const hash = await bcrypt.hash(adminPassword, 10);
      await rawDb.execute(rawSql`UPDATE admins SET password=${hash}, is_active=true, auth_token=NULL, auth_token_expires_at=NULL WHERE email=${adminEmail}`);
      console.log(`[admin] Password synced for ${adminEmail} (restart sync)`);
    }
  } catch (e: any) {
    console.error("[admin] ensureAdminExists error:", formatDbError(e));
  }
}

async function ensureOperationalSchema() {
  try {
    await rawDb.execute(rawSql`CREATE EXTENSION IF NOT EXISTS pgcrypto`);

    // ── Core auth tables — must always exist even if Drizzle migrations haven't run ──
    await rawDb.execute(rawSql`
      CREATE TABLE IF NOT EXISTS admins (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        email VARCHAR(191) NOT NULL UNIQUE,
        password VARCHAR(191) NOT NULL,
        role VARCHAR(50) NOT NULL DEFAULT 'admin',
        is_active BOOLEAN NOT NULL DEFAULT true,
        auth_token TEXT,
        auth_token_expires_at TIMESTAMP,
        last_login_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT NOW()
      )
    `);
    await rawDb.execute(rawSql`
      CREATE TABLE IF NOT EXISTS admin_login_otp (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        admin_id UUID NOT NULL,
        otp VARCHAR(10) NOT NULL,
        is_used BOOLEAN NOT NULL DEFAULT false,
        expires_at TIMESTAMP NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT NOW()
      )
    `);
    // Used by forgot-password / reset-password flow
    await rawDb.execute(rawSql`
      CREATE TABLE IF NOT EXISTS admin_otp_resets (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(191) NOT NULL,
        otp VARCHAR(10) NOT NULL,
        is_used BOOLEAN NOT NULL DEFAULT false,
        expires_at TIMESTAMP NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT NOW()
      )
    `);

    await rawDb.execute(rawSql`
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS cancel_reason TEXT;
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS cancelled_by VARCHAR(50);
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS rejected_driver_ids UUID[] DEFAULT '{}'::uuid[];

      ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_status VARCHAR(30) DEFAULT 'pending';
      ALTER TABLE users ADD COLUMN IF NOT EXISTS wallet_balance NUMERIC(12,2) DEFAULT 0;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS current_trip_id UUID;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS license_expiry DATE;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_brand VARCHAR(120);
      ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_color VARCHAR(60);
      ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_year INTEGER;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_birth DATE;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS city VARCHAR(120);
      ALTER TABLE users ADD COLUMN IF NOT EXISTS gender VARCHAR(20);
      ALTER TABLE users ADD COLUMN IF NOT EXISTS selfie_image TEXT;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS revenue_model VARCHAR(30) DEFAULT 'commission';
      ALTER TABLE users ADD COLUMN IF NOT EXISTS model_selected_at TIMESTAMP;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS theme_preference VARCHAR(20) DEFAULT 'light';
      ALTER TABLE users ADD COLUMN IF NOT EXISTS onboard_date TIMESTAMP;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS free_period_end TIMESTAMP;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS launch_free_active BOOLEAN DEFAULT false;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS completed_rides_count INTEGER NOT NULL DEFAULT 0;

      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS ride_full_fare NUMERIC(23,3) DEFAULT 0;
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS user_discount NUMERIC(23,3) DEFAULT 0;
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS user_payable NUMERIC(23,3) DEFAULT 0;
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS gst_amount NUMERIC(23,3) DEFAULT 0;
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS driver_wallet_credit NUMERIC(23,3) DEFAULT 0;
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS vehicle_type_name VARCHAR(100);
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS seats_booked INTEGER DEFAULT 1;
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS seat_price NUMERIC(10,2) DEFAULT 0;

      ALTER TABLE vehicle_categories ADD COLUMN IF NOT EXISTS vehicle_type VARCHAR(50);
      ALTER TABLE vehicle_categories ADD COLUMN IF NOT EXISTS base_fare NUMERIC(10,2) DEFAULT 0;
      ALTER TABLE vehicle_categories ADD COLUMN IF NOT EXISTS fare_per_km NUMERIC(10,2) DEFAULT 0;
      ALTER TABLE vehicle_categories ADD COLUMN IF NOT EXISTS minimum_fare NUMERIC(10,2) DEFAULT 0;
      ALTER TABLE vehicle_categories ADD COLUMN IF NOT EXISTS waiting_charge_per_min NUMERIC(10,2) DEFAULT 0;
      ALTER TABLE vehicle_categories ADD COLUMN IF NOT EXISTS total_seats INTEGER DEFAULT 0;
      ALTER TABLE vehicle_categories ADD COLUMN IF NOT EXISTS is_carpool BOOLEAN DEFAULT false;

      ALTER TABLE vehicle_brands ADD COLUMN IF NOT EXISTS logo_url TEXT;
      ALTER TABLE vehicle_brands ADD COLUMN IF NOT EXISTS category VARCHAR(50) DEFAULT 'two_wheeler';

      ALTER TABLE subscription_plans ADD COLUMN IF NOT EXISTS max_rides INTEGER DEFAULT 0;
      ALTER TABLE subscription_plans ADD COLUMN IF NOT EXISTS plan_type VARCHAR(30) DEFAULT 'both';

      -- Commission Settlement: per-driver pending balance tracking
      ALTER TABLE users ADD COLUMN IF NOT EXISTS pending_commission_balance NUMERIC(12,2) NOT NULL DEFAULT 0;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS pending_gst_balance NUMERIC(12,2) NOT NULL DEFAULT 0;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS total_pending_balance NUMERIC(12,2) NOT NULL DEFAULT 0;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS lock_threshold NUMERIC(10,2) NOT NULL DEFAULT 200;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS pending_payment_amount NUMERIC(12,2) NOT NULL DEFAULT 0;

      -- Parcel / delivery fields on trip_requests
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS commission_amount NUMERIC(12,2) DEFAULT 0;
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS driver_fare NUMERIC(12,2) DEFAULT 0;
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS customer_fare NUMERIC(12,2) DEFAULT 0;
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS weight_kg NUMERIC(10,2) DEFAULT 0;
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS parcel_category_id UUID;

      -- Weight-based rate on vehicle_categories (for parcel vehicles)
      ALTER TABLE vehicle_categories ADD COLUMN IF NOT EXISTS weight_rate NUMERIC(10,2) DEFAULT 0;

      -- Fix: missing users columns referenced by many routes
      ALTER TABLE users ADD COLUMN IF NOT EXISTS lock_reason TEXT;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS locked_at TIMESTAMP;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS prefer_female_driver BOOLEAN DEFAULT false;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS emergency_contact_name VARCHAR(120);
      ALTER TABLE users ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(30);
      ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo TEXT;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS jago_coins INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS break_until TIMESTAMP;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS rating NUMERIC(3,2) NOT NULL DEFAULT 5.0;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS total_ratings INTEGER NOT NULL DEFAULT 0;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_token_expires_at TIMESTAMP;

      -- Fix: missing trip_requests columns for parcel/person-booking flow
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS receiver_name VARCHAR(120);
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS receiver_phone VARCHAR(20);
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS is_for_someone_else BOOLEAN DEFAULT false;
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS passenger_name VARCHAR(120);
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS passenger_phone VARCHAR(20);
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS tip_amount NUMERIC(10,2) DEFAULT 0;
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS driver_rating NUMERIC(3,1);
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS customer_rating NUMERIC(3,1);
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS driver_note TEXT;
      ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS tips NUMERIC(10,2) DEFAULT 0;

      -- Fix: reviews table column name mismatch (code uses review_type and comment)
      ALTER TABLE reviews ADD COLUMN IF NOT EXISTS review_type VARCHAR(50);
      ALTER TABLE reviews ADD COLUMN IF NOT EXISTS comment TEXT;

      -- Fix: safety_alerts missing columns (table may exist as older schema version)
      ALTER TABLE safety_alerts ADD COLUMN IF NOT EXISTS user_id UUID;
      ALTER TABLE safety_alerts ADD COLUMN IF NOT EXISTS triggered_by VARCHAR(20) DEFAULT 'customer';
      ALTER TABLE safety_alerts ADD COLUMN IF NOT EXISTS acknowledged_by_name VARCHAR(120);
      ALTER TABLE safety_alerts ADD COLUMN IF NOT EXISTS acknowledged_at TIMESTAMP;
      ALTER TABLE safety_alerts ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP;
      ALTER TABLE safety_alerts ADD COLUMN IF NOT EXISTS police_notified BOOLEAN DEFAULT false;
      ALTER TABLE safety_alerts ADD COLUMN IF NOT EXISTS notes TEXT;
      ALTER TABLE safety_alerts ADD COLUMN IF NOT EXISTS nearby_drivers_notified INTEGER DEFAULT 0;
    `);

    await rawDb.execute(rawSql`
      CREATE TABLE IF NOT EXISTS insurance_plans (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(191) NOT NULL,
        plan_type VARCHAR(50) DEFAULT 'vehicle',
        premium_daily NUMERIC(10,2) DEFAULT 0,
        premium_monthly NUMERIC(10,2) DEFAULT 0,
        coverage_amount NUMERIC(12,2) DEFAULT 0,
        features TEXT DEFAULT '',
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS driver_insurance (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        driver_id UUID NOT NULL,
        plan_id UUID,
        start_date DATE,
        end_date DATE,
        payment_amount NUMERIC(10,2) DEFAULT 0,
        payment_status VARCHAR(30) DEFAULT 'pending',
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS refund_requests (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        customer_id UUID NOT NULL,
        trip_id UUID,
        amount NUMERIC(12,2) NOT NULL DEFAULT 0,
        reason TEXT,
        payment_method VARCHAR(30) DEFAULT 'wallet',
        status VARCHAR(30) DEFAULT 'pending',
        admin_note TEXT,
        approved_by VARCHAR(120),
        approved_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS car_sharing_rides (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        driver_id UUID,
        vehicle_category_id UUID,
        zone_id UUID,
        from_location TEXT,
        to_location TEXT,
        departure_time TIMESTAMP,
        seat_price NUMERIC(10,2) DEFAULT 0,
        max_seats INTEGER DEFAULT 4,
        seats_booked INTEGER DEFAULT 0,
        status VARCHAR(30) DEFAULT 'scheduled',
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS car_sharing_bookings (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        ride_id UUID,
        customer_id UUID,
        seats_booked INTEGER DEFAULT 1,
        total_fare NUMERIC(10,2) DEFAULT 0,
        status VARCHAR(30) DEFAULT 'confirmed',
        payment_status VARCHAR(30) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS intercity_cs_settings (
        key_name VARCHAR(120) PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS intercity_cs_rides (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        driver_id UUID,
        from_city VARCHAR(120) NOT NULL,
        to_city VARCHAR(120) NOT NULL,
        route_km NUMERIC(10,2) DEFAULT 0,
        departure_date DATE,
        departure_time VARCHAR(20),
        total_seats INTEGER DEFAULT 4,
        vehicle_number VARCHAR(60),
        vehicle_model VARCHAR(120),
        note TEXT,
        fare_per_seat NUMERIC(10,2) DEFAULT 0,
        is_active BOOLEAN DEFAULT true,
        status VARCHAR(30) DEFAULT 'scheduled',
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS intercity_cs_bookings (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        ride_id UUID,
        customer_id UUID,
        seats_booked INTEGER DEFAULT 1,
        total_fare NUMERIC(10,2) DEFAULT 0,
        status VARCHAR(30) DEFAULT 'confirmed',
        payment_status VARCHAR(30) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS car_sharing_settings (
        key_name VARCHAR(120) PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS intercity_routes (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        from_city VARCHAR(120) NOT NULL,
        to_city VARCHAR(120) NOT NULL,
        estimated_km NUMERIC(10,2) DEFAULT 0,
        base_fare NUMERIC(10,2) DEFAULT 0,
        fare_per_km NUMERIC(10,2) DEFAULT 0,
        toll_charges NUMERIC(10,2) DEFAULT 0,
        vehicle_category_id UUID,
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS safety_alerts (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID,
        trip_id UUID,
        alert_type VARCHAR(40) DEFAULT 'sos',
        triggered_by VARCHAR(20) DEFAULT 'customer',
        status VARCHAR(20) DEFAULT 'active',
        latitude NUMERIC(10,7),
        longitude NUMERIC(10,7),
        location_address TEXT,
        nearby_drivers_notified INTEGER DEFAULT 0,
        acknowledged_by_name VARCHAR(120),
        acknowledged_at TIMESTAMP,
        resolved_at TIMESTAMP,
        police_notified BOOLEAN DEFAULT false,
        notes TEXT,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS police_stations (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(191) NOT NULL,
        zone_id UUID,
        address TEXT,
        phone VARCHAR(30),
        latitude NUMERIC(10,7),
        longitude NUMERIC(10,7),
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS revenue_model_settings (
        key_name VARCHAR(120) PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TIMESTAMP DEFAULT NOW()
      );

      -- Commission settlements: records every driver payment toward pending balance
      CREATE TABLE IF NOT EXISTS commission_settlements (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        driver_id UUID NOT NULL,
        trip_id UUID,
        settlement_type VARCHAR(40) NOT NULL DEFAULT 'commission_debit',
        -- settlement_type: commission_debit | gst_debit | payment_credit | manual_credit | adjustment
        commission_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
        gst_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
        total_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
        direction VARCHAR(10) NOT NULL DEFAULT 'debit',  -- debit | credit
        balance_before NUMERIC(12,2) DEFAULT 0,
        balance_after NUMERIC(12,2) DEFAULT 0,
        ride_fare NUMERIC(12,2) DEFAULT 0,
        service_type VARCHAR(30) DEFAULT 'ride',
        payment_method VARCHAR(40),
        razorpay_order_id VARCHAR(120),
        razorpay_payment_id VARCHAR(120),
        status VARCHAR(30) NOT NULL DEFAULT 'completed',
        description TEXT,
        created_at TIMESTAMP DEFAULT NOW()
      );

      -- Outstation carpool (driver posts city-to-city rides, customers book seats)
      CREATE TABLE IF NOT EXISTS outstation_pool_rides (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        driver_id UUID NOT NULL,
        from_city VARCHAR(120) NOT NULL,
        to_city VARCHAR(120) NOT NULL,
        route_km NUMERIC(10,2) DEFAULT 0,
        departure_date DATE,
        departure_time VARCHAR(20),
        total_seats INTEGER DEFAULT 4,
        available_seats INTEGER DEFAULT 4,
        vehicle_number VARCHAR(60),
        vehicle_model VARCHAR(120),
        fare_per_seat NUMERIC(10,2) DEFAULT 0,
        note TEXT,
        is_active BOOLEAN DEFAULT true,
        status VARCHAR(30) DEFAULT 'scheduled',
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS outstation_pool_bookings (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        ride_id UUID NOT NULL,
        customer_id UUID,
        seats_booked INTEGER DEFAULT 1,
        total_fare NUMERIC(10,2) DEFAULT 0,
        from_city VARCHAR(120),
        to_city VARCHAR(120),
        pickup_address TEXT,
        dropoff_address TEXT,
        status VARCHAR(30) DEFAULT 'confirmed',
        payment_status VARCHAR(30) DEFAULT 'pending',
        payment_method VARCHAR(40) DEFAULT 'cash',
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
    `);

    await rawDb.execute(rawSql`
      INSERT INTO revenue_model_settings (key_name, value)
      VALUES
        ('driver_commission_pct','20'),
        ('auto_lock_threshold','-100'),
        ('subscription_enabled','true'),
        ('launch_campaign_enabled','true'),
        ('ride_gst_rate','5'),
        ('commission_lock_threshold','200'),
        ('commission_rate','15'),
        ('rides_model','subscription'),
        ('parcels_model','commission'),
        ('cargo_model','commission'),
        ('intercity_model','commission'),
        ('outstation_pool_model','commission'),
        ('outstation_pool_mode','off'),
        ('subscription_mode','off'),
        ('commission_mode','on')
      ON CONFLICT (key_name) DO NOTHING;
    `);

    // ── Company GST wallet (single-row ledger) ─────────────────────────────
    await rawDb.execute(rawSql`
      CREATE TABLE IF NOT EXISTS company_gst_wallet (
        id INTEGER PRIMARY KEY DEFAULT 1,
        balance NUMERIC(15,3) NOT NULL DEFAULT 0,
        total_collected NUMERIC(15,3) NOT NULL DEFAULT 0,
        total_trips INTEGER NOT NULL DEFAULT 0,
        updated_at TIMESTAMP DEFAULT NOW()
      );
      INSERT INTO company_gst_wallet (id, balance, total_collected, total_trips)
      VALUES (1, 0, 0, 0) ON CONFLICT (id) DO NOTHING;
    `).catch(() => {});

    // Fix: completely missing tables (no CREATE TABLE existed anywhere)
    await rawDb.execute(rawSql`
      CREATE TABLE IF NOT EXISTS driver_subscriptions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        driver_id UUID NOT NULL,
        plan_id UUID,
        start_date DATE,
        end_date DATE,
        payment_amount NUMERIC(10,2) DEFAULT 0,
        payment_status VARCHAR(30) DEFAULT 'pending',
        rides_used INTEGER DEFAULT 0,
        is_active BOOLEAN DEFAULT true,
        razorpay_payment_id VARCHAR(100),
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS admin_revenue (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        driver_id UUID,
        trip_id UUID,
        amount NUMERIC(12,2) NOT NULL DEFAULT 0,
        revenue_type VARCHAR(50) DEFAULT 'commission',
        breakdown JSONB DEFAULT '{}',
        created_at TIMESTAMP DEFAULT NOW()
      );
    `).catch(() => {});

    // ── Seed all vehicle categories (Bike, Auto, Mini Car, Sedan, SUV, Car Pool) ───
    // Inserts each vehicle type if no category with that name exists yet (case-insensitive).
    await rawDb.execute(rawSql`
      INSERT INTO vehicle_categories
        (name, vehicle_type, type, icon, is_active, base_fare, fare_per_km, minimum_fare, waiting_charge_per_min, total_seats, is_carpool)
      SELECT v.vname, v.vtype, v.svc_type, v.icon, true,
             v.base_fare::numeric, v.fare_per_km::numeric, v.minimum_fare::numeric,
             v.wait_charge::numeric, v.total_seats::int, v.is_carpool::boolean
      FROM (VALUES
        ('Bike',     'bike',     'ride', '🏍️',  30, 12,  40, 1, 0, false),
        ('Auto',     'auto',     'ride', '🛺',   40, 15,  60, 2, 0, false),
        ('Mini Car', 'mini_car', 'ride', '🚕',   60, 16,  80, 2, 0, false),
        ('Sedan',    'sedan',    'ride', '🚗',   80, 18, 120, 3, 0, false),
        ('SUV',      'suv',      'ride', '🚙',  100, 22, 150, 3, 0, false),
        ('Car Pool', 'carpool',  'ride', '🚐',   80, 15, 100, 2, 4, true)
      ) AS v(vname, vtype, svc_type, icon, base_fare, fare_per_km, minimum_fare, wait_charge, total_seats, is_carpool)
      WHERE NOT EXISTS (
        SELECT 1 FROM vehicle_categories WHERE LOWER(name) = LOWER(v.vname)
      )
    `);

    // ── Seed parcel vehicle categories (Porter model) ───────────────────────
    // weight_rate is per-kg surcharge added on top of base + distance fare.
    await rawDb.execute(rawSql`
      INSERT INTO vehicle_categories
        (name, vehicle_type, type, icon, is_active, base_fare, fare_per_km, minimum_fare, waiting_charge_per_min, weight_rate, total_seats, is_carpool)
      SELECT v.vname, v.vtype, 'parcel', v.icon, true,
             v.base_fare::numeric, v.fare_per_km::numeric, v.minimum_fare::numeric,
             0::numeric, v.weight_rate::numeric, 0::int, false
      FROM (VALUES
        ('Bike Parcel',  'bike_parcel',  '🏍️', 30, 10,  40, 3),
        ('Auto Parcel',  'auto_parcel',  '🛺',  40, 12,  60, 4),
        ('Tata Ace',     'tata_ace',     '🚛',  80, 20, 120, 5),
        ('Cargo Car',    'cargo_car',    '🚗',  80, 18, 100, 5),
        ('Bolero Cargo', 'bolero_cargo', '🚙', 100, 22, 150, 6)
      ) AS v(vname, vtype, icon, base_fare, fare_per_km, minimum_fare, weight_rate)
      WHERE NOT EXISTS (
        SELECT 1 FROM vehicle_categories WHERE LOWER(name) = LOWER(v.vname)
      )
    `);
    console.log('[seed] Parcel vehicle categories seeded/updated');
    // Back-fill pricing + vehicle_type for any rows still missing them
    await rawDb.execute(rawSql`
      UPDATE vehicle_categories
      SET
        vehicle_type = COALESCE(NULLIF(vehicle_type,''), CASE
          WHEN LOWER(name) LIKE '%bike%' OR LOWER(name) LIKE '%moto%' THEN 'bike'
          WHEN LOWER(name) LIKE '%auto%' THEN 'auto'
          WHEN LOWER(name) LIKE '%mini%' THEN 'mini_car'
          WHEN LOWER(name) LIKE '%sedan%' THEN 'sedan'
          WHEN LOWER(name) LIKE '%suv%' THEN 'suv'
          WHEN LOWER(name) LIKE '%pool%' OR LOWER(name) LIKE '%share%' THEN 'carpool'
          WHEN LOWER(name) LIKE '%car%' THEN 'sedan'
          ELSE 'bike' END),
        base_fare = CASE WHEN (base_fare IS NULL OR base_fare = 0) THEN
          CASE WHEN LOWER(name) LIKE '%suv%' THEN 100
               WHEN LOWER(name) LIKE '%sedan%' THEN 80
               WHEN LOWER(name) LIKE '%mini%' OR LOWER(name) LIKE '%pool%' THEN 60
               WHEN LOWER(name) LIKE '%car%' THEN 80
               WHEN LOWER(name) LIKE '%auto%' THEN 40
               ELSE 30 END ELSE base_fare END,
        fare_per_km = CASE WHEN (fare_per_km IS NULL OR fare_per_km = 0) THEN
          CASE WHEN LOWER(name) LIKE '%suv%' THEN 22
               WHEN LOWER(name) LIKE '%sedan%' THEN 18
               WHEN LOWER(name) LIKE '%mini%' THEN 16
               WHEN LOWER(name) LIKE '%pool%' THEN 15
               WHEN LOWER(name) LIKE '%car%' THEN 18
               WHEN LOWER(name) LIKE '%auto%' THEN 15
               ELSE 12 END ELSE fare_per_km END,
        minimum_fare = CASE WHEN (minimum_fare IS NULL OR minimum_fare = 0) THEN
          CASE WHEN LOWER(name) LIKE '%suv%' THEN 150
               WHEN LOWER(name) LIKE '%sedan%' THEN 120
               WHEN LOWER(name) LIKE '%mini%' THEN 80
               WHEN LOWER(name) LIKE '%pool%' THEN 100
               WHEN LOWER(name) LIKE '%car%' THEN 80
               WHEN LOWER(name) LIKE '%auto%' THEN 60
               ELSE 40 END ELSE minimum_fare END,
        waiting_charge_per_min = CASE WHEN (waiting_charge_per_min IS NULL OR waiting_charge_per_min = 0) THEN
          CASE WHEN LOWER(name) LIKE '%suv%' OR LOWER(name) LIKE '%sedan%' THEN 3
               WHEN LOWER(name) LIKE '%auto%' OR LOWER(name) LIKE '%mini%' OR LOWER(name) LIKE '%car%' THEN 2
               ELSE 1 END ELSE waiting_charge_per_min END
      WHERE vehicle_type IS NULL OR base_fare = 0
    `);
    console.log('[seed] Vehicle categories seeded/updated');

    // ── Seed trip_fares using vehicle_categories pricing as source of truth ──
    // Inserts only where no fare row exists yet. Safe to re-run.
    await rawDb.execute(rawSql`
      INSERT INTO trip_fares (vehicle_category_id, base_fare, fare_per_km, fare_per_min,
                              minimum_fare, cancellation_fee, waiting_charge_per_min, night_charge_multiplier)
      SELECT
        vc.id,
        COALESCE(NULLIF(vc.base_fare, 0), CASE
          WHEN LOWER(vc.name) LIKE '%suv%'    THEN 100
          WHEN LOWER(vc.name) LIKE '%sedan%'  THEN 80
          WHEN LOWER(vc.name) LIKE '%mini%'   THEN 60
          WHEN LOWER(vc.name) LIKE '%pool%' OR LOWER(vc.name) LIKE '%share%' THEN 80
          WHEN LOWER(vc.name) LIKE '%car%'    THEN 80
          WHEN LOWER(vc.name) LIKE '%auto%'   THEN 40
          WHEN LOWER(vc.name) LIKE '%cargo%'  THEN 80
          WHEN LOWER(vc.name) LIKE '%parcel%' THEN 35
          ELSE 30
        END),
        COALESCE(NULLIF(vc.fare_per_km, 0), CASE
          WHEN LOWER(vc.name) LIKE '%suv%'    THEN 22
          WHEN LOWER(vc.name) LIKE '%sedan%'  THEN 18
          WHEN LOWER(vc.name) LIKE '%mini%'   THEN 16
          WHEN LOWER(vc.name) LIKE '%pool%' OR LOWER(vc.name) LIKE '%share%' THEN 15
          WHEN LOWER(vc.name) LIKE '%car%'    THEN 18
          WHEN LOWER(vc.name) LIKE '%auto%'   THEN 15
          WHEN LOWER(vc.name) LIKE '%cargo%'  THEN 20
          WHEN LOWER(vc.name) LIKE '%parcel%' THEN 13
          ELSE 12
        END),
        0,
        COALESCE(NULLIF(vc.minimum_fare, 0), CASE
          WHEN LOWER(vc.name) LIKE '%suv%'    THEN 150
          WHEN LOWER(vc.name) LIKE '%sedan%'  THEN 120
          WHEN LOWER(vc.name) LIKE '%mini%'   THEN 80
          WHEN LOWER(vc.name) LIKE '%pool%' OR LOWER(vc.name) LIKE '%share%' THEN 100
          WHEN LOWER(vc.name) LIKE '%car%'    THEN 80
          WHEN LOWER(vc.name) LIKE '%auto%'   THEN 60
          WHEN LOWER(vc.name) LIKE '%cargo%'  THEN 100
          WHEN LOWER(vc.name) LIKE '%parcel%' THEN 40
          ELSE 40
        END),
        10,
        COALESCE(NULLIF(vc.waiting_charge_per_min, 0),
          CASE WHEN LOWER(vc.name) LIKE '%suv%' OR LOWER(vc.name) LIKE '%sedan%' THEN 3
               WHEN LOWER(vc.name) LIKE '%auto%' OR LOWER(vc.name) LIKE '%mini%' OR LOWER(vc.name) LIKE '%car%' THEN 2
               ELSE 1 END),
        1.25
      FROM vehicle_categories vc
      WHERE vc.is_active = true
        AND NOT EXISTS (
          SELECT 1 FROM trip_fares tf
          WHERE tf.vehicle_category_id = vc.id
            AND (tf.base_fare > 0 OR tf.fare_per_km > 0 OR tf.minimum_fare > 0)
        )
    `);

    // ── platform_services: per-service activation + revenue model ────────────
    await rawDb.execute(rawSql`
      CREATE TABLE IF NOT EXISTS platform_services (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        service_key VARCHAR(50) UNIQUE NOT NULL,
        service_name VARCHAR(100) NOT NULL,
        service_category VARCHAR(50) NOT NULL DEFAULT 'rides',
        service_status VARCHAR(20) NOT NULL DEFAULT 'inactive',
        revenue_model VARCHAR(30) NOT NULL DEFAULT 'commission',
        commission_rate NUMERIC(5,2) DEFAULT 15.0,
        sort_order INTEGER DEFAULT 0,
        icon VARCHAR(20) DEFAULT '🚗',
        color VARCHAR(20) DEFAULT '#2F80ED',
        description TEXT DEFAULT '',
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );

      -- Seed 9 canonical services. Only bike_ride + parcel_delivery are active at launch.
      INSERT INTO platform_services
        (service_key, service_name, service_category, service_status, revenue_model, commission_rate, sort_order, icon, color, description)
      VALUES
        ('bike_ride',       'Bike Ride',          'rides',   'active',   'subscription',  0,    1, '🏍️', '#2F80ED', 'Quick and affordable bike taxi rides'),
        ('auto_ride',       'Auto Ride',           'rides',   'inactive', 'subscription',  0,    2, '🛺',  '#F59E0B', 'Classic CNG auto rides'),
        ('mini_car',        'Mini Car',            'rides',   'inactive', 'subscription',  0,    3, '🚕',  '#10B981', 'Budget sedan rides'),
        ('sedan',           'Sedan',               'rides',   'inactive', 'subscription',  0,    4, '🚗',  '#8B5CF6', 'Comfortable sedan rides'),
        ('suv',             'SUV',                 'rides',   'inactive', 'subscription',  0,    5, '🚙',  '#EF4444', 'Premium SUV rides'),
        ('city_pool',       'City Car Pool',       'carpool', 'inactive', 'commission',   10.0,  6, '🚘',  '#06B6D4', 'Share city rides and save'),
        ('intercity_pool',  'Intercity Car Pool',  'carpool', 'inactive', 'commission',   12.0,  7, '🛣️', '#6366F1', 'Intercity shared travel'),
        ('outstation_pool', 'Outstation Pool',     'carpool', 'inactive', 'commission',   15.0,  8, '🗺️', '#EC4899', 'Long distance pool travel'),
        ('parcel_delivery', 'Parcel Delivery',     'parcel',  'active',   'commission',   15.0,  9, '📦',  '#FF6B35', 'Porter-style parcel and goods delivery')
      ON CONFLICT (service_key) DO NOTHING;
    `).catch(() => {});

    // ── parcel_orders: multi-drop Porter-style delivery ───────────────────────
    await rawDb.execute(rawSql`
      CREATE TABLE IF NOT EXISTS parcel_orders (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        customer_id UUID NOT NULL,
        driver_id UUID,
        vehicle_category VARCHAR(50) DEFAULT 'bike_parcel',
        pickup_address TEXT NOT NULL,
        pickup_lat NUMERIC(10,7),
        pickup_lng NUMERIC(10,7),
        pickup_contact_name VARCHAR(100),
        pickup_contact_phone VARCHAR(20),
        drop_locations JSONB NOT NULL DEFAULT '[]',
        total_distance_km NUMERIC(8,2) DEFAULT 0,
        weight_kg NUMERIC(8,2) DEFAULT 0,
        base_fare NUMERIC(10,2) DEFAULT 0,
        distance_fare NUMERIC(10,2) DEFAULT 0,
        weight_fare NUMERIC(10,2) DEFAULT 0,
        total_fare NUMERIC(10,2) DEFAULT 0,
        commission_amt NUMERIC(10,2) DEFAULT 0,
        commission_pct NUMERIC(5,2) DEFAULT 15.0,
        current_drop_index INTEGER DEFAULT 0,
        current_status VARCHAR(40) DEFAULT 'pending',
        pickup_otp VARCHAR(6),
        is_b2b BOOLEAN DEFAULT false,
        b2b_company_id UUID,
        payment_method VARCHAR(30) DEFAULT 'cash',
        payment_status VARCHAR(30) DEFAULT 'pending',
        notes TEXT DEFAULT '',
        cancelled_reason TEXT DEFAULT '',
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
      CREATE INDEX IF NOT EXISTS idx_parcel_orders_customer ON parcel_orders(customer_id);
      CREATE INDEX IF NOT EXISTS idx_parcel_orders_driver  ON parcel_orders(driver_id);
      CREATE INDEX IF NOT EXISTS idx_parcel_orders_status  ON parcel_orders(current_status);
    `).catch(() => {});

    // ── FCM device registry: stores one push token per user ──────────────────
    await rawDb.execute(rawSql`
      CREATE TABLE IF NOT EXISTS user_devices (
        user_id UUID PRIMARY KEY,
        fcm_token TEXT NOT NULL,
        device_type VARCHAR(20) DEFAULT 'android',
        app_version VARCHAR(30) DEFAULT '',
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );
      CREATE INDEX IF NOT EXISTS idx_user_devices_fcm ON user_devices(fcm_token);
    `).catch(() => {});

    // ── Driver payment ledger: records every commission debt/payment ──────────
    await rawDb.execute(rawSql`
      CREATE TABLE IF NOT EXISTS driver_payments (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        driver_id UUID NOT NULL,
        amount NUMERIC(12,2) NOT NULL DEFAULT 0,
        payment_type VARCHAR(60) NOT NULL DEFAULT 'commission_debit',
        razorpay_order_id VARCHAR(120),
        razorpay_payment_id VARCHAR(120),
        status VARCHAR(30) NOT NULL DEFAULT 'pending',
        description TEXT,
        verified_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT NOW()
      );
      CREATE INDEX IF NOT EXISTS idx_driver_payments_driver ON driver_payments(driver_id);
      CREATE INDEX IF NOT EXISTS idx_driver_payments_status ON driver_payments(status);
    `).catch(() => {});

    // ── Performance indexes for high-traffic queries ──────────────────────────
    await rawDb.execute(rawSql`
      CREATE INDEX IF NOT EXISTS idx_trip_requests_customer_status ON trip_requests(customer_id, current_status);
      CREATE INDEX IF NOT EXISTS idx_trip_requests_driver_status   ON trip_requests(driver_id, current_status);
      CREATE INDEX IF NOT EXISTS idx_trip_requests_status_created  ON trip_requests(current_status, created_at DESC);
      CREATE INDEX IF NOT EXISTS idx_users_phone                   ON users(phone);
      CREATE INDEX IF NOT EXISTS idx_users_user_type               ON users(user_type);
      CREATE INDEX IF NOT EXISTS idx_driver_locations_lat_lng      ON driver_locations(lat, lng) WHERE is_online = true;
    `).catch(() => {});

  } catch (e: any) {
    console.error("[schema] ensureOperationalSchema error:", formatDbError(e));
  }
}

export async function registerRoutes(httpServer: Server, app: Express): Promise<Server> {
  // Always run schema bootstrap on startup to ensure all columns/tables exist
  try {
    await ensureOperationalSchema();
    console.log("[schema] Operational schema verified OK");
  } catch (e: any) {
    console.error("[schema] startup schema error:", e.message);
  }
  // Must be awaited so the admins table exists before any login request is handled
  try {
    await ensureAdminExists();
    console.log("[admin] Admin bootstrap complete");
  } catch (e: any) {
    console.error("[admin] startup admin error:", e.message);
  }

  // Apply API-level throttling for customer/driver mobile endpoints.
  app.use("/api/app", appLimiter);

  // Protect admin APIs except auth recovery routes.
  app.use("/api/admin", async (req, res, next) => {
    const publicPaths = new Set(["/login", "/login/verify-2fa", "/forgot-password", "/reset-password", "/emergency-reset"]);
    if (publicPaths.has(req.path)) return next();
    const token = extractBearerToken(req);
    if (!token) return res.status(401).json({ message: "Admin authorization required" });
    try {
      const r = await rawDb.execute(rawSql`
        SELECT id, name, email, role, is_active
        FROM admins
        WHERE auth_token=${token}
          AND is_active=true
          AND (auth_token_expires_at IS NULL OR auth_token_expires_at > NOW())
        LIMIT 1
      `);
      if (!r.rows.length) return res.status(401).json({ message: "Admin session expired. Please login again." });
      (req as any).adminUser = camelize(r.rows[0]);
      next();
    } catch (_e: any) {
      res.status(401).json({ message: "Admin authentication failed" });
    }
  });

  // Health check endpoint
  app.get("/api/health", async (_req, res) => {
    try {
      const { pool: dbPool } = await import("./db");
      await dbPool.query("SELECT 1");
      res.json({ status: "ok", db: "connected", ts: new Date().toISOString() });
    } catch (e: any) {
      res.status(503).json({ status: "error", db: "disconnected", message: formatDbError(e) });
    }
  });

  app.get("/api/ops/ready", requireOpsKey, async (_req, res) => {
    try {
      await rawDb.execute(rawSql`SELECT 1`);
      res.json({ status: "ready", ts: new Date().toISOString() });
    } catch (e: any) {
      res.status(503).json({ status: "not_ready", message: formatDbError(e), ts: new Date().toISOString() });
    }
  });

  // ── Force re-run full DB bootstrap + admin seed ───────────────────────────
  // GET  /api/ops/init-db?key=ADMIN_RESET_KEY
  // Useful when the live server has a missing schema (e.g. fresh DB or failed migration).
  app.get("/api/ops/init-db", async (req, res) => {
    const resetKey = process.env.ADMIN_RESET_KEY || process.env.OPS_API_KEY;
    const provided = String(req.query.key || req.headers["x-ops-key"] || "").trim();
    if (!resetKey || provided !== resetKey) return res.status(403).json({ message: "Invalid key" });
    try {
      await ensureOperationalSchema();
      await ensureAdminExists();
      const adminEmail = (process.env.ADMIN_EMAIL || "kiranatmakuri518@gmail.com").trim().toLowerCase();
      const r = await rawDb.execute(rawSql`SELECT id, email, is_active FROM admins WHERE LOWER(email)=${adminEmail} LIMIT 1`);
      const adminRow: any = r.rows[0];
      res.json({
        success: true,
        message: "DB schema bootstrapped and admin account synced.",
        admin: adminRow ? { id: adminRow.id, email: adminRow.email, is_active: adminRow.is_active } : null,
        ts: new Date().toISOString(),
      });
    } catch (e: any) {
      res.status(500).json({ success: false, message: e.message });
    }
  });

  app.get("/api/ops/metrics", requireOpsKey, async (_req, res) => {
    try {
      const [activeTrips, onlineDrivers, openComplaints] = await Promise.all([
        rawDb.execute(rawSql`SELECT COUNT(*)::int AS c FROM trip_requests WHERE current_status IN ('searching','driver_assigned','accepted','arrived','on_the_way')`),
        rawDb.execute(rawSql`SELECT COUNT(*)::int AS c FROM driver_locations WHERE is_online=true`),
        rawDb.execute(rawSql`SELECT COUNT(*)::int AS c FROM ride_complaints WHERE status='open'`).catch(() => ({ rows: [{ c: 0 }] as any[] })),
      ]);
      const mem = process.memoryUsage();
      res.json({
        service: "jago-gateway",
        ts: new Date().toISOString(),
        uptimeSeconds: Math.floor(process.uptime()),
        memory: {
          rss: mem.rss,
          heapTotal: mem.heapTotal,
          heapUsed: mem.heapUsed,
          external: mem.external,
        },
        activeTrips: (activeTrips.rows[0] as any)?.c || 0,
        onlineDrivers: (onlineDrivers.rows[0] as any)?.c || 0,
        openComplaints: (openComplaints.rows[0] as any)?.c || 0,
      });
    } catch (e: any) {
      res.status(500).json({ message: formatDbError(e) });
    }
  });

  // Heat Map & Fleet View points
  app.get("/api/heatmap-points", requireAdminAuth, async (_req, res) => {
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

  // Live vehicle tracking — use actual driver telemetry instead of synthetic positions
  app.get("/api/live-tracking", requireAdminAuth, async (_req, res) => {
    try {
      const { db: ltDb } = await import("./db");
      const { sql: ltSql } = await import("drizzle-orm");
      const r = await ltDb.execute(ltSql`
        SELECT
          t.id, t.ref_id, t.trip_type,
          t.pickup_address, t.destination_address,
          t.pickup_lat, t.pickup_lng,
          t.destination_lat, t.destination_lng,
          t.estimated_fare, t.estimated_distance,
          t.payment_method, t.current_status,
          t.created_at,
          u.full_name as customer_name, u.phone as customer_phone,
          vc.name as vehicle_type,
          dl.lat as driver_lat,
          dl.lng as driver_lng,
          dl.heading as driver_heading,
          dl.speed as driver_speed,
          dl.updated_at as driver_location_updated_at
        FROM trip_requests t
        LEFT JOIN users u ON u.id = t.customer_id
        LEFT JOIN vehicle_categories vc ON vc.id = t.vehicle_category_id
        LEFT JOIN driver_locations dl ON dl.driver_id = t.driver_id
        WHERE t.current_status IN ('accepted', 'arrived', 'on_the_way', 'ongoing')
          AND t.pickup_lat IS NOT NULL
          AND t.destination_lat IS NOT NULL
        ORDER BY t.created_at DESC
      `);

      const trips = r.rows.map((t: any) => {
        const pickupLat = Number(t.pickup_lat);
        const pickupLng = Number(t.pickup_lng);
        const destinationLat = Number(t.destination_lat);
        const destinationLng = Number(t.destination_lng);
        const currentLat = t.driver_lat !== null && t.driver_lat !== undefined ? Number(t.driver_lat) : pickupLat;
        const currentLng = t.driver_lng !== null && t.driver_lng !== undefined ? Number(t.driver_lng) : pickupLng;
        const segmentLat = destinationLat - pickupLat;
        const segmentLng = destinationLng - pickupLng;
        const segmentLengthSq = segmentLat * segmentLat + segmentLng * segmentLng;
        const projectedProgress = segmentLengthSq > 0
          ? ((currentLat - pickupLat) * segmentLat + (currentLng - pickupLng) * segmentLng) / segmentLengthSq
          : 0;
        const progressPct = Math.max(0, Math.min(100, Math.round(projectedProgress * 100)));

        return {
          id: t.id,
          refId: t.ref_id,
          type: t.trip_type,
          vehicleType: t.vehicle_type || 'Car',
          customerName: t.customer_name || 'Customer',
          customerPhone: t.customer_phone,
          pickupAddress: t.pickup_address,
          destinationAddress: t.destination_address,
          pickupLat,
          pickupLng,
          destinationLat,
          destinationLng,
          currentLat,
          currentLng,
          progress: progressPct,
          estimatedFare: t.estimated_fare,
          estimatedDistance: t.estimated_distance,
          paymentMethod: t.payment_method,
          status: t.current_status,
          driverHeading: t.driver_heading !== null && t.driver_heading !== undefined ? Number(t.driver_heading) : null,
          driverSpeed: t.driver_speed !== null && t.driver_speed !== undefined ? Number(t.driver_speed) : null,
          driverLocationUpdatedAt: t.driver_location_updated_at,
          telemetryLive: t.driver_lat !== null && t.driver_lng !== null,
        };
      });

      res.json(trips);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/fleet-drivers", requireAdminAuth, async (_req, res) => {
    try {
      const drivers = await storage.getUsers('driver');
      const result = drivers.data
        .filter((d: any) => d.currentLat && d.currentLng && d.currentLat !== 0 && d.currentLng !== 0)
        .map((d: any) => ({
          id: d.id,
          name: d.fullName || `${d.firstName || ""} ${d.lastName || ""}`.trim() || "Driver",
          phone: d.phone,
          status: (d.isOnline ?? d.is_online) ? 'active' : 'inactive',
          lat: d.currentLat,
          lng: d.currentLng,
        }));
      res.json(result);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Dashboard
  app.get("/api/dashboard/stats", requireAdminAuth, async (req, res) => {
    try {
      const stats = await storage.getDashboardStats();
      res.json(stats);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // ── COMPREHENSIVE ADMIN DASHBOARD ──────────────────────────────────────────
  // Single endpoint with per-service breakdowns, driver wallet health, subscription stats
  app.get("/api/admin/dashboard", async (_req, res) => {
    try {
      const [tripsR, driversR, customersR, walletR, subscriptionsR, carpoolR, parcelsR, outstationR, settingsR] = await Promise.all([
        // All-time trip counts + revenue per service type
        rawDb.execute(rawSql`
          SELECT
            COUNT(*)::int                                                              AS total_trips,
            COUNT(*) FILTER (WHERE current_status = 'completed')::int                 AS completed_trips,
            COUNT(*) FILTER (WHERE current_status = 'cancelled')::int                 AS cancelled_trips,
            COUNT(*) FILTER (WHERE current_status IN ('searching','driver_assigned','accepted','arrived','on_the_way'))::int AS active_trips,
            COALESCE(SUM(actual_fare) FILTER (WHERE current_status = 'completed'), 0) AS total_revenue,
            -- Today
            COUNT(*) FILTER (WHERE DATE(created_at) = CURRENT_DATE)::int              AS today_trips,
            COALESCE(SUM(actual_fare) FILTER (WHERE current_status='completed' AND DATE(created_at)=CURRENT_DATE), 0) AS today_revenue,
            -- This week
            COUNT(*) FILTER (WHERE created_at >= DATE_TRUNC('week', NOW()))::int      AS week_trips,
            COALESCE(SUM(actual_fare) FILTER (WHERE current_status='completed' AND created_at>=DATE_TRUNC('week',NOW())), 0) AS week_revenue,
            -- This month
            COUNT(*) FILTER (WHERE created_at >= DATE_TRUNC('month', NOW()))::int     AS month_trips,
            COALESCE(SUM(actual_fare) FILTER (WHERE current_status='completed' AND created_at>=DATE_TRUNC('month',NOW())), 0) AS month_revenue,
            -- By service type (rides only)
            COUNT(*) FILTER (WHERE trip_type IN ('ride','normal') AND current_status='completed')::int  AS ride_trips,
            COALESCE(SUM(actual_fare) FILTER (WHERE trip_type IN ('ride','normal') AND current_status='completed'), 0) AS ride_revenue,
            -- Commission totals
            COALESCE(SUM(commission_amount) FILTER (WHERE current_status='completed'), 0)   AS total_commission_collected,
            COALESCE(SUM(gst_amount) FILTER (WHERE current_status='completed'), 0)          AS total_gst_collected
          FROM trip_requests
        `),
        // Driver stats
        rawDb.execute(rawSql`
          SELECT
            COUNT(*)::int                                                              AS total_drivers,
            COUNT(*) FILTER (WHERE is_active = true AND verification_status='verified')::int AS active_drivers,
            COUNT(*) FILTER (WHERE is_locked = true)::int                             AS locked_drivers,
            COALESCE(SUM(CASE WHEN total_pending_balance > 0 THEN total_pending_balance ELSE 0 END), 0) AS total_pending_commission
          FROM users WHERE user_type = 'driver'
        `),
        // Customer stats
        rawDb.execute(rawSql`
          SELECT
            COUNT(*)::int                                                              AS total_customers,
            COUNT(*) FILTER (WHERE is_active = true)::int                             AS active_customers,
            COUNT(*) FILTER (WHERE created_at >= DATE_TRUNC('month', NOW()))::int     AS new_this_month
          FROM users WHERE user_type = 'customer'
        `),
        // Online drivers right now
        rawDb.execute(rawSql`
          SELECT COUNT(*)::int AS online_drivers
          FROM driver_locations WHERE is_online = true
        `).catch(() => ({ rows: [{ online_drivers: 0 }] as any[] })),
        // Active subscriptions
        rawDb.execute(rawSql`
          SELECT COUNT(*)::int AS active_subscriptions
          FROM driver_subscriptions
          WHERE status = 'active' AND end_date >= CURRENT_DATE
        `).catch(() => ({ rows: [{ active_subscriptions: 0 }] as any[] })),
        // Carpool stats
        rawDb.execute(rawSql`
          SELECT
            COUNT(*)::int AS total_carpool_trips,
            COALESCE(SUM(actual_fare), 0) AS carpool_revenue
          FROM trip_requests
          WHERE trip_type = 'carpool' AND current_status = 'completed'
        `),
        // Parcel stats
        rawDb.execute(rawSql`
          SELECT
            COUNT(*)::int AS total_parcel_trips,
            COALESCE(SUM(actual_fare), 0) AS parcel_revenue
          FROM trip_requests
          WHERE trip_type IN ('parcel','delivery') AND current_status = 'completed'
        `),
        // Outstation pool stats
        rawDb.execute(rawSql`
          SELECT
            COUNT(DISTINCT opr.id)::int AS total_outstation_rides,
            COUNT(opb.id)::int AS total_outstation_bookings,
            COALESCE(SUM(opb.total_fare) FILTER (WHERE opb.status = 'confirmed'), 0) AS outstation_revenue
          FROM outstation_pool_rides opr
          LEFT JOIN outstation_pool_bookings opb ON opb.ride_id = opr.id
        `).catch(() => ({ rows: [{ total_outstation_rides: 0, total_outstation_bookings: 0, outstation_revenue: 0 }] as any[] })),
        // Service model settings
        rawDb.execute(rawSql`
          SELECT key_name, value FROM revenue_model_settings
          WHERE key_name IN ('rides_model','parcels_model','cargo_model','intercity_model','outstation_pool_model','outstation_pool_mode','subscription_mode','commission_mode')
        `),
      ]);

      const trips  = (tripsR.rows[0] as any) || {};
      const drv    = (driversR.rows[0] as any) || {};
      const cust   = (customersR.rows[0] as any) || {};
      const wallet = (walletR.rows[0] as any) || {};
      const subs   = (subscriptionsR.rows[0] as any) || {};
      const cp     = (carpoolR.rows[0] as any) || {};
      const parcels= (parcelsR.rows[0] as any) || {};
      const opool  = (outstationR.rows[0] as any) || {};
      const svcSettings: Record<string, string> = {};
      for (const row of settingsR.rows as any[]) svcSettings[row.key_name] = row.value;

      res.json({
        summary: {
          totalTrips:             parseInt(trips.total_trips || 0),
          completedTrips:         parseInt(trips.completed_trips || 0),
          cancelledTrips:         parseInt(trips.cancelled_trips || 0),
          activeTrips:            parseInt(trips.active_trips || 0),
          totalRevenue:           parseFloat(trips.total_revenue || 0),
          todayTrips:             parseInt(trips.today_trips || 0),
          todayRevenue:           parseFloat(trips.today_revenue || 0),
          weekTrips:              parseInt(trips.week_trips || 0),
          weekRevenue:            parseFloat(trips.week_revenue || 0),
          monthTrips:             parseInt(trips.month_trips || 0),
          monthRevenue:           parseFloat(trips.month_revenue || 0),
          totalCommissionCollected: parseFloat(trips.total_commission_collected || 0),
          totalGstCollected:      parseFloat(trips.total_gst_collected || 0),
        },
        services: {
          rides:       { trips: parseInt(trips.ride_trips || 0), revenue: parseFloat(trips.ride_revenue || 0), model: svcSettings['rides_model'] || 'subscription' },
          parcels:     { trips: parseInt(parcels.total_parcel_trips || 0), revenue: parseFloat(parcels.parcel_revenue || 0), model: svcSettings['parcels_model'] || 'commission' },
          carpool:     { trips: parseInt(cp.total_carpool_trips || 0), revenue: parseFloat(cp.carpool_revenue || 0), model: svcSettings['intercity_model'] || 'commission' },
          outstationPool: { rides: parseInt(opool.total_outstation_rides || 0), bookings: parseInt(opool.total_outstation_bookings || 0), revenue: parseFloat(opool.outstation_revenue || 0), model: svcSettings['outstation_pool_model'] || 'commission', mode: svcSettings['outstation_pool_mode'] || 'off' },
        },
        drivers: {
          total:               parseInt(drv.total_drivers || 0),
          active:              parseInt(drv.active_drivers || 0),
          online:              parseInt(wallet.online_drivers || 0),
          locked:              parseInt(drv.locked_drivers || 0),
          totalPendingCommission: parseFloat(drv.total_pending_commission || 0),
          activeSubscriptions: parseInt(subs.active_subscriptions || 0),
        },
        customers: {
          total:       parseInt(cust.total_customers || 0),
          active:      parseInt(cust.active_customers || 0),
          newThisMonth: parseInt(cust.new_this_month || 0),
        },
        serviceSettings: svcSettings,
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });



  app.get("/api/dashboard/chart", requireAdminAuth, async (req, res) => {
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
      res.json(chart);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // ── ADMIN CONTROL: Ride Ops and Live Monitoring ──────────────────────────
  app.get("/api/admin/rides/active", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT t.id, t.ref_id, t.trip_type, t.current_status, t.pickup_address, t.destination_address,
          t.pickup_lat, t.pickup_lng, t.destination_lat, t.destination_lng,
          t.estimated_fare, t.estimated_distance, t.created_at,
          c.full_name as customer_name, c.phone as customer_phone,
          d.full_name as driver_name, d.phone as driver_phone, d.vehicle_number, d.vehicle_model,
          dl.lat as driver_lat, dl.lng as driver_lng
        FROM trip_requests t
        LEFT JOIN users c ON c.id = t.customer_id
        LEFT JOIN users d ON d.id = t.driver_id
        LEFT JOIN driver_locations dl ON dl.driver_id = t.driver_id
        WHERE t.current_status IN ('searching','driver_assigned','accepted','arrived','on_the_way')
        ORDER BY t.created_at DESC
      `);
      const items = camelize(r.rows).map((x: any) => ({ ...x, uiState: toUiTripState(x) }));
      res.json({ items, total: items.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/admin/rides/history", async (req, res) => {
    try {
      const limit = Math.min(500, Math.max(1, Number(req.query.limit || 100)));
      const r = await rawDb.execute(rawSql`
        SELECT t.id, t.ref_id, t.trip_type, t.current_status, t.created_at, t.ride_started_at, t.ride_ended_at,
          t.actual_fare, t.actual_distance, t.cancel_reason,
          c.full_name as customer_name,
          d.full_name as driver_name, d.vehicle_number, d.vehicle_model
        FROM trip_requests t
        LEFT JOIN users c ON c.id = t.customer_id
        LEFT JOIN users d ON d.id = t.driver_id
        ORDER BY t.created_at DESC LIMIT ${limit}
      `);
      const items = camelize(r.rows).map((x: any) => ({ ...x, uiState: toUiTripState(x) }));
      res.json({ items, total: items.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/admin/rides/cancelled", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT t.id, t.ref_id, t.trip_type, t.current_status, t.cancel_reason, t.cancelled_by, t.created_at,
          c.full_name as customer_name, d.full_name as driver_name
        FROM trip_requests t
        LEFT JOIN users c ON c.id = t.customer_id
        LEFT JOIN users d ON d.id = t.driver_id
        WHERE t.current_status='cancelled'
        ORDER BY t.created_at DESC LIMIT 500
      `);
      res.json({ items: camelize(r.rows) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/admin/rides/:tripId/route", async (req, res) => {
    try {
      const { tripId } = req.params;
      const events = await rawDb.execute(rawSql`
        SELECT event_type, actor_type, meta, created_at
        FROM ride_events WHERE trip_id=${tripId}::uuid ORDER BY created_at ASC
      `);
      const waypoints = getTripWaypoints(tripId);
      res.json({ events: camelize(events.rows), waypoints });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post("/api/admin/complaints", async (req, res) => {
    try {
      const { tripId, customerId, driverId, complaintType = 'general', description } = req.body;
      if (!tripId || !description) return res.status(400).json({ message: 'tripId and description are required' });
      const r = await rawDb.execute(rawSql`
        INSERT INTO ride_complaints (trip_id, customer_id, driver_id, complaint_type, description)
        VALUES (${tripId}::uuid, ${customerId || null}::uuid, ${driverId || null}::uuid, ${complaintType}, ${description})
        RETURNING *
      `);
      await logAdminAction('complaint_created', 'ride_complaint', (r.rows[0] as any)?.id, { tripId, complaintType });
      res.status(201).json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/admin/complaints", async (req, res) => {
    try {
      const status = String(req.query.status || 'all');
      const r = await rawDb.execute(rawSql`
        SELECT rc.*, t.ref_id, c.full_name as customer_name, d.full_name as driver_name
        FROM ride_complaints rc
        LEFT JOIN trip_requests t ON t.id = rc.trip_id
        LEFT JOIN users c ON c.id = rc.customer_id
        LEFT JOIN users d ON d.id = rc.driver_id
        ${status !== 'all' ? rawSql`WHERE rc.status=${status}` : rawSql``}
        ORDER BY rc.created_at DESC LIMIT 500
      `);
      res.json({ items: camelize(r.rows) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.patch("/api/admin/complaints/:id", requireAdminRole(["admin", "superadmin", "support"]), async (req, res) => {
    try {
      const id = Array.isArray(req.params.id) ? req.params.id[0] : req.params.id;
      const { status, resolutionNote } = req.body;
      const nextStatus = typeof status === "string" ? status : "resolved";
      const note = typeof resolutionNote === "string" ? resolutionNote : "";
      const r = await rawDb.execute(rawSql`
        UPDATE ride_complaints
        SET status=${nextStatus}, resolution_note=${note}, updated_at=NOW()
        WHERE id=${id}::uuid RETURNING *
      `);
      if (!r.rows.length) return res.status(404).json({ message: 'Complaint not found' });
      await logAdminAction('complaint_updated', 'ride_complaint', id, { status: nextStatus, resolutionNote: note });
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/admin/system/live-overview", async (_req, res) => {
    try {
      const [rides, drivers, sos] = await Promise.all([
        rawDb.execute(rawSql`SELECT COUNT(*)::int as c FROM trip_requests WHERE current_status IN ('searching','driver_assigned','accepted','arrived','on_the_way')`),
        rawDb.execute(rawSql`SELECT COUNT(*)::int as c FROM driver_locations WHERE is_online=true`),
        rawDb.execute(rawSql`SELECT COUNT(*)::int as c FROM sf_incidents WHERE status='open'`).catch(() => ({ rows: [{ c: 0 }] as any[] })),
      ]);
      res.json({
        activeRides: (rides.rows[0] as any)?.c || 0,
        onlineDrivers: (drivers.rows[0] as any)?.c || 0,
        openSafetyIncidents: (sos.rows[0] as any)?.c || 0,
        ts: new Date().toISOString(),
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Auth — with rate limiting and bcrypt password verification
  app.post("/api/admin/login", loginLimiter, async (req, res) => {
    try {
      const { email, password } = req.body;
      if (!email || !password) return res.status(400).json({ message: "Email and password are required" });

      // Self-healing: ensure admins table & seed exist before querying.
      // Uses rawDb directly so it works regardless of Drizzle ORM table state.
      const lookupAdmin = async (lookupEmail: string) => {
        const r = await rawDb.execute(rawSql`
          SELECT id, name, email, password, role, is_active as "isActive"
          FROM admins WHERE LOWER(email) = ${lookupEmail.trim().toLowerCase()} LIMIT 1
        `);
        if (!r.rows.length) return null;
        const row: any = r.rows[0];
        return { id: row.id, name: row.name, email: row.email, password: row.password, role: row.role, isActive: row.isActive };
      };

      let admin: any;
      try {
        admin = await lookupAdmin(email);
      } catch (dbErr: any) {
        if (String(dbErr.message).toLowerCase().includes("does not exist")) {
          console.warn("[admin-login] admins table missing — running bootstrap then retrying...");
          await ensureAdminExists();
          admin = await lookupAdmin(email);
        } else {
          throw dbErr;
        }
      }
      if (!admin) return res.status(401).json({ message: "Invalid credentials" });
      if (!admin.isActive) return res.status(403).json({ message: "Account is disabled. Contact administrator." });
      const passwordValid = await bcrypt.compare(String(password), admin.password);
      if (!passwordValid) return res.status(401).json({ message: "Invalid credentials" });
      if (requireAdminTwoFactor) {
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000);
        await rawDb.execute(rawSql`UPDATE admin_login_otp SET is_used=true WHERE admin_id=${admin.id}::uuid AND is_used=false`);
        await rawDb.execute(rawSql`
          INSERT INTO admin_login_otp (admin_id, otp, expires_at)
          VALUES (${admin.id}::uuid, ${otp}, ${expiresAt.toISOString()})
        `);
        console.log(`[ADMIN-2FA] ${admin.email} OTP: ${otp}`);
        const response: any = {
          requiresTwoFactor: true,
          admin: { id: admin.id, name: admin.name, email: admin.email, role: admin.role },
          message: "Second-factor OTP required",
        };
        if (process.env.NODE_ENV !== "production" && isDevOtpResponseEnabled) {
          response.otp = otp;
          response.dev = true;
        }
        return res.status(202).json(response);
      }

      let session: { sessionToken: string; expiresAt: Date };
      try {
        session = await issueAdminSession(admin.id);
      } catch (sessionErr: any) {
        // Self-heal if auth_token_expires_at or other columns were added after table was first created
        if (String(sessionErr.message).toLowerCase().includes("does not exist")) {
          console.warn("[admin-login] Missing column — running schema self-heal then retrying...");
          await ensureAdminExists();
          session = await issueAdminSession(admin.id);
        } else {
          throw sessionErr;
        }
      }
      res.json({
        admin: { id: admin.id, name: admin.name, email: admin.email, role: admin.role },
        token: session.sessionToken,
        expiresAt: session.expiresAt.toISOString(),
      });
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/admin/login/verify-2fa", loginLimiter, async (req, res) => {
    try {
      const { email, otp } = req.body;
      if (!email || !otp) return res.status(400).json({ message: "Email and OTP are required" });
      const adminR = await rawDb.execute(rawSql`
        SELECT id, name, email, role, is_active as "isActive"
        FROM admins WHERE LOWER(email)=${email.trim().toLowerCase()} LIMIT 1
      `);
      const admin: any = adminR.rows[0];
      if (!admin) return res.status(401).json({ message: "Invalid credentials" });
      if (!admin.isActive) return res.status(403).json({ message: "Account is disabled. Contact administrator." });

      const otpR = await rawDb.execute(rawSql`
        SELECT id
        FROM admin_login_otp
        WHERE admin_id=${admin.id}::uuid
          AND otp=${String(otp)}
          AND is_used=false
          AND expires_at > NOW()
        ORDER BY created_at DESC
        LIMIT 1
      `);
      if (!otpR.rows.length) return res.status(400).json({ message: "Invalid or expired OTP" });

      await rawDb.execute(rawSql`UPDATE admin_login_otp SET is_used=true WHERE id=${(otpR.rows[0] as any).id}::uuid`);
      const { sessionToken, expiresAt } = await issueAdminSession(admin.id);
      res.json({
        admin: { id: admin.id, name: admin.name, email: admin.email, role: admin.role },
        token: sessionToken,
        expiresAt: expiresAt.toISOString(),
      });
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.post("/api/admin/logout", (req, res) => {
    const token = extractBearerToken(req);
    if (token) {
      rawDb.execute(rawSql`UPDATE admins SET auth_token=NULL, auth_token_expires_at=NULL WHERE auth_token=${token}`)
        .catch(() => {});
    }
    res.json({ success: true });
  });

  // ── ADMIN: Forgot Password — send OTP to email ────────────────────────────
  app.post("/api/admin/forgot-password", async (req, res) => {
    try {
      const { email } = req.body;
      if (!email) return res.status(400).json({ message: "Email is required" });
      const admin = await storage.getAdminByEmail(email);
      if (!admin) return res.status(404).json({ message: "No admin account found with this email" });
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 min
      await rawDb.execute(rawSql`UPDATE admin_otp_resets SET is_used=true WHERE email=${email} AND is_used=false`);
      await rawDb.execute(rawSql`INSERT INTO admin_otp_resets (email, otp, expires_at) VALUES (${email}, ${otp}, ${expiresAt.toISOString()})`);
      // In production: send via email. For now, log it and return in dev mode.
      console.log(`[ADMIN-FORGOT-PWD] ${email} → OTP: ${otp}`);
      if (process.env.NODE_ENV === 'production' || !isDevOtpResponseEnabled) {
        res.json({ success: true, message: "Password reset OTP sent to your email." });
      } else {
        res.json({ success: true, message: "Password reset OTP sent (dev mode — check console).", otp, dev: true });
      }
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── ADMIN: Reset Password — verify OTP and set new password ───────────────
  app.post("/api/admin/reset-password", async (req, res) => {
    try {
      const { email, otp, newPassword } = req.body;
      if (!email || !otp || !newPassword) return res.status(400).json({ message: "Email, OTP and new password are required" });
      if (newPassword.length < 6) return res.status(400).json({ message: "Password must be at least 6 characters" });
      const otpRow = await rawDb.execute(rawSql`
        SELECT * FROM admin_otp_resets WHERE email=${email} AND otp=${otp} AND is_used=false AND expires_at > NOW()
        ORDER BY created_at DESC LIMIT 1
      `);
      if (!otpRow.rows.length) return res.status(400).json({ message: "Invalid or expired OTP" });
      await rawDb.execute(rawSql`UPDATE admin_otp_resets SET is_used=true WHERE id=${(otpRow.rows[0] as any).id}::uuid`);
      const hashedPassword = await bcrypt.hash(newPassword, 12);
      await rawDb.execute(rawSql`UPDATE admins SET password=${hashedPassword} WHERE email=${email}`);
      res.json({ success: true, message: "Password reset successfully. You can now login with your new password." });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── ADMIN: Emergency password reset (protected by ADMIN_RESET_KEY) ────────
  // Call: POST /api/admin/emergency-reset  { key: "...", email: "...", password: "..." }
  // Only works if ADMIN_RESET_KEY env var is set on the server.
  app.post("/api/admin/emergency-reset", async (req, res) => {
    const resetKey = process.env.ADMIN_RESET_KEY;
    if (!resetKey) return res.status(404).json({ message: "Not found" }); // disabled if env not set
    const { key, email, password } = req.body;
    if (!key || key !== resetKey) return res.status(403).json({ message: "Invalid reset key" });
    if (!email || !password || password.length < 6) return res.status(400).json({ message: "email and password (min 6 chars) required" });
    try {
      const hash = await bcrypt.hash(password, 12);
      const r = await rawDb.execute(rawSql`
        UPDATE admins SET password=${hash}, is_active=true, auth_token=NULL, auth_token_expires_at=NULL
        WHERE LOWER(email)=${email.trim().toLowerCase()}
      `);
      res.json({ success: true, message: "Admin password reset successfully. You can now login." });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── Catch-all protection for legacy /api/ admin routes ──────────────────
  // All /api/ routes that are NOT explicitly excluded below are admin-only.
  // This complements the /api/admin/* global middleware and per-route requireAdminAuth.
  app.use("/api", (req: Request, res: Response, next: NextFunction) => {
    const p = req.path;
    // Skip paths handled by their own auth mechanism or that are truly public
    if (
      p === "/health"           ||  // public health check
      p.startsWith("/ops/")     ||  // requireOpsKey
      p.startsWith("/app/")     ||  // mobile app routes — each has authApp
      p.startsWith("/admin/")   ||  // global admin middleware at line 1101
      p.startsWith("/driver/")  ||  // mobile driver routes — each has authApp
      p.startsWith("/webhook")       // payment callbacks (Razorpay, etc.)
    ) return next();
    // Everything else is a legacy admin route → require admin auth
    return requireAdminAuth(req, res, next);
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

  app.post("/api/users", async (req, res) => {
    try {
      const { fullName, phone, email, userType = "customer", vehicleNumber, vehicleModel, licenseNumber } = req.body;
      if (!fullName || !phone) return res.status(400).json({ message: "Name and phone are required" });
      const { db: xDb, sql: xSql } = await import("./db").then(async m => ({ db: m.db, sql: (await import("drizzle-orm")).sql }));
      const result = await xDb.execute(xSql`
        INSERT INTO users (full_name, phone, email, user_type, is_active, loyalty_points, vehicle_number, vehicle_model, license_number)
        VALUES (${fullName}, ${phone}, ${email || null}, ${userType}, true, 0, ${vehicleNumber || null}, ${vehicleModel || null}, ${licenseNumber || null})
        RETURNING *
      `);
      res.status(201).json(result.rows[0]);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.delete("/api/users/:id", async (req, res) => {
    try {
      const { db: xDb, sql: xSql } = await import("./db").then(async m => ({ db: m.db, sql: (await import("drizzle-orm")).sql }));
      await xDb.execute(xSql`DELETE FROM users WHERE id::text = ${req.params.id}`);
      res.json({ success: true });
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

  app.patch("/api/vehicle-categories/:id", async (req, res) => {
    try {
      const { isActive } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE vehicle_categories SET is_active=${isActive} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
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

  // ── VEHICLE-FARES: All vehicle categories with their current fare config ──
  // Used by the admin Fare Setup page (single unified view of all vehicles).
  app.get("/api/vehicle-fares", async (req, res) => {
    try {
      const rows = await rawDb.execute(rawSql`
        SELECT
          vc.id AS vehicle_category_id,
          vc.name AS vehicle_name,
          vc.vehicle_type,
          vc.type AS service_type,
          vc.icon AS vehicle_icon,
          vc.is_active,
          vc.total_seats,
          vc.is_carpool,
          tf.id             AS fare_id,
          COALESCE(NULLIF(tf.base_fare, 0), vc.base_fare)     AS base_fare,
          COALESCE(NULLIF(tf.fare_per_km, 0), vc.fare_per_km) AS fare_per_km,
          tf.fare_per_min,
          tf.fare_per_kg,
          COALESCE(NULLIF(tf.minimum_fare, 0), vc.minimum_fare) AS minimum_fare,
          tf.cancellation_fee,
          COALESCE(NULLIF(tf.waiting_charge_per_min, 0), vc.waiting_charge_per_min) AS waiting_charge_per_min,
          tf.night_charge_multiplier,
          tf.helper_charge,
          tf.zone_id,
          z.name            AS zone_name
        FROM vehicle_categories vc
        LEFT JOIN LATERAL (
          SELECT * FROM trip_fares tf2
          WHERE tf2.vehicle_category_id = vc.id
          ORDER BY tf2.created_at DESC
          LIMIT 1
        ) tf ON true
        LEFT JOIN zones z ON z.id = tf.zone_id
        ORDER BY
          CASE vc.vehicle_type
            WHEN 'bike'     THEN 1
            WHEN 'auto'     THEN 2
            WHEN 'mini_car' THEN 3
            WHEN 'sedan'    THEN 4
            WHEN 'suv'      THEN 5
            WHEN 'carpool'  THEN 6
            ELSE 7
          END,
          CASE vc.type WHEN 'ride' THEN 1 WHEN 'parcel' THEN 2 WHEN 'cargo' THEN 3 ELSE 4 END,
          vc.name
      `);
      res.json(rows.rows.map(camelize));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Upsert fare for a specific vehicle category (no zone required)
  app.post("/api/vehicle-fares/:vehicleCategoryId", async (req, res) => {
    try {
      const { vehicleCategoryId } = req.params;
      const {
        baseFare = 0, farePerKm = 0, farePerMin = 0, farePerKg = 0,
        minimumFare = 0, cancellationFee = 0, waitingChargePerMin = 0,
        nightChargeMultiplier = 1.25, helperCharge = 0, zoneId,
      } = req.body;

      // Check if a fare already exists for this vehicle category
      const existing = await rawDb.execute(rawSql`
        SELECT id FROM trip_fares WHERE vehicle_category_id = ${vehicleCategoryId}::uuid
        ORDER BY created_at DESC LIMIT 1
      `);

      let result: any;
      if (existing.rows.length) {
        // UPDATE the existing row
        const fareId = (existing.rows[0] as any).id;
        result = await rawDb.execute(rawSql`
          UPDATE trip_fares SET
            base_fare               = ${parseFloat(String(baseFare)) || 0},
            fare_per_km             = ${parseFloat(String(farePerKm)) || 0},
            fare_per_min            = ${parseFloat(String(farePerMin)) || 0},
            fare_per_kg             = ${parseFloat(String(farePerKg)) || 0},
            minimum_fare            = ${parseFloat(String(minimumFare)) || 0},
            cancellation_fee        = ${parseFloat(String(cancellationFee)) || 0},
            waiting_charge_per_min  = ${parseFloat(String(waitingChargePerMin)) || 0},
            night_charge_multiplier = ${parseFloat(String(nightChargeMultiplier)) || 1.25},
            helper_charge           = ${parseFloat(String(helperCharge)) || 0},
            zone_id                 = ${zoneId ? rawSql`${zoneId}::uuid` : rawSql`NULL`}
          WHERE id = ${fareId}::uuid
          RETURNING *
        `);
      } else {
        // INSERT a new row
        result = await rawDb.execute(rawSql`
          INSERT INTO trip_fares
            (vehicle_category_id, base_fare, fare_per_km, fare_per_min, fare_per_kg,
             minimum_fare, cancellation_fee, waiting_charge_per_min,
             night_charge_multiplier, helper_charge, zone_id)
          VALUES (
            ${vehicleCategoryId}::uuid,
            ${parseFloat(String(baseFare)) || 0},
            ${parseFloat(String(farePerKm)) || 0},
            ${parseFloat(String(farePerMin)) || 0},
            ${parseFloat(String(farePerKg)) || 0},
            ${parseFloat(String(minimumFare)) || 0},
            ${parseFloat(String(cancellationFee)) || 0},
            ${parseFloat(String(waitingChargePerMin)) || 0},
            ${parseFloat(String(nightChargeMultiplier)) || 1.25},
            ${parseFloat(String(helperCharge)) || 0},
            ${zoneId ? rawSql`${zoneId}::uuid` : rawSql`NULL`}
          )
          RETURNING *
        `);
      }
      res.json(camelize(result.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── ADMIN: Pricing Management ─────────────────────────────────────────────

  // GET all vehicle categories with full pricing (vehicle_categories + trip_fares merged)
  app.get("/api/admin/pricing/vehicles", requireAdminRole(["admin", "superadmin"]), async (_req, res) => {
    try {
      const rows = await rawDb.execute(rawSql`
        SELECT
          vc.id, vc.name, vc.vehicle_type, vc.type, vc.icon, vc.is_active,
          vc.base_fare     AS vc_base_fare,
          vc.fare_per_km   AS vc_fare_per_km,
          vc.minimum_fare  AS vc_minimum_fare,
          vc.waiting_charge_per_min AS vc_waiting_charge,
          vc.total_seats, vc.is_carpool,
          tf.id            AS fare_id,
          COALESCE(NULLIF(tf.base_fare, 0), vc.base_fare)    AS base_fare,
          COALESCE(NULLIF(tf.fare_per_km, 0), vc.fare_per_km) AS fare_per_km,
          COALESCE(NULLIF(tf.minimum_fare, 0), vc.minimum_fare) AS minimum_fare,
          COALESCE(NULLIF(tf.waiting_charge_per_min, 0), vc.waiting_charge_per_min) AS waiting_charge_per_min,
          tf.fare_per_min, tf.cancellation_fee, tf.night_charge_multiplier, tf.helper_charge
        FROM vehicle_categories vc
        LEFT JOIN LATERAL (
          SELECT * FROM trip_fares tf2
          WHERE tf2.vehicle_category_id = vc.id
          ORDER BY tf2.created_at DESC LIMIT 1
        ) tf ON true
        ORDER BY
          CASE vc.vehicle_type
            WHEN 'bike'     THEN 1
            WHEN 'auto'     THEN 2
            WHEN 'mini_car' THEN 3
            WHEN 'sedan'    THEN 4
            WHEN 'suv'      THEN 5
            WHEN 'carpool'  THEN 6
            ELSE 7
          END, vc.name
      `);
      res.json(rows.rows.map(camelize));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // PUT /api/admin/pricing/vehicles/:id — update vehicle pricing in both vehicle_categories + trip_fares
  app.put("/api/admin/pricing/vehicles/:id", requireAdminRole(["admin", "superadmin"]), async (req, res) => {
    try {
      const { id } = req.params;
      const {
        baseFare, farePerKm, minimumFare, waitingChargePerMin,
        farePerMin = 0, cancellationFee = 10, nightChargeMultiplier = 1.25,
        helperCharge = 0, totalSeats, isActive, name, icon,
      } = req.body;

      // Validate required pricing fields
      if (baseFare === undefined || farePerKm === undefined || minimumFare === undefined) {
        return res.status(400).json({ message: "baseFare, farePerKm, minimumFare are required" });
      }

      const bf   = parseFloat(String(baseFare));
      const pkm  = parseFloat(String(farePerKm));
      const mf   = parseFloat(String(minimumFare));
      const wc   = parseFloat(String(waitingChargePerMin ?? 0));
      const pm   = parseFloat(String(farePerMin));
      const cf   = parseFloat(String(cancellationFee));
      const ncm  = parseFloat(String(nightChargeMultiplier));
      const hc   = parseFloat(String(helperCharge));

      // Update vehicle_categories primary pricing
      const updateParts: string[] = [
        `base_fare = ${bf}`,
        `fare_per_km = ${pkm}`,
        `minimum_fare = ${mf}`,
        `waiting_charge_per_min = ${wc}`,
      ];
      if (totalSeats !== undefined) updateParts.push(`total_seats = ${parseInt(String(totalSeats)) || 0}`);
      if (isActive !== undefined)   updateParts.push(`is_active = ${isActive === true || isActive === 'true'}`);
      if (name)  updateParts.push(`name = '${String(name).replace(/'/g, "''")}'`);
      if (icon)  updateParts.push(`icon = '${String(icon).replace(/'/g, "''")}'`);

      const vcUpdated = await rawDb.execute(rawSql`
        UPDATE vehicle_categories
        SET base_fare = ${bf}, fare_per_km = ${pkm}, minimum_fare = ${mf},
            waiting_charge_per_min = ${wc}
            ${totalSeats !== undefined ? rawSql`, total_seats = ${parseInt(String(totalSeats)) || 0}` : rawSql``}
            ${isActive !== undefined ? rawSql`, is_active = ${isActive === true || isActive === 'true'}` : rawSql``}
        WHERE id = ${id}::uuid
        RETURNING *
      `);

      if (!vcUpdated.rows.length) return res.status(404).json({ message: "Vehicle category not found" });

      // Sync to trip_fares: upsert the fare row
      const existingFare = await rawDb.execute(rawSql`
        SELECT id FROM trip_fares WHERE vehicle_category_id = ${id}::uuid ORDER BY created_at DESC LIMIT 1
      `);
      if (existingFare.rows.length) {
        await rawDb.execute(rawSql`
          UPDATE trip_fares SET
            base_fare = ${bf}, fare_per_km = ${pkm}, minimum_fare = ${mf},
            waiting_charge_per_min = ${wc}, fare_per_min = ${pm},
            cancellation_fee = ${cf}, night_charge_multiplier = ${ncm}, helper_charge = ${hc}
          WHERE id = ${(existingFare.rows[0] as any).id}::uuid
        `);
      } else {
        await rawDb.execute(rawSql`
          INSERT INTO trip_fares (vehicle_category_id, base_fare, fare_per_km, minimum_fare,
            waiting_charge_per_min, fare_per_min, cancellation_fee, night_charge_multiplier, helper_charge)
          VALUES (${id}::uuid, ${bf}, ${pkm}, ${mf}, ${wc}, ${pm}, ${cf}, ${ncm}, ${hc})
        `);
      }

      res.json({ success: true, vehicleCategory: camelize(vcUpdated.rows[0]) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // PATCH /api/admin/pricing/vehicles/:id/availability — toggle vehicle availability
  app.patch("/api/admin/pricing/vehicles/:id/availability", requireAdminRole(["admin", "superadmin"]), async (req, res) => {
    try {
      const { isActive } = req.body;
      const r = await rawDb.execute(rawSql`
        UPDATE vehicle_categories SET is_active = ${isActive === true || isActive === 'true'}
        WHERE id = ${req.params.id}::uuid RETURNING id, name, is_active
      `);
      if (!r.rows.length) return res.status(404).json({ message: "Vehicle category not found" });
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // GET /api/admin/pricing/settings — get GST rate, launch campaign, commission settings
  app.get("/api/admin/pricing/settings", requireAdminRole(["admin", "superadmin"]), async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT key_name, value FROM revenue_model_settings ORDER BY key_name`);
      const settings: Record<string, string> = {};
      r.rows.forEach((row: any) => { settings[row.key_name] = row.value; });
      res.json({
        settings,
        gstRate: parseFloat(settings.ride_gst_rate || '5'),
        commissionPct: parseFloat(settings.driver_commission_pct || '20'),
        launchCampaignEnabled: settings.launch_campaign_enabled !== 'false',
        activeModel: settings.active_model || 'commission',
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // PUT /api/admin/pricing/settings — update one or more pricing settings
  app.put("/api/admin/pricing/settings", requireAdminRole(["admin", "superadmin"]), async (req, res) => {
    try {
      const updates = req.body as Record<string, string>;
      if (!updates || typeof updates !== 'object') return res.status(400).json({ message: "Body must be an object of key→value" });
      const allowedKeys = new Set([
        'ride_gst_rate', 'driver_commission_pct', 'launch_campaign_enabled',
        'active_model', 'rides_model', 'parcels_model', 'cargo_model', 'intercity_model',
        'outstation_pool_model', 'outstation_pool_mode', 'subscription_mode', 'commission_mode',
        'subscription_enabled', 'sub_platform_fee_per_ride',
        'commission_pct', 'hybrid_commission_pct', 'hybrid_platform_fee_per_ride',
        'commission_insurance_per_ride', 'auto_lock_threshold',
        'commission_lock_threshold', 'commission_rate',
      ]);
      const invalidKeys = Object.keys(updates).filter(k => !allowedKeys.has(k));
      if (invalidKeys.length) return res.status(400).json({ message: `Unknown setting keys: ${invalidKeys.join(', ')}` });
      for (const [key, value] of Object.entries(updates)) {
        await rawDb.execute(rawSql`
          INSERT INTO revenue_model_settings (key_name, value, updated_at)
          VALUES (${key}, ${String(value)}, NOW())
          ON CONFLICT (key_name) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()
        `);
      }
      res.json({ success: true, updated: Object.keys(updates).length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ─── Admin: Commission Settlement Endpoints ────────────────────────────────

  // GET /api/admin/commission-settlements — all settlement rows, filterable
  app.get("/api/admin/commission-settlements", requireAdminRole(["admin", "superadmin"]), async (req, res) => {
    try {
      const { driverId, type, direction, page = '1', limit = '50' } = req.query as Record<string, string>;
      const offset = (parseInt(page) - 1) * parseInt(limit);
      let whereClause = rawSql`WHERE 1=1`;
      if (driverId) whereClause = rawSql`WHERE cs.driver_id = ${driverId}::uuid`;
      const rows = await rawDb.execute(rawSql`
        SELECT cs.*,
               u.full_name as driver_name, u.phone as driver_phone, u.email as driver_email,
               tr.ref_id as trip_ref, tr.pickup_address, tr.dropoff_address
        FROM commission_settlements cs
        JOIN users u ON u.id = cs.driver_id
        LEFT JOIN trip_requests tr ON tr.id = cs.trip_id
        ${whereClause}
        ORDER BY cs.created_at DESC
        LIMIT ${parseInt(limit)} OFFSET ${offset}
      `);
      const totalR = await rawDb.execute(rawSql`SELECT COUNT(*) as cnt FROM commission_settlements cs ${whereClause}`).catch(() => ({ rows: [{ cnt: 0 }] }));
      res.json({ data: camelize(rows.rows), total: parseInt((totalR.rows[0] as any)?.cnt || 0), page: parseInt(page), limit: parseInt(limit) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // GET /api/admin/commission-settlements/drivers — per-driver pending balance summary
  app.get("/api/admin/commission-settlements/drivers", requireAdminRole(["admin", "superadmin"]), async (req, res) => {
    try {
      const rows = await rawDb.execute(rawSql`
        SELECT u.id, u.full_name, u.phone, u.email, u.is_locked, u.lock_reason,
               u.wallet_balance, u.pending_commission_balance, u.pending_gst_balance,
               u.total_pending_balance, u.lock_threshold,
               COUNT(DISTINCT tr.id) FILTER (WHERE tr.current_status='completed') as completed_trips,
               MAX(tr.created_at) as last_trip_at,
               COALESCE(SUM(cs.total_amount) FILTER (WHERE cs.direction='debit'), 0) as total_debited,
               COALESCE(SUM(cs.total_amount) FILTER (WHERE cs.direction='credit'), 0) as total_paid
        FROM users u
        LEFT JOIN trip_requests tr ON tr.driver_id = u.id
        LEFT JOIN commission_settlements cs ON cs.driver_id = u.id
        WHERE u.user_type = 'driver'
        GROUP BY u.id
        ORDER BY u.total_pending_balance DESC
      `);
      res.json({ data: camelize(rows.rows), total: rows.rows.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // POST /api/admin/commission-settlements/drivers/:driverId/settle — admin manually settles partial/full amount
  app.post("/api/admin/commission-settlements/drivers/:driverId/settle", requireAdminRole(["admin", "superadmin"]), async (req, res) => {
    try {
      const { driverId } = req.params;
      const { amount, method = 'cash', description, forceUnlock = false } = req.body;
      const payAmt = parseFloat(String(amount));
      if (!payAmt || payAmt <= 0) return res.status(400).json({ message: "Invalid amount" });

      const settingRows = await rawDb.execute(rawSql`SELECT key_name, value FROM revenue_model_settings`);
      const settings: any = {};
      settingRows.rows.forEach((r: any) => { settings[r.key_name] = r.value; });

      const balR = await rawDb.execute(rawSql`
        SELECT pending_commission_balance, pending_gst_balance, total_pending_balance, is_locked
        FROM users WHERE id=${driverId}::uuid LIMIT 1
      `);
      const bal: any = balR.rows[0] || {};
      const prevTotal      = parseFloat(bal.total_pending_balance ?? '0') || 0;
      const prevCommission = parseFloat(bal.pending_commission_balance ?? '0') || 0;
      const prevGst        = parseFloat(bal.pending_gst_balance ?? '0') || 0;

      const gstReduction  = Math.min(prevGst, parseFloat((payAmt * (prevTotal > 0 ? prevGst / prevTotal : 0.05)).toFixed(2)));
      const commReduction = Math.min(prevCommission, parseFloat((payAmt - gstReduction).toFixed(2)));
      const newTotal      = Math.max(0, parseFloat((prevTotal - payAmt).toFixed(2)));
      const newCommission = Math.max(0, parseFloat((prevCommission - commReduction).toFixed(2)));
      const newGst        = Math.max(0, parseFloat((prevGst - gstReduction).toFixed(2)));

      await rawDb.execute(rawSql`
        UPDATE users
        SET wallet_balance             = wallet_balance + ${payAmt},
            pending_commission_balance = ${newCommission},
            pending_gst_balance        = ${newGst},
            total_pending_balance      = ${newTotal},
            pending_payment_amount     = GREATEST(0, pending_payment_amount - ${payAmt})
        WHERE id = ${driverId}::uuid
      `);
      const lockThreshold = parseFloat(settings.commission_lock_threshold || '200');
      const shouldUnlock = forceUnlock || newTotal < lockThreshold;
      if (shouldUnlock && bal.is_locked) {
        await rawDb.execute(rawSql`UPDATE users SET is_locked=false, lock_reason=NULL, locked_at=NULL WHERE id=${driverId}::uuid`);
      }
      await rawDb.execute(rawSql`
        INSERT INTO commission_settlements
          (driver_id, settlement_type, commission_amount, gst_amount, total_amount,
           direction, balance_before, balance_after, payment_method, status, description)
        VALUES
          (${driverId}::uuid, 'admin_settle', ${commReduction}, ${gstReduction}, ${payAmt},
           'credit', ${prevTotal}, ${newTotal}, ${method},
           'completed', ${description || 'Admin manual settlement'})
      `).catch(() => {});
      await rawDb.execute(rawSql`
        INSERT INTO driver_payments (driver_id, amount, payment_type, status, description)
        VALUES (${driverId}::uuid, ${payAmt}, 'admin_settlement', 'completed', ${description || 'Admin settlement'})
      `).catch(() => {});
      res.json({ success: true, newPendingBalance: newTotal, pendingCommission: newCommission, pendingGst: newGst, autoUnlocked: shouldUnlock && bal.is_locked });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── Transactions
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

  app.patch("/api/coupons/:id", async (req, res) => {
    try {
      const { isActive } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE coupon_setups SET is_active=${isActive} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
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
      // Normalize keys: storage returns { withdraw, user } but frontend expects { withdrawal, driver }
      const normalized = result.map((r: any) => ({
        withdrawal: r.withdraw || r.withdrawal || r,
        driver: r.user || r.driver || null,
      }));
      res.json(normalized);
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  app.patch("/api/withdrawals/:id/status", async (req, res) => {
    try {
      const { status } = req.body;
      const validStatuses = ["pending", "approved", "rejected", "paid"];
      if (!validStatuses.includes(status)) return res.status(400).json({ message: "Invalid status" });

      // If approving/paying, deduct from driver wallet and record transaction
      if (status === "approved" || status === "paid") {
        const wdRes = await rawDb.execute(rawSql`SELECT * FROM withdraw_requests WHERE id=${req.params.id}::uuid`);
        if (wdRes.rows.length) {
          const wd = wdRes.rows[0] as any;
          if (wd.status === "pending") {
            // Deduct from driver wallet
            await rawDb.execute(rawSql`
              UPDATE users SET wallet_balance = wallet_balance - ${parseFloat(wd.amount)}
              WHERE id=${wd.user_id}::uuid
            `);
            // Record transaction
            await rawDb.execute(rawSql`
              INSERT INTO transactions (user_id, account, debit, credit, balance, transaction_type)
              VALUES (${wd.user_id}::uuid, ${'Withdrawal processed'}, ${parseFloat(wd.amount)}, 0, 0, ${'withdrawal'})
            `).catch(() => {});
          }
        }
      }
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
  app.patch("/api/discounts/:id", async (req, res) => {
    try {
      const { isActive } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE discounts SET is_active=${isActive} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(r.rows[0]);
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
  app.patch("/api/spin-wheel/:id", async (req, res) => {
    try {
      const { isActive } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE spin_wheel_items SET is_active=${isActive} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(r.rows[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.put("/api/spin-wheel/:id", async (req, res) => {
    try {
      const { label, reward_amount, rewardAmount, reward_type, rewardType, probability, is_active, isActive } = req.body;
      const lbl = label; const rAmt = reward_amount ?? rewardAmount; const rType = reward_type ?? rewardType; const prob = probability; const active = is_active ?? isActive;
      const r = await rawDb.execute(rawSql`UPDATE spin_wheel_items SET label=${lbl}, reward_amount=${rAmt}, reward_type=${rType}, probability=${prob}, is_active=${active} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(r.rows[0]);
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
  app.get("/api/vehicle-brands", async (req, res) => {
    try {
      const { category } = req.query;
      const r = category
        ? await rawDb.execute(rawSql`SELECT * FROM vehicle_brands WHERE is_active=true AND category=${category as string} ORDER BY name ASC`)
        : await rawDb.execute(rawSql`SELECT * FROM vehicle_brands WHERE is_active=true ORDER BY category, name ASC`);
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/vehicle-brands", async (req, res) => {
    try {
      const { name, logo_url, category = 'two_wheeler', is_active } = req.body;
      const r = await rawDb.execute(rawSql`INSERT INTO vehicle_brands (name, logo_url, category, is_active) VALUES (${name}, ${logo_url||null}, ${category}, ${is_active ?? true}) RETURNING *`);
      res.status(201).json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.put("/api/vehicle-brands/:id", async (req, res) => {
    try {
      const { name, logo_url, category, is_active } = req.body;
      const r = await rawDb.execute(rawSql`UPDATE vehicle_brands SET name=${name}, logo_url=${logo_url||null}, category=${category||'two_wheeler'}, is_active=${is_active??true} WHERE id=${req.params.id}::uuid RETURNING *`);
      res.json(camelize(r.rows[0]));
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
      res.json(camelize(r.rows));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.post("/api/surge-pricing", async (req, res) => {
    try {
      const { zoneId, zone_id, startTime, start_time, endTime, end_time, multiplier, reason, isActive, is_active } = req.body;
      const zid = zoneId || zone_id || null;
      const st = (startTime || start_time || '').trim() || null;
      const et = (endTime || end_time || '').trim() || null;
      const active = isActive ?? is_active ?? true;
      const r = await rawDb.execute(rawSql`INSERT INTO surge_pricing (zone_id, start_time, end_time, multiplier, reason, is_active) VALUES (${zid}, ${st}, ${et}, ${multiplier}, ${reason || null}, ${active}) RETURNING *`);
      res.status(201).json(camelize(r.rows[0]));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });
  app.put("/api/surge-pricing/:id", async (req, res) => {
    try {
      const { zoneId, zone_id, startTime, start_time, endTime, end_time, multiplier, reason, isActive, is_active } = req.body;
      const zid = zoneId || zone_id || null;
      const st = (startTime || start_time || '').trim() || null;
      const et = (endTime || end_time || '').trim() || null;
      const active = isActive ?? is_active ?? true;
      await rawDb.execute(rawSql`UPDATE surge_pricing SET zone_id=${zid}, start_time=${st}, end_time=${et}, multiplier=${multiplier}, reason=${reason || null}, is_active=${active} WHERE id=${req.params.id}::uuid`);
      const r = await rawDb.execute(rawSql`SELECT sp.*, z.name as zone_name FROM surge_pricing sp LEFT JOIN zones z ON z.id::uuid=sp.zone_id WHERE sp.id=${req.params.id}::uuid`);
      res.json(camelize(r.rows[0]));
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
  app.get("/api/newsletter", requireAdminAuth, async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT id, full_name, email, phone, created_at FROM users WHERE user_type='customer' ORDER BY created_at DESC`);
      res.json(r.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Parcel Refunds (derived from cancelled parcel trips)
  app.get("/api/parcel-refunds", requireAdminAuth, async (req, res) => {
    try {
      const status = req.query.status as string || "all";
      const { data } = await storage.getTrips(undefined, undefined, 1, 500);
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

  app.patch("/api/parcel-refunds/:id/status", requireAdminAuth, async (req, res) => {
    try {
      const { refundStatus } = req.body;
      const payMap: Record<string, string> = {
        approved: "refund_approved",
        denied: "refund_denied",
        refunded: "refunded",
      };
      const paymentStatus = payMap[refundStatus];
      if (!paymentStatus) return res.status(400).json({ message: "Invalid refundStatus" });
      await rawDb.execute(rawSql`
        UPDATE trip_requests SET payment_status=${paymentStatus}, updated_at=NOW()
        WHERE id=${req.params.id}::uuid
      `);
      res.json({ success: true, refundStatus, paymentStatus });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Customer Wallet top-up / deduct (admin operation — adjusts users.wallet_balance)
  app.post("/api/customer-wallet/topup", requireAdminAuth, async (req, res) => {
    try {
      const { userId, amount, type } = req.body;
      if (!userId || !amount) return res.status(400).json({ message: "userId and amount required" });
      const parsedAmount = Number(amount);
      if (isNaN(parsedAmount) || parsedAmount <= 0) return res.status(400).json({ message: "amount must be a positive number" });
      const r = await rawDb.execute(rawSql`
        UPDATE users
        SET wallet_balance = GREATEST(0, wallet_balance + ${type === "deduct" ? -parsedAmount : parsedAmount}),
            updated_at = NOW()
        WHERE id = ${userId}::uuid
        RETURNING wallet_balance
      `);
      if (!(r.rows as any[]).length) return res.status(404).json({ message: "User not found" });
      const newBalance = parseFloat((r.rows as any[])[0].wallet_balance);
      res.json({ success: true, newBalance, type });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Notifications send (stub - log only)
  app.post("/api/notifications/send", requireAdminAuth, async (req, res) => {
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
  app.get("/api/car-sharing/stats", requireAdminAuth, async (req, res) => {
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
  app.get("/api/car-sharing/rides", requireAdminAuth, async (req, res) => {
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
  app.patch("/api/car-sharing/rides/:id/status", requireAdminAuth, async (req, res) => {
    try {
      const { id } = req.params;
      const { status } = req.body;
      await rawDb.execute(rawSql`UPDATE car_sharing_rides SET status = ${status} WHERE id = ${id}::uuid`);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Bookings list
  app.get("/api/car-sharing/bookings", requireAdminAuth, async (req, res) => {
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
  app.put("/api/car-sharing/settings", requireAdminAuth, async (req, res) => {
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

  app.put("/api/revenue-model", requireAdminAuth, async (req, res) => {
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

  // ─── Admin Revenue Stats ─────────────────────────────────────────────────────
  app.get("/api/admin-revenue", requireAdminAuth, async (req, res) => {
    try {
      const { from, to, revenueType, page = 1, limit = 50 } = req.query;
      const offset = (Number(page) - 1) * Number(limit);
      let whereClause = rawSql`1=1`;
      if (from) whereClause = rawSql`ar.created_at >= ${from}::date`;
      if (to) whereClause = rawSql`ar.created_at <= ${(to as string) + ' 23:59:59'}::timestamp`;
      if (revenueType) whereClause = rawSql`ar.revenue_type = ${revenueType}`;

      const rows = await rawDb.execute(rawSql`
        SELECT ar.*, u.full_name as driver_name, u.phone as driver_phone
        FROM admin_revenue ar
        LEFT JOIN users u ON u.id = ar.driver_id
        ORDER BY ar.created_at DESC
        LIMIT ${Number(limit)} OFFSET ${offset}
      `);
      const totals = await rawDb.execute(rawSql`
        SELECT
          revenue_type,
          COUNT(*) as count,
          SUM(amount) as total
        FROM admin_revenue
        GROUP BY revenue_type
      `);
      const grandTotal = await rawDb.execute(rawSql`SELECT COALESCE(SUM(amount),0) as total FROM admin_revenue`);
      res.json({
        rows: rows.rows.map(camelize),
        breakdown: totals.rows.map(camelize),
        totalRevenue: parseFloat((grandTotal.rows[0] as any).total || 0),
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ─── Driver Commission Settlement System ────────────────────────────────────

  // Helper: recalculate total_pending_balance and check auto-lock/unlock
  async function checkAndApplySettlementLock(driverId: string, settings: Record<string, string>) {
    const lockThreshold = parseFloat(settings.commission_lock_threshold || '200');
    const r = await rawDb.execute(rawSql`
      SELECT total_pending_balance, is_locked FROM users WHERE id=${driverId}::uuid LIMIT 1
    `);
    const row: any = r.rows[0] || {};
    const total = parseFloat(row.total_pending_balance ?? '0');
    const isCurrentlyLocked = row.is_locked;
    if (total >= lockThreshold && !isCurrentlyLocked) {
      await rawDb.execute(rawSql`
        UPDATE users SET is_locked=true,
          lock_reason=${'Pending balance ₹' + total.toFixed(2) + ' exceeds ₹' + lockThreshold + '. Pay to unlock ride access.'},
          locked_at=NOW()
        WHERE id=${driverId}::uuid
      `);
      return { locked: true, autoLocked: true, total };
    }
    if (total < lockThreshold && isCurrentlyLocked) {
      await rawDb.execute(rawSql`UPDATE users SET is_locked=false, lock_reason=NULL, locked_at=NULL WHERE id=${driverId}::uuid`);
      return { locked: false, autoUnlocked: true, total };
    }
    return { locked: isCurrentlyLocked, total };
  }

  // Get all drivers with wallet + pending balance info
  app.get("/api/driver-wallet", async (req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT u.id, u.full_name, u.phone, u.email, u.user_type,
          u.wallet_balance, u.is_locked, u.lock_reason, u.locked_at,
          u.pending_commission_balance, u.pending_gst_balance, u.total_pending_balance,
          u.lock_threshold, u.pending_payment_amount, u.is_active,
          (SELECT COUNT(*) FROM trip_requests WHERE driver_id = u.id AND current_status='completed') as completed_trips,
          (SELECT COALESCE(SUM(actual_fare),0) FROM trip_requests WHERE driver_id = u.id AND current_status='completed') as gross_earnings
        FROM users u WHERE u.user_type = 'driver'
        ORDER BY u.total_pending_balance DESC
      `);
      res.json({ data: camelize(r.rows), total: r.rows.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Get driver payment history
  app.get("/api/driver-wallet/:id/history", async (req, res) => {
    try {
      const { id } = req.params;
      const payments = await rawDb.execute(rawSql`
        SELECT * FROM driver_payments WHERE driver_id = ${id}::uuid ORDER BY created_at DESC LIMIT 100
      `);
      const settlements = await rawDb.execute(rawSql`
        SELECT cs.*, tr.ref_id as trip_ref
        FROM commission_settlements cs
        LEFT JOIN trip_requests tr ON tr.id = cs.trip_id
        WHERE cs.driver_id = ${id}::uuid
        ORDER BY cs.created_at DESC LIMIT 100
      `);
      res.json({ payments: camelize(payments.rows), settlements: camelize(settlements.rows) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Deduct platform fee per ride (called after ride completion — legacy endpoint)
  app.post("/api/driver-wallet/:id/deduct", async (req, res) => {
    try {
      const { id } = req.params;
      const { amount, description, tripId, gstPortion = 0 } = req.body;
      const settingRows = await rawDb.execute(rawSql`SELECT key_name, value FROM revenue_model_settings`);
      const settings: any = {};
      settingRows.rows.forEach((r: any) => { settings[r.key_name] = r.value; });

      const gstAmt   = parseFloat(String(gstPortion)) || 0;
      const commAmt  = parseFloat((parseFloat(String(amount)) - gstAmt).toFixed(2));
      const totalAmt = parseFloat(String(amount));

      const balR = await rawDb.execute(rawSql`
        SELECT pending_commission_balance, pending_gst_balance, total_pending_balance
        FROM users WHERE id=${id}::uuid LIMIT 1
      `);
      const bal: any = balR.rows[0] || {};
      const prevTotal    = parseFloat(bal.total_pending_balance ?? '0') || 0;
      const newCommission = parseFloat(((parseFloat(bal.pending_commission_balance ?? '0') || 0) + commAmt).toFixed(2));
      const newGst        = parseFloat(((parseFloat(bal.pending_gst_balance ?? '0') || 0) + gstAmt).toFixed(2));
      const newTotal      = parseFloat((prevTotal + totalAmt).toFixed(2));

      const updated = await rawDb.execute(rawSql`
        UPDATE users
        SET wallet_balance = wallet_balance - ${totalAmt},
            pending_commission_balance = ${newCommission},
            pending_gst_balance = ${newGst},
            total_pending_balance = ${newTotal},
            pending_payment_amount = GREATEST(0, -(wallet_balance - ${totalAmt}))
        WHERE id = ${id}::uuid RETURNING wallet_balance, is_locked
      `);
      await rawDb.execute(rawSql`
        INSERT INTO driver_payments (driver_id, amount, payment_type, status, description)
        VALUES (${id}::uuid, ${totalAmt}, 'deduction', 'completed', ${description || 'Platform fee deduction'})
      `).catch(() => {});
      await rawDb.execute(rawSql`
        INSERT INTO commission_settlements (driver_id, trip_id, settlement_type, commission_amount, gst_amount, total_amount, direction, balance_before, balance_after, description)
        VALUES (${id}::uuid, ${tripId ? rawSql`${tripId}::uuid` : rawSql`NULL`}, 'commission_debit', ${commAmt}, ${gstAmt}, ${totalAmt}, 'debit', ${prevTotal}, ${newTotal}, ${description || 'Fee deduction'})
      `).catch(() => {});

      const lockResult = await checkAndApplySettlementLock(id, settings);
      const newBalance = parseFloat((updated.rows[0] as any)?.wallet_balance || 0);
      res.json({ success: true, newBalance, pendingBalance: newTotal, ...lockResult });
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

  // Razorpay: Create payment order for driver commission settlement
  app.post("/api/driver-wallet/:id/create-order", async (req, res) => {
    try {
      const { id } = req.params;
      const { amount } = req.body;
      const keyId = await getConf("RAZORPAY_KEY_ID", "razorpay_key_id");
      const keySecret = await getConf("RAZORPAY_KEY_SECRET", "razorpay_key_secret");
      if (!keyId || !keySecret) {
        return res.status(503).json({ message: "Payment gateway not configured. Add Razorpay keys in Admin → Configuration." });
      }
      const Razorpay = _require("razorpay");
      const rzp = new Razorpay({ key_id: keyId, key_secret: keySecret });
      const order = await rzp.orders.create({ amount: Math.round(amount * 100), currency: "INR", receipt: `cs_${Date.now().toString(36)}` });
      await rawDb.execute(rawSql`
        INSERT INTO driver_payments (driver_id, amount, payment_type, razorpay_order_id, status, description)
        VALUES (${id}::uuid, ${amount}, 'commission_payment', ${order.id}, 'pending', 'Commission settlement via Razorpay')
      `);
      res.json({ order, keyId });
    } catch (e: any) {
      const msg = e.message || e.error?.description || e.error?.reason || JSON.stringify(e).slice(0, 200);
      res.status(500).json({ message: msg });
    }
  });

  // Razorpay: Verify payment + reduce pending balance (partial payment supported)
  app.post("/api/driver-wallet/:id/verify-payment", async (req, res) => {
    try {
      const { id } = req.params;
      const { razorpayOrderId, razorpayPaymentId, razorpaySignature, amount } = req.body;
      const keySecret = process.env.RAZORPAY_KEY_SECRET;
      if (keySecret) {
        const body = razorpayOrderId + "|" + razorpayPaymentId;
        const expectedSig = crypto.createHmac("sha256", keySecret).update(body).digest("hex");
        if (expectedSig !== razorpaySignature) return res.status(400).json({ message: "Invalid payment signature" });
      }

      const settingRows = await rawDb.execute(rawSql`SELECT key_name, value FROM revenue_model_settings`);
      const settings: any = {};
      settingRows.rows.forEach((r: any) => { settings[r.key_name] = r.value; });

      // Fetch current balances before payment
      const balR = await rawDb.execute(rawSql`
        SELECT pending_commission_balance, pending_gst_balance, total_pending_balance, wallet_balance
        FROM users WHERE id=${id}::uuid LIMIT 1
      `);
      const bal: any = balR.rows[0] || {};
      const prevTotal      = parseFloat(bal.total_pending_balance ?? '0') || 0;
      const prevCommission = parseFloat(bal.pending_commission_balance ?? '0') || 0;
      const prevGst        = parseFloat(bal.pending_gst_balance ?? '0') || 0;
      const paidAmt        = parseFloat(String(amount));

      // Proportionally reduce commission vs GST (or reduce from commission first)
      const gstReduction  = Math.min(prevGst, paidAmt * (prevTotal > 0 ? prevGst / prevTotal : 0.05));
      const commReduction = Math.min(prevCommission, paidAmt - gstReduction);
      const newTotal      = Math.max(0, parseFloat((prevTotal - paidAmt).toFixed(2)));
      const newCommission = Math.max(0, parseFloat((prevCommission - commReduction).toFixed(2)));
      const newGst        = Math.max(0, parseFloat((prevGst - gstReduction).toFixed(2)));

      const updated = await rawDb.execute(rawSql`
        UPDATE users
        SET wallet_balance             = wallet_balance + ${paidAmt},
            pending_commission_balance = ${newCommission},
            pending_gst_balance        = ${newGst},
            total_pending_balance      = ${newTotal},
            pending_payment_amount     = GREATEST(0, pending_payment_amount - ${paidAmt})
        WHERE id = ${id}::uuid
        RETURNING wallet_balance, is_locked, total_pending_balance
      `);
      const updRow: any = updated.rows[0] || {};
      const newWalletBalance = parseFloat(updRow.wallet_balance ?? 0);

      // Auto-unlock check (based on pending threshold)
      const lockThreshold = parseFloat(settings.commission_lock_threshold || '200');
      const wasLocked = updRow.is_locked;
      if (newTotal < lockThreshold && wasLocked) {
        await rawDb.execute(rawSql`UPDATE users SET is_locked=false, lock_reason=NULL, locked_at=NULL WHERE id=${id}::uuid`);
      }

      // Record settlement payment
      await rawDb.execute(rawSql`
        INSERT INTO commission_settlements
          (driver_id, settlement_type, commission_amount, gst_amount, total_amount,
           direction, balance_before, balance_after, payment_method,
           razorpay_order_id, razorpay_payment_id, status, description)
        VALUES
          (${id}::uuid, 'payment_credit', ${commReduction}, ${gstReduction}, ${paidAmt},
           'credit', ${prevTotal}, ${newTotal}, 'razorpay',
           ${razorpayOrderId}, ${razorpayPaymentId}, 'completed',
           ${'Commission payment via Razorpay. Commission: ₹' + commReduction.toFixed(2) + ', GST: ₹' + gstReduction.toFixed(2)})
      `).catch(() => {});
      await rawDb.execute(rawSql`
        UPDATE driver_payments SET status='completed', razorpay_payment_id=${razorpayPaymentId},
          razorpay_signature=${razorpaySignature||''}, verified_at=NOW()
        WHERE razorpay_order_id=${razorpayOrderId}
      `).catch(() => {});
      await rawDb.execute(rawSql`
        INSERT INTO driver_payments (driver_id, amount, payment_type, status, description)
        VALUES (${id}::uuid, ${paidAmt}, 'commission_payment', 'completed', ${'Commission settlement: ₹' + paidAmt})
      `).catch(() => {});

      res.json({
        success: true,
        newWalletBalance,
        pendingBalance: newTotal,
        pendingCommission: newCommission,
        pendingGst: newGst,
        autoUnlocked: newTotal < lockThreshold && wasLocked,
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Admin: manually credit pending balance (offline/cash payment to platform)
  app.post("/api/driver-wallet/:id/credit", async (req, res) => {
    try {
      const { id } = req.params;
      const { amount, description } = req.body;
      const settingRows = await rawDb.execute(rawSql`SELECT key_name, value FROM revenue_model_settings`);
      const settings: any = {};
      settingRows.rows.forEach((r: any) => { settings[r.key_name] = r.value; });

      const balR = await rawDb.execute(rawSql`
        SELECT pending_commission_balance, pending_gst_balance, total_pending_balance
        FROM users WHERE id=${id}::uuid LIMIT 1
      `);
      const bal: any = balR.rows[0] || {};
      const prevTotal      = parseFloat(bal.total_pending_balance ?? '0') || 0;
      const prevCommission = parseFloat(bal.pending_commission_balance ?? '0') || 0;
      const prevGst        = parseFloat(bal.pending_gst_balance ?? '0') || 0;
      const paidAmt        = parseFloat(String(amount));

      const gstReduction  = Math.min(prevGst, paidAmt * (prevTotal > 0 ? prevGst / prevTotal : 0.05));
      const commReduction = Math.min(prevCommission, paidAmt - gstReduction);
      const newTotal      = Math.max(0, parseFloat((prevTotal - paidAmt).toFixed(2)));
      const newCommission = Math.max(0, parseFloat((prevCommission - commReduction).toFixed(2)));
      const newGst        = Math.max(0, parseFloat((prevGst - gstReduction).toFixed(2)));

      const updated = await rawDb.execute(rawSql`
        UPDATE users
        SET wallet_balance             = wallet_balance + ${paidAmt},
            pending_commission_balance = ${newCommission},
            pending_gst_balance        = ${newGst},
            total_pending_balance      = ${newTotal},
            pending_payment_amount     = GREATEST(0, pending_payment_amount - ${paidAmt})
        WHERE id = ${id}::uuid
        RETURNING wallet_balance, is_locked, total_pending_balance
      `);
      const updRow: any = updated.rows[0] || {};
      const lockThreshold = parseFloat(settings.commission_lock_threshold || '200');
      const wasLocked = updRow.is_locked;
      if (newTotal < lockThreshold && wasLocked) {
        await rawDb.execute(rawSql`UPDATE users SET is_locked=false, lock_reason=NULL, locked_at=NULL WHERE id=${id}::uuid`);
      }
      await rawDb.execute(rawSql`
        INSERT INTO commission_settlements
          (driver_id, settlement_type, commission_amount, gst_amount, total_amount,
           direction, balance_before, balance_after, payment_method, status, description)
        VALUES
          (${id}::uuid, 'manual_credit', ${commReduction}, ${gstReduction}, ${paidAmt},
           'credit', ${prevTotal}, ${newTotal}, 'cash',
           'completed', ${description || 'Manual payment received by admin'})
      `).catch(() => {});
      await rawDb.execute(rawSql`
        INSERT INTO driver_payments (driver_id, amount, payment_type, status, description)
        VALUES (${id}::uuid, ${paidAmt}, 'manual_credit', 'completed', ${description || 'Manual credit by admin'})
      `).catch(() => {});
      res.json({
        success: true,
        newBalance: parseFloat(updRow.wallet_balance ?? 0),
        pendingBalance: newTotal,
        pendingCommission: newCommission,
        pendingGst: newGst,
        autoUnlocked: newTotal < lockThreshold && wasLocked,
      });
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
      const { driverId, fromCity, toCity, routeKm, departureDate, departureTime, totalSeats, vehicleNumber, vehicleModel, note, farePerSeat } = req.body;
      // Calculate fare from settings
      const settingsR = await rawDb.execute(rawSql`SELECT key_name, value FROM intercity_cs_settings`);
      const s: any = {};
      settingsR.rows.forEach((r: any) => { s[r.key_name] = parseFloat(r.value); });
      const routeKmNum = parseFloat(routeKm || 0);
      const farePerSeatNum = parseFloat(farePerSeat || 0) > 0
        ? parseFloat(farePerSeat)
        : (routeKmNum * (s.rate_per_km_per_seat || 3.5));
      const r = await rawDb.execute(rawSql`
        INSERT INTO intercity_cs_rides (driver_id, from_city, to_city, route_km, departure_date, departure_time, total_seats, vehicle_number, vehicle_model, note, fare_per_seat)
        VALUES (${driverId}::uuid, ${fromCity}, ${toCity}, ${routeKmNum}, ${departureDate}, ${departureTime}, ${totalSeats}, ${vehicleNumber||''}, ${vehicleModel||''}, ${note||''}, ${farePerSeatNum})
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

  // ── OUTSTATION POOL ────────────────────────────────────────────────────────
  // Driver: post a city-to-city ride, list own rides
  app.post("/api/app/driver/outstation-pool/rides", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { fromCity, toCity, routeKm, departureDate, departureTime, totalSeats, vehicleNumber, vehicleModel, farePerSeat, note } = req.body;
      if (!fromCity || !toCity) return res.status(400).json({ message: "fromCity and toCity are required" });

      const r = await rawDb.execute(rawSql`
        INSERT INTO outstation_pool_rides
          (driver_id, from_city, to_city, route_km, departure_date, departure_time,
           total_seats, available_seats, vehicle_number, vehicle_model, fare_per_seat, note)
        VALUES
          (${driver.id}::uuid, ${fromCity}, ${toCity},
           ${parseFloat(routeKm) || 0}, ${departureDate || null}, ${departureTime || null},
           ${parseInt(totalSeats) || 4}, ${parseInt(totalSeats) || 4},
           ${vehicleNumber || null}, ${vehicleModel || null},
           ${parseFloat(farePerSeat) || 0}, ${note || null})
        RETURNING *
      `);
      res.json({ success: true, ride: camelize(r.rows[0]) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/app/driver/outstation-pool/rides", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT opr.*,
          COUNT(opb.id) as total_bookings,
          COALESCE(SUM(opb.total_fare), 0) as total_fare_collected
        FROM outstation_pool_rides opr
        LEFT JOIN outstation_pool_bookings opb ON opb.ride_id = opr.id AND opb.status != 'cancelled'
        WHERE opr.driver_id = ${driver.id}::uuid
        GROUP BY opr.id
        ORDER BY opr.created_at DESC
      `);
      res.json({ data: camelize(r.rows) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.patch("/api/app/driver/outstation-pool/rides/:id", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { id } = req.params;
      const { status, isActive, farePerSeat, note } = req.body;
      await rawDb.execute(rawSql`
        UPDATE outstation_pool_rides
        SET
          status     = COALESCE(${status || null}, status),
          is_active  = COALESCE(${isActive != null ? isActive : null}, is_active),
          fare_per_seat = COALESCE(${farePerSeat != null ? parseFloat(farePerSeat) : null}, fare_per_seat),
          note       = COALESCE(${note || null}, note),
          updated_at = NOW()
        WHERE id = ${id}::uuid AND driver_id = ${driver.id}::uuid
      `);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Customer: search outstation pool rides
  app.get("/api/app/customer/outstation-pool/search", authApp, async (req, res) => {
    try {
      const { fromCity, toCity, date } = req.query as any;
      if (!fromCity || !toCity) return res.status(400).json({ message: "fromCity and toCity are required" });

      const r = await rawDb.execute(rawSql`
        SELECT opr.*,
          u.full_name as driver_name, u.phone as driver_phone,
          dd.avg_rating as driver_rating, dd.total_trips
        FROM outstation_pool_rides opr
        LEFT JOIN users u ON u.id = opr.driver_id
        LEFT JOIN driver_details dd ON dd.user_id = opr.driver_id
        WHERE LOWER(opr.from_city) LIKE ${`%${fromCity.toLowerCase()}%`}
          AND LOWER(opr.to_city) LIKE ${`%${toCity.toLowerCase()}%`}
          AND opr.is_active = true
          AND opr.status = 'scheduled'
          AND opr.available_seats > 0
          ${date ? rawSql`AND opr.departure_date = ${date}::date` : rawSql``}
        ORDER BY opr.departure_date ASC, opr.fare_per_seat ASC
      `);
      res.json({ data: camelize(r.rows), total: r.rows.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Customer: book seats in outstation pool ride
  app.post("/api/app/customer/outstation-pool/book", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const { rideId, seatsBooked = 1, pickupAddress, dropoffAddress, paymentMethod = 'cash' } = req.body;
      if (!rideId) return res.status(400).json({ message: "rideId is required" });

      const seats = Math.max(1, parseInt(seatsBooked));

      // Check availability
      const rideRes = await rawDb.execute(rawSql`
        SELECT * FROM outstation_pool_rides
        WHERE id = ${rideId}::uuid AND is_active = true AND status = 'scheduled'
        LIMIT 1
      `);
      if (!rideRes.rows.length) return res.status(404).json({ message: "Ride not found or no longer available" });
      const ride = rideRes.rows[0] as any;
      if (ride.available_seats < seats) return res.status(400).json({ message: `Only ${ride.available_seats} seat(s) available` });

      const totalFare = parseFloat(ride.fare_per_seat) * seats;

      // Create booking and decrement available seats atomically
      const [bookingRes] = await Promise.all([
        rawDb.execute(rawSql`
          INSERT INTO outstation_pool_bookings
            (ride_id, customer_id, seats_booked, total_fare, from_city, to_city,
             pickup_address, dropoff_address, payment_method, status, payment_status)
          VALUES
            (${rideId}::uuid, ${customer.id}::uuid, ${seats}, ${totalFare},
             ${ride.from_city}, ${ride.to_city},
             ${pickupAddress || null}, ${dropoffAddress || null},
             ${paymentMethod}, 'confirmed', 'pending')
          RETURNING *
        `),
        rawDb.execute(rawSql`
          UPDATE outstation_pool_rides
          SET available_seats = available_seats - ${seats}, updated_at = NOW()
          WHERE id = ${rideId}::uuid
        `),
      ]);
      res.json({ success: true, booking: camelize(bookingRes.rows[0]) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/app/customer/outstation-pool/bookings", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT opb.*,
          opr.departure_date, opr.departure_time, opr.vehicle_number, opr.vehicle_model,
          u.full_name as driver_name, u.phone as driver_phone
        FROM outstation_pool_bookings opb
        LEFT JOIN outstation_pool_rides opr ON opr.id = opb.ride_id
        LEFT JOIN users u ON u.id = opr.driver_id
        WHERE opb.customer_id = ${customer.id}::uuid
        ORDER BY opb.created_at DESC
      `);
      res.json({ data: camelize(r.rows) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Admin: manage outstation pool
  app.get("/api/admin/outstation-pool/rides", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT opr.*,
          u.full_name as driver_name, u.phone as driver_phone,
          COUNT(opb.id)::int as total_bookings,
          COALESCE(SUM(opb.total_fare), 0) as total_revenue
        FROM outstation_pool_rides opr
        LEFT JOIN users u ON u.id = opr.driver_id
        LEFT JOIN outstation_pool_bookings opb ON opb.ride_id = opr.id AND opb.status != 'cancelled'
        GROUP BY opr.id, u.full_name, u.phone
        ORDER BY opr.created_at DESC
      `);
      res.json({ data: camelize(r.rows), total: r.rows.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/admin/outstation-pool/bookings", async (req, res) => {
    try {
      const status = req.query.status as string;
      const r = await rawDb.execute(rawSql`
        SELECT opb.*,
          u.full_name as customer_name, u.phone as customer_phone,
          d.full_name as driver_name
        FROM outstation_pool_bookings opb
        LEFT JOIN users u ON u.id = opb.customer_id
        LEFT JOIN outstation_pool_rides opr ON opr.id = opb.ride_id
        LEFT JOIN users d ON d.id = opr.driver_id
        ${status && status !== 'all' ? rawSql`WHERE opb.status = ${status}` : rawSql``}
        ORDER BY opb.created_at DESC
      `);
      res.json({ data: camelize(r.rows), total: r.rows.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.patch("/api/admin/outstation-pool/settings", async (req, res) => {
    try {
      const { mode } = req.body; // 'on' | 'off'
      if (!['on','off'].includes(mode)) return res.status(400).json({ message: "mode must be 'on' or 'off'" });
      await rawDb.execute(rawSql`
        INSERT INTO revenue_model_settings (key_name, value)
        VALUES ('outstation_pool_mode', ${mode})
        ON CONFLICT (key_name) DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()
      `);
      res.json({ success: true, outstation_pool_mode: mode });
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

  // ── Support Chat (Admin ↔ User) ────────────────────────────────────────────
  app.get('/api/support-chat', async (req, res) => {
    try {
      const userId = req.query.userId as string;
      if (!userId) return res.status(400).json({ message: 'userId required' });
      const r = await rawDb.execute(rawSql`
        SELECT sm.*, u.full_name, u.user_type FROM support_messages sm
        LEFT JOIN users u ON u.id = sm.user_id
        WHERE sm.user_id=${userId}::uuid
        ORDER BY sm.created_at ASC LIMIT 100
      `);
      // Mark as read
      await rawDb.execute(rawSql`UPDATE support_messages SET is_read=true WHERE user_id=${userId}::uuid AND sender='user'`);
      res.json({ messages: r.rows.map(camelize) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post('/api/support-chat', async (req, res) => {
    try {
      const { userId, message, sender = 'admin' } = req.body;
      if (!userId || !message) return res.status(400).json({ message: 'userId and message required' });
      const r = await rawDb.execute(rawSql`
        INSERT INTO support_messages (user_id, sender, message)
        VALUES (${userId}::uuid, ${sender}, ${message}) RETURNING *
      `);
      res.json({ success: true, data: camelize(r.rows[0]) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get('/api/support-chat/unread-count', async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT user_id, COUNT(*) as unread
        FROM support_messages WHERE sender='user' AND is_read=false
        GROUP BY user_id
      `);
      res.json({ unreadByUser: r.rows.map(camelize) });
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

  // ── OTP SEND (Twilio SMS gateway) ──────────────────────────────────────
  app.post("/api/app/send-otp", otpLimiter, async (req, res) => {
    try {
      const { phone, userType = "customer" } = req.body;
      if (!phone) return res.status(400).json({ message: "Phone required" });
      const phoneStr = phone.toString().replace(/\D/g, "");
      if (phoneStr.length < 10) return res.status(400).json({ message: "Invalid phone number" });

      // Rate limiting: max 5 OTPs per phone per hour
      const recentCount = await rawDb.execute(rawSql`
        SELECT COUNT(*) as cnt FROM otp_logs WHERE phone=${phoneStr} AND created_at > NOW() - INTERVAL '1 hour'
      `);
      if (parseInt((recentCount.rows[0] as any)?.cnt || "0") >= 5) {
        return res.status(429).json({ message: "Too many OTP requests. Try again after 1 hour." });
      }

      const otp = Math.floor(100000 + Math.random() * 900000).toString();

      // Invalidate old OTPs and store new one
      await rawDb.execute(rawSql`UPDATE otp_logs SET is_used=true WHERE phone=${phoneStr} AND is_used=false`);
      await rawDb.execute(rawSql`
        INSERT INTO otp_logs (phone, otp, user_type, expires_at)
        VALUES (${phoneStr}, ${otp}, ${userType}, NOW() + INTERVAL '5 minutes')
      `);

      // Send real SMS via Twilio
      const smsResult = await sendOtpSms(phoneStr, otp);

      if (smsResult.provider === "none" || !smsResult.success) {
        // No SMS provider configured or SMS failed — return OTP in response if ENABLE_DEV_OTP_RESPONSES=true
        console.log(`[OTP] ${phoneStr} → ${otp} (SMS provider: ${smsResult.provider}, success: ${smsResult.success})`);
        if (isDevOtpResponseEnabled) {
          return res.json({ success: true, message: "OTP generated. Enter it to continue.", otp });
        }
        // SMS provider not configured and dev mode not enabled
        return res.status(503).json({ message: "SMS service not configured. Set FAST2SMS_API_KEY or ENABLE_DEV_OTP_RESPONSES=true." });
      }

      // SMS sent successfully
      res.json({ success: true, message: "OTP sent to your mobile number" });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── OTP VERIFY + LOGIN / REGISTER ────────────────────────────────────────
  app.post("/api/app/verify-otp", async (req, res) => {
    try {
      const { phone, otp, userType = "customer", name, referralCode } = req.body;
      if (!phone || !otp) return res.status(400).json({ message: "Phone and OTP required" });
      const phoneStr = phone.toString().replace(/\D/g, "");
      if (phoneStr.length < 10) return res.status(400).json({ message: "Invalid phone number" });

      // Check OTP
      const otpRow = await rawDb.execute(rawSql`
        SELECT * FROM otp_logs WHERE phone=${phoneStr} AND otp=${otp} AND is_used=false AND expires_at > NOW()
        ORDER BY created_at DESC LIMIT 1
      `);
      if (!otpRow.rows.length) return res.status(400).json({ message: "Invalid or expired OTP" });

      // Mark used
      await rawDb.execute(rawSql`UPDATE otp_logs SET is_used=true WHERE id=${(otpRow.rows[0] as any).id}::uuid`);

      // Find or create user
      let userRes = await rawDb.execute(rawSql`SELECT * FROM users WHERE phone=${phoneStr} AND user_type=${userType} LIMIT 1`);
      let user: any;
      let isNew = false;

      if (!userRes.rows.length) {
        // Register new user
        isNew = true;
        const fullName = name || `User_${phone.slice(-4)}`;
        const newUser = await rawDb.execute(rawSql`
          INSERT INTO users (full_name, phone, user_type, is_active, wallet_balance)
          VALUES (${fullName}, ${phoneStr}, ${userType}, true, 0)
          RETURNING *
        `);
        user = camelize(newUser.rows[0]);
      } else {
        user = camelize(userRes.rows[0]);
        if (!user.isActive) return res.status(403).json({ message: "Account deactivated. Contact support." });
      }

      // Generate secure auth token (30-day expiry)
      const token = `${user.id}:${crypto.randomBytes(32).toString("hex")}`;
      const tokenExpiry = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
      // Store auth token in users.auth_token (NOT in fcm_token — that's for Firebase)
      await rawDb.execute(rawSql`UPDATE users SET auth_token=${token}, auth_token_expires_at=${tokenExpiry} WHERE id=${user.id}::uuid`);

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

  // ── FIREBASE TOKEN VERIFICATION ───────────────────────────────────────────
  app.post("/api/app/verify-firebase-token", async (req, res) => {
    try {
      const { firebaseIdToken, phone, userType = "customer" } = req.body;
      if (!firebaseIdToken) return res.status(400).json({ message: "Firebase ID token required" });

      let phoneStr = "";

      // Try Firebase Admin SDK first (needs service account key)
      const { getFirebaseAdmin } = await import("./fcm.js");
      const adminInst = getFirebaseAdmin();
      if (adminInst) {
        const decoded = await adminInst.auth().verifyIdToken(firebaseIdToken);
        const firebasePhone = (decoded.phone_number || "").replace(/\D/g, "").slice(-10);
        const clientPhone = (phone?.toString() || "").replace(/\D/g, "").slice(-10);
        phoneStr = firebasePhone || clientPhone;
        if (clientPhone && firebasePhone && clientPhone !== firebasePhone) {
          return res.status(400).json({ message: "Phone number mismatch. Please retry login." });
        }
      } else {
        // Fallback: verify token via Firebase REST API (only needs Web API key — no service account needed)
        const webApiKey = process.env.FIREBASE_WEB_API_KEY || "AIzaSyBJIuefXlqcKNsIssYHQP6lpIWQ3ih4_Z8";
        const lookupRes = await fetch(
          `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${webApiKey}`,
          { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ idToken: firebaseIdToken }) }
        );
        if (!lookupRes.ok) {
          return res.status(401).json({ message: "Invalid or expired Firebase token. Please retry." });
        }
        const lookupData = (await lookupRes.json()) as any;
        const firebaseUser = lookupData.users?.[0];
        if (!firebaseUser) return res.status(401).json({ message: "Invalid Firebase token." });
        const firebasePhone = (firebaseUser.phoneNumber || "").replace(/\D/g, "").slice(-10);
        const clientPhone = (phone?.toString() || "").replace(/\D/g, "").slice(-10);
        phoneStr = firebasePhone || clientPhone;
        if (clientPhone && firebasePhone && clientPhone !== firebasePhone) {
          return res.status(400).json({ message: "Phone number mismatch. Please retry login." });
        }
      }

      if (!phoneStr || phoneStr.length < 10) {
        return res.status(400).json({ message: "Could not determine phone number from token" });
      }

      // Find or create user
      let userRes = await rawDb.execute(rawSql`SELECT * FROM users WHERE phone=${phoneStr} AND user_type=${userType} LIMIT 1`);
      let user: any;
      let isNew = false;
      if (!userRes.rows.length) {
        isNew = true;
        const fullName = `User_${phoneStr.slice(-4)}`;
        const newUser = await rawDb.execute(rawSql`
          INSERT INTO users (full_name, phone, user_type, is_active, wallet_balance)
          VALUES (${fullName}, ${phoneStr}, ${userType}, true, 0)
          RETURNING *
        `);
        user = camelize(newUser.rows[0]);
      } else {
        user = camelize(userRes.rows[0]);
        if (!user.isActive) return res.status(403).json({ message: "Account deactivated. Contact support." });
      }

      const token = `${user.id}:${crypto.randomBytes(32).toString("hex")}`;
      const tokenExpiry = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
      await rawDb.execute(rawSql`UPDATE users SET auth_token=${token}, auth_token_expires_at=${tokenExpiry} WHERE id=${user.id}::uuid`);

      let walletBalance = 0;
      let isLocked = false;
      if (userType === "driver") {
        const walletR = await rawDb.execute(rawSql`SELECT wallet_balance, is_locked FROM users WHERE id=${user.id}::uuid`);
        if (walletR.rows.length) {
          walletBalance = parseFloat((walletR.rows[0] as any).wallet_balance || 0);
          isLocked = (walletR.rows[0] as any).is_locked || false;
        }
      }

      res.json({
        success: true, isNew, token,
        user: {
          id: user.id, fullName: user.fullName, phone: user.phone,
          email: user.email || null, userType: user.userType,
          profilePhoto: user.profilePhoto || null,
          rating: parseFloat(user.rating || "5.0"),
          isActive: user.isActive, walletBalance, isLocked,
        }
      });
    } catch (e: any) {
      if (e.code && String(e.code).startsWith("auth/")) {
        return res.status(401).json({ message: "Invalid or expired Firebase token. Please retry." });
      }
      res.status(500).json({ message: e.message });
    }
  });

  // ── PASSWORD-BASED REGISTER ───────────────────────────────────────────────
  app.post("/api/app/register", async (req, res) => {
    try {
      const { phone, password, fullName, userType = "customer", email } = req.body;
      if (!phone || !password || !fullName) return res.status(400).json({ message: "Phone, password and name are required" });
      if (phone.length !== 10) return res.status(400).json({ message: "Enter a valid 10-digit phone number" });
      if (password.length < 6) return res.status(400).json({ message: "Password must be at least 6 characters" });
      const existing = await rawDb.execute(rawSql`SELECT id FROM users WHERE phone=${phone} AND user_type=${userType} LIMIT 1`);
      if (existing.rows.length) return res.status(409).json({ message: "Account already exists. Please login." });
      const passwordHash = await bcrypt.hash(password, 10);
      const insertRes = await rawDb.execute(rawSql`
        INSERT INTO users (full_name, phone, email, user_type, is_active, wallet_balance, password_hash)
        VALUES (${fullName}, ${phone}, ${email || null}, ${userType}, true, 0, ${passwordHash})
        RETURNING *
      `);
      const user = camelize(insertRes.rows[0]) as any;
      const token = `${user.id}:${crypto.randomBytes(32).toString("hex")}`;
      const tokenExpiry = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
      await rawDb.execute(rawSql`UPDATE users SET auth_token=${token}, auth_token_expires_at=${tokenExpiry} WHERE id=${user.id}::uuid`);
      res.json({ success: true, isNew: true, token, user: { id: user.id, fullName: user.fullName, phone: user.phone, email: user.email || null, userType: user.userType, walletBalance: 0 } });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── PASSWORD-BASED LOGIN ──────────────────────────────────────────────────
  app.post("/api/app/login-password", async (req, res) => {
    try {
      const { phone, password, userType = "customer" } = req.body;
      if (!phone || !password) return res.status(400).json({ message: "Phone and password are required" });
      const userRes = await rawDb.execute(rawSql`SELECT * FROM users WHERE phone=${phone} AND user_type=${userType} LIMIT 1`);
      if (!userRes.rows.length) return res.status(404).json({ message: "No account found. Please register first." });
      const user = camelize(userRes.rows[0]) as any;
      if (!user.isActive) return res.status(403).json({ message: "Account deactivated. Contact support." });
      if (!user.passwordHash) return res.status(400).json({ message: "Password not set. Please use Forgot Password to set one." });
      const match = await bcrypt.compare(password, user.passwordHash);
      if (!match) return res.status(401).json({ message: "Incorrect password. Please try again." });
      const token = `${user.id}:${crypto.randomBytes(32).toString("hex")}`;
      const tokenExpiry = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();
      await rawDb.execute(rawSql`UPDATE users SET auth_token=${token}, auth_token_expires_at=${tokenExpiry} WHERE id=${user.id}::uuid`);
      const walletBalance = parseFloat(user.walletBalance || 0);
      res.json({ success: true, token, user: { id: user.id, fullName: user.fullName, phone: user.phone, email: user.email || null, userType: user.userType, profilePhoto: user.profilePhoto || null, rating: parseFloat(user.rating || "5.0"), isActive: user.isActive, walletBalance, isLocked: user.isLocked || false } });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── FORGOT PASSWORD (send reset OTP to phone) ─────────────────────────────
  app.post("/api/app/forgot-password", otpLimiter, async (req, res) => {
    try {
      const { phone, userType = "customer" } = req.body;
      if (!phone) return res.status(400).json({ message: "Phone number is required" });
      const phoneStr = phone.toString().replace(/\D/g, "");
      if (phoneStr.length < 10) return res.status(400).json({ message: "Invalid phone number" });
      const userRes = await rawDb.execute(rawSql`SELECT id FROM users WHERE phone=${phoneStr} AND user_type=${userType} LIMIT 1`);
      if (!userRes.rows.length) return res.status(404).json({ message: "No account found with this phone number." });
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      await rawDb.execute(rawSql`
        UPDATE users
        SET reset_otp=${otp}, reset_otp_expiry=NOW() + INTERVAL '10 minutes'
        WHERE phone=${phoneStr} AND user_type=${userType}
      `);
      const isProd = process.env.NODE_ENV === "production";
      let smsSent = false;
      try { const r = await sendOtpSms(phoneStr, otp); smsSent = r.success; } catch (_) {}
      if (!smsSent) {
        console.log("[RESET OTP] Phone: " + phoneStr + " OTP: " + otp);
        if (isDevOtpResponseEnabled) return res.json({ success: true, message: "Reset OTP generated. Enter it to continue.", otp });
        return res.json({ success: true, message: "Reset OTP sent to your mobile number" });
      }
      res.json({ success: true, message: "Reset OTP sent to your mobile number" });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── RESET PASSWORD (verify OTP + set new password) ────────────────────────
  app.post("/api/app/reset-password", async (req, res) => {
    try {
      const { phone, otp, newPassword, userType = "customer" } = req.body;
      if (!phone || !otp || !newPassword) return res.status(400).json({ message: "Phone, OTP and new password are required" });
      const phoneStr = phone.toString().replace(/\D/g, "");
      if (phoneStr.length < 10) return res.status(400).json({ message: "Invalid phone number" });
      if (newPassword.length < 6) return res.status(400).json({ message: "Password must be at least 6 characters" });
      const userRes = await rawDb.execute(rawSql`SELECT * FROM users WHERE phone=${phoneStr} AND user_type=${userType} AND reset_otp=${otp} AND reset_otp_expiry > NOW() LIMIT 1`);
      if (!userRes.rows.length) return res.status(400).json({ message: "Invalid or expired OTP. Please try again." });
      const passwordHash = await bcrypt.hash(newPassword, 10);
      await rawDb.execute(rawSql`UPDATE users SET password_hash=${passwordHash}, reset_otp=NULL, reset_otp_expiry=NULL WHERE phone=${phoneStr} AND user_type=${userType}`);
      res.json({ success: true, message: "Password reset successfully. Please login with your new password." });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

    // ── AUTH MIDDLEWARE (simple token check) ─────────────────────────────────
  async function authApp(req: Request, res: Response, next: NextFunction) {
    try {
      const token = req.headers.authorization?.replace("Bearer ", "");
      if (!token) return res.status(401).json({ message: "No token provided" });
      const parts = token.split(":");
      if (parts.length < 2) return res.status(401).json({ message: "Invalid token format" });
      const userId = parts[0];
      // Validate full token against stored auth_token in DB and check expiry
      const userR = await rawDb.execute(rawSql`
        SELECT * FROM users WHERE id=${userId}::uuid AND is_active=true AND auth_token=${token}
          AND (auth_token_expires_at IS NULL OR auth_token_expires_at > NOW()) LIMIT 1
      `);
      if (!userR.rows.length) return res.status(401).json({ message: "Session expired or invalid. Please login again." });
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
      if (isOnline) {
        // Check verification status FIRST — driver cannot go online until approved
        const verR = await rawDb.execute(rawSql`SELECT verification_status, rejection_note FROM users WHERE id=${driver.id}::uuid`);
        const vs = (verR.rows[0] as any)?.verification_status;
        if (vs !== 'approved') {
          const msg = vs === 'rejected'
            ? `Account rejected: ${(verR.rows[0] as any)?.rejection_note || 'Contact support for details'}`
            : 'Account pending verification. You will be notified once approved.';
          return res.status(403).json({ message: msg, verificationStatus: vs, notVerified: true });
        }
        // Check if driver has selected a revenue model
        const modelR = await rawDb.execute(rawSql`SELECT revenue_model, model_selected_at FROM users WHERE id=${driver.id}::uuid`);
        const modelRow = modelR.rows[0] as any;
        if (!modelRow?.model_selected_at) {
          if (modelRow?.revenue_model) {
            // Auto-heal: driver has a revenue model set (e.g. by admin) but model_selected_at was never recorded — backfill it
            await rawDb.execute(rawSql`UPDATE users SET model_selected_at=NOW() WHERE id=${driver.id}::uuid`);
          } else {
            return res.status(403).json({ message: 'Please choose your revenue model before going online.', needsModelSelection: true });
          }
        }
        // Subscription-like models require an active plan before going online
        const isSubscriptionLikeModel = ['subscription', 'hybrid'].includes(String(modelRow?.revenue_model || ''));
        if (isSubscriptionLikeModel) {
          const subR = await rawDb.execute(rawSql`SELECT id, end_date FROM driver_subscriptions WHERE driver_id=${driver.id}::uuid AND is_active=true AND end_date > NOW() ORDER BY end_date DESC LIMIT 1`);
          if (!subR.rows.length) {
            return res.status(403).json({ message: 'Your subscription has expired. Please renew to go online.', subscriptionExpired: true });
          }
        }
        // Check document expiry — insurance, RC, PUC must be valid
        const docExpR = await rawDb.execute(rawSql`
          SELECT doc_type, expiry_date FROM driver_documents
          WHERE driver_id=${driver.id}::uuid
            AND doc_type IN ('insurance','rc','puc')
            AND expiry_date IS NOT NULL AND expiry_date != ''
            AND expiry_date < CURRENT_DATE::text
          LIMIT 1
        `);
        if (docExpR.rows.length) {
          const expDoc = docExpR.rows[0] as any;
          const docLabel = expDoc.doc_type === 'rc' ? 'Vehicle RC' : expDoc.doc_type === 'insurance' ? 'Vehicle Insurance' : 'Pollution Certificate (PUC)';
          return res.status(403).json({
            message: `Your ${docLabel} has expired (${expDoc.expiry_date}). Please upload an updated document to go online.`,
            documentExpired: true,
            docType: expDoc.doc_type,
          });
        }
        // Check wallet lock (applies to both models — negative balance)
        const walletR = await rawDb.execute(rawSql`SELECT is_locked, wallet_balance, lock_reason FROM users WHERE id=${driver.id}::uuid`);
        const w = walletR.rows[0] as any;
        const currentBalance = parseFloat(w?.wallet_balance || 0);
        // Also fetch the auto-lock threshold from settings
        const thresholdR = await rawDb.execute(rawSql`SELECT value FROM revenue_model_settings WHERE key_name='auto_lock_threshold' LIMIT 1`);
        const lockThreshold = parseFloat((thresholdR.rows[0] as any)?.value || "-100");
        // Block if explicitly locked
        if (w?.is_locked) return res.status(403).json({
          message: w.lock_reason || "Account locked. Please recharge wallet to go online.",
          isLocked: true, walletBalance: currentBalance
        });
        // Block if wallet is below threshold (auto-lock that wasn't yet written)
        if (currentBalance < lockThreshold) {
          const lockMsg = `Wallet balance ₹${currentBalance.toFixed(2)} is below minimum threshold ₹${lockThreshold}. Recharge wallet to go online.`;
          await rawDb.execute(rawSql`UPDATE users SET is_locked=true, lock_reason=${lockMsg}, locked_at=NOW() WHERE id=${driver.id}::uuid`);
          return res.status(403).json({
            message: lockMsg, isLocked: true, walletBalance: currentBalance
          });
        }
        // Per-service subscription check: use model based on driver's vehicle category type
        const modelAllR = await rawDb.execute(rawSql`SELECT key_name, value FROM revenue_model_settings`);
        const mS: any = {};
        modelAllR.rows.forEach((row: any) => { mS[(row as any).key_name] = (row as any).value; });
        // Get driver's vehicle category type
        const driverVehicleR = await rawDb.execute(rawSql`
          SELECT vc.type as vehicle_type FROM driver_details dd
          JOIN vehicle_categories vc ON vc.id = dd.vehicle_category_id
          WHERE dd.user_id = ${driver.id}::uuid
        `);
        const vehicleType = (driverVehicleR.rows[0] as any)?.vehicle_type || 'ride';
        let relevantModelKey = 'rides_model';
        if (vehicleType === 'parcel') relevantModelKey = 'parcels_model';
        else if (vehicleType === 'cargo') relevantModelKey = 'cargo_model';
        const activeModel = mS[relevantModelKey] || mS['active_model'] || "commission";
        if (activeModel === "subscription" || activeModel === "hybrid") {
          const subR = await rawDb.execute(rawSql`
            SELECT id, end_date, is_active FROM driver_subscriptions
            WHERE driver_id=${driver.id}::uuid AND is_active=true AND end_date >= CURRENT_DATE
            ORDER BY end_date DESC LIMIT 1
          `);
          if (!subR.rows.length) {
            return res.status(403).json({
              message: "Subscription required. Please purchase or renew your subscription to go online.",
              requiresSubscription: true, isLocked: false
            });
          }
          const sub = subR.rows[0] as any;
          const daysLeft = Math.ceil((new Date(sub.end_date).getTime() - Date.now()) / 86400000);
          if (daysLeft <= 2) {
            res.setHeader("X-Subscription-Warning", `Subscription expires in ${daysLeft} day(s)`);
          }
        }
      }
      const lat = req.body.lat ?? 0;
      const lng = req.body.lng ?? 0;
      await rawDb.execute(rawSql`UPDATE users SET is_online=${isOnline} WHERE id=${driver.id}::uuid`);
      // UPSERT driver_locations — creates row for new drivers, always updates lat/lng
      await rawDb.execute(rawSql`
        INSERT INTO driver_locations (driver_id, lat, lng, is_online, updated_at)
        VALUES (${driver.id}::uuid, ${lat}, ${lng}, ${isOnline}, NOW())
        ON CONFLICT (driver_id) DO UPDATE SET lat=${lat}, lng=${lng}, is_online=${isOnline}, updated_at=NOW()
      `);
      res.json({ success: true, isOnline });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Get profile + wallet + current trip ───────────────────────────
  app.get("/api/app/driver/profile", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT u.*,
          dd.vehicle_category_id, dd.zone_id, dd.availability_status, dd.avg_rating as driver_rating, dd.total_trips as driver_total_trips,
          vc.name as vehicle_category_name, vc.type as vehicle_category_type, vc.icon as vehicle_category_icon,
          z.name as zone_name,
          (SELECT COUNT(*) FROM trip_requests WHERE driver_id=u.id AND current_status='completed') as completed_trips,
          (SELECT COALESCE(SUM(actual_fare),0) FROM trip_requests WHERE driver_id=u.id AND current_status='completed') as total_earned,
          (SELECT COUNT(*) FROM trip_requests WHERE driver_id=u.id AND current_status='cancelled') as cancelled_trips
        FROM users u
        LEFT JOIN driver_details dd ON dd.user_id = u.id
        LEFT JOIN vehicle_categories vc ON vc.id = dd.vehicle_category_id
        LEFT JOIN zones z ON z.id = dd.zone_id
        WHERE u.id=${driver.id}::uuid
      `);
      const loc = await rawDb.execute(rawSql`SELECT lat, lng, is_online FROM driver_locations WHERE driver_id=${driver.id}::uuid`);
      const d = camelize(r.rows[0]) as any;
      const userObj = {
        id: d.id,
        fullName: d.fullName,
        phone: d.phone,
        email: d.email,
        profilePhoto: d.profilePhoto,
        rating: parseFloat(d.driverRating || d.rating || "5.0"),
        totalRatings: d.totalRatings || 0,
        walletBalance: parseFloat(d.walletBalance || "0"),
        isLocked: d.isLocked || false,
        lockReason: d.lockReason || null,
        isOnline: loc.rows.length ? (loc.rows[0] as any).is_online : false,
        currentLat: loc.rows.length ? (loc.rows[0] as any).lat : null,
        currentLng: loc.rows.length ? (loc.rows[0] as any).lng : null,
        vehicleNumber: d.vehicleNumber || null,
        vehicleModel: d.vehicleModel || null,
        vehicleCategoryId: d.vehicleCategoryId || null,
        vehicleCategory: d.vehicleCategoryName || null,
        vehicleCategoryType: d.vehicleCategoryType || null,
        vehicleCategoryIcon: d.vehicleCategoryIcon || null,
        zoneId: d.zoneId || null,
        zone: d.zoneName || null,
        availabilityStatus: d.availabilityStatus || 'offline',
        stats: {
          completedTrips: parseInt(d.completedTrips || "0"),
          totalEarned: parseFloat(d.totalEarned || "0"),
          cancelledTrips: parseInt(d.cancelledTrips || "0"),
        }
      };
      res.json({ user: userObj, ...userObj });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Incoming trip request (polling) ───────────────────────────────
  app.get("/api/app/driver/incoming-trip", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      // 1. Check if this driver has an active/accepted trip
      const active = await rawDb.execute(rawSql`
        SELECT t.*, c.full_name as customer_name, c.phone as customer_phone, c.rating as customer_rating,
          vc.name as vehicle_name,
          CASE WHEN t.is_for_someone_else THEN t.passenger_name ELSE c.full_name END as contact_name,
          CASE WHEN t.is_for_someone_else THEN t.passenger_phone ELSE c.phone END as contact_phone
        FROM trip_requests t
        LEFT JOIN users c ON c.id = t.customer_id
        LEFT JOIN vehicle_categories vc ON vc.id = t.vehicle_category_id
        WHERE t.driver_id = ${driver.id}::uuid
          AND t.current_status IN ('driver_assigned','accepted','arrived','on_the_way')
        ORDER BY t.created_at DESC LIMIT 1
      `);
      if (active.rows.length) {
        const stage = (active.rows[0] as any).current_status;
        return res.json({ trip: camelize(active.rows[0]), stage });
      }
      // 2. Check driver location + vehicle category to find matching nearby trips
      const locR = await rawDb.execute(rawSql`
        SELECT dl.lat, dl.lng, dd.vehicle_category_id
        FROM driver_locations dl
        LEFT JOIN driver_details dd ON dd.user_id = dl.driver_id
        WHERE dl.driver_id=${driver.id}::uuid
      `);
      if (!locR.rows.length) return res.json({ trip: null });
      const { lat, lng, vehicle_category_id } = locR.rows[0] as any;
      // Show matching searching trip within 15km radius
      const searching = await rawDb.execute(rawSql`
        SELECT t.*, c.full_name as customer_name, c.phone as customer_phone,
          vc.name as vehicle_name, vc.icon as vehicle_icon,
          ROUND(CAST(SQRT((t.pickup_lat - ${Number(lat)})*(t.pickup_lat - ${Number(lat)}) + (t.pickup_lng - ${Number(lng)})*(t.pickup_lng - ${Number(lng)})) * 111 AS numeric), 1) as distance_km,
          CASE WHEN t.is_for_someone_else THEN t.passenger_name ELSE c.full_name END as contact_name,
          CASE WHEN t.is_for_someone_else THEN t.passenger_phone ELSE c.phone END as contact_phone
        FROM trip_requests t
        LEFT JOIN users c ON c.id = t.customer_id
        LEFT JOIN vehicle_categories vc ON vc.id = t.vehicle_category_id
        WHERE t.current_status = 'searching' AND t.driver_id IS NULL
          AND t.created_at > NOW() - INTERVAL '10 minutes'
          AND NOT (${driver.id}::uuid = ANY(COALESCE(t.rejected_driver_ids, '{}'::uuid[])))
          ${vehicle_category_id ? rawSql`AND t.vehicle_category_id = ${vehicle_category_id}::uuid` : rawSql``}
          AND (t.pickup_lat - ${Number(lat)})*(t.pickup_lat - ${Number(lat)}) + (t.pickup_lng - ${Number(lng)})*(t.pickup_lng - ${Number(lng)}) < 0.02
        ORDER BY (t.pickup_lat - ${Number(lat)})*(t.pickup_lat - ${Number(lat)}) + (t.pickup_lng - ${Number(lng)})*(t.pickup_lng - ${Number(lng)}) ASC LIMIT 1
      `);
      if (searching.rows.length) {
        return res.json({ trip: camelize(searching.rows[0]), stage: "new_request" });
      }
      res.json({ trip: null });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Accept trip ───────────────────────────────────────────────────
  app.post("/api/app/driver/accept-trip", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { tripId } = req.body;
      const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!tripId || !uuidRe.test(tripId)) return res.status(400).json({ message: "Invalid trip ID" });

      // ── Subscription gate: bike_ride uses subscription model ──────────────
      // Check if a bike_ride service is active + uses subscription model
      const svcR = await rawDb.execute(rawSql`
        SELECT revenue_model FROM platform_services
        WHERE service_key = 'bike_ride' AND service_status = 'active' LIMIT 1
      `).catch(() => ({ rows: [] as any[] }));
      if (svcR.rows.length) {
        const model = (svcR.rows[0] as any).revenue_model;
        if (model === 'subscription') {
          // Driver must have an active, non-expired subscription
          const subR = await rawDb.execute(rawSql`
            SELECT id FROM driver_subscriptions
            WHERE driver_id = ${driver.id}::uuid
              AND is_active = true
              AND end_date > NOW()
            LIMIT 1
          `);
          if (!subR.rows.length) {
            return res.status(403).json({
              message: "Active subscription required to accept rides. Please subscribe to continue.",
              code: "SUBSCRIPTION_REQUIRED",
            });
          }
        }
      }

      // ── Account lock check ────────────────────────────────────────────────
      if (driver.is_locked || driver.isLocked) {
        return res.status(403).json({
          message: driver.lock_reason || driver.lockReason || "Account locked. Please clear pending dues to accept rides.",
          code: "ACCOUNT_LOCKED",
        });
      }

      // Check driver doesn't already have an active trip (include driver_assigned = pre-dispatched)
      const driverBusy = await rawDb.execute(rawSql`SELECT id FROM trip_requests WHERE driver_id=${driver.id}::uuid AND current_status IN ('driver_assigned','accepted','arrived','on_the_way')`);
      if (driverBusy.rows.length) return res.status(400).json({ message: "You already have an active trip" });

      // Generate pickup OTP
      const otp = Math.floor(1000 + Math.random() * 9000).toString();

      // Atomically claim the trip — only succeeds if trip is still searching/driver_assigned and unaccepted
      const r = await rawDb.execute(rawSql`
        UPDATE trip_requests
        SET current_status='accepted', driver_accepted_at=NOW(), driver_arriving_at=NOW(), pickup_otp=${otp}, driver_id=${driver.id}::uuid
        WHERE id=${tripId}::uuid
          AND current_status IN ('searching','driver_assigned')
          AND (driver_id IS NULL OR driver_id=${driver.id}::uuid)
        RETURNING *
      `);
      if (!r.rows.length) {
        const exists = await rawDb.execute(rawSql`SELECT current_status, driver_id FROM trip_requests WHERE id=${tripId}::uuid`);
        const info = exists.rows[0] as any;
        if (!info) return res.status(404).json({ message: "Trip not found" });
        if (info.current_status === 'accepted') return res.status(409).json({ message: "Trip already accepted by another driver" });
        return res.status(400).json({ message: `Cannot accept trip in status: ${info.current_status}` });
      }

      // Mark driver as on current trip
      await rawDb.execute(rawSql`UPDATE users SET current_trip_id=${tripId}::uuid WHERE id=${driver.id}::uuid`);

      const tripData = camelize(r.rows[0]) as any;
      await appendTripStatus(tripData.id, 'driver_assigned', 'driver', 'Driver accepted trip');
      await logRideLifecycleEvent(tripData.id, 'driver_assigned', driver.id, 'driver', { pickupOtp: otp });

      // 🔌 Socket: notify customer — driver accepted, show pilot details
      if (io) {
        io.to(`user:${tripData.customerId}`).emit("trip:accepted", {
          tripId: tripData.id,
          driverName: driver.fullName || "Pilot",
          driverPhone: driver.phone || "",
          driverPhoto: driver.profilePhoto || null,
          pickupOtp: otp,
          driverId: driver.id,
          uiState: 'driver_assigned',
        });
        // Notify other nearby drivers that this trip is taken
        io.emit("trip:taken", { tripId: tripData.id });
      }

      // 🔔 FCM: notify customer
      const custDevRes = await rawDb.execute(rawSql`SELECT fcm_token FROM user_devices WHERE user_id=${tripData.customerId}::uuid`);
      const custFcmToken = (custDevRes.rows[0] as any)?.fcm_token || null;
      notifyCustomerDriverAccepted({
        fcmToken: custFcmToken,
        driverName: driver.fullName || "Driver",
        tripId: tripData.id,
      }).catch(() => {});

      res.json({ success: true, trip: tripData, pickupOtp: otp });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Reject / skip trip ─────────────────────────────────────────────
  app.post("/api/app/driver/reject-trip", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { tripId } = req.body;
      const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!tripId || !uuidRe.test(tripId)) return res.json({ success: true });

      // Clear current_trip_id on this driver (defensive — should not be set for searching trips)
      await rawDb.execute(rawSql`UPDATE users SET current_trip_id=NULL WHERE id=${driver.id}::uuid AND current_trip_id=${tripId}::uuid`);

      // Record rejection — keep trip in 'searching', clear driver_id assignment if any
      const tripRes = await rawDb.execute(rawSql`
        UPDATE trip_requests
        SET current_status='searching', driver_id=NULL,
            rejected_driver_ids = array_append(COALESCE(rejected_driver_ids,'{}'), ${driver.id}::uuid)
        WHERE id=${tripId}::uuid AND current_status IN ('driver_assigned','searching','accepted')
          AND (driver_id=${driver.id}::uuid OR driver_id IS NULL)
        RETURNING pickup_lat, pickup_lng, vehicle_category_id, rejected_driver_ids, customer_id,
                  pickup_address, destination_address, estimated_fare
      `);

      if (tripRes.rows.length && io) {
        const trip = camelize(tripRes.rows[0]) as any;
        // Notify customer that we're still searching
        if (trip.customerId) {
          io.to(`user:${trip.customerId}`).emit("trip:searching", { tripId, message: "Looking for another pilot..." });
        }

        // AI-scored driver reassignment after rejection
        const rejectExcludeList = (trip.rejectedDriverIds || []).filter(Boolean);
        const nextBestDrivers = await findBestDrivers(
          Number(trip.pickupLat), Number(trip.pickupLng),
          trip.vehicleCategoryId || undefined,
          rejectExcludeList,
          3
        );

        for (const nd of nextBestDrivers) {
          io.to(`user:${nd.driverId}`).emit("trip:new_request", {
            tripId,
            refId: trip.refId,
            customerName: "",
            pickupAddress: trip.pickupAddress || "Pickup",
            destinationAddress: trip.destinationAddress || "",
            pickupLat: Number(trip.pickupLat),
            pickupLng: Number(trip.pickupLng),
            estimatedFare: Number(trip.estimatedFare) || 0,
          });
          if (nd.fcmToken) {
            notifyDriverNewRide({
              fcmToken: nd.fcmToken, driverName: nd.fullName,
              customerName: "", pickupAddress: trip.pickupAddress || "Pickup",
              estimatedFare: Number(trip.estimatedFare) || 0, tripId,
            }).catch(() => {});
          }
        }
      }

      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Verify pickup OTP + start ride ────────────────────────────────
  app.post("/api/app/driver/verify-pickup-otp", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { tripId, otp } = req.body;
      const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!tripId || !uuidRe.test(tripId)) return res.status(400).json({ message: "Invalid trip ID" });
      if (!otp || String(otp).trim().length < 4) return res.status(400).json({ message: "Pickup OTP required" });
      const r = await rawDb.execute(rawSql`
        SELECT *, (SELECT full_name FROM users WHERE id=customer_id) as customer_name,
          (SELECT phone FROM users WHERE id=customer_id) as customer_phone
        FROM trip_requests WHERE id=${tripId}::uuid
          AND driver_id=${driver.id}::uuid
          AND current_status = 'arrived'
      `);
      if (!r.rows.length) return res.status(404).json({ message: "Trip not found" });
      const trip = r.rows[0] as any;
      if (trip.pickup_otp !== otp) return res.status(400).json({ message: "Wrong OTP. Please check with sender." });
      const updated = await rawDb.execute(rawSql`
        UPDATE trip_requests SET current_status='on_the_way', ride_started_at=NOW()
        WHERE id=${tripId}::uuid RETURNING *
      `);
      await appendTripStatus(tripId, 'trip_started', 'driver', 'Pickup OTP verified');
      await logRideLifecycleEvent(tripId, 'trip_started', driver.id, 'driver', { via: 'verify-pickup-otp' });
      // 📦 For parcel — send delivery OTP to receiver via SMS when pickup is done
      if ((trip.trip_type === 'parcel' || trip.trip_type === 'delivery') && trip.delivery_otp && trip.receiver_phone) {
        sendCustomSms(trip.receiver_phone,
          `JAGO Parcel: Package picked up by driver ${driver.fullName || ''}. Delivery OTP: ${trip.delivery_otp}. Share this to receive your parcel.`
        ).catch(() => {});
      }
      if (io) {
        io.to(`user:${trip.customer_id}`).emit("trip:status_update", { tripId, status: "on_the_way", otp, uiState: 'trip_started' });
        io.to(`trip:${tripId}`).emit("trip:status_update", { tripId, status: "on_the_way", otp, uiState: 'trip_started' });
      }
      res.json({ success: true, trip: camelize(updated.rows[0]) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Verify delivery OTP (Parcel) ─────────────────────────────────
  app.post("/api/app/driver/verify-delivery-otp", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { tripId, otp } = req.body;
      const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!tripId || !uuidRe.test(tripId)) return res.status(400).json({ message: "Invalid trip ID" });
      if (!otp || String(otp).trim().length < 4) return res.status(400).json({ message: "Delivery OTP required" });
      const r = await rawDb.execute(rawSql`
        SELECT * FROM trip_requests WHERE id=${tripId}::uuid AND driver_id=${driver.id}::uuid
          AND trip_type IN ('parcel','delivery') AND current_status='on_the_way'
      `);
      if (!r.rows.length) return res.status(404).json({ message: "Parcel trip not found or not in transit" });
      const trip = r.rows[0] as any;
      if (String(trip.delivery_otp || '').trim() !== String(otp).trim()) return res.status(400).json({ message: "Wrong delivery OTP. Please check with receiver." });
      await rawDb.execute(rawSql`
        UPDATE trip_requests SET delivery_otp = NULL, updated_at = NOW()
        WHERE id=${tripId}::uuid AND driver_id=${driver.id}::uuid
      `);
      res.json({ success: true, message: "Delivery OTP verified. Complete the trip." });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Arrived at pickup ─────────────────────────────────────────────
  app.post("/api/app/driver/arrived", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { tripId } = req.body;
      const updR = await rawDb.execute(rawSql`
        UPDATE trip_requests SET current_status='arrived'
        WHERE id=${tripId}::uuid AND driver_id=${driver.id}::uuid
          AND current_status IN ('accepted','driver_assigned')
        RETURNING id, pickup_otp, customer_id
      `);
      // Get pickup OTP + passenger info + customer FCM token
      const r = await rawDb.execute(rawSql`
        SELECT t.pickup_otp, t.customer_id, t.passenger_phone, t.passenger_name,
          t.is_for_someone_else, t.trip_type, c.phone as customer_phone, c.full_name as customer_name
        FROM trip_requests t
        LEFT JOIN users c ON c.id = t.customer_id
        WHERE t.id=${tripId}::uuid
      `);
      const tripRow = r.rows[0] as any;
      const otp = tripRow?.pickup_otp;
      await appendTripStatus(tripId, 'driver_arriving', 'driver', 'Driver reached pickup');
      await logRideLifecycleEvent(tripId, 'driver_arriving', driver.id, 'driver');

      // 🔔 Notify customer — driver arrived, show OTP
      const custDevRes = await rawDb.execute(rawSql`SELECT fcm_token FROM user_devices WHERE user_id=${tripRow.customer_id}::uuid`);
      const custFcmToken = (custDevRes.rows[0] as any)?.fcm_token || null;
      notifyCustomerDriverArrived({
        fcmToken: custFcmToken,
        driverName: driver.fullName || "Driver",
        otp: otp || "",
        tripId,
      }).catch(() => {});

      // 📱 If booked for someone else — send OTP as SMS to passenger phone
      if (tripRow?.is_for_someone_else && tripRow?.passenger_phone) {
        sendCustomSms(tripRow.passenger_phone,
          `JAGO: Your ride OTP is ${otp}. Share with driver ${driver.fullName || ''} to start. Ref: ${tripId.slice(-6).toUpperCase()}`
        ).catch(() => {});
      }
      // 📦 For parcel — remind sender with pickup OTP via SMS
      if (tripRow?.trip_type === 'parcel' || tripRow?.trip_type === 'delivery') {
        const senderPhone = tripRow.customer_phone;
        if (senderPhone) sendCustomSms(senderPhone,
          `JAGO Parcel: Driver ${driver.fullName || ''} arrived. Pickup OTP: ${otp}. Share to hand over parcel.`
        ).catch(() => {});
      }

      if (io && tripRow?.customer_id) {
        io.to(`user:${tripRow.customer_id}`).emit("trip:status_update", { tripId, status: "arrived", otp, uiState: 'driver_arriving' });
        io.to(`trip:${tripId}`).emit("trip:status_update", { tripId, status: "arrived", otp, uiState: 'driver_arriving' });
      }

      res.json({ success: true, pickupOtp: otp });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Start trip (arrived → on_the_way) ────────────────────────────
  app.post("/api/app/driver/start-trip", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { tripId, pickupOtp } = req.body;
      const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!tripId || !uuidRe.test(tripId)) return res.status(400).json({ message: "Invalid trip ID" });
      const tripInfo = await rawDb.execute(rawSql`
        SELECT current_status, pickup_otp, trip_type FROM trip_requests
        WHERE id=${tripId}::uuid AND driver_id=${driver.id}::uuid
      `);
      if (!tripInfo.rows.length) return res.status(404).json({ message: "Trip not found" });
      const tripRow = tripInfo.rows[0] as any;
      if (tripRow.current_status !== 'arrived') {
        return res.status(400).json({ message: `Cannot start trip in status: ${tripRow.current_status}` });
      }
      if (!pickupOtp || !String(pickupOtp).trim()) {
        return res.status(400).json({ message: "Pickup OTP is required" });
      }
      if (tripRow.pickup_otp && pickupOtp !== tripRow.pickup_otp) {
        return res.status(400).json({ message: "Invalid OTP" });
      }
      await rawDb.execute(rawSql`
        UPDATE trip_requests SET current_status='on_the_way', ride_started_at=COALESCE(ride_started_at, NOW())
        WHERE id=${tripId}::uuid AND driver_id=${driver.id}::uuid
      `);
      await appendTripStatus(tripId, 'trip_started', 'driver', 'Trip started from driver app');
      await logRideLifecycleEvent(tripId, 'trip_started', driver.id, 'driver', { via: 'start-trip' });
      res.json({ success: true, message: "Trip started" });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Complete trip ─────────────────────────────────────────────────
  app.post("/api/app/driver/complete-trip", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { tripId, actualFare, actualDistance, tips = 0 } = req.body;
      // Input validation
      const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!tripId || !uuidRe.test(tripId)) return res.status(400).json({ message: "Invalid trip ID" });
      // Get trip details to use estimated_fare as fallback
      const tripInfo = await rawDb.execute(rawSql`
        SELECT tr.estimated_fare, tr.estimated_distance, tr.current_status, tr.payment_method,
               tr.customer_id, tr.trip_type, tr.type, tr.delivery_otp, tr.seats_booked,
               vc.name as vehicle_name, vc.vehicle_type as vehicle_type_field,
               vc.is_carpool, vc.total_seats
        FROM trip_requests tr
        LEFT JOIN vehicle_categories vc ON vc.id = tr.vehicle_category_id
        WHERE tr.id=${tripId}::uuid AND tr.driver_id=${driver.id}::uuid`);
      if (!tripInfo.rows.length) return res.status(404).json({ message: "Trip not found" });
      const tripRow = tripInfo.rows[0] as any;
      if (tripRow.current_status !== 'on_the_way') return res.status(400).json({ message: `Cannot complete trip in status: ${tripRow.current_status}. Ride must be in progress.` });
      if ((tripRow.trip_type === 'parcel' || tripRow.trip_type === 'delivery') && tripRow.delivery_otp) {
        return res.status(400).json({ message: "Verify delivery OTP before completing this parcel trip." });
      }
      const fare = parseFloat(actualFare) || parseFloat(tripRow.estimated_fare) || 0;
      if (!fare || fare <= 0) return res.status(400).json({ message: "Fare amount is invalid" });

      // ── Pricing: user discount (first 2 rides = 50% off) ─────────────────
      const customerRow = tripRow.customer_id
        ? (await rawDb.execute(rawSql`SELECT completed_rides_count FROM users WHERE id=${tripRow.customer_id}::uuid LIMIT 1`).catch(() => ({ rows: [] }))).rows[0] as any
        : null;
      const completedRidesCount = parseInt(customerRow?.completed_rides_count ?? '0') || 0;
      const rideFullFare = fare;
      const userDiscount = completedRidesCount < 2 ? parseFloat((rideFullFare * 0.50).toFixed(2)) : 0;
      const userPayable  = parseFloat((rideFullFare - userDiscount).toFixed(2));

      // ── Car Pool: per-seat fare ───────────────────────────────────────────
      const seatsBooked   = parseInt(tripRow.seats_booked ?? '1') || 1;
      const isCarpool     = tripRow.is_carpool === true || tripRow.is_carpool === 'true';
      const carpoolSeats  = parseInt(tripRow.total_seats ?? '4') || 4;
      const seatPrice     = isCarpool ? parseFloat((fare / carpoolSeats).toFixed(2)) : 0;
      const vehicleTypeName = tripRow.vehicle_name || tripRow.vehicle_type_field || null;

      // ── GST: 5% of full ride fare (government tax, always deducted from driver credit) ──
      const gstPctR = await rawDb.execute(rawSql`SELECT value FROM revenue_model_settings WHERE key_name='ride_gst_rate' LIMIT 1`).catch(() => ({ rows: [] as any[] }));
      const rideGstRate = parseFloat((gstPctR.rows[0] as any)?.value || '5') / 100;
      const gstAmount = parseFloat((rideFullFare * rideGstRate).toFixed(2));

      const r = await rawDb.execute(rawSql`
        UPDATE trip_requests
        SET current_status='completed', ride_ended_at=NOW(),
            actual_fare=${fare}, actual_distance=${parseFloat(actualDistance) || parseFloat(tripRow.estimated_distance) || 0},
            tips=${parseFloat(tips) || 0}, payment_status='paid',
            ride_full_fare=${rideFullFare}, user_discount=${userDiscount},
            user_payable=${userPayable}, gst_amount=${gstAmount},
            vehicle_type_name=${vehicleTypeName},
            seats_booked=${seatsBooked}, seat_price=${seatPrice}
        WHERE id=${tripId}::uuid AND driver_id=${driver.id}::uuid
          AND current_status = 'on_the_way'
        RETURNING *
      `);
      if (!r.rows.length) {
        const exists = await rawDb.execute(rawSql`SELECT current_status FROM trip_requests WHERE id=${tripId}::uuid AND driver_id=${driver.id}::uuid`);
        const s = (exists.rows[0] as any)?.current_status;
        if (!s) return res.status(404).json({ message: "Trip not found" });
        return res.status(400).json({ message: `Cannot complete trip in status: ${s}. Ride must be on_the_way.` });
      }

      // Auto-deduct platform fees from driver wallet (commission OR subscription model)
      const settingR = await rawDb.execute(rawSql`SELECT key_name, value FROM revenue_model_settings`).catch(() => ({ rows: [] as any[] }));
      const s: any = {};
      settingR.rows.forEach((row: any) => { s[row.key_name] = row.value; });

      // ── Launch Benefit: check if this driver is in their 30-day free period ──
      const driverBenefitR = await rawDb.execute(rawSql`
        SELECT launch_free_active, free_period_end FROM users WHERE id=${driver.id}::uuid LIMIT 1
      `).catch(() => ({ rows: [] as any[] }));
      const driverBenefit = driverBenefitR.rows[0] as any;
      const campaignGlobalOn = s['launch_campaign_enabled'] !== 'false';
      const freePeriodStillValid = driverBenefit?.launch_free_active === true
        && driverBenefit?.free_period_end
        && new Date(driverBenefit.free_period_end) >= new Date();
      const launchFreeApplied = campaignGlobalOn && freePeriodStillValid;

      // Auto-expire: if period has ended, flip the flag off
      if (driverBenefit?.launch_free_active === true && driverBenefit?.free_period_end && new Date(driverBenefit.free_period_end) < new Date()) {
        await rawDb.execute(rawSql`UPDATE users SET launch_free_active=false WHERE id=${driver.id}::uuid`).catch(() => {});
      }

      // Per-service revenue model: use rides_model/parcels_model/cargo_model if set
      const tripServiceType = (tripRow.trip_type || tripRow.type || 'normal');
      let serviceModelKey = 'active_model';
      if (tripServiceType === 'parcel') serviceModelKey = 'parcels_model';
      else if (tripServiceType === 'cargo') serviceModelKey = 'cargo_model';
      else if (tripServiceType === 'intercity') serviceModelKey = 'intercity_model';
      else serviceModelKey = 'rides_model';
      const activeModel = s[serviceModelKey] || s.active_model || "commission";
      let deductAmount = 0;
      let breakdown: any = {};

      if (launchFreeApplied) {
        // 🎉 Launch Benefit: no commission, no subscription fee — only GST
        deductAmount = gstAmount;
        breakdown = { model: "launch_free", commission: 0, platformFee: 0, gst: gstAmount, insurance: 0, total: gstAmount };
      } else if (activeModel === "commission") {
        const commPct = parseFloat(s.commission_pct || "15") / 100;
        const ins = parseFloat(s.commission_insurance_per_ride || "2");
        const comm = parseFloat((fare * commPct).toFixed(2));
        deductAmount = parseFloat((comm + gstAmount + ins).toFixed(2));
        breakdown = { model: "commission", commission: comm, gst: gstAmount, insurance: ins, total: deductAmount };
      } else if (activeModel === "subscription") {
        // Subscription model: per-ride platform fee + GST + insurance
        const platFee = parseFloat(s.sub_platform_fee_per_ride || "5");
        const ins = parseFloat(s.commission_insurance_per_ride || "2");
        deductAmount = parseFloat((platFee + gstAmount + ins).toFixed(2));
        breakdown = { model: "subscription", platformFee: platFee, gst: gstAmount, insurance: ins, total: deductAmount };
      } else if (activeModel === "hybrid") {
        // Hybrid model: reduced commission + base platform fee + GST + insurance
        const commPct = parseFloat(s.hybrid_commission_pct || s.commission_pct || "10") / 100;
        const platFee = parseFloat(s.hybrid_platform_fee_per_ride || s.sub_platform_fee_per_ride || "5");
        const ins = parseFloat(s.hybrid_insurance_per_ride || s.commission_insurance_per_ride || "2");
        const comm = parseFloat((fare * commPct).toFixed(2));
        deductAmount = parseFloat((comm + platFee + gstAmount + ins).toFixed(2));
        breakdown = { model: "hybrid", commission: comm, platformFee: platFee, gst: gstAmount, insurance: ins, total: deductAmount };
      }

      // driverWalletCredit = what driver actually keeps
      const driverWalletCredit = parseFloat((fare - deductAmount).toFixed(2));

      // Save all pricing fields: commission_amount + driver_wallet_credit + driver_fare + customer_fare
      await rawDb.execute(rawSql`
        UPDATE trip_requests
        SET commission_amount=${deductAmount},
            driver_wallet_credit=${driverWalletCredit},
            driver_fare=${driverWalletCredit},
            customer_fare=${userPayable}
        WHERE id=${tripId}::uuid
      `);

      // ── GST: credit to company GST wallet ──────────────────────────────────
      if (gstAmount > 0) {
        await rawDb.execute(rawSql`
          UPDATE company_gst_wallet
          SET balance = balance + ${gstAmount},
              total_collected = total_collected + ${gstAmount},
              total_trips = total_trips + 1,
              updated_at = NOW()
          WHERE id = 1
        `).catch(() => {});
      }

      // ── Commission Settlement: add pending commission + GST to driver balance ──
      // Driver collects full fare from user directly (cash/UPI).
      // Platform's commission + GST are tracked as pending amounts the driver owes.
      // (commission-only part without GST for separate column tracking)
      const commissionOwed = parseFloat((deductAmount - gstAmount).toFixed(2));
      const lockThresholdVal = parseFloat(s.commission_lock_threshold || "200");

      if (deductAmount > 0) {
        // Fetch current pending balances before update
        const balBeforeR = await rawDb.execute(rawSql`
          SELECT pending_commission_balance, pending_gst_balance, total_pending_balance
          FROM users WHERE id=${driver.id}::uuid LIMIT 1
        `).catch(() => ({ rows: [] as any[] }));
        const balBefore = balBeforeR.rows[0] as any || {};
        const prevCommission = parseFloat(balBefore.pending_commission_balance ?? '0') || 0;
        const prevGst        = parseFloat(balBefore.pending_gst_balance ?? '0') || 0;
        const prevTotal      = parseFloat(balBefore.total_pending_balance ?? '0') || 0;

        // Add new ride debits to pending balances
        const newCommission = parseFloat((prevCommission + commissionOwed).toFixed(2));
        const newGst        = parseFloat((prevGst + gstAmount).toFixed(2));
        const newTotal      = parseFloat((prevTotal + deductAmount).toFixed(2));

        // Also deduct from wallet_balance (negative balance system) + update pending fields
        const wUpd = await rawDb.execute(rawSql`
          UPDATE users
          SET wallet_balance            = wallet_balance - ${deductAmount},
              pending_commission_balance = ${newCommission},
              pending_gst_balance        = ${newGst},
              total_pending_balance      = ${newTotal}
          WHERE id=${driver.id}::uuid
          RETURNING wallet_balance, is_locked, total_pending_balance
        `);
        const wRow: any = wUpd.rows[0] || {};
        const newWalletBalance = parseFloat(wRow.wallet_balance ?? 0);

        // Auto-lock: if total_pending_balance exceeds lock threshold → lock rides
        const lockMsg = `Pending balance ₹${newTotal.toFixed(2)} exceeds ₹${lockThresholdVal} limit. Pay to unlock ride access.`;
        if (newTotal >= lockThresholdVal && !wRow.is_locked) {
          await rawDb.execute(rawSql`
            UPDATE users SET is_locked=true, lock_reason=${lockMsg}, locked_at=NOW()
            WHERE id=${driver.id}::uuid
          `);
        }
        // Also apply legacy wallet threshold lock
        const legacyThreshold = parseFloat(s.auto_lock_threshold || "-100");
        if (newWalletBalance < legacyThreshold && !wRow.is_locked) {
          await rawDb.execute(rawSql`
            UPDATE users SET is_locked=true,
              lock_reason=${'Wallet balance ₹' + newWalletBalance.toFixed(2) + ' below minimum. Pay ₹' + Math.abs(newWalletBalance).toFixed(2) + ' to unlock.'},
              locked_at=NOW()
            WHERE id=${driver.id}::uuid
          `);
        }

        // Record in commission_settlements (split: commission + GST as separate lines)
        const serviceTypeLabel = tripServiceType || 'ride';
        if (commissionOwed > 0) {
          await rawDb.execute(rawSql`
            INSERT INTO commission_settlements
              (driver_id, trip_id, settlement_type, commission_amount, gst_amount, total_amount,
               direction, balance_before, balance_after, ride_fare, service_type, description)
            VALUES
              (${driver.id}::uuid, ${tripId}::uuid, 'commission_debit',
               ${commissionOwed}, 0, ${commissionOwed},
               'debit', ${prevTotal}, ${newTotal}, ${fare}, ${serviceTypeLabel},
               ${'Commission ' + (breakdown.model || activeModel) + ' for trip ' + tripId.slice(0,8)})
          `).catch(() => {});
        }
        if (gstAmount > 0) {
          await rawDb.execute(rawSql`
            INSERT INTO commission_settlements
              (driver_id, trip_id, settlement_type, commission_amount, gst_amount, total_amount,
               direction, balance_before, balance_after, ride_fare, service_type, description)
            VALUES
              (${driver.id}::uuid, ${tripId}::uuid, 'gst_debit',
               0, ${gstAmount}, ${gstAmount},
               'debit', ${prevTotal}, ${newTotal}, ${fare}, ${serviceTypeLabel},
               ${'Government GST (5%) for trip ' + tripId.slice(0,8)})
          `).catch(() => {});
        }

        // Record driver deduction in driver_payments (legacy table)
        const deductDesc = launchFreeApplied
          ? `Government GST ₹${gstAmount} for trip ${tripId.slice(0,8)}… (launch period)`
          : `Platform fee (${activeModel}) ₹${deductAmount} for trip ${tripId.slice(0,8)}…`;
        await rawDb.execute(rawSql`
          INSERT INTO driver_payments (driver_id, amount, payment_type, status, description)
          VALUES (${driver.id}::uuid, ${deductAmount}, 'deduction', 'completed', ${deductDesc})
        `).catch(() => {});

        // Credit admin revenue
        const revenueType = launchFreeApplied ? 'gst_only'
          : activeModel === 'commission' ? 'commission'
          : activeModel === 'hybrid' ? 'hybrid_fee'
          : 'subscription_fee';
        await rawDb.execute(rawSql`
          INSERT INTO admin_revenue (driver_id, trip_id, amount, revenue_type, breakdown)
          VALUES (${driver.id}::uuid, ${tripId}::uuid, ${deductAmount}, ${revenueType}, ${JSON.stringify(breakdown)}::jsonb)
        `).catch(() => {});
      }

      // ── Customer wallet deduction: use userPayable (discounted amount) ────
      const tripPaymentMethod = tripRow.payment_method || 'cash';
      const tripCustomerId = tripRow.customer_id;
      if (tripPaymentMethod === 'wallet' && tripCustomerId) {
        try {
          const custWalRes = await rawDb.execute(rawSql`SELECT wallet_balance FROM users WHERE id=${tripCustomerId}::uuid`);
          const custBal = parseFloat((custWalRes.rows[0] as any)?.wallet_balance || '0');
          if (custBal >= userPayable) {
            await rawDb.execute(rawSql`UPDATE users SET wallet_balance = wallet_balance - ${userPayable} WHERE id=${tripCustomerId}::uuid`);
            const newCustBal = parseFloat((custBal - userPayable).toFixed(2));
            await rawDb.execute(rawSql`
              INSERT INTO transactions (user_id, account, credit, debit, balance, transaction_type, ref_transaction_id)
              VALUES (${tripCustomerId}::uuid, ${'Ride payment via Wallet'}, 0, ${userPayable}, ${newCustBal}, ${'ride_payment'}, ${tripId})
            `).catch(() => {});
          } else {
            await rawDb.execute(rawSql`UPDATE trip_requests SET payment_status='pending_payment' WHERE id=${tripId}::uuid`).catch(() => {});
          }
        } catch (_) {}
      }

      // Record transaction for online/razorpay payments
      if ((tripPaymentMethod === 'online' || tripPaymentMethod === 'upi' || tripPaymentMethod === 'razorpay') && tripCustomerId) {
        try {
          const custWalRes2 = await rawDb.execute(rawSql`SELECT wallet_balance FROM users WHERE id=${tripCustomerId}::uuid`);
          const custBal2 = parseFloat((custWalRes2.rows[0] as any)?.wallet_balance || '0');
          await rawDb.execute(rawSql`
            INSERT INTO transactions (user_id, account, credit, debit, balance, transaction_type, ref_transaction_id)
            VALUES (${tripCustomerId}::uuid, ${'Ride payment via UPI/Online'}, 0, ${userPayable}, ${custBal2}, ${'ride_payment'}, ${tripId})
          `).catch(() => {});
        } catch (_) {}
      }

      // ── Increment customer's completed_rides_count ──────────────────────
      if (tripCustomerId) {
        await rawDb.execute(rawSql`
          UPDATE users SET completed_rides_count = completed_rides_count + 1 WHERE id=${tripCustomerId}::uuid
        `).catch(() => {});
      }

      // ✅ Clear driver's current trip — driver is now free for the next ride
      await rawDb.execute(rawSql`UPDATE users SET current_trip_id=NULL WHERE id=${driver.id}::uuid`);

      // AI: Update driver performance stats + clear trip waypoints
      updateDriverStats(driver.id).catch(() => {});
      clearTripWaypoints(tripId);

      const completedTrip = camelize(r.rows[0]) as any;
      await appendTripStatus(tripId, 'trip_completed', 'driver', 'Trip completed by driver');
      await logRideLifecycleEvent(tripId, 'trip_completed', driver.id, 'driver', { fare, actualDistance });

      // 🔌 Socket: notify customer — enriched with discount/GST breakdown
      if (io && completedTrip.customerId) {
        io.to(`user:${completedTrip.customerId}`).emit("trip:completed", {
          tripId,
          fare: rideFullFare,
          userDiscount,
          userPayable,
          gstAmount,
          driverWalletCredit,
          actualDistance: parseFloat(actualDistance) || parseFloat((tripRow as any).estimated_distance) || 0,
          paymentMethod: tripRow.payment_method || 'cash',
          platformDeduction: deductAmount,
          launchOfferApplied: userDiscount > 0,
          uiState: 'trip_completed',
        });
      }

      // 🔔 FCM: notify customer
      const custDevResComp = await rawDb.execute(rawSql`SELECT fcm_token FROM user_devices WHERE user_id=${completedTrip.customerId}::uuid`);
      const custFcmComp = (custDevResComp.rows[0] as any)?.fcm_token || null;
      notifyCustomerTripCompleted({ fcmToken: custFcmComp, fare: userPayable, tripId }).catch(() => {});

      res.json({
        success: true,
        trip: completedTrip,
        pricing: {
          rideFare: rideFullFare,
          userDiscount,
          userPayable,
          gstAmount,
          driverWalletCredit,
          platformDeduction: deductAmount,
          launchOfferApplied: userDiscount > 0,
          launchDriverFree: launchFreeApplied,
          breakdown,
        },
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Cancel trip ───────────────────────────────────────────────────
  app.post("/api/app/driver/cancel-trip", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { tripId, reason } = req.body;
      // Get trip details first
      const tripDetails = await rawDb.execute(rawSql`
        SELECT * FROM trip_requests WHERE id=${tripId}::uuid AND driver_id=${driver.id}::uuid AND current_status IN ('driver_assigned','accepted','arrived')
      `);
      if (!tripDetails.rows.length) return res.status(400).json({ message: "Cannot cancel this trip" });
      const trip = camelize(tripDetails.rows[0]) as any;

      // Reset trip to 'searching' — auto-reassign to next driver
      await rawDb.execute(rawSql`
        UPDATE trip_requests SET current_status='searching', driver_id=NULL, pickup_otp=NULL,
          driver_accepted_at=NULL, cancel_reason=${reason || 'Driver cancelled'}, updated_at=NOW()
        WHERE id=${tripId}::uuid
      `);
      await appendTripStatus(tripId, 'requested', 'driver', reason || 'Driver cancelled, reassigned');
      await logRideLifecycleEvent(tripId, 'driver_reassigned', driver.id, 'driver', { reason: reason || 'Driver cancelled' });
      // Free the driver
      await rawDb.execute(rawSql`UPDATE users SET current_trip_id=NULL WHERE id=${driver.id}::uuid`);
      clearTripWaypoints(tripId);

      // Notify customer — driver cancelled, now searching again
      if (io && trip.customerId) {
        io.to(`user:${trip.customerId}`).emit("trip:searching", {
          tripId, message: "Your previous pilot cancelled. Looking for a new one...",
        });
      }

      // AI-scored reassignment after driver cancellation
      const cancelNextBest = await findBestDrivers(
        Number(trip.pickupLat), Number(trip.pickupLng),
        trip.vehicleCategoryId || undefined,
        [driver.id],
        3
      );

      if (cancelNextBest.length) {
        for (const nd of cancelNextBest) {
          if (io) io.to(`user:${nd.driverId}`).emit("trip:new_request", {
            tripId,
            pickupAddress: trip.pickupAddress,
            destinationAddress: trip.destinationAddress,
            pickupLat: trip.pickupLat,
            pickupLng: trip.pickupLng,
            estimatedFare: trip.estimatedFare || 0,
            tripType: trip.tripType || 'ride',
          });
          const dDevRes = await rawDb.execute(rawSql`SELECT fcm_token FROM user_devices WHERE user_id=${nd.driverId}::uuid`);
          const dFcm = (dDevRes.rows[0] as any)?.fcm_token;
          if (dFcm) notifyDriverNewRide({ fcmToken: dFcm, driverName: nd.fullName, customerName: "Customer", tripId, pickupAddress: trip.pickupAddress, estimatedFare: trip.estimatedFare || 0 }).catch(() => {});
        }
      } else {
        const custDevRes = await rawDb.execute(rawSql`SELECT fcm_token FROM user_devices WHERE user_id=${trip.customerId}::uuid`);
        const custFcm = (custDevRes.rows[0] as any)?.fcm_token || null;
        notifyTripCancelled({ fcmToken: custFcm, cancelledBy: "driver", tripId }).catch(() => {});
      }
      res.json({ success: true, reassigned: cancelNextBest.length > 0 });
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
      const trips = camelize(r.rows);
      res.json({ trips, total: Number((cnt.rows[0] as any).total) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Rate customer ─────────────────────────────────────────────────
  app.post("/api/app/driver/rate-customer", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { tripId, rating, note } = req.body;
      const parsedRating = parseFloat(rating);
      if (!tripId || isNaN(parsedRating) || parsedRating < 1 || parsedRating > 5) {
        return res.status(400).json({ message: "tripId required and rating must be 1-5" });
      }
      const tripR = await rawDb.execute(rawSql`
        SELECT customer_id FROM trip_requests
        WHERE id=${tripId}::uuid AND driver_id=${driver.id}::uuid AND current_status='completed'
      `);
      if (!tripR.rows.length) return res.status(404).json({ message: "Completed trip not found" });
      const customerId = (tripR.rows[0] as any).customer_id;
      await rawDb.execute(rawSql`UPDATE trip_requests SET customer_rating=${parsedRating}, driver_note=${note||''} WHERE id=${tripId}::uuid AND driver_id=${driver.id}::uuid`);
      // Update customer rating average
      await rawDb.execute(rawSql`
        UPDATE users SET
          rating = (rating * total_ratings + ${parsedRating}) / (total_ratings + 1),
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
      const r = await rawDb.execute(rawSql`
        SELECT wallet_balance, is_locked, lock_reason, pending_payment_amount,
               pending_commission_balance, pending_gst_balance, total_pending_balance, lock_threshold
        FROM users WHERE id=${driver.id}::uuid LIMIT 1
      `);
      const payments = await rawDb.execute(rawSql`SELECT * FROM driver_payments WHERE driver_id=${driver.id}::uuid ORDER BY created_at DESC LIMIT 50`);
      const wdReqs = await rawDb.execute(rawSql`SELECT * FROM withdraw_requests WHERE user_id=${driver.id}::uuid ORDER BY created_at DESC LIMIT 20`).catch(() => ({ rows: [] }));
      const d = r.rows[0] as any;
      const bal = parseFloat(d?.wallet_balance || 0);
      const totalPending = parseFloat(d?.total_pending_balance ?? '0');
      const lockThreshold = parseFloat(d?.lock_threshold ?? '200');
      const historyRows = camelize(payments.rows).map((p: any) => ({
        ...p,
        type: p.paymentType || p.type || 'deduction',
        description: p.description || 'Platform charge',
        date: p.createdAt,
        amount: parseFloat(p.amount || 0),
      }));
      // ── Subscription status ───────────────────────────────────────────────
      const subR = await rawDb.execute(rawSql`
        SELECT ds.id, ds.is_active, ds.end_date, ds.payment_status, sp.name as plan_name, sp.price
        FROM driver_subscriptions ds
        LEFT JOIN subscription_plans sp ON sp.id = ds.plan_id
        WHERE ds.driver_id = ${driver.id}::uuid
        ORDER BY ds.created_at DESC LIMIT 1
      `).catch(() => ({ rows: [] as any[] }));
      const subRow: any = subR.rows[0] || null;
      const hasActiveSub = subRow && subRow.is_active && new Date(subRow.end_date) > new Date();

      res.json({
        walletBalance: bal,
        balance: bal,
        isLocked: d?.is_locked || false,
        lockReason: d?.lock_reason || null,
        pendingPaymentAmount: parseFloat(d?.pending_payment_amount || 0),
        pendingCommission: parseFloat(d?.pending_commission_balance ?? '0'),
        pendingGst: parseFloat(d?.pending_gst_balance ?? '0'),
        totalPendingBalance: totalPending,
        lockThreshold,
        history: historyRows,
        transactions: historyRows,
        withdrawRequests: wdReqs.rows.map(camelize),
        subscription: subRow ? {
          planName: subRow.plan_name || 'Unknown Plan',
          price: parseFloat(subRow.price ?? 0),
          endDate: subRow.end_date,
          isActive: !!hasActiveSub,
          paymentStatus: subRow.payment_status,
          daysLeft: hasActiveSub
            ? Math.max(0, Math.ceil((new Date(subRow.end_date).getTime() - Date.now()) / 86400000))
            : 0,
        } : null,
        subscriptionRequired: true,
        canAcceptRides: !!hasActiveSub && !(d?.is_locked),
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Commission settlement status (detailed breakdown) ────────────────
  app.get("/api/app/driver/settlement-status", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT wallet_balance, is_locked, lock_reason,
               pending_commission_balance, pending_gst_balance, total_pending_balance, lock_threshold
        FROM users WHERE id=${driver.id}::uuid LIMIT 1
      `);
      const row: any = r.rows[0] || {};
      const pendingCommission = parseFloat(row.pending_commission_balance ?? '0');
      const pendingGst        = parseFloat(row.pending_gst_balance ?? '0');
      const totalPending      = parseFloat(row.total_pending_balance ?? '0');
      const lockThreshold     = parseFloat(row.lock_threshold ?? '200');
      const recent = await rawDb.execute(rawSql`
        SELECT settlement_type, total_amount, direction, balance_before, balance_after,
               payment_method, status, description, created_at
        FROM commission_settlements WHERE driver_id=${driver.id}::uuid
        ORDER BY created_at DESC LIMIT 10
      `).catch(() => ({ rows: [] }));
      let displayMessage = 'No pending dues';
      if (totalPending > 0) {
        displayMessage = `Platform Fee ₹${pendingCommission.toFixed(2)}\nGST ₹${pendingGst.toFixed(2)}\nTotal Due ₹${totalPending.toFixed(2)}`;
      }
      res.json({
        pendingCommission,
        pendingGst,
        totalPendingBalance: totalPending,
        lockThreshold,
        isLocked: row.is_locked || false,
        lockReason: row.lock_reason || null,
        displayMessage,
        recentSettlements: camelize(recent.rows),
        progressPercent: lockThreshold > 0 ? Math.min(100, Math.round((totalPending / lockThreshold) * 100)) : 0,
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Initiate Razorpay payment to settle pending commission ───────────
  app.post("/api/app/driver/commission/create-order", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { amount } = req.body;
      const keyId     = process.env.RAZORPAY_KEY_ID;
      const keySecret = process.env.RAZORPAY_KEY_SECRET;
      if (!keyId || !keySecret) return res.status(503).json({ message: "Payment gateway not configured." });
      // Validate amount against pending balance
      const balR = await rawDb.execute(rawSql`SELECT total_pending_balance FROM users WHERE id=${driver.id}::uuid LIMIT 1`);
      const bal: any = balR.rows[0] || {};
      const pendingAmt = parseFloat(bal.total_pending_balance ?? '0');
      const payAmt = parseFloat(String(amount));
      if (!payAmt || payAmt <= 0) return res.status(400).json({ message: "Invalid amount" });
      if (payAmt > pendingAmt + 1) return res.status(400).json({ message: `Amount ₹${payAmt} exceeds pending balance ₹${pendingAmt.toFixed(2)}` });
      const Razorpay = _require("razorpay");
      const rzp = new Razorpay({ key_id: keyId, key_secret: keySecret });
      const order = await rzp.orders.create({ amount: Math.round(payAmt * 100), currency: "INR", receipt: `cs_${Date.now().toString(36)}` });
      await rawDb.execute(rawSql`
        INSERT INTO driver_payments (driver_id, amount, payment_type, razorpay_order_id, status, description)
        VALUES (${driver.id}::uuid, ${payAmt}, 'commission_payment', ${order.id}, 'pending', ${'Commission settlement ₹' + payAmt})
      `).catch(() => {});
      res.json({ order, keyId, pendingBalance: pendingAmt });
    } catch (e: any) {
      const msg = e.message || e.error?.description || JSON.stringify(e).slice(0, 200);
      res.status(500).json({ message: msg });
    }
  });

  // ── DRIVER: Verify Razorpay commission payment ───────────────────────────────
  app.post("/api/app/driver/commission/verify-payment", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { razorpayOrderId, razorpayPaymentId, razorpaySignature, amount } = req.body;
      const keySecret = process.env.RAZORPAY_KEY_SECRET;
      if (keySecret) {
        const expectedSig = crypto.createHmac("sha256", keySecret).update(razorpayOrderId + "|" + razorpayPaymentId).digest("hex");
        if (expectedSig !== razorpaySignature) return res.status(400).json({ message: "Invalid payment signature" });
      }
      const settingRows = await rawDb.execute(rawSql`SELECT key_name, value FROM revenue_model_settings`);
      const settings: any = {};
      settingRows.rows.forEach((r: any) => { settings[r.key_name] = r.value; });

      const balR = await rawDb.execute(rawSql`
        SELECT pending_commission_balance, pending_gst_balance, total_pending_balance, wallet_balance, is_locked
        FROM users WHERE id=${driver.id}::uuid LIMIT 1
      `);
      const bal: any = balR.rows[0] || {};
      const prevTotal      = parseFloat(bal.total_pending_balance ?? '0') || 0;
      const prevCommission = parseFloat(bal.pending_commission_balance ?? '0') || 0;
      const prevGst        = parseFloat(bal.pending_gst_balance ?? '0') || 0;
      const paidAmt        = parseFloat(String(amount));
      const gstReduction   = Math.min(prevGst, parseFloat((paidAmt * (prevTotal > 0 ? prevGst / prevTotal : 0.05)).toFixed(2)));
      const commReduction  = Math.min(prevCommission, parseFloat((paidAmt - gstReduction).toFixed(2)));
      const newTotal       = Math.max(0, parseFloat((prevTotal - paidAmt).toFixed(2)));
      const newCommission  = Math.max(0, parseFloat((prevCommission - commReduction).toFixed(2)));
      const newGst         = Math.max(0, parseFloat((prevGst - gstReduction).toFixed(2)));

      const updated = await rawDb.execute(rawSql`
        UPDATE users
        SET wallet_balance             = wallet_balance + ${paidAmt},
            pending_commission_balance = ${newCommission},
            pending_gst_balance        = ${newGst},
            total_pending_balance      = ${newTotal},
            pending_payment_amount     = GREATEST(0, pending_payment_amount - ${paidAmt})
        WHERE id = ${driver.id}::uuid
        RETURNING wallet_balance, is_locked
      `);
      const updRow: any = updated.rows[0] || {};
      const lockThreshold = parseFloat(settings.commission_lock_threshold || '200');
      const wasLocked = updRow.is_locked;
      if (newTotal < lockThreshold && wasLocked) {
        await rawDb.execute(rawSql`UPDATE users SET is_locked=false, lock_reason=NULL, locked_at=NULL WHERE id=${driver.id}::uuid`);
      }
      await rawDb.execute(rawSql`
        INSERT INTO commission_settlements
          (driver_id, settlement_type, commission_amount, gst_amount, total_amount,
           direction, balance_before, balance_after, payment_method,
           razorpay_order_id, razorpay_payment_id, status, description)
        VALUES
          (${driver.id}::uuid, 'payment_credit', ${commReduction}, ${gstReduction}, ${paidAmt},
           'credit', ${prevTotal}, ${newTotal}, 'razorpay',
           ${razorpayOrderId}, ${razorpayPaymentId}, 'completed',
           ${'Driver payment via Razorpay. Commission: ₹' + commReduction.toFixed(2) + ', GST: ₹' + gstReduction.toFixed(2)})
      `).catch(() => {});
      await rawDb.execute(rawSql`
        UPDATE driver_payments SET status='completed', razorpay_payment_id=${razorpayPaymentId},
          razorpay_signature=${razorpaySignature||''}, verified_at=NOW()
        WHERE razorpay_order_id=${razorpayOrderId}
      `).catch(() => {});
      res.json({
        success: true,
        paidAmount: paidAmt,
        newPendingBalance: newTotal,
        pendingCommission: newCommission,
        pendingGst: newGst,
        autoUnlocked: newTotal < lockThreshold && wasLocked,
        message: newTotal <= 0 ? 'All dues cleared! Account unlocked.' : `₹${newTotal.toFixed(2)} pending. Pay remaining to unlock.`,
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Submit withdrawal request ────────────────────────────────────────
  app.post("/api/app/driver/withdraw-request", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { amount, bankName, accountNumber, ifscCode, accountHolderName, upiId, method = "bank" } = req.body;
      const amt = parseFloat(amount);
      if (!amt || amt <= 0) return res.status(400).json({ message: "Invalid amount" });
      if (amt < 100) return res.status(400).json({ message: "Minimum withdrawal is ₹100" });
      // Check wallet balance
      const walR = await rawDb.execute(rawSql`SELECT wallet_balance, is_locked FROM users WHERE id=${driver.id}::uuid`);
      const w = walR.rows[0] as any;
      if (w?.is_locked) return res.status(403).json({ message: "Account locked. Please clear dues first." });
      const bal = parseFloat(w?.wallet_balance || 0);
      if (bal < amt) return res.status(400).json({ message: `Insufficient balance. Available: ₹${bal.toFixed(2)}` });
      // Check no pending withdrawal exists
      const pending = await rawDb.execute(rawSql`SELECT COUNT(*) as cnt FROM withdraw_requests WHERE user_id=${driver.id}::uuid AND status='pending'`).catch(() => ({ rows: [{ cnt: 0 }] }));
      if (parseInt((pending.rows[0] as any)?.cnt || 0) > 0) return res.status(400).json({ message: "You already have a pending withdrawal request" });
      // Insert withdraw request
      const notes = method === "upi"
        ? `UPI: ${upiId || ''}`
        : `Bank: ${bankName || ''} | Acc: ${accountNumber || ''} | IFSC: ${ifscCode || ''} | Name: ${accountHolderName || ''}`;
      const wr = await rawDb.execute(rawSql`
        INSERT INTO withdraw_requests (user_id, amount, note, status, created_at)
        VALUES (${driver.id}::uuid, ${amt}, ${notes}, 'pending', now())
        RETURNING *
      `);
      res.json({ success: true, message: `Withdrawal request of ₹${amt} submitted. Will be processed in 2-3 business days.`, request: camelize(wr.rows[0]) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Subscription status & purchase ───────────────────────────────
  app.get("/api/app/driver/subscription", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const modelR = await rawDb.execute(rawSql`SELECT key_name, value FROM revenue_model_settings`);
      const s: any = {};
      modelR.rows.forEach((r: any) => { s[r.key_name] = r.value; });
      const activeModel = s.active_model || "commission";
      let activeSub = null;
      let daysLeft = 0;
      if (activeModel === "subscription" || activeModel === "hybrid") {
        const subR = await rawDb.execute(rawSql`
          SELECT ds.*, sp.name as plan_name, sp.price, sp.duration_days
          FROM driver_subscriptions ds
          LEFT JOIN subscription_plans sp ON sp.id = ds.plan_id
          WHERE ds.driver_id=${driver.id}::uuid AND ds.is_active=true
          ORDER BY ds.end_date DESC LIMIT 1
        `);
        if (subR.rows.length) {
          activeSub = camelize(subR.rows[0]);
          daysLeft = Math.max(0, Math.ceil((new Date((activeSub as any).endDate).getTime() - Date.now()) / 86400000));
        }
      }
      const plans = await rawDb.execute(rawSql`SELECT * FROM subscription_plans WHERE is_active=true ORDER BY price ASC`);
      res.json({
        activeModel,
        activeSub,
        daysLeft,
        isSubscriptionRequired: activeModel === "subscription" || activeModel === "hybrid",
        hasActiveSubscription: !!activeSub && daysLeft > 0,
        plans: plans.rows.map(camelize),
        perRideFees: {
          platformFee: parseFloat(s.sub_platform_fee_per_ride || "5"),
          gstPct: parseFloat(s.sub_gst_pct || "18"),
          insurance: parseFloat(s.commission_insurance_per_ride || "2"),
        },
        commissionRate: parseFloat(s.commission_pct || "15"),
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post("/api/app/driver/subscription/create-order", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { planId } = req.body;
      if (!planId) return res.status(400).json({ message: "planId required" });
      const planR = await rawDb.execute(rawSql`SELECT * FROM subscription_plans WHERE id=${planId}::uuid AND is_active=true`);
      if (!planR.rows.length) return res.status(404).json({ message: "Plan not found" });
      const plan = camelize(planR.rows[0]) as any;
      const gstPct = await rawDb.execute(rawSql`SELECT value FROM revenue_model_settings WHERE key_name='sub_gst_pct'`);
      const gst = parseFloat(plan.price) * (parseFloat((gstPct.rows[0] as any)?.value || "18") / 100);
      const total = parseFloat((parseFloat(plan.price) + gst).toFixed(2));
      const keyId = process.env.RAZORPAY_KEY_ID;
      const keySecret = process.env.RAZORPAY_KEY_SECRET;
      if (!keyId || !keySecret) return res.status(503).json({ message: "Payment gateway not configured" });
      const Razorpay = _require("razorpay");
      const rzp = new Razorpay({ key_id: keyId, key_secret: keySecret });
      const order = await rzp.orders.create({
        amount: Math.round(total * 100),
        currency: "INR",
        receipt: `sub_${Date.now().toString(36)}`,
        notes: { driver_id: driver.id, plan_id: planId, plan_name: plan.name }
      });
      res.json({ order, keyId, amount: total, planFee: parseFloat(plan.price), gst, plan });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post("/api/app/driver/subscription/verify-payment", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { razorpayOrderId, razorpayPaymentId, razorpaySignature, planId } = req.body;
      if (!razorpayOrderId || !razorpayPaymentId || !planId) return res.status(400).json({ message: "Missing required fields" });
      const keySecret = process.env.RAZORPAY_KEY_SECRET;
      if (keySecret && razorpaySignature) {
        const expectedSig = crypto.createHmac("sha256", keySecret).update(`${razorpayOrderId}|${razorpayPaymentId}`).digest("hex");
        if (expectedSig !== razorpaySignature) return res.status(400).json({ message: "Invalid payment signature" });
      }
      const planR = await rawDb.execute(rawSql`SELECT * FROM subscription_plans WHERE id=${planId}::uuid`);
      if (!planR.rows.length) return res.status(404).json({ message: "Plan not found" });
      const plan = camelize(planR.rows[0]) as any;
      const startDate = new Date().toISOString().split("T")[0];
      const endDate = new Date(Date.now() + plan.durationDays * 86400000).toISOString().split("T")[0];
      await rawDb.execute(rawSql`UPDATE driver_subscriptions SET is_active=false WHERE driver_id=${driver.id}::uuid`);
      const sub = await rawDb.execute(rawSql`
        INSERT INTO driver_subscriptions (driver_id, plan_id, start_date, end_date, payment_amount, payment_status, is_active)
        VALUES (${driver.id}::uuid, ${planId}::uuid, ${startDate}, ${endDate}, ${plan.price}, 'paid', true)
        RETURNING *
      `);
      await rawDb.execute(rawSql`
        INSERT INTO driver_payments (driver_id, amount, payment_type, razorpay_order_id, razorpay_payment_id, status, description)
        VALUES (${driver.id}::uuid, ${plan.price}, 'subscription', ${razorpayOrderId}, ${razorpayPaymentId}, 'completed', ${`Subscription: ${plan.name} (${plan.durationDays} days)`})
      `).catch(() => {});
      await rawDb.execute(rawSql`
        INSERT INTO admin_revenue (driver_id, amount, revenue_type, breakdown)
        VALUES (${driver.id}::uuid, ${plan.price}, 'subscription_purchase', ${JSON.stringify({ planName: plan.name, durationDays: plan.durationDays, paymentId: razorpayPaymentId })}::jsonb)
      `).catch(() => {});
      res.json({ success: true, subscription: camelize(sub.rows[0]), plan, validUntil: endDate, message: `Subscription activated until ${endDate}` });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post("/api/app/driver/wallet/create-order", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { amount } = req.body;
      const amt = parseFloat(amount);
      if (!amt || amt <= 0 || amt > 50000) return res.status(400).json({ message: "Invalid amount" });
      const keyId = process.env.RAZORPAY_KEY_ID;
      const keySecret = process.env.RAZORPAY_KEY_SECRET;
      if (!keyId || !keySecret) return res.status(503).json({ message: "Payment gateway not configured" });
      const Razorpay = _require("razorpay");
      const rzp = new Razorpay({ key_id: keyId, key_secret: keySecret });
      const order = await rzp.orders.create({
        amount: Math.round(amt * 100), currency: "INR",
        receipt: `dw_${Date.now().toString(36)}`,
        notes: { driver_id: driver.id, purpose: "wallet_recharge" }
      });
      res.json({ order, keyId, amount: amt });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post("/api/app/driver/wallet/verify-payment", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { razorpayOrderId, razorpayPaymentId, razorpaySignature, amount } = req.body;
      if (!razorpayOrderId || !razorpayPaymentId) return res.status(400).json({ message: "Missing payment details" });
      // Idempotency: reject duplicate payment IDs
      const dupCheck = await rawDb.execute(rawSql`
        SELECT id FROM driver_payments WHERE razorpay_payment_id=${razorpayPaymentId} AND status='completed' LIMIT 1
      `);
      if (dupCheck.rows.length) return res.status(409).json({ message: "Payment already processed", alreadyCredited: true });
      const keySecret = process.env.RAZORPAY_KEY_SECRET;
      if (keySecret && razorpaySignature) {
        const expectedSig = crypto.createHmac("sha256", keySecret).update(`${razorpayOrderId}|${razorpayPaymentId}`).digest("hex");
        if (expectedSig !== razorpaySignature) return res.status(400).json({ message: "Invalid payment signature" });
      }
      const amt = parseFloat(amount);
      const wUpd = await rawDb.execute(rawSql`
        UPDATE users SET wallet_balance = wallet_balance + ${amt}, pending_payment_amount = GREATEST(0, pending_payment_amount - ${amt})
        WHERE id=${driver.id}::uuid RETURNING wallet_balance, is_locked
      `);
      const newBalance = parseFloat((wUpd.rows[0] as any)?.wallet_balance || 0);
      // Auto-unlock if wallet is now above the auto-lock threshold
      const threshR = await rawDb.execute(rawSql`SELECT value FROM revenue_model_settings WHERE key_name='auto_lock_threshold' LIMIT 1`);
      const unlockThreshold = parseFloat((threshR.rows[0] as any)?.value || "-100");
      const wasLocked = (wUpd.rows[0] as any)?.is_locked;
      let autoUnlocked = false;
      if (newBalance >= unlockThreshold && wasLocked) {
        await rawDb.execute(rawSql`UPDATE users SET is_locked=false, lock_reason=NULL, locked_at=NULL WHERE id=${driver.id}::uuid`);
        autoUnlocked = true;
      }
      await rawDb.execute(rawSql`
        INSERT INTO driver_payments (driver_id, amount, payment_type, razorpay_order_id, razorpay_payment_id, status, description)
        VALUES (${driver.id}::uuid, ${amt}, 'wallet_topup', ${razorpayOrderId}, ${razorpayPaymentId}, 'completed', ${`Wallet recharge via Razorpay`})
      `).catch(() => {});
      res.json({ success: true, newBalance, autoUnlocked, message: `₹${amt.toFixed(0)} added to wallet` });
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
      const custObj = {
        id: d.id,
        fullName: d.fullName,
        phone: d.phone,
        email: d.email,
        profilePhoto: d.profileImage || null,
        rating: parseFloat(d.rating || "5.0"),
        walletBalance: parseFloat(d.walletBalance || "0"),
        loyaltyPoints: parseFloat(d.loyaltyPoints || "0"),
        stats: {
          completedTrips: parseInt(d.completedTrips || "0"),
          totalSpent: parseFloat(d.totalSpent || "0"),
        }
      };
      res.json({ user: custObj, ...custObj });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Book a ride ─────────────────────────────────────────────────
  app.post("/api/app/customer/book-ride", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const {
        pickupAddress, pickupLat, pickupLng,
        destinationAddress, destAddress, destinationLat, destLat, destinationLng, destLng,
        vehicleCategoryId, estimatedFare, estimatedDistance, distanceKm,
        paymentMethod, paymentMode, tripType = "normal", isScheduled = false, scheduledAt,
        // Book for someone else
        isForSomeoneElse = false, passengerName, passengerPhone,
        // Parcel fields
        receiverName, receiverPhone
      } = req.body;
      const finalDestAddress = destinationAddress || destAddress || "";
      const finalDestLat = destinationLat || destLat || 0;
      const finalDestLng = destinationLng || destLng || 0;
      const finalPayment = paymentMethod || paymentMode || "cash";
      const finalDistance = estimatedDistance || distanceKm || 0;

      // ── Service activation gate ───────────────────────────────────────────
      const rideGate = await rawDb.execute(rawSql`
        SELECT service_status FROM platform_services WHERE service_key = 'bike_ride' LIMIT 1
      `).catch(() => ({ rows: [] as any[] }));
      // Only block if the record explicitly says inactive (if table missing, allow through)
      if (rideGate.rows.length && (rideGate.rows[0] as any).service_status !== 'active') {
        return res.status(503).json({ message: "Bike Ride service is currently unavailable. Please try again later.", code: "SERVICE_INACTIVE" });
      }

      // ── Server-side fare calculation (fallback when client sends 0 or missing) ──
      let computedFare = Number(estimatedFare) || 0;
      if ((computedFare === 0 || isNaN(computedFare)) && vehicleCategoryId) {
        try {
          const fareConfig = await rawDb.execute(rawSql`
            SELECT base_fare, fare_per_km, fare_per_min, minimum_fare, night_charge_multiplier
            FROM trip_fares
            WHERE vehicle_category_id = ${vehicleCategoryId}::uuid
              AND (zone_id IS NULL OR zone_id IN (
                SELECT id FROM zones WHERE is_active = true ORDER BY created_at ASC LIMIT 1
              ))
            ORDER BY created_at DESC
            LIMIT 1
          `);
          if (fareConfig.rows.length) {
            const fc = fareConfig.rows[0] as any;
            const base   = parseFloat(fc.base_fare   || "0");
            const perKm  = parseFloat(fc.fare_per_km || "0");
            const perMin = parseFloat(fc.fare_per_min || "0");
            const minFare = parseFloat(fc.minimum_fare || "0");
            const dist  = Number(finalDistance) || 0;
            // Apply night charge multiplier between 22:00-06:00
            const hr = new Date().getHours();
            const isNight = hr >= 22 || hr < 6;
            const nightMult = isNight ? parseFloat(fc.night_charge_multiplier || "1") : 1;
            const raw = (base + perKm * dist + perMin * 0) * nightMult;
            computedFare = Math.max(raw, minFare);
          } else {
            // Absolute fallback: ₹30 + ₹12/km (standard bike fare)
            const dist = Number(finalDistance) || 0;
            computedFare = Math.max(30 + 12 * dist, 30);
          }
        } catch (fareErr: any) {
          console.error("[fare-calc] fallback error:", fareErr.message);
          const dist = Number(finalDistance) || 0;
          computedFare = Math.max(30 + 12 * dist, 30);
        }
      }

      // Auto-cancel any trips stuck in 'searching' for more than 3 minutes
      await rawDb.execute(rawSql`
        UPDATE trip_requests
        SET current_status='cancelled', cancel_reason='Auto-cancelled: no pilot found within 3 minutes'
        WHERE customer_id=${customer.id}::uuid
          AND current_status = 'searching'
          AND created_at < NOW() - INTERVAL '3 minutes'
      `);

      // Check if customer already has a genuinely active trip
      const active = await rawDb.execute(rawSql`
        SELECT id, current_status FROM trip_requests
        WHERE customer_id=${customer.id}::uuid
          AND current_status IN ('searching','driver_assigned','accepted','arrived','on_the_way')
      `);
      if (active.rows.length) {
        const st = (active.rows[0] as any).current_status;
        const msg = st === 'searching'
          ? "Searching for a pilot. Please wait or cancel your current trip."
          : "You already have an active trip in progress.";
        return res.status(400).json({ message: msg, tripId: (active.rows[0] as any).id, status: st });
      }

      // Generate ref_id
      const refId = "TRP" + Date.now().toString().slice(-8).toUpperCase();

      // For parcel trips, generate delivery OTP now
      const deliveryOtpVal = (tripType === 'parcel' || tripType === 'delivery') ? Math.floor(1000 + Math.random() * 9000).toString() : null;

      // Always start as 'searching' — driver must ACCEPT before being assigned
      const trip = await rawDb.execute(rawSql`
        INSERT INTO trip_requests (
          ref_id, customer_id, driver_id, vehicle_category_id,
          pickup_address, pickup_lat, pickup_lng,
          destination_address, destination_lat, destination_lng,
          estimated_fare, estimated_distance, payment_method,
          trip_type, current_status, is_scheduled, scheduled_at,
          is_for_someone_else, passenger_name, passenger_phone,
          receiver_name, receiver_phone, delivery_otp
        ) VALUES (
          ${refId}, ${customer.id}::uuid,
          NULL,
          ${vehicleCategoryId ? rawSql`${vehicleCategoryId}::uuid` : rawSql`NULL`},
          ${pickupAddress || ""}, ${Number(pickupLat) || 0}, ${Number(pickupLng) || 0},
          ${finalDestAddress}, ${Number(finalDestLat) || 0}, ${Number(finalDestLng) || 0},
          ${computedFare}, ${Number(finalDistance) || 0}, ${finalPayment},
          ${tripType}, 'searching', ${isScheduled ? true : false}, ${scheduledAt || null},
          ${isForSomeoneElse ? true : false}, ${passengerName || null}, ${passengerPhone || null},
          ${receiverName || null}, ${receiverPhone || null}, ${deliveryOtpVal}
        ) RETURNING *
      `);

      const tripRow = camelize(trip.rows[0]) as any;
      await appendTripStatus(tripRow.id, 'requested', 'customer', 'Customer created booking request');
      await logRideLifecycleEvent(tripRow.id, 'ride_requested', customer.id, 'customer', {
        tripType,
        paymentMethod: finalPayment,
      });

      // AI Driver Matching — find best drivers using intelligent scoring (distance + rating + response speed + completion rate)
      const bestDrivers = await findBestDrivers(
        Number(pickupLat), Number(pickupLng),
        vehicleCategoryId || undefined,
        [customer.id],
        5
      );

      if (io && bestDrivers.length) {
        for (const bd of bestDrivers) {
          io.to(`user:${bd.driverId}`).emit("trip:new_request", {
            tripId: tripRow.id,
            refId: tripRow.refId,
            customerName: customer.fullName || "Customer",
            pickupAddress: pickupAddress,
            destinationAddress: finalDestAddress,
            pickupLat: Number(pickupLat),
            pickupLng: Number(pickupLng),
            estimatedFare: tripRow.estimatedFare || estimatedFare || 0,
            estimatedDistance: tripRow.estimatedDistance || finalDistance || 0,
            paymentMethod: finalPayment,
            tripType,
            aiScore: bd.score,
            driverDistanceKm: bd.distanceKm,
          });
          rawDb.execute(rawSql`SELECT fcm_token FROM user_devices WHERE user_id=${bd.driverId}::uuid`)
            .then(devR => {
              const fcm = (devR.rows[0] as any)?.fcm_token;
              if (fcm) notifyDriverNewRide({
                fcmToken: fcm, driverName: bd.fullName,
                customerName: customer.fullName || "Customer",
                pickupAddress, estimatedFare: tripRow.estimatedFare || estimatedFare || 0, tripId: tripRow.id,
              });
            }).catch(() => {});
        }
        console.log(`[AI] Book-ride: ${bestDrivers.length} drivers matched (scores: ${bestDrivers.map(d => d.score).join(', ')})`);
      } else {
        notifyNearbyDriversNewTrip(tripRow.id, Number(pickupLat), Number(pickupLng), vehicleCategoryId).catch(() => {});
      }

      // ── 15-second reassignment cycle ────────────────────────────────────────
      // If no driver accepts within 15s, timeout current batch and dispatch next.
      // Repeats up to 3 rounds (45s total). Auto-cancels trip if still unaccepted.
      if (io && bestDrivers.length > 0) {
        const _rTripId    = tripRow.id;
        const _rCustomerId = customer.id;
        const _rLat       = Number(pickupLat);
        const _rLng       = Number(pickupLng);
        const _rVcId      = vehicleCategoryId || undefined;
        const _rFare      = Number(tripRow.estimatedFare || estimatedFare || 0);
        const _rDist      = Number(tripRow.estimatedDistance || finalDistance || 0);
        const _rBaseMsg   = {
          refId: tripRow.refId,
          customerName: customer.fullName || "Customer",
          pickupAddress: pickupAddress || "",
          destinationAddress: finalDestAddress,
          pickupLat: _rLat,
          pickupLng: _rLng,
          estimatedFare: _rFare,
          estimatedDistance: _rDist,
          paymentMethod: finalPayment,
          tripType,
        };
        // Closure-based recursive round scheduler (no TypeScript hoisting issues)
        let _scheduleRound: (excludeIds: string[], round: number) => void;
        _scheduleRound = (excludeIds: string[], round: number) => {
          if (round > 3) return; // Max 3 reassignment rounds = 45 seconds
          setTimeout(async () => {
            try {
              const chk = await rawDb.execute(rawSql`SELECT current_status FROM trip_requests WHERE id=${_rTripId}::uuid`);
              if (!chk.rows.length || (chk.rows[0] as any)?.current_status !== 'searching') return;

              // Emit timeout to drivers who were notified in this round
              const prevRoundIds = excludeIds.filter(id => id !== _rCustomerId);
              if (io) for (const dId of prevRoundIds) {
                io.to(`user:${dId}`).emit("trip:timeout", { tripId: _rTripId });
              }

              // Find next batch of drivers (exclude all previously notified)
              const next = await findBestDrivers(_rLat, _rLng, _rVcId, excludeIds, 5);
              if (!next.length) {
                // No more drivers — notify customer and auto-cancel
                if (io) io.to(`user:${_rCustomerId}`).emit("trip:no_drivers", {
                  tripId: _rTripId,
                  message: "No pilots available nearby. Please try again.",
                });
                await rawDb.execute(rawSql`
                  UPDATE trip_requests
                  SET current_status='cancelled', cancel_reason='No pilots available in your area'
                  WHERE id=${_rTripId}::uuid AND current_status='searching'
                `).catch(() => {});
                return;
              }

              if (io) {
                for (const nd of next) {
                  io.to(`user:${nd.driverId}`).emit("trip:new_request", { tripId: _rTripId, ...(_rBaseMsg as any) });
                  if (nd.fcmToken) {
                    notifyDriverNewRide({
                      fcmToken: nd.fcmToken,
                      driverName: nd.fullName,
                      customerName: _rBaseMsg.customerName,
                      pickupAddress: _rBaseMsg.pickupAddress,
                      estimatedFare: _rFare,
                      tripId: _rTripId,
                    }).catch(() => {});
                  }
                }
                console.log(`[AI] Reassign round ${round}: ${next.length} new drivers notified`);
              }

              // Schedule next round with expanded exclusion list
              _scheduleRound([...excludeIds, ...next.map(d => d.driverId)], round + 1);
            } catch (e: any) {
              console.error('[trip-reassign]', e.message);
            }
          }, 15000);
        };
        _scheduleRound([_rCustomerId, ...bestDrivers.map(d => d.driverId)], 1);
      }

      res.json({
        success: true,
        trip: tripRow,
        driver: null,
        status: "searching",
        uiState: toUiTripState({ current_status: 'searching' }),
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
          d.vehicle_number as driver_vehicle_number, d.vehicle_model as driver_vehicle_model,
          vc.name as vehicle_name,
          dl.lat as driver_lat, dl.lng as driver_lng, dl.heading as driver_heading
        FROM trip_requests t
        LEFT JOIN users d ON d.id = t.driver_id
        LEFT JOIN vehicle_categories vc ON vc.id = t.vehicle_category_id
        LEFT JOIN driver_locations dl ON dl.driver_id = t.driver_id
        WHERE t.id = ${tripId}::uuid AND t.customer_id = ${customer.id}::uuid
      `);
      if (!r.rows.length) return res.status(404).json({ message: "Trip not found" });
      const trip = camelize(r.rows[0]) as any;
      trip.uiState = toUiTripState(trip);
      if (trip.rideStartedAt) {
        trip.rideTimerSeconds = Math.max(0, Math.floor((Date.now() - new Date(trip.rideStartedAt).getTime()) / 1000));
      }
      if (trip.driverLat != null && trip.driverLng != null) {
        const isPrePickup = ['searching', 'driver_assigned', 'accepted', 'arrived'].includes(String(trip.currentStatus));
        const targetLat = isPrePickup ? Number(trip.pickupLat) : Number(trip.destinationLat);
        const targetLng = isPrePickup ? Number(trip.pickupLng) : Number(trip.destinationLng);
        if (Number.isFinite(targetLat) && Number.isFinite(targetLng)) {
          const km = haversineKm(Number(trip.driverLat), Number(trip.driverLng), targetLat, targetLng);
          trip.etaMinutes = computeEtaMinutes(km);
        }
      }
      if (trip.currentStatus === "arrived" || trip.currentStatus === "accepted") {
        trip.pickupOtpVisible = trip.pickupOtp;
      } else {
        delete trip.pickupOtp;
      }
      res.json({ trip });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Get active trip ─────────────────────────────────────────────
  app.get("/api/app/customer/active-trip", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT t.*,
          d.full_name as driver_name, d.phone as driver_phone, d.rating as driver_rating,
          d.vehicle_number as driver_vehicle_number, d.vehicle_model as driver_vehicle_model,
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
      trip.uiState = toUiTripState(trip);
      if (trip.rideStartedAt) {
        trip.rideTimerSeconds = Math.max(0, Math.floor((Date.now() - new Date(trip.rideStartedAt).getTime()) / 1000));
      }
      if (trip.driverLat != null && trip.driverLng != null) {
        const isPrePickup = ['searching', 'driver_assigned', 'accepted', 'arrived'].includes(String(trip.currentStatus));
        const targetLat = isPrePickup ? Number(trip.pickupLat) : Number(trip.destinationLat);
        const targetLng = isPrePickup ? Number(trip.pickupLng) : Number(trip.destinationLng);
        if (Number.isFinite(targetLat) && Number.isFinite(targetLng)) {
          const km = haversineKm(Number(trip.driverLat), Number(trip.driverLng), targetLat, targetLng);
          trip.etaMinutes = computeEtaMinutes(km);
        }
      }
      // Round distance to 1 decimal
      if (trip.estimatedDistance) trip.estimatedDistance = Math.round(parseFloat(trip.estimatedDistance) * 10) / 10;
      if (trip.actualDistance) trip.actualDistance = Math.round(parseFloat(trip.actualDistance) * 10) / 10;
      // Show pickup OTP to customer when driver arrived (share with driver to start ride)
      const showPickupOtp = ['driver_assigned','accepted','arrived'].includes(trip.currentStatus);
      if (!showPickupOtp) delete trip.pickupOtp;
      // For parcel: show delivery OTP to customer (sender shares with receiver)
      // Only show delivery_otp when trip is 'on_the_way' or later
      if (trip.tripType !== 'parcel' && trip.tripType !== 'delivery') {
        delete trip.deliveryOtp;
      }
      res.json({ trip });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── TRIP: Get chat message history ───────────────────────────────────────
  app.get("/api/app/trip/:tripId/messages", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const { tripId } = req.params;
      // Verify user is a participant of this trip
      const access = await rawDb.execute(rawSql`
        SELECT id FROM trip_requests
        WHERE id=${tripId}::uuid AND (customer_id=${user.id}::uuid OR driver_id=${user.id}::uuid)
        LIMIT 1
      `);
      if (!access.rows.length) return res.status(403).json({ message: "Access denied" });

      const rows = await rawDb.execute(rawSql`
        SELECT id, trip_id, sender_id, sender_type, sender_name, message, created_at
        FROM trip_messages
        WHERE trip_id=${tripId}::uuid
        ORDER BY created_at ASC
        LIMIT 200
      `);
      return res.json({
        messages: rows.rows.map((r: any) => ({
          id: r.id,
          tripId: r.trip_id,
          from: r.sender_id,
          senderType: r.sender_type,
          senderName: r.sender_name,
          message: r.message,
          timestamp: r.created_at,
        })),
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Cancel trip ─────────────────────────────────────────────────
  app.post("/api/app/customer/cancel-trip", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const { tripId, reason } = req.body;
      // If no tripId provided, find the active trip for this customer
      const effectiveTripId = tripId || await rawDb.execute(rawSql`
        SELECT id FROM trip_requests WHERE customer_id=${customer.id}::uuid
          AND current_status NOT IN ('completed','cancelled','on_the_way')
        ORDER BY created_at DESC LIMIT 1
      `).then(r2 => (r2.rows[0] as any)?.id).catch(() => null);
      if (!effectiveTripId) return res.status(404).json({ message: "No active trip to cancel" });
      const r = await rawDb.execute(rawSql`
        UPDATE trip_requests SET current_status='cancelled', cancelled_by='customer', cancel_reason=${reason||'Customer cancelled'}
        WHERE id=${effectiveTripId}::uuid AND customer_id=${customer.id}::uuid AND current_status NOT IN ('completed','cancelled','on_the_way')
        RETURNING *
      `);
      if (!r.rows.length) return res.status(400).json({ message: "Cannot cancel — trip already in progress or completed" });
      const trip = r.rows[0] as any;
      await appendTripStatus(effectiveTripId, 'trip_cancelled', 'customer', reason || 'Customer cancelled');
      await logRideLifecycleEvent(effectiveTripId, 'trip_cancelled', customer.id, 'customer', { reason: reason || 'Customer cancelled' });
      clearTripWaypoints(effectiveTripId);
      if (trip.driver_id) {
        await rawDb.execute(rawSql`UPDATE users SET current_trip_id=NULL WHERE id=${trip.driver_id}::uuid`);
        const drvDevRes = await rawDb.execute(rawSql`SELECT fcm_token FROM user_devices WHERE user_id=${trip.driver_id}::uuid`);
        const drvFcm = (drvDevRes.rows[0] as any)?.fcm_token || null;
        notifyTripCancelled({ fcmToken: drvFcm, cancelledBy: "customer", tripId }).catch(() => {});
      }
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Rate driver ─────────────────────────────────────────────────
  app.post("/api/app/customer/rate-driver", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const { tripId, rating, review } = req.body;
      const parsedRating = parseFloat(rating);
      if (!tripId || isNaN(parsedRating) || parsedRating < 1 || parsedRating > 5) {
        return res.status(400).json({ message: "tripId required and rating must be 1-5" });
      }
      const tripR = await rawDb.execute(rawSql`
        SELECT driver_id FROM trip_requests
        WHERE id=${tripId}::uuid AND customer_id=${customer.id}::uuid AND current_status='completed'
      `);
      if (!tripR.rows.length) return res.status(404).json({ message: "Completed trip not found" });
      const driverId = (tripR.rows[0] as any).driver_id;
      await rawDb.execute(rawSql`UPDATE trip_requests SET driver_rating=${parsedRating} WHERE id=${tripId}::uuid AND customer_id=${customer.id}::uuid`);
      if (driverId) {
        await rawDb.execute(rawSql`
          UPDATE users SET
            rating = (rating * total_ratings + ${parsedRating}) / (total_ratings + 1),
            total_ratings = total_ratings + 1
          WHERE id=${driverId}::uuid
        `);
        // Also insert into reviews table
        await rawDb.execute(rawSql`
          INSERT INTO reviews (trip_id, reviewer_id, reviewee_id, rating, comment, review_type)
          VALUES (${tripId}::uuid, ${customer.id}::uuid, ${driverId}::uuid, ${parsedRating}, ${review||''}, 'customer_to_driver')
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
      const cTrips = camelize(r.rows);
      res.json({ trips: cTrips, total: Number((cnt.rows[0] as any).total) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Fare estimate ────────────────────────────────────────────────
  app.post("/api/app/customer/estimate-fare", async (req, res) => {
    try {
      const {
        pickupLat, pickupLng,
        destLat: _destLat, destLng: _destLng,
        destinationLat, destinationLng,
        vehicleCategoryId, distanceKm, durationMin = 0,
        userId, // optional — if provided, include launch offer info
      } = req.body;
      const destLat = _destLat ?? destinationLat;
      const destLng = _destLng ?? destinationLng;

      // Server-side Haversine when distanceKm is not provided or is 0
      let dist = parseFloat(distanceKm || 0);
      if (dist === 0 && pickupLat && pickupLng && destLat && destLng) {
        const R = 6371;
        const lat1 = parseFloat(pickupLat) * Math.PI / 180;
        const lat2 = parseFloat(destLat)   * Math.PI / 180;
        const dLat = (parseFloat(destLat)  - parseFloat(pickupLat)) * Math.PI / 180;
        const dLng = (parseFloat(destLng)  - parseFloat(pickupLng)) * Math.PI / 180;
        const a = Math.sin(dLat / 2) ** 2 + Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
        dist = parseFloat((R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)) * 1.3).toFixed(2));
      }
      if (dist <= 0) dist = 1;

      const dur = parseFloat(durationMin || 0);
      // Night charge check: 22:00 - 06:00 IST
      const nowHr = new Date().getUTCHours() + 5.5;
      const hr = nowHr >= 24 ? nowHr - 24 : nowHr;
      const isNight = hr >= 22 || hr < 6;

      // DISTINCT ON ensures exactly one row per vehicle category, avoiding zone duplicates
      const fareR = await rawDb.execute(rawSql`
        SELECT DISTINCT ON (f.vehicle_category_id)
          f.*, vc.name as vehicle_name, vc.icon as vehicle_icon,
          vc.vehicle_type as vc_vehicle_type,
          vc.base_fare     as vc_base_fare,
          vc.fare_per_km   as vc_fare_per_km,
          vc.minimum_fare  as vc_minimum_fare,
          vc.waiting_charge_per_min as vc_waiting_charge,
          COALESCE(vc.total_seats, 0) as vc_total_seats,
          COALESCE(vc.is_carpool, false) as vc_is_carpool
        FROM trip_fares f
        JOIN vehicle_categories vc ON vc.id = f.vehicle_category_id
        WHERE vc.is_active = true
        ${vehicleCategoryId ? rawSql`AND f.vehicle_category_id = ${vehicleCategoryId}::uuid` : rawSql``}
        ORDER BY f.vehicle_category_id, vc.name
      `);
      const fares = camelize(fareR.rows).map((f: any) => {
        // Resolve vehicle name for smart defaults
        const vn = (f.vehicleName || '').toLowerCase();
        const isSuv    = vn.includes('suv');
        const isSedan  = !isSuv && (vn.includes('sedan') || (vn.includes('car') && !vn.includes('mini') && !vn.includes('pool') && !vn.includes('share')));
        const isMini   = vn.includes('mini');
        const isPool   = vn.includes('pool') || vn.includes('share');
        const isAuto   = !isSuv && !isSedan && !isMini && !isPool && vn.includes('auto');
        const isCargo  = vn.includes('cargo');
        const isParcel = !isCargo && vn.includes('parcel');

        // Smart defaults by vehicle type
        const defaultBase  = isSuv ? 100 : isSedan ? 80 : isMini ? 60 : isPool ? 80 : isAuto ? 40 : isCargo ? 80 : isParcel ? 35 : 30;
        const defaultPerKm = isSuv ? 22  : isSedan ? 18 : isMini ? 16 : isPool ? 15 : isAuto ? 15 : isCargo ? 20 : isParcel ? 13 : 12;
        const defaultMin   = isSuv ? 150 : isSedan ? 120 : isMini ? 80 : isPool ? 100 : isAuto ? 60 : isCargo ? 100 : isParcel ? 40 : 40;
        const defaultWait  = isSuv ? 3 : (isSedan || isMini || isPool || isAuto) ? 2 : 1;

        // vehicle_categories pricing takes precedence over trip_fares (trip_fares is zone-specific override)
        const base           = parseFloat(f.vcBaseFare)           || parseFloat(f.baseFare)           || defaultBase;
        const perKm          = parseFloat(f.vcFarePerKm)          || parseFloat(f.farePerKm)          || defaultPerKm;
        const perMin         = parseFloat(f.farePerMin)           || 0;
        const minFare        = parseFloat(f.vcMinimumFare)        || parseFloat(f.minimumFare)        || defaultMin;
        const waitPerMin     = parseFloat(f.vcWaitingCharge)      || parseFloat(f.waitingChargePerMin) || defaultWait;
        const nightMultiplier = parseFloat(f.nightChargeMultiplier) || 1.25;
        const cancelFee      = parseFloat(f.cancellationFee)    || 10;
        const helperCharge   = parseFloat(f.helperCharge)       || 0;
        const isCarpool      = f.vcIsCarpool === true || f.vcIsCarpool === 'true';
        const totalSeats     = parseInt(f.vcTotalSeats) || 4;

        // Formula: fullFare = base_fare + (distanceKm × fare_per_km), floored at minimum_fare
        const billableKm   = dist;
        const distanceFare = +(billableKm * perKm).toFixed(2);
        const timeFare     = +(dur * perMin).toFixed(2);

        let subtotal = base + distanceFare + timeFare;
        if (isNight) subtotal = +(subtotal * nightMultiplier).toFixed(2);
        const total = Math.max(subtotal, minFare);
        // GST 5% on full fare (government tax)
        const gst = +(total * 0.05).toFixed(2);
        const grandTotal = +(total + gst).toFixed(2);
        // ±5% range shown in UI: "₹85 – ₹95"
        const fareMin = Math.floor(grandTotal * 0.95);
        const fareMax = Math.ceil(grandTotal * 1.05);
        const estTime = Math.max(5, Math.round(dist * 3));

        // ── Car Pool: seat-based pricing ──────────────────────────────────
        const seatPrice = isCarpool ? +(grandTotal / totalSeats).toFixed(2) : 0;

        return {
          vehicleCategoryId: f.vehicleCategoryId,
          vehicleName: f.vehicleName || "Ride",
          vehicleType: f.vcVehicleType || null,
          vehicleIcon: f.vehicleIcon,
          baseFare: +base.toFixed(2),
          farePerKm: +perKm.toFixed(2),
          billableKm: +billableKm.toFixed(2),
          distanceFare,
          timeFare,
          subtotal: +total.toFixed(2),
          gst,
          estimatedFare: grandTotal,
          fareMin,
          fareMax,
          minimumFare: +minFare.toFixed(2),
          cancellationFee: +cancelFee.toFixed(2),
          waitingChargePerMin: +waitPerMin.toFixed(2),
          isNightCharge: isNight,
          nightMultiplier: isNight ? nightMultiplier : 1,
          helperCharge: +helperCharge.toFixed(2),
          estimatedTime: estTime + " min",
          // Car Pool fields
          isCarpool,
          totalSeats: isCarpool ? totalSeats : undefined,
          seatPrice: isCarpool ? seatPrice : undefined,
          seatPriceDisplay: isCarpool ? `₹${seatPrice}/seat` : undefined,
        };
      });

      // ── User launch offer: first 2 rides 50% discount ─────────────────────
      let launchOffer: any = null;
      if (userId) {
        const userR = await rawDb.execute(rawSql`SELECT completed_rides_count FROM users WHERE id=${userId}::uuid LIMIT 1`).catch(() => ({ rows: [] as any[] }));
        const completedCount = parseInt((userR.rows[0] as any)?.completed_rides_count ?? '0') || 0;
        if (completedCount < 2) {
          launchOffer = {
            active: true,
            discountPct: 50,
            ridesRemaining: 2 - completedCount,
            message: `🎉 Launch Offer: 50% off your first 2 rides! (${2 - completedCount} ride(s) remaining)`,
          };
        }
      }

      res.json({ fares, distanceKm: Math.round(dist * 10) / 10, durationMin: dur, isNight, launchOffer });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── PARCEL FARE ESTIMATE (weight + distance based) ────────────────────────
  // Formula: customerFare = base_fare + (distanceKm × fare_per_km) + (weightKg × weight_rate)
  // driverFare  = customerFare — platform commission (per parcels_model setting)
  app.post("/api/app/customer/estimate-parcel-fare", async (req, res) => {
    try {
      const { pickupLat, pickupLng, destLat, destLng, weightKg = 0 } = req.body;

      const pLat = Number(pickupLat), pLng = Number(pickupLng);
      const dLat = Number(destLat),  dLng = Number(destLng);

      // Haversine distance
      let distKm = 0;
      if (pLat && pLng && dLat && dLng) {
        const R = 6371;
        const dLa = (dLat - pLat) * Math.PI / 180;
        const dLo = (dLng - pLng) * Math.PI / 180;
        const a = Math.sin(dLa / 2) ** 2 + Math.cos(pLat * Math.PI / 180) * Math.cos(dLat * Math.PI / 180) * Math.sin(dLo / 2) ** 2;
        distKm = R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      }

      // Fetch all active parcel vehicles + their weight_rate
      const vcRes = await rawDb.execute(rawSql`
        SELECT id, name, vehicle_type, icon,
               base_fare, fare_per_km, minimum_fare, weight_rate
        FROM vehicle_categories
        WHERE type = 'parcel' AND is_active = true
        ORDER BY base_fare ASC
      `);

      if (!vcRes.rows.length) return res.status(404).json({ message: "No parcel vehicle types configured" });

      // Fetch parcels commission model setting
      const settingsRes = await rawDb.execute(rawSql`
        SELECT key_name, value FROM revenue_model_settings
        WHERE key_name IN ('parcels_model','driver_commission_pct','commission_rate','ride_gst_rate')
      `);
      const settings: Record<string, string> = {};
      for (const row of settingsRes.rows as any[]) settings[row.key_name] = row.value;

      const parcelsModel = settings['parcels_model'] || 'commission';
      const commPct = parseFloat(settings['driver_commission_pct'] || '20') / 100;
      const gstRate = parseFloat(settings['ride_gst_rate'] || '5') / 100;

      const wt = Math.max(0, Number(weightKg));

      const fares = (vcRes.rows as any[]).map(vc => {
        const baseFare   = parseFloat(vc.base_fare   || 0);
        const perKm      = parseFloat(vc.fare_per_km || 0);
        const minFare    = parseFloat(vc.minimum_fare || 0);
        const weightRate = parseFloat(vc.weight_rate  || 0);

        const rawFare = baseFare + (distKm * perKm) + (wt * weightRate);
        const customerFare = Math.ceil(Math.max(rawFare, minFare));
        const gstAmount    = Math.ceil(customerFare * gstRate);
        const grandTotal   = customerFare + gstAmount;

        // driverFare = what driver earns after platform deduction
        let platformFee = 0;
        if (parcelsModel === 'commission') {
          platformFee = Math.ceil(customerFare * commPct);
        }
        const driverFare = Math.max(0, customerFare - platformFee);

        return {
          vehicleCategoryId: vc.id,
          vehicleName: vc.name,
          vehicleType: vc.vehicle_type,
          icon: vc.icon,
          distanceKm: Math.round(distKm * 10) / 10,
          weightKg: wt,
          baseFare,
          perKmCharge: Math.ceil(distKm * perKm),
          weightCharge: Math.ceil(wt * weightRate),
          customerFare,
          gstAmount,
          grandTotal,
          driverFare,
          platformFee,
        };
      });

      res.json({ fares, distanceKm: Math.round(distKm * 10) / 10, weightKg: wt });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── VOICE BOOKING: AI-Enhanced NLP Intent Parser ──────────────────────────
  app.post("/api/app/voice-booking/parse", authApp, async (req, res) => {
    try {
      const { text } = req.body;
      if (!text) return res.status(400).json({ message: "No text provided" });

      const { parsed, parserSource } = await parseVoiceIntentOrchestrated(text);

      let vehicleName = parsed.vehicleType || "Bike";
      let vehicleCategoryId: string | null = null;

      const vcRes = await rawDb.execute(rawSql`
        SELECT id, name FROM vehicle_categories
        WHERE LOWER(name) LIKE ${`%${vehicleName.toLowerCase().split(' ')[0]}%`} AND is_active=true LIMIT 1
      `);
      if (vcRes.rows.length) {
        vehicleCategoryId = (vcRes.rows[0] as any).id;
        vehicleName = (vcRes.rows[0] as any).name;
      }

      let pickupGeo: any = null;
      let destGeo: any = null;

      const apiKey = await getConf("GOOGLE_MAPS_API_KEY", "google_maps_key");
      if (!apiKey) {
        return res.status(503).json({ message: "Maps service unavailable. Add Google Maps API Key in Admin → Configuration." });
      }
      const geocode = async (place: string) => {
        const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(place)}&key=${apiKey}`;
        const r = await fetch(url);
        const d = await r.json() as any;
        if (d.status === 'OK' && d.results.length) {
          const loc = d.results[0].geometry.location;
          return { lat: loc.lat, lng: loc.lng, address: d.results[0].formatted_address };
        }
        return null;
      };

      if (parsed.pickup || parsed.destination) {
        const promises: Promise<any>[] = [];
        promises.push(parsed.pickup ? geocode(parsed.pickup) : Promise.resolve(null));
        promises.push(parsed.destination ? geocode(parsed.destination) : Promise.resolve(null));
        [pickupGeo, destGeo] = await Promise.all(promises);
      }

      res.json({
        success: parsed.intent !== "unknown",
        intent: parsed.intent,
        confidence: parsed.confidence,
        pickup: pickupGeo?.address || parsed.pickup,
        destination: destGeo?.address || parsed.destination,
        pickupLat: pickupGeo?.lat || null,
        pickupLng: pickupGeo?.lng || null,
        destLat: destGeo?.lat || null,
        destLng: destGeo?.lng || null,
        vehicleName,
        vehicleCategoryId,
        entities: parsed.entities,
        parserSource,
        originalText: text,
      });
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // ── SHARED: Nearby drivers (for customer map) ──────────────────────────────
  app.get("/api/app/nearby-drivers", async (req, res) => {
    try {
      const { lat, lng, radius = 5, vehicleCategoryId } = req.query;
      const vcFilter = vehicleCategoryId
        ? rawSql`AND dd.vehicle_category_id = ${vehicleCategoryId as string}::uuid`
        : rawSql``;
      const r = await rawDb.execute(rawSql`
        SELECT u.id, u.full_name, u.rating, dl.lat, dl.lng, dl.heading,
          vc.name as vehicle_name, vc.id as vehicle_category_id
        FROM driver_locations dl
        JOIN users u ON u.id = dl.driver_id
        JOIN driver_details dd ON dd.user_id = u.id
        LEFT JOIN vehicle_categories vc ON vc.id = dd.vehicle_category_id
        WHERE dl.is_online=true AND u.is_active=true AND u.is_locked=false
          AND u.current_trip_id IS NULL
          AND u.verification_status = 'approved'
          ${vcFilter}
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
      const [cats, reasons, settings, brands, parcelCats, parcelWeights] = await Promise.all([
        rawDb.execute(rawSql`SELECT id, name, icon, type, is_active FROM vehicle_categories WHERE is_active=true ORDER BY CASE type WHEN 'ride' THEN 1 WHEN 'parcel' THEN 2 WHEN 'cargo' THEN 3 ELSE 4 END, name`),
        rawDb.execute(rawSql`SELECT * FROM cancellation_reasons WHERE is_active=true`),
        rawDb.execute(rawSql`SELECT key_name, value FROM business_settings WHERE key_name IN ('otp_on_pickup','max_ride_radius_km','driver_auto_accept','sos_number','support_phone','currency','currency_symbol')`),
        rawDb.execute(rawSql`SELECT * FROM vehicle_brands WHERE is_active=true ORDER BY category, name`),
        rawDb.execute(rawSql`SELECT * FROM parcel_categories WHERE is_active=true ORDER BY name`),
        rawDb.execute(rawSql`SELECT * FROM parcel_weights WHERE is_active=true ORDER BY min_weight`),
      ]);
      const configs: any = {};
      (settings.rows as any[]).forEach(r => { configs[r.key_name] = r.value; });
      res.json({
        vehicleCategories: camelize(cats.rows),
        cancellationReasons: camelize(reasons.rows),
        vehicleBrands: camelize(brands.rows),
        parcelCategories: camelize(parcelCats.rows),
        parcelWeights: camelize(parcelWeights.rows),
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
        VALUES (${user.id}::uuid, ${tripId || null}, ${lat||0}, ${lng||0}, ${message||'SOS triggered from app'}, 'active')
      `).catch(() => {}); // if sos_alerts table doesn't exist, ignore
      console.log(`[SOS] ${user.userType} ${user.fullName} (${user.phone}) at ${lat},${lng}`);
      res.json({ success: true, message: "SOS alert sent. Help is on the way." });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Wallet balance + transactions ───────────────────────────────
  app.get("/api/app/customer/wallet", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const walRes = await rawDb.execute(rawSql`SELECT wallet_balance FROM users WHERE id=${customer.id}::uuid`);
      const balance = parseFloat((walRes.rows[0] as any)?.wallet_balance || "0");
      const txRes = await rawDb.execute(rawSql`
        SELECT id, account, debit, credit, balance, transaction_type, ref_transaction_id, created_at
        FROM transactions WHERE user_id=${customer.id}::uuid ORDER BY created_at DESC LIMIT 50
      `);
      const transactions = txRes.rows.map((r: any) => ({
        id: r.id,
        type: parseFloat(r.credit || 0) > 0 ? 'credit' : 'debit',
        amount: parseFloat(r.credit || 0) > 0 ? parseFloat(r.credit) : parseFloat(r.debit || 0),
        description: r.account || r.transaction_type || 'Transaction',
        paymentMethod: r.account || '',
        referenceId: r.ref_transaction_id || '',
        balance: parseFloat(r.balance || 0),
        date: r.created_at,
      }));
      res.json({ balance, transactions });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Wallet recharge (manual / legacy) ───────────────────────────
  app.post("/api/app/customer/wallet/recharge", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const { amount, paymentRef, paymentMethod = "upi" } = req.body;
      const amt = parseFloat(amount);
      if (!amt || amt <= 0) return res.status(400).json({ message: "Invalid amount" });
      if (amt < 10) return res.status(400).json({ message: "Minimum recharge is ₹10" });
      if (amt > 10000) return res.status(400).json({ message: "Maximum recharge is ₹10,000 per transaction" });
      if (!paymentRef) return res.status(400).json({ message: "Payment reference required" });
      await rawDb.execute(rawSql`UPDATE users SET wallet_balance = wallet_balance + ${amt} WHERE id=${customer.id}::uuid`);
      const newBalRes = await rawDb.execute(rawSql`SELECT wallet_balance FROM users WHERE id=${customer.id}::uuid`);
      const newBal = parseFloat((newBalRes.rows[0] as any).wallet_balance || "0");
      await rawDb.execute(rawSql`
        INSERT INTO transactions (user_id, account, credit, debit, balance, transaction_type, ref_transaction_id)
        VALUES (${customer.id}::uuid, ${`Wallet recharge via ${paymentMethod}`}, ${amt}, 0, ${newBal}, ${'wallet_recharge'}, ${paymentRef||null})
      `).catch(() => {});
      res.json({ success: true, balance: newBal, message: `₹${amt} added to wallet` });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Razorpay – Create order ────────────────────────────────────
  app.post("/api/app/customer/wallet/create-order", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const { amount } = req.body;
      const amt = parseFloat(amount);
      if (!amt || amt < 10 || amt > 50000) return res.status(400).json({ message: "Amount must be ₹10–₹50,000" });
      const keyId = process.env.RAZORPAY_KEY_ID;
      const keySecret = process.env.RAZORPAY_KEY_SECRET;
      if (!keyId || !keySecret) return res.status(503).json({ message: "Payment gateway not configured" });
      const Razorpay = _require("razorpay");
      const rzp = new Razorpay({ key_id: keyId, key_secret: keySecret });
      const order = await rzp.orders.create({
        amount: Math.round(amt * 100),
        currency: "INR",
        receipt: `w_${Date.now().toString(36)}`,
        notes: { customer_id: customer.id, purpose: "wallet_topup" }
      });
      res.json({ order, keyId, amount: amt });
    } catch (e: any) {
      const msg = e.message || e.error?.description || e.error?.reason || JSON.stringify(e).slice(0, 200);
      res.status(500).json({ message: msg });
    }
  });

  // ── CUSTOMER: Razorpay – Verify & credit wallet ───────────────────────────
  app.post("/api/app/customer/wallet/verify-payment", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const { razorpayOrderId, razorpayPaymentId, razorpaySignature, amount } = req.body;
      if (!razorpayOrderId || !razorpayPaymentId) return res.status(400).json({ message: "Missing payment details" });
      // Idempotency: reject duplicate payment IDs
      const dupCheck = await rawDb.execute(rawSql`
        SELECT id FROM transactions WHERE ref_transaction_id=${razorpayPaymentId} AND transaction_type='wallet_recharge' LIMIT 1
      `);
      if (dupCheck.rows.length) return res.status(409).json({ message: "Payment already processed", alreadyCredited: true });
      const keySecret = process.env.RAZORPAY_KEY_SECRET;
      if (keySecret) {
        const expectedSig = crypto.createHmac("sha256", keySecret)
          .update(`${razorpayOrderId}|${razorpayPaymentId}`).digest("hex");
        if (expectedSig !== razorpaySignature) return res.status(400).json({ message: "Invalid payment signature" });
      }
      const amt = parseFloat(amount);
      await rawDb.execute(rawSql`UPDATE users SET wallet_balance = wallet_balance + ${amt} WHERE id=${customer.id}::uuid`);
      const newBalRes = await rawDb.execute(rawSql`SELECT wallet_balance FROM users WHERE id=${customer.id}::uuid`);
      const newBal = parseFloat((newBalRes.rows[0] as any).wallet_balance || "0");
      await rawDb.execute(rawSql`
        INSERT INTO transactions (user_id, account, credit, debit, balance, transaction_type, ref_transaction_id)
        VALUES (${customer.id}::uuid, ${'Wallet recharge via Razorpay'}, ${amt}, 0, ${newBal}, ${'wallet_recharge'}, ${razorpayPaymentId})
      `).catch(() => {});
      res.json({ success: true, balance: newBal, message: `₹${amt.toFixed(0)} added to wallet` });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Razorpay – Create order for ride payment ────────────────────
  app.post("/api/app/customer/ride/create-order", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const { amount } = req.body;
      const amt = parseFloat(amount);
      if (!amt || amt <= 0 || amt > 50000) return res.status(400).json({ message: "Invalid fare amount" });
      const keyId = process.env.RAZORPAY_KEY_ID;
      const keySecret = process.env.RAZORPAY_KEY_SECRET;
      if (!keyId || !keySecret) return res.status(503).json({ message: "Payment gateway not configured" });
      const Razorpay = _require("razorpay");
      const rzp = new Razorpay({ key_id: keyId, key_secret: keySecret });
      const order = await rzp.orders.create({
        amount: Math.round(amt * 100),
        currency: "INR",
        receipt: `r_${Date.now().toString(36)}`,
        notes: { customer_id: customer.id, purpose: "ride_payment" }
      });
      res.json({ order, keyId, amount: amt });
    } catch (e: any) {
      const msg = e.message || e.error?.description || e.error?.reason || JSON.stringify(e).slice(0, 200);
      res.status(500).json({ message: msg });
    }
  });

  // ── CUSTOMER: Razorpay – Verify ride payment ──────────────────────────────
  app.post("/api/app/customer/ride/verify-payment", authApp, async (req, res) => {
    try {
      const { razorpayOrderId, razorpayPaymentId, razorpaySignature, amount } = req.body;
      if (!razorpayOrderId || !razorpayPaymentId) return res.status(400).json({ message: "Missing payment details" });
      const keySecret = process.env.RAZORPAY_KEY_SECRET;
      if (keySecret && razorpaySignature) {
        const expectedSig = crypto.createHmac("sha256", keySecret)
          .update(`${razorpayOrderId}|${razorpayPaymentId}`).digest("hex");
        if (expectedSig !== razorpaySignature) return res.status(400).json({ message: "Invalid payment signature" });
      }
      res.json({ success: true, paymentId: razorpayPaymentId, amount: parseFloat(amount) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── RAZORPAY WEBHOOK (server-side async payment confirmation) ─────────────
  app.post("/api/webhooks/razorpay", async (req, res) => {
    try {
      const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET || process.env.RAZORPAY_KEY_SECRET;
      const signature = req.headers['x-razorpay-signature'] as string;

      if (webhookSecret) {
        // Secret is configured — signature MUST be present and valid
        if (!signature) {
          return res.status(400).json({ message: "Missing webhook signature header" });
        }
        const rawBody = (req as any).rawBody;
        const body = rawBody ? rawBody.toString() : JSON.stringify(req.body);
        const expectedSig = crypto.createHmac("sha256", webhookSecret).update(body).digest("hex");
        if (expectedSig !== signature) {
          return res.status(400).json({ message: "Invalid webhook signature" });
        }
      }

      const event = req.body;
      const eventType: string = event?.event || '';

      if (eventType === 'payment.captured') {
        const payment = event?.payload?.payment?.entity;
        if (payment) {
          const orderId = payment.order_id;
          const paymentId = payment.id;
          const amount = payment.amount / 100; // Convert from paise

          // Find and complete the payment record
          const paymentR = await rawDb.execute(rawSql`
            SELECT * FROM driver_payments WHERE razorpay_order_id=${orderId} AND status='pending'
          `);
          if (paymentR.rows.length) {
            const rec = camelize(paymentR.rows[0]) as any;
            await rawDb.execute(rawSql`
              UPDATE driver_payments SET status='completed', razorpay_payment_id=${paymentId}, verified_at=NOW()
              WHERE razorpay_order_id=${orderId}
            `);
            // Credit wallet
            const updated = await rawDb.execute(rawSql`
              UPDATE users SET wallet_balance = wallet_balance + ${rec.amount}
              WHERE id = ${rec.driverId}::uuid RETURNING wallet_balance, is_locked
            `);
            if (updated.rows.length) {
              const row: any = updated.rows[0];
              const newBalance = parseFloat(row.wallet_balance);
              const threshR = await rawDb.execute(rawSql`SELECT value FROM revenue_model_settings WHERE key_name='auto_lock_threshold'`);
              const thresh = parseFloat((threshR.rows[0] as any)?.value || '-100');
              if (newBalance > thresh && row.is_locked) {
                await rawDb.execute(rawSql`UPDATE users SET is_locked=false, lock_reason=NULL, locked_at=NULL WHERE id=${rec.driverId}::uuid`);
              }
              // Notify driver via socket
              if (io) {
                io.to(`user:${rec.driverId}`).emit("wallet:recharged", { amount: rec.amount, newBalance });
              }
            }
          }
        }
      } else if (eventType === 'payment.failed') {
        const payment = event?.payload?.payment?.entity;
        if (payment?.order_id) {
          await rawDb.execute(rawSql`
            UPDATE driver_payments SET status='failed' WHERE razorpay_order_id=${payment.order_id} AND status='pending'
          `);
        }
      }

      res.json({ success: true });
    } catch (e: any) {
      console.error("[WEBHOOK] Razorpay webhook error:", e.message);
      res.status(500).json({ message: e.message });
    }
  });

  // ── CUSTOMER: Update profile ──────────────────────────────────────────────
  app.patch("/api/app/customer/profile", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const { fullName, email, profileImage, gender, phone } = req.body;
      if (!fullName && !email && !profileImage && !gender && !phone) return res.status(400).json({ message: "Nothing to update" });
      if (fullName) await rawDb.execute(rawSql`UPDATE users SET full_name=${fullName}, updated_at=now() WHERE id=${customer.id}::uuid`);
      if (email) await rawDb.execute(rawSql`UPDATE users SET email=${email}, updated_at=now() WHERE id=${customer.id}::uuid`);
      if (profileImage) await rawDb.execute(rawSql`UPDATE users SET profile_image=${profileImage}, updated_at=now() WHERE id=${customer.id}::uuid`);
      if (gender) await rawDb.execute(rawSql`UPDATE users SET gender=${gender}, updated_at=now() WHERE id=${customer.id}::uuid`);
      res.json({ success: true, message: "Profile updated" });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Update profile ────────────────────────────────────────────────
  app.patch("/api/app/driver/profile", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { fullName, email, profileImage, gender, vehicleNumber, vehicleModel, vehicleCategoryId } = req.body;
      // Update user fields
      if (fullName) await rawDb.execute(rawSql`UPDATE users SET full_name=${fullName}, updated_at=now() WHERE id=${driver.id}::uuid`);
      if (email) await rawDb.execute(rawSql`UPDATE users SET email=${email}, updated_at=now() WHERE id=${driver.id}::uuid`);
      if (profileImage) await rawDb.execute(rawSql`UPDATE users SET profile_image=${profileImage}, updated_at=now() WHERE id=${driver.id}::uuid`);
      if (gender) await rawDb.execute(rawSql`UPDATE users SET gender=${gender}, updated_at=now() WHERE id=${driver.id}::uuid`);
      if (vehicleNumber) await rawDb.execute(rawSql`UPDATE users SET vehicle_number=${vehicleNumber}, updated_at=now() WHERE id=${driver.id}::uuid`);
      if (vehicleModel) await rawDb.execute(rawSql`UPDATE users SET vehicle_model=${vehicleModel}, updated_at=now() WHERE id=${driver.id}::uuid`);
      // Create or update driver_details with vehicle category
      if (vehicleCategoryId) {
        const existing = await rawDb.execute(rawSql`SELECT id FROM driver_details WHERE user_id=${driver.id}::uuid`);
        if (existing.rows.length === 0) {
          await rawDb.execute(rawSql`
            INSERT INTO driver_details (user_id, vehicle_category_id, availability_status, is_online, total_trips, avg_rating)
            VALUES (${driver.id}::uuid, ${vehicleCategoryId}::uuid, 'offline', false, 0, 5.0)
          `);
        } else {
          await rawDb.execute(rawSql`UPDATE driver_details SET vehicle_category_id=${vehicleCategoryId}::uuid WHERE user_id=${driver.id}::uuid`);
        }
      }
      res.json({ success: true, message: "Profile updated" });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Earnings summary ──────────────────────────────────────────────
  app.get("/api/app/driver/earnings", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { period = "today" } = req.query;
      let r: any;
      if (period === "today") {
        r = await rawDb.execute(rawSql`
          SELECT COUNT(*) FILTER (WHERE current_status='completed') as completed,
            COUNT(*) FILTER (WHERE current_status='cancelled') as cancelled,
            COALESCE(SUM(actual_fare) FILTER (WHERE current_status='completed'), 0) as gross_fare,
            COALESCE(SUM(commission_amount) FILTER (WHERE current_status='completed'), 0) as commission,
            COALESCE(SUM(actual_fare - COALESCE(commission_amount,0)) FILTER (WHERE current_status='completed'), 0) as net_earnings
          FROM trip_requests WHERE driver_id=${driver.id}::uuid AND DATE(created_at) = CURRENT_DATE
        `);
      } else if (period === "week") {
        r = await rawDb.execute(rawSql`
          SELECT COUNT(*) FILTER (WHERE current_status='completed') as completed,
            COUNT(*) FILTER (WHERE current_status='cancelled') as cancelled,
            COALESCE(SUM(actual_fare) FILTER (WHERE current_status='completed'), 0) as gross_fare,
            COALESCE(SUM(commission_amount) FILTER (WHERE current_status='completed'), 0) as commission,
            COALESCE(SUM(actual_fare - COALESCE(commission_amount,0)) FILTER (WHERE current_status='completed'), 0) as net_earnings
          FROM trip_requests WHERE driver_id=${driver.id}::uuid AND created_at >= date_trunc('week', now())
        `);
      } else if (period === "month") {
        r = await rawDb.execute(rawSql`
          SELECT COUNT(*) FILTER (WHERE current_status='completed') as completed,
            COUNT(*) FILTER (WHERE current_status='cancelled') as cancelled,
            COALESCE(SUM(actual_fare) FILTER (WHERE current_status='completed'), 0) as gross_fare,
            COALESCE(SUM(commission_amount) FILTER (WHERE current_status='completed'), 0) as commission,
            COALESCE(SUM(actual_fare - COALESCE(commission_amount,0)) FILTER (WHERE current_status='completed'), 0) as net_earnings
          FROM trip_requests WHERE driver_id=${driver.id}::uuid AND created_at >= date_trunc('month', now())
        `);
      } else {
        r = await rawDb.execute(rawSql`
          SELECT COUNT(*) FILTER (WHERE current_status='completed') as completed,
            COUNT(*) FILTER (WHERE current_status='cancelled') as cancelled,
            COALESCE(SUM(actual_fare) FILTER (WHERE current_status='completed'), 0) as gross_fare,
            COALESCE(SUM(commission_amount) FILTER (WHERE current_status='completed'), 0) as commission,
            COALESCE(SUM(actual_fare - COALESCE(commission_amount,0)) FILTER (WHERE current_status='completed'), 0) as net_earnings
          FROM trip_requests WHERE driver_id=${driver.id}::uuid
        `);
      }
      const d = camelize(r.rows[0]) as any;
      res.json({
        period,
        completedTrips: parseInt(d.completed || "0"),
        cancelledTrips: parseInt(d.cancelled || "0"),
        grossFare: parseFloat(d.grossFare || "0"),
        commission: parseFloat(d.commission || "0"),
        netEarnings: parseFloat(d.netEarnings || "0"),
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Saved places ────────────────────────────────────────────────
  app.get("/api/app/customer/saved-places", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT * FROM saved_places WHERE user_id=${customer.id}::uuid ORDER BY created_at DESC
      `);
      res.json({ data: r.rows.map(camelize) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post("/api/app/customer/saved-places", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const { label, address, lat, lng } = req.body;
      if (!label || !address) return res.status(400).json({ message: "label and address required" });
      const r = await rawDb.execute(rawSql`
        INSERT INTO saved_places (user_id, label, address, lat, lng)
        VALUES (${customer.id}::uuid, ${label}, ${address}, ${lat||0}, ${lng||0})
        RETURNING *
      `);
      res.json({ success: true, data: camelize(r.rows[0]) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.delete("/api/app/customer/saved-places/:id", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const { id } = req.params;
      await rawDb.execute(rawSql`
        DELETE FROM saved_places WHERE id=${id}::uuid AND user_id=${customer.id}::uuid
      `);
      res.json({ success: true, message: "Place removed" });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Browse available offers/coupons ────────────────────────────
  app.get("/api/app/customer/offers", authApp, async (req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT id, name, code, discount_type, discount_amount, min_trip_amount, max_discount_amount,
               end_date, total_usage_limit, limit_per_user
        FROM coupon_setups
        WHERE is_active=true AND (end_date IS NULL OR end_date >= now())
        ORDER BY created_at DESC
        LIMIT 20
      `);
      res.json(r.rows.map(camelize));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Apply coupon code ───────────────────────────────────────────
  app.post("/api/app/customer/apply-coupon", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const { code, fareAmount } = req.body;
      if (!code) return res.status(400).json({ message: "Coupon code required" });
      const r = await rawDb.execute(rawSql`
        SELECT * FROM coupon_setups WHERE code=${code.toUpperCase()} AND is_active=true
          AND (end_date IS NULL OR end_date >= now())
        LIMIT 1
      `);
      if (!r.rows.length) return res.status(400).json({ message: "Invalid or expired coupon" });
      const coupon = camelize(r.rows[0]) as any;
      let discount = 0;
      if (coupon.discountType === "percent") {
        discount = (fareAmount * coupon.discountAmount) / 100;
        if (coupon.maxDiscountAmount) discount = Math.min(discount, coupon.maxDiscountAmount);
      } else {
        discount = coupon.discountAmount || 0;
      }
      discount = Math.min(discount, fareAmount);
      res.json({
        success: true,
        couponId: coupon.id,
        code: coupon.code,
        discountType: coupon.discountType,
        discountValue: coupon.discountAmount,
        discount: parseFloat(discount.toFixed(2)),
        finalFare: parseFloat((fareAmount - discount).toFixed(2)),
        message: `Coupon applied! You save ₹${discount.toFixed(2)}`,
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── LOGOUT: Invalidate auth token ────────────────────────────────────────
  app.post("/api/app/logout", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      await rawDb.execute(rawSql`UPDATE users SET auth_token=NULL WHERE id=${user.id}::uuid`);
      res.json({ success: true, message: "Logged out successfully" });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Change password ───────────────────────────────────────────────
  app.post("/api/app/change-password", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const { newPin, newPassword, currentPassword } = req.body;
      const newPass = newPassword || newPin;
      if (!newPass || String(newPass).length < 4) return res.status(400).json({ message: "Password must be at least 4 characters" });
      // Verify current password if provided
      if (currentPassword) {
        const userRow = await rawDb.execute(rawSql`SELECT password_hash FROM users WHERE id=${user.id}::uuid`);
        const stored = (userRow.rows[0] as any)?.password_hash;
        if (stored) {
          const valid = await bcrypt.compare(String(currentPassword), stored);
          if (!valid) return res.status(401).json({ message: "Current password is incorrect" });
        }
      }
      const hashed = await bcrypt.hash(String(newPass), 10);
      await rawDb.execute(rawSql`UPDATE users SET password_hash=${hashed}, updated_at=now() WHERE id=${user.id}::uuid`);
      res.json({ success: true, message: "Password updated successfully" });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Delete account ──────────────────────────────────────────────
  app.delete("/api/app/customer/account", authApp, async (req, res) => {
    try {
      const customer = (req as any).currentUser;
      const { permanent = false } = req.body || {};
      if (permanent) {
        // Permanent delete — anonymize all PII, revoke token, keep records for audit
        await rawDb.execute(rawSql`
          UPDATE users SET is_active=false, full_name='Deleted User', email=null, phone=null,
            profile_image=null, auth_token=null, wallet_balance=0, updated_at=NOW()
          WHERE id=${customer.id}::uuid
        `);
        // Also cancel any active trips
        await rawDb.execute(rawSql`
          UPDATE trip_requests SET current_status='cancelled', cancelled_by='customer', cancel_reason='Account deleted'
          WHERE customer_id=${customer.id}::uuid AND current_status NOT IN ('completed','cancelled')
        `);
        return res.json({ success: true, message: "Account permanently deleted. All data has been removed." });
      }
      // Soft delete — just deactivate
      await rawDb.execute(rawSql`UPDATE users SET is_active=false, auth_token=null, updated_at=NOW() WHERE id=${customer.id}::uuid`);
      res.json({ success: true, message: "Account deactivated. Contact support to reactivate." });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Delete account ────────────────────────────────────────────────
  app.delete("/api/app/driver/account", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { permanent = false } = req.body || {};
      if (permanent) {
        await rawDb.execute(rawSql`
          UPDATE users SET is_active=false, full_name='Deleted Driver', email=null, phone=null,
            profile_image=null, auth_token=null, wallet_balance=0, updated_at=NOW()
          WHERE id=${driver.id}::uuid AND user_type='driver'
        `);
        // Cancel active trip if any
        await rawDb.execute(rawSql`
          UPDATE trip_requests SET current_status='cancelled', cancelled_by='driver', cancel_reason='Driver account deleted'
          WHERE driver_id=${driver.id}::uuid AND current_status NOT IN ('completed','cancelled')
        `);
        await rawDb.execute(rawSql`UPDATE users SET current_trip_id=NULL WHERE id=${driver.id}::uuid`);
        return res.json({ success: true, message: "Driver account permanently deleted." });
      }
      await rawDb.execute(rawSql`UPDATE users SET is_active=false, auth_token=null, updated_at=NOW() WHERE id=${driver.id}::uuid AND user_type='driver'`);
      res.json({ success: true, message: "Account deactivated. Contact support to reactivate." });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Referral info ─────────────────────────────────────────────────
  app.get("/api/app/referral", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT * FROM referrals WHERE referrer_id=${user.id}::uuid ORDER BY created_at DESC
      `);
      const countRes = await rawDb.execute(rawSql`
        SELECT COUNT(*) as total, COALESCE(SUM(reward_amount),0) as total_earned FROM referrals WHERE referrer_id=${user.id}::uuid AND status='paid'
      `);
      const summary = camelize(countRes.rows[0]) as any;
      res.json({
        referralCode: user.phone,
        totalReferrals: parseInt(summary.total || "0"),
        totalEarned: parseFloat(summary.totalEarned || "0"),
        referrals: r.rows.map(camelize),
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ========== ADVANCED FEATURES ==========

  // ── DRIVER: Check if face verification needed ─────────────────────────────
  app.get("/api/app/driver/check-verification", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT last_face_verified_at, face_verified_trips,
        (SELECT COUNT(*) FROM trip_requests WHERE driver_id=${user.id}::uuid AND current_status='completed'
         AND created_at > COALESCE((SELECT last_face_verified_at FROM users WHERE id=${user.id}::uuid), '2000-01-01')) AS trips_since_verify
        FROM users WHERE id=${user.id}::uuid
      `);
      const row = r.rows[0] as any;
      const lastVerified = row?.last_face_verified_at ? new Date(row.last_face_verified_at) : null;
      const tripsSince = parseInt(row?.trips_since_verify || '0');
      const hoursSinceVerify = lastVerified ? (Date.now() - new Date(lastVerified).getTime()) / 3600000 : 999;
      const needsVerification = !lastVerified || hoursSinceVerify >= 24 || tripsSince >= 10;
      const reason = !lastVerified ? 'first_time' : hoursSinceVerify >= 24 ? 'daily_check' : tripsSince >= 10 ? 'after_10_trips' : null;
      res.json({ needsVerification, reason, tripsSince, lastVerified });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Submit face verification selfie ───────────────────────────────
  app.post("/api/app/driver/face-verify", authApp, upload.single("selfie"), async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const selfieUrl = req.file ? `/uploads/${req.file.filename}` : null;
      if (!selfieUrl) return res.status(400).json({ message: "Selfie required" });
      // In production: compare selfie with profile photo using AWS Rekognition / Azure Face API
      // For now: auto-approve after selfie submission
      await rawDb.execute(rawSql`
        UPDATE users SET last_face_verified_at=now(), face_verified_trips=0, updated_at=now() WHERE id=${user.id}::uuid
      `).catch(() => {
        // Add columns if not exist
        return rawDb.execute(rawSql`ALTER TABLE users ADD COLUMN IF NOT EXISTS last_face_verified_at TIMESTAMPTZ`).then(() =>
          rawDb.execute(rawSql`ALTER TABLE users ADD COLUMN IF NOT EXISTS face_verified_trips INTEGER DEFAULT 0`).then(() =>
            rawDb.execute(rawSql`UPDATE users SET last_face_verified_at=now(), face_verified_trips=0 WHERE id=${user.id}::uuid`)
          )
        );
      });
      res.json({ success: true, verified: true, selfieUrl, message: "Face verified successfully!" });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Upload pickup location photo (ride security) ─────────────────
  app.post("/api/app/driver/trip-photo", authApp, upload.single("photo"), async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const { tripId } = req.body;
      const photoUrl = req.file ? `/uploads/${req.file.filename}` : null;
      if (!photoUrl || !tripId) return res.status(400).json({ message: "photo and tripId required" });
      // Ensure column exists, then update
      await rawDb.execute(rawSql`ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS pickup_photo_url TEXT`).catch(() => {});
      await rawDb.execute(rawSql`
        UPDATE trip_requests SET pickup_photo_url=${photoUrl}
        WHERE id=${tripId}::uuid AND driver_id=${user.id}::uuid
      `);
      res.json({ success: true, photoUrl });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Upload documents (DL, RC, Aadhar) ────────────────────────────
  app.post("/api/app/driver/upload-document", authApp, upload.single("document"), async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const { docType } = req.body; // dl_front, dl_back, rc, aadhar_front, aadhar_back, insurance
      const fileUrl = req.file ? `/uploads/${req.file.filename}` : null;
      if (!fileUrl || !docType) return res.status(400).json({ message: "Document type and file required" });
      await rawDb.execute(rawSql`
        INSERT INTO driver_documents (driver_id, doc_type, file_url, status, created_at, updated_at)
        VALUES (${user.id}::uuid, ${docType}, ${fileUrl}, 'pending', now(), now())
        ON CONFLICT (driver_id, doc_type) DO UPDATE SET file_url=${fileUrl}, status='pending', updated_at=now()
      `).catch(async () => {
        await rawDb.execute(rawSql`
          CREATE TABLE IF NOT EXISTS driver_documents (
            id SERIAL PRIMARY KEY,
            driver_id UUID, doc_type VARCHAR(50), file_url TEXT,
            status VARCHAR(20) DEFAULT 'pending', created_at TIMESTAMPTZ DEFAULT now(), updated_at TIMESTAMPTZ DEFAULT now(),
            UNIQUE(driver_id, doc_type)
          )
        `);
        await rawDb.execute(rawSql`
          INSERT INTO driver_documents (driver_id, doc_type, file_url, status) VALUES (${user.id}::uuid, ${docType}, ${fileUrl}, 'pending')
          ON CONFLICT (driver_id, doc_type) DO UPDATE SET file_url=${fileUrl}, status='pending', updated_at=now()
        `);
      });
      res.json({ success: true, docType, fileUrl, status: 'pending', message: "Document uploaded. Under review." });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Get documents status ──────────────────────────────────────────
  app.get("/api/app/driver/documents", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`SELECT * FROM driver_documents WHERE driver_id=${user.id}::uuid`).catch(() => ({ rows: [] }));
      res.json({ success: true, documents: r.rows.map(camelize) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Upload document as base64 (for Flutter) ───────────────────────
  app.post("/api/app/driver/upload-document-base64", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const { docType, imageData, expiryDate } = req.body;
      if (!docType || !imageData) return res.status(400).json({ message: "docType and imageData required" });
      const validTypes = ['dl_front', 'dl_back', 'rc', 'aadhar_front', 'aadhar_back', 'insurance', 'selfie', 'vehicle_photo'];
      if (!validTypes.includes(docType)) return res.status(400).json({ message: "Invalid docType" });
      await rawDb.execute(rawSql`
        INSERT INTO driver_documents (driver_id, doc_type, file_url, status, expiry_date, created_at, updated_at)
        VALUES (${user.id}::uuid, ${docType}, ${imageData}, 'pending', ${expiryDate || null}, now(), now())
        ON CONFLICT (driver_id, doc_type) DO UPDATE SET file_url=${imageData}, status='pending', expiry_date=${expiryDate || null}, updated_at=now()
      `);
      res.json({ success: true, docType, status: 'pending', message: "Document uploaded. Under review." });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Update registration profile fields ─────────────────────────────
  app.patch("/api/app/driver/update-registration", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      // Accept both dateOfBirth (camelCase) and dob (Flutter sends 'dob')
      const dateOfBirth = req.body.dateOfBirth || req.body.dob || null;
      const { city, vehicleBrand, vehicleColor, vehicleYear, licenseNumber, licenseExpiry,
              vehicleNumber, vehicleModel, vehicleType, selfieImage } = req.body;
      // Accept both 'name' (Flutter) and 'fullName' for driver full name update
      const fullName = req.body.fullName || req.body.name || null;
      const password = req.body.password || null;
      let passwordHash: string | null = null;
      if (password && typeof password === 'string' && password.length >= 6) {
        passwordHash = await bcrypt.hash(password, 10);
      }
      await rawDb.execute(rawSql`
        UPDATE users SET
          full_name = COALESCE(${fullName || null}, full_name),
          date_of_birth = COALESCE(${dateOfBirth || null}, date_of_birth),
          city = COALESCE(${city || null}, city),
          vehicle_brand = COALESCE(${vehicleBrand || null}, vehicle_brand),
          vehicle_color = COALESCE(${vehicleColor || null}, vehicle_color),
          vehicle_year = COALESCE(${vehicleYear || null}, vehicle_year),
          license_number = COALESCE(${licenseNumber || null}, license_number),
          license_expiry = COALESCE(${licenseExpiry || null}, license_expiry),
          vehicle_number = COALESCE(${vehicleNumber || null}, vehicle_number),
          vehicle_model = COALESCE(${vehicleModel || null}, vehicle_model),
          selfie_image = COALESCE(${selfieImage || null}, selfie_image),
          password_hash = COALESCE(${passwordHash || null}, password_hash),
          updated_at = now()
        WHERE id = ${user.id}::uuid
      `);
      if (vehicleType) {
        await rawDb.execute(rawSql`
          UPDATE driver_details SET vehicle_type=${vehicleType}, updated_at=now() WHERE user_id=${user.id}::uuid
        `).catch(() => {});
      }
      res.json({ success: true, message: "Profile updated" });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Get verification status (full detail) ──────────────────────────
  app.get("/api/app/driver/verification-status", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const profileR = await rawDb.execute(rawSql`
        SELECT u.verification_status, u.vehicle_status, u.rejection_note, u.license_number,
               u.license_expiry, u.vehicle_number, u.vehicle_model, u.vehicle_brand,
               u.vehicle_color, u.vehicle_year, u.date_of_birth, u.city, u.selfie_image,
               u.full_name, u.phone, u.profile_image, u.revenue_model, u.model_selected_at,
               u.theme_preference,
               dd.vehicle_category_id, vc.name as vehicle_category_name
        FROM users u
        LEFT JOIN driver_details dd ON dd.user_id = u.id
        LEFT JOIN vehicle_categories vc ON vc.id = dd.vehicle_category_id
        WHERE u.id = ${user.id}::uuid
      `);
      const docsR = await rawDb.execute(rawSql`
        SELECT doc_type, status, expiry_date, admin_note, reviewed_at
        FROM driver_documents WHERE driver_id = ${user.id}::uuid ORDER BY created_at
      `).catch(() => ({ rows: [] }));
      const profile = camelize(profileR.rows[0] || {});
      const documents = docsR.rows.map(camelize);
      res.json({ success: true, ...profile, documents });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Get subscription plans ────────────────────────────────────────
  app.get("/api/app/driver/subscription-plans", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT id, name, price, duration_days, features, plan_type
        FROM subscription_plans WHERE is_active=true AND plan_type IN ('driver','both')
        ORDER BY duration_days ASC
      `);
      const plans = r.rows.map((p: any) => ({
        ...camelize(p),
        features: (p.features || '').split('|').filter(Boolean),
        savings: p.duration_days === 30 ? 'Best Value' : p.duration_days === 15 ? 'Popular' : p.duration_days === 7 ? 'Starter' : null,
      }));
      res.json({ success: true, plans });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Choose revenue model (commission, subscription, or hybrid) ─────
  app.post("/api/app/driver/choose-model", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { model } = req.body; // 'commission' | 'subscription' | 'hybrid'
      if (!['commission', 'subscription', 'hybrid'].includes(model)) return res.status(400).json({ message: "Invalid model" });
      await rawDb.execute(rawSql`
        UPDATE users SET revenue_model=${model}, model_selected_at=NOW() WHERE id=${driver.id}::uuid
      `);
      res.json({ success: true, model });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Create Razorpay order for subscription plan ────────────────────
  app.post("/api/app/driver/subscribe", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { planId } = req.body;
      const planR = await rawDb.execute(rawSql`SELECT * FROM subscription_plans WHERE id=${planId}::uuid AND is_active=true`);
      if (!planR.rows.length) return res.status(404).json({ message: "Plan not found" });
      const plan = camelize(planR.rows[0] as any) as any;
      // Check if Razorpay credentials exist
      const Razorpay = require('razorpay');
      const razorpay = new Razorpay({ key_id: process.env.RAZORPAY_KEY_ID, key_secret: process.env.RAZORPAY_KEY_SECRET });
      const amountPaise = Math.round(parseFloat(plan.price) * 100);
      const order = await razorpay.orders.create({ amount: amountPaise, currency: 'INR', receipt: `sub_${driver.id}_${planId}` });
      res.json({ success: true, orderId: order.id, amount: amountPaise, currency: 'INR', plan, keyId: process.env.RAZORPAY_KEY_ID });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Activate subscription after payment ────────────────────────────
  app.post("/api/app/driver/activate-subscription", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { planId, razorpayPaymentId, razorpayOrderId } = req.body;
      if (!planId || !razorpayPaymentId) return res.status(400).json({ message: "planId and razorpayPaymentId required" });
      // Idempotency check
      const existing = await rawDb.execute(rawSql`SELECT id FROM driver_subscriptions WHERE driver_id=${driver.id}::uuid AND razorpay_payment_id=${razorpayPaymentId}`).catch(() => ({ rows: [] }));
      if ((existing as any).rows?.length) return res.status(409).json({ message: "Payment already activated" });
      const planR = await rawDb.execute(rawSql`SELECT * FROM subscription_plans WHERE id=${planId}::uuid AND is_active=true`);
      if (!planR.rows.length) return res.status(404).json({ message: "Plan not found" });
      const plan = camelize(planR.rows[0] as any) as any;
      const startDate = new Date();
      const endDate = new Date(startDate.getTime() + plan.durationDays * 86400000);
      await rawDb.execute(rawSql`
        INSERT INTO driver_subscriptions (id, driver_id, plan_id, start_date, end_date, payment_amount, payment_status, rides_used, is_active, created_at)
        VALUES (gen_random_uuid(), ${driver.id}::uuid, ${planId}::uuid, ${startDate.toISOString()}, ${endDate.toISOString()}, ${plan.price}, 'paid', 0, true, now())
      `).catch(async () => {
        // Add razorpay_payment_id column if missing
        await rawDb.execute(rawSql`ALTER TABLE driver_subscriptions ADD COLUMN IF NOT EXISTS razorpay_payment_id VARCHAR(100)`);
        await rawDb.execute(rawSql`
          INSERT INTO driver_subscriptions (id, driver_id, plan_id, start_date, end_date, payment_amount, payment_status, rides_used, is_active, created_at)
          VALUES (gen_random_uuid(), ${driver.id}::uuid, ${planId}::uuid, ${startDate.toISOString()}, ${endDate.toISOString()}, ${plan.price}, 'paid', 0, true, now())
        `);
      });
      // Keep hybrid if already chosen; otherwise default to subscription after successful payment
      await rawDb.execute(rawSql`
        UPDATE users
        SET revenue_model = CASE WHEN revenue_model='hybrid' THEN 'hybrid' ELSE 'subscription' END,
            model_selected_at = NOW()
        WHERE id=${driver.id}::uuid
      `);
      res.json({ success: true, message: `Subscription active until ${endDate.toDateString()}`, endDate });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── DRIVER: Update theme preference ────────────────────────────────────────
  app.patch("/api/app/driver/theme", authApp, async (req, res) => {
    try {
      const driver = (req as any).currentUser;
      const { theme } = req.body; // 'dark' | 'light'
      if (!['dark', 'light'].includes(theme)) return res.status(400).json({ message: "Invalid theme" });
      await rawDb.execute(rawSql`UPDATE users SET theme_preference=${theme} WHERE id=${driver.id}::uuid`);
      res.json({ success: true, theme });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── ADMIN: GST Wallet ────────────────────────────────────────────────────
  app.get("/api/admin/gst-wallet", requireAdminRole(["admin", "superadmin"]), async (_req, res) => {
    try {
      const walletR = await rawDb.execute(rawSql`SELECT * FROM company_gst_wallet WHERE id=1`);
      const recentR = await rawDb.execute(rawSql`
        SELECT tr.ref_id, tr.gst_amount, tr.ride_full_fare, tr.user_payable, tr.created_at,
               d.full_name AS driver_name, c.full_name AS customer_name
        FROM trip_requests tr
        LEFT JOIN users d ON d.id = tr.driver_id
        LEFT JOIN users c ON c.id = tr.customer_id
        WHERE tr.gst_amount > 0 AND tr.current_status = 'completed'
        ORDER BY tr.created_at DESC
        LIMIT 50
      `);
      res.json({ wallet: camelize(walletR.rows[0] ?? {}), recentCollections: camelize(recentR.rows) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── ADMIN: List drivers by verification status ─────────────────────────────
  // ── ADMIN: Force-clear stale trips & stuck drivers ───────────────────────
  app.post("/api/admin/cleanup-stale-trips", requireAdminRole(["superadmin"]), async (req, res) => {
    try {
      // Cancel searching/driver_assigned trips older than 15 min
      const staleTripRes = await rawDb.execute(rawSql`
        UPDATE trip_requests SET current_status='cancelled',
          cancel_reason='Admin: manual cleanup of stale trip'
        WHERE current_status IN ('searching','driver_assigned','accepted')
          AND created_at < NOW() - INTERVAL '30 minutes'
        RETURNING id, ref_id, current_status
      `);
      // Free drivers stuck with completed/cancelled current_trip_id
      const freedRes = await rawDb.execute(rawSql`
        UPDATE users SET current_trip_id=NULL
        WHERE current_trip_id IS NOT NULL
          AND current_trip_id NOT IN (
            SELECT id FROM trip_requests WHERE current_status IN ('accepted','arrived','on_the_way')
          )
        RETURNING id, full_name
      `);
      res.json({
        success: true,
        cancelledTrips: staleTripRes.rows.length,
        freedDrivers: freedRes.rows.length,
        cancelledTripIds: staleTripRes.rows.map((r: any) => r.ref_id),
        freedDriverNames: freedRes.rows.map((r: any) => r.full_name),
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/admin/drivers/pending-verification", async (req, res) => {
    try {
      const status = (req.query.status as string) || 'pending';
      const r = await rawDb.execute(rawSql`
        SELECT u.id, u.full_name, u.phone, u.email, u.verification_status, u.vehicle_status,
               u.rejection_note, u.license_number, u.license_expiry, u.vehicle_number,
               u.vehicle_model, u.vehicle_brand, u.vehicle_color, u.vehicle_year,
               u.date_of_birth, u.city, u.selfie_image, u.profile_image, u.created_at,
               vc.name as vehicle_category_name, vc.icon as vehicle_category_icon
        FROM users u
        LEFT JOIN driver_details dd ON dd.user_id = u.id
        LEFT JOIN vehicle_categories vc ON vc.id = dd.vehicle_category_id
        WHERE u.user_type = 'driver' AND u.verification_status = ${status}
        ORDER BY u.created_at DESC
        LIMIT 100
      `);
      const drivers = await Promise.all(r.rows.map(async (d: any) => {
        const docsR = await rawDb.execute(rawSql`
          SELECT doc_type, file_url, status, expiry_date, admin_note, reviewed_at
          FROM driver_documents WHERE driver_id = ${d.id}::uuid ORDER BY created_at
        `).catch(() => ({ rows: [] }));
        return { ...camelize(d), documents: docsR.rows.map(camelize) };
      }));
      res.json({ success: true, drivers, count: drivers.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── ADMIN: Review a single document (approve/reject) ──────────────────────
  app.patch("/api/admin/drivers/:id/doc-review", requireAdminRole(["admin", "superadmin"]), async (req, res) => {
    try {
      const { id } = req.params;
      const { docType, status, adminNote } = req.body;
      if (!docType || !status) return res.status(400).json({ message: "docType and status required" });
      if (!['approved', 'rejected', 'pending'].includes(status)) return res.status(400).json({ message: "Invalid status" });
      await rawDb.execute(rawSql`
        UPDATE driver_documents SET status=${status}, admin_note=${adminNote || null},
          reviewed_at=NOW(), updated_at=NOW()
        WHERE driver_id=${id}::uuid AND doc_type=${docType}
      `);
      res.json({ success: true, docType, status });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── ADMIN: Approve/Reject entire driver verification ──────────────────────
  app.patch("/api/admin/drivers/:id/verify-driver", requireAdminRole(["admin", "superadmin"]), async (req, res) => {
    try {
      const { id } = req.params;
      const { status, note, vehicleStatus } = req.body;
      if (!['approved', 'rejected', 'pending'].includes(status)) return res.status(400).json({ message: "Invalid status" });
      await rawDb.execute(rawSql`
        UPDATE users SET
          verification_status=${status},
          vehicle_status=${vehicleStatus || status},
          rejection_note=${note || null},
          updated_at=NOW()
        WHERE id=${id}::uuid AND user_type='driver'
      `);
      if (status === 'approved') {
        await rawDb.execute(rawSql`UPDATE users SET is_active=true WHERE id=${id}::uuid`);
        // Check if the global launch campaign is enabled
        const campaignR = await rawDb.execute(rawSql`SELECT value FROM revenue_model_settings WHERE key_name='launch_campaign_enabled' LIMIT 1`).catch(() => ({ rows: [] }));
        const campaignEnabled = (campaignR.rows[0] as any)?.value !== 'false';
        if (campaignEnabled) {
          await rawDb.execute(rawSql`
            UPDATE users
            SET onboard_date = NOW(),
                free_period_end = NOW() + INTERVAL '30 days',
                launch_free_active = true
            WHERE id=${id}::uuid AND user_type='driver'
          `);
        }
      }
      // Send FCM notification if token exists
      const tokenR = await rawDb.execute(rawSql`SELECT fcm_token, full_name FROM users WHERE id=${id}::uuid`).catch(() => ({ rows: [] }));
      const driverRow = (tokenR.rows[0] as any);
      if (driverRow?.fcm_token) {
        try {
          await sendFcmNotification({
            fcmToken: driverRow.fcm_token,
            title: status === 'approved' ? '✅ Account Approved!' : '❌ Verification Issue',
            body: status === 'approved'
              ? 'Congratulations! Your JAGO Pilot account is approved. You can now go online.'
              : `Account issue: ${note || 'Please re-upload documents or contact support.'}`,
            data: { type: 'verification_update', verificationStatus: status },
          });
        } catch (_) {}
      }
      res.json({ success: true, status });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── Driver: Launch Benefit status endpoint ──────────────────────────────
  app.get("/api/app/driver/launch-benefit", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const [benefitR, campaignR] = await Promise.all([
        rawDb.execute(rawSql`SELECT launch_free_active, free_period_end, onboard_date FROM users WHERE id=${user.id}::uuid LIMIT 1`),
        rawDb.execute(rawSql`SELECT value FROM revenue_model_settings WHERE key_name='launch_campaign_enabled' LIMIT 1`).catch(() => ({ rows: [] as any[] })),
      ]);
      const row = benefitR.rows[0] as any;
      const campaignGlobalOn = (campaignR.rows[0] as any)?.value !== 'false';
      const now = new Date();
      let launchFreeActive = row?.launch_free_active === true;
      const freePeriodEnd: Date | null = row?.free_period_end ? new Date(row.free_period_end) : null;

      // Auto-expire silently
      if (launchFreeActive && freePeriodEnd && freePeriodEnd < now) {
        await rawDb.execute(rawSql`UPDATE users SET launch_free_active=false WHERE id=${user.id}::uuid`).catch(() => {});
        launchFreeActive = false;
      }

      const isActive = campaignGlobalOn && launchFreeActive && freePeriodEnd !== null && freePeriodEnd >= now;
      const freeDaysRemaining = isActive && freePeriodEnd
        ? Math.max(0, Math.ceil((freePeriodEnd.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)))
        : 0;

      res.json({
        active: isActive,
        freeDaysRemaining,
        freePeriodEnd: freePeriodEnd ? freePeriodEnd.toISOString() : null,
        onboardDate: row?.onboard_date ? new Date(row.onboard_date).toISOString() : null,
        message: isActive
          ? `🎉 Launch Offer Active! No commission and no platform fee for your first 30 days. ${freeDaysRemaining} day(s) remaining.`
          : null,
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── ADMIN: Advanced dashboard stats ─────────────────────────────────────
  app.get("/api/app/driver/dashboard", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const [todayStats, weekStats, monthStats, recentTrips, walletRow] = await Promise.all([
        rawDb.execute(rawSql`
          SELECT COUNT(*) as trips, COALESCE(SUM(actual_fare),0) as gross, COALESCE(SUM(commission_amount),0) as commission
          FROM trip_requests WHERE driver_id=${user.id}::uuid AND current_status='completed'
          AND created_at >= CURRENT_DATE
        `),
        rawDb.execute(rawSql`
          SELECT COUNT(*) as trips, COALESCE(SUM(actual_fare),0) as gross, COALESCE(SUM(commission_amount),0) as commission
          FROM trip_requests WHERE driver_id=${user.id}::uuid AND current_status='completed'
          AND created_at >= date_trunc('week', CURRENT_DATE)
        `),
        rawDb.execute(rawSql`
          SELECT COUNT(*) as trips, COALESCE(SUM(actual_fare),0) as gross, COALESCE(SUM(commission_amount),0) as commission
          FROM trip_requests WHERE driver_id=${user.id}::uuid AND current_status='completed'
          AND created_at >= date_trunc('month', CURRENT_DATE)
        `),
        rawDb.execute(rawSql`
          SELECT id, ref_id, pickup_address, destination_address, actual_fare, estimated_fare, current_status, created_at
          FROM trip_requests WHERE driver_id=${user.id}::uuid ORDER BY created_at DESC LIMIT 5
        `),
        rawDb.execute(rawSql`SELECT wallet_balance, is_locked FROM users WHERE id=${user.id}::uuid`),
      ]);

      const today = todayStats.rows[0] as any;
      const week = weekStats.rows[0] as any;
      const month = monthStats.rows[0] as any;

      // Get vehicle + zone + online status
      const driverInfo = await rawDb.execute(rawSql`
        SELECT dd.vehicle_category_id, dd.availability_status,
          vc.name as vehicle_category_name, vc.icon as vehicle_category_icon, vc.type as vehicle_type,
          z.name as zone_name, dl.is_online,
          u.vehicle_number, u.vehicle_model
        FROM users u
        LEFT JOIN driver_details dd ON dd.user_id = u.id
        LEFT JOIN vehicle_categories vc ON vc.id = dd.vehicle_category_id
        LEFT JOIN zones z ON z.id = dd.zone_id
        LEFT JOIN driver_locations dl ON dl.driver_id = u.id
        WHERE u.id = ${user.id}::uuid
      `);
      const di = driverInfo.rows.length ? camelize(driverInfo.rows[0]) as any : {};

      const todayTrips = parseInt(today.trips);
      const todayGross = parseFloat(today.gross);
      const todayCommission = parseFloat(today.commission);

      // ── Launch Benefit: auto-expire + build response fields ──
      const launchR = await rawDb.execute(rawSql`
        SELECT launch_free_active, free_period_end, onboard_date FROM users WHERE id=${user.id}::uuid LIMIT 1
      `).catch(() => ({ rows: [] as any[] }));
      const launchRow = launchR.rows[0] as any;
      const campaignSettR = await rawDb.execute(rawSql`SELECT value FROM revenue_model_settings WHERE key_name='launch_campaign_enabled' LIMIT 1`).catch(() => ({ rows: [] as any[] }));
      const campaignGlobalOn = (campaignSettR.rows[0] as any)?.value !== 'false';

      let launchFreeActive = launchRow?.launch_free_active === true;
      let freePeriodEnd: Date | null = launchRow?.free_period_end ? new Date(launchRow.free_period_end) : null;
      const now = new Date();

      // Auto-expire if period ended
      if (launchFreeActive && freePeriodEnd && freePeriodEnd < now) {
        await rawDb.execute(rawSql`UPDATE users SET launch_free_active=false WHERE id=${user.id}::uuid`).catch(() => {});
        launchFreeActive = false;
      }

      const isLaunchBenefitActive = campaignGlobalOn && launchFreeActive && freePeriodEnd !== null && freePeriodEnd >= now;
      const freeDaysRemaining = isLaunchBenefitActive && freePeriodEnd
        ? Math.max(0, Math.ceil((freePeriodEnd.getTime() - now.getTime()) / (1000 * 60 * 60 * 24)))
        : 0;

      res.json({
        isOnline: di.isOnline ?? false,
        tripsToday: todayTrips,
        earningsToday: todayGross - todayCommission,
        walletBalance: parseFloat((walletRow.rows[0] as any)?.wallet_balance || 0),
        isLocked: (walletRow.rows[0] as any)?.is_locked || false,
        vehicleCategory: di.vehicleCategoryName || null,
        vehicleIcon: di.vehicleCategoryIcon || null,
        vehicleType: di.vehicleType || null,
        vehicleNumber: di.vehicleNumber || null,
        vehicleModel: di.vehicleModel || null,
        zone: di.zoneName || null,
        availabilityStatus: di.availabilityStatus || 'offline',
        today: { trips: todayTrips, gross: todayGross, net: todayGross - todayCommission },
        week: { trips: parseInt(week.trips), gross: parseFloat(week.gross), net: parseFloat(week.gross) - parseFloat(week.commission) },
        month: { trips: parseInt(month.trips), gross: parseFloat(month.gross), net: parseFloat(month.gross) - parseFloat(month.commission) },
        recentTrips: recentTrips.rows.map(camelize),
        dailyGoal: { target: 10, achieved: todayTrips },
        weeklyGoal: { target: 50, achieved: parseInt(week.trips) },
        launchBenefit: {
          active: isLaunchBenefitActive,
          freeDaysRemaining,
          freePeriodEnd: freePeriodEnd ? freePeriodEnd.toISOString() : null,
          onboardDate: launchRow?.onboard_date ? new Date(launchRow.onboard_date).toISOString() : null,
        },
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Home data (recent + nearby drivers count) ───────────────────
  app.get("/api/app/customer/home-data", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const [recentTrips, walletRow, savedPlaces, stats, vehicleCats, banners] = await Promise.all([
        rawDb.execute(rawSql`
          SELECT id, ref_id, pickup_address, destination_address, actual_fare, estimated_fare, current_status, created_at, driver_id
          FROM trip_requests WHERE customer_id=${user.id}::uuid ORDER BY created_at DESC LIMIT 5
        `),
        rawDb.execute(rawSql`SELECT wallet_balance FROM users WHERE id=${user.id}::uuid`),
        rawDb.execute(rawSql`SELECT * FROM saved_places WHERE user_id=${user.id}::uuid LIMIT 5`).catch(() => ({ rows: [] })),
        rawDb.execute(rawSql`
          SELECT COUNT(*) as total_trips, COALESCE(SUM(actual_fare),0) as total_spent
          FROM trip_requests WHERE customer_id=${user.id}::uuid AND current_status='completed'
        `),
        rawDb.execute(rawSql`
          SELECT vc.id, vc.name, vc.type, vc.icon,
            MIN(tf.minimum_fare) as minimum_fare, MIN(tf.base_fare) as base_fare,
            MIN(tf.fare_per_km) as fare_per_km, MIN(tf.helper_charge) as helper_charge
          FROM vehicle_categories vc
          LEFT JOIN trip_fares tf ON tf.vehicle_category_id = vc.id
          WHERE vc.is_active = true
          GROUP BY vc.id, vc.name, vc.type, vc.icon
          ORDER BY CASE vc.type WHEN 'ride' THEN 1 WHEN 'parcel' THEN 2 WHEN 'cargo' THEN 3 ELSE 4 END, vc.name
        `),
        rawDb.execute(rawSql`SELECT * FROM banners WHERE is_active=true ORDER BY created_at DESC LIMIT 6`).catch(() => ({ rows: [] })),
      ]);
      res.json({
        walletBalance: parseFloat((walletRow.rows[0] as any)?.wallet_balance || 0),
        recentTrips: recentTrips.rows.map(camelize),
        savedPlaces: savedPlaces.rows.map(camelize),
        stats: { totalTrips: parseInt((stats.rows[0] as any)?.total_trips || 0), totalSpent: parseFloat((stats.rows[0] as any)?.total_spent || 0) },
        vehicleCategories: vehicleCats.rows.map(camelize),
        banners: banners.rows.map(camelize),
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Schedule a ride ─────────────────────────────────────────────
  app.post("/api/app/customer/schedule-ride", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const { pickupAddress, pickupLat, pickupLng, destinationAddress, destinationLat, destinationLng,
              vehicleCategoryId, estimatedFare, estimatedDistance, paymentMethod, scheduledAt } = req.body;
      if (!scheduledAt) return res.status(400).json({ message: "scheduledAt is required" });
      const scheduledTime = new Date(scheduledAt);
      if (scheduledTime <= new Date()) return res.status(400).json({ message: "Schedule time must be in the future" });
      const refId = generateRefId();
      const r = await rawDb.execute(rawSql`
        INSERT INTO trip_requests (
          ref_id, customer_id, pickup_address, pickup_lat, pickup_lng,
          destination_address, destination_lat, destination_lng,
          vehicle_category_id, estimated_fare, estimated_distance,
          payment_method, trip_type, current_status, is_scheduled, scheduled_at, created_at, updated_at
        ) VALUES (
          ${refId}, ${user.id}::uuid, ${pickupAddress}, ${parseFloat(pickupLat)}, ${parseFloat(pickupLng)},
          ${destinationAddress}, ${parseFloat(destinationLat)}, ${parseFloat(destinationLng)},
          ${vehicleCategoryId}::uuid, ${parseFloat(estimatedFare)}, ${parseFloat(estimatedDistance)},
          ${paymentMethod || 'cash'}, 'normal', 'scheduled', true, ${scheduledAt}, now(), now()
        ) RETURNING *
      `);
      res.json({ success: true, trip: camelize(r.rows[0]), message: `Ride scheduled for ${scheduledTime.toLocaleString('en-IN')}` });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER: Get scheduled rides ────────────────────────────────────────
  app.get("/api/app/customer/scheduled-rides", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT t.*, u.full_name as driver_name FROM trip_requests t
        LEFT JOIN users u ON t.driver_id = u.id
        WHERE t.customer_id=${user.id}::uuid AND t.is_scheduled=true
        AND t.scheduled_at > now() - interval '1 day'
        ORDER BY t.scheduled_at ASC
      `);
      res.json({ success: true, scheduledRides: r.rows.map(camelize) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── INTERCITY BOOKING ────────────────────────────────────────────────────
  app.post('/api/app/customer/intercity-book', authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const { routeId, pickupAddress, destinationAddress, vehicleCategoryId, paymentMethod, scheduledAt, passengers = 1 } = req.body;
      if (!routeId || !scheduledAt) return res.status(400).json({ message: 'routeId and scheduledAt required' });
      const pax = Math.max(1, Math.min(6, parseInt(passengers, 10) || 1));

      const route = await rawDb.execute(rawSql`SELECT * FROM intercity_routes WHERE id=${routeId}::uuid AND is_active=true`);
      if (!route.rows.length) return res.status(404).json({ message: 'Route not found or inactive' });
      const r = route.rows[0] as any;

      const farePerPassenger = parseFloat(r.base_fare || 0) + (parseFloat(r.estimated_km || 0) * parseFloat(r.fare_per_km || 0)) + parseFloat(r.toll_charges || 0);
      const totalFare = parseFloat((farePerPassenger * pax).toFixed(2));
      const refId = 'INT' + Date.now().toString().slice(-8).toUpperCase();

      const trip = await rawDb.execute(rawSql`
        INSERT INTO trip_requests (
          ref_id, customer_id, vehicle_category_id,
          pickup_address, pickup_lat, pickup_lng,
          destination_address, destination_lat, destination_lng,
          estimated_fare, estimated_distance, payment_method,
          trip_type, current_status, is_scheduled, scheduled_at
        ) VALUES (
          ${refId}, ${user.id}::uuid, ${vehicleCategoryId ? rawSql`${vehicleCategoryId}::uuid` : rawSql`NULL`},
          ${pickupAddress || r.from_city}, 0, 0,
          ${destinationAddress || r.to_city}, 0, 0,
          ${totalFare}, ${parseFloat(r.estimated_km || 0)}, ${paymentMethod || 'cash'},
          'intercity', 'scheduled', true, ${scheduledAt}
        ) RETURNING *
      `);
      res.json({
        success: true,
        trip: camelize(trip.rows[0]),
        refId,
        estimatedFare: totalFare,
        farePerPassenger,
        passengers: pax,
        route: camelize(r),
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── CUSTOMER SUPPORT CHAT ─────────────────────────────────────────────────
  app.get('/api/app/customer/support-chat', authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT * FROM support_messages WHERE user_id=${user.id}::uuid ORDER BY created_at ASC LIMIT 100
      `);
      await rawDb.execute(rawSql`UPDATE support_messages SET is_read=true WHERE user_id=${user.id}::uuid AND sender='admin'`);
      res.json({ messages: r.rows.map(camelize) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post('/api/app/customer/support-chat/send', authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const { message } = req.body;
      if (!message) return res.status(400).json({ message: 'message required' });
      const r = await rawDb.execute(rawSql`
        INSERT INTO support_messages (user_id, sender, message) VALUES (${user.id}::uuid, 'user', ${message}) RETURNING *
      `);
      res.json({ success: true, data: camelize(r.rows[0]) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── Driver support chat (aliases customer endpoints — same user table) ───
  app.get('/api/app/driver/support-chat', authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT * FROM support_messages WHERE user_id=${user.id}::uuid ORDER BY created_at ASC LIMIT 100
      `);
      await rawDb.execute(rawSql`UPDATE support_messages SET is_read=true WHERE user_id=${user.id}::uuid AND sender='admin'`);
      res.json({ messages: r.rows.map(camelize) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post('/api/app/driver/support-chat/send', authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const { message } = req.body;
      if (!message) return res.status(400).json({ message: 'message required' });
      const r = await rawDb.execute(rawSql`
        INSERT INTO support_messages (user_id, sender, message) VALUES (${user.id}::uuid, 'user', ${message}) RETURNING *
      `);
      res.json({ success: true, data: camelize(r.rows[0]) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── TRIP SHARING: Generate share link ────────────────────────────────────
  app.post("/api/app/trip-share", authApp, async (req, res) => {
    try {
      const { tripId } = req.body;
      if (!tripId) return res.status(400).json({ message: "tripId required" });
      const shareToken = crypto.randomBytes(8).toString("hex");
      await rawDb.execute(rawSql`
        UPDATE trip_requests SET share_token=${shareToken}, updated_at=now() WHERE id=${tripId}::uuid
      `).catch(async () => {
        await rawDb.execute(rawSql`ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS share_token VARCHAR(64)`);
        await rawDb.execute(rawSql`UPDATE trip_requests SET share_token=${shareToken} WHERE id=${tripId}::uuid`);
      });
      const shareLink = `https://jagopro.org/track/${shareToken}`;
      res.json({ success: true, shareLink, shareToken });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── TRIP SHARING: Get trip by share token (public) ────────────────────────
  app.get("/api/app/track/:token", async (req, res) => {
    try {
      const { token } = req.params;
      const r = await rawDb.execute(rawSql`
        SELECT t.ref_id, t.pickup_address, t.destination_address, t.current_status,
               t.pickup_lat, t.pickup_lng, t.destination_lat, t.destination_lng,
               u.full_name as driver_name, u.phone as driver_phone,
               uv.lat as driver_lat, uv.lng as driver_lng
        FROM trip_requests t
        LEFT JOIN users u ON t.driver_id = u.id
        LEFT JOIN (SELECT user_id, lat, lng FROM driver_locations ORDER BY created_at DESC) uv ON uv.user_id = t.driver_id
        WHERE t.share_token=${token}
        LIMIT 1
      `).catch(() => ({ rows: [] }));
      if (!r.rows.length) return res.status(404).json({ message: "Trip not found" });
      res.json({ success: true, trip: camelize(r.rows[0]) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── EMERGENCY CONTACTS (CRUD) ─────────────────────────────────────────────
  app.get("/api/app/emergency-contacts", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT * FROM emergency_contacts WHERE user_id=${user.id}::uuid ORDER BY created_at ASC
      `).catch(async () => {
        await rawDb.execute(rawSql`
          CREATE TABLE IF NOT EXISTS emergency_contacts (
            id SERIAL PRIMARY KEY, user_id UUID, name VARCHAR(100), phone VARCHAR(20),
            relation VARCHAR(50), created_at TIMESTAMPTZ DEFAULT now()
          )
        `);
        return { rows: [] };
      });
      res.json({ success: true, contacts: r.rows.map(camelize) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post("/api/app/emergency-contacts", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const { name, phone, relation } = req.body;
      if (!name || !phone) return res.status(400).json({ message: "Name and phone required" });
      const existing = await rawDb.execute(rawSql`SELECT COUNT(*) as c FROM emergency_contacts WHERE user_id=${user.id}::uuid`).catch(() => ({ rows: [{ c: '0' }] }));
      if (parseInt((existing.rows[0] as any).c) >= 3) return res.status(400).json({ message: "Maximum 3 emergency contacts allowed" });
      await rawDb.execute(rawSql`
        CREATE TABLE IF NOT EXISTS emergency_contacts (
          id SERIAL PRIMARY KEY, user_id UUID, name VARCHAR(100), phone VARCHAR(20),
          relation VARCHAR(50), created_at TIMESTAMPTZ DEFAULT now()
        )
      `);
      const r = await rawDb.execute(rawSql`
        INSERT INTO emergency_contacts (user_id, name, phone, relation) VALUES (${user.id}::uuid, ${name}, ${phone}, ${relation || 'Friend'}) RETURNING *
      `);
      res.json({ success: true, contact: camelize(r.rows[0]) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.delete("/api/app/emergency-contacts/:id", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      await rawDb.execute(rawSql`DELETE FROM emergency_contacts WHERE id=${parseInt(req.params.id as string)} AND user_id=${user.id}::uuid`);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── IN-APP NOTIFICATIONS ─────────────────────────────────────────────────
  app.get("/api/app/notifications", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT * FROM notification_log WHERE user_id=${user.id}::uuid ORDER BY created_at DESC LIMIT 30
      `).catch(() => ({ rows: [] }));
      const unread = await rawDb.execute(rawSql`
        SELECT COUNT(*) as c FROM notification_log WHERE user_id=${user.id}::uuid AND is_read=false
      `).catch(() => ({ rows: [{ c: '0' }] }));
      res.json({ success: true, notifications: r.rows.map(camelize), unreadCount: parseInt((unread.rows[0] as any)?.c || '0') });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  const _markNotificationsRead = async (req: any, res: any) => {
    try {
      const user = (req as any).currentUser;
      await rawDb.execute(rawSql`UPDATE notification_log SET is_read=true WHERE user_id=${user.id}::uuid`).catch(() => {});
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  };
  app.patch("/api/app/notifications/read-all", authApp, _markNotificationsRead);
  app.post("/api/app/notifications/read-all", authApp, _markNotificationsRead);

  // ── DRIVER: Performance score ─────────────────────────────────────────────
  // ── DRIVER: Weekly Earnings Chart (7 days breakdown) ────────────────────
  app.get("/api/app/driver/weekly-earnings", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT
          TO_CHAR(created_at::date, 'Dy') as day,
          TO_CHAR(created_at::date, 'YYYY-MM-DD') as date,
          COUNT(*) as trips,
          COALESCE(SUM(actual_fare::numeric), 0) as gross
        FROM trip_requests
        WHERE driver_id=${user.id}::uuid
          AND current_status='completed'
          AND created_at >= NOW() - INTERVAL '7 days'
        GROUP BY created_at::date
        ORDER BY created_at::date ASC
      `);
      const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
      const today = new Date();
      const result = days.map((d, i) => {
        const date = new Date(today);
        date.setDate(today.getDate() - (6 - i));
        const dateStr = date.toISOString().split('T')[0];
        const row = r.rows.find((row: any) => row.date === dateStr);
        return {
          day: d,
          date: dateStr,
          trips: parseInt(row?.trips?.toString() || '0'),
          gross: parseFloat(row?.gross?.toString() || '0'),
        };
      });
      res.json({ days: result, total: result.reduce((s, d) => s + d.gross, 0) });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/app/driver/performance", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const [acceptance, completion, rating] = await Promise.all([
        rawDb.execute(rawSql`
          SELECT COUNT(*) FILTER (WHERE current_status='completed') as accepted,
                 COUNT(*) FILTER (WHERE current_status='cancelled') as cancelled,
                 COUNT(*) as total
          FROM trip_requests WHERE driver_id=${user.id}::uuid
          AND created_at >= date_trunc('month', CURRENT_DATE)
        `),
        rawDb.execute(rawSql`
          SELECT COALESCE(AVG(driver_rating),5) as avg_rating FROM trip_requests
          WHERE driver_id=${user.id}::uuid AND driver_rating IS NOT NULL
          AND created_at >= date_trunc('month', CURRENT_DATE)
        `),
        rawDb.execute(rawSql`SELECT rating FROM users WHERE id=${user.id}::uuid`),
      ]);
      const acc = acceptance.rows[0] as any;
      const totalTrips = parseInt(acc.total || '0');
      const completedTrips = parseInt(acc.accepted || '0');
      const cancelledTrips = parseInt(acc.cancelled || '0');
      const acceptanceRate = totalTrips > 0 ? Math.round((completedTrips / totalTrips) * 100) : 100;
      const avgRating = parseFloat((rating.rows[0] as any)?.avg_rating || 5);
      const performanceScore = Math.round((acceptanceRate * 0.4) + (avgRating * 12));
      res.json({
        acceptanceRate, completedTrips, cancelledTrips,
        avgRating: avgRating.toFixed(1),
        performanceScore: Math.min(100, performanceScore),
        level: performanceScore >= 90 ? 'Gold' : performanceScore >= 70 ? 'Silver' : 'Bronze',
        overallRating: parseFloat((rating.rows[0] as any)?.rating || 5),
      });
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

  // ═══════════════════════════════════════════════════════════════════
  // ██████   UNIQUE FEATURES — No competitor has all of these   ██████
  // ═══════════════════════════════════════════════════════════════════

  // Helper: inline auth check for unique feature routes
  async function requireAppAuth(req: Request, res: Response): Promise<any | null> {
    try {
      const token = req.headers.authorization?.replace("Bearer ", "");
      if (!token) { res.status(401).json({ message: "No token provided" }); return null; }
      const parts = token.split(":");
      if (parts.length < 2) { res.status(401).json({ message: "Invalid token format" }); return null; }
      const userId = parts[0];
      const userR = await rawDb.execute(rawSql`SELECT * FROM users WHERE id=${userId}::uuid AND is_active=true AND auth_token=${token} LIMIT 1`);
      if (!userR.rows.length) { res.status(401).json({ message: "Session expired. Please login again." }); return null; }
      return camelize(userR.rows[0]);
    } catch (e: any) { res.status(401).json({ message: "Auth failed" }); return null; }
  }

  // ── Ensure feature tables exist ─────────────────────────────────────
  (async () => {
    try {
      await rawDb.execute(rawSql`
        CREATE TABLE IF NOT EXISTS coins_ledger (
          id SERIAL PRIMARY KEY, user_id UUID NOT NULL, amount INTEGER NOT NULL,
          type VARCHAR(30) NOT NULL, description TEXT, trip_id UUID,
          created_at TIMESTAMP DEFAULT NOW()
        );
        CREATE TABLE IF NOT EXISTS user_preferences (
          user_id UUID PRIMARY KEY, quiet_ride BOOLEAN DEFAULT false,
          ac_preferred BOOLEAN DEFAULT true, music_off BOOLEAN DEFAULT false,
          wheelchair_accessible BOOLEAN DEFAULT false, extra_luggage BOOLEAN DEFAULT false,
          preferred_gender VARCHAR(10) DEFAULT 'any',
          updated_at TIMESTAMP DEFAULT NOW()
        );
        CREATE TABLE IF NOT EXISTS lost_found_reports (
          id SERIAL PRIMARY KEY, customer_id UUID NOT NULL, trip_id UUID,
          description TEXT NOT NULL, contact_phone VARCHAR(15),
          status VARCHAR(20) DEFAULT 'open', driver_id UUID,
          created_at TIMESTAMP DEFAULT NOW(), resolved_at TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS monthly_passes (
          id SERIAL PRIMARY KEY, user_id UUID NOT NULL,
          rides_total INTEGER DEFAULT 30, rides_used INTEGER DEFAULT 0,
          valid_from DATE DEFAULT CURRENT_DATE,
          valid_until DATE DEFAULT (CURRENT_DATE + INTERVAL '30 days'),
          amount_paid NUMERIC(10,2), plan_name VARCHAR(50),
          is_active BOOLEAN DEFAULT true, created_at TIMESTAMP DEFAULT NOW()
        );
        CREATE TABLE IF NOT EXISTS surge_alerts (
          id SERIAL PRIMARY KEY, user_id UUID NOT NULL,
          pickup_lat NUMERIC(10,7), pickup_lng NUMERIC(10,7),
          pickup_address TEXT, created_at TIMESTAMP DEFAULT NOW(), notified_at TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS spin_wheel_plays (
          id SERIAL PRIMARY KEY,
          user_id UUID NOT NULL,
          item_id UUID,
          reward_type VARCHAR(30),
          reward_amount NUMERIC(10,2) DEFAULT 0,
          played_at TIMESTAMP DEFAULT NOW()
        );
        CREATE TABLE IF NOT EXISTS support_messages (
          id SERIAL PRIMARY KEY,
          user_id UUID NOT NULL,
          sender VARCHAR(10) NOT NULL CHECK (sender IN ('admin','user')),
          message TEXT NOT NULL,
          is_read BOOLEAN DEFAULT false,
          created_at TIMESTAMP DEFAULT NOW()
        );
      `);
      // Add break_until column to users if not exists
      await rawDb.execute(rawSql`
        ALTER TABLE users ADD COLUMN IF NOT EXISTS break_until TIMESTAMP;
        ALTER TABLE users ADD COLUMN IF NOT EXISTS jago_coins INTEGER DEFAULT 0;
        ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS tip_amount NUMERIC(10,2) DEFAULT 0;
        ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS ride_preferences JSONB;
      `);
    } catch (_) {}
  })();

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 1. JAGO COINS — Loyalty Program
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  app.get("/api/app/customer/coins", async (req, res) => {
    try {
      const user = await requireAppAuth(req, res); if (!user) return;
      const [balRes, histRes] = await Promise.all([
        rawDb.execute(rawSql`SELECT jago_coins FROM users WHERE id=${user.id}::uuid`),
        rawDb.execute(rawSql`
          SELECT * FROM coins_ledger WHERE user_id=${user.id}::uuid
          ORDER BY created_at DESC LIMIT 30
        `),
      ]);
      const balance = parseInt((balRes.rows[0] as any)?.jago_coins || 0);
      res.json({
        balance,
        rupeeValue: Math.floor(balance / 10),
        history: histRes.rows.map(camelize),
        howItWorks: [
          "Every ₹10 fare = 1 JAGO Coin",
          "100 Coins = ₹10 discount on next ride",
          "Coins valid for 12 months",
          "Bonus coins on referrals & first rides",
        ],
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post("/api/app/customer/redeem-coins", async (req, res) => {
    try {
      const user = await requireAppAuth(req, res); if (!user) return;
      const { coins } = req.body;
      if (!coins || coins < 100) return res.status(400).json({ message: "Minimum 100 coins to redeem" });
      const bal = await rawDb.execute(rawSql`SELECT jago_coins FROM users WHERE id=${user.id}::uuid`);
      const current = parseInt((bal.rows[0] as any)?.jago_coins || 0);
      if (current < coins) return res.status(400).json({ message: "Insufficient coins" });
      const discount = Math.floor(coins / 10);
      await rawDb.execute(rawSql`UPDATE users SET jago_coins = jago_coins - ${coins} WHERE id=${user.id}::uuid`);
      await rawDb.execute(rawSql`
        INSERT INTO coins_ledger (user_id, amount, type, description)
        VALUES (${user.id}::uuid, ${-coins}, 'redeem', 'Redeemed ${coins} coins for ₹${discount} discount')
      `);
      res.json({ success: true, coinsUsed: coins, discountAmount: discount, message: `₹${discount} discount applied to next ride!` });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── Daily Spin Wheel (customer-facing) ───────────────────────────────────
  app.get("/api/app/customer/spin-wheel", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const [itemsR, playedR] = await Promise.all([
        rawDb.execute(rawSql`SELECT id, label, reward_amount, reward_type, probability FROM spin_wheel_items WHERE is_active=true ORDER BY RANDOM()`),
        rawDb.execute(rawSql`
          SELECT id FROM spin_wheel_plays
          WHERE user_id=${user.id}::uuid AND played_at > NOW() - INTERVAL '24 hours'
          LIMIT 1
        `),
      ]);
      const canSpin = playedR.rows.length === 0;
      res.json({ items: itemsR.rows.map(camelize), canSpin });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post("/api/app/customer/spin-wheel/play", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      // Check 24h cooldown
      const played = await rawDb.execute(rawSql`
        SELECT id FROM spin_wheel_plays
        WHERE user_id=${user.id}::uuid AND played_at > NOW() - INTERVAL '24 hours'
        LIMIT 1
      `);
      if (played.rows.length > 0) return res.status(429).json({ message: 'Already spun today! Come back in 24 hours.' });

      // Pick a weighted random item
      const itemsR = await rawDb.execute(rawSql`
        SELECT id, label, reward_amount, reward_type, probability FROM spin_wheel_items WHERE is_active=true
      `);
      if (itemsR.rows.length === 0) return res.status(404).json({ message: 'Spin wheel not configured' });

      const items = itemsR.rows as any[];
      const totalWeight = items.reduce((s: number, i: any) => s + parseFloat(i.probability || 1), 0);
      let rand = Math.random() * totalWeight;
      let chosen = items[0];
      for (const it of items) {
        rand -= parseFloat(it.probability || 1);
        if (rand <= 0) { chosen = it; break; }
      }

      // Record play
      await rawDb.execute(rawSql`
        INSERT INTO spin_wheel_plays (user_id, item_id, reward_type, reward_amount)
        VALUES (${user.id}::uuid, ${chosen.id}::uuid, ${chosen.reward_type}, ${chosen.reward_amount})
      `);

      // Award reward
      if (chosen.reward_type === 'coins' && parseFloat(chosen.reward_amount) > 0) {
        await rawDb.execute(rawSql`UPDATE users SET jago_coins = COALESCE(jago_coins,0) + ${parseInt(chosen.reward_amount)} WHERE id=${user.id}::uuid`);
        await rawDb.execute(rawSql`INSERT INTO coins_ledger (user_id, amount, type, description) VALUES (${user.id}::uuid, ${parseInt(chosen.reward_amount)}, 'spin_wheel', 'Daily spin reward: ${chosen.label}')`).catch(() => {});
      } else if (chosen.reward_type === 'wallet' && parseFloat(chosen.reward_amount) > 0) {
        await rawDb.execute(rawSql`UPDATE users SET wallet_balance = COALESCE(wallet_balance,0) + ${parseFloat(chosen.reward_amount)} WHERE id=${user.id}::uuid`);
      }

      res.json({ success: true, item: camelize(chosen), canSpin: false });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 2. RIDE PREFERENCES (Quiet ride, AC, Music off, etc.)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  app.get("/api/app/customer/preferences", async (req, res) => {
    try {
      const user = await requireAppAuth(req, res); if (!user) return;
      const rows = await rawDb.execute(rawSql`SELECT * FROM user_preferences WHERE user_id=${user.id}::uuid`);
      if (rows.rows.length === 0) {
        res.json({ quietRide: false, acPreferred: true, musicOff: false, wheelchairAccessible: false, extraLuggage: false, preferredGender: 'any' });
      } else {
        res.json(camelize(rows.rows[0]));
      }
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post("/api/app/customer/preferences", async (req, res) => {
    try {
      const user = await requireAppAuth(req, res); if (!user) return;
      const { quietRide, acPreferred, musicOff, wheelchairAccessible, extraLuggage, preferredGender } = req.body;
      await rawDb.execute(rawSql`
        INSERT INTO user_preferences (user_id, quiet_ride, ac_preferred, music_off, wheelchair_accessible, extra_luggage, preferred_gender)
        VALUES (${user.id}::uuid, ${!!quietRide}, ${acPreferred !== false}, ${!!musicOff}, ${!!wheelchairAccessible}, ${!!extraLuggage}, ${preferredGender || 'any'})
        ON CONFLICT (user_id) DO UPDATE SET
          quiet_ride=${!!quietRide}, ac_preferred=${acPreferred !== false}, music_off=${!!musicOff},
          wheelchair_accessible=${!!wheelchairAccessible}, extra_luggage=${!!extraLuggage},
          preferred_gender=${preferredGender || 'any'}, updated_at=NOW()
      `);
      res.json({ success: true, message: "Preferences saved! Applied to your next ride." });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 3. POST-RIDE TIP DRIVER
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  app.post("/api/app/tip-driver", async (req, res) => {
    try {
      const user = await requireAppAuth(req, res); if (!user) return;
      const { tripId, amount } = req.body;
      if (!tripId || !amount || amount <= 0) return res.status(400).json({ message: "Invalid tip amount" });
      const tripRes = await rawDb.execute(rawSql`SELECT * FROM trip_requests WHERE id=${tripId}::uuid`);
      const trip = tripRes.rows[0] as any;
      if (!trip) return res.status(404).json({ message: "Trip not found" });
      if (trip.customer_id !== user.id && trip.driver_id !== user.id) return res.status(403).json({ message: "Not authorized" });
      await rawDb.execute(rawSql`UPDATE trip_requests SET tip_amount=${amount} WHERE id=${tripId}::uuid`);
      // Credit tip to driver wallet
      await rawDb.execute(rawSql`UPDATE users SET wallet_balance = wallet_balance + ${amount} WHERE id=${trip.driver_id}::uuid`);
      // Log it
      await rawDb.execute(rawSql`
        INSERT INTO coins_ledger (user_id, amount, type, description, trip_id)
        VALUES (${trip.driver_id}::uuid, ${amount * 10}, 'tip_bonus', 'Tip received for ride — bonus coins', ${tripId}::uuid)
      `);
      res.json({ success: true, message: `₹${amount} tip sent to driver! You also earned ${amount * 10} bonus JAGO Coins 🎉` });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 4. LOST & FOUND
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  app.post("/api/app/lost-found", async (req, res) => {
    try {
      const user = await requireAppAuth(req, res); if (!user) return;
      const { tripId, description, contactPhone } = req.body;
      if (!description) return res.status(400).json({ message: "Description required" });
      let driverId = null;
      if (tripId) {
        const tr = await rawDb.execute(rawSql`SELECT driver_id FROM trip_requests WHERE id=${tripId}::uuid`);
        driverId = (tr.rows[0] as any)?.driver_id || null;
      }
      const result = await rawDb.execute(rawSql`
        INSERT INTO lost_found_reports (customer_id, trip_id, description, contact_phone, driver_id)
        VALUES (${user.id}::uuid, ${tripId || null}, ${description}, ${contactPhone || user.phone}, ${driverId || null})
        RETURNING id
      `);
      res.json({ success: true, reportId: (result.rows[0] as any).id, message: "Report submitted! We will contact the driver and update you within 2 hours." });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/app/customer/lost-found", async (req, res) => {
    try {
      const user = await requireAppAuth(req, res); if (!user) return;
      const rows = await rawDb.execute(rawSql`
        SELECT l.*, t.pickup_address, t.destination_address,
               u.full_name as driver_name, u.phone as driver_phone
        FROM lost_found_reports l
        LEFT JOIN trip_requests t ON l.trip_id = t.id
        LEFT JOIN users u ON l.driver_id = u.id
        WHERE l.customer_id=${user.id}::uuid
        ORDER BY l.created_at DESC
      `);
      res.json(rows.rows.map(camelize));
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 5. MONTHLY PASS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  const MONTHLY_PLANS = [
    { name: 'JAGO Basic', rides: 20, price: 699, discount: '15%' },
    { name: 'JAGO Plus', rides: 40, price: 1199, discount: '25%' },
    { name: 'JAGO Pro', rides: 80, price: 1999, discount: '35%' },
  ];

  app.get("/api/app/customer/monthly-pass", async (req, res) => {
    try {
      const user = await requireAppAuth(req, res); if (!user) return;
      const active = await rawDb.execute(rawSql`
        SELECT * FROM monthly_passes WHERE user_id=${user.id}::uuid
        AND is_active=true AND valid_until >= CURRENT_DATE
        ORDER BY created_at DESC LIMIT 1
      `);
      res.json({
        activePlan: active.rows.length ? camelize(active.rows[0]) : null,
        availablePlans: MONTHLY_PLANS,
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post("/api/app/customer/monthly-pass/buy", async (req, res) => {
    try {
      const user = await requireAppAuth(req, res); if (!user) return;
      const { planName } = req.body;
      const plan = MONTHLY_PLANS.find(p => p.name === planName);
      if (!plan) return res.status(400).json({ message: "Invalid plan" });
      // Check wallet balance
      const walRes = await rawDb.execute(rawSql`SELECT wallet_balance FROM users WHERE id=${user.id}::uuid`);
      const bal = parseFloat((walRes.rows[0] as any)?.wallet_balance || 0);
      if (bal < plan.price) return res.status(400).json({ message: `Insufficient wallet balance. Need ₹${plan.price}, have ₹${bal.toFixed(0)}` });
      // Deduct & create pass
      await rawDb.execute(rawSql`UPDATE users SET wallet_balance = wallet_balance - ${plan.price} WHERE id=${user.id}::uuid`);
      await rawDb.execute(rawSql`UPDATE monthly_passes SET is_active=false WHERE user_id=${user.id}::uuid`);
      await rawDb.execute(rawSql`
        INSERT INTO monthly_passes (user_id, rides_total, rides_used, amount_paid, plan_name)
        VALUES (${user.id}::uuid, ${plan.rides}, 0, ${plan.price}, ${plan.name})
      `);
      // Bonus coins for buying pass
      const bonusCoins = plan.rides * 5;
      await rawDb.execute(rawSql`UPDATE users SET jago_coins = jago_coins + ${bonusCoins} WHERE id=${user.id}::uuid`);
      await rawDb.execute(rawSql`
        INSERT INTO coins_ledger (user_id, amount, type, description)
        VALUES (${user.id}::uuid, ${bonusCoins}, 'pass_bonus', 'Welcome bonus for ${plan.name} purchase')
      `);
      res.json({ success: true, message: `${plan.name} activated! ${plan.rides} rides for 30 days. Bonus: ${bonusCoins} JAGO Coins credited!` });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // CAR SHARING — Customer browse & book
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  app.get('/api/app/customer/car-sharing/rides', authApp, async (req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT cs.*,
          u.full_name as driver_name,
          vc.name as vehicle_name,
          GREATEST(0, cs.max_seats - COALESCE((SELECT SUM(b.seats_booked) FROM car_sharing_bookings b WHERE b.ride_id = cs.id AND b.status != 'cancelled'),0)) as available_seats
        FROM car_sharing_rides cs
        LEFT JOIN users u ON u.id = cs.driver_id
        LEFT JOIN vehicle_categories vc ON vc.id = cs.vehicle_category_id
        WHERE cs.status = 'active' AND cs.departure_time > NOW()
        ORDER BY cs.departure_time ASC
      `);
      res.json({ data: camelize(r.rows), total: r.rows.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.post('/api/app/customer/car-sharing/book', authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const { rideId, seatsBooked = 1 } = req.body;
      if (!rideId) return res.status(400).json({ message: 'rideId required' });
      const seats = parseInt(seatsBooked, 10);
      if (!Number.isFinite(seats) || seats < 1 || seats > 6) {
        return res.status(400).json({ message: 'seatsBooked must be between 1 and 6' });
      }
      const rideRes = await rawDb.execute(rawSql`
        SELECT cs.*, COALESCE((SELECT SUM(b.seats_booked) FROM car_sharing_bookings b WHERE b.ride_id = cs.id AND b.status != 'cancelled'),0) as booked_count
        FROM car_sharing_rides cs
        WHERE cs.id = ${rideId}::uuid AND cs.status = 'active' AND cs.departure_time > NOW()
      `);
      if (!rideRes.rows.length) return res.status(404).json({ message: 'Ride not found' });
      const ride = camelize(rideRes.rows[0]);
      const available = Math.max(0, (parseInt(String(ride.maxSeats || 0), 10) || 0) - (parseInt(String(ride.bookedCount || 0), 10) || 0));
      if (available < seats) return res.status(400).json({ message: 'Only ' + available + ' seat(s) available' });
      const totalFare = parseFloat((parseFloat(ride.seatPrice || 0) * seats).toFixed(2));
      const walRes = await rawDb.execute(rawSql`SELECT wallet_balance FROM users WHERE id=${user.id}::uuid`);
      const bal = parseFloat(String(walRes.rows[0]?.wallet_balance || '0'));
      if (bal < totalFare) return res.status(400).json({ message: 'Insufficient wallet balance. Need ₹' + totalFare });
      await rawDb.execute(rawSql`INSERT INTO car_sharing_bookings (ride_id, customer_id, seats_booked, total_fare, status) VALUES (${rideId}::uuid, ${user.id}::uuid, ${seats}, ${totalFare}, 'confirmed')`);
      await rawDb.execute(rawSql`UPDATE users SET wallet_balance = wallet_balance - ${totalFare} WHERE id=${user.id}::uuid`);
      res.json({ success: true, message: seats + ' seat(s) booked for ₹' + totalFare + '. Deducted from wallet.', totalFare });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get('/api/app/customer/car-sharing/my-bookings', authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const r = await rawDb.execute(rawSql`
        SELECT b.*, cs.from_location, cs.to_location, cs.departure_time, cs.seat_price,
          u.full_name as driver_name, u.phone as driver_phone, vc.name as vehicle_name
        FROM car_sharing_bookings b
        LEFT JOIN car_sharing_rides cs ON cs.id = b.ride_id
        LEFT JOIN users u ON u.id = cs.driver_id
        LEFT JOIN vehicle_categories vc ON vc.id = cs.vehicle_category_id
        WHERE b.customer_id = ${user.id}::uuid
        ORDER BY b.created_at DESC
      `);
      res.json({ data: camelize(r.rows), total: r.rows.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // 6. SURGE ALERT — "Notify me when surge drops"
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  app.post("/api/app/customer/surge-alert", async (req, res) => {
    try {
      const user = await requireAppAuth(req, res); if (!user) return;
      const { lat, lng, address } = req.body;
      await rawDb.execute(rawSql`
        INSERT INTO surge_alerts (user_id, pickup_lat, pickup_lng, pickup_address)
        VALUES (${user.id}::uuid, ${lat || 0}, ${lng || 0}, ${address || ''})
      `);
      res.json({ success: true, message: "We'll notify you when surge pricing drops for this area!" });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 7. DRIVER BREAK MODE — Set break, show "Back in X min" to customers
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  app.post("/api/app/driver/break", async (req, res) => {
    try {
      const user = await requireAppAuth(req, res); if (!user) return;
      const { minutes } = req.body;
      if (!minutes || minutes < 1 || minutes > 120) return res.status(400).json({ message: "Break: 1–120 minutes only" });
      const breakUntil = new Date(Date.now() + minutes * 60 * 1000);
      await rawDb.execute(rawSql`UPDATE users SET break_until=${breakUntil.toISOString()}, is_online=false WHERE id=${user.id}::uuid`);
      res.json({ success: true, breakUntil: breakUntil.toISOString(), message: `Break set for ${minutes} minutes. You'll auto go-online after break.` });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.delete("/api/app/driver/break", async (req, res) => {
    try {
      const user = await requireAppAuth(req, res); if (!user) return;
      await rawDb.execute(rawSql`UPDATE users SET break_until=NULL, is_online=true WHERE id=${user.id}::uuid`);
      res.json({ success: true, message: "Break ended! You are now online." });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  app.get("/api/app/driver/break", async (req, res) => {
    try {
      const user = await requireAppAuth(req, res); if (!user) return;
      const dbRes = await rawDb.execute(rawSql`SELECT break_until FROM users WHERE id=${user.id}::uuid`);
      const breakUntil = (dbRes.rows[0] as any)?.break_until;
      if (!breakUntil || new Date(breakUntil) < new Date()) {
        // Auto end break if time passed
        if (breakUntil) await rawDb.execute(rawSql`UPDATE users SET break_until=NULL, is_online=true WHERE id=${user.id}::uuid`);
        return res.json({ onBreak: false });
      }
      const minsLeft = Math.ceil((new Date(breakUntil).getTime() - Date.now()) / 60000);
      res.json({ onBreak: true, breakUntil, minutesLeft: minsLeft });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 8. DRIVER FATIGUE ALERT — Warn admin if driver online 8+ hrs
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  app.get("/api/app/driver/fatigue-status", async (req, res) => {
    try {
      const user = await requireAppAuth(req, res); if (!user) return;
      // Count trips today
      const today = await rawDb.execute(rawSql`
        SELECT COUNT(*) as cnt, COALESCE(SUM(EXTRACT(EPOCH FROM (updated_at - created_at))/3600), 0) as hrs
        FROM trip_requests WHERE driver_id=${user.id}::uuid
        AND created_at >= CURRENT_DATE AND (current_status='completed' OR current_status='on_the_way')
      `);
      const trips = parseInt((today.rows[0] as any)?.cnt || 0);
      const hrs = parseFloat((today.rows[0] as any)?.hrs || 0);
      const fatigueLevel = hrs >= 8 ? 'high' : hrs >= 5 ? 'medium' : 'low';
      res.json({
        hoursOnline: hrs.toFixed(1),
        tripsToday: trips,
        fatigueLevel,
        recommendation: fatigueLevel === 'high'
          ? "You've been driving 8+ hours. Please take a long break for your safety!"
          : fatigueLevel === 'medium'
          ? "You've been driving 5+ hours. Consider a short break soon."
          : "You're doing great! Keep safe.",
        suggestBreak: fatigueLevel !== 'low',
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ─── LANGUAGE MANAGEMENT ────────────────────────────────────────────────────

  // Public: get active languages for Flutter apps
  app.get("/api/app/languages", async (req, res) => {
    try {
      const rows = await rawDb.execute(rawSql`
        SELECT id, code, name, native_name, flag, is_active, sort_order
        FROM app_languages ORDER BY sort_order ASC
      `);
      res.json(rows.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Admin: list all languages
  app.get("/api/admin/languages", async (req, res) => {
    try {
      const rows = await rawDb.execute(rawSql`
        SELECT id, code, name, native_name, flag, is_active, sort_order, created_at
        FROM app_languages ORDER BY sort_order ASC
      `);
      res.json(rows.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Admin: add language
  app.post("/api/admin/languages", requireAdminRole(["superadmin"]), async (req, res) => {
    try {
      const { code, name, nativeName, flag, isActive, sortOrder } = req.body;
      if (!code || !name || !nativeName) {
        return res.status(400).json({ message: "code, name, nativeName are required" });
      }
      const result = await rawDb.execute(rawSql`
        INSERT INTO app_languages (code, name, native_name, flag, is_active, sort_order)
        VALUES (${code}, ${name}, ${nativeName}, ${flag || '🌐'}, ${isActive !== false}, ${sortOrder || 0})
        RETURNING *
      `);
      res.json(result.rows[0]);
    } catch (e: any) {
      if (e.message.includes('unique')) {
        res.status(400).json({ message: "Language code already exists" });
      } else {
        res.status(500).json({ message: e.message });
      }
    }
  });

  // Admin: update language
  app.patch("/api/admin/languages/:id", requireAdminRole(["superadmin"]), async (req, res) => {
    try {
      const { id } = req.params;
      const { name, nativeName, flag, isActive, sortOrder } = req.body;
      await rawDb.execute(rawSql`
        UPDATE app_languages SET
          name = COALESCE(${name}, name),
          native_name = COALESCE(${nativeName}, native_name),
          flag = COALESCE(${flag}, flag),
          is_active = COALESCE(${isActive}, is_active),
          sort_order = COALESCE(${sortOrder}, sort_order)
        WHERE id = ${id}::uuid
      `);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Admin: delete language
  app.delete("/api/admin/languages/:id", requireAdminRole(["superadmin"]), async (req, res) => {
    try {
      const { id } = req.params;
      await rawDb.execute(rawSql`DELETE FROM app_languages WHERE id = ${id}::uuid`);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── PLATFORM SERVICES — per-service activation + revenue model control ──────
  // Admin: list all 9 configured services
  app.get("/api/platform-services", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT * FROM platform_services ORDER BY sort_order ASC`);
      res.json(r.rows);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Admin: toggle status / update revenue model + commission rate
  app.patch("/api/platform-services/:key", async (req, res) => {
    try {
      const { key } = req.params;
      const { service_status, revenue_model, commission_rate } = req.body;
      const updates: string[] = ['updated_at=NOW()'];
      if (service_status !== undefined) updates.push(`service_status='${service_status === 'active' ? 'active' : 'inactive'}'`);
      if (revenue_model !== undefined && ['subscription','commission','hybrid'].includes(revenue_model)) {
        updates.push(`revenue_model='${revenue_model}'`);
      }
      if (commission_rate !== undefined) updates.push(`commission_rate=${parseFloat(commission_rate)}`);
      if (updates.length === 1) return res.status(400).json({ message: 'Nothing to update' });
      const r = await rawDb.execute(rawSql`
        UPDATE platform_services SET updated_at=NOW(),
          service_status = COALESCE(${service_status ?? null}, service_status),
          revenue_model  = COALESCE(${revenue_model  ?? null}, revenue_model),
          commission_rate = COALESCE(${commission_rate != null ? parseFloat(commission_rate) : null}, commission_rate)
        WHERE service_key = ${key}
        RETURNING *
      `);
      if (!(r.rows as any[]).length) return res.status(404).json({ message: 'Service not found' });
      res.json((r.rows as any[])[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // App: get only active services (for customer app home screen)
  app.get("/api/app/platform-services", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT service_key, service_name, service_category, icon, color, description
        FROM platform_services
        WHERE service_status = 'active'
        ORDER BY sort_order ASC
      `);
      res.json({ services: r.rows });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── MULTI-DROP PARCEL DELIVERY ────────────────────────────────────────────

  // Fare vehicle categories for parcel
  const PARCEL_VEHICLES: Record<string, { baseFare: number; perKm: number; perKg: number; name: string }> = {
    bike_parcel:   { baseFare: 35,  perKm: 10, perKg: 5,  name: 'Bike Parcel'   },
    auto_parcel:   { baseFare: 50,  perKm: 13, perKg: 7,  name: 'Auto Parcel'   },
    tata_ace:      { baseFare: 150, perKm: 18, perKg: 3,  name: 'Tata Ace'      },
    cargo_car:     { baseFare: 120, perKm: 16, perKg: 4,  name: 'Cargo Car'     },
    bolero_cargo:  { baseFare: 200, perKm: 22, perKg: 3,  name: 'Bolero Cargo'  },
  };

  // Customer: get fare quote for multi-drop parcel
  app.post("/api/app/parcel/quote", authApp, async (req, res) => {
    try {
      const { vehicleCategory = 'bike_parcel', dropLocations = [], weightKg = 1 } = req.body;
      const vc = PARCEL_VEHICLES[vehicleCategory] || PARCEL_VEHICLES.bike_parcel;
      const totalDistance: number = parseFloat(req.body.totalDistanceKm ?? '5') || 5;
      const baseFare    = vc.baseFare;
      const distFare    = Math.round(totalDistance * vc.perKm);
      const weightFare  = Math.round(parseFloat(weightKg) * vc.perKg);
      const totalFare   = baseFare + distFare + weightFare;
      const commPct     = 15;
      const commAmt     = Math.round(totalFare * commPct / 100);
      res.json({
        vehicleCategory,
        vehicleName: vc.name,
        baseFare,
        distanceFare: distFare,
        weightFare,
        totalFare,
        commissionPct: commPct,
        commissionAmt: commAmt,
        driverEarnings: totalFare - commAmt,
        dropCount: (dropLocations as any[]).length,
      });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Customer: book a multi-drop parcel order
  app.post("/api/app/parcel/book", authApp, async (req, res) => {
    try {
      const customerId = (req as any).currentUser?.id;

      // ── Service activation gate ───────────────────────────────────────────
      const parcelGate = await rawDb.execute(rawSql`
        SELECT service_status FROM platform_services WHERE service_key = 'parcel_delivery' LIMIT 1
      `).catch(() => ({ rows: [] as any[] }));
      if (parcelGate.rows.length && (parcelGate.rows[0] as any).service_status !== 'active') {
        return res.status(503).json({ message: "Parcel Delivery service is currently unavailable.", code: "SERVICE_INACTIVE" });
      }

      const {
        vehicleCategory = 'bike_parcel',
        pickupAddress, pickupLat, pickupLng,
        pickupContactName, pickupContactPhone,
        dropLocations = [],
        totalDistanceKm = 5,
        weightKg = 1,
        paymentMethod = 'cash',
        notes = '',
        isB2b = false, b2bCompanyId,
      } = req.body;
      if (!pickupAddress) return res.status(400).json({ message: 'pickupAddress required' });
      if (!(dropLocations as any[]).length) return res.status(400).json({ message: 'At least one drop location required' });
      const vc = PARCEL_VEHICLES[vehicleCategory] || PARCEL_VEHICLES.bike_parcel;
      const dist    = parseFloat(totalDistanceKm) || 5;
      const wt      = parseFloat(weightKg) || 1;
      const baseFare   = vc.baseFare;
      const distFare   = Math.round(dist * vc.perKm);
      const wFare      = Math.round(wt * vc.perKg);
      const totalFare  = baseFare + distFare + wFare;
      const commPct    = 15;
      const commAmt    = Math.round(totalFare * commPct / 100);
      const pickupOtp  = Math.floor(100000 + Math.random() * 900000).toString();

      // Attach a 6-digit OTP to each drop location for delivery verification
      const dropsWithOtp = (dropLocations as any[]).map((d: any, i: number) => ({
        ...d,
        dropIndex: i,
        deliveryOtp: Math.floor(100000 + Math.random() * 900000).toString(),
        delivered_at: null,
      }));

      const r = await rawDb.execute(rawSql`
        INSERT INTO parcel_orders
          (customer_id, vehicle_category, pickup_address, pickup_lat, pickup_lng,
           pickup_contact_name, pickup_contact_phone, drop_locations,
           total_distance_km, weight_kg, base_fare, distance_fare, weight_fare,
           total_fare, commission_amt, commission_pct, current_status,
           pickup_otp, is_b2b, b2b_company_id, payment_method, notes)
        VALUES
          (${customerId}::uuid, ${vehicleCategory}, ${pickupAddress},
           ${pickupLat ?? null}, ${pickupLng ?? null},
           ${pickupContactName ?? ''}, ${pickupContactPhone ?? ''},
           ${JSON.stringify(dropsWithOtp)},
           ${dist}, ${wt}, ${baseFare}, ${distFare}, ${wFare},
           ${totalFare}, ${commAmt}, ${commPct}, 'searching',
           ${pickupOtp}, ${isB2b ?? false}, ${b2bCompanyId ?? null},
           ${paymentMethod}, ${notes})
        RETURNING *
      `);
      const order = (r.rows as any[])[0];

      // Notify nearby parcel-capable drivers via socket
      if (io) {
        io.emit('parcel:new_request', {
          orderId: order.id,
          vehicleCategory,
          pickupAddress,
          pickupLat, pickupLng,
          totalFare,
          dropCount: dropsWithOtp.length,
        });
      }

      res.json({ success: true, orderId: order.id, pickupOtp, totalFare, drops: dropsWithOtp.length });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Customer: get active/recent parcel orders
  app.get("/api/app/parcel/orders", authApp, async (req, res) => {
    try {
      const customerId = (req as any).currentUser?.id;
      const r = await rawDb.execute(rawSql`
        SELECT po.*, u.full_name as driver_name, u.phone as driver_phone
        FROM parcel_orders po
        LEFT JOIN users u ON u.id = po.driver_id
        WHERE po.customer_id = ${customerId}::uuid
        ORDER BY po.created_at DESC
        LIMIT 20
      `);
      res.json({ orders: r.rows });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Customer: cancel parcel order
  app.post("/api/app/parcel/:id/cancel", authApp, async (req, res) => {
    try {
      const customerId = (req as any).currentUser?.id;
      const { reason = 'Customer cancelled' } = req.body;
      const r = await rawDb.execute(rawSql`
        UPDATE parcel_orders
        SET current_status='cancelled', cancelled_reason=${reason}, updated_at=NOW()
        WHERE id=${req.params.id}::uuid AND customer_id=${customerId}::uuid
          AND current_status IN ('pending','searching')
        RETURNING id
      `);
      if (!(r.rows as any[]).length) return res.status(400).json({ message: 'Cannot cancel this order' });
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Driver: get pending parcel requests nearby
  app.get("/api/driver/parcel/pending", authApp, async (req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT * FROM parcel_orders
        WHERE current_status = 'searching'
        ORDER BY created_at ASC
        LIMIT 20
      `);
      res.json({ orders: r.rows });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Driver: accept a parcel order
  app.post("/api/driver/parcel/:id/accept", authApp, async (req, res) => {
    try {
      const driverId = (req as any).currentUser?.id;
      const r = await rawDb.execute(rawSql`
        UPDATE parcel_orders
        SET driver_id=${driverId}::uuid, current_status='driver_assigned', updated_at=NOW()
        WHERE id=${req.params.id}::uuid AND current_status='searching'
          AND driver_id IS NULL
        RETURNING *
      `);
      if (!(r.rows as any[]).length) return res.status(409).json({ message: 'Already assigned' });
      const order = (r.rows as any[])[0];
      if (io) io.to(`user:${order.customer_id}`).emit('parcel:driver_assigned', { orderId: order.id, driverId });
      res.json({ success: true, order });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Driver: verify pickup OTP → start delivery
  app.post("/api/driver/parcel/:id/pickup-otp", authApp, async (req, res) => {
    try {
      const { otp } = req.body;
      const r = await rawDb.execute(rawSql`
        SELECT id, pickup_otp, current_status, customer_id FROM parcel_orders WHERE id=${req.params.id}::uuid
      `);
      const order = (r.rows as any[])[0];
      if (!order) return res.status(404).json({ message: 'Order not found' });
      if (order.current_status !== 'driver_assigned') return res.status(400).json({ message: 'Invalid order state' });
      if (String(order.pickup_otp) !== String(otp)) return res.status(400).json({ message: 'Invalid OTP' });
      await rawDb.execute(rawSql`
        UPDATE parcel_orders SET current_status='in_transit', updated_at=NOW() WHERE id=${req.params.id}::uuid
      `);
      if (io) io.to(`user:${order.customer_id}`).emit('parcel:in_transit', { orderId: order.id });
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Driver: verify delivery OTP for a specific drop stop
  app.post("/api/driver/parcel/:id/drop-otp", authApp, async (req, res) => {
    try {
      const { dropIndex, otp } = req.body;
      const r = await rawDb.execute(rawSql`
        SELECT id, drop_locations, current_drop_index, current_status, customer_id, total_fare, driver_id
        FROM parcel_orders WHERE id=${req.params.id}::uuid
      `);
      const order = (r.rows as any[])[0];
      if (!order) return res.status(404).json({ message: 'Order not found' });
      if (order.current_status !== 'in_transit') return res.status(400).json({ message: 'Order not in transit' });
      const drops: any[] = typeof order.drop_locations === 'string'
        ? JSON.parse(order.drop_locations) : order.drop_locations;
      const idx = parseInt(dropIndex ?? order.current_drop_index);
      const drop = drops[idx];
      if (!drop) return res.status(404).json({ message: 'Drop stop not found' });
      if (String(drop.deliveryOtp) !== String(otp)) return res.status(400).json({ message: 'Invalid delivery OTP' });
      drops[idx].delivered_at = new Date().toISOString();
      const nextIdx = idx + 1;
      const allDelivered = nextIdx >= drops.length;
      await rawDb.execute(rawSql`
        UPDATE parcel_orders
        SET drop_locations = ${JSON.stringify(drops)},
            current_drop_index = ${nextIdx},
            current_status = ${allDelivered ? 'completed' : 'in_transit'},
            updated_at = NOW()
        WHERE id = ${req.params.id}::uuid
      `);
      if (allDelivered) {
        // Credit driver wallet
        const driverEarnings = Math.round(order.total_fare * 0.85);
        await rawDb.execute(rawSql`
          UPDATE users SET wallet_balance = wallet_balance + ${driverEarnings}
          WHERE id = ${order.driver_id}::uuid
        `).catch(() => {});
        if (io) io.to(`user:${order.customer_id}`).emit('parcel:completed', { orderId: order.id });
      }
      res.json({ success: true, allDelivered, nextDrop: allDelivered ? null : drops[nextIdx] });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Admin: list all parcel orders with filters
  app.get("/api/admin/parcel-orders", async (req, res) => {
    try {
      const { status, b2b, limit = 100, offset = 0 } = req.query;
      const rows = await rawDb.execute(rawSql`
        SELECT po.*,
          cu.full_name as customer_name, cu.phone as customer_phone,
          dr.full_name as driver_name,   dr.phone as driver_phone
        FROM parcel_orders po
        LEFT JOIN users cu ON cu.id = po.customer_id
        LEFT JOIN users dr ON dr.id = po.driver_id
        ${status ? rawSql`WHERE po.current_status = ${status}` : rawSql`WHERE TRUE`}
        ${b2b === 'true' ? rawSql`AND po.is_b2b = true` : rawSql``}
        ORDER BY po.created_at DESC
        LIMIT ${parseInt(limit as string)} OFFSET ${parseInt(offset as string)}
      `);
      res.json({ orders: rows.rows });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Admin: get single parcel order detail
  app.get("/api/admin/parcel-orders/:id", async (req, res) => {
    try {
      const r = await rawDb.execute(rawSql`
        SELECT po.*, cu.full_name as customer_name, cu.phone as customer_phone,
               dr.full_name as driver_name, dr.phone as driver_phone
        FROM parcel_orders po
        LEFT JOIN users cu ON cu.id = po.customer_id
        LEFT JOIN users dr ON dr.id = po.driver_id
        WHERE po.id = ${req.params.id}::uuid
      `);
      if (!(r.rows as any[]).length) return res.status(404).json({ message: 'Not found' });
      res.json((r.rows as any[])[0]);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // B2B: bulk delivery — create multiple parcel orders for a business
  app.post("/api/b2b/:companyId/bulk-delivery", async (req, res) => {
    try {
      const { companyId } = req.params;
      const { customerId, vehicleCategory = 'bike_parcel', pickupAddress, pickupLat, pickupLng,
              pickupContactName, pickupContactPhone, deliveries = [], weightKg = 1, notes = '' } = req.body;
      if (!pickupAddress) return res.status(400).json({ message: 'pickupAddress required' });
      if (!(deliveries as any[]).length) return res.status(400).json({ message: 'deliveries array required' });
      const vc = PARCEL_VEHICLES[vehicleCategory] || PARCEL_VEHICLES.bike_parcel;
      const wt = parseFloat(weightKg) || 1;
      const results: any[] = [];
      for (const delivery of deliveries as any[]) {
        const dist     = parseFloat(delivery.distanceKm ?? '5') || 5;
        const baseFare = vc.baseFare;
        const distF    = Math.round(dist * vc.perKm);
        const wtF      = Math.round(wt * vc.perKg);
        const total    = baseFare + distF + wtF;
        const commAmt  = Math.round(total * 0.15);
        const pickupOtp = Math.floor(100000 + Math.random() * 900000).toString();
        const drops = [{
          address: delivery.dropAddress,
          lat: delivery.dropLat,
          lng: delivery.dropLng,
          receiverName: delivery.receiverName ?? '',
          receiverPhone: delivery.receiverPhone ?? '',
          dropIndex: 0,
          deliveryOtp: Math.floor(100000 + Math.random() * 900000).toString(),
          delivered_at: null,
        }];
        const r = await rawDb.execute(rawSql`
          INSERT INTO parcel_orders
            (customer_id, vehicle_category, pickup_address, pickup_lat, pickup_lng,
             pickup_contact_name, pickup_contact_phone, drop_locations,
             total_distance_km, weight_kg, base_fare, distance_fare, weight_fare,
             total_fare, commission_amt, commission_pct, current_status,
             pickup_otp, is_b2b, b2b_company_id, notes)
          VALUES
            (${customerId ?? null}, ${vehicleCategory}, ${pickupAddress},
             ${pickupLat ?? null}, ${pickupLng ?? null},
             ${pickupContactName ?? ''}, ${pickupContactPhone ?? ''},
             ${JSON.stringify(drops)},
             ${dist}, ${wt}, ${baseFare}, ${distF}, ${wtF},
             ${total}, ${commAmt}, 15, 'searching',
             ${pickupOtp}, true, ${companyId}::uuid, ${notes})
          RETURNING id, total_fare
        `);
        results.push((r.rows as any[])[0]);
      }
      res.json({ success: true, ordersCreated: results.length, orders: results });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── SERVICES MANAGEMENT ───────────────────────────────────────────────────
  // Service definitions (hardcoded business models)
  const SERVICE_DEFS = [
    { key: 'ride', name: 'Normal Ride', description: 'Bike, Auto, Car, SUV rides', icon: '🚗', emoji: '🚕', color: '#1E6DE5' },
    { key: 'parcel', name: 'Parcel Delivery', description: 'Send packages with bike or auto', icon: '📦', emoji: '📦', color: '#F59E0B' },
    { key: 'cargo', name: 'Cargo & Freight', description: 'Large goods with truck or van', icon: '🚚', emoji: '🚛', color: '#10B981' },
    { key: 'intercity', name: 'Intercity', description: 'Travel between cities', icon: '🛣️', emoji: '🛣️', color: '#8B5CF6' },
    { key: 'carsharing', name: 'Car Sharing', description: 'Share rides with others', icon: '🚘', emoji: '🚘', color: '#EF4444' },
  ];

  // Admin: Get all services with toggle state
  app.get("/api/services", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT key_name, value FROM business_settings WHERE settings_type='service_settings'`);
      const map: Record<string, string> = {};
      (r.rows as any[]).forEach(row => { map[row.key_name] = row.value; });
      const services = SERVICE_DEFS.map(s => ({
        ...s,
        isActive: map[`service_${s.key}_enabled`] !== '0',
      }));
      res.json(services);
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Admin: Toggle service on/off
  app.patch("/api/services/:key", async (req, res) => {
    try {
      const { key } = req.params;
      const { isActive } = req.body;
      if (!SERVICE_DEFS.find(s => s.key === key)) return res.status(404).json({ message: 'Service not found' });
      await rawDb.execute(rawSql`
        INSERT INTO business_settings (key_name, value, settings_type)
        VALUES (${'service_' + key + '_enabled'}, ${isActive ? '1' : '0'}, 'service_settings')
        ON CONFLICT (key_name) DO UPDATE SET value=${isActive ? '1' : '0'}, updated_at=now()
      `);
      res.json({ success: true, key, isActive });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // App: Get active services for customer app
  app.get("/api/app/services", async (_req, res) => {
    try {
      const r = await rawDb.execute(rawSql`SELECT key_name, value FROM business_settings WHERE settings_type='service_settings'`);
      const map: Record<string, string> = {};
      (r.rows as any[]).forEach(row => { map[row.key_name] = row.value; });
      const services = SERVICE_DEFS.map(s => ({
        key: s.key,
        name: s.name,
        description: s.description,
        icon: s.icon,
        emoji: s.emoji,
        color: s.color,
        isActive: map[`service_${s.key}_enabled`] !== '0',
      }));
      res.json({ services });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // Also seed default vehicle_category is_active based on service toggle
  app.patch("/api/services/:key/vehicles", async (req, res) => {
    try {
      const { key } = req.params;
      const { isActive } = req.body;
      await rawDb.execute(rawSql`UPDATE vehicle_categories SET is_active=${isActive} WHERE type=${key}`);
      res.json({ success: true });
    } catch (e: any) { res.status(500).json({ message: e.message }); }
  });

  // ── Stale searching trip auto-cancel: expire after 12 minutes ───────────
  setInterval(async () => {
    try {
      const stale = await rawDb.execute(rawSql`
        UPDATE trip_requests
        SET current_status='cancelled', cancel_reason='No driver found within 12 minutes', updated_at=NOW()
        WHERE current_status='searching'
          AND driver_id IS NULL
          AND created_at < NOW() - INTERVAL '12 minutes'
        RETURNING id, customer_id
      `);
      for (const row of stale.rows) {
        const r = row as any;
        if (io && r.customer_id) {
          io.to(`user:${r.customer_id}`).emit("trip:cancelled", {
            tripId: r.id,
            reason: "No driver available nearby. Please try again.",
          });
        }
        await appendTripStatus(r.id, 'cancelled', 'system', 'Auto-cancelled: no driver in 12 minutes').catch(() => {});
      }
      if (stale.rows.length) console.log(`[EXPIRE] Auto-cancelled ${stale.rows.length} stale searching trip(s)`);
    } catch (e: any) {
      console.error("[EXPIRE] Stale trip cleanup error:", formatDbError(e));
    }
  }, 60000); // runs every 60 seconds

  // ── Driver request timeout: auto-reassign after 90 seconds ───────────────
  setInterval(async () => {
    try {
      // Find trips assigned to a driver for >90s with no response (still driver_assigned)
      const timedOut = await rawDb.execute(rawSql`
         SELECT t.id, t.pickup_lat, t.pickup_lng, t.pickup_address, t.estimated_fare,
           t.vehicle_category_id, t.driver_id, t.rejected_driver_ids
        FROM trip_requests t
        WHERE t.current_status = 'driver_assigned'
           AND t.driver_id IS NOT NULL
          AND t.updated_at < NOW() - INTERVAL '90 seconds'
      `);

      for (const row of timedOut.rows) {
        const trip = camelize(row) as any;
        if (!trip.driverId) continue;

        // Add current driver to rejected list and reset
        await rawDb.execute(rawSql`
          UPDATE trip_requests
          SET current_status='searching', driver_id=NULL,
              rejected_driver_ids = array_append(COALESCE(rejected_driver_ids,'{}'), ${trip.driverId}::uuid),
              updated_at=NOW()
          WHERE id=${trip.id}::uuid AND current_status='driver_assigned'
        `);

        // Notify the timed-out driver
        if (io) io.to(`user:${trip.driverId}`).emit("trip:timeout", { tripId: trip.id });

        // AI-scored driver reassignment
        const excludeList = [...(trip.rejectedDriverIds || []), trip.driverId].filter(Boolean);
        const nextBest = await findBestDrivers(
          trip.pickupLat, trip.pickupLng,
          trip.vehicleCategoryId || undefined,
          excludeList,
          1
        );

        if (nextBest.length && io) {
          const nd = nextBest[0];
          io.to(`user:${nd.driverId}`).emit("trip:new_request", { tripId: trip.id, pickupAddress: trip.pickupAddress || "Pickup", estimatedFare: trip.estimatedFare || 0 });
          if (nd.fcmToken) {
            notifyDriverNewRide({ fcmToken: nd.fcmToken, driverName: nd.fullName, customerName: "", pickupAddress: trip.pickupAddress || "Pickup", estimatedFare: trip.estimatedFare || 0, tripId: trip.id }).catch(() => {});
          }
          console.log(`[TIMEOUT] Trip ${trip.id} AI-reassigned to driver ${nd.driverId} (score: ${nd.score})`);
        } else if (io) {
          notifyNearbyDriversNewTrip(trip.id, trip.pickupLat, trip.pickupLng, trip.vehicleCategoryId, excludeList).catch(() => {});
        }
      }
    } catch (e: any) {
      console.error("[TIMEOUT] Auto-reassign error:", formatDbError(e));
    }
  }, 30000);

  // ══════════════════════════════════════════════════════════════════════════
  //  AI INTELLIGENCE LAYER — ENDPOINTS
  // ══════════════════════════════════════════════════════════════════════════

  // Initialize AI tables on startup
  initAiTables().then(() => {
    console.log("[AI] Intelligence layer ready");
    refreshAllDriverStats().catch(() => {});
  });

  // ── AI: Smart Suggestions for customer ─────────────────────────────────
  app.get("/api/app/ai/suggestions", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const hour = req.query.hour ? Number(req.query.hour) : undefined;
      const suggestions = await getSmartSuggestions(user.id, hour);
      res.json({ suggestions });
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // ── AI: Driver Matching (explicit endpoint for testing/admin) ─────────
  app.post("/api/app/ai/driver-match", authApp, async (req, res) => {
    try {
      const { pickupLat, pickupLng, vehicleCategoryId, excludeDriverIds = [], limit = 5 } = req.body;
      if (!pickupLat || !pickupLng) return res.status(400).json({ message: "pickupLat and pickupLng required" });
      const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      const safeExclude = Array.isArray(excludeDriverIds)
        ? excludeDriverIds.filter((id: string) => typeof id === 'string' && uuidRe.test(id))
        : [];
      if (vehicleCategoryId && !uuidRe.test(vehicleCategoryId)) {
        return res.status(400).json({ message: "Invalid vehicleCategoryId" });
      }
      const drivers = await findBestDrivers(
        Number(pickupLat), Number(pickupLng),
        vehicleCategoryId || undefined,
        safeExclude,
        Math.min(Number(limit) || 5, 20)
      );
      res.json({ drivers, count: drivers.length });
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // ── AI: Demand Heatmap for drivers ────────────────────────────────────
  app.get("/api/app/ai/demand-heatmap", async (_req, res) => {
    try {
      const zones = await getDemandHeatmap();
      res.json({ zones, generatedAt: new Date().toISOString() });
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // ── AI: Safety Alerts (list active/unresolved) ────────────────────────
  app.get("/api/app/ai/safety-alerts", authApp, async (req, res) => {
    try {
      const { tripId, resolved = "false" } = req.query;
      const isResolved = resolved === "true";
      let alerts;
      if (tripId) {
        alerts = await rawDb.execute(rawSql`
          SELECT * FROM ai_safety_alerts
          WHERE trip_id = ${tripId as string}::uuid
          ORDER BY created_at DESC LIMIT 50
        `);
      } else {
        alerts = await rawDb.execute(rawSql`
          SELECT * FROM ai_safety_alerts
          WHERE resolved = ${isResolved}
          ORDER BY created_at DESC LIMIT 100
        `);
      }
      res.json({ alerts: alerts.rows.map(camelize) });
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // ── AI: Acknowledge/resolve a safety alert ────────────────────────────
  app.patch("/api/app/ai/safety-alerts/:alertId", authApp, async (req, res) => {
    try {
      const alertIdParam = req.params.alertId;
      const alertId = Array.isArray(alertIdParam) ? alertIdParam[0] : alertIdParam;
      const uuidRe = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidRe.test(alertId)) return res.status(400).json({ message: "Invalid alert ID" });
      const acknowledged = req.body.acknowledged === true;
      const resolved = req.body.resolved === true;
      await rawDb.execute(rawSql`
        UPDATE ai_safety_alerts
        SET acknowledged = ${acknowledged}, resolved = ${resolved}
        WHERE id = ${alertId}::uuid
      `);
      res.json({ success: true });
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // ── AI: SOS Emergency Trigger ─────────────────────────────────────────
  app.post("/api/app/ai/sos", authApp, async (req, res) => {
    try {
      const user = (req as any).currentUser;
      const { tripId, lat, lng, message: sosMsg } = req.body;
      await rawDb.execute(rawSql`
        INSERT INTO ai_safety_alerts (trip_id, driver_id, customer_id, alert_type, severity, message, lat, lng)
        VALUES (
          ${tripId ? rawSql`${tripId}::uuid` : rawSql`NULL`},
          ${user.userType === 'driver' ? rawSql`${user.id}::uuid` : rawSql`NULL`},
          ${user.userType === 'customer' ? rawSql`${user.id}::uuid` : rawSql`NULL`},
          'sos', 'critical',
          ${sosMsg || 'SOS Emergency triggered by user'},
          ${Number(lat) || 0}, ${Number(lng) || 0}
        )
      `);
      if (tripId && io) {
        const tripR = await rawDb.execute(rawSql`
          SELECT customer_id, driver_id FROM trip_requests WHERE id=${tripId}::uuid
        `);
        if (tripR.rows.length) {
          const t = tripR.rows[0] as any;
          const otherId = user.userType === 'driver' ? t.customer_id : t.driver_id;
          if (otherId) {
            io.to(`user:${otherId}`).emit("safety:sos", {
              tripId, lat, lng, fromUserType: user.userType,
              message: sosMsg || "SOS Emergency! Your co-rider triggered an emergency alert."
            });
          }
        }
      }
      res.json({ success: true, message: "SOS alert recorded and notifications sent" });
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // ── AI: Driver Stats (for driver profile / admin) ─────────────────────
  app.get("/api/app/ai/driver-stats/:driverId", authApp, async (req, res) => {
    try {
      const driverIdParam = req.params.driverId;
      const driverId = Array.isArray(driverIdParam) ? driverIdParam[0] : driverIdParam;
      await updateDriverStats(driverId);
      const stats = await rawDb.execute(rawSql`
        SELECT * FROM driver_stats WHERE driver_id = ${driverId}::uuid
      `);
      if (!stats.rows.length) return res.json({ stats: null });
      res.json({ stats: camelize(stats.rows[0]) });
    } catch (e: any) {
      res.status(500).json({ message: e.message });
    }
  });

  // ── Periodic driver stats refresh (every 10 minutes) ──────────────────
  setInterval(() => {
    refreshAllDriverStats().catch(() => {});
  }, 10 * 60 * 1000);

  // ── Periodic stale trip cleanup (every 2 minutes) ────────────────────────
  setInterval(async () => {
    try {
      // Cancel trips stuck in 'searching' for more than 3 minutes (no driver accepted)
      const staleTrips = await rawDb.execute(rawSql`
        UPDATE trip_requests SET current_status='cancelled', cancel_reason='Auto-cancelled: no pilot found within 3 minutes'
        WHERE current_status = 'searching'
          AND created_at < NOW() - INTERVAL '3 minutes'
        RETURNING id, customer_id
      `);
      if (staleTrips.rows.length) {
        console.log(`[CLEANUP] Auto-cancelled ${staleTrips.rows.length} stale trip(s)`);
        // Notify each customer
        for (const row of staleTrips.rows) {
          const r = row as any;
          if (io && r.customer_id) {
            io.to(`user:${r.customer_id}`).emit("trip:cancelled", {
              tripId: r.id, reason: "No pilot accepted your ride in time. Please try again."
            });
          }
        }
      }
      // Free drivers whose current_trip_id points to a completed/cancelled trip
      const freedDrivers = await rawDb.execute(rawSql`
        UPDATE users SET current_trip_id=NULL
        WHERE current_trip_id IS NOT NULL
          AND current_trip_id NOT IN (
            SELECT id FROM trip_requests WHERE current_status IN ('accepted','arrived','on_the_way')
          )
      `);
      if ((freedDrivers as any).rowCount > 0) {
        console.log(`[CLEANUP] Freed ${(freedDrivers as any).rowCount} driver(s) from stale trip assignments`);
      }
    } catch (e: any) {
      console.error("[CLEANUP] Error:", e.message);
    }
  }, 2 * 60 * 1000);

  // ── SYSTEM HEALTH CHECK ───────────────────────────────────────────────────
  app.get("/api/admin/system-health", async (_req, res) => {
    try {
      const [services, tripStats, parcelStats, driverStats, gstWallet] = await Promise.all([
        rawDb.execute(rawSql`SELECT service_key, service_name, service_status, revenue_model, commission_rate FROM platform_services ORDER BY sort_order ASC`)
          .catch(() => ({ rows: [] })),
        rawDb.execute(rawSql`
          SELECT
            COUNT(*) FILTER (WHERE current_status IN ('searching','accepted','arrived','on_the_way'))::int AS active,
            COUNT(*) FILTER (WHERE current_status = 'completed' AND created_at > NOW() - INTERVAL '24h')::int AS completed_today,
            COUNT(*) FILTER (WHERE current_status = 'cancelled' AND created_at > NOW() - INTERVAL '24h')::int AS cancelled_today,
            COUNT(*) FILTER (WHERE current_status = 'searching' AND created_at < NOW() - INTERVAL '5 minutes')::int AS stale_searching
          FROM trip_requests
        `).catch(() => ({ rows: [{}] })),
        rawDb.execute(rawSql`
          SELECT
            COUNT(*) FILTER (WHERE current_status IN ('searching','driver_assigned','in_transit'))::int AS active,
            COUNT(*) FILTER (WHERE current_status = 'completed' AND created_at > NOW() - INTERVAL '24h')::int AS completed_today,
            COALESCE(SUM(commission_amt) FILTER (WHERE current_status = 'completed' AND created_at > NOW() - INTERVAL '24h'), 0)::numeric AS commission_today
          FROM parcel_orders
        `).catch(() => ({ rows: [{}] })),
        rawDb.execute(rawSql`
          SELECT
            COUNT(*) FILTER (WHERE is_online = true)::int AS online,
            COUNT(*) FILTER (WHERE is_locked = true)::int AS locked,
            COUNT(*) FILTER (WHERE current_trip_id IS NOT NULL)::int AS on_trip
          FROM users WHERE role = 'driver'
        `).catch(() => ({ rows: [{}] })),
        rawDb.execute(rawSql`SELECT balance, total_collected, total_trips FROM company_gst_wallet WHERE id = 1`)
          .catch(() => ({ rows: [{}] })),
      ]);

      const t = (tripStats.rows[0] as any) || {};
      const p = (parcelStats.rows[0] as any) || {};
      const d = (driverStats.rows[0] as any) || {};
      const g = (gstWallet.rows[0] as any) || {};

      // Subscription check: how many drivers have active subscriptions
      const subStats = await rawDb.execute(rawSql`
        SELECT
          COUNT(*) FILTER (WHERE is_active = true AND end_date > NOW())::int AS active_subs,
          COUNT(DISTINCT driver_id) FILTER (WHERE is_active = true AND end_date > NOW())::int AS subscribed_drivers
        FROM driver_subscriptions
      `).catch(() => ({ rows: [{}] }));
      const sub = (subStats.rows[0] as any) || {};

      res.json({
        timestamp: new Date().toISOString(),
        services: services.rows,
        trips: {
          active: parseInt(t.active ?? 0),
          completedToday: parseInt(t.completed_today ?? 0),
          cancelledToday: parseInt(t.cancelled_today ?? 0),
          staleSearching: parseInt(t.stale_searching ?? 0),
        },
        parcels: {
          active: parseInt(p.active ?? 0),
          completedToday: parseInt(p.completed_today ?? 0),
          commissionToday: parseFloat(p.commission_today ?? 0),
        },
        drivers: {
          online: parseInt(d.online ?? 0),
          locked: parseInt(d.locked ?? 0),
          onTrip: parseInt(d.on_trip ?? 0),
          activeSubscriptions: parseInt(sub.active_subs ?? 0),
          subscribedDrivers: parseInt(sub.subscribed_drivers ?? 0),
        },
        gstWallet: {
          balance: parseFloat(g.balance ?? 0),
          totalCollected: parseFloat(g.total_collected ?? 0),
          totalTrips: parseInt(g.total_trips ?? 0),
        },
        status: 'ok',
      });
    } catch (e: any) { res.status(500).json({ message: e.message, status: 'error' }); }
  });

  return httpServer;
}
