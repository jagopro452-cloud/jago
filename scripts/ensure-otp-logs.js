const { Client } = require('pg');

(async () => {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();
  await c.query("CREATE EXTENSION IF NOT EXISTS pgcrypto");
  await c.query("CREATE TABLE IF NOT EXISTS otp_logs (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), phone VARCHAR(20) NOT NULL, otp VARCHAR(10) NOT NULL, user_type VARCHAR(20) NOT NULL DEFAULT 'customer', expires_at TIMESTAMP NOT NULL, is_used BOOLEAN NOT NULL DEFAULT false, created_at TIMESTAMP NOT NULL DEFAULT NOW())");
  await c.query("CREATE INDEX IF NOT EXISTS idx_otp_logs_phone_created ON otp_logs(phone, created_at DESC)");
  await c.query("CREATE INDEX IF NOT EXISTS idx_otp_logs_phone_otp_active ON otp_logs(phone, otp, is_used)");
  console.log('otp_logs_ready');
  await c.end();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
