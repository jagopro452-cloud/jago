import twilio from "twilio";

type SmsResult = { success: boolean; provider: string; error?: string };

async function sendViaFast2Sms(phone: string, otp: string): Promise<SmsResult> {
  const apiKey = process.env.FAST2SMS_API_KEY;
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
