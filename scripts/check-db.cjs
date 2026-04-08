const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

// Read .env manually
const envPath = path.join(__dirname, '..', '.env');
const envContent = fs.readFileSync(envPath, 'utf8');
const dbMatch = envContent.match(/DATABASE_URL=(.+)/);
const DATABASE_URL = dbMatch ? dbMatch[1].trim() : process.env.DATABASE_URL;

const pool = new Pool({ 
  connectionString: DATABASE_URL,
  connectionTimeoutMillis: 30000 
});

async function check() {
  try {
    console.log('Connecting to Neon DB...');
    const tables = await pool.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
      ORDER BY table_name
    `);
    console.log('\n=== Tables in Neon DB ===\n');
    for (const t of tables.rows) {
      try {
        const countRes = await pool.query(`SELECT COUNT(*) as cnt FROM "${t.table_name}"`);
        const cnt = countRes.rows[0].cnt;
        if (parseInt(cnt) > 0) {
          console.log(`  ✓ ${t.table_name}: ${cnt} rows`);
        } else {
          console.log(`    ${t.table_name}: empty`);
        }
      } catch(e) {
        console.log(`  ✗ ${t.table_name}: error - ${e.message}`);
      }
    }
    console.log('\n=== Critical Data Summary ===\n');
    
    // Check users
    const users = await pool.query(`SELECT user_type, COUNT(*) as cnt FROM users GROUP BY user_type`).catch(() => ({rows:[]}));
    console.log('Users:', users.rows.map(r => `${r.user_type}: ${r.cnt}`).join(', ') || 'none');
    
    // Check trips
    const trips = await pool.query(`SELECT current_status, COUNT(*) as cnt FROM trip_requests GROUP BY current_status`).catch(() => ({rows:[]}));
    console.log('Trips:', trips.rows.map(r => `${r.current_status}: ${r.cnt}`).join(', ') || 'none');
    
    // Check admins
    const admins = await pool.query(`SELECT email FROM admins`).catch(() => ({rows:[]}));
    console.log('Admins:', admins.rows.map(r => r.email).join(', ') || 'none');

    await pool.end();
    console.log('\nDone.');
  } catch(e) { 
    console.error('Connection Error:', e.message); 
    process.exit(1);
  }
}
check();
