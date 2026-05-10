# Final Realtime Operations Release Gate

Branch of record:

- `release/preprod-hardening-2026-05-08-recovered`

Release discipline rules:

- Do not validate or deploy from unpacked or unborn workspaces.
- Do not hot-patch `main`.
- Do not approve production with uncommitted crash logs, build logs, or generated test noise.
- Do not mark any reconnect, recovery, or admin-observability flow as passed without captured evidence.

## Automated gate

Required on the release branch worktree:

1. `npm run check`
2. `npm run build`
3. `npm test`
4. `npm run ops:staging-evidence -- --base-url=<staging-url> --ops-key=<ops-key> --admin-token=<admin-bearer-token>`

Archive:

- `docs/audit/evidence/<date>/staging-evidence.json`
- `docs/audit/evidence/<date>/staging-evidence.md`

## Driver real-device matrix

Run on a physical device and record timestamps/screenshots:

1. Accept ride
2. Lock phone
3. Internet off
4. Internet on
5. App minimize
6. Resume
7. Arrived
8. Waiting
9. OTP
10. Start trip
11. Destination
12. Complete

Evidence required:

- No forced logout
- No active-ride disappearance
- Trip screen restored after reconnect/background/resume
- Route continuity preserved
- Waiting timer preserved
- Completion delivered once

## Customer real-device matrix

1. Book ride
2. Observe nearby vehicle state
3. Observe live driver movement
4. Observe arrival
5. Observe waiting timer
6. Observe live ETA
7. Observe destination tracking
8. Observe completion

Evidence required:

- No blank tracking state during reconnect
- No duplicate tracking sessions
- No stale frozen vehicle marker after recovery
- Completion state matches backend/admin telemetry

## Admin telemetry matrix

During the same staged ride session confirm screenshots for:

- reconnect events
- stale tracking detection
- frozen ride alerts
- recovery audit trail
- waiting lifecycle continuity
- driver health transitions
- socket replay or reconnect indicators
- tracking freshness changes

Cross-check:

- customer app state
- driver app state
- `/api/admin/system-health`
- `/api/admin/ride-telemetry`
- `/api/ops/metrics`

## Failure drills

Document exact start/end times and outcomes for:

1. Redis interruption
2. Internet switching during active trip
3. Reconnect storm
4. Delayed GPS packet burst
5. App process restore
6. Runtime config change during active telemetry

Pass criteria:

- no ghost rides
- no duplicate ride sessions
- no duplicate waiting timers
- no lifecycle regression
- admin alerting reflects the fault
- recovery clears the unhealthy state after restoration

## Environment separation gate

Before production approval verify and record:

- production database is not staging
- production Redis is not staging
- Firebase project differs from staging
- Maps/API credentials differ from staging
- payment credentials differ from staging
- webhook targets differ from staging
- runtime config defaults are production-safe

## Approval rule

Production is blocked until every section above has:

- pass/fail outcome
- timestamp
- operator name
- screenshot/log reference
- rollback note if a step failed before later passing
