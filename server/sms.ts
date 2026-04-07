/**
 * SMS service removed — Firebase Phone Auth is the only OTP provider.
 * This stub keeps existing imports valid while doing nothing.
 */
export async function sendCustomSms(_to: string, _message: string): Promise<boolean> {
  // No-op: SMS delivery removed. All OTP goes through Firebase.
  return false;
}
