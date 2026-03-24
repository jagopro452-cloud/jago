#!/usr/bin/env node

/**
 * APK Auto-Sync Script
 * Automatically copies latest APKs from release-apks/ to public/apks/
 * Runs before each deployment to ensure latest versions are always available
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const SOURCE_DIR = path.join(__dirname, '..', 'release-apks');
const DEST_DIR = path.join(__dirname, '..', 'public', 'apks');

function copyFile(src, dest) {
  try {
    fs.copyFileSync(src, dest);
    console.log(`✅ Synced: ${path.basename(src)}`);
    return true;
  } catch (err) {
    console.error(`❌ Failed to sync ${path.basename(src)}:`, err.message);
    return false;
  }
}

function syncAPKs() {
  console.log('🔄 Starting APK Auto-Sync...\n');

  // Ensure destination directory exists
  if (!fs.existsSync(DEST_DIR)) {
    fs.mkdirSync(DEST_DIR, { recursive: true });
    console.log(`📁 Created directory: ${DEST_DIR}\n`);
  }

  // Read all APK files from release-apks
  const apkFiles = fs.readdirSync(SOURCE_DIR).filter(file => file.endsWith('.apk'));

  if (apkFiles.length === 0) {
    console.log('⚠️  No APK files found in release-apks/');
    return false;
  }

  console.log(`📦 Found ${apkFiles.length} APK files:\n`);

  let syncCount = 0;
  const filesToCopy = [
    'jago-customer-v1.0.55-release.apk',
    'jago-pilot-v1.0.57-release.apk',
    'jago-customer-final.apk',
    'jago-driver-final.apk'
  ];

  // Copy specific latest versions + finals
  filesToCopy.forEach(fileName => {
    const srcPath = path.join(SOURCE_DIR, fileName);
    if (fs.existsSync(srcPath)) {
      const destPath = path.join(DEST_DIR, fileName);
      if (copyFile(srcPath, destPath)) {
        syncCount++;
      }
    }
  });

  // Also sync any version updates (for fallback)
  apkFiles.forEach(fileName => {
    const srcPath = path.join(SOURCE_DIR, fileName);
    const destPath = path.join(DEST_DIR, fileName);
    
    // Skip if already synced or old versions
    if (fileName.includes('v1.0.55') || fileName.includes('v1.0.57') || 
        fileName.includes('final')) {
      return;
    }
    
    // Only copy if newer
    const srcStat = fs.statSync(srcPath);
    const destExists = fs.existsSync(destPath);
    
    if (!destExists || srcStat.mtime > fs.statSync(destPath).mtime) {
      if (copyFile(srcPath, destPath)) {
        syncCount++;
      }
    }
  });

  console.log(`\n✨ Sync complete! ${syncCount} files synced.\n`);

  // Verify latest versions exist
  const customerLatest = path.join(DEST_DIR, 'jago-customer-v1.0.55-release.apk');
  const driverLatest = path.join(DEST_DIR, 'jago-pilot-v1.0.57-release.apk');

  const customerOK = fs.existsSync(customerLatest);
  const driverOK = fs.existsSync(driverLatest);

  console.log('📋 Latest versions status:');
  console.log(`   ${customerOK ? '✅' : '❌'} Customer v1.0.55 available`);
  console.log(`   ${driverOK ? '✅' : '❌'} Driver v1.0.57 available\n`);

  if (customerOK && driverOK) {
    console.log('🎉 All APKs ready for download!\n');
    return true;
  } else {
    console.warn('⚠️  Some APKs missing - deployment may fail\n');
    return false;
  }
}

// Run the sync
syncAPKs();
