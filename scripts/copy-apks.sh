#!/bin/bash
# APK Auto-Copy Script - Copies newly built APKs to public/apks folder
# Usage: bash scripts/copy-apks.sh

set -e

echo "🔄 APK Auto-Copy Script"
echo "======================"

# Customer App
if [ -f "flutter_apps/customer_app/build/app/outputs/apk/release/app-release.apk" ]; then
    echo "📱 Found Customer App..."
    cp "flutter_apps/customer_app/build/app/outputs/apk/release/app-release.apk" \
       "public/apks/jago-customer-v1.0.56-release.apk"
    echo "✅ Copied: jago-customer-v1.0.56-release.apk"
    
    cp "public/apks/jago-customer-v1.0.56-release.apk" \
       "public/apks/jago-customer-final.apk"
    echo "✅ Copied: jago-customer-final.apk"
else
    echo "❌ Customer app build not found"
    echo "   Build it first: cd flutter_apps/customer_app && flutter build apk --release"
fi

# Driver App
if [ -f "flutter_apps/driver_app/build/app/outputs/apk/release/app-release.apk" ]; then
    echo ""
    echo "🚗 Found Driver App..."
    cp "flutter_apps/driver_app/build/app/outputs/apk/release/app-release.apk" \
       "public/apks/jago-driver-v1.0.58-release.apk"
    echo "✅ Copied: jago-driver-v1.0.58-release.apk"
    
    cp "public/apks/jago-driver-v1.0.58-release.apk" \
       "public/apks/jago-driver-final.apk"
    echo "✅ Copied: jago-driver-final.apk"
else
    echo "❌ Driver app build not found"
    echo "   Build it first: cd flutter_apps/driver_app && flutter build apk --release"
fi

# Verify
echo ""
echo "📊 Current APKs in public/apks/:"
ls -lh public/apks/*.apk | awk '{print $9, "(" $5 ")"}'

echo ""
echo "✅ Done!"
