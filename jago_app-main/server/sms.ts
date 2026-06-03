/**
 * SMS delivery via smslogin.co XML API v3.
 * Credentials are loaded from business_settings DB into process.env at startup.
 * Required env vars: SMSLOGIN_USERNAME, SMSLOGIN_API_KEY, SMSLOGIN_SENDER_ID
 */

const SMS_URL = "https://smslogin.co/v3/xmlapi.php";

export async function sendCustomSms(phone: string, text: string): Promise<boolean> {
  const username = process.env.SMSLOGIN_USERNAME?.trim();
  const apiKey   = process.env.SMSLOGIN_API_KEY?.trim();
  const senderId = process.env.SMSLOGIN_SENDER_ID?.trim();

  if (!username || !apiKey || !senderId) {
    console.warn(`[SMS] Credentials not set (SMSLOGIN_USERNAME/API_KEY/SENDER_ID) — skipping SMS to ${phone}`);
    return false;
  }

  // Normalise to 10-digit number (smslogin expects local 10-digit)
  const mobile = phone.replace(/\D/g, "").replace(/^91/, "").slice(-10);
  if (mobile.length !== 10) {
    console.warn(`[SMS] Invalid phone number: ${phone}`);
    return false;
  }

  const xml = `<?xml version="1.0" encoding="UTF-8"?><xmlapi><auth><username>${username}</username><apikey>${apiKey}</apikey></auth><sendSMS><mobile>${mobile}</mobile><message>${escapeXml(text)}</message></sendSMS><options><senderid>${senderId}</senderid></options></xmlapi>`;

  const url = `${SMS_URL}?data=${encodeURIComponent(xml)}`;

  try {
    const res  = await fetch(url, { method: "GET" });
    const body = await res.text();

    if (body.includes("<success>")) {
      console.log(`[SMS] Delivered to ******${mobile.slice(-4)}`);
      return true;
    }

    console.error(`[SMS] smslogin error: ${body.slice(0, 300)}`);
    return false;
  } catch (e: any) {
    console.error(`[SMS] Network error: ${e.message}`);
    return false;
  }
}

function escapeXml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}
