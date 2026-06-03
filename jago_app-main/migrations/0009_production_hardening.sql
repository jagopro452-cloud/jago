-- ============================================================
-- Migration 0009: Production Hardening
-- Adds DB-level constraints, missing columns, and indexes
-- required for pool rides, wallet safety, and dispatch integrity
-- ============================================================

-- ── 1. Wallet non-negative balance ──────────────────────────
ALTER TABLE users
  ADD CONSTRAINT chk_users_wallet_non_negative
    CHECK (wallet_balance >= 0)
  NOT VALID;

-- Validate existing rows without locking table
ALTER TABLE users
  VALIDATE CONSTRAINT chk_users_wallet_non_negative;

-- ── 2. UNIQUE razorpay_payment_id (defense-in-depth) ────────
-- Application already prevents duplicates; DB constraint is the safety net.
ALTER TABLE customer_payments
  ADD CONSTRAINT uq_customer_payments_payment_id
    UNIQUE (razorpay_payment_id)
  NOT VALID;

ALTER TABLE driver_payments
  ADD CONSTRAINT uq_driver_payments_payment_id
    UNIQUE (razorpay_payment_id)
  NOT VALID;

-- ── 3. Pool seat integrity ───────────────────────────────────
ALTER TABLE outstation_pool_rides
  ADD CONSTRAINT chk_outstation_pool_seats_non_negative
    CHECK (available_seats >= 0)
  NOT VALID;

ALTER TABLE outstation_pool_rides
  VALIDATE CONSTRAINT chk_outstation_pool_seats_non_negative;

ALTER TABLE car_sharing_bookings
  ADD CONSTRAINT chk_car_sharing_seats_positive
    CHECK (seats_booked >= 1)
  NOT VALID;

-- ── 4. Add missing columns to car_sharing_rides ─────────────
ALTER TABLE car_sharing_rides
  ADD COLUMN IF NOT EXISTS vehicle_number VARCHAR(60),
  ADD COLUMN IF NOT EXISTS vehicle_model  VARCHAR(120),
  ADD COLUMN IF NOT EXISTS notes          TEXT;

-- ── 5. Add missing columns to car_sharing_bookings ──────────
ALTER TABLE car_sharing_bookings
  ADD COLUMN IF NOT EXISTS pickup_address  TEXT,
  ADD COLUMN IF NOT EXISTS dropoff_address TEXT,
  ADD COLUMN IF NOT EXISTS notes          TEXT,
  ADD COLUMN IF NOT EXISTS updated_at     TIMESTAMP DEFAULT NOW();

-- ── 6. Performance indexes for pool tables ───────────────────
CREATE INDEX IF NOT EXISTS idx_car_sharing_rides_driver
  ON car_sharing_rides(driver_id);

CREATE INDEX IF NOT EXISTS idx_car_sharing_rides_status_departure
  ON car_sharing_rides(status, departure_time)
  WHERE status = 'active';

CREATE INDEX IF NOT EXISTS idx_car_sharing_bookings_ride
  ON car_sharing_bookings(ride_id);

CREATE INDEX IF NOT EXISTS idx_car_sharing_bookings_customer
  ON car_sharing_bookings(customer_id);

CREATE INDEX IF NOT EXISTS idx_car_sharing_bookings_status
  ON car_sharing_bookings(status);

CREATE INDEX IF NOT EXISTS idx_outstation_pool_rides_driver
  ON outstation_pool_rides(driver_id);

CREATE INDEX IF NOT EXISTS idx_outstation_pool_rides_status
  ON outstation_pool_rides(status, is_active)
  WHERE is_active = true;

CREATE INDEX IF NOT EXISTS idx_outstation_pool_bookings_ride
  ON outstation_pool_bookings(ride_id);

CREATE INDEX IF NOT EXISTS idx_outstation_pool_bookings_customer
  ON outstation_pool_bookings(customer_id);

-- ── 7. Transactions table idempotency index ──────────────────
CREATE UNIQUE INDEX IF NOT EXISTS idx_transactions_ref_type
  ON transactions(ref_transaction_id, transaction_type)
  WHERE ref_transaction_id IS NOT NULL;
