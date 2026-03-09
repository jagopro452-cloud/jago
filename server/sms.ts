import twilio from "twilio";
import { getConf } from "./config-db";

type SmsResult = { success: boolean; provider: string; error?: string };

async function sendViaFast2Sms(phone: string, otp: string): Promise<SmsResult> {
  const apiKey = await getConf("FAST2SMS_API_KEY", "fast2sms_api_key");
  if (!apiKey) return { success: false, provider: "fast2sms", error: "No API key" };

  const tenDigit = phone.slice(-10);

  // Try OTP route first (fast, template-based)
  try {
    const otpRes = await fetch("https://www.fast2sms.com/dev/bulkV2", {
      method: "POST",
      headers: { authorization: apiKey, "Content-Type": "application/json" },
      body: JSON.stringify({ route: "otp", variables_values: otp, flash: 0, numbers: tenDigit }),
    });
    const otpData = (await otpRes.json()) as any;
    if (otpData.return === true) {
      console.log(`[SMS-FAST2SMS-OTP] OTP sent to ${tenDigit}`);
      return { success: true, provider: "fast2sms" };
    }
    console.warn(`[SMS-FAST2SMS-OTP] ${otpData.message} — trying Quick SMS route...`);
  } catch (_) {}

  // Fallback: Quick SMS route (works without website verification — good for testing)
  try {
    const quickRes = await fetch("https://www.fast2sms.com/dev/bulkV2", {
      method: "POST",
      headers: { authorization: apiKey, "Content-Type": "application/json" },
      body: JSON.stringify({
        route: "q",
        message: `Your JAGO OTP is ${otp}. Valid for 5 minutes. Do not share. -JAGO`,
        flash: 0,
        numbers: tenDigit,
      }),
    });
    const quickData = (await quickRes.json()) as any;
    if (quickData.return === true) {
      console.log(`[SMS-FAST2SMS-QUICK] OTP sent to ${tenDigit}`);
      return { success: true, provider: "fast2sms-quick" };
    }
    console.error(`[SMS-FAST2SMS-QUICK] Failed:`, quickData.message);
    return { success: false, provider: "fast2sms", error: quickData.message?.join?.(" ") || "Failed" };
  } catch (err: any) {
    console.error(`[SMS-FAST2SMS] Error:`, err.message);
    return { success: false, provider: "fast2sms", error: err.message };
  }
}

async function sendViaTwilio(phone: string, otp: string): Promise<SmsResult> {
  const accountSid = await getConf("TWILIO_ACCOUNT_SID", "twilio_account_sid");
  const authToken  = await getConf("TWILIO_AUTH_TOKEN", "twilio_auth_token");
  const fromNumber = await getConf("TWILIO_PHONE_NUMBER", "twilio_phone_number");
  if (!accountSid || !authToken || !fromNumber) {
    return { success: false, provider: "twilio", error: "Missing credentials" };
  }

  const e164Phone = phone.startsWith("+") ? phone : `+91${phone.slice(-10)}`;

  try {
    const client = twilio(accountSid, authToken);
    await client.messages.create({
      body: `Your JAGO OTP is: ${otp}\n\nValid for 5 minutes. Do not share.\n- JAGO Team`,
      from: fromNumber,
      to: e164Phone,
    });
    console.log(`[SMS-TWILIO] OTP sent to ${e164Phone}`);
    return { success: true, provider: "twilio" };
  } catch (err: any) {
    console.error(`[SMS-TWILIO] Error:`, err.message);
    return { success: false, provider: "twilio", error: err.message };
  }
}

export async function sendOtpSms(phone: string, otp: string): Promise<SmsResult> {
  // Try Fast2SMS first (best for India — cheap, easy)
  const fast2smsKey = await getConf("FAST2SMS_API_KEY", "fast2sms_api_key");
  if (fast2smsKey) {
    const result = await sendViaFast2Sms(phone, otp);
    if (result.success) return result;
    console.warn("[SMS] Fast2SMS failed, trying Twilio...");
  }

  // Fallback: Twilio
  const twilioSid = await getConf("TWILIO_ACCOUNT_SID", "twilio_account_sid");
  if (twilioSid) {
    const result = await sendViaTwilio(phone, otp);
    if (result.success) return result;
  }

  // No provider configured
  console.warn(`[SMS-NONE] No SMS provider configured. OTP for ${phone}: ${otp}`);
  return { success: false, provider: "none", error: "No SMS provider configured" };
}

