/* Basic smoke checks for local backend */
const baseUrl = process.env.SMOKE_BASE_URL || 'http://localhost:5000';

async function check(name, fn) {
  try {
    await fn();
    console.log(`[PASS] ${name}`);
    return true;
  } catch (e) {
    console.error(`[FAIL] ${name}: ${e.message}`);
    return false;
  }
}

async function getJson(path) {
  const res = await fetch(`${baseUrl}${path}`);
  const text = await res.text();
  let body = null;
  try { body = JSON.parse(text); } catch { body = text; }
  return { res, body };
}

(async () => {
  const results = [];

  results.push(await check('health endpoint', async () => {
    const { res, body } = await getJson('/api/health');
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    if (!body || body.status !== 'ok') throw new Error('status is not ok');
  }));

  results.push(await check('app configs endpoint', async () => {
    const { res, body } = await getJson('/api/app/configs');
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    if (!body || !Array.isArray(body.vehicleCategories)) {
      throw new Error('vehicleCategories missing');
    }
  }));

  results.push(await check('offers endpoint requires auth', async () => {
    const { res } = await getJson('/api/app/customer/offers');
    if (![401, 403].includes(res.status)) {
      throw new Error(`expected 401/403 got ${res.status}`);
    }
  }));

  const passCount = results.filter(Boolean).length;
  console.log(`\nSmoke result: ${passCount}/${results.length} checks passed`);
  if (passCount !== results.length) process.exit(1);
})();
