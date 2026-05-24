#!/usr/bin/env node
const fs = require("fs");
const os = require("os");
const path = require("path");
const { execFileSync } = require("child_process");

function die(message) {
  console.error(message);
  process.exit(1);
}

function readJson(filePath) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch (error) {
    die(`Failed to read JSON file: ${error.message}`);
  }
}

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--app-id") args.appId = argv[++i];
    else if (arg === "--service-account") args.serviceAccount = argv[++i];
    else if (arg === "--project-id") args.projectId = argv[++i];
    else die(`Unknown argument: ${arg}`);
  }
  return args;
}

function upsertEnv(envs, key, value, encrypted = true) {
  const next = Array.isArray(envs) ? [...envs] : [];
  const existing = next.find((entry) => entry.key === key);
  const item = {
    key,
    value,
    scope: "RUN_AND_BUILD_TIME",
    type: encrypted ? "SECRET" : "GENERAL",
  };
  if (existing) Object.assign(existing, item);
  else next.push(item);
  return next;
}

const args = parseArgs(process.argv);
const appId = args.appId || process.env.DO_APP_ID;
const keyPath = args.serviceAccount || process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
if (!appId) die("--app-id or DO_APP_ID is required");
if (!keyPath) die("--service-account or FIREBASE_SERVICE_ACCOUNT_JSON is required");

const serviceAccount = readJson(keyPath);
if (serviceAccount.type !== "service_account") die("Provided file is not a Firebase Admin service-account JSON");
if (!serviceAccount.project_id || !serviceAccount.client_email || !serviceAccount.private_key) {
  die("Service account JSON is missing project_id, client_email, or private_key");
}

const projectId = args.projectId || process.env.FIREBASE_PROJECT_ID || serviceAccount.project_id;
if (serviceAccount.project_id !== projectId) {
  die(`Project mismatch: service account project_id=${serviceAccount.project_id}, expected=${projectId}`);
}

const appJson = execFileSync("doctl", ["apps", "get", appId, "-o", "json"], {
  encoding: "utf8",
  stdio: ["ignore", "pipe", "pipe"],
});
const parsedApp = JSON.parse(appJson);
const app = Array.isArray(parsedApp) ? parsedApp[0] : parsedApp;
const spec = app.spec;
if (!spec?.services?.length) die("DigitalOcean app spec has no services");

const service = spec.services.find((entry) => entry.name === "jago") || spec.services[0];
service.envs = upsertEnv(service.envs, "FIREBASE_SERVICE_ACCOUNT_KEY", JSON.stringify(serviceAccount), true);
service.envs = upsertEnv(service.envs, "FIREBASE_PROJECT_ID", projectId, true);
service.envs = upsertEnv(service.envs, "REQUIRE_FIREBASE_ADMIN", "true", false);

const tempFile = path.join(os.tmpdir(), `jago-firebase-rotation-${Date.now()}.json`);
fs.writeFileSync(tempFile, JSON.stringify(spec, null, 2));

try {
  execFileSync("doctl", ["apps", "update", appId, "--spec", tempFile], {
    stdio: ["ignore", "ignore", "pipe"],
  });
  console.log(JSON.stringify({
    success: true,
    appId,
    service: service.name,
    projectId,
    envsUpdated: ["FIREBASE_SERVICE_ACCOUNT_KEY", "FIREBASE_PROJECT_ID", "REQUIRE_FIREBASE_ADMIN"],
  }, null, 2));
} finally {
  try {
    fs.rmSync(tempFile, { force: true });
  } catch {
    // ignore cleanup failure
  }
}
