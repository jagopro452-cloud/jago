# JAGO Staging Secrets Inventory Template

Use this file as an audit worksheet only. Do not paste live secret values into git.

| Secret Key | Required | Source System | Rotation Owner | Last Rotated | Notes |
|---|---|---|---|---|---|
| `DATABASE_URL` | Yes | Managed Postgres | TODO | TODO | Must point only to `jago-staging-postgres` |
| `REDIS_URL` | Yes | Managed Redis | TODO | TODO | Must point only to `jago-staging-redis` |
| `ADMIN_EMAIL` | Yes | Identity/Admin | TODO | TODO | Staging-only admin |
| `ADMIN_PASSWORD` | Yes | Identity/Admin | TODO | TODO | Do not reuse production |
| `ADMIN_PHONE` | Recommended | Identity/Admin | TODO | TODO | Required when 2FA is enabled |
| `ADMIN_RESET_KEY` | Yes | Identity/Admin | TODO | TODO | Staging-only reset scope |
| `OPS_API_KEY` | Yes | Ops | TODO | TODO | Used for `/api/ops/*` |
| `ALERT_WEBHOOK_URL` | Yes | Alerting | TODO | TODO | Must route to staging alert channel |
| `GOOGLE_MAPS_API_KEY` | Yes | Google Cloud | TODO | TODO | Staging restrictions preferred |
| `FIREBASE_SERVICE_ACCOUNT_KEY` | Yes | Firebase | TODO | TODO | Use staging Firebase project |
| `FIREBASE_WEB_API_KEY` | Yes | Firebase | TODO | TODO | Use staging Firebase project |
| `RAZORPAY_KEY_ID` | Optional | Razorpay | TODO | TODO | Use test/staging mode |
| `RAZORPAY_KEY_SECRET` | Optional | Razorpay | TODO | TODO | Use test/staging mode |
| `RAZORPAY_WEBHOOK_SECRET` | Optional | Razorpay | TODO | TODO | Staging webhook target only |
| `TWO_FACTOR_API_KEY` | Optional | OTP provider | TODO | TODO | Staging quota |
| `ANTHROPIC_API_KEY` | Optional | Anthropic | TODO | TODO | Only if staging AI flows are required |
