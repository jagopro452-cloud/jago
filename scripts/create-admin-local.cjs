const pg = require('pg');
const bcrypt = require('bcryptjs');

(async () => {
  const pool = new pg.Pool({
    connectionString: process.env.DATABASE_URL || 'postgresql://postgres:postgres@localhost:5432/postgres',
    ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false,
    max: 1,
  });

  const adminEmail = (process.env.ADMIN_EMAIL || 'kiranatmakuri518@gmail.com').trim().toLowerCase();
  const adminPassword = process.env.ADMIN_PASSWORD || 'JagoAdmin@2026!';
  const adminName = (process.env.ADMIN_NAME || 'Jago Admin').trim() || 'Jago Admin';

  console.log('Creating admin with email:', adminEmail);

  // Ensure UUID generator exists (pgcrypto may be unavailable in some environments)
  await pool.query(`CREATE EXTENSION IF NOT EXISTS pgcrypto`).catch(() => {});
  await pool.query(`
    DO $$
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'gen_random_uuid') THEN
        CREATE OR REPLACE FUNCTION gen_random_uuid()
        RETURNS uuid
        AS $fn$ SELECT md5(random()::text || clock_timestamp()::text)::uuid; $fn$
        LANGUAGE sql;
      END IF;
    END
    $$;
  `).catch(() => {});

  await pool.query(`
    CREATE TABLE IF NOT EXISTS admins (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(255) NOT NULL,
      email VARCHAR(191) NOT NULL UNIQUE,
      password VARCHAR(191) NOT NULL,
      role VARCHAR(50) NOT NULL DEFAULT 'admin',
      is_active BOOLEAN NOT NULL DEFAULT true,
      auth_token VARCHAR(255),
      auth_token_expires_at TIMESTAMPTZ,
      last_login_at TIMESTAMPTZ,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);

  const hash = await bcrypt.hash(adminPassword, 12);
  const r = await pool.query(
    `INSERT INTO admins (name, email, password, role, is_active)
     VALUES ($1, $2, $3, $4, true)
     ON CONFLICT (email)
     DO UPDATE SET password=$3, name=$1, is_active=true
     RETURNING id, email, role`,
    [adminName, adminEmail, hash, 'admin']
  );

  console.log('Admin created:', JSON.stringify(r.rows[0]));
  console.log('Email:', adminEmail);
  console.log('Password:', adminPassword);
  await pool.end();
})().catch(e => { console.error('ERROR:', e.message); process.exit(1); });
