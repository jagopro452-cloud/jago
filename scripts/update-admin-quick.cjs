#!/usr/bin/env node

/**
 * Quick Admin Reset Script
 * Updates existing admin with new email + password
 */

const pg = require('pg');
const bcrypt = require('bcryptjs');

const { Pool } = pg;

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  console.error('❌ DATABASE_URL not set');
  process.exit(1);
}

const adminEmail = 'Kiranatmakuri518@gmail.com';
const adminPassword = 'Greeshmant@2023';
const adminName = 'Kiran';

(async () => {
  const pool = new Pool({
    connectionString: databaseUrl,
    ssl: { rejectUnauthorized: false },
    max: 1,
    idleTimeoutMillis: 5000,
    connectionTimeoutMillis: 5000,
  });

  try {
    console.log('🔧 Updating admin account...\n');

    // Ensure table exists
    await pool.query(`
      CREATE TABLE IF NOT EXISTS admins (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        email VARCHAR(191) NOT NULL UNIQUE,
        password VARCHAR(191) NOT NULL,
        role VARCHAR(50) NOT NULL DEFAULT 'admin',
        is_active BOOLEAN NOT NULL DEFAULT true,
        auth_token VARCHAR(255),
        auth_token_expires_at TIMESTAMP WITH TIME ZONE,
        last_login_at TIMESTAMP WITH TIME ZONE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      )
    `);

    // Hash password
    console.log('🔐 Hashing password with bcrypt...');
    const hashedPassword = await bcrypt.hash(adminPassword, 12);

    // Delete old admin (if any)
    console.log('🗑️ Removing old admin accounts...');
    await pool.query('DELETE FROM admins WHERE role = $1', ['admin']);

    // Insert new admin
    console.log('👤 Creating new admin account...');
    const result = await pool.query(
      `INSERT INTO admins (name, email, password, role, is_active)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, name, email, role`,
      [adminName, adminEmail, hashedPassword, 'admin', true]
    );

    const adminId = result.rows[0].id;
    console.log('✅ Admin created:\n');
    console.log(`   ID:    ${adminId}`);
    console.log(`   Name:  ${result.rows[0].name}`);
    console.log(`   Email: ${result.rows[0].email}`);
    console.log(`   Role:  ${result.rows[0].role}`);
    console.log(`\n✅ Ready to login!`);
    console.log(`\n📝 Use these credentials:`);
    console.log(`   Email:    ${adminEmail}`);
    console.log(`   Password: ${adminPassword}`);

    await pool.end();
    process.exit(0);
  } catch (err) {
    console.error('❌ Error:', err.message);
    await pool.end();
    process.exit(1);
  }
})();
