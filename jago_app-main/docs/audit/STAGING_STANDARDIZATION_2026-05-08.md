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

- Redis must be attached as a production-managed cluster reference in App Platform spec
- The staging spec therefore expects a separately provisioned cluster named `jago-staging-redis`

## Current infrastructure findings

Observed from available operator tooling:

- DigitalOcean CLI access is available on this machine
- Existing managed resource visible: `jago-redis`
- No clearly named JAGO staging app currently exists in App Platform list
- No dedicated `jago-staging-redis` resource was visible at validation time
- No local staging `.env` or checked-in `.env.staging.example` exists

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

### Staging deployment

Not executed because:

- staging-only secret values are not available in this worktree
- a dedicated staging Redis cluster is not yet confirmed
- a dedicated staging Postgres mapping is not yet confirmed
- creating new managed resources would create billable infrastructure and should be done deliberately

### Live operational evidence

Not yet captured because there is no confirmed live staging base URL for:

- `/api/health`
- `/api/ops/ready`
- `/api/ops/metrics`
- socket runtime validation
- Redis outage drill
- alert delivery verification

### Real device matrix

Not executable from this machine because no physical mobile devices are connected.

## Recommended next operator actions

1. Provision `jago-staging-postgres` and `jago-staging-redis`.
2. Populate staging-only secrets from `.do/staging.secrets.template.env`.
3. Create the staging app from `.do/app.staging.yaml`.
4. Run `npm run ops:staging-evidence -- --base-url=<staging-url> --ops-key=<ops-key>`.
5. Execute the mobile manual matrix from `docs/MANUAL_TESTING_GUIDE.md` on physical devices.
6. Perform Redis outage drill and alert verification against staging only.

## Release gate status

Staging is now standardized and reproducible on paper and in tooling, but the
final operational evidence gate remains blocked until live staging resources,
staging secrets, and physical devices are available.
