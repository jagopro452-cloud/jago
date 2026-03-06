import { z } from "zod";

const EnvSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "staging", "production"]).default("development"),
  PORT: z.string().optional(),
  DATABASE_URL: z.string().min(1, "DATABASE_URL is required"),

  ADMIN_EMAIL: z.string().email().optional(),
  ADMIN_NAME: z.string().optional(),
  ADMIN_PASSWORD: z.string().optional(),
  ADMIN_SESSION_TTL_HOURS: z.string().optional(),
  ADMIN_2FA_REQUIRED: z.string().optional(),
  ENABLE_DEV_OTP_RESPONSES: z.string().optional(),

  GOOGLE_MAPS_API_KEY: z.string().optional(),
  SOCKET_ALLOWED_ORIGINS: z.string().optional(),
  OPS_API_KEY: z.string().optional(),
  ALERT_WEBHOOK_URL: z.string().optional(),

  RAZORPAY_KEY_ID: z.string().optional(),
  RAZORPAY_KEY_SECRET: z.string().optional(),
  RAZORPAY_WEBHOOK_SECRET: z.string().optional(),

  FAST2SMS_API_KEY: z.string().optional(),
  TWILIO_ACCOUNT_SID: z.string().optional(),
  TWILIO_AUTH_TOKEN: z.string().optional(),
  TWILIO_PHONE_NUMBER: z.string().optional(),

  FIREBASE_SERVICE_ACCOUNT_KEY: z.string().optional(),
  FIREBASE_WEB_API_KEY: z.string().optional(),
});

export type AppEnv = z.infer<typeof EnvSchema>;

export function parseEnv(): AppEnv {
  const parsed = EnvSchema.safeParse(process.env);
  if (!parsed.success) {
    const issues = parsed.error.issues.map((i) => `${i.path.join(".")}: ${i.message}`).join("; ");
    throw new Error(`Invalid environment configuration: ${issues}`);
  }
  return parsed.data;
}

export function isTrue(value: string | undefined): boolean {
  if (!value) return false;
  return ["1", "true", "yes", "on"].includes(value.toLowerCase());
}

export function validateProductionReadiness(env: AppEnv): void {
  if (env.NODE_ENV !== "production") return;

  const missing: string[] = [];
  if (!env.ADMIN_PASSWORD) missing.push("ADMIN_PASSWORD");
  if (!env.GOOGLE_MAPS_API_KEY) missing.push("GOOGLE_MAPS_API_KEY");
  if (!env.OPS_API_KEY) missing.push("OPS_API_KEY");
  if (!env.SOCKET_ALLOWED_ORIGINS) missing.push("SOCKET_ALLOWED_ORIGINS");

  if (missing.length) {
    throw new Error(`Production environment is missing required variables: ${missing.join(", ")}`);
  }
}
