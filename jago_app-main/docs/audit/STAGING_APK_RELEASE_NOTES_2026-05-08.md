# JAGO Staging APK Release Notes - 2026-05-08

## Label

FOR STAGING VALIDATION ONLY

NOT FINAL PRODUCTION RELEASE

## Source

- Branch: `release/preprod-hardening-2026-05-08-recovered`
- Build source base commit: `a56b38d`
- Build timestamp: `2026-05-08 15:57:46 +05:30`
- Staging backend URL: `https://jago-staging-ljuq3.ondigitalocean.app`
- Runtime governance baseline: recovered release candidate with staging ops telemetry and runtime-config hardening

## APKs

- Customer staging release APK: [jago-customer-staging-release-2026-05-08.apk](C:\tmp\jago-audit\jago_app-main\artifacts\staging-apks\2026-05-08\jago-customer-staging-release-2026-05-08.apk)
- Customer version: `1.0.59` (`versionCode 59`)
- Customer SHA256: `D0C339A09044597F5D0C0B3CBAC29D854A6E3507B1C11999FC1A6AF074BC1552`
- Driver staging release APK: [jago-driver-staging-release-2026-05-08.apk](C:\tmp\jago-audit\jago_app-main\artifacts\staging-apks\2026-05-08\jago-driver-staging-release-2026-05-08.apk)
- Driver version: `1.0.60` (`versionCode 60`)
- Driver SHA256: `14C7C6141A4871A641BD4F15A3FF5D665ACE9CE3FDA8D2D7A31DE62616F88CF6`

## Build Profile

- Android `release` mode
- Flutter release APK build with tree-shaken icons and resource shrinking enabled
- Backend and socket target pinned at compile time to the staging ingress
- Runtime-config endpoints resolved through the staging backend base URL
- Android Google Maps API key injected at build time instead of hardcoded in manifest

## Staging Safety Verification

- Packaged APKs contain the staging base URL string
- No `localhost` or `192.168.1.6:5000` backend string was found in the packaged APK verification scan
- No production API base URL match was found in the packaged APK verification scan
- Production-hosted static asset URLs still exist in app content and copy, but they are not the compiled API base URL

## Known Operational Limitations

- Android release builds currently fall back to debug signing because `key.properties` is not present in either Flutter app
- Firebase Android config is still the currently checked-in `jagopro-9aa9b` project; no dedicated staging Firebase config is checked into this branch yet
- Build output still emits Java 8 source/target deprecation warnings from Android dependencies and plugin toolchains
- Protected staging ops validation was proven on the backend, but real-device runtime propagation and reconnect evidence still need to be captured separately
- These APKs are prepared for staging reconnect, runtime propagation, ride continuity, and Redis recovery testing only

## Recommended Device Validation Focus

- Customer login and OTP flow against staging backend
- Driver login and online/offline socket reconnection
- Runtime-config propagation while apps are foregrounded, backgrounded, and relaunched
- Active ride continuity across network loss and app restore
- Parcel and pool runtime toggle visibility
- Staging health reachability through live app flows

## Artifact Location

- Packaged artifact folder: [artifacts/staging-apks/2026-05-08](C:\tmp\jago-audit\jago_app-main\artifacts\staging-apks\2026-05-08)
