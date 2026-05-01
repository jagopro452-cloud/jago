/**
 * Autonomous monitoring, alerting, and auto-action engine.
 *
 * Every 60 seconds:
 *   1. getDashboardMetrics() — parallel DB queries for all system vitals
 *   2. evaluateRules()       — compare metrics against thresholds
 *   3. fireAlerts()          — send webhook/SMS for new violations (15-min cooldown)
 *   4. executeActions()      — apply automatic corrections
 *   5. evaluateRecovery()    — reverse actions when conditions clear
 *
 * Auto-actions:
 *   surge_increase    — bump zone surge_factor +0.3 (cap 2.0) when search queue backs up
 *   surge_restore     — reset surge_factor to 1.0 when queue clears
 *   booking_pause     — set platform_services = paused when payment failures spike
 *   booking_restore   — re-enable booking when failures drop
 *
 * Alert deduplication: same rule does not re-fire within ALERT_COOLDOWN_MS.
 * Every alert + action is written to system_logs for the admin audit trail.
 */

import { db as rawDb } from "./db";
import { sql as rawSql } from "drizzle-orm";
import { getApiErrorStats } from "./metrics";
import { sendOpsAlert } from "./observability";

export interface DashboardMetrics {
  // Auth
  otpFailLast1h: number;
  otpSendLast1h: number;
  loginSuccessRatePct: number;

  // Rides
  activeRides: number;
  searchingRides: number;
  completedToday: number;
  cancelledToday: number;
  rideCompletionRatePct: number;

  // Drivers
  onlineDrivers: number;

  // Payments
  pendingPayments: number;
  failedPayments: number;
  revenueToday: number;

  // System
  socketConnections: number;
  redisHealthy: boolean;
  apiErrorCount: number;
  apiErrorRatePct: number;

  // Fraud
  fraudFlagsToday: number;

  // Meta
  generatedAt: string;
  uptimeSeconds: number;
}

// ── Alert rules ───────────────────────────────────────────────────────────────

type AlertSeverity = "warning" | "critical";
type AutoActionId = "surge_increase" | "surge_restore" | "booking_pause" | "booking_restore" | null;

interface AlertRule {
  id: string;
  label: string;
  severity: AlertSeverity;
  check: (m: DashboardMetrics) => boolean;
  message: (m: DashboardMetrics) => string;
  action: AutoActionId;
  recoveryRule?: string; // id of the rule that reverses this action
}

const ALERT_RULES: AlertRule[] = [
  {
    id: "otp_fail_high",
    label: "OTP failures high",
    severity: "warning",
    check: m => m.otpFailLast1h > 10,
    message: m => `OTP failures: ${m.otpFailLast1h} in last 1h (threshold: 10)`,
    action: null,
  },
  {
    id: "searching_rides_high",
    label: "Searching rides backing up",
    severity: "critical",
    check: m => m.searchingRides > 5,
    message: m => `${m.searchingRides} rides searching — no drivers accepting. Surge increased.`,
    action: "surge_increase",
    recoveryRule: "searching_rides_clear",
  },
  {
    id: "searching_rides_clear",
    label: "Searching rides normalized",
    severity: "warning",
    check: m => m.searchingRides <= 2,
    message: () => "Searching queue cleared — surge restored to normal.",
    action: "surge_restore",
  },
  {
    id: "pending_payments_high",
    label: "Pending payments spike",
    severity: "warning",
    check: m => m.pendingPayments > 3,
    message: m => `${m.pendingPayments} pending payments — investigate payment gateway.`,
    action: null,
  },
  {
    id: "payment_failures_high",
    label: "Payment failures — booking paused",
    severity: "critical",
    check: m => m.failedPayments > 5,
    message: m => `${m.failedPayments} payment failures. New bookings paused automatically.`,
    action: "booking_pause",
    recoveryRule: "payment_failures_clear",
  },
  {
    id: "payment_failures_clear",
    label: "Payment failures cleared — booking restored",
    severity: "warning",
    check: m => m.failedPayments <= 1,
    message: () => "Payment failures resolved — booking re-enabled.",
    action: "booking_restore",
  },
  {
    id: "api_error_rate_high",
    label: "API error rate elevated",
    severity: "critical",
    check: m => m.apiErrorRatePct > 2,
    message: m => `API error rate: ${m.apiErrorRatePct}% (threshold: 2%). Check server logs.`,
    action: null,
  },
  {
    id: "no_online_drivers",
    label: "No drivers online with searching rides",
    severity: "critical",
    check: m => m.onlineDrivers === 0 && m.searchingRides > 0,
    message: m => `0 drivers online but ${m.searchingRides} rides searching. Surge increased.`,
    action: "surge_increase",
  },
  {
    id: "redis_down",
    label: "Redis unavailable",
    severity: "warning",
    check: m => !m.redisHealthy,
    message: () => "Redis is down — driver presence cache degraded to DB fallback.",
    action: null,
  },
];

