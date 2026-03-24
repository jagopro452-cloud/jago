# QUICKFIX: Code Changes for Critical Issues

## 1. FIX BCRYPT ROUNDS INCONSISTENCY

Create new file: `server/utils/crypto.ts`

```typescript
import bcrypt from "bcryptjs";

export const PASSWORD_HASH_ROUNDS = 12;

/**
 * Hash a password with consistent rounds (12)
 * Never use bcrypt.hash directly - use this wrapper
 */
export async function hashPassword(password: string): Promise<string> {
  const trimmed = String(password || "").trim();
  if (!trimmed) throw new Error("Password cannot be empty");
  return bcrypt.hash(trimmed, PASSWORD_HASH_ROUNDS);
}

/**
 * Verify a password against its hash
 * Returns false instead of throwing on invalid hash
 */
export async function verifyPassword(
  password: string,
  hash: string
): Promise<boolean> {
  try {
    return await bcrypt.compare(String(password || "").trim(), hash);
  } catch (err) {
    console.error("[crypto] Password verification error:", (err as any).message);
    return false;
  }
}
```

### Replace all bcrypt.hash calls in server/routes.ts:

**Line 801** (Admin bootstrap):
```typescript
// OLD
const hash = await bcrypt.hash(adminPassword, 10);

// NEW
import { hashPassword } from "./utils/crypto";
const hash = await hashPassword(adminPassword);
```

**Line 2309** (Test user):
```typescript
// OLD
const pwHash = await bcrypt.hash("Test@123", 10);

// NEW
const pwHash = await hashPassword("Test@123");
```

**Line 2971** (Force reset):
```typescript
// OLD
const hash = await bcrypt.hash(adminPassword, 10);

// NEW
const hash = await hashPassword(adminPassword);
```

**Lines 3192, 3208, 3246** (Password reset/change):
```typescript
// OLD
const hashedPassword = await bcrypt.hash(newPassword, 12);

// NEW
const hashedPassword = await hashPassword(newPassword);
```

**All other bcrypt.hash calls** - Replace with:
```typescript
const hash = await hashPassword(password);
```

### Replace all bcrypt.compare calls:

**Line 3059** (Admin login):
```typescript
// OLD
const passwordValid = await bcrypt.compare(String(password), admin.password);

// NEW
import { verifyPassword } from "./utils/crypto";
const passwordValid = await verifyPassword(password, admin.password);
```

---

## 2. FIX DATABASE POOL CONFIGURATION

**File**: `server/db.ts`

Replace the `Pool` initialization (lines 14-20):

```typescript
// OLD
export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: isLocalDb ? false : { rejectUnauthorized: false },
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
  allowExitOnIdle: false,
});

// NEW
const isProduction = process.env.NODE_ENV === "production";
const maxConnections = isProduction ? 50 : 20; // Scale for multiple instances

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: isLocalDb ? false : { rejectUnauthorized: false },
  max: maxConnections,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,  // Fail fast instead of hanging
  allowExitOnIdle: false,
  application_name: "jago-api",    // For debugging in pg_stat_statements
});

// Add pool event logging
pool.on("error", (err: Error) => {
  console.error("[DB] Unexpected connection pool error:", err.message);
});

pool.on("connect", () => {
  console.debug("[DB] New connection established");
});
```

---

## 3. ENABLE 2FA IN PRODUCTION

**File**: `.do/app.yaml`

Replace lines 59 and add ADMIN_PHONE:

```yaml
# OLD
- key: ADMIN_2FA_REQUIRED
  value: "false"

# NEW
- key: ADMIN_2FA_REQUIRED
  value: "true"

# ADD (if not present)
- key: ADMIN_PHONE
  value: "+91XXXXXXXXXX"  # Set in DigitalOcean dashboard
  type: SECRET
```

---

## 4. CREATE ADMIN SCHEMA MIGRATION

**New File**: `migrations/0008_admin_login_system.sql`

```sql
-- Admin user management and login OTP system
CREATE TABLE IF NOT EXISTS admins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  email VARCHAR(191) NOT NULL UNIQUE,
  password VARCHAR(191) NOT NULL,
  role VARCHAR(50) NOT NULL DEFAULT 'admin',
  is_active BOOLEAN NOT NULL DEFAULT true,
  auth_token TEXT,
  auth_token_expires_at TIMESTAMP,
  last_login_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Login OTP for 2FA
CREATE TABLE IF NOT EXISTS admin_login_otp (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
  otp VARCHAR(10) NOT NULL,
  is_used BOOLEAN NOT NULL DEFAULT false,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Password reset OTP
CREATE TABLE IF NOT EXISTS admin_otp_resets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(191) NOT NULL,
  otp VARCHAR(10) NOT NULL,
  is_used BOOLEAN NOT NULL DEFAULT false,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_admins_email 
  ON admins(LOWER(email));

CREATE INDEX IF NOT EXISTS idx_admins_auth_token 
  ON admins(auth_token);

CREATE INDEX IF NOT EXISTS idx_admin_login_otp_admin_created 
  ON admin_login_otp(admin_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_login_otp_not_used
  ON admin_login_otp(admin_id, expires_at DESC) 
  WHERE is_used = false;

CREATE INDEX IF NOT EXISTS idx_admin_otp_resets_email 
  ON admin_otp_resets(LOWER(email), expires_at DESC);
```

