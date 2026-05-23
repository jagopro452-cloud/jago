-- Vehicle category availability integrity.
-- Keeps customer booking fail-closed while preventing ride/parcel category bleed.

ALTER TABLE vehicle_categories
  ADD COLUMN IF NOT EXISTS service_type VARCHAR(30) DEFAULT 'ride';

UPDATE vehicle_categories
SET service_type = CASE
  WHEN LOWER(COALESCE(vehicle_type, '')) IN ('bike_parcel','auto_parcel','tata_ace','pickup_truck','bolero_cargo','tempo_407','cargo_car')
    OR LOWER(COALESCE(type, '')) IN ('parcel','cargo')
    OR LOWER(COALESCE(name, '')) LIKE '%parcel%'
    OR LOWER(COALESCE(name, '')) LIKE '%cargo%'
    OR LOWER(COALESCE(name, '')) LIKE '%truck%'
    OR LOWER(COALESCE(name, '')) LIKE '%tempo%'
    OR LOWER(COALESCE(name, '')) LIKE '%tata%'
    OR LOWER(COALESCE(name, '')) LIKE '%bolero%'
    OR LOWER(COALESCE(name, '')) LIKE '%pickup%'
    THEN 'parcel'
  WHEN COALESCE(is_carpool, false) = true
    OR LOWER(COALESCE(vehicle_type, '')) IN ('carpool','local_pool','outstation_pool')
    OR LOWER(COALESCE(name, '')) LIKE '%pool%'
    OR LOWER(COALESCE(name, '')) LIKE '%share%'
    THEN 'pool'
  ELSE 'ride'
END
WHERE service_type IS NULL
   OR TRIM(service_type) = ''
   OR LOWER(COALESCE(vehicle_type, '')) IN ('bike_parcel','auto_parcel','tata_ace','pickup_truck','bolero_cargo','tempo_407','cargo_car')
   OR LOWER(COALESCE(type, '')) IN ('parcel','cargo')
   OR COALESCE(is_carpool, false) = true;

UPDATE vehicle_categories
SET type = CASE
  WHEN service_type IN ('parcel','cargo') THEN 'parcel'
  ELSE 'ride'
END
WHERE LOWER(COALESCE(type, '')) NOT IN ('legacy')
  AND (
    (service_type IN ('parcel','cargo') AND LOWER(COALESCE(type, '')) <> 'parcel')
    OR (service_type IN ('ride','pool','carpool') AND LOWER(COALESCE(type, '')) NOT IN ('ride'))
  );

-- Production had a duplicate/legacy Tempo row classified as ride. Keep one
-- canonical active Tempo parcel category and deactivate duplicate legacy rows.
WITH ranked_tempo AS (
  SELECT id,
         ROW_NUMBER() OVER (
           PARTITION BY LOWER(COALESCE(vehicle_type, ''))
           ORDER BY
             CASE WHEN LOWER(name) = 'tempo 407' THEN 0 ELSE 1 END,
             created_at ASC NULLS LAST,
             id
         ) AS rn
  FROM vehicle_categories
  WHERE LOWER(COALESCE(vehicle_type, '')) = 'tempo_407'
)
UPDATE vehicle_categories vc
SET is_active = false
FROM ranked_tempo rt
WHERE vc.id = rt.id
  AND rt.rn > 1;

ALTER TABLE vehicle_categories
  ALTER COLUMN service_type SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'vehicle_categories_service_type_check'
  ) THEN
    ALTER TABLE vehicle_categories
      ADD CONSTRAINT vehicle_categories_service_type_check
      CHECK (service_type IN ('ride','parcel','pool','cargo','carpool'));
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_vehicle_categories_active_service
  ON vehicle_categories(service_type, is_active);

CREATE INDEX IF NOT EXISTS idx_trip_fares_vehicle_category_id
  ON trip_fares(vehicle_category_id);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'trip_fares_vehicle_category_id_fkey'
  ) THEN
    ALTER TABLE trip_fares
      ADD CONSTRAINT trip_fares_vehicle_category_id_fkey
      FOREIGN KEY (vehicle_category_id)
      REFERENCES vehicle_categories(id)
      ON UPDATE CASCADE
      ON DELETE RESTRICT;
  END IF;
END $$;