const ALERT_COOLDOWN_MS = 15 * 60 * 1000; // 15 min between same alert

// ── Alert state ───────────────────────────────────────────────────────────────

interface AlertState {
  firing: boolean;
  lastFiredAt: number;
  fireCount: number;
}

const alertStates = new Map<string, AlertState>();

function getState(ruleId: string): AlertState {
  return alertStates.get(ruleId) ?? { firing: false, lastFiredAt: 0, fireCount: 0 };
}

// ── Dashboard metrics collector ───────────────────────────────────────────────

let cachedMetrics: DashboardMetrics | null = null;
let cacheExpiresAt = 0;
const METRICS_CACHE_MS = 30_000; // 30s cache — fresh enough for dashboard, not hammering DB

export async function getDashboardMetrics(forceRefresh = false): Promise<DashboardMetrics> {
  if (!forceRefresh && cachedMetrics && Date.now() < cacheExpiresAt) return cachedMetrics;

  const apiStats = getApiErrorStats();

  const [
    rideStatsR, otpR, paymentR, fraudR, driverR, socketCountR,
  ] = await Promise.all([
    // Ride stats — active, searching, today completed/cancelled
    rawDb.execute(rawSql`
      SELECT
        COUNT(*) FILTER (WHERE current_status IN ('accepted','driver_assigned','arrived','on_the_way')) AS active_rides,
        COUNT(*) FILTER (WHERE current_status = 'searching') AS searching_rides,
        COUNT(*) FILTER (WHERE current_status = 'completed' AND DATE(updated_at) = CURRENT_DATE) AS completed_today,
        COUNT(*) FILTER (WHERE current_status = 'cancelled'  AND DATE(updated_at) = CURRENT_DATE) AS cancelled_today,
        COALESCE(SUM(actual_fare) FILTER (WHERE current_status = 'completed' AND DATE(updated_at) = CURRENT_DATE), 0) AS revenue_today
      FROM trip_requests
    `).catch(() => ({ rows: [{}] })),

    // OTP fail count last 1h (logged by per-phone rate limiter in routes.ts)
    rawDb.execute(rawSql`
      SELECT
        COUNT(*) FILTER (WHERE tag = 'OTP_RATE_LIMIT') AS fail_count,
        COUNT(*) FILTER (WHERE tag IN ('OTP_SENT','OTP_RATE_LIMIT')) AS send_count
      FROM system_logs
      WHERE created_at > NOW() - INTERVAL '1 hour'
    `).catch(() => ({ rows: [{ fail_count: 0, send_count: 0 }] })),

    // Payment stats — pending + failed
    rawDb.execute(rawSql`
      SELECT
        COUNT(*) FILTER (WHERE payment_status IN ('pending','payment_pending')) AS pending_payments,
        COUNT(*) FILTER (WHERE payment_status = 'failed' AND DATE(updated_at) = CURRENT_DATE) AS failed_payments
      FROM trip_requests
      WHERE payment_method != 'cash'
    `).catch(() => ({ rows: [{ pending_payments: 0, failed_payments: 0 }] })),

    // Fraud flags today
    rawDb.execute(rawSql`
      SELECT COUNT(*) AS cnt FROM system_logs
      WHERE tag LIKE 'FRAUD_%' AND DATE(created_at) = CURRENT_DATE
    `).catch(() => ({ rows: [{ cnt: 0 }] })),

    // Online drivers
    rawDb.execute(rawSql`
      SELECT COUNT(*) AS cnt FROM driver_locations
      WHERE is_online = true AND updated_at > NOW() - INTERVAL '5 minutes'
    `).catch(() => ({ rows: [{ cnt: 0 }] })),

    // System logs error count last 1h (approximates API errors)
    rawDb.execute(rawSql`
      SELECT COUNT(*) AS cnt FROM system_logs
      WHERE level = 'error' AND created_at > NOW() - INTERVAL '1 hour'
    `).catch(() => ({ rows: [{ cnt: 0 }] })),
  ]);

  const rides = (rideStatsR.rows[0] as any) ?? {};
  const active = parseInt(rides.active_rides ?? "0");
  const searching = parseInt(rides.searching_rides ?? "0");
  const completed = parseInt(rides.completed_today ?? "0");
  const cancelled = parseInt(rides.cancelled_today ?? "0");
  const completionRate = (completed + cancelled) > 0
    ? Math.round((completed / (completed + cancelled)) * 100)
    : 100;

  const otp = (otpR.rows[0] as any) ?? {};
  const otpFail = parseInt(otp.fail_count ?? "0");
  const otpSend = parseInt(otp.send_count ?? "0");
  const loginSuccessRate = otpSend > 0
    ? Math.round(((otpSend - otpFail) / otpSend) * 100)
    : 100;

  const pay = (paymentR.rows[0] as any) ?? {};
  const fraud = (fraudR.rows[0] as any) ?? {};
  const drivers = (driverR.rows[0] as any) ?? {};
  const sysErrors = (socketCountR.rows[0] as any) ?? {};

  let socketConnections = 0;
  try {
    const { io } = await import("./socket");
    socketConnections = io?.sockets?.sockets?.size ?? 0;
  } catch { /* socket not initialised yet */ }

  const redisHealthy = await (async () => {
    try {
      const { default: IORedis } = await import("ioredis");
      const r = new IORedis(process.env.REDIS_URL || "redis://localhost:6379", {
        lazyConnect: true, enableOfflineQueue: false, maxRetriesPerRequest: 0,
        retryStrategy: () => null, connectTimeout: 2000,
      });
      r.on("error", () => { });
      await r.connect();
      await r.ping();
      r.disconnect();
      return true;
    } catch { return false; }
  })();

  const metrics: DashboardMetrics = {
    otpFailLast1h: otpFail,
    otpSendLast1h: otpSend,
    loginSuccessRatePct: loginSuccessRate,

    activeRides: active,
    searchingRides: searching,
    completedToday: completed,
    cancelledToday: cancelled,
    rideCompletionRatePct: completionRate,

    onlineDrivers: parseInt(drivers.cnt ?? "0"),

    pendingPayments: parseInt(pay.pending_payments ?? "0"),
    failedPayments: parseInt(pay.failed_payments ?? "0"),
    revenueToday: parseFloat(rides.revenue_today ?? "0"),

    socketConnections,
    redisHealthy,
    apiErrorCount: apiStats.errorCount + parseInt(sysErrors.cnt ?? "0"),
    apiErrorRatePct: apiStats.errorRatePct,

    fraudFlagsToday: parseInt(fraud.cnt ?? "0"),

    generatedAt: new Date().toISOString(),
    uptimeSeconds: Math.round(process.uptime()),
  };

  cachedMetrics = metrics;
  cacheExpiresAt = Date.now() + METRICS_CACHE_MS;
  return metrics;
}

