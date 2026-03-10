import twilio from "twilio";
import { getConf } from "./config-db";

type SmsResult = { success: boolean; provider: string; error?: string };

async function sendViaFast2Sms(phone: string, otp: string): Promise<SmsResult> {
  const apiKey = await getConf("FAST2SMS_API_KEY", "fast2sms_api_key");
  if (!apiKey) return { success: false, provider: "fast2sms", error: "No API key" };
  const tenDigit = phone.slice(-10);
  try {
    const otpRes = await fetch("https://www.fast2sms.com/dev/bulkV2", {
      method: "POST",
      headers: { authorization: apiKey, "Content-Type": "application/json" },
      body: JSON.stringify({ route: "otp", variables_values: otp, flash: 0, numbers: tenDigit }),
    });
    const otpData = (await otpRes.json()) as any;
    if (otpData.return === true) { console.log(`[SMS-FAST2SMS-OTP] OTP sent to ${tenDigit}`); return { success: true, provider: "fast2sms" }; }
    console.warn(`[SMS-FAST2SMS-OTP] Failed, trying Quick SMS...`);
  } catch (_) {}
  try {
    const quickRes = await fetch("https://www.fast2sms.com/dev/bulkV2", {
      method: "POST",
      headers: { authorization: apiKey, "Content-Type": "application/json" },
      body: JSON.stringify({ route: "q", message: `Your JAGO OTP is ${otp}. Valid for 5 minutes. Do not share. -JAGO`, flash: 0, numbers: tenDigit }),
    });
    const quickData = (await quickRes.json()) as any;
    if (quickData.return === true) { console.log(`[SMS-FAST2SMS-QUICK] OTP sent to ${tenDigit}`); return { success: true, provider: "fast2sms-quick" }; }
    return { success: false, provider: "fast2sms", error: quickData.message?.join?.(" ") || "Failed" };
  } catch (err: any) { return { success: false, provider: "fast2sms", error: err.message }; }
}

async function sendViaTwilio(phone: string, otp: string): Promise<SmsResult> {
  const accountSid = await getConf("TWILIO_ACCOUNT_SID", "twilio_account_sid");
  const authToken  = await getConf("TWILIO_AUTH_TOKEN", "twilio_auth_token");
  const fromNumber = await getConf("TWILIO_PHONE_NUMBER", "twilio_phone_number");
  if (!accountSid || !authToken || !fromNumber) return { success: false, provider: "twilio", error: "Missing credentials" };
  const e164Phone = phone.startsWith("+") ? phone : `+91${phone.slice(-10)}`;
  try {
    const client = twilio(accountSid, authToken);
    await client.messages.create({ body: `Your JAGO OTP is: ${otp}\n\nValid for 5 minutes. Do not share.\n- JAGO Team`, from: fromNumber, to: e164Phone });
    console.log(`[SMS-TWILIO] OTP sent to ${e164Phone}`);
    return { success: true, provider: "twilio" };
  } catch (err: any) { return { success: false, provider: "twilio", error: err.message }; }
}

export async function sendOtpSms(phone: string, otp: string): Promise<SmsResult> {
  const fast2smsKey = await getConf("FAST2SMS_API_KEY", "fast2sms_api_key");
  if (fast2smsKey) { const r = await sendViaFast2Sms(phone, otp); if (r.success) return r; }
  const twilioSid = await getConf("TWILIO_ACCOUNT_SID", "twilio_account_sid");
  if (twilioSid) { const r = await sendViaTwilio(phone, otp); if (r.success) return r; }
  console.warn(`[SMS-NONE] No SMS provider configured. OTP for ${phone}: ${otp}`);
  return { success: false, provider: "none", error: "No SMS provider configured" };
}

export async function sendCustomSms(phone: string, message: string): Promise<SmsResult> {
  const tenDigit = phone.replace(/\D/g, "").slice(-10);
  if (!tenDigit || tenDigit.length < 10) return { success: false, provider: "none", error: "Invalid phone" };
  const fast2smsKey = await getConf("FAST2SMS_API_KEY", "fast2sms_api_key");
  if (fast2smsKey) {
    try {
      const res = await fetch("https://www.fast2sms.com/dev/bulkV2", { method: "POST", headers: { authorization: fast2smsKey, "Content-Type": "application/json" }, body: JSON.stringify({ route: "q", message, flash: 0, numbers: tenDigit }) });
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
