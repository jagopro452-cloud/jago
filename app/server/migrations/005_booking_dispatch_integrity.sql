-- Booking and dispatch integrity hardening.
-- Fails closed for future bookings while safely quarantining legacy null-category rows.

CREATE INDEX IF NOT EXISTS idx_trip_requests_vehicle_category_id ON trip_requests(vehicle_category_id);
CREATE INDEX IF NOT EXISTS idx_trip_requests_customer_active ON trip_requests(customer_id, current_status, updated_at);
CREATE INDEX IF NOT EXISTS idx_trip_requests_offered_driver ON trip_requests(offered_driver_id, offer_expires_at);

DO $$
DECLARE
  legacy_category_id uuid;
BEGIN
  SELECT id INTO legacy_category_id
  FROM vehicle_categories
  WHERE name = 'Legacy Unknown Vehicle'
  LIMIT 1;

  IF legacy_category_id IS NULL THEN
    INSERT INTO vehicle_categories (
      name,
      icon,
      type,
      vehicle_type,
      base_fare,
      fare_per_km,
      minimum_fare,
      waiting_charge_per_min,
      total_seats,
      is_carpool,
      is_active,
      created_at
    ) VALUES (
      'Legacy Unknown Vehicle',
      'warning',
      'legacy',
      'legacy',
      0,
      0,
      0,
      0,
      0,
      false,
      false,
      NOW()
    )
    RETURNING id INTO legacy_category_id;
  END IF;

  UPDATE trip_requests
  SET current_status = 'cancelled',
      cancel_reason = COALESCE(cancel_reason, 'Cancelled by migration: missing vehicle category'),
      cancelled_by = COALESCE(cancelled_by, 'system'),
      vehicle_category_id = legacy_category_id,
      updated_at = NOW()
  WHERE vehicle_category_id IS NULL
    AND current_status IN ('searching','driver_assigned','accepted','arrived','on_the_way');

  UPDATE trip_requests
  SET vehicle_category_id = legacy_category_id,
      updated_at = NOW()
  WHERE vehicle_category_id IS NULL;

  ALTER TABLE trip_requests
    ALTER COLUMN vehicle_category_id SET NOT NULL;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'trip_requests_vehicle_category_id_fkey'
  ) THEN
    ALTER TABLE trip_requests
      ADD CONSTRAINT trip_requests_vehicle_category_id_fkey
      FOREIGN KEY (vehicle_category_id)
      REFERENCES vehicle_categories(id)
      ON UPDATE CASCADE
      ON DELETE RESTRICT;
  END IF;
END $$;
