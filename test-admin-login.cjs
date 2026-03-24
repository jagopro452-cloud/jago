const http = require('http');

// ⚠️ SECURITY WARNING: Do NOT use hardcoded credentials in production!
// Load from environment variables in production:
// - ADMIN_EMAIL (required)
// - ADMIN_PASSWORD (required)
// - NODE_ENV=production (enables security checks)
//
// This test script is for LOCAL DEVELOPMENT ONLY
// In production, use: ADMIN_EMAIL=your@email.com ADMIN_PASSWORD=securepass npm start

const adminEmail = process.env.ADMIN_EMAIL || 'superadmin@jago.com';  // Override with env var for production
const adminPassword = process.env.ADMIN_PASSWORD || 'superadmin123';   // Override with env var for production

// Security check: warn if using defaults in production
if (process.env.NODE_ENV === 'production' && 
    (adminEmail === 'superadmin@jago.com' || adminPassword === 'superadmin123')) {
  console.error('⚠️  PRODUCTION SECURITY ERROR: Using default credentials!');
  console.error('Set ADMIN_EMAIL and ADMIN_PASSWORD environment variables before deploying.');
  process.exit(1);
}

const data = JSON.stringify({
  email: adminEmail,
  password: adminPassword
});

const options = {
  hostname: process.env.ADMIN_HOST || 'localhost',
  port: process.env.ADMIN_PORT || 5000,
  path: '/api/admin/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = http.request(options, res => {
  let body = '';
  res.on('data', chunk => {
    body += chunk;
  });
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Response:', body);
    if (res.statusCode === 200 || res.statusCode === 202) {
      console.log('✅ Admin login successful');
    } else {
      console.error('❌ Admin login failed');
    }
  });
});

req.on('error', error => {
  console.error('Error:', error);
});

req.write(data);
req.end();
