#!/bin/bash
# ============================================================
# Jago App — Pull latest code & restart
# Run this on EC2 whenever you push new code to GitHub
# Usage: bash /var/www/jago/deploy/update.sh
# ============================================================
set -e

APP_DIR="/var/www/jago"
cd $APP_DIR

echo "==> Pulling latest code..."
git pull origin main

echo "==> Installing dependencies..."
npm install

echo "==> Building..."
npm run build

echo "==> Restarting app..."
pm2 restart jago

echo "==> Done. Status:"
pm2 status jago
