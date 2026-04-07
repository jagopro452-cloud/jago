// Allow self-signed DB certificates in development only (not in production).
if (process.env.NODE_ENV !== "production" && process.env.NODE_ENV !== "test") {
  process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";
}

import express, { type Request, Response, NextFunction } from "express";
import { registerRoutes } from "./routes";
import { serveStatic } from "./static";
import { createServer } from "http";
import { setupSocket } from "./socket";
import { parseEnv, validateProductionReadiness } from "./config/env";
import { makeErrorId, sendAlert } from "./observability";
import { migrate } from "drizzle-orm/node-postgres/migrator";
import { db as drizzleDb } from "./db";
import path from "path";

const env = parseEnv();
validateProductionReadiness(env);

const app = express();
app.set("trust proxy", 1);
const httpServer = createServer(app);

declare module "http" {
  interface IncomingMessage {
    rawBody: unknown;
  }
}

app.use(
  express.json({
    limit: "2mb",
    verify: (req, _res, buf) => {
      req.rawBody = buf;
    },
  }),
);

app.use(express.urlencoded({ extended: false, limit: "1mb", parameterLimit: 100 }));

export function log(message: string, source = "express") {
  const formattedTime = new Date().toLocaleTimeString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    second: "2-digit",
    hour12: true,
  });

  console.log(`${formattedTime} [${source}] ${message}`);
}

function pickTripTraceFields(payload: any) {
  if (!payload || typeof payload !== "object") return undefined;
  const p = payload as Record<string, any>;
  const trace = {
    tripId: p.tripId || p.trip_id || p.id || p.trip?.id || p.data?.tripId,
    status: p.status || p.currentStatus || p.current_status || p.tripStatus || p.trip?.currentStatus,
    driverId: p.driverId || p.driver_id || p.driver?.id,
    customerId: p.customerId || p.customer_id || p.customer?.id,
    createdAt: p.createdAt || p.created_at || p.trip?.createdAt,
    acceptedAt: p.acceptedAt || p.driverAcceptedAt || p.driver_accepted_at || p.trip?.driverAcceptedAt,
    arrivedAt: p.arrivedAt || p.driverArrivedAt || p.driver_arrived_at || p.trip?.driverArrivedAt,
    startedAt: p.startedAt || p.rideStartedAt || p.ride_started_at || p.trip?.rideStartedAt,
    completedAt: p.completedAt || p.rideEndedAt || p.ride_ended_at || p.trip?.rideEndedAt,
  };
  const hasAny = Object.values(trace).some((v) => v !== undefined && v !== null && v !== "");
  return hasAny ? trace : undefined;
}

// Security headers
app.use((_req, res, next) => {
  // CORS headers — allow requests from frontend domain(s)
  const origin = _req.headers.origin || "*";
  const allowedOrigins = [
    "https://jagopro.org",
    "https://www.jagopro.org",
    "http://localhost:5173",
    "http://localhost:5000",
    "http://127.0.0.1:5173",
  ];
  
  // If origin is in allowed list, or if no origin header (same-site), allow it
  if (allowedOrigins.includes(origin as string) || !_req.headers.origin) {
    res.setHeader("Access-Control-Allow-Origin", origin);
  } else if (origin.includes("localhost") || origin.includes("127.0.0.1")) {
    // Allow all localhost variants for development
    res.setHeader("Access-Control-Allow-Origin", origin);
  }
  
  res.setHeader("Access-Control-Allow-Credentials", "true");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS, PATCH");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With");
  res.setHeader("Access-Control-Max-Age", "3600");
  
  // Handle preflight requests
  if (_req.method === "OPTIONS") {
    return res.sendStatus(200);
  }
  
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("X-Frame-Options", "SAMEORIGIN");
  res.setHeader("X-XSS-Protection", "1; mode=block");
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
  res.setHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload");
  res.setHeader("Permissions-Policy", "camera=(), microphone=(), geolocation=(self)");
  next();
});

