# JAGO Release Evidence - 2026-05-08

## Release branch

- Branch: `release/preprod-hardening-2026-05-08-recovered`
- Current validated tip at time of report: `d21bfe7`
- Recovery tag: `recovery-preprod-hardening-2026-05-08`
- Ops validation tag: `rc-validated-ops-2026-05-08`
- Final repo validation tag: `rc-validated-final-2026-05-08`

## Repository and build evidence

- Repository lineage restored to a clean release branch off `origin/main`
- Tracked crash dumps and diagnostic output artifacts removed from the release path
- `npm run check` passed on the recovered branch
- `npm run build` passed on the recovered branch
- Flutter dependency refresh completed for both apps
- Runtime config mutation endpoints now emit lightweight ops-state telemetry
- Readiness and metrics endpoints now include runtime ops and socket health snapshots

## Monitoring and observability evidence

Verified in code:

- Mobile Crashlytics wiring exists in both Flutter apps
- Backend alert webhook support exists through `ALERT_WEBHOOK_URL`
- Backend readiness endpoint: `/api/ops/ready`
- Backend metrics endpoint: `/api/ops/metrics`
- Redis adapter fallback now records degraded state in ops snapshot
- Socket auth failures and disconnect counts now surface in ops snapshot
- Runtime config publish/failure counters now surface in ops snapshot

Not yet proven live in staging:

- alert delivery to webhook target
- end-to-end log correlation during runtime failures
- Redis outage alert delivery
- socket disconnect alert delivery

## Staging infrastructure findings

Observed from operator tooling on this machine:

- DigitalOcean CLI access is available
- Managed Redis resource exists for JAGO: `jago-redis`
- No clearly named JAGO App Platform service was present in the visible app list
- No checked-in staging app spec or `.env.staging.example` was present in this branch
- No local `.env` file was present in the clean recovered worktree

Conclusion:

- A safe staging bring-up requires explicit staging app configuration and isolated secrets
- Provisioning should not proceed by guessing production values or reusing production credentials

## Device validation findings

Available Flutter targets on this machine:

- Windows desktop
- Chrome web
- Edge web

Unavailable from this machine at validation time:

- physical Android devices
- emulator evidence for the required phone runtime flows
- `adb` on `PATH`

Conclusion:

- The required real-device matrix for reconnect, background restore, killed-app recovery, active ride continuity, and poor-network behavior is still pending

## Redis failure drill status

Not executed in a live staging environment.

Reason:

- no confirmed JAGO staging backend was available
- no isolated staging database assignment was confirmed
- no safe staging runtime secrets were present locally

Evidence still required:

- outage start/end timestamps
- degraded mode screenshots or logs
- reconnect timing
- active ride continuity proof
- post-recovery propagation consistency proof

## Current release gate status

Passed:

- repository integrity
- release lineage
- deterministic typecheck/build
- release artifact cleanup
- baseline ops instrumentation

Blocked:

- staging stack provisioning proof
- real-device validation proof
- Redis outage drill proof
- live alert delivery proof
- final operational evidence package with screenshots/log bundles

## Next required actions before production approval

1. Provision or identify an isolated JAGO staging app, database, Redis, and webhook target.
2. Configure staging-only secrets for DB, Redis, Firebase, Maps, payment gateway, and `ALERT_WEBHOOK_URL`.
3. Run the manual validation matrix in `docs/MANUAL_TESTING_GUIDE.md` on physical customer and driver devices.
4. Capture `/api/health`, `/api/ops/ready`, and `/api/ops/metrics` before, during, and after a Redis outage drill.
5. Confirm alert delivery and attach screenshots/log correlation evidence.
6. Archive the resulting screenshots, timings, and logs alongside this report.
