#!/usr/bin/env node
import pg from 'pg';

const { Client } = pg;

async function main() {
  const tripId = process.argv[2] || null;
  const intervalMs = Number(process.argv[3] || 2000);
  const conn = process.env.DATABASE_URL;

  if (!conn) {
    console.error('[watch-trip] DATABASE_URL is not set');
    process.exit(1);
  }

  const client = new Client({ connectionString: conn, ssl: { rejectUnauthorized: false } });
  await client.connect();

  console.log(`[watch-trip] connected, polling every ${intervalMs}ms ${tripId ? `(tripId=${tripId})` : '(active trips)'}`);

  const query = tripId
    ? `SELECT id, current_status, driver_id, customer_id, created_at, driver_accepted_at, driver_arrived_at, ride_started_at, ride_ended_at, updated_at\n       FROM trip_requests\n       WHERE id = $1::uuid\n       LIMIT 1`
    : `SELECT id, current_status, driver_id, customer_id, created_at, driver_accepted_at, driver_arrived_at, ride_started_at, ride_ended_at, updated_at\n       FROM trip_requests\n       WHERE current_status IN ('searching','driver_assigned','accepted','arrived','on_the_way','payment_pending')\n       ORDER BY updated_at DESC\n       LIMIT 10`;

  let last = '';

  const tick = async () => {
    try {
      const r = tripId ? await client.query(query, [tripId]) : await client.query(query);
      const out = JSON.stringify(r.rows, null, 2);
      if (out !== last) {
        last = out;
        console.log(`\n[watch-trip] ${new Date().toISOString()}`);
        console.log(out);
      }
    } catch (e) {
      console.error('[watch-trip] query error:', e.message);
    }
  };

  await tick();
  const t = setInterval(tick, intervalMs);

  process.on('SIGINT', async () => {
    clearInterval(t);
    await client.end();
    console.log('\n[watch-trip] stopped');
    process.exit(0);
  });
}

main().catch((e) => {
  console.error('[watch-trip] fatal:', e.message);
  process.exit(1);
});