app.use((req, res, next) => {
  const start = Date.now();
  const path = req.path;
  let capturedJsonResponse: Record<string, any> | undefined = undefined;
  const requestTrace = pickTripTraceFields(req.body);

  const originalResJson = res.json;
  res.json = function (bodyJson, ...args) {
    capturedJsonResponse = bodyJson;
    return originalResJson.apply(res, [bodyJson, ...args]);
  };

  res.on("finish", () => {
    const duration = Date.now() - start;
    if (path.startsWith("/api")) {
      let logLine = `${req.method} ${path} ${res.statusCode} in ${duration}ms`;
      if (requestTrace) {
        logLine += ` :: reqTrace=${JSON.stringify(requestTrace)}`;
      }
      if (capturedJsonResponse) {
        const sanitized = { ...capturedJsonResponse };
        if (sanitized.otp !== undefined) sanitized.otp = "[REDACTED]";
        if (sanitized.password !== undefined) sanitized.password = "[REDACTED]";
        if (sanitized.token !== undefined) sanitized.token = "[REDACTED]";
        if (sanitized.sessionToken !== undefined) sanitized.sessionToken = "[REDACTED]";
        const responseTrace = pickTripTraceFields(sanitized);
        if (responseTrace) {
          logLine += ` :: resTrace=${JSON.stringify(responseTrace)}`;
        }
        logLine += ` :: ${JSON.stringify(sanitized)}`;
      }

      log(logLine);
    }
  });

  next();
});

