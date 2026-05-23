-- Vehicle availability controls are DB-authoritative.
-- Firebase/Firestore is a best-effort mirror and must not block admin toggles.

CREATE TABLE IF NOT EXISTS vehicle_runtime_status (
  key VARCHAR(50) PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  active BOOLEAN NOT NULL DEFAULT true,
  icon VARCHAR(50) NOT NULL DEFAULT '',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by TEXT,
  sync_warning TEXT
);

INSERT INTO vehicle_runtime_status (key, name, active, icon, updated_by)
VALUES
  ('bike', 'Bike', true, 'bike', 'migration'),
  ('auto', 'Auto', true, 'auto', 'migration'),
  ('cab', 'Cab', false, 'car', 'migration'),
  ('premium', 'Premium', false, 'premium', 'migration')
ON CONFLICT (key) DO NOTHING;
