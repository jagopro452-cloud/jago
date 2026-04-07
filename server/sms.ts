import twilio from "twilio";

/**
 * Send an SMS in best-effort mode.
 * Uses Twilio only when credentials are configured; otherwise no-op with a warning.
 */
export async function sendCustomSms(to: string, message: string): Promise<boolean> {
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  const from = process.env.TWILIO_PHONE_NUMBER;

  if (!to || !message) return false;

  if (!sid || !token || !from) {
    console.warn("[SMS] Twilio not configured; skipping SMS delivery");
    return false;
  }

  try {
    const client = twilio(sid, token);
    await client.messages.create({
      to,
      from,
      body: message,
    });
    return true;
  } catch (err: any) {
    console.error("[SMS] send failed:", err?.message || err);
    return false;
  }
}
