import bcrypt from 'bcryptjs';
import pg from 'pg';
const { Pool } = pg;
const pool = new Pool({ connectionString: 'postgresql://jago:jago@localhost:5432/jago_dev' });

async function main() {
  const hash = await bcrypt.hash('Admin@1234', 10);
  await pool.query('UPDATE admins SET password = $1, is_active = true WHERE email = $2', [hash, 'admin@jago.in']);
  console.log('Admin password reset to Admin@1234, hash length:', hash.length);
  await pool.end();
}

main().catch(e => { console.error(e); pool.end(); });
