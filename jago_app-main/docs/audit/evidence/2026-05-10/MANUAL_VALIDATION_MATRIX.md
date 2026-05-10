# Manual Validation Matrix

Use this file for the final staging-backed evidence round on:

- Branch: `release/preprod-hardening-2026-05-08-recovered`
- Worktree: `C:\tmp\jago-audit\jago_app-main`

## Session metadata

- Operator:
- Staging base URL:
- Start time:
- End time:
- Driver device:
- Customer device:
- Admin operator:

## Automated capture

- `npm run ops:staging-evidence -- --base-url=<staging-url> --ops-key=<ops-key> --admin-token=<admin-bearer-token>`
- Evidence path:
- Result:
- Notes:

## Driver real-device flow

| Step | Timestamp | Pass/Fail | Screenshot/Recording Ref | Notes |
| --- | --- | --- | --- | --- |
| Accept ride |  |  |  |  |
| Lock phone |  |  |  |  |
| Internet off |  |  |  |  |
| Internet on |  |  |  |  |
| App minimize |  |  |  |  |
| Resume |  |  |  |  |
| Arrived |  |  |  |  |
| Waiting |  |  |  |  |
| OTP |  |  |  |  |
| Start trip |  |  |  |  |
| Destination |  |  |  |  |
| Complete |  |  |  |  |

## Customer real-device flow

| Step | Timestamp | Pass/Fail | Screenshot/Recording Ref | Notes |
| --- | --- | --- | --- | --- |
| Book ride |  |  |  |  |
| Nearby vehicle movement |  |  |  |  |
| Live driver tracking |  |  |  |  |
| Arrival |  |  |  |  |
| Waiting timer |  |  |  |  |
| Live ETA |  |  |  |  |
| Destination tracking |  |  |  |  |
| Completion |  |  |  |  |

## Admin telemetry validation

| Signal | Timestamp | Pass/Fail | Screenshot Ref | Notes |
| --- | --- | --- | --- | --- |
| Reconnect event visible |  |  |  |  |
| Stale tracking alert visible |  |  |  |  |
| Ride recovery event visible |  |  |  |  |
| Frozen tracking warning visible |  |  |  |  |
| Waiting lifecycle continuity visible |  |  |  |  |
| Socket replay or reconnect indicator visible |  |  |  |  |
| Tracking freshness transition visible |  |  |  |  |

## Failure drills

| Drill | Start | End | Pass/Fail | Alert Ref | Notes |
| --- | --- | --- | --- | --- | --- |
| Redis interruption |  |  |  |  |  |
| Internet switching during active trip |  |  |  |  |  |
| Reconnect storm |  |  |  |  |  |
| Delayed GPS burst |  |  |  |  |  |
| App process restore |  |  |  |  |  |
| Runtime config change during active telemetry |  |  |  |  |  |

## Performance and battery checks

| Check | Timestamp | Pass/Fail | Evidence Ref | Notes |
| --- | --- | --- | --- | --- |
| GPS cadence stability |  |  |  |  |
| Battery consumption acceptable |  |  |  |  |
| Socket overhead acceptable |  |  |  |  |
| Map rerender frequency acceptable |  |  |  |  |
| Route refresh load acceptable |  |  |  |  |
| Tracking throughput stable |  |  |  |  |

## Environment separation gate

| Assertion | Pass/Fail | Evidence Ref | Notes |
| --- | --- | --- | --- |
| Firebase separation verified |  |  |  |
| Maps/API credentials verified |  |  |  |
| Production secrets verified |  |  |  |
| Redis isolation verified |  |  |  |
| Runtime-config defaults verified |  |  |  |
| Webhook/alert URLs verified |  |  |  |
| No staging URLs inside release APKs |  |  |  |

## Final outcome

- Production approval decision:
- Blocking issues:
- Rollback plan reference:
