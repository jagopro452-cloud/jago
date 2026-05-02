import crypto from "crypto";

function redactSecrets(input: string): string {
  return input
    .replace(/(password|token|secret|authorization)\s*[:=]\s*[^\s,;]+/gi, "$1=[REDACTED]")
    .replace(/Bearer\s+[A-Za-z0-9._-]+/g, "Bearer [REDACTED]");
}

export function makeErrorId(): string {
  return crypto.randomBytes(8).toString("hex");
}

export async function sendAlert(event: {
  level: "error" | "critical";
  source: string;
  message: string;
  details?: string;
}) {
  const webhook = process.env.ALERT_WEBHOOK_URL;
  if (!webhook) return;
  try {
    const payload = {
      text: `[${event.level.toUpperCase()}] ${event.source}: ${event.message}`,
      source: event.source,
      message: event.message,
      details: event.details ? redactSecrets(event.details).slice(0, 1800) : undefined,
      ts: new Date().toISOString(),
    };
    await fetch(webhook, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
  } catch {
    // Do not crash request flow on observability failures.
  }
}

/**
 * Multi-channel alert routing based on priority.
 *
 * P0 → PAGER_WEBHOOK_URL + WHATSAPP_WEBHOOK_URL + ALERT_WEBHOOK_URL (all channels)
 * P1 → WHATSAPP_WEBHOOK_URL + ALERT_WEBHOOK_URL
 * P2/P3/default → ALERT_WEBHOOK_URL only
 *
 * Any channel URL not set is silently skipped.
 * Falls back to ALERT_WEBHOOK_URL for all calls without a priority field.
 */
export async function sendOpsAlert(event: {
  level: "error" | "critical";
  source: string;
  message: string;
  priority?: 0 | 1 | 2 | 3;
  details?: string;
}): Promise<void> {
  const payload = {
    text: `[P${event.priority ?? "?"}/${event.level.toUpperCase()}] ${event.source}: ${event.message}`,
    source: event.source,
    priority: event.priority,
    level: event.level,
    message: event.message,
    details: event.details ? redactSecrets(event.details).slice(0, 1800) : undefined,
    ts: new Date().toISOString(),
  };

  const channels: string[] = [];
  const p = event.priority ?? 99;

  if (p === 0) {
    // P0: all available channels
    if (process.env.PAGER_WEBHOOK_URL)     channels.push(process.env.PAGER_WEBHOOK_URL);
    if (process.env.WHATSAPP_WEBHOOK_URL)  channels.push(process.env.WHATSAPP_WEBHOOK_URL);
  } else if (p === 1) {
    // P1: WhatsApp + default
    if (process.env.WHATSAPP_WEBHOOK_URL)  channels.push(process.env.WHATSAPP_WEBHOOK_URL);
  }
  // P2/P3/default: default webhook only
  if (process.env.ALERT_WEBHOOK_URL) channels.push(process.env.ALERT_WEBHOOK_URL);

  if (channels.length === 0) return;

  await Promise.allSettled(
    channels.map(url =>
      fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      })
    )
  );
}
