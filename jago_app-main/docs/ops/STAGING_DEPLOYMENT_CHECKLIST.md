# JAGO Staging Deployment Checklist

## Purpose

Standardize staging so release candidates can be deployed and validated without
touching production infrastructure or runtime state.

## 1. Provision isolated infrastructure

- Create App Platform app from `.do/app.staging.yaml`
- Confirm app name is `jago-staging`
- Confirm branch is `release/preprod-hardening-2026-05-08-recovered`
- Provision dedicated Postgres named `jago-staging-postgres`
- Provision dedicated Redis named `jago-staging-redis`
- Confirm no production database or Redis URL is reused

## 2. Configure secrets

- Populate secrets from `.do/staging.secrets.template.env`
- Use staging-only Firebase project and service account
- Use staging-only Maps/API keys where provider policy allows
- Use staging-only Razorpay/webhook configuration
- Set `ALERT_WEBHOOK_URL` to staging-only alert channel
- Set staging admin contact and reset keys

## 3. Runtime isolation

- Set `APP_BASE_URL=https://staging.jagopro.org`
- Set `SOCKET_ALLOWED_ORIGINS=https://staging.jagopro.org`
- Set `APP_ENV=staging`
- Verify runtime config changes in staging do not alter production behavior
- Verify staging webhooks point only to staging receivers

## 4. Deployment

- Create the Postgres cluster first if it does not already exist
- Create the Redis cluster first if it does not already exist
- Run `doctl apps create --spec .do/app.staging.yaml` for first deploy
- Run `doctl apps update <app-id> --spec .do/app.staging.yaml` for subsequent deploys
- Wait for deploy to complete
- Record deployment id, timestamp, and source commit

## 5. Baseline validation

- `GET /api/health`
- `GET /api/ops/ready` with `x-ops-key`
- `GET /api/ops/metrics` with `x-ops-key`
- Verify Redis adapter connects or degrades visibly
- Verify admin auth returns `401` when unauthorized
- Verify webhook endpoints return controlled failures on invalid signatures

## 6. Evidence capture

- Run `npm run ops:staging-evidence -- --base-url=https://staging.jagopro.org --ops-key=<value>`
- Save staging screenshots for:
  - health probe success
  - metrics snapshot
  - deployment details
  - alert delivery
  - reconnect behavior

## 7. Exit criteria

- Staging app healthy
- Dedicated Postgres and Redis confirmed
- Ops endpoints return valid snapshots
- Runtime config isolated
- Evidence archived under `docs/audit/`
