const { Client } = require('pg');

(async () => {
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();

  await c.query(`
    CREATE TABLE IF NOT EXISTS revenue_model_settings (
      key_name VARCHAR(100) PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    )
  `);

  const defaults = {
    active_model: 'commission',
    rides_model: 'commission',
    parcels_model: 'commission',
    cargo_model: 'commission',
    intercity_model: 'commission',
    commission_pct: '15',
    commission_gst_pct: '18',
    commission_insurance_per_ride: '2',
    sub_platform_fee_per_ride: '5',
    sub_gst_pct: '18',
    auto_lock_threshold: '-100'
  };

  for (const [key, val] of Object.entries(defaults)) {
    await c.query(
      `INSERT INTO revenue_model_settings (key_name, value) VALUES ($1, $2) ON CONFLICT (key_name) DO NOTHING`,
      [key, val]
    );
  }

  console.log('revenue_settings_ready');
  await c.end();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
