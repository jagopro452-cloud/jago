/**
 * JAGO Admin Password Reset Script
 * Run: npx tsx scripts/reset-admin-password.ts
 */

import { config } from "dotenv";
config(); // load .env

import { Pool } from "pg";
import bcrypt from "bcrypt";

const NEW_PASSWORD = "Jago@Admin2026!";          // ← Change this to your desired password
const ADMIN_EMAIL  = process.env.ADMIN_EMAIL || "admin@jagopro.org";

async function reset() {
  if (!process.env.DATABASE_URL) {
    console.error("❌ DATABASE_URL not set in .env");
    process.exit(1);
  }

  const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

  try {
    const hash = await bcrypt.hash(NEW_PASSWORD, 10);
    const result = await pool.query(
      `UPDATE admins SET password = $1, is_active = true WHERE LOWER(email) = LOWER($2) RETURNING id, email`,
      [hash, ADMIN_EMAIL]
    );

    if (result.rowCount === 0) {
      console.log(`⚠️  No admin found with email: ${ADMIN_EMAIL}`);
      console.log("Creating new admin...");
      await pool.query(
        `INSERT INTO admins (id, name, email, password, role, is_active, created_at)
         VALUES (gen_random_uuid(), 'Jago Admin', $1, $2, 'superadmin', true, NOW())`,
        [ADMIN_EMAIL, hash]
      );
      console.log(`✅ Admin created: ${ADMIN_EMAIL}`);
    } else {
      console.log(`✅ Password reset for: ${result.rows[0].email}`);
    }

    console.log(`\n📋 Admin Login Details:`);
    console.log(`   URL:      https://jagopro.org/admin`);
    console.log(`   Email:    ${ADMIN_EMAIL}`);
    console.log(`   Password: ${NEW_PASSWORD}`);
    console.log(`\n⚠️  IMPORTANT: Also update ADMIN_PASSWORD in DigitalOcean env vars`);
    console.log(`   to prevent it from being reset on next deploy.\n`);

  } catch (err: any) {
    console.error("❌ Error:", err.message);
  } finally {
    await pool.end();
  }
}

reset();
