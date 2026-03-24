#!/bin/bash

# Update Admin Account on Production Server
# Usage: bash deploy-admin-update.sh

echo "🚀 Updating Admin Account on Production..."
echo ""

# SSH to production server
ssh -o StrictHostKeyChecking=no root@oyster-app-9e9cd.ondigitalocean.app << 'EOF'

cd /var/www/jago

echo "📝 Getting latest code..."
git pull origin main --quiet

echo "🔧 Running admin update script..."
DATABASE_URL="${DATABASE_URL}" node scripts/update-admin-quick.cjs

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Admin account updated successfully!"
  echo ""
  echo "🔄 Restarting server..."
  pm2 restart jago-pro
  sleep 2
  pm2 logs jago-pro --lines 20
else
  echo "❌ Admin update failed"
  exit 1
fi

EOF

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🧪 Test login:"
echo "   Email:    Kiranatmakuri518@gmail.com"
echo "   Password: Greeshmant@2023"
echo "   URL:      https://jagopro.org/admin/auth/login"
