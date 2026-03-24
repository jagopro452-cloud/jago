import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const SOURCE_DIR = path.join(__dirname, '..', 'release-apks');
const DEST_DIR_PUBLIC = path.join(__dirname, '..', 'public', 'apks');
const DEST_DIR_DIST = path.join(__dirname, '..', 'dist', 'public', 'apks');

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

function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
    console.log(`📁 Created directory: ${dirPath}`);
  }
}

function syncAPKs() {
  console.log('🔄 Starting APK Auto-Sync...\n');

  // Ensure both destination directories exist
  ensureDir(DEST_DIR_PUBLIC);
  ensureDir(DEST_DIR_DIST);

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

  // Copy specific latest versions + finals to BOTH locations
  filesToCopy.forEach(fileName => {
    const srcPath = path.join(SOURCE_DIR, fileName);
    if (fs.existsSync(srcPath)) {
      // Copy to public/apks/
      const destPath1 = path.join(DEST_DIR_PUBLIC, fileName);
      if (copyFile(srcPath, destPath1)) {
        syncCount++;
      }
      
      // Copy to dist/public/apks/ (for web server)
      const destPath2 = path.join(DEST_DIR_DIST, fileName);
      if (copyFile(srcPath, destPath2)) {
        syncCount++;
      }
    }
  });

  // Also sync any version updates (for fallback)
  apkFiles.forEach(fileName => {
    const srcPath = path.join(SOURCE_DIR, fileName);
    
    // Skip if already synced
    if (fileName.includes('v1.0.55') || fileName.includes('v1.0.57') || 
        fileName.includes('final')) {
      return;
    }
    
    // Sync to both locations
    const destPath1 = path.join(DEST_DIR_PUBLIC, fileName);
    const destPath2 = path.join(DEST_DIR_DIST, fileName);
    
    const srcStat = fs.statSync(srcPath);
    
    // Check both destinations
    const dest1Exists = fs.existsSync(destPath1);
    const dest2Exists = fs.existsSync(destPath2);
    
    if (!dest1Exists || srcStat.mtime > fs.statSync(destPath1).mtime) {
      copyFile(srcPath, destPath1);
      syncCount++;
    }
    
    if (!dest2Exists || srcStat.mtime > fs.statSync(destPath2).mtime) {
      copyFile(srcPath, destPath2);
      syncCount++;
    }
  });

  console.log(`\n✨ Sync complete! Files synced to both locations.\n`);

  // Verify latest versions exist in BOTH places
  const customerLatest1 = path.join(DEST_DIR_PUBLIC, 'jago-customer-v1.0.55-release.apk');
  const customerLatest2 = path.join(DEST_DIR_DIST, 'jago-customer-v1.0.55-release.apk');
  const driverLatest1 = path.join(DEST_DIR_PUBLIC, 'jago-pilot-v1.0.57-release.apk');
  const driverLatest2 = path.join(DEST_DIR_DIST, 'jago-pilot-v1.0.57-release.apk');

  const customer1OK = fs.existsSync(customerLatest1);
  const customer2OK = fs.existsSync(customerLatest2);
  const driver1OK = fs.existsSync(driverLatest1);
  const driver2OK = fs.existsSync(driverLatest2);

  console.log('📋 Latest versions status:');
  console.log(`   ${customer1OK ? '✅' : '❌'} Customer v1.0.55 in public/apks/`);
  console.log(`   ${customer2OK ? '✅' : '❌'} Customer v1.0.55 in dist/public/apks/ (WEB SERVER)`);
  console.log(`   ${driver1OK ? '✅' : '❌'} Driver v1.0.57 in public/apks/`);
  console.log(`   ${driver2OK ? '✅' : '❌'} Driver v1.0.57 in dist/public/apks/ (WEB SERVER)\n`);

  if (customer1OK && customer2OK && driver1OK && driver2OK) {
    console.log('🎉 All APKs ready for download on web server!\n');
    return true;
  } else {
    console.warn('⚠️  Some APKs missing in required locations\n');
    return false;
  }
}

// Run the sync
syncAPKs();
