export async function canSendSms(): Promise<boolean> {
  return false;
}

export async function sendCustomSms(phone: string, text: string) {
  console.log(`[SMS-STUB] SMS providers disabled. Skipping message to ${phone}: ${text}`);
  return false;
}
