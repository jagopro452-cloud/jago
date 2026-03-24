#!/bin/bash

# JAGO Pro - Admin Setup Script
# For Non-Technical Users
# Just copy-paste this entire script on your DigitalOcean server

set -e

echo "🔧 JAGO Pro Admin Setup Starting..."
echo "=================================="

# These are your custom credentials
ADMIN_EMAIL="atmakuriarena@gmail.com"
ADMIN_PASSWORD="Kiran@1986"
ADMIN_NAME="Jagapro"

# First, go to the jago folder
cd /var/www/jago

echo "📋 Step 1: Pulling latest code..."
git pull origin master

echo "✅ Step 1 Complete"
echo ""

# Check if DATABASE_URL exists
if [ -z "$DATABASE_URL" ]; then
    echo "⚠️  DATABASE_URL not set. Loading from .env file..."
    if [ -f "/var/www/jago/.env" ]; then
        export $(cat /var/www/jago/.env | xargs)
    else
        echo "❌ ERROR: .env file not found at /var/www/jago/.env"
        echo "Please create .env file with DATABASE_URL"
        exit 1
    fi
fi

echo ""
echo "📝 Step 2: Creating admin account..."
echo "   Email: $ADMIN_EMAIL"
echo "   Name: $ADMIN_NAME"
echo "   Password: ••••••••"
echo ""

# Create temporary Node.js script to set up admin
cat > /tmp/setup-admin-temp.js << 'EOFSCRIPT'
const pg = require('pg');
const bcrypt = require('bcryptjs');

(async () => {
  try {
    const databaseUrl = process.env.DATABASE_URL;
    if (!databaseUrl) {
      throw new Error('DATABASE_URL environment variable not set');
    }

    const pool = new pg.Pool({
      connectionString: databaseUrl,
      ssl: { rejectUnauthorized: false },
      max: 1,
      connectionTimeoutMillis: 5000,
    });

    console.log('Connecting to database...');
    
    // Create admins table
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

    // Create indexes
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_admins_email ON admins(LOWER(email))
    `).catch(() => {});

    // Hash password
    const passwordHash = await bcrypt.hash(process.env.ADMIN_PASSWORD, 12);

    // Insert or update admin
    const result = await pool.query(
      `INSERT INTO admins (name, email, password, role, is_active)
       VALUES ($1, $2, $3, $4, true)
       ON CONFLICT (email)
       DO UPDATE SET password=$3, name=$1, is_active=true
       RETURNING id, email, name, role`,
      [process.env.ADMIN_NAME, process.env.ADMIN_EMAIL, passwordHash, 'admin']
    );

    const admin = result.rows[0];
    console.log('✅ Admin created successfully!');
    console.log('ID: ' + admin.id);
    console.log('Email: ' + admin.email);
    console.log('Name: ' + admin.name);

    await pool.end();
    process.exit(0);

  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
})();
EOFSCRIPT

# Set environment variables and run the script
export ADMIN_EMAIL="$ADMIN_EMAIL"
export ADMIN_PASSWORD="$ADMIN_PASSWORD"
export ADMIN_NAME="$ADMIN_NAME"

node /tmp/setup-admin-temp.js

echo "✅ Step 2 Complete"
echo ""

echo "🔄 Step 3: Restarting server..."
pm2 restart jago-pro
sleep 5

echo "✅ Step 3 Complete"
echo ""

echo "======================================"
echo "✅ SUCCESS! Admin setup is complete!"
echo "======================================"
echo ""
echo "🌐 Login to Admin Panel:"
echo "   https://jagopro.org/admin/auth/login"
echo ""
echo "📧 Credentials:"
echo "   Email: $ADMIN_EMAIL"
echo "   Password: $ADMIN_PASSWORD"
echo ""
echo "⏳ Wait 2-3 minutes for server to fully start..."
echo ""

# Cleanup
rm -f /tmp/setup-admin-temp.js

echo "🎉 Done!"