// ── Auto-actions ──────────────────────────────────────────────────────────────

async function executeAction(actionId: AutoActionId, metrics: DashboardMetrics): Promise<void> {
  if (!actionId) return;

  try {
    switch (actionId) {
      case "surge_increase":
        await rawDb.execute(rawSql`
          UPDATE zones
          SET surge_factor = LEAST(2.0, COALESCE(surge_factor, 1.0) + 0.3)
          WHERE is_active = true AND surge_factor < 2.0
        `);
        await logEngineEvent("AUTO_ACTION", `surge_increase applied — searchingRides=${metrics.searchingRides}`);
        break;

      case "surge_restore":
        await rawDb.execute(rawSql`
          UPDATE zones SET surge_factor = 1.0 WHERE is_active = true AND surge_factor > 1.0
        `);
        await logEngineEvent("AUTO_ACTION", "surge_restore — zones reset to 1.0");
        break;

      case "booking_pause":
        await rawDb.execute(rawSql`
          UPDATE platform_services
          SET service_status = 'paused'
          WHERE service_key IN ('bike_ride','auto_ride','cab_ride','parcel')
            AND service_status = 'active'
        `).catch(() => { });
        await logEngineEvent("AUTO_ACTION", `booking_pause — failedPayments=${metrics.failedPayments}`);
        break;

      case "booking_restore":
        await rawDb.execute(rawSql`
          UPDATE platform_services
          SET service_status = 'active'
          WHERE service_key IN ('bike_ride','auto_ride','cab_ride','parcel')
            AND service_status = 'paused'
        `).catch(() => { });
        await logEngineEvent("AUTO_ACTION", "booking_restore — payment failures cleared");
        break;
    }
  } catch (e: any) {
    console.error(`[ALERT-ENGINE] Action ${actionId} failed:`, e.message);
  }
}

