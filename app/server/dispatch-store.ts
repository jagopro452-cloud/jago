import { getRedisClient, withRedisLock } from "./redis";

export type DispatchPhase =
  | "searching"
  | "offered"
  | "accepted"
  | "cancelled"
  | "no_drivers"
  | "expired";

export interface RedisDispatchSession {
  tripId: string;
  customerId: string;
  pickupLat: number;
  pickupLng: number;
  vehicleCategoryId: string | null;
  parcelVehicleCategory: string | null;
  serviceType: string;
  phase: DispatchPhase;
  radiusIndex: number;
  queueIndex: number;
  currentOfferedDriverId: string | null;
  notifiedDriverIds: string[];
  rejectedDriverIds: string[];
  retryCount: number;
  createdAt: number;
  updatedAt: number;
  expiresAt: number;
  tripMeta: Record<string, unknown>;
}

export interface RedisDispatchOffer {
  tripId: string;
  driverId: string;
  payload: Record<string, unknown>;
  status: "offered" | "accepted" | "rejected" | "expired" | "cancelled";
  createdAt: number;
  expiresAt: number;
}

const ACTIVE_SET_KEY = "dispatch:active";
const SESSION_TTL_SECONDS = 30 * 60;

export const dispatchSessionKey = (tripId: string) => `dispatch:${tripId}`;
export const dispatchOfferKey = (tripId: string, driverId: string) => `dispatch_offer:${tripId}:${driverId}`;
export const dispatchLockKey = (tripId: string) => `dispatch_lock:${tripId}`;

export async function saveDispatchSession(session: RedisDispatchSession): Promise<void> {
  const redis = await getRedisClient();
  if (!redis) throw new Error("redis_unavailable");
  const payload = JSON.stringify({ ...session, updatedAt: Date.now() });
  await redis
    .multi()
    .set(dispatchSessionKey(session.tripId), payload, "EX", SESSION_TTL_SECONDS)
    .sadd(ACTIVE_SET_KEY, session.tripId)
    .exec();
}

export async function getDispatchSession(tripId: string): Promise<RedisDispatchSession | null> {
  const redis = await getRedisClient();
  if (!redis) return null;
  const raw = await redis.get(dispatchSessionKey(tripId));
  if (!raw) return null;
  try {
    return JSON.parse(raw) as RedisDispatchSession;
  } catch {
    return null;
  }
}

export async function saveDispatchOffer(offer: RedisDispatchOffer): Promise<void> {
  const redis = await getRedisClient();
  if (!redis) throw new Error("redis_unavailable");
  const ttlSeconds = Math.max(5, Math.ceil((offer.expiresAt - Date.now()) / 1000) + 60);
  await redis.set(dispatchOfferKey(offer.tripId, offer.driverId), JSON.stringify(offer), "EX", ttlSeconds);
}

export async function markDispatchOffer(
  tripId: string,
  driverId: string,
  status: RedisDispatchOffer["status"],
): Promise<void> {
  const redis = await getRedisClient();
  if (!redis) return;
  const key = dispatchOfferKey(tripId, driverId);
  const raw = await redis.get(key);
  if (!raw) return;
  try {
    const parsed = JSON.parse(raw) as RedisDispatchOffer;
    parsed.status = status;
    await redis.set(key, JSON.stringify(parsed), "EX", Math.max(60, Math.ceil((parsed.expiresAt - Date.now()) / 1000) + 60));
  } catch {
    await redis.del(key).catch(() => undefined);
  }
}

export async function clearDispatchOffer(tripId: string, driverId?: string): Promise<void> {
  const redis = await getRedisClient();
  if (!redis) return;
  if (driverId) {
    await redis.del(dispatchOfferKey(tripId, driverId));
    return;
  }
  const keys = await redis.keys(dispatchOfferKey(tripId, "*"));
  if (keys.length) await redis.del(...keys);
}

export async function clearDispatchSession(tripId: string): Promise<void> {
  const redis = await getRedisClient();
  if (!redis) return;
  const offerKeys = await redis.keys(dispatchOfferKey(tripId, "*"));
  const keys = [dispatchSessionKey(tripId), ...offerKeys];
  await redis.multi().srem(ACTIVE_SET_KEY, tripId).del(...keys).exec();
}

export async function getActiveDispatchTripIds(): Promise<string[]> {
  const redis = await getRedisClient();
  if (!redis) return [];
  const ids = await redis.smembers(ACTIVE_SET_KEY);
  if (!ids.length) return [];
  const live: string[] = [];
  for (const tripId of ids) {
    if (await redis.exists(dispatchSessionKey(tripId))) live.push(tripId);
    else await redis.srem(ACTIVE_SET_KEY, tripId).catch(() => undefined);
  }
  return live;
}

export function runWithDispatchLock<T>(tripId: string, fn: () => Promise<T>): Promise<T> {
  return withRedisLock(dispatchLockKey(tripId), 30_000, fn);
}
