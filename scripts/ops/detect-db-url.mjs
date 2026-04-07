import pg from 'pg';

const hosts = ['localhost', '127.0.0.1'];
const ports = [5432];
const users = ['postgres', 'kiran', 'admin'];
const passwords = ['', 'postgres', 'admin', 'password'];
const dbs = ['postgres', 'jago', 'jago_main', 'jagopro', 'rest_express'];

function buildUrl({ user, password, host, port, db }) {
  const auth = password ? `${encodeURIComponent(user)}:${encodeURIComponent(password)}` : encodeURIComponent(user);
  return `postgresql://${auth}@${host}:${port}/${db}`;
}

async function canConnect(url) {
  const client = new pg.Client({ connectionString: url, ssl: false, connectionTimeoutMillis: 1500 });
  try {
    await client.connect();
    await client.query('SELECT 1');
    await client.end();
    return true;
  } catch {
    try { await client.end(); } catch {}
    return false;
  }
}

async function main() {
  const candidates = [];
  for (const host of hosts) for (const port of ports) for (const user of users) for (const password of passwords) for (const db of dbs) {
    candidates.push(buildUrl({ user, password, host, port, db }));
  }

  for (const url of candidates) {
    // eslint-disable-next-line no-await-in-loop
    const ok = await canConnect(url);
    if (ok) {
      console.log(url);
      process.exit(0);
    }
  }

  console.error('NO_WORKING_DB_URL');
  process.exit(1);
}

main();
