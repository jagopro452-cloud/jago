type RedisHealth = {
  status: "unknown" | "connected" | "degraded";
  adapterMode: "unknown" | "redis" | "memory";
  lastChangeAt: string | null;
  lastError: string | null;
};

type SocketHealth = {
  authFailures: number;
  disconnects: number;
  lastDisconnectAt: string | null;
  lastDisconnectReason: string | null;
  lastDisconnectUserType: string | null;
};

type RuntimePublish = {
  publishCount: number;
  lastPublishAt: string | null;
  lastPublisher: string | null;
  lastKeys: string[];
  failureCount: number;
  lastFailureAt: string | null;
  lastFailureMessage: string | null;
};

type ApiHealth = {
  totalRequests: number;
  errorResponses: number;
  slowRequests: number;
  lastSlowRequest: null | {
    method: string;
    path: string;
    statusCode: number;
    durationMs: number;
    at: string;
  };
};

const redisHealth: RedisHealth = {
  status: "unknown",
  adapterMode: "unknown",
  lastChangeAt: null,
  lastError: null,
};

const socketHealth: SocketHealth = {
  authFailures: 0,
  disconnects: 0,
  lastDisconnectAt: null,
  lastDisconnectReason: null,
  lastDisconnectUserType: null,
};

const runtimePublish: RuntimePublish = {
  publishCount: 0,
  lastPublishAt: null,
  lastPublisher: null,
  lastKeys: [],
  failureCount: 0,
  lastFailureAt: null,
  lastFailureMessage: null,
};

const apiHealth: ApiHealth = {
  totalRequests: 0,
  errorResponses: 0,
  slowRequests: 0,
  lastSlowRequest: null,
};

const SLOW_REQUEST_MS = 1500;

function nowIso() {
  return new Date().toISOString();
}

export function noteRedisHealthy(adapterMode: RedisHealth["adapterMode"]) {
  redisHealth.status = "connected";
  redisHealth.adapterMode = adapterMode;
  redisHealth.lastChangeAt = nowIso();
  redisHealth.lastError = null;
}

export function noteRedisDegraded(message: string, adapterMode: RedisHealth["adapterMode"] = "memory") {
  redisHealth.status = "degraded";
  redisHealth.adapterMode = adapterMode;
  redisHealth.lastChangeAt = nowIso();
  redisHealth.lastError = message;
}

export function noteSocketAuthFailure() {
  socketHealth.authFailures += 1;
}

export function noteSocketDisconnect(reason: string, userType: string) {
  socketHealth.disconnects += 1;
  socketHealth.lastDisconnectAt = nowIso();
  socketHealth.lastDisconnectReason = reason;
  socketHealth.lastDisconnectUserType = userType;
}

export function noteRuntimeConfigPublish(keys: string[], publisher?: string | null) {
  runtimePublish.publishCount += 1;
  runtimePublish.lastPublishAt = nowIso();
  runtimePublish.lastPublisher = publisher || null;
  runtimePublish.lastKeys = keys.slice(0, 50);
}

export function noteRuntimeConfigFailure(message: string, publisher?: string | null) {
  runtimePublish.failureCount += 1;
  runtimePublish.lastFailureAt = nowIso();
  runtimePublish.lastFailureMessage = message;
  if (publisher) {
    runtimePublish.lastPublisher = publisher;
  }
}

export function recordApiRequest(method: string, path: string, statusCode: number, durationMs: number) {
  apiHealth.totalRequests += 1;
  if (statusCode >= 500) {
    apiHealth.errorResponses += 1;
  }
  if (durationMs >= SLOW_REQUEST_MS) {
    apiHealth.slowRequests += 1;
    apiHealth.lastSlowRequest = {
      method,
      path,
      statusCode,
      durationMs,
      at: nowIso(),
    };
  }
}

export function getOpsSnapshot() {
  return {
    redis: { ...redisHealth },
    socket: { ...socketHealth },
    runtimeConfig: { ...runtimePublish },
    api: {
      ...apiHealth,
      slowThresholdMs: SLOW_REQUEST_MS,
    },
  };
}
