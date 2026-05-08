# JAGO Staging Environment Inventory

## Application

- App name: `jago-staging`
- Source branch: `release/preprod-hardening-2026-05-08-recovered`
- Region: `blr`
- Expected base URL: `https://staging.jagopro.org`
- Expected socket origin: `https://staging.jagopro.org`

## Managed services

- PostgreSQL: `jago-staging-postgres`
- Redis: `jago-staging-redis`

## External integrations

- Firebase project: `TODO`
- Maps key owner/project: `TODO`
- Razorpay account or test-mode profile: `TODO`
- Alerting channel/webhook target: `TODO`
- Webhook receiver base URL: `TODO`

## Admin and operations

- Staging admin email: `TODO`
- Staging admin phone: `TODO`
- OPS API key owner: `TODO`
- Credential rotation owner: `TODO`

## Runtime isolation assertions

- No production `DATABASE_URL`
- No production `REDIS_URL`
- No production alert webhook
- No production admin credentials
- No production webhook receivers
- No production Firebase service account

## Evidence references

- Deployment record: `TODO`
- Health capture: `TODO`
- Ready capture: `TODO`
- Metrics capture: `TODO`
- Redis drill record: `TODO`
- Device validation record: `TODO`
