#!/bin/bash
# ============================================================
# Jago App — AWS EC2 Setup Script
# ============================================================
set -e

APP_DIR="/var/www/jago"
APP_USER="ubuntu"
DB_URL="postgresql://jagoadmin:Jago2024DBpass@jagoapp-db.cwviog02ssvd.us-east-1.rds.amazonaws.com:5432/jagoapp"

echo "==> Updating system..."
sudo apt-get update -y

echo "==> Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "==> Installing PM2 + Git + Nginx..."
sudo npm install -g pm2
sudo apt-get install -y nginx git

echo "==> Cloning Jago repository..."
sudo rm -rf $APP_DIR
sudo mkdir -p $APP_DIR
sudo chown $APP_USER:$APP_USER $APP_DIR
git clone https://github.com/jagopro452-cloud/jago.git $APP_DIR
cd $APP_DIR/jago_app-main

echo "==> Installing dependencies..."
npm install

echo "==> Building app..."
npm run build

echo "==> Writing .env..."
cat > $APP_DIR/jago_app-main/.env <<EOF
NODE_ENV=production
PORT=5000
DATABASE_URL=$DB_URL
SESSION_SECRET=jago_session_secret_2024_production_key_xyz
SMSLOGIN_USERNAME=jago123
SMSLOGIN_API_KEY=90e188232cf203b02e3a
SMSLOGIN_SENDER_ID=JAGOAP
EOF

echo "==> Configuring Nginx..."
sudo tee /etc/nginx/sites-available/jago > /dev/null <<'NGINX'
server {
    listen 80;
    server_name _;
    client_max_body_size 50M;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_read_timeout 86400;
    }
}
NGINX

sudo ln -sf /etc/nginx/sites-available/jago /etc/nginx/sites-enabled/jago
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx

echo "==> Creating log directory..."
sudo mkdir -p /var/log/jago
sudo chown $APP_USER:$APP_USER /var/log/jago

echo "==> Starting app with PM2..."
cd $APP_DIR/jago_app-main
pm2 delete jago 2>/dev/null || true
pm2 start dist/index.js --name jago --env production
pm2 save

echo "==> Setting PM2 to start on boot..."
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $APP_USER --hp /home/$APP_USER | tail -1 | bash || true
pm2 save

echo ""
echo "============================================================"
echo " JAGO DEPLOYED SUCCESSFULLY!"
echo " Open: http://54.234.80.142"
echo "============================================================"
pm2 status
