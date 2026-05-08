# JAGO Staging Environment Inventory

## Application

- App name: `jago-staging`
- Source branch: `release/preprod-hardening-2026-05-08-recovered`
- App id: `c628b4a3-e535-4450-87f1-35c9164b28a3`
- Region: `blr1`
- Current bootstrap base URL: `https://jago-staging-ljuq3.ondigitalocean.app`
- Expected final base URL: `https://staging.jagopro.org`
- Current socket origin: bootstrap/default ingress
- Expected final socket origin: `https://staging.jagopro.org`

## Managed services

- PostgreSQL: `jago-staging-postgres`
- PostgreSQL id: `9c736c05-d4a8-4125-bdc5-c5e26b9805dd`
- Redis/Valkey: `jago-staging-redis`
- Redis/Valkey id: `5aaee7bd-ea75-4ba1-9063-fb3538d25b47`

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

- Deployment record: `docs/audit/STAGING_STANDARDIZATION_2026-05-08.md`
- Health capture: `docs/audit/evidence/2026-05-08-staging-postreconcile/staging-evidence.json`
- Ready capture: `docs/audit/evidence/2026-05-08-staging-postreconcile/staging-evidence.json`
- Metrics capture: `docs/audit/evidence/2026-05-08-staging-postreconcile/staging-evidence.json`
- Redis drill record: `TODO`
- Device validation record: `TODO`
