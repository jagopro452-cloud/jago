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
