#!/bin/bash
# ============================================================
# JAGO Platform — DigitalOcean Server Setup Script
# Run this ONCE on a fresh Ubuntu 22.04 droplet as root
# Usage: bash server-setup.sh
# ============================================================
set -e

echo "===== [1/8] System Update ====="
apt-get update -y && apt-get upgrade -y

echo "===== [2/8] Install Node.js 20 ====="
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs git nginx certbot python3-certbot-nginx ufw

echo "===== [3/8] Install PM2 ====="
npm install -g pm2

echo "===== [4/8] Firewall ====="
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

echo "===== [5/8] Clone Repository ====="
mkdir -p /var/www
cd /var/www
if [ -d "jago" ]; then
  echo "Repo exists, pulling..."
  cd jago && git pull origin master
else
  git clone https://github.com/jagopro452-cloud/jago.git jago
  cd jago
fi

echo "===== [6/8] Build Application ====="
npm ci
npm run build

echo "===== [7/8] Configure Environment ====="
if [ ! -f ".env" ]; then
  cat > .env << 'EOF'
NODE_ENV=production
PORT=5000
DATABASE_URL=your_postgresql_connection_string_here
ADMIN_EMAIL=kiranatmakuri518@gmail.com
ADMIN_PASSWORD=JagoAdmin@2026!
ADMIN_NAME=Admin
SESSION_SECRET=jago_super_secret_session_key_change_this
RAZORPAY_KEY_ID=your_razorpay_key
RAZORPAY_KEY_SECRET=your_razorpay_secret
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret
FAST2SMS_API_KEY=your_fast2sms_key
GOOGLE_MAPS_API_KEY=AIzaSyBJIuefXlqcKNsIssYHQP6lpIWQ3ih4_Z8
EOF
  echo "IMPORTANT: Edit /var/www/jago/.env and add your DATABASE_URL and API keys!"
fi

echo "===== [8/8] Start + Configure PM2 ====="
pm2 start dist/index.js --name jago --max-memory-restart 512M --env production
pm2 startup systemd -u root --hp /root
pm2 save

echo ""
echo "========================================================="
echo "Server setup complete!"
echo "Next steps:"
echo "1. Edit /var/www/jago/.env → add DATABASE_URL and other keys"
echo "2. Copy nginx config:  cp /var/www/jago/deploy/nginx/jago.conf /etc/nginx/sites-enabled/jago"
echo "3. Edit nginx config:  nano /etc/nginx/sites-enabled/jago  (set server_name jagopro.org)"
echo "4. Test nginx:         nginx -t && systemctl reload nginx"
echo "5. SSL certificate:    certbot --nginx -d jagopro.org"
echo "6. Add GitHub Secrets: DO_HOST, DO_USER, DO_SSH_KEY"
echo "========================================================="
