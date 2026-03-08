const { Client } = require('pg');

const urls = [
  process.env.DATABASE_URL,
  'postgresql://jago@localhost:55432/jago_dev',
  'postgresql://jago:jago@localhost:5432/jago_dev',
].filter(Boolean);

const seedSql = `
  INSERT INTO intercity_routes (
    from_city,
    to_city,
    estimated_km,
    base_fare,
    fare_per_km,
    toll_charges,
    is_active
  )
  SELECT 'Hyderabad', 'Vijayawada', 275, 300, 12, 80, true
  WHERE NOT EXISTS (
    SELECT 1 FROM intercity_routes WHERE is_active = true
  )
`;

(async () => {
  for (const url of urls) {
    const client = new Client({ connectionString: url });
    try {
      await client.connect();
      await client.query(seedSql);
      const result = await client.query('SELECT COUNT(*)::int AS count FROM intercity_routes WHERE is_active = true');
      console.log(`SEEDED_OK ${url} active_routes=${result.rows[0].count}`);
    } catch (error) {
      console.log(`SEEDED_SKIP ${url} ${error.message}`);
    } finally {
      try { await client.end(); } catch {}
    }
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
