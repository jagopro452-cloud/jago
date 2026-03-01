import twilio from "twilio";

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const fromNumber = process.env.TWILIO_PHONE_NUMBER;

export async function sendOtpSms(phone: string, otp: string): Promise<{ success: boolean; provider: string; error?: string }> {
  const e164Phone = phone.startsWith("+") ? phone : `+91${phone.slice(-10)}`;

  if (accountSid && authToken && fromNumber) {
    try {
      const client = twilio(accountSid, authToken);
      await client.messages.create({
        body: `Your JAGO verification code is: ${otp}\n\nValid for 5 minutes. Do not share this OTP.\n- JAGO Team`,
        from: fromNumber,
        to: e164Phone,
      });
      console.log(`[SMS-TWILIO] OTP sent to ${e164Phone}`);
      return { success: true, provider: "twilio" };
    } catch (err: any) {
      console.error(`[SMS-TWILIO] Failed to send OTP to ${e164Phone}:`, err.message);
      return { success: false, provider: "twilio", error: err.message };
    }
  }

  console.warn(`[SMS-FALLBACK] No SMS provider configured. OTP for ${e164Phone}: ${otp}`);
  return { success: false, provider: "none", error: "No SMS provider configured" };
}
