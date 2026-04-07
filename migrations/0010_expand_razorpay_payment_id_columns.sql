-- Ensure Razorpay payment id fields use VARCHAR(255) across payment tables.
ALTER TABLE IF EXISTS customer_payments
  ADD COLUMN IF NOT EXISTS razorpay_payment_id VARCHAR(255);

ALTER TABLE IF EXISTS driver_payments
  ADD COLUMN IF NOT EXISTS razorpay_payment_id VARCHAR(255);

ALTER TABLE IF EXISTS customer_payments
  ALTER COLUMN razorpay_payment_id TYPE VARCHAR(255);

ALTER TABLE IF EXISTS driver_payments
  ALTER COLUMN razorpay_payment_id TYPE VARCHAR(255);