(async () => {
  // Run Drizzle migrations at startup — this creates ALL tables including admins
  try {
    const migrationsFolder = path.join(process.cwd(), "migrations");
    log(`[db] Running migrations from: ${migrationsFolder}`);
    await migrate(drizzleDb, { migrationsFolder });
    log("[db] Migrations applied OK — all tables ready");
  } catch (e: any) {
    console.error("[db] MIGRATION FAILED — tables may be missing:", e.message);
    console.error("[db] Full error:", e.stack || e);
    process.exit(1);
  }

  // Setup error handler early
  app.use((err: any, _req: Request, res: Response, next: NextFunction) => {
    const status = err.status || err.statusCode || 500;
    const errorId = makeErrorId();

    console.error(`Internal Server Error [${errorId}]:`, err);
    sendAlert({
      level: status >= 500 ? "critical" : "error",
      source: "express",
      message: `Request failed with status ${status} (${errorId})`,
      details: typeof err?.stack === "string" ? err.stack : String(err?.message || err),
    }).catch(() => {});

    if (res.headersSent) {
      return next(err);
    }

    const isProd = process.env.NODE_ENV === "production";
    const message = isProd && status >= 500
      ? `An internal error occurred. Reference: ${errorId}`
      : (err.message || "Internal Server Error");

    return res.status(status).json({ message, errorId });
  });

  // ─── REGISTER ROUTES FIRST (CRITICAL) ───
  // Must complete before server handles any API requests
  try {
    log("[server] Registering API routes...");
    await registerRoutes(httpServer, app);
    log("[server] API routes registered successfully");
  } catch (e: any) {
    console.error("[routes] Failed to register routes:", e.message);
    console.error("[routes] Stack:", e.stack);
    sendAlert({
      level: "critical",
      source: "routes",
      message: "Failed to register API routes",
      details: String(e.message || e),
    }).catch(() => {});
    process.exit(1);
  }

  // Setup static files AFTER routes (so routes take precedence)
  if (process.env.NODE_ENV === "production") {
    log("[server] Setting up static file serving for production");
    serveStatic(app);
  }

  // ─── NOW START SERVER LISTENING ───
  // Routes are registered and ready to handle requests
  const port = parseInt(process.env.PORT || "5000", 10);
  const server = httpServer.listen(port, "0.0.0.0", () => {
    log(`serving on port ${port}`);
  });

  // ─── BACKGROUND INITIALIZATION (non-blocking) ───

  // Load API keys from business_settings DB (non-blocking)
  (async () => {
    try {
      const { pool: dbPool } = await import("./db");
      const settingsRes = await dbPool.query(
        "SELECT key_name, value FROM business_settings WHERE key_name IN ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)",
        ["razorpay_key_id","razorpay_key_secret","razorpay_webhook_secret","fast2sms_api_key","two_factor_api_key","google_maps_key","twilio_account_sid","twilio_auth_token","twilio_phone_number","anthropic_api_key"]
      );
      const ENV_MAP: Record<string, string> = {
        razorpay_key_id:        "RAZORPAY_KEY_ID",
        razorpay_key_secret:    "RAZORPAY_KEY_SECRET",
        razorpay_webhook_secret:"RAZORPAY_WEBHOOK_SECRET",
        fast2sms_api_key:       "FAST2SMS_API_KEY",
        two_factor_api_key:     "TWO_FACTOR_API_KEY",
        google_maps_key:        "GOOGLE_MAPS_API_KEY",
        twilio_account_sid:     "TWILIO_ACCOUNT_SID",
        twilio_auth_token:      "TWILIO_AUTH_TOKEN",
        twilio_phone_number:    "TWILIO_PHONE_NUMBER",
        anthropic_api_key:      "ANTHROPIC_API_KEY",
      };
      for (const row of settingsRes.rows as any[]) {
        const envKey = ENV_MAP[row.key_name];
        if (envKey && !process.env[envKey] && row.value?.trim()) {
          process.env[envKey] = row.value.trim();
          log(`[config] Loaded ${envKey} from DB settings`);
        }
      }
      log("[config] DB settings loaded into runtime config");
    } catch (e: any) {
      log(`[config] Could not load DB settings (non-fatal): ${e.message}`);
    }
  })();

  // Setup Socket.IO with Redis adapter (non-blocking)
  setupSocket(httpServer);
  (async () => {
    try {
      const { createAdapter } = await import("@socket.io/redis-adapter");
      const { default: IORedis } = await import("ioredis");
      const REDIS_URL = process.env.REDIS_URL || "redis://localhost:6379";
      const pubClient = new IORedis(REDIS_URL, { lazyConnect: true, enableOfflineQueue: false, maxRetriesPerRequest: 0, retryStrategy: () => null });
      const subClient = pubClient.duplicate();
      // Prevent unhandled error events from crashing / spamming logs
      pubClient.on("error", () => {});
      subClient.on("error", () => {});
      const { io: socketIo } = await import("./socket");
      Promise.all([
        new Promise<void>((res, rej) => { pubClient.once("ready", res); pubClient.once("error", rej); }),
        new Promise<void>((res, rej) => { subClient.once("ready", res); subClient.once("error", rej); }),
      ]).then(() => {
        socketIo.adapter(createAdapter(pubClient, subClient));
        log("[Socket.IO] Redis adapter connected");
      }).catch((err: any) => {
        log(`[Socket.IO] Redis unavailable, using in-memory adapter: ${err.message}`);
      });
    } catch (err: any) {
      log(`[Socket.IO] Redis adapter package not available, using in-memory adapter: ${err.message}`);
    }
  })();

  // ─── INITIALIZE PRODUCTION HARDENING (CRITICAL) ───
  (async () => {
    try {
      const { startHardeningJobs, loadHardeningSettings, logInfo } = await import("./hardening");
      await loadHardeningSettings();
      await startHardeningJobs();
      await logInfo('HARDENING-STARTUP', 'Production hardening system initialized', {});
    } catch (e: any) {
      console.error('[hardening] Failed to initialize:', e.message);
      // Non-fatal: hardening should not prevent server startup
      // but log it loudly for visibility
      sendAlert({
        level: "error",
        source: "hardening",
        message: "Hardening system failed to initialize",
        details: e.message,
      }).catch(() => {});
    }
  })();

  // Payment retry job: every 5 minutes, check trips stuck in payment_pending
  // for more than 5 minutes and query Razorpay to auto-resolve them
  setInterval(async () => {
    try {
      const { rawDb, rawSql } = await import("./db");
      const { io: socketIo } = await import("./socket");
      const { getRazorpayKeys } = await import("./routes");
      const { keyId: RAZORPAY_KEY_ID, keySecret: RAZORPAY_KEY_SECRET } = await getRazorpayKeys();
      if (!RAZORPAY_KEY_ID) return;
      // Find trips stuck in payment_pending for > 5 minutes
      const stuckTrips = await rawDb.execute(rawSql`
        SELECT t.id as trip_id, t.customer_id, dp.razorpay_order_id, dp.id as payment_id, dp.driver_id
        FROM trip_requests t
        JOIN driver_payments dp ON dp.trip_id = t.id
        WHERE t.current_status = 'payment_pending'
          AND t.updated_at < NOW() - INTERVAL '5 minutes'
          AND dp.status = 'pending'
          AND dp.razorpay_order_id IS NOT NULL
        LIMIT 20
      `);
      for (const row of stuckTrips.rows as any[]) {
        try {
          // Query Razorpay for order payment status
          const rzpRes = await fetch(`https://api.razorpay.com/v1/orders/${row.razorpay_order_id}/payments`, {
            headers: { Authorization: `Basic ${Buffer.from(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`).toString("base64")}` },
          });
          if (!rzpRes.ok) continue;
          const rzpData = await rzpRes.json() as any;
          const captured = rzpData?.items?.find((p: any) => p.status === "captured");
          if (captured) {
            // Payment confirmed — complete the trip
            await rawDb.execute(rawSql`
              UPDATE driver_payments SET status='completed', razorpay_payment_id=${captured.id}, verified_at=NOW()
              WHERE id=${row.payment_id}::uuid
            `);
            await rawDb.execute(rawSql`
              UPDATE trip_requests SET current_status='completed', completed_at=NOW(), payment_status='paid', updated_at=NOW()
              WHERE id=${row.trip_id}::uuid AND current_status='payment_pending'
            `);
            socketIo.to(`user:${row.customer_id}`).emit("trip:completed", { tripId: row.trip_id, message: "Payment confirmed. Trip complete." });
            log(`[PaymentRetry] Trip ${row.trip_id} resolved — payment ${captured.id} captured`);
          }
        } catch (_) {}
      }
    } catch (e: any) {
      log(`[PaymentRetry] Error: ${e.message}`);
    }
  }, 5 * 60 * 1000); // every 5 minutes

  // Ghost driver auto-offline: every 60 seconds, mark drivers with no location ping > 5min as offline
  setInterval(async () => {
    try {
      const { autoOfflineInactiveDrivers } = await import("./ai");
      await autoOfflineInactiveDrivers();
    } catch (_) {}
  }, 60 * 1000); // every 60 seconds

  // Setup Vite in development (after server is listening)
  if (process.env.NODE_ENV !== "production") {
    try {
      const { setupVite } = await import("./vite");
      await setupVite(httpServer, app);
    } catch (e: any) {
      console.error("[vite] Failed to setup Vite:", e.message);
    }
  }

  process.on("unhandledRejection", (reason: any) => {
    const errorId = makeErrorId();
    console.error(`[unhandledRejection] [${errorId}]`, reason);
    sendAlert({
      level: "critical",
      source: "process",
      message: `Unhandled promise rejection (${errorId})`,
      details: String(reason?.stack || reason),
    }).catch(() => {});
  });

  process.on("uncaughtException", (err: any) => {
    const errorId = makeErrorId();
    console.error(`[uncaughtException] [${errorId}]`, err);
    sendAlert({
      level: "critical",
      source: "process",
      message: `Uncaught exception (${errorId})`,
      details: String(err?.stack || err),
    }).catch(() => {});
  });
})();
