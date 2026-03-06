# JAGO Microservices Skeleton

This folder contains a non-breaking microservices scaffold for phased migration from the existing monolith.

## Services
- `gateway-service`: API gateway facade and compatibility routing
- `matching-service`: driver discovery and scoring service shell
- `trip-service`: trip state machine service shell
- `location-service`: driver location ingestion and lookup shell
- `ai-assistant-service`: voice intent and booking orchestration shell
- `shared`: shared contracts and utility helpers

## Upgraded capabilities
- Unified booking API (`/v1/bookings/estimate`, `/v1/bookings`) for:
	- bike rides
	- auto rides
	- car rides
	- parcel delivery
	- car sharing
	- intercity rides
	- hyperlocal delivery
- Dispatch API with ranking + acceptance SLA (`/internal/matching/request`)
- Trip state machine APIs with OTP-gated start/complete (`trip-service`)
- Real-time location streaming via SSE snapshots every 2-3s (`/internal/location/stream`)
- Demand zone feed for smart driver positioning (`/internal/location/demand-zones`)
- AI voice parsing with Telugu-English route extraction (`ai-assistant-service`)
- Fleet/microservice health aggregation (`/v1/health/all`)

## Quick Start
1. `cd microservices`
2. `npm install`
3. `docker compose -f docker-compose.microservices.yml up --build`

## Notes
- Existing app behavior remains unchanged unless traffic is explicitly routed to these services.
- `gateway-service` now supports unified booking and health aggregation while preserving compatibility proxies.
- Add feature flags in monolith (`server/config/featureFlags.ts`) before traffic migration.

## Scale-out guidance
- Replace in-memory stores in `matching-service`, `trip-service`, and `location-service` with Redis streams + Postgres persistence.
- Deploy multiple instances behind a load balancer and keep gateway stateless.
- Route mobile/web traffic to gateway first; keep monolith as fallback target during migration.
