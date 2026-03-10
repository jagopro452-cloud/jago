#!/usr/bin/env node
/**
 * JAGO Admin Password Reset Script
 * Run this on the server when you can't log in to the admin panel.
 *
 * Usage:
 *   node scripts/reset-admin-password.js
 *   node scripts/reset-admin-password.js --email admin@example.com --password NewPassword123
 *
 * Prereqs: DATABASE_URL must be set in environment (same as server)
 */

import pg from "pg";
import bcrypt from "bcryptjs";

const args = process.argv.slice(2);
const getArg = (flag) => {
  const idx = args.indexOf(flag);
  return idx !== -1 ? args[idx + 1] : null;
};

const EMAIL    = getArg("--email")    || process.env.ADMIN_EMAIL    || "kiranatmakuri518@gmail.com";
const PASSWORD = getArg("--password") || process.env.ADMIN_PASSWORD || "JagoAdmin@2026!";
const DB_URL   = process.env.DATABASE_URL;

if (!DB_URL) {
  console.error("❌  DATABASE_URL env var is not set. Cannot connect to database.");
  process.exit(1);
}

const client = new pg.Client({ connectionString: DB_URL, ssl: { rejectUnauthorized: false } });

async function run() {
  try {
    await client.connect();
    console.log("✅  Connected to database.");

    // Ensure admins table exists
    await client.query(`
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

    const hash = await bcrypt.hash(PASSWORD, 12);

    // Check if admin exists
    const existing = await client.query(
      "SELECT id, email FROM admins WHERE LOWER(email) = $1 LIMIT 1",
      [EMAIL.trim().toLowerCase()]
    );

    if (existing.rows.length > 0) {
      await client.query(
        "UPDATE admins SET password=$1, is_active=true, auth_token=NULL, auth_token_expires_at=NULL WHERE LOWER(email)=$2",
        [hash, EMAIL.trim().toLowerCase()]
      );
      console.log(`✅  Password UPDATED for admin: ${EMAIL}`);
    } else {
      // No admin with this email — check if any admin exists
      const any = await client.query("SELECT id, email FROM admins ORDER BY created_at ASC LIMIT 1");
      if (any.rows.length > 0) {
        // Update the first admin's email + password
        await client.query(
          "UPDATE admins SET email=$1, password=$2, is_active=true, auth_token=NULL, auth_token_expires_at=NULL WHERE id=$3",
          [EMAIL.trim().toLowerCase(), hash, any.rows[0].id]
        );
        console.log(`✅  Migrated admin ${any.rows[0].email} → ${EMAIL}, password reset.`);
      } else {
        // Create new admin
        await client.query(
          "INSERT INTO admins (name, email, password, role, is_active) VALUES ($1, $2, $3, 'superadmin', true)",
          ["Admin", EMAIL.trim().toLowerCase(), hash]
        );
        console.log(`✅  Admin CREATED: ${EMAIL}`);
      }
    }

    console.log("");
    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    console.log("  Login with:");
    console.log(`  Email   : ${EMAIL}`);
    console.log(`  Password: ${PASSWORD}`);
    console.log("  URL     : https://jagopro.org/admin");
    console.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  } catch (err) {
    console.error("❌  Error:", err.message);
    process.exit(1);
  } finally {
    await client.end();
  }
}

run();
