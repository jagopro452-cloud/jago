import crypto from "crypto";
import { db as rawDb } from "../db";
import { sql as rawSql } from "drizzle-orm";

export type SessionContext = {
  deviceId: string;
  ipAddress?: string | null;
  userAgent?: string | null;
};

export async function findActiveSessionByUser(userId: string) {
  const result = await rawDb.execute(rawSql`
    SELECT id, user_id, token, device_id, expires_at, last_active_at
    FROM sessions
    WHERE user_id=${userId}::uuid
      AND revoked=false
      AND expires_at > NOW()
    ORDER BY created_at DESC
    LIMIT 1
  `);
  return (result.rows[0] as any) || null;
}

export async function createSessionRecord(
  userId: string,
  token: string,
  expiresAtIso: string,
  context: SessionContext,
) {
  const result = await rawDb.execute(rawSql`
    INSERT INTO sessions (user_id, token, device_id, ip_address, user_agent, expires_at, last_active_at)
    VALUES (
      ${userId}::uuid,
      ${token},
      ${context.deviceId},
      ${context.ipAddress || null},
      ${context.userAgent || null},
      ${expiresAtIso}::timestamp,
      NOW()
    )
    RETURNING id
  `);
  return String((result.rows[0] as any).id);
}

export async function revokeSessionsForUser(userId: string) {
  await rawDb.execute(rawSql`
    UPDATE sessions
    SET revoked=true, revoked_at=NOW()
    WHERE user_id=${userId}::uuid
      AND revoked=false
  `);
}

export async function revokeSessionByToken(token: string) {
  await rawDb.execute(rawSql`
    UPDATE sessions
    SET revoked=true, revoked_at=NOW()
    WHERE token=${token}
      AND revoked=false
  `);
}

export async function touchSession(token: string) {
  await rawDb.execute(rawSql`
    UPDATE sessions
    SET last_active_at=NOW()
    WHERE token=${token}
      AND revoked=false
  `).catch(() => undefined);
}

export async function findSessionByToken(token: string) {
  const result = await rawDb.execute(rawSql`
    SELECT s.id, s.user_id, s.device_id, s.expires_at, u.user_type
    FROM sessions s
    JOIN users u ON u.id = s.user_id
    WHERE s.token=${token}
      AND s.revoked=false
      AND s.expires_at > NOW()
      AND u.is_active=true
    LIMIT 1
  `);
  return (result.rows[0] as any) || null;
}

export async function createRefreshTokenRecord(
  userId: string,
  sessionId: string,
  token: string,
  expiresAtIso: string,
  context: SessionContext,
) {
  await rawDb.execute(rawSql`
    INSERT INTO refresh_tokens (user_id, session_id, token, device_id, ip_address, user_agent, expires_at, revoked)
    VALUES (
      ${userId}::uuid,
      ${sessionId}::uuid,
      ${token},
      ${context.deviceId},
      ${context.ipAddress || null},
      ${context.userAgent || null},
      ${expiresAtIso}::timestamp,
      false
    )
  `);
}

export async function findRefreshToken(token: string) {
  const result = await rawDb.execute(rawSql`
    SELECT rt.id, rt.user_id, rt.session_id, rt.token, rt.device_id, rt.expires_at, rt.revoked, u.is_active
    FROM refresh_tokens rt
    JOIN users u ON u.id = rt.user_id
    WHERE rt.token=${token}
    LIMIT 1
  `);
  return (result.rows[0] as any) || null;
}

export async function revokeRefreshToken(token: string, replacedByToken?: string | null) {
  await rawDb.execute(rawSql`
    UPDATE refresh_tokens
    SET revoked=true,
        revoked_at=NOW(),
        replaced_by_token=${replacedByToken || null}
    WHERE token=${token}
      AND revoked=false
  `);
}

export async function revokeRefreshTokensBySession(sessionId: string) {
  await rawDb.execute(rawSql`
    UPDATE refresh_tokens
    SET revoked=true, revoked_at=NOW()
    WHERE session_id=${sessionId}::uuid
      AND revoked=false
  `);
}

export async function revokeAllRefreshTokensForUser(userId: string) {
  await rawDb.execute(rawSql`
    UPDATE refresh_tokens
    SET revoked=true, revoked_at=NOW()
    WHERE user_id=${userId}::uuid
      AND revoked=false
  `);
}

export async function revokeUserAuthColumns(userId: string) {
  await rawDb.execute(rawSql`
    UPDATE users
    SET auth_token=NULL,
        auth_token_expires_at=NULL,
        refresh_token=NULL,
        refresh_token_expires_at=NULL
    WHERE id=${userId}::uuid
  `);
}

export async function syncLegacyUserAuthColumns(
  userId: string,
  accessToken: string,
  accessTokenExpiresAt: string,
  refreshToken: string,
  refreshTokenExpiresAt: string,
) {
  await rawDb.execute(rawSql`
    UPDATE users
    SET auth_token=${accessToken},
        auth_token_expires_at=${accessTokenExpiresAt}::timestamp,
        refresh_token=${refreshToken},
        refresh_token_expires_at=${refreshTokenExpiresAt}::timestamp
    WHERE id=${userId}::uuid
  `);
}

export async function countDistinctOtpPhonesForDevice(
  deviceId: string,
  sinceMinutes: number,
) {
  const result = await rawDb.execute(rawSql`
    SELECT COUNT(DISTINCT phone)::int AS count
    FROM otp_request_events
    WHERE device_id=${deviceId}
      AND created_at > NOW() - (${sinceMinutes} * INTERVAL '1 minute')
      AND event_type='send'
  `);
  return Number((result.rows[0] as any)?.count || 0);
}

export async function insertOtpRequestEvent(input: {
  phone: string;
  countryCode: string;
  deviceId?: string | null;
  ipAddress?: string | null;
  userAgent?: string | null;
  userType: string;
  eventType: "send" | "verify";
  outcome: string;
}) {
  await rawDb.execute(rawSql`
    INSERT INTO otp_request_events (phone, country_code, device_id, ip_address, user_agent, user_type, event_type, outcome)
    VALUES (
      ${input.phone},
      ${input.countryCode},
      ${input.deviceId || null},
      ${input.ipAddress || null},
      ${input.userAgent || null},
      ${input.userType},
      ${input.eventType},
      ${input.outcome}
    )
  `).catch(() => undefined);
}

export function createOpaqueToken(userId: string, bytes: number) {
  return `${userId}:${crypto.randomBytes(bytes).toString("hex")}`;
}
