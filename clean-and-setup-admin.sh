#!/bin/bash

# Clean Admin Setup - Delete old and create fresh admin account
# Run on DigitalOcean server

set -e

echo ""
echo "========================================="
echo "🗑️  CLEANING UP OLD ADMIN ACCOUNTS"
echo "========================================="
echo ""

cd /var/www/jago

# Create script to delete all old admins
cat > /tmp/clean-admin.js << 'EOFJS'
const pg = require('pg');
const bcrypt = require('bcryptjs');

(async () => {
  try {
    const pool = new pg.Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    });

    console.log('📋 Creating admins table if not exists...');
    
    // Create table
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

    console.log('✅ Table ready');
    console.log('');

    // Delete ALL existing admins
    console.log('🗑️  Deleting ALL old admin accounts...');
    const deleteResult = await pool.query('DELETE FROM admins');
    console.log(`✅ Deleted ${deleteResult.rowCount} old admin account(s)`);
    console.log('');

    // Hash password
    console.log('🔐 Creating new admin account...');
    const hash = await bcrypt.hash(process.env.ADMIN_PASSWORD, 12);

    // Insert fresh admin
    const result = await pool.query(
      `INSERT INTO admins (name, email, password, role, is_active)
       VALUES ($1, $2, $3, 'admin', true)
       RETURNING id, email, name, role`,
      [process.env.ADMIN_NAME, process.env.ADMIN_EMAIL, hash]
    );

    const admin = result.rows[0];
    console.log('✅ New admin created: ' + admin.email);
    console.log('');

    await pool.end();
    process.exit(0);

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
})();
EOFJS

echo "🗑️  Deleting old admin accounts..."
ADMIN_EMAIL="atmakuriarena@gmail.com" \
ADMIN_PASSWORD="Kiran@1986" \
ADMIN_NAME="Jagapro" \
DATABASE_URL="$DATABASE_URL" \
node /tmp/clean-admin.js

echo ""
echo "========================================="
echo "✅ ADMIN CLEANED & FRESH ACCOUNT CREATED"
echo "========================================="
echo ""
echo "🌐 Admin Login:"
echo "   Email: atmakuriarena@gmail.com"
echo "   Password: Kiran@1986"
echo ""

# Restart server
echo "🔄 Restarting server..."
pm2 restart jago-pro --silent
sleep 5

echo "✅ Server restarted"
echo ""
echo "📝 Ready to login at:"
echo "   https://jagopro.org/admin/auth/login"
echo ""

rm -f /tmp/clean-admin.js
