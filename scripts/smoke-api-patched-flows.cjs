const { Client } = require('pg');

const BASE = process.env.SMOKE_BASE_URL || 'http://localhost:5000';

async function postJson(path, body, token) {
  const res = await fetch(`${BASE}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  let json = {};
  try {
    json = text ? JSON.parse(text) : {};
  } catch (_) {
    json = { raw: text };
  }
  return { status: res.status, body: json };
}

async function getJson(path, token) {
  const res = await fetch(`${BASE}${path}`, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  });
  const text = await res.text();
  let json = {};
  try {
    json = text ? JSON.parse(text) : {};
  } catch (_) {
    json = { raw: text };
  }
  return { status: res.status, body: json };
}

async function getLatestOtp(db, phone) {
  const r = await db.query(
    'SELECT otp FROM otp_logs WHERE phone=$1 ORDER BY created_at DESC LIMIT 1',
    [phone]
  );
  return r.rows[0]?.otp;
}

async function issueTestToken(db, phone, userType, name) {
  const existing = await db.query(
    'SELECT id FROM users WHERE phone=$1 AND user_type=$2 LIMIT 1',
    [phone, userType]
  );
  let userId = existing.rows[0]?.id;
  if (!userId) {
    const inserted = await db.query(
      'INSERT INTO users (full_name, phone, user_type, is_active, wallet_balance) VALUES ($1,$2,$3,true,10000) RETURNING id',
      [name, phone, userType]
    );
    userId = inserted.rows[0].id;
  }
  const token = `${userId}:${Math.random().toString(16).slice(2)}${Date.now().toString(16)}`;
  await db.query('UPDATE users SET auth_token=$1, is_active=true WHERE id=$2::uuid', [token, userId]);
  return token;
}

(async () => {
  const db = new Client({ connectionString: process.env.DATABASE_URL });
  await db.connect();

  const ts = Date.now().toString().slice(-8);
  const customerPhone = `9${ts}1`;
  const driverPhone = `8${ts}2`;

  const customerToken = await issueTestToken(db, customerPhone, 'customer', 'Smoke Customer');
  const driverToken = await issueTestToken(db, driverPhone, 'driver', 'Smoke Driver');

  const routesResp = await getJson('/api/intercity-routes');
  if (routesResp.status !== 200 || !Array.isArray(routesResp.body)) {
    throw new Error(`intercity-routes failed: ${JSON.stringify(routesResp.body)}`);
  }
  const route = routesResp.body.find((r) => r.isActive) || routesResp.body[0];
  if (!route?.id) throw new Error('No intercity route found');

  const intercityBook = await postJson(
    '/api/app/customer/intercity-book',
    {
      routeId: route.id,
      scheduledAt: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      passengers: 3,
      paymentMethod: 'cash',
      pickupAddress: route.fromCity || route.from_city,
      destinationAddress: route.toCity || route.to_city,
    },
    customerToken
  );

  const badSeats = await postJson(
    '/api/app/customer/car-sharing/book',
    {
      rideId: '00000000-0000-0000-0000-000000000001',
      seatsBooked: 0,
    },
    customerToken
  );

  const badDeliveryTrip = await postJson(
    '/api/app/driver/verify-delivery-otp',
    {
      tripId: 'bad-id',
      otp: '1234',
    },
    driverToken
  );

  const summary = {
    phones: { customerPhone, driverPhone },
    intercity: {
      status: intercityBook.status,
      estimatedFare: intercityBook.body?.estimatedFare,
      farePerPassenger: intercityBook.body?.farePerPassenger,
      passengers: intercityBook.body?.passengers,
    },
    carSharingBadSeats: {
      status: badSeats.status,
      message: badSeats.body?.message,
    },
    deliveryOtpBadTrip: {
      status: badDeliveryTrip.status,
      message: badDeliveryTrip.body?.message,
    },
  };

  console.log(JSON.stringify(summary, null, 2));
  await db.end();
})().catch(async (e) => {
  console.error('SMOKE_FAIL', e?.message || e);
  process.exit(1);
});
