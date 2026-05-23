import IORedis from "ioredis";

let redisClient: IORedis | null = null;
let redisError: string | null = null;

export function getLastRedisError(): string | null {
  return redisError;
}

export async function getRedisClient(): Promise<IORedis | null> {
  const redisUrl = (process.env.REDIS_URL || "").trim();
  if (!redisUrl) {
    redisError = "REDIS_URL missing";
    return null;
  }

  if (!redisClient) {
    redisClient = new IORedis(redisUrl, {
      lazyConnect: true,
      enableOfflineQueue: false,
      maxRetriesPerRequest: 2,
      retryStrategy: (times) => Math.min(times * 250, 3000),
      reconnectOnError: () => true,
      keepAlive: 15000,
    });
    redisClient.on("error", (error) => {
      redisError = error.message;
      console.error(`[REDIS] error=${error.message}`);
    });
    redisClient.on("ready", () => {
      redisError = null;
      console.log("[REDIS] client ready");
    });
  }

  if (redisClient.status === "end") {
    redisClient = null;
    return getRedisClient();
  }

  if (redisClient.status !== "ready") {
    await redisClient.connect().catch((error) => {
      redisError = error?.message || "redis_connect_failed";
    });
  }

  return redisClient.status === "ready" ? redisClient : null;
}

export async function assertRedisReady(): Promise<void> {
  const client = await getRedisClient();
  if (!client) throw new Error(getLastRedisError() || "redis_unavailable");
  const pong = await client.ping();
  if (pong !== "PONG") throw new Error(`redis_ping_failed:${pong}`);
}

export async function withRedisLock<T>(
  key: string,
  ttlMs: number,
  fn: () => Promise<T>,
): Promise<T> {
  const client = await getRedisClient();
  if (!client) throw new Error("redis_lock_unavailable");
  const token = `${process.pid}:${Date.now()}:${Math.random().toString(36).slice(2)}`;
  const acquired = await client.set(key, token, "PX", ttlMs, "NX");
  if (acquired !== "OK") throw new Error("redis_lock_busy");
  try {
    return await fn();
  } finally {
    const current = await client.get(key).catch(() => null);
    if (current === token) {
      await client.del(key).catch(() => undefined);
    }
  }
}
