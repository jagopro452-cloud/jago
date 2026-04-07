-- Add Razorpay payment reference for legacy payments table when present.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'payments'
  ) THEN
    ALTER TABLE public.payments
      ADD COLUMN IF NOT EXISTS razorpay_payment_id VARCHAR(255);
  END IF;
END
$$;
