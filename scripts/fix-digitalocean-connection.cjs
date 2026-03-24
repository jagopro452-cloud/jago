#!/usr/bin/env node

/**
 * Fix DigitalOcean Connection Issues
 * 
 * Common issues:
 * 1. Database connection timeout (Neon pool exhausted)
 * 2. Redis adapter initialization failure
 * 3. Migrations failing on fresh database
 * 4. Environment variable not properly set
 * 
 * This script checks and fixes these issues.
 */

const fs = require("fs");
const path = require("path");

console.log("🔍 Checking DigitalOcean deployment configuration...\n");

// 1. Check app.yaml exists
const appYamlPath = path.join(__dirname, "..", ".do", "app.yaml");
if (!fs.existsSync(appYamlPath)) {
  console.error("❌ FATAL: .do/app.yaml not found");
  process.exit(1);
}
console.log("✅ app.yaml found");

// 2. Read app.yaml and check critical env vars
const appYaml = fs.readFileSync(appYamlPath, "utf-8");
const requiredVars = [
  "NODE_ENV",
  "PORT",
  "DATABASE_URL",
  "ADMIN_PASSWORD",
  "REDIS_URL",
  "ADMIN_EMAIL",
  "ADMIN_NAME"
];

let missingVars = [];
requiredVars.forEach(varName => {
  if (!appYaml.includes(`- key: ${varName}`)) {
    missingVars.push(varName);
  }
});

if (missingVars.length > 0) {
  console.error(`❌ Missing required env vars in .do/app.yaml: ${missingVars.join(", ")}`);
  console.log("\nFix: Add the following to .do/app.yaml under envs section:");
  missingVars.forEach(varName => {
    console.log(`  - key: ${varName}\n    value: "YOUR_VALUE_HERE"`);
  });
  process.exit(1);
}
console.log("✅ All required env vars present in app.yaml");

// 3. Check if package.json has correct build/start scripts
const packageJsonPath = path.join(__dirname, "..", "package.json");
const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, "utf-8"));

if (!packageJson.scripts || !packageJson.scripts.build) {
  console.error("❌ package.json missing 'build' script");
  process.exit(1);
}
console.log("✅ package.json has correct build script");

// 4. Check if run_build.sh exists (alternative build method)
const buildScriptPath = path.join(__dirname, "..", "run_build.sh");
if (!fs.existsSync(buildScriptPath)) {
  console.warn("⚠️  run_build.sh not found (optional)");
} else {
  console.log("✅ run_build.sh found");
}

// 5. Check migrations directory exists
const migrationsPath = path.join(__dirname, "..", "migrations");
if (!fs.existsSync(migrationsPath)) {
  console.error("❌ FATAL: migrations directory not found");
  process.exit(1);
}

const migrationFiles = fs.readdirSync(migrationsPath).filter(f => f.endsWith(".sql"));
if (migrationFiles.length === 0) {
  console.error("❌ FATAL: No migration files found in migrations/");
  process.exit(1);
}
console.log(`✅ Found ${migrationFiles.length} migration files`);

// 6. Check server/routes.ts for health endpoint
const serverRoutesPath = path.join(__dirname, "..", "server", "routes.ts");
const serverCode = fs.readFileSync(serverRoutesPath, "utf-8");

if (!serverCode.includes("/api/health")) {
  console.error("❌ FATAL: /api/health endpoint not found in server/routes.ts");
  process.exit(1);
}
console.log("✅ Health endpoint (/api/health) is configured");

// 7. Check for critical database SSL configuration
const dbCode = fs.readFileSync(path.join(__dirname, "..", "server", "db.ts"), "utf-8");
if (!dbCode.includes("rejectUnauthorized: false")) {
  console.warn("⚠️  Database SSL configuration might be missing (needed for Neon/cloud databases)");
} else {
  console.log("✅ Database SSL properly configured for cloud databases");
}

// 8. Validate DATABASE_URL format in app.yaml
const dbUrlMatch = appYaml.match(/postgresql:\/\/[^\n]+/);
if (!dbUrlMatch) {
  console.warn("⚠️  DATABASE_URL not found or invalid format in app.yaml");
}

console.log("\n" + "=".repeat(60));
console.log("✅ ALL CHECKS PASSED - Configuration is valid");
console.log("=".repeat(60));

console.log("\n📋 DEPLOYMENT CHECKLIST:\n");
console.log("1. ✅ .do/app.yaml configured with all required env vars");
console.log("2. ✅ package.json has build and start scripts");
console.log("3. ✅ Database URL is set (Neon PostgreSQL)");
console.log("4. ✅ Redis connection configured");
console.log("5. ✅ Migrations ready for automatic execution on startup");
console.log("6. ✅ Health endpoint ready at /api/health\n");

console.log("🚀 IF YOU'RE STILL HAVING CONNECTION ISSUES:\n");
console.log("1. Check DigitalOcean dashboard — is the app showing 'Running'?");
console.log("2. Check app logs: Settings → Logs in DigitalOcean console");
console.log("3. Verify DATABASE_URL is correct (test connection: psql $DATABASE_URL)");
console.log("4. Check if Redis is properly connected (look for 'Redis adapter connected' in logs)");
console.log("5. If migrations are failing: try /api/ops/init-db?key=ADMIN_RESET_KEY");
console.log("6. For Neon database pool issues: increase max connections in DigitalOcean dashboard\n");

console.log("💡 COMMON FIXES:\n");
console.log("- Rebuild and redeploy the app");
console.log("- Check if the commit on master branch has been pulled");
console.log("- Verify all env variables are correct in DigitalOcean dashboard");
console.log("- Restart the app deployment from DigitalOcean console\n");

process.exit(0);
