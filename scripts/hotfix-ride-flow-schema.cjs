const { Client } = require('pg');

(async () => {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();

  const statements = [
    "CREATE EXTENSION IF NOT EXISTS pgcrypto",

    // Required realtime/location tables
    `CREATE TABLE IF NOT EXISTS driver_locations (
      driver_id UUID PRIMARY KEY,
      lat DOUBLE PRECISION DEFAULT 0,
      lng DOUBLE PRECISION DEFAULT 0,
      heading DOUBLE PRECISION DEFAULT 0,
      speed DOUBLE PRECISION DEFAULT 0,
      is_online BOOLEAN NOT NULL DEFAULT false,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    )`,
    "CREATE INDEX IF NOT EXISTS idx_driver_locations_online ON driver_locations(is_online)",

    `CREATE TABLE IF NOT EXISTS user_devices (
      user_id UUID PRIMARY KEY,
      fcm_token TEXT,
      device_type VARCHAR(30) DEFAULT 'android',
      app_version VARCHAR(30) DEFAULT '',
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    )`,

    // Lifecycle/audit tables for production operations and admin controls
    `CREATE TABLE IF NOT EXISTS trip_status (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      trip_id UUID NOT NULL,
      status VARCHAR(50) NOT NULL,
      source VARCHAR(30) NOT NULL DEFAULT 'system',
      note TEXT,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    )`,
    "CREATE INDEX IF NOT EXISTS idx_trip_status_trip_created ON trip_status(trip_id, created_at DESC)",

    `CREATE TABLE IF NOT EXISTS ride_events (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      trip_id UUID NOT NULL,
      event_type VARCHAR(80) NOT NULL,
      actor_id UUID,
      actor_type VARCHAR(30) DEFAULT 'system',
      meta JSONB DEFAULT '{}'::jsonb,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    )`,
    "CREATE INDEX IF NOT EXISTS idx_ride_events_trip_created ON ride_events(trip_id, created_at DESC)",

    `CREATE TABLE IF NOT EXISTS admin_logs (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      admin_email VARCHAR(191),
      action VARCHAR(120) NOT NULL,
      entity_type VARCHAR(80),
      entity_id UUID,
      details JSONB DEFAULT '{}'::jsonb,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    )`,
    "CREATE INDEX IF NOT EXISTS idx_admin_logs_created ON admin_logs(created_at DESC)",

    `CREATE TABLE IF NOT EXISTS ride_complaints (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      trip_id UUID NOT NULL,
      customer_id UUID,
      driver_id UUID,
      complaint_type VARCHAR(80) NOT NULL DEFAULT 'general',
      description TEXT NOT NULL,
      status VARCHAR(30) NOT NULL DEFAULT 'open',
      resolution_note TEXT,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    )`,
    "CREATE INDEX IF NOT EXISTS idx_ride_complaints_status_created ON ride_complaints(status, created_at DESC)",

    `CREATE TABLE IF NOT EXISTS admins (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(255) NOT NULL,
      email VARCHAR(191) NOT NULL UNIQUE,
      password VARCHAR(191) NOT NULL,
      role VARCHAR(50) NOT NULL DEFAULT 'admin',
      is_active BOOLEAN NOT NULL DEFAULT true,
      created_at TIMESTAMP DEFAULT NOW()
    )`,

    // Admin auth/session hardening columns (for deployments with existing admins table)
    "ALTER TABLE admins ADD COLUMN IF NOT EXISTS auth_token TEXT",
    "ALTER TABLE admins ADD COLUMN IF NOT EXISTS auth_token_expires_at TIMESTAMP",
    "ALTER TABLE admins ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMP",
    "CREATE INDEX IF NOT EXISTS idx_admins_auth_token ON admins(auth_token)",
    `CREATE TABLE IF NOT EXISTS admin_login_otp (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      admin_id UUID NOT NULL,
      otp VARCHAR(10) NOT NULL,
      is_used BOOLEAN NOT NULL DEFAULT false,
      expires_at TIMESTAMP NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT NOW()
    )`,
    "CREATE INDEX IF NOT EXISTS idx_admin_login_otp_admin_created ON admin_login_otp(admin_id, created_at DESC)",

    // trip_requests columns used in booking -> assign -> otp -> start -> complete
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS cancel_reason TEXT",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS cancelled_by VARCHAR(30)",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS pickup_otp VARCHAR(10)",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS delivery_otp VARCHAR(10)",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS receiver_name VARCHAR(120)",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS receiver_phone VARCHAR(30)",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS is_for_someone_else BOOLEAN NOT NULL DEFAULT false",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS passenger_name VARCHAR(120)",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS passenger_phone VARCHAR(30)",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS driver_accepted_at TIMESTAMP",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS ride_started_at TIMESTAMP",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS ride_ended_at TIMESTAMP",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS commission_amount DOUBLE PRECISION NOT NULL DEFAULT 0",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS tips DOUBLE PRECISION NOT NULL DEFAULT 0",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS customer_rating DOUBLE PRECISION",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS driver_rating DOUBLE PRECISION",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS driver_note TEXT",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS share_token VARCHAR(64)",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS rejected_driver_ids UUID[] NOT NULL DEFAULT '{}'::uuid[]",
    "ALTER TABLE trip_requests ADD COLUMN IF NOT EXISTS driver_arriving_at TIMESTAMP"
  ];

  for (const sql of statements) {
    await c.query(sql);
  }

  console.log('ride_flow_schema_hotfix_done');
  await c.end();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
