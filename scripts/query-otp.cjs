const { Client } = require('pg');

(async () => {
  const phone = process.argv[2];
  const c = new Client({ connectionString: process.env.DATABASE_URL });
  await c.connect();
  const r = await c.query(
    'SELECT phone, otp, user_type, is_used, expires_at, created_at FROM otp_logs WHERE phone = $1 ORDER BY created_at DESC LIMIT 5',
    [phone]
  );
  console.log(JSON.stringify(r.rows, null, 2));
  await c.end();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