async function logEngineEvent(tag: string, message: string, details?: object): Promise<void> {
  rawDb.execute(rawSql`
    INSERT INTO system_logs (level, tag, message, details)
    VALUES ('info', ${tag}, ${message}, ${JSON.stringify(details ?? {})}::jsonb)
  `).catch(() => { });
}

// ── Alert check cycle ─────────────────────────────────────────────────────────

async function runAlertCheck(): Promise<void> {
  let metrics: DashboardMetrics;
  try {
    metrics = await getDashboardMetrics(true); // force fresh on each engine tick
  } catch (e: any) {
    console.error("[ALERT-ENGINE] metrics fetch failed:", e.message);
    return;
  }

  for (const rule of ALERT_RULES) {
    const fires = rule.check(metrics);
    const state = getState(rule.id);
    const now = Date.now();

    if (fires) {
      const cooldownOk = now - state.lastFiredAt > ALERT_COOLDOWN_MS;

      if (!state.firing || cooldownOk) {
        // New fire or re-fire after cooldown
        alertStates.set(rule.id, { firing: true, lastFiredAt: now, fireCount: state.fireCount + 1 });

        const msg = rule.message(metrics);
        console.log(`[ALERT-ENGINE] 🔴 ${rule.severity.toUpperCase()} — ${rule.label}: ${msg}`);

        // Send external alert (non-blocking)
        sendOpsAlert({ level: rule.severity === "critical" ? "critical" : "error", source: "alert-engine", message: msg }).catch(() => { });

        // Log to system_logs
        await logEngineEvent(`ALERT_${rule.severity.toUpperCase()}`, msg, {
          ruleId: rule.id, metrics: {
            searchingRides: metrics.searchingRides, otpFailLast1h: metrics.otpFailLast1h,
            pendingPayments: metrics.pendingPayments, apiErrorRatePct: metrics.apiErrorRatePct,
          }
        });

        // Execute auto-action
        if (rule.action) {
          await executeAction(rule.action, metrics);
        }
      }
    } else {
      // Condition cleared
      if (state.firing) {
        alertStates.set(rule.id, { ...state, firing: false });
        console.log(`[ALERT-ENGINE] ✅ RESOLVED — ${rule.label}`);
        await logEngineEvent("ALERT_RESOLVED", `${rule.label} resolved`, { ruleId: rule.id });
      }
    }
  }
}

// ── Engine lifecycle ──────────────────────────────────────────────────────────

const CHECK_INTERVAL_MS = 60_000; // every 60 seconds
let engineInterval: ReturnType<typeof setInterval> | null = null;
let engineStartedAt = 0;

export function startAlertEngine(): void {
  if (engineInterval) return;
  engineStartedAt = Date.now();
  // First check after 30s (let server finish bootstrapping)
  setTimeout(() => {
    runAlertCheck().catch(e => console.error("[ALERT-ENGINE] initial check error:", e.message));
    engineInterval = setInterval(() => {
      runAlertCheck().catch(e => console.error("[ALERT-ENGINE] check error:", e.message));
    }, CHECK_INTERVAL_MS);
  }, 30_000);
  console.log("[ALERT-ENGINE] Started — checking every 60s");
}

export function getAlertEngineStatus(): {
  running: boolean;
  uptimeMs: number;
  activeAlerts: { ruleId: string; label: string; severity: AlertSeverity; since: number }[];
  allRules: { id: string; label: string; severity: AlertSeverity; firing: boolean }[];
} {
  const activeAlerts = ALERT_RULES
    .filter(r => getState(r.id).firing)
    .map(r => ({
      ruleId: r.id,
      label: r.label,
      severity: r.severity,
      since: getState(r.id).lastFiredAt,
    }));

  return {
    running: engineInterval !== null,
    uptimeMs: engineStartedAt ? Date.now() - engineStartedAt : 0,
    activeAlerts,
    allRules: ALERT_RULES.map(r => ({
      id: r.id,
      label: r.label,
      severity: r.severity,
      firing: getState(r.id).firing,
    })),
  };
}

// ── Daily health report ───────────────────────────────────────────────────────

export interface DailyHealthReport {
  date: string;
  totalRides: number;
  completedRides: number;
  cancelledRides: number;
  completionRatePct: number;
  revenueTotal: number;
  avgFare: number;
  fraudFlagsTotal: number;
  topFraudTypes: { type: string; count: number }[];
  otpFailures: number;
  apiErrors: number;
  buildApprovals: number;
  buildRejections: number;
  peakOnlineDrivers: number;
  generatedAt: string;
}

