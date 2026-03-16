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

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: isLocalDb ? false : { rejectUnauthorized: false },
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
  allowExitOnIdle: false,
});

pool.on("error", (err) => {
  console.error("[DB] Unexpected pool error:", err.message);
});

export const db = drizzle(pool, { schema });

const gracefulShutdown = async (signal: string) => {
  console.log(`[DB] ${signal} received — draining pool...`);
  try { await pool.end(); } catch (e) { /* ignore */ }
  process.exit(0);
};

process.on("SIGTERM", () => gracefulShutdown("SIGTERM"));
process.on("SIGINT", () => gracefulShutdown("SIGINT"));
