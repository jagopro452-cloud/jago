#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const root = process.cwd();

function read(relPath) {
  return fs.readFileSync(path.join(root, relPath), 'utf8');
}

function exists(relPath) {
  return fs.existsSync(path.join(root, relPath));
}

function checkContains(source, needle, message) {
  if (!source.includes(needle)) {
    throw new Error(message);
  }
}

function extractApplicationId(gradleText) {
  const match = gradleText.match(/applicationId\s+"([^"]+)"/);
  return match ? match[1] : null;
}

function extractFirebasePackages(googleServicesJsonText) {
  const json = JSON.parse(googleServicesJsonText);
  return (json.client || [])
    .map((client) => client?.client_info?.android_client_info?.package_name)
    .filter(Boolean);
}

async function probeJson(url) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 7000);
  try {
    const res = await fetch(url, { signal: controller.signal });
    const text = await res.text();
    let body = null;
    try {
      body = JSON.parse(text);
    } catch (_) {}
    return { ok: res.ok, status: res.status, body };
  } catch (error) {
    return { ok: false, status: 0, error: error.message };
  } finally {
    clearTimeout(timeout);
  }
}

async function main() {
  const passes = [];
  const warns = [];
  const fails = [];

  function pass(msg) { passes.push(msg); }
  function warn(msg) { warns.push(msg); }
  function fail(msg) { fails.push(msg); }

  try {
    if (!exists('server/routes.ts')) throw new Error('server/routes.ts missing');
    if (!exists('server/socket.ts')) throw new Error('server/socket.ts missing');
    if (!exists('server/dispatch-eligibility.ts')) throw new Error('server/dispatch-eligibility.ts missing');
    if (!exists('flutter_apps/driver_app/lib/screens/home/home_screen.dart')) throw new Error('driver home screen missing');
    if (!exists('flutter_apps/customer_app/lib/screens/booking/premium_location_screen.dart')) throw new Error('premium location screen missing');
    pass('Critical source files present');
  } catch (error) {
    fail(error.message);
  }

  try {
    const routes = read('server/routes.ts');
    checkContains(
      routes,
      'const driverEligibility = await isDriverEligibleForDispatch(driver.id, dispatchRequirements);',
      'accept-trip route missing strict driver eligibility check',
    );
    checkContains(
      routes,
      'notifyNearbyDriversNewTrip(',
      'reject/reassign fallback is not using strict nearby dispatch helper',
    );
    pass('Ride accept route and fallback reassignment use strict dispatch entrypoints');
  } catch (error) {
    fail(error.message);
  }

  try {
    const socket = read('server/socket.ts');
    checkContains(
      socket,
      'const strictDrivers = await findEligibleDriversForDispatch({',
      'socket nearby-trip notifier does not use strict eligible driver search',
    );
    checkContains(
      socket,
      'const eligibility = await isDriverEligibleForDispatch(driverId, requirements);',
      'socket online-driver notifier is missing strict eligibility validation',
    );
    checkContains(
      socket,
      'code: "DISPATCH_MISMATCH"',
      'socket accept flow is missing explicit dispatch mismatch code',
    );
    pass('Socket dispatch paths are strict-filtered');
  } catch (error) {
    fail(error.message);
  }

  try {
    const home = read('flutter_apps/driver_app/lib/screens/home/home_screen.dart');
    checkContains(
      home,
      'await _fetchEligibleServices();',
      'driver home startup does not await eligible services before socket connect',
    );
    checkContains(
      home,
      "_connectSocket();",
      'driver home screen missing socket connect flow',
    );
    checkContains(
      home,
      "This trip does not match your vehicle or enabled service. Please wait for the next request.",
      'driver app is missing explicit mismatch error mapping',
    );
    pass('Driver app startup and mismatch messaging hardened');
  } catch (error) {
    fail(error.message);
  }

  try {
    const premium = read('flutter_apps/customer_app/lib/screens/booking/premium_location_screen.dart');
    if (premium.includes('https://maps.googleapis.com/maps/api/place/autocomplete/json')) {
      throw new Error('premium location screen still calls Google autocomplete directly');
    }
    if (premium.includes('https://maps.googleapis.com/maps/api/place/details/json')) {
      throw new Error('premium location screen still calls Google place details directly');
    }
    checkContains(premium, 'ApiConfig.placesAutocomplete', 'premium location screen missing server-backed autocomplete');
    checkContains(premium, 'ApiConfig.placeDetails', 'premium location screen missing server-backed place details');
    checkContains(premium, 'ApiConfig.reverseGeocode', 'premium location screen missing server-backed reverse geocode');
    pass('Customer premium destination search is server-backed');
  } catch (error) {
    fail(error.message);
  }

  try {
    const customerGradle = read('flutter_apps/customer_app/android/app/build.gradle');
    const driverGradle = read('flutter_apps/driver_app/android/app/build.gradle');
    const customerGoogle = read('flutter_apps/customer_app/android/app/google-services.json');
    const driverGoogle = read('flutter_apps/driver_app/android/app/google-services.json');

    const customerAppId = extractApplicationId(customerGradle);
    const driverAppId = extractApplicationId(driverGradle);
    const customerPackages = extractFirebasePackages(customerGoogle);
    const driverPackages = extractFirebasePackages(driverGoogle);

    if (!customerAppId || !customerPackages.includes(customerAppId)) {
      throw new Error(`customer Firebase package mismatch: gradle=${customerAppId || 'missing'} json=${customerPackages.join(', ')}`);
    }
    if (!driverAppId || !driverPackages.includes(driverAppId)) {
      throw new Error(`driver Firebase package mismatch: gradle=${driverAppId || 'missing'} json=${driverPackages.join(', ')}`);
    }
    pass('Firebase Android package names match app IDs');
  } catch (error) {
    fail(error.message);
  }

  try {
    const stagingSpec = JSON.parse(read('.do/jago-staging-spec.json'));
    const service = (stagingSpec.services || [])[0] || {};
    const envs = service.envs || [];
    const envKeys = new Set(envs.map((entry) => entry.key));

    if (!envKeys.has('FIREBASE_WEB_API_KEY')) {
      throw new Error('staging spec missing FIREBASE_WEB_API_KEY');
    }
    if (!envKeys.has('GOOGLE_MAPS_API_KEY')) {
      throw new Error('staging spec missing GOOGLE_MAPS_API_KEY');
    }
    if (!envKeys.has('SOCKET_ALLOWED_ORIGINS')) {
      throw new Error('staging spec missing SOCKET_ALLOWED_ORIGINS');
    }
    pass('Staging spec declares core Maps/Firebase env vars');

    const appBaseUrl = envs.find((entry) => entry.key === 'APP_BASE_URL')?.value;
    if (appBaseUrl) {
      const health = await probeJson(`${appBaseUrl}/api/health/env`);
      if (health.ok && health.body?.env) {
        const envBody = health.body.env;
        if (envBody.FIREBASE_WEB_API_KEY === true && envBody.GOOGLE_MAPS_API_KEY_resolved === true) {
          pass('Live staging health probe reports Maps and Firebase envs configured');
        } else {
          warn(`Live staging health probe reachable, but env flags are not fully green: ${JSON.stringify(envBody)}`);
        }
      } else {
        warn(`Live staging health probe unreachable or non-JSON (status=${health.status || 0}${health.error ? ` error=${health.error}` : ''})`);
      }
    } else {
      warn('APP_BASE_URL missing from staging spec; skipped live health probe');
    }
  } catch (error) {
    fail(error.message);
  }

  try {
    const envPath = path.join(root, '.env');
    if (fs.existsSync(envPath)) {
      const envText = fs.readFileSync(envPath, 'utf8');
      const hasFirebaseWebKey = /(^|\n)FIREBASE_WEB_API_KEY=.+/m.test(envText);
      const hasFirebaseServiceKey = /(^|\n)FIREBASE_SERVICE_ACCOUNT_KEY=.+/m.test(envText);
      if (!hasFirebaseWebKey && !hasFirebaseServiceKey) {
        warn('Local .env is missing Firebase server verification keys; local OTP verify cannot be fully trusted');
      } else {
        pass('Local .env has Firebase server verification config');
      }
    } else {
      warn('No local .env found; skipped local Firebase verification check');
    }
  } catch (error) {
    warn(`Could not inspect local .env: ${error.message}`);
  }

  try {
    if (!exists('scripts/e2e-production-readiness.cjs')) {
      warn('smoke:prod target is still missing');
    } else {
      pass('smoke:prod target exists');
    }
  } catch (error) {
    warn(`Could not inspect smoke:prod target: ${error.message}`);
  }

  console.log('\nJago core smoke report');
  console.log('=======================');
  for (const msg of passes) console.log(`PASS  ${msg}`);
  for (const msg of warns) console.log(`WARN  ${msg}`);
  for (const msg of fails) console.log(`FAIL  ${msg}`);
  console.log('-----------------------');
  console.log(`Summary: ${passes.length} pass, ${warns.length} warn, ${fails.length} fail`);

  if (fails.length > 0) process.exit(1);
}

main().catch((error) => {
  console.error('Smoke suite crashed:', error);
  process.exit(1);
});
