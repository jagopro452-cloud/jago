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
- Staging App Platform service exists: `jago-staging`
- Staging app id: `c628b4a3-e535-4450-87f1-35c9164b28a3`
- Staging ingress exists and responds at `jago-staging-ljuq3.ondigitalocean.app`
- Isolated staging Postgres exists: `jago-staging-postgres`
- Staging Postgres id: `9c736c05-d4a8-4125-bdc5-c5e26b9805dd`
- Isolated staging cache exists: `jago-staging-redis`
- Staging cache id: `5aaee7bd-ea75-4ba1-9063-fb3538d25b47`
- Staging cache engine is `valkey`
- No checked-in staging app spec or `.env.staging.example` was present in this branch before this pass
- No local `.env` file was present in the clean recovered worktree before staging bring-up

Conclusion:

- A safe staging bring-up now exists with isolated managed data services and an auditable staging app definition
- Staging was brought up without reusing production database or Redis resources

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

- the live staging app now exists, but no outage window has been executed yet
- alert routing and third-party runtime secrets are still incomplete
- no real active client sessions are attached for continuity validation

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
- isolated staging infrastructure provisioning
- live staging deployment
- baseline live staging health proof
- protected live staging ops probe proof
- staging schema reconciliation for core background jobs

Blocked:

- real-device validation proof
- Redis outage drill proof
- live alert delivery proof
- runtime-config propagation proof
- rollback endpoint proof
- final operational evidence package with screenshots/log bundles

## Next required actions before production approval

1. Populate the remaining staging-only third-party secrets, especially Firebase, Maps, payment, and `ALERT_WEBHOOK_URL`.
2. Run the manual validation matrix in `docs/MANUAL_TESTING_GUIDE.md` on physical customer and driver devices.
3. Capture runtime-config publish and rollback behavior with timestamps and screenshots.
4. Capture `/api/health`, `/api/ops/ready`, and `/api/ops/metrics` before, during, and after a Redis outage drill.
5. Confirm alert delivery and attach screenshots and log correlation evidence.
6. Archive the resulting screenshots, timings, logs, and outage notes alongside this report.
