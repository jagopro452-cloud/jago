const { Client } = require('pg');

(async () => {
  const db = new Client({ connectionString: process.env.DATABASE_URL });
  await db.connect();

  await db.query('CREATE EXTENSION IF NOT EXISTS pgcrypto');

  await db.query(`
    CREATE TABLE IF NOT EXISTS intercity_routes (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      from_city TEXT NOT NULL,
      to_city TEXT NOT NULL,
      estimated_km NUMERIC(10,2) DEFAULT 0,
      base_fare NUMERIC(10,2) DEFAULT 0,
      fare_per_km NUMERIC(10,2) DEFAULT 0,
      toll_charges NUMERIC(10,2) DEFAULT 0,
      vehicle_category_id UUID NULL,
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);

  await db.query(`
    CREATE TABLE IF NOT EXISTS car_sharing_settings (
      key_name TEXT PRIMARY KEY,
      value TEXT,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);

  await db.query(`
    CREATE TABLE IF NOT EXISTS intercity_cs_settings (
      key_name TEXT PRIMARY KEY,
      value TEXT,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);

  await db.query(`
    CREATE TABLE IF NOT EXISTS car_sharing_rides (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      driver_id UUID NULL,
      vehicle_category_id UUID NULL,
      from_location TEXT NOT NULL,
      to_location TEXT NOT NULL,
      departure_time TIMESTAMPTZ NOT NULL,
      max_seats INTEGER NOT NULL DEFAULT 1,
      seat_price NUMERIC(10,2) NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'active',
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);

  await db.query(`
    CREATE TABLE IF NOT EXISTS car_sharing_bookings (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      ride_id UUID NOT NULL,
      customer_id UUID NOT NULL,
      seats_booked INTEGER NOT NULL DEFAULT 1,
      total_fare NUMERIC(10,2) NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'confirmed',
      payment_status TEXT NOT NULL DEFAULT 'paid',
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);

  await db.query(`
    CREATE TABLE IF NOT EXISTS intercity_cs_rides (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      driver_id UUID NOT NULL,
      from_city TEXT NOT NULL,
      to_city TEXT NOT NULL,
      route_km NUMERIC(10,2) DEFAULT 0,
      departure_date DATE NOT NULL,
      departure_time TIME NOT NULL,
      total_seats INTEGER NOT NULL DEFAULT 1,
      vehicle_number TEXT DEFAULT '',
      vehicle_model TEXT DEFAULT '',
      note TEXT DEFAULT '',
      fare_per_seat NUMERIC(10,2) NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'active',
      is_active BOOLEAN DEFAULT true,
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);

  await db.query(`
    CREATE TABLE IF NOT EXISTS intercity_cs_bookings (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      ride_id UUID NOT NULL,
      customer_id UUID NOT NULL,
      seats_booked INTEGER NOT NULL DEFAULT 1,
      total_fare NUMERIC(10,2) NOT NULL DEFAULT 0,
      status TEXT NOT NULL DEFAULT 'confirmed',
      payment_status TEXT NOT NULL DEFAULT 'paid',
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);

  const routeCount = await db.query('SELECT COUNT(*)::int AS c FROM intercity_routes');
  if ((routeCount.rows[0]?.c || 0) === 0) {
    await db.query(`
      INSERT INTO intercity_routes (from_city, to_city, estimated_km, base_fare, fare_per_km, toll_charges, is_active)
      VALUES ('Hyderabad', 'Vijayawada', 275, 250, 12, 100, true)
    `);
  }

  await db.query(`
    INSERT INTO intercity_cs_settings (key_name, value)
    VALUES ('rate_per_km_per_seat', '3.5')
    ON CONFLICT (key_name) DO NOTHING
  `);

  console.log('sharing_intercity_schema_ok');
  await db.end();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
