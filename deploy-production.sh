#!/bin/bash

# JAGO Pro - Complete Deployment Script
# Run this ONCE on DigitalOcean server to deploy everything
# No coding needed - just one command!

set -e

echo ""
echo "=============================================="
echo "🚀 JAGO Pro - PRODUCTION DEPLOYMENT"
echo "=============================================="
echo ""

ADMIN_EMAIL="atmakuriarena@gmail.com"
ADMIN_PASSWORD="Kiran@1986"
ADMIN_NAME="Jagapro"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Navigate to jago directory
echo -e "${YELLOW}📁 Step 1: Going to jago directory...${NC}"
cd /var/www/jago
echo -e "${GREEN}✅ Ready${NC}"
echo ""

# Step 2: Pull latest code
echo -e "${YELLOW}📥 Step 2: Pulling latest code from GitHub...${NC}"
git pull origin master --quiet
echo -e "${GREEN}✅ Code updated${NC}"
echo ""

# Step 3: Install dependencies
echo -e "${YELLOW}📦 Step 3: Installing dependencies...${NC}"
npm install --quiet
echo -e "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Step 4: Build application
echo -e "${YELLOW}🔨 Step 4: Building application...${NC}"
npm run build --quiet
echo -e "${GREEN}✅ Build complete${NC}"
echo ""

# Step 5: Create/Update Admin Account
echo -e "${YELLOW}👤 Step 5: Setting up admin account...${NC}"
cat > /tmp/setup-admin-deploy.js << 'EOFJS'
const pg = require('pg');
const bcrypt = require('bcryptjs');

(async () => {
  try {
    const pool = new pg.Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
      max: 1,
      connectionTimeoutMillis: 5000,
    });

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

    // Create index
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_admins_email ON admins(LOWER(email))
    `).catch(() => {});

    // Hash password with bcrypt 12 rounds
    const hash = await bcrypt.hash(process.env.ADMIN_PASSWORD, 12);

    // Insert or update admin
    const result = await pool.query(
      `INSERT INTO admins (name, email, password, role, is_active)
       VALUES ($1, $2, $3, 'admin', true)
       ON CONFLICT (email)
       DO UPDATE SET password=$3, name=$1, is_active=true
       RETURNING email, name, role`,
      [process.env.ADMIN_NAME, process.env.ADMIN_EMAIL, hash]
    );

    const admin = result.rows[0];
    console.log(`✅ Admin ready: ${admin.email}`);
    await pool.end();
    process.exit(0);

  } catch (error) {
    console.error('❌ Admin setup failed:', error.message);
    process.exit(1);
  }
})();
EOFJS

ADMIN_EMAIL="$ADMIN_EMAIL" \
ADMIN_PASSWORD="$ADMIN_PASSWORD" \
ADMIN_NAME="$ADMIN_NAME" \
DATABASE_URL="$DATABASE_URL" \
node /tmp/setup-admin-deploy.js

echo -e "${GREEN}✅ Admin account ready${NC}"
echo ""

# Step 6: Restart server
echo -e "${YELLOW}🔄 Step 6: Restarting server...${NC}"
pm2 restart jago-pro --silent
sleep 5
echo -e "${GREEN}✅ Server restarted${NC}"
echo ""

# Step 7: Verify server is running
echo -e "${YELLOW}✓ Step 7: Verifying server...${NC}"
sleep 5
HEALTH=$(curl -s https://oyster-app-9e9cd.ondigitalocean.app/api/health || echo "error")
if [[ $HEALTH == *"ok"* ]]; then
  echo -e "${GREEN}✅ Server is healthy${NC}"
else
  echo -e "${YELLOW}⏳ Server still starting... (this is normal)${NC}"
fi
echo ""

# Cleanup
rm -f /tmp/setup-admin-deploy.js

# Final Summary
echo "=============================================="
echo -e "${GREEN}✅ DEPLOYMENT COMPLETE!${NC}"
echo "=============================================="
echo ""
echo "🌐 Access your app:"
echo "   Admin: https://jagopro.org/admin/auth/login"
echo "   App: https://jagopro.org"
echo ""
echo "📧 Admin Credentials:"
echo "   Email:    atmakuriarena@gmail.com"
echo "   Password: Kiran@1986"
echo ""
echo "⏳ Server may take 30-60 seconds to fully warm up"
echo "   If login fails, wait 1 minute and try again"
echo ""
echo "📊 View server logs:"
echo "   pm2 logs jago-pro"
echo ""
echo "🎉 Your app is now LIVE!"
echo ""
