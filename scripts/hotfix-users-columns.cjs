const { Client } = require('pg');

(async () => {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();

  const statements = [
    "CREATE EXTENSION IF NOT EXISTS pgcrypto",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_token TEXT",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS wallet_balance DOUBLE PRECISION NOT NULL DEFAULT 0",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS pending_payment_amount DOUBLE PRECISION NOT NULL DEFAULT 0",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_locked BOOLEAN NOT NULL DEFAULT false",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS lock_reason TEXT",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS locked_at TIMESTAMP",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_online BOOLEAN NOT NULL DEFAULT false",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS current_lat DOUBLE PRECISION",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS current_lng DOUBLE PRECISION",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS current_trip_id UUID",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS rating DOUBLE PRECISION NOT NULL DEFAULT 5.0",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS total_ratings INTEGER NOT NULL DEFAULT 0",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo TEXT",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_status VARCHAR(20) DEFAULT 'pending'",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS license_expiry VARCHAR(40)",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_brand VARCHAR(120)",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_color VARCHAR(80)",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS vehicle_year VARCHAR(10)",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS date_of_birth VARCHAR(40)",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS city VARCHAR(120)",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS selfie_image TEXT",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS revenue_model VARCHAR(20)",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS model_selected_at TIMESTAMP",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS theme_preference VARCHAR(20) DEFAULT 'dark'",
    "ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT"
  ];

  for (const sql of statements) {
    await c.query(sql);
  }

  console.log('users_hotfix_done');
  await c.end();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
