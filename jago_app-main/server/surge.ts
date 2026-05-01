/**
 * Real-time surge pricing engine.
 *
 * Calculates demand/supply ratio for a given location and returns a surge multiplier.
 *
 * Demand  = active 'searching' trip_requests within 2km in the last 5 min
 * Supply  = online drivers within 2km (fresh location within last 3 min)
 * Ratio   = demand / max(supply, 1)
 *
 * Surge tiers:
 *   ratio < 1.5  → 1.0x (no surge)
 *   ratio 1.5–2  → 1.2x
 *   ratio 2–3    → 1.5x
 *   ratio > 3    → 2.0x (capped)
 *
 * Cache: in-memory grid cell (~1km) with 15s TTL.
 * Falls back gracefully — never blocks booking.
 */

import { db as rawDb } from "./db";
import { sql as rawSql } from "drizzle-orm";

const SURGE_CACHE_TTL_MS = 15_000;
const SURGE_RADIUS_KM = 2;

const SURGE_TIERS: { minRatio: number; multiplier: number; label: string }[] = [
  { minRatio: 3.0, multiplier: 2.0, label: "very_high" },
  { minRatio: 2.0, multiplier: 1.5, label: "high" },
  { minRatio: 1.5, multiplier: 1.2, label: "moderate" },
  { minRatio: 0,   multiplier: 1.0, label: "normal" },
];

export interface SurgeInfo {
  multiplier: number;
  label: string;
  demandCount: number;
  supplyCount: number;
  ratio: number;
  source: "realtime" | "default";
  cachedAt: number;
}

// Grid-cell cache: ~1km resolution (2 decimal places ≈ 1.1km)
const surgeCache = new Map<string, SurgeInfo>();

function gridKey(lat: number, lng: number): string {
  return `${lat.toFixed(2)},${lng.toFixed(2)}`;
}

/** Returns surge multiplier (e.g. 1.0, 1.2, 1.5, 2.0) for a pickup location. */
export async function getSurgeFactor(lat: number, lng: number): Promise<number> {
  return (await getSurgeInfo(lat, lng)).multiplier;
}

/** Returns full surge info object including demand/supply stats for customer display. */
export async function getSurgeInfo(lat: number, lng: number): Promise<SurgeInfo> {
  const key = gridKey(lat, lng);
  const cached = surgeCache.get(key);
  if (cached && Date.now() - cached.cachedAt < SURGE_CACHE_TTL_MS) return cached;

  try {
    // Bounding-box approximation (fast, no PostGIS needed)
    // 1 degree latitude ≈ 111km; longitude varies by cos(lat)
    const latDelta = SURGE_RADIUS_KM / 111;
    const lngDelta = SURGE_RADIUS_KM / (111 * Math.cos(lat * Math.PI / 180));

    const [demandR, supplyR] = await Promise.all([
      rawDb.execute(rawSql`
        SELECT COUNT(*) AS cnt FROM trip_requests
        WHERE current_status = 'searching'
          AND pickup_lat BETWEEN ${lat - latDelta} AND ${lat + latDelta}
          AND pickup_lng BETWEEN ${lng - lngDelta} AND ${lng + lngDelta}
          AND created_at > NOW() - INTERVAL '5 minutes'
      `),
      rawDb.execute(rawSql`
        SELECT COUNT(*) AS cnt FROM driver_locations
        WHERE is_online = true
          AND lat BETWEEN ${lat - latDelta} AND ${lat + latDelta}
          AND lng BETWEEN ${lng - lngDelta} AND ${lng + lngDelta}
          AND updated_at > NOW() - INTERVAL '3 minutes'
      `),
    ]);

    const demand = parseInt((demandR.rows[0] as any)?.cnt ?? "0");
    const supply = parseInt((supplyR.rows[0] as any)?.cnt ?? "0");
    const ratio = demand / Math.max(supply, 1);

    // Pick the highest-tier that applies
    const tier = SURGE_TIERS.find(t => ratio >= t.minRatio) ?? SURGE_TIERS[SURGE_TIERS.length - 1];

    const info: SurgeInfo = {
      multiplier: tier.multiplier,
      label: tier.label,
      demandCount: demand,
      supplyCount: supply,
      ratio: Math.round(ratio * 100) / 100,
      source: "realtime",
      cachedAt: Date.now(),
    };
    surgeCache.set(key, info);
    return info;
  } catch {
    const info: SurgeInfo = {
      multiplier: 1.0, label: "normal",
      demandCount: 0, supplyCount: 0, ratio: 0,
      source: "default", cachedAt: Date.now(),
    };
    surgeCache.set(key, info);
    return info;
  }
}

/** Force-refresh surge for an area (call after a new booking is placed). */
export function invalidateSurgeCache(lat: number, lng: number): void {
  const key = gridKey(lat, lng);
  surgeCache.delete(key);
}

// Prune stale cache entries every 5 minutes
setInterval(() => {
  const now = Date.now();
  Array.from(surgeCache.entries()).forEach(([key, info]) => {
    if (now - info.cachedAt > SURGE_CACHE_TTL_MS * 8) surgeCache.delete(key);
  });
}, 5 * 60 * 1000);