export async function sendCustomSms(phone: string, message: string): Promise<SmsResult> {
  const tenDigit = phone.replace(/\D/g, '').slice(-10);
  if (!tenDigit || tenDigit.length < 10) return { success: false, provider: "none", error: "Invalid phone" };

  // Try Fast2SMS Quick SMS route
  const fast2smsKey = await getConf("FAST2SMS_API_KEY", "fast2sms_api_key");
  if (fast2smsKey) {
    try {
      const res = await fetch("https://www.fast2sms.com/dev/bulkV2", {
        method: "POST",
        headers: { authorization: fast2smsKey, "Content-Type": "application/json" },
        body: JSON.stringify({ route: "q", message, flash: 0, numbers: tenDigit }),
      });
      const data = (await res.json()) as any;
      if (data.return === true) return { success: true, provider: "fast2sms" };
      console.warn("[SMS-CUSTOM] Fast2SMS failed:", data.message);
    } catch (e: any) { console.warn("[SMS-CUSTOM] Fast2SMS error:", e.message); }
  }

  // Fallback: Twilio
  const twilioSid = await getConf("TWILIO_ACCOUNT_SID", "twilio_account_sid");
  const twilioToken = await getConf("TWILIO_AUTH_TOKEN", "twilio_auth_token");
  const twilioFrom = await getConf("TWILIO_PHONE_NUMBER", "twilio_phone_number");
  if (twilioSid && twilioToken && twilioFrom) {
    try {
      const twClient = twilio(twilioSid, twilioToken);
      await twClient.messages.create({ body: message, from: twilioFrom, to: `+91${tenDigit}` });
      return { success: true, provider: "twilio" };
    } catch (e: any) { console.warn("[SMS-CUSTOM] Twilio error:", e.message); }
  }

  console.warn(`[SMS-NONE] Custom SMS for ${tenDigit}: ${message}`);
  return { success: false, provider: "none" };
}

  const tenDigit = phone.slice(-10);

  // Try OTP route first (fast, template-based)
  try {
    const otpRes = await fetch("https://www.fast2sms.com/dev/bulkV2", {
      method: "POST",
      headers: { authorization: apiKey, "Content-Type": "application/json" },
      body: JSON.stringify({ route: "otp", variables_values: otp, flash: 0, numbers: tenDigit }),
    });
    const otpData = (await otpRes.json()) as any;
    if (otpData.return === true) {
      console.log(`[SMS-FAST2SMS-OTP] OTP sent to ${tenDigit}`);
      return { success: true, provider: "fast2sms" };
    }
    console.warn(`[SMS-FAST2SMS-OTP] ${otpData.message} — trying Quick SMS route...`);
  } catch (_) {}

  // Fallback: Quick SMS route (works without website verification — good for testing)
  try {
    const quickRes = await fetch("https://www.fast2sms.com/dev/bulkV2", {
      method: "POST",
      headers: { authorization: apiKey, "Content-Type": "application/json" },
      body: JSON.stringify({
        route: "q",
        message: `Your JAGO OTP is ${otp}. Valid for 5 minutes. Do not share. -JAGO`,
        flash: 0,
        numbers: tenDigit,
      }),
    });
    const quickData = (await quickRes.json()) as any;
    if (quickData.return === true) {
      console.log(`[SMS-FAST2SMS-QUICK] OTP sent to ${tenDigit}`);
      return { success: true, provider: "fast2sms-quick" };
    }
    console.error(`[SMS-FAST2SMS-QUICK] Failed:`, quickData.message);
    return { success: false, provider: "fast2sms", error: quickData.message?.join?.(" ") || "Failed" };
  } catch (err: any) {
    console.error(`[SMS-FAST2SMS] Error:`, err.message);
    return { success: false, provider: "fast2sms", error: err.message };
  }
}

async function sendViaTwilio(phone: string, otp: string): Promise<SmsResult> {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const fromNumber = process.env.TWILIO_PHONE_NUMBER;
  if (!accountSid || !authToken || !fromNumber) {
    return { success: false, provider: "twilio", error: "Missing credentials" };
  }

  const e164Phone = phone.startsWith("+") ? phone : `+91${phone.slice(-10)}`;

  try {
    const client = twilio(accountSid, authToken);
    await client.messages.create({
      body: `Your JAGO OTP is: ${otp}\n\nValid for 5 minutes. Do not share.\n- JAGO Team`,
      from: fromNumber,
      to: e164Phone,
    });
    console.log(`[SMS-TWILIO] OTP sent to ${e164Phone}`);
    return { success: true, provider: "twilio" };
  } catch (err: any) {
    console.error(`[SMS-TWILIO] Error:`, err.message);
    return { success: false, provider: "twilio", error: err.message };
  }
}

export async function sendOtpSms(phone: string, otp: string): Promise<SmsResult> {
  // Try Fast2SMS first (best for India — cheap, easy)
  if (process.env.FAST2SMS_API_KEY) {
    const result = await sendViaFast2Sms(phone, otp);
    if (result.success) return result;
    console.warn("[SMS] Fast2SMS failed, trying Twilio...");
  }

  // Fallback: Twilio
  if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN && process.env.TWILIO_PHONE_NUMBER) {
    const result = await sendViaTwilio(phone, otp);
    if (result.success) return result;
  }

  // No provider configured
  console.warn(`[SMS-NONE] No SMS provider configured. OTP for ${phone}: ${otp}`);
  return { success: false, provider: "none", error: "No SMS provider configured" };
}

export async function sendCustomSms(phone: string, message: string): Promise<SmsResult> {
  const tenDigit = phone.replace(/\D/g, '').slice(-10);
  if (!tenDigit || tenDigit.length < 10) return { success: false, provider: "none", error: "Invalid phone" };

  // Try Fast2SMS Quick SMS route
  if (process.env.FAST2SMS_API_KEY) {
    try {
      const res = await fetch("https://www.fast2sms.com/dev/bulkV2", {
        method: "POST",
        headers: { authorization: process.env.FAST2SMS_API_KEY!, "Content-Type": "application/json" },
        body: JSON.stringify({ route: "q", message, flash: 0, numbers: tenDigit }),
      });
      const data = (await res.json()) as any;
      if (data.return === true) return { success: true, provider: "fast2sms" };
      console.warn("[SMS-CUSTOM] Fast2SMS failed:", data.message);
    } catch (e: any) { console.warn("[SMS-CUSTOM] Fast2SMS error:", e.message); }
  }

  // Fallback: Twilio
  if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN && process.env.TWILIO_PHONE_NUMBER) {
    try {
      const twClient = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
      await twClient.messages.create({ body: message, from: process.env.TWILIO_PHONE_NUMBER!, to: `+91${tenDigit}` });
      return { success: true, provider: "twilio" };
    } catch (e: any) { console.warn("[SMS-CUSTOM] Twilio error:", e.message); }
  }

  console.warn(`[SMS-NONE] Custom SMS for ${tenDigit}: ${message}`);
  return { success: false, provider: "none" };
}
