import { sql } from "drizzle-orm";
import { drizzle } from "drizzle-orm/node-postgres";
import pg from "pg";
import * as schema from "@shared/schema";

const { Pool } = pg;

if (!process.env.DATABASE_URL) {
  throw new Error("DATABASE_URL must be set. Did you forget to provision a database?");
}

// Cloud DBs (Neon, Supabase, Railway) use intermediate CAs that trigger Node.js SSL errors.
// Fix: disable cert rejection at pool level only (not globally — global setting breaks all HTTPS).
const isLocalDb = (process.env.DATABASE_URL || "").match(/localhost|127\.0\.0\.1/);
const isProduction = process.env.NODE_ENV === 'production';

// Single-instance production: 25 connections max (Neon free tier allows ~100)
// Development: 20 connections max
const maxConnections = isProduction ? 25 : 20;

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: isLocalDb ? false : { rejectUnauthorized: false },
  max: maxConnections,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,  // Fail fast instead of hanging (was 10000ms)
  allowExitOnIdle: false,
  application_name: 'jago-api',   // For debugging in pg_stat_statements
});

pool.on("error", (err) => {
  console.error("[DB] Unexpected pool error:", err.message);
});

pool.on("connect", () => {
  console.debug("[DB] New connection established, pool size:", pool.totalCount);
});

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
