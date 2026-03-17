import twilio from "twilio";
import { getConf } from "./config-db";

type SmsResult = { success: boolean; provider: string; error?: string };

// OTP is now handled entirely by Firebase Phone Auth.
// sendCustomSms is kept for non-OTP notifications (parcel delivery, ride updates, etc.)

export async function sendCustomSms(phone: string, message: string): Promise<SmsResult> {
  const tenDigit = phone.replace(/\D/g, "").slice(-10);
  if (!tenDigit || tenDigit.length < 10) return { success: false, provider: "none", error: "Invalid phone" };
  const fast2smsKey = await getConf("FAST2SMS_API_KEY", "fast2sms_api_key");
  if (fast2smsKey) {
    try {
      const res = await fetch("https://www.fast2sms.com/dev/bulkV2", { method: "POST", headers: { authorization: fast2smsKey, "Content-Type": "application/json" }, body: JSON.stringify({ route: "q", message, flash: 0, numbers: tenDigit }), signal: AbortSignal.timeout(10000) });
      const data = (await res.json()) as any;
      if (data.return === true) return { success: true, provider: "fast2sms" };
    } catch (e: any) { console.warn("[SMS-CUSTOM] Fast2SMS error:", e.message); }
  }
  const twilioSid = await getConf("TWILIO_ACCOUNT_SID", "twilio_account_sid");
  const twilioToken = await getConf("TWILIO_AUTH_TOKEN", "twilio_auth_token");
  const twilioFrom  = await getConf("TWILIO_PHONE_NUMBER", "twilio_phone_number");
  if (twilioSid && twilioToken && twilioFrom) {
    try {
      const twClient = twilio(twilioSid, twilioToken);
      await twClient.messages.create({ body: message, from: twilioFrom, to: `+91${tenDigit}` });
      return { success: true, provider: "twilio" };
    } catch (e: any) { console.warn("[SMS-CUSTOM] Twilio error:", e.message); }
  }
  return { success: false, provider: "none" };
}