### Remove dynamic table creation:

**File**: `server/routes.ts` - Remove lines 760-790 (ensureAdminExists CREATE TABLE block)

```typescript
// DELETE THESE LINES:
try {
  await rawDb.execute(rawSql`
    CREATE TABLE IF NOT EXISTS admins (
      ...
    )
  `);
} catch (e: any) { console.error("[admin] create admins table:", formatDbError(e)); }

// AND THESE ALTER TABLE calls:
await rawDb.execute(rawSql`ALTER TABLE admins ADD COLUMN IF NOT EXISTS auth_token TEXT`).catch(dbCatch("db"));
await rawDb.execute(rawSql`ALTER TABLE admins ADD COLUMN IF NOT EXISTS auth_token_expires_at TIMESTAMP`).catch(dbCatch("db"));
// ... etc
```

---

## 5. INCREASE DB INDEXES FOR PERFORMANCE

**New File**: `migrations/0009_query_performance_indexes.sql`

```sql
-- High-traffic query indexes
CREATE INDEX IF NOT EXISTS idx_business_settings_key_name 
  ON business_settings(key_name);

CREATE INDEX IF NOT EXISTS idx_trip_requests_customer_created
  ON trip_requests(customer_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_trip_requests_driver_created
  ON trip_requests(driver_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_trip_requests_status
  ON trip_requests(current_status);

CREATE INDEX IF NOT EXISTS idx_driver_locations_online
  ON driver_locations(is_online) WHERE is_online = true;

CREATE INDEX IF NOT EXISTS idx_user_devices_fcm_token
  ON user_devices(user_id) WHERE fcm_token IS NOT NULL;
```

---

## 6. ADD ERROR HANDLING TO BCRYPT OPERATIONS

**File**: `server/routes.ts` line 3059

Replace:
```typescript
// OLD
const passwordValid = await bcrypt.compare(String(password), admin.password);
if (!passwordValid) return res.status(401).json({ message: "Invalid credentials" });

// NEW
import { verifyPassword } from "./utils/crypto";

let passwordValid = false;
try {
  passwordValid = await verifyPassword(password, admin.password);
} catch (hashErr: any) {
  console.error("[auth] Password verification failed:", hashErr.message);
  return res.status(500).json({ message: "Authentication service temporarily unavailable" });
}

if (!passwordValid) {
  return res.status(401).json({ message: "Invalid credentials" });
}
```

---

## DEPLOYMENT CHECKLIST

After making these changes:

```bash
# 1. Run type check
npm run check

# 2. Build
npm run build

# 3. Run migrations before deploying
npm run db:migrate

# 4. Verify admin table exists
psql $DATABASE_URL -c "SELECT * FROM admins LIMIT 1;"

# 5. Test admin login locally
curl -X POST http://localhost:5000/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@test.com","password":"testpass123"}'

# 6. In DigitalOcean dashboard:
#    - Delete .do/app.yaml secrets from env vars (if shown)
#    - Set ADMIN_PASSWORD, ADMIN_PHONE in dashboard env section
#    - Set RAZORPAY_WEBHOOK_SECRET if not already set
```

---

## VALIDATION TESTS

### Test 1: Bcrypt Rounds
```bash
# Check password created with new hash function
node -e "
const crypto = require('./server/utils/crypto.ts');
crypto.hashPassword('test123').then(h => {
  console.log('Hash rounds:', h.substring(0, 7));  // Should be \$2b\$12
});
"
```

### Test 2: DB Pool
```bash
curl http://localhost:5000/api/health -w '\nResponse time: %{time_total}s\n'
# Should respond <100ms
```

### Test 3: Admin Login
```bash
curl -X POST http://localhost:5000/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "email":"kiranatmakuri518@gmail.com",
    "password":"Greeshmant@2023"
  }' \
  -w '\nResponse time: %{time_total}s\n'
# Should return token and complete in <500ms
```

---

## FILES MODIFIED SUMMARY

| File | Changes | Lines |
|------|---------|-------|
| server/utils/crypto.ts | NEW | - |
| server/db.ts | Pool config | 14-20 |
| server/routes.ts | Replace bcrypt calls | 801, 2309, 2971, 3192, 3208, 3246, 3059, etc |
| .do/app.yaml | 2FA enabled, ADMIN_PHONE added | 59, +1 |
| migrations/0008_admin_login_system.sql | NEW | - |
| migrations/0009_query_performance_indexes.sql | NEW | - |

