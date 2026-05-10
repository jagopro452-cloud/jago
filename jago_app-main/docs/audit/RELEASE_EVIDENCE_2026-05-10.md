# JAGO Release Evidence - 2026-05-10

## Release branch of record

- Branch: `release/preprod-hardening-2026-05-08-recovered`
- Worktree used for validation: `C:\tmp\jago-audit\jago_app-main`
- Reason: the unpacked `jago_app-main` workspace is an unborn local `main` and is not a valid release workspace

## Release discipline restoration

Confirmed:

- release branch already exists locally and tracks `origin/release/preprod-hardening-2026-05-08-recovered`
- release work is isolated to the clean worktree, not the unpacked non-repo workspace
- branch lineage is reproducible from the tracked release branch head
- validation was executed only inside the release worktree

Blocked until commit hygiene is finalized:

- tracked release changes are still in progress and not yet committed as a final production candidate

## Repository hygiene

Removed from release path:

- `flutter_apps/driver_app/android/hs_err_pid9536.log`
- `flutter_apps/driver_app/android/hs_err_pid10544.log`
- `flutter_apps/customer_app/build-logs/`
- `flutter_apps/customer_app/customer_test_output.txt`

Validated:

- `landing-corrupted.tsx` does not exist on the release branch
- production candidate typecheck is not blocked by dead broken landing-page artifacts

## Automated validation evidence

Passed on the release branch worktree:

- `npm run check`
- `npm run build`
- `npm test`

Observed:

- Vite production build completed successfully
- Vitest suite passed: 5 files, 171 tests
- automated gate was re-run after release-noise cleanup on `2026-05-10`

## Realtime operations evidence tooling

Improved:

- `scripts/ops/capture-staging-evidence.mjs` now supports optional admin bearer capture
- staging evidence can now include:
  - `/api/admin/system-health`
  - `/api/admin/ride-telemetry`
  - `/api/admin/vehicle-status`
- markdown summary is generated alongside JSON evidence

Runbook updated:

- `docs/ops/PRODUCTION_READINESS_RUNBOOK.md`
- `docs/ops/FINAL_REALTIME_OPERATIONS_RELEASE_GATE_2026-05.md`

## Still required before production approval

Not executed from this machine in this pass:

- authoritative staging evidence capture because `OPS_API_KEY` and `ADMIN_BEARER_TOKEN` are not present in the current shell
- physical driver device validation
- physical customer device validation
- reconnect storm drill
- Redis interruption drill
- runtime config propagation drill
- staging admin telemetry screenshot bundle
- production/staging secret separation confirmation in live control planes

## Current gate status

Passed:

- release branch identification
- clean validation worktree selection
- repository hygiene cleanup for crash/build noise
- deterministic typecheck
- deterministic web build
- unit test suite
- evidence-capture tooling for staging ops and admin telemetry

Pending:

- final clean git status for the production candidate commit set
- staging evidence capture against live staging URL
- real-device driver/customer proof
- admin telemetry screenshot proof during active failure drills
- Redis/runtime failure drills
- production environment separation checklist completion

## Approval rule

Production remains blocked until the evidence checklist in `docs/ops/FINAL_REALTIME_OPERATIONS_RELEASE_GATE_2026-05.md` is completed with timestamps, screenshots, and operator attribution.