export async function getDailyHealthReport(dateStr?: string): Promise<DailyHealthReport> {
  const targetDate = dateStr ?? new Date().toISOString().slice(0, 10); // YYYY-MM-DD

  const [ridesR, fraudR, logsR, qaR] = await Promise.all([
    rawDb.execute(rawSql`
      SELECT
        COUNT(*) AS total_rides,
        COUNT(*) FILTER (WHERE current_status = 'completed') AS completed,
        COUNT(*) FILTER (WHERE current_status = 'cancelled')  AS cancelled,
        COALESCE(SUM(actual_fare) FILTER (WHERE current_status = 'completed'), 0) AS revenue,
        COALESCE(AVG(actual_fare) FILTER (WHERE current_status = 'completed'), 0) AS avg_fare
      FROM trip_requests
      WHERE DATE(created_at) = ${targetDate}::date
    `),
    rawDb.execute(rawSql`
      SELECT tag, COUNT(*) AS cnt
      FROM system_logs
      WHERE tag LIKE 'FRAUD_%' AND DATE(created_at) = ${targetDate}::date
      GROUP BY tag ORDER BY cnt DESC
    `),
    rawDb.execute(rawSql`
      SELECT
        COUNT(*) FILTER (WHERE tag = 'OTP_RATE_LIMIT') AS otp_fails,
        COUNT(*) FILTER (WHERE level = 'error')        AS api_errors
      FROM system_logs
      WHERE DATE(created_at) = ${targetDate}::date
    `),
    rawDb.execute(rawSql`
      SELECT
        COUNT(*) FILTER (WHERE tag = 'BUILD_APPROVED') AS approvals,
        COUNT(*) FILTER (WHERE tag = 'BUILD_REJECTED') AS rejections
      FROM system_logs
      WHERE DATE(created_at) = ${targetDate}::date
    `),
  ]);

  const rides = (ridesR.rows[0] as any) ?? {};
  const total = parseInt(rides.total_rides ?? "0");
  const completed = parseInt(rides.completed ?? "0");
  const cancelled = parseInt(rides.cancelled ?? "0");
  const logs = (logsR.rows[0] as any) ?? {};
  const qa = (qaR.rows[0] as any) ?? {};
  const fraudTotal = (fraudR.rows as any[]).reduce((s, r) => s + parseInt(r.cnt), 0);

  return {
    date: targetDate,
    totalRides: total,
    completedRides: completed,
    cancelledRides: cancelled,
    completionRatePct: (completed + cancelled) > 0 ? Math.round(completed / (completed + cancelled) * 100) : 100,
    revenueTotal: Math.round(parseFloat(rides.revenue ?? "0")),
    avgFare: Math.round(parseFloat(rides.avg_fare ?? "0")),
    fraudFlagsTotal: fraudTotal,
    topFraudTypes: (fraudR.rows as any[]).map(r => ({ type: r.tag, count: parseInt(r.cnt) })),
    otpFailures: parseInt(logs.otp_fails ?? "0"),
    apiErrors: parseInt(logs.api_errors ?? "0"),
    buildApprovals: parseInt(qa.approvals ?? "0"),
    buildRejections: parseInt(qa.rejections ?? "0"),
    peakOnlineDrivers: 0, // would need time-series table for accurate peak; 0 = not tracked yet
    generatedAt: new Date().toISOString(),
  };
}

// Schedule daily report at 23:30 — logs to system_logs and fires alert channel
function scheduleDailyReport(): void {
  const now = new Date();
  const target = new Date(now);
  target.setHours(23, 30, 0, 0);
  if (target <= now) target.setDate(target.getDate() + 1);
  const msUntil = target.getTime() - now.getTime();

  setTimeout(async () => {
    try {
      const report = await getDailyHealthReport();
      const summary =
        `📊 Daily Report ${report.date}: ` +
        `${report.totalRides} rides | ${report.completedRides} completed (${report.completionRatePct}%) | ` +
        `₹${report.revenueTotal} revenue | ${report.fraudFlagsTotal} fraud flags | ` +
        `${report.apiErrors} API errors`;

      sendOpsAlert({ level: "error", source: "daily-report", message: summary }).catch(() => { });
      await logEngineEvent("DAILY_REPORT", summary, report as unknown as object);
      console.log(`[ALERT-ENGINE] ${summary}`);
    } catch (e: any) {
      console.error("[ALERT-ENGINE] daily report error:", e.message);
    }
    scheduleDailyReport(); // reschedule for tomorrow
  }, msUntil);
}

// Start daily report scheduler when module loads
scheduleDailyReport();
