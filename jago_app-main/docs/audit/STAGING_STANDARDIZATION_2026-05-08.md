# JAGO Staging Standardization Report - 2026-05-08

## Scope

This pass standardized the staging deployment contract and evidence workflow for
the release branch `release/preprod-hardening-2026-05-08-recovered`.

## Completed

- Added validated App Platform staging spec: `.do/app.staging.yaml`
- Added staging secrets template: `.do/staging.secrets.template.env`
- Added deployment checklist: `docs/ops/STAGING_DEPLOYMENT_CHECKLIST.md`
- Added environment inventory: `docs/ops/STAGING_ENVIRONMENT_INVENTORY.md`
- Added secrets inventory template: `docs/ops/STAGING_SECRETS_INVENTORY_TEMPLATE.md`
- Added deploy verification checklist: `docs/ops/STAGING_DEPLOY_VERIFICATION_CHECKLIST.md`
- Added evidence capture tool: `scripts/ops/capture-staging-evidence.mjs`
- Added package script: `npm run ops:staging-evidence`
- Sanitized legacy deployment scripts to remove embedded admin credentials and API keys

## Validation proof

### Type safety

- `npm run check` passed after all staging/tooling changes

### Secret hygiene

The following previously tracked literals were removed from active deploy scripts:

- hardcoded admin password strings
- hardcoded reset key string
- hardcoded Google Maps API key string

### DigitalOcean spec validation

Validated successfully:

```bash
doctl apps spec validate .do/app.staging.yaml
```

Important platform constraint discovered during validation:

- Managed Postgres and Valkey must be attached as production-managed cluster references in App Platform spec
- The staging spec therefore expects separately provisioned clusters named `jago-staging-postgres` and `jago-staging-redis`

## Current infrastructure findings

Provisioned and verified from operator tooling:

- Staging app name: `jago-staging`
- Staging app id: `c628b4a3-e535-4450-87f1-35c9164b28a3`
- Staging default ingress: `https://jago-staging-ljuq3.ondigitalocean.app`
- Staging Postgres id: `9c736c05-d4a8-4125-bdc5-c5e26b9805dd`
- Staging Postgres name: `jago-staging-postgres`
- Staging cache id: `5aaee7bd-ea75-4ba1-9063-fb3538d25b47`
- Staging cache name: `jago-staging-redis`
- Staging cache engine: `valkey`
- Deployment region for managed data resources: `blr1`
- DigitalOcean CLI access is available on this machine
- No local staging `.env` or checked-in `.env.staging.example` exists

## Live staging validation completed

- `doctl apps spec validate .do/app.staging.yaml` passed
- Live staging app was created successfully from a staging-only spec
- `GET /api/health` returned `200`
- `GET /api/ops/ready` returned `200`
- `GET /api/ops/metrics` returned `200`
- `GET /api/health/env` returned `200`
- Protected ops endpoints were confirmed with the `x-ops-key` header
- Initial runtime errors caused by missing staging schema objects were reconciled
- Post-reconciliation logs no longer showed the recurring `zones.latitude`, `trip_requests.pickup_short_name`, or `user_devices` runtime failures in the latest log window

Evidence captured under:

- `docs/audit/evidence/2026-05-08-staging/staging-evidence.json`
- `docs/audit/evidence/2026-05-08-staging-postschema/staging-evidence.json`
- `docs/audit/evidence/2026-05-08-staging-postreconcile/staging-evidence.json`

## Device findings

Available Flutter targets:

- Windows
- Chrome
- Edge

Unavailable for required release validation:

- physical Android phones
- physical iPhones
- `adb`-based Android evidence workflow

## What remains blocked

### Remaining staging configuration gaps

Still missing or not yet proven in the live app:

- `GOOGLE_MAPS_API_KEY`
- `FIREBASE_SERVICE_ACCOUNT_KEY`
- `FIREBASE_WEB_API_KEY`
- `RAZORPAY_KEY_ID`
- `RAZORPAY_KEY_SECRET`
- `RAZORPAY_WEBHOOK_SECRET`
- `TWO_FACTOR_API_KEY`
- `FAST2SMS_API_KEY`
- `ANTHROPIC_API_KEY`
- `ALERT_WEBHOOK_URL`

### Live operational evidence still blocked

Not yet completed from this machine:

- socket connectivity proof with real clients
- runtime-config propagation proof
- rollback endpoint validation
- Redis outage drill
- alert delivery verification
- Crashlytics or Sentry delivery proof

### Real device matrix

Not executable from this machine because no physical mobile devices are connected.

## Recommended next operator actions

1. Populate the remaining staging-only third-party secrets from `.do/staging.secrets.template.env`.
2. Update the live staging app to use the finalized staging domain and socket origin instead of the bootstrap base URL.
3. Execute runtime-config publish and rollback validation against the live staging app.
4. Execute the mobile manual matrix from `docs/MANUAL_TESTING_GUIDE.md` on physical devices.
5. Perform Redis outage drill and alert verification against staging only.
6. Archive screenshots and timestamps alongside the existing JSON probe captures.

## Release gate status

Staging is now standardized and live, with isolated infrastructure and green
baseline ops probes. The final production gate remains blocked on third-party
secret completion, real-device validation, Redis outage evidence, and alert
delivery proof.
