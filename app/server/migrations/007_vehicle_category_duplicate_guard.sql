-- Prevent duplicate active service/vehicle categories from leaking into fare
-- estimate and dispatch selection.

WITH ranked_active_categories AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY LOWER(COALESCE(service_type, 'ride')), LOWER(COALESCE(vehicle_type, ''))
      ORDER BY
        CASE
          WHEN LOWER(name) IN ('bike','auto','mini car','sedan','suv','bike parcel','auto parcel','mini truck','pickup truck','bolero cargo','tempo 407','car pool','local pool','outstation pool') THEN 0
          ELSE 1
        END,
        created_at ASC NULLS LAST,
        id
    ) AS rn
  FROM vehicle_categories
  WHERE is_active = true
    AND COALESCE(vehicle_type, '') <> ''
    AND COALESCE(service_type, '') <> ''
)
UPDATE vehicle_categories vc
SET is_active = false
FROM ranked_active_categories ranked
WHERE vc.id = ranked.id
  AND ranked.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS ux_vehicle_categories_active_service_vehicle_type
  ON vehicle_categories(LOWER(service_type), LOWER(vehicle_type))
  WHERE is_active = true
    AND COALESCE(vehicle_type, '') <> ''
    AND COALESCE(service_type, '') <> '';
