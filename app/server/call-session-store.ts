import { getRedisClient } from "./redis";

export type ActiveCallSession = {
  sessionId: string;
  tripId: string;
  callerId: string;
  targetId: string;
  startedAt: number;
  connectedAt?: number;
  mode: "ride" | "support";
};

const CALL_TTL_SECONDS = 20 * 60;
const SUPPORT_CALL_TARGET = "__admin_support__";

const sessionKey = (sessionId: string) => `call_session:${sessionId}`;
const userSessionsKey = (userId: string) => `call_user:${userId}`;

const localFallback = new Map<string, ActiveCallSession>();

function canUseLocalFallback(): boolean {
  return process.env.NODE_ENV !== "production";
}

function sessionUsers(session: ActiveCallSession): string[] {
  const users = [session.callerId];
  if (session.targetId && session.targetId !== SUPPORT_CALL_TARGET) {
    users.push(session.targetId);
  }
  return Array.from(new Set(users.filter(Boolean)));
}

async function getRedisOrThrow() {
  const redis = await getRedisClient();
  if (!redis) {
    if (canUseLocalFallback()) return null;
    throw new Error("call_session_redis_unavailable");
  }
  return redis;
}

export async function saveCallSession(session: ActiveCallSession): Promise<void> {
  const redis = await getRedisOrThrow();
  if (!redis) {
    localFallback.set(session.sessionId, session);
    return;
  }

  const tx = redis.multi().set(sessionKey(session.sessionId), JSON.stringify(session), "EX", CALL_TTL_SECONDS);
  for (const userId of sessionUsers(session)) {
    tx.sadd(userSessionsKey(userId), session.sessionId);
    tx.expire(userSessionsKey(userId), CALL_TTL_SECONDS);
  }
  await tx.exec();
}

export async function getCallSession(sessionId: string): Promise<ActiveCallSession | null> {
  const redis = await getRedisOrThrow();
  if (!redis) {
    return localFallback.get(sessionId) ?? null;
  }
  const raw = await redis.get(sessionKey(sessionId));
  if (!raw) return null;
  try {
    return JSON.parse(raw) as ActiveCallSession;
  } catch {
    await redis.del(sessionKey(sessionId)).catch(() => undefined);
    return null;
  }
}

export async function deleteCallSession(sessionId: string): Promise<ActiveCallSession | null> {
  const redis = await getRedisOrThrow();
  if (!redis) {
    const session = localFallback.get(sessionId) ?? null;
    localFallback.delete(sessionId);
    return session;
  }

  const session = await getCallSession(sessionId);
  const tx = redis.multi().del(sessionKey(sessionId));
  if (session) {
    for (const userId of sessionUsers(session)) {
      tx.srem(userSessionsKey(userId), sessionId);
    }
  }
  await tx.exec();
  return session;
}

export async function findCallSessionsForUser(userId: string): Promise<ActiveCallSession[]> {
  const redis = await getRedisOrThrow();
  if (!redis) {
    return Array.from(localFallback.values()).filter(
      (session) => session.callerId === userId || session.targetId === userId,
    );
  }

  const ids = await redis.smembers(userSessionsKey(userId));
  const sessions: ActiveCallSession[] = [];
  for (const id of ids) {
    const session = await getCallSession(id);
    if (!session) {
      await redis.srem(userSessionsKey(userId), id).catch(() => undefined);
      continue;
    }
    sessions.push(session);
  }
  return sessions;
}
