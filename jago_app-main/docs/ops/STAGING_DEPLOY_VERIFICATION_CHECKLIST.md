# JAGO Staging Deploy Verification Checklist

## Deployment metadata

- [ ] deployment id captured
- [ ] deploy timestamp captured
- [ ] source commit captured
- [ ] branch captured

## Infrastructure verification

- [ ] app name is `jago-staging`
- [ ] PostgreSQL resource is isolated
- [ ] Redis/Valkey resource is isolated
- [ ] alert webhook target is staging-only
- [ ] Firebase config is staging-only

## Endpoint checks

- [ ] `/api/health` returns `200`
- [ ] `/api/ops/ready` returns `200`
- [ ] `/api/ops/metrics` returns `200`
- [ ] `/api/health/env` shows required keys configured
- [ ] `/api/health/maps` resolves correctly for staging config

## Socket and runtime checks

- [ ] socket connection succeeds from staging web/admin
- [ ] `ops.socket.connectedDrivers` visible when driver connects
- [ ] `ops.redis.status` visible in ready/metrics payload
- [ ] runtime config publish increments counters in ops snapshot
- [ ] invalid ops auth returns `401`

## Evidence capture

- [ ] health JSON saved
- [ ] ready JSON saved
- [ ] metrics JSON saved
- [ ] deployment screenshot saved
- [ ] runtime config propagation timing saved
- [ ] monitoring alert screenshot saved

## Release blockers

- [ ] physical device validation complete
- [ ] Redis outage drill complete
- [ ] alert delivery proved
- [ ] rollback proof archived
