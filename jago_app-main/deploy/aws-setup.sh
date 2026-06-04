#!/bin/bash
# ============================================================
# Jago App — AWS EC2 Setup Script
# Run this ONCE on a fresh Ubuntu 22.04 EC2 instance
# Usage: bash aws-setup.sh
# ============================================================
set -e

APP_DIR="/var/www/jago"
APP_USER="ubuntu"

echo "==> Updating system..."
sudo apt-get update -y && sudo apt-get upgrade -y

echo "==> Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

echo "==> Installing PM2..."
sudo npm install -g pm2

echo "==> Installing Nginx..."
sudo apt-get install -y nginx

echo "==> Installing Git..."
sudo apt-get install -y git

echo "==> Cloning Jago repository..."
sudo mkdir -p $APP_DIR
sudo chown $APP_USER:$APP_USER $APP_DIR
git clone https://github.com/jagopro452-cloud/jago.git $APP_DIR

echo "==> Installing dependencies..."
cd $APP_DIR
npm install

echo "==> Building app..."
npm run build

echo "==> Setting up PM2 ecosystem..."
cp $APP_DIR/deploy/ecosystem.config.cjs $APP_DIR/ecosystem.config.cjs

echo "==> Configuring Nginx..."
sudo cp $APP_DIR/deploy/nginx.conf /etc/nginx/sites-available/jago
sudo ln -sf /etc/nginx/sites-available/jago /etc/nginx/sites-enabled/jago
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

echo "==> Setting up PM2 startup..."
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $APP_USER --hp /home/$APP_USER
pm2 start $APP_DIR/ecosystem.config.cjs
pm2 save

echo "============================================================"
echo "Setup complete!"
echo "Next: Edit $APP_DIR/.env with your RDS and other credentials"
echo "Then: pm2 restart jago"
echo "============================================================"
