import { sql } from "drizzle-orm";
import { drizzle } from "drizzle-orm/node-postgres";
import pg from "pg";
import fs from "fs";
import path from "path";
import * as schema from "@shared/schema";

const { Pool } = pg;

function loadEnvFile(fileName: string): void {
  const filePath = path.resolve(process.cwd(), fileName);
  if (!fs.existsSync(filePath)) return;

  const raw = fs.readFileSync(filePath, "utf8");
  for (const rawLine of raw.split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith("#")) continue;
    const idx = line.indexOf("=");
    if (idx <= 0) continue;

    const key = line.slice(0, idx).trim();
    if (!key || process.env[key] !== undefined) continue;

    let value = line.slice(idx + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    process.env[key] = value;
  }
}

loadEnvFile(".env");
loadEnvFile(`.env.${process.env.NODE_ENV || "development"}`);

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL must be set. Did you forget to provision a database?");
}

// Cloud DBs (Neon, Supabase, Railway) use intermediate CAs that trigger Node.js SSL errors.
// Fix: disable cert rejection at pool level only (not globally — global setting breaks all HTTPS).
const isLocalDb = (process.env.DATABASE_URL || "").match(/localhost|127\.0\.0\.1/);
const isProduction = process.env.NODE_ENV === 'production';

// Single-instance production: keep conservative.
// Development: allow more parallel initializers without connection timeout noise.
const maxConnections = isProduction ? 25 : 35;
// Neon serverless DBs have cold starts (5-10s) — give enough headroom
const connectTimeoutMs = isProduction ? 20000 : 15000;

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: isLocalDb ? false : { rejectUnauthorized: false },
  max: maxConnections,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: connectTimeoutMs,
  keepAlive: true,
  keepAliveInitialDelayMillis: 10000,
  allowExitOnIdle: false,
  application_name: 'jago-api',   // For debugging in pg_stat_statements
});

pool.on("error", (err) => {
  console.error("[DB] Unexpected pool error:", err.message);
});

if (process.env.DB_VERBOSE_LOGS === "true") {
  pool.on("connect", () => {
    console.debug("[DB] New connection established, pool size:", pool.totalCount);
  });
}

export const db = drizzle(pool, { schema });
export const rawDb = db;
export const rawSql = sql;

const gracefulShutdown = async (signal: string) => {
  console.log(`[DB] ${signal} received — draining pool...`);
  try { await pool.end(); } catch (e) { /* ignore */ }
  process.exit(0);
};

process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));
