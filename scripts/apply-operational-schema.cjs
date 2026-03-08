const fs = require('fs');
const { Client } = require('pg');

const sql = fs.readFileSync('migrations/0001_operational_schema_hardening.sql', 'utf8');
const urls = [
  process.env.DATABASE_URL,
  'postgresql://jago@localhost:55432/jago_dev',
  'postgresql://jago:jago@localhost:5432/jago_dev',
].filter(Boolean);

(async () => {
  for (const url of urls) {
    const client = new Client({ connectionString: url });
    try {
      await client.connect();
      await client.query(sql);
      console.log(`APPLIED ${url}`);
    } catch (error) {
      console.log(`SKIPPED ${url} ${error.message}`);
    } finally {
      try {
        await client.end();
      } catch {}
    }
  }
})().catch((error) => {
  console.error(error);
  process.exit(1);
});