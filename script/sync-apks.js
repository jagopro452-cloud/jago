import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const SOURCE_DIR = path.join(__dirname, '..', 'public', 'apks');
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

  // Check if public/apks directory exists
  if (!fs.existsSync(SOURCE_DIR)) {
    console.log('⚠️  public/apks/ directory not found - skipping APK sync');
    console.log('   (This is normal in production - APKs are hosted separately)\n');
    return true; // Don't fail the build
  }

  // Ensure destination directory exists
  ensureDir(DEST_DIR_DIST);

  // Read all APK files from release-apks
  const apkFiles = fs.readdirSync(SOURCE_DIR).filter(file => file.endsWith('.apk'));

  if (apkFiles.length === 0) {
    console.log('⚠️  No APK files found in public/apks/');
    return true; // Don't fail the build
  }

  console.log(`📦 Found ${apkFiles.length} APK files:\n`);

  let syncCount = 0;
  const filesToCopy = [
    'jago-customer-v1.0.56-release.apk',
    'jago-customer-final.apk',
    'jago-driver-v1.0.58-release.apk',
    'jago-driver-final.apk',
    'jago-pilot-final.apk'
  ];

  // Copy specific latest versions to web server
  filesToCopy.forEach(fileName => {
    const srcPath = path.join(SOURCE_DIR, fileName);
    if (fs.existsSync(srcPath)) {
      // Copy to dist/public/apks/ (for web server)
      const destPath = path.join(DEST_DIR_DIST, fileName);
      if (copyFile(srcPath, destPath)) {
        syncCount++;
      }
    }
  });

  console.log(`\n✨ Sync complete! Latest APKs ready for web server.\n`);

  // Verify latest versions exist
  const customerLatest = path.join(DEST_DIR_DIST, 'jago-customer-v1.0.56-release.apk');
  const driverLatest = path.join(DEST_DIR_DIST, 'jago-driver-v1.0.58-release.apk');
  const pilotLatest = path.join(DEST_DIR_DIST, 'jago-pilot-final.apk');
  const customerFinal = path.join(DEST_DIR_DIST, 'jago-customer-final.apk');
  const driverFinal = path.join(DEST_DIR_DIST, 'jago-driver-final.apk');

  const customerOK = fs.existsSync(customerLatest);
  const driverOK = fs.existsSync(driverLatest);
  const pilotOK = fs.existsSync(pilotLatest);
  const customerFinalOK = fs.existsSync(customerFinal);
  const driverFinalOK = fs.existsSync(driverFinal);

  console.log('📋 Latest versions status:');
  console.log(`   ${customerOK ? '✅' : '❌'} Customer v1.0.56 in dist/public/apks/ (WEB SERVER)`);
  console.log(`   ${driverOK ? '✅' : '❌'} Driver v1.0.58 in dist/public/apks/ (WEB SERVER)`);
  console.log(`   ${pilotOK ? '✅' : '❌'} Pilot v1.0.58 in dist/public/apks/ (WEB SERVER)`);
  console.log(`   ${customerFinalOK ? '✅' : '❌'} Customer Download Link Ready`);
  console.log(`   ${driverFinalOK ? '✅' : '❌'} Driver Download Link Ready\n`);

  if (customerOK && driverOK && customerFinalOK && driverFinalOK) {
    console.log('🎉 All APKs ready for download on web server!\n');
    return true;
  } else {
    console.log('⚠️  Some APKs not found (this is OK in production)\n');
    return true; // Don't fail the build
  }
}

// Run the sync
syncAPKs();
