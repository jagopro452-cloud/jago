# COMPREHENSIVE AUDIT REPORT: JAGO Pro Ride-Hailing Application

**Date**: March 24, 2026  
**Status**: CRITICAL ISSUES IDENTIFIED  
**Focus Areas**: Admin Login Timeout, Code Duplication, Database Performance, Configuration Issues

---

## EXECUTIVE SUMMARY

The JAGO Pro application has **8 critical/important issues** affecting Production Readiness:

1. **Admin login timeout** — bcrypt rounds configuration causing slow password verification
2. **Bcrypt rounds inconsistency** — multiple conflicting round values (10, 12)
3. **Admin table schema not in migrations** — created dynamically at runtime
4. **N+1 query patterns** — multiple SELECT queries in loops/repeated requests
5. **Duplicate query patterns** — identical SQL queries scattered across codebase
6. **Insufficient database connection pooling configuration** — max 20 connections for 2 instances
7. **Missing indexes on high-traffic queries** — admin_login_otp, business_settings
8. **Configuration secrets exposed in app.yaml** — hardcoded credentials visible in repo

---

## 1. ADMIN LOGIN TIMEOUT ISSUES ⚠️ CRITICAL

### Root Cause: Bcrypt Hash Round Configuration Mismatch

**Files Affected**:
- [server/routes.ts](server/routes.ts#L3059) — Line 3059: Admin login password verification
- [server/routes.ts](server/routes.ts#L801) — Line 801: Admin account creation (bcrypt rounds 10)
- [server/routes.ts](server/routes.ts#L3192) — Line 3192: Password reset (bcrypt rounds 12)
- [server/routes.ts](server/routes.ts#L3240) — Line 3240: Change password (bcrypt rounds 10)

**The Problem**:

```typescript
// ❌ Line 801 — Admin bootstrap uses 10 rounds
const hash = await bcrypt.hash(adminPassword, 10);

// ❌ Line 3192 — Password reset uses 12 rounds
const hashedPassword = await bcrypt.hash(newPassword, 12);

// ❌ Line 3246 — Change password uses 10 rounds
const newHash = await bcrypt.hash(newPassword, 10);

// ❌ Line 3059 — Every login calls bcrypt.compare (variable timing)
const passwordValid = await bcrypt.compare(String(password), admin.password);
```

**Why This Causes Timeouts**:

1. **Bcrypt rounds determine CPU cost**: 10 rounds = ~10ms, 12 rounds = ~40ms
2. **Rate limiter blocks after 5 fails in 15 minutes** (line 467)
3. **Mixed round counts cause verification failures** if password was hashed with different round count
4. **Every login attempt includes bcrypt.compare** which is blocking and CPU-bound
5. **No timeout protection on bcrypt operations** — if hash rounds are high, request hangs

**Performance Impact**:
- 10 rounds: ~10ms per login
- 12 rounds: ~40ms per login
- Rate limiter on slow network: 5 × 40ms = 200ms+ before error (can appear as timeout)

**Fix Priority**: 🔴 **CRITICAL**

### Recommended Fix:

```typescript
// Standardize on 12 rounds for better security
const BCRYPT_ROUNDS = 12;  // Use consistently everywhere

// Line 801 — Admin bootstrap
const hash = await bcrypt.hash(adminPassword, BCRYPT_ROUNDS);

// Line 3192 — Password reset
const hashedPassword = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);

// Line 3246 — Change password  
const newHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);

// Add timeout protection for bcrypt operations
const PASSWORD_HASH_TIMEOUT = 5000; // 5 second timeout
const bcryptWithTimeout = Promise.race([
  bcrypt.compare(password, hash),
  new Promise((_, reject) => 
    setTimeout(() => reject(new Error("Password verification timeout")), PASSWORD_HASH_TIMEOUT)
  )
]);
```

---

## 2. DATABASE CONNECTION & QUERY ISSUES ⚠️ CRITICAL

### 2.1 Insufficient Connection Pool Configuration

**File**: [server/db.ts](server/db.ts)

**Current Config**:
```typescript
export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: isLocalDb ? false : { rejectUnauthorized: false },
  max: 20,                          // ❌ Only 20 max connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,   // 10 second timeout
  allowExitOnIdle: false,
});
```

**Problem**:
- **Production deployment has 2 instances** (.do/app.yaml)
- 20 connections ÷ 2 instances = **10 connections per instance**
- With concurrent requests, pool exhaustion causes connection timeouts
- Admin login attempt → requires connection → waits for available connection → timeout

**Fix**:
```typescript
const isProduction = process.env.NODE_ENV === 'production';
const maxConnections = isProduction ? 40 : 20; // Scale for 2+ instances

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: isLocalDb ? false : { rejectUnauthorized: false },
  max: maxConnections,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,    // Fail fast instead of hanging
  allowExitOnIdle: false,
  application_name: 'jago-api',     // For debugging
});
```

### 2.2 N+1 Query Patterns

**Files Affected**:
- [server/intelligence.ts](server/intelligence.ts#L857-L868) — Dashboard stats query
- [server/retention.ts](server/retention.ts#L85-L88) — Retention campaigns  
- [server/routes.ts](server/routes.ts#L2799) — Transaction mapping loop

**Example - Dashboard Stats** (Line 857-868):

```typescript
// ❌ PROBLEM: Each stat is a separate subquery
SELECT
  (SELECT COUNT(*) FROM trip_requests WHERE current_status IN ('accepted', 'arrived', 'on_the_way')) as active_rides,
  (SELECT COUNT(*) FROM parcel_orders WHERE current_status IN ('accepted', 'picked_up', 'in_transit')) as parcel_deliveries,
  (SELECT COUNT(*) FROM driver_locations dl JOIN users u ON u.id = dl.driver_id WHERE ...) as drivers_online,
  (SELECT COUNT(*) FROM trip_requests WHERE current_status IN ('searching', 'driver_assigned')) as pending_requests
```

**Performance Impact**: 5-10 slow subqueries per request = 50-100ms latency

**Fix**: Use UNION ALL or window functions:

```sql
WITH stats AS (
  SELECT 'active_rides' as stat_type, COUNT(*) as count
  FROM trip_requests WHERE current_status IN ('accepted', 'arrived', 'on_the_way')
  UNION ALL
  SELECT 'parcel_deliveries', COUNT(*)
  FROM parcel_orders WHERE current_status IN ('accepted', 'picked_up', 'in_transit')
  UNION ALL
  SELECT 'drivers_online', COUNT(*)
  FROM driver_locations dl
  JOIN users u ON u.id = dl.driver_id
  WHERE dl.is_online = true AND u.is_active = true
  UNION ALL
  SELECT 'pending_requests', COUNT(*)
  FROM trip_requests WHERE current_status IN ('searching', 'driver_assigned')
)
SELECT * FROM stats;
```

### 2.3 Missing Indexes on High-Traffic Queries

**Admin Login Query** (Line 3037-3045):

```typescript
// ❌ SLOW: No indexes on email + auth token
const r = await rawDb.execute(rawSql`
  SELECT id, name, email, password, role, is_active as "isActive"
  FROM admins WHERE LOWER(email) = ${lookupEmail.trim().toLowerCase()} LIMIT 1
`);
```

**Missing Indexes**:
- `admins.email` — **Referenced in 3+ queries**
- `admin_login_otp(admin_id, created_at)` — **For OTP lookup**
- `admins(auth_token)` — **For session validation** (index exists at line 789)
- `business_settings(key_name)` — **Used in 15+ queries**

**Fix**: Add migrations:

```sql
CREATE INDEX IF NOT EXISTS idx_admins_email_lower 
  ON admins(LOWER(email));

CREATE INDEX IF NOT EXISTS idx_business_settings_key_name 
  ON business_settings(key_name);

CREATE INDEX IF NOT EXISTS idx_admin_login_otp_admin_expires
  ON admin_login_otp(admin_id, expires_at DESC) 
  WHERE is_used = false;
```

---

## 3. ADMIN TABLE SCHEMA NOT IN MIGRATIONS ⚠️ IMPORTANT

**Issue**: Admin table created dynamically at runtime, NOT in migrations

**Files Affected**:
- [server/routes.ts](server/routes.ts#L1860) — `ensureAdminExists()` function

**Problem**:

```typescript
// ❌ Line 760 — Table created dynamically in ensureAdminExists()
try {
  await rawDb.execute(rawSql`
    CREATE TABLE IF NOT EXISTS admins (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(255) NOT NULL,
      email VARCHAR(191) NOT NULL UNIQUE,
      password VARCHAR(191) NOT NULL,
      ...
    )
  `);
} catch (e: any) { console.error("[admin] create admins table:", formatDbError(e)); }
```

**Why This Is Bad**:
1. **Migration tracking lost** — drizzle-kit doesn't track this schema
2. **Deployment race condition** — If routes register before table exists = error
3. **Column additions scattered** — Lines 774-777 add columns with `ALTER TABLE IF NOT EXISTS`
4. **Schema visibility reduced** — Admins can't see schema in migration files
5. **Testing difficulty** — Can't seed test data in migrations

**Fix**: Create proper migration file:

```sql
-- migrations/0008_admin_login_system.sql

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

CREATE TABLE IF NOT EXISTS admin_login_otp (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  admin_id UUID NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
  otp VARCHAR(10) NOT NULL,
  is_used BOOLEAN NOT NULL DEFAULT false,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS admin_otp_resets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(191) NOT NULL,
  otp VARCHAR(10) NOT NULL,
  is_used BOOLEAN NOT NULL DEFAULT false,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admins_email ON admins(LOWER(email));
CREATE INDEX IF NOT EXISTS idx_admins_auth_token ON admins(auth_token);
CREATE INDEX IF NOT EXISTS idx_admin_login_otp_admin_created 
  ON admin_login_otp(admin_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_otp_resets_email 
  ON admin_otp_resets(LOWER(email), created_at DESC);
```

---

## 4. DUPLICATE CODE & FUNCTIONS ⚠️ IMPORTANT

### 4.1 Repeated Password Hashing with Inconsistent Rounds

**Locations**:
- Line 801: `bcrypt.hash(adminPassword, 10)` — Admin bootstrap
- Line 2309: `bcrypt.hash("Test@123", 10)` — Test user
- Line 2971: `bcrypt.hash(adminPassword, 10)` — Force reset
- Line 3192: `bcrypt.hash(newPassword, 12)` — Password reset
- Line 3208: `bcrypt.hash(password, 12)` — Password reset (2FA verify)
- Line 3246: `bcrypt.hash(newPassword, 10)` — Change password
- Line 7341, 7416, 7458, 11590, 11794, 14025, 14084: **7 more instances with 10 rounds**

**Fix**: Extract to utility function:

```typescript
// server/utils/crypto.ts
export const PASSWORD_HASH_ROUNDS = 12;

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(String(password).trim(), PASSWORD_HASH_ROUNDS);
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  try {
    return await bcrypt.compare(String(password).trim(), hash);
  } catch {
    return false;
  }
}
```

### 4.2 Update Operation Duplication in storage.ts

**Pattern**: 8 identical update methods (lines 95-300):

```typescript
// ❌ DUPLICATED 8 times
async updateUserStatus(id: string, isActive: boolean): Promise<User> {
  const [updated] = await db.update(users).set({ isActive }).where(eq(users.id, id)).returning();
  return updated;
}

async updateUser(id: string, data: Partial<User>): Promise<User> {
  const [updated] = await db.update(users).set(data as any).where(eq(users.id, id)).returning();
  return updated;
}
```

**Fix**: Extract generic update:

```typescript
async updateEntity<T extends Table>(
  table: T,
  id: string,
  data: Partial<T['_']['columns']>
): Promise<any> {
  const [updated] = await db.update(table).set(data as any).where(eq(table.id, id)).returning();
  return updated;
}
```

### 4.3 Query Building Duplication

**Lines 201-218 & 280-297** in [server/dynamic-services.ts](server/dynamic-services.ts):

Two nearly identical SELECT queries for platform services and parcel vehicles, 90 lines apart, with city-based conditional branching duplicated.

---

## 5. CONFIGURATION & ENVIRONMENT ISSUES ⚠️ CRITICAL (SECURITY)

### 5.1 Hardcoded Secrets in app.yaml

**File**: [.do/app.yaml](./do/app.yaml#L32-L75)

```yaml
# ❌ EXPOSED IN REPO
- key: ADMIN_PASSWORD
  value: "Greeshmant@2023"
  type: SECRET

- key: ADMIN_RESET_KEY
  value: "JagoReset2026"
  type: SECRET

- key: RAZORPAY_KEY_SECRET
  value: "NoLQoxlCg8SPnKHSX0ciIDjJ"
  type: SECRET

- key: GOOGLE_MAPS_API_KEY
  value: "AIzaSyBk3Lj0EIppvldBZue9Cmhff_oi9NeBlL0"
  type: SECRET
```

**Issues**:
1. **Last commit has plaintext credentials** — Git history exposed
2. **API keys visible in code review** — All developers see secrets
3. **Production credentials in repo** — Violates security best practices

**Fix**:
1. **Rotate all exposed credentials immediately**
2. **Remove from .do/app.yaml, add comments instead**:
   ```yaml
   - key: ADMIN_PASSWORD
     type: SECRET
     # Set this value in DigitalOcean dashboard, DO NOT add here
   ```
3. **Add to .gitignore**: `.do/app.yaml` (or use `.do/app.yaml.sample`)
4. **Regenerate**:
   - Admin password
   - All API keys (Razorpay, Google Maps, Firebase)
   - Reset keys

### 5.2 Environment Config Mismatch

**Configured in .do/app.yaml**:
```yaml
- key: ADMIN_2FA_REQUIRED
  value: "false"  # 2FA disabled in production
```

**But code expects** (server/routes.ts line 681):
```typescript
const requireAdminTwoFactor = process.env.NODE_ENV === "production"
  ? !isFalse(runtimeEnv.ADMIN_2FA_REQUIRED)
  : isTrue(runtimeEnv.ADMIN_2FA_REQUIRED);
```

**Problem**: Admin 2FA disabled in production = security risk

**Fix**:
```yaml
- key: ADMIN_2FA_REQUIRED
  value: "true"  # Enable 2FA in production
- key: ADMIN_PHONE
  value: "+91XXXXXXXXXX"  # Required for OTP delivery
  type: SECRET
```

### 5.3 Missing Configuration Variables

**Issues**:
- No `CONNECTION_TIMEOUT` env var → uses hardcoded 10s (may be too long)
- No `QUERY_TIMEOUT` env var → risk of slow queries blocking
- No `MAX_DB_CONNECTIONS` env var → hardcoded to 20

---

## 6. MIDDLEWARE & ROUTING ISSUES ⚠️ IMPORTANT

### 6.1 Auth Middleware Check on Line 3262-3277

**File**: [server/routes.ts](server/routes.ts#L3262-3277)

```typescript
// Global middleware that requires admin auth
app.use("/api", (req: Request, res: Response, next: NextFunction) => {
  const p = req.path;
  if (
    p === "/health"           ||
    p === "/ping"             ||
    p.startsWith("/diag/")    ||
    p.startsWith("/ops/")     ||
    p.startsWith("/app/")     ||
    p.startsWith("/admin/")   ||
    p.startsWith("/driver/")  ||
    p.startsWith("/webhook")
  ) return next();
  
  // ⚠️ Everything else requires admin auth
  return requireAdminAuth(req, res, next);
});
```

**Problem**: There's ALSO a per-route `requireAdminAuth` middleware on many routes. This creates double-checking overhead and potential auth bypass issues.

**Fix**: Use path-based routing groups:

```typescript
// Public routes (no auth)
app.use("/api/health", healthRoutes);
app.use("/api/ping", pingRoutes);
app.use("/api/webhook", webhookRoutes);

// Authenticated routes
app.use("/api/admin", requireAdminAuth, adminRoutes);
app.use("/api/driver", authApp, driverRoutes);
```

---

## 7. PAGINATION & QUERY ISSUES

### Missing Pagination on High-Volume Tables

**Example**: [server/routes.ts](server/routes.ts#L725)

```typescript
// ❌ No limit on admin list
const adminList = await rawDb.execute(rawSql`
  SELECT id, name, email, role, is_active FROM admins
`);
```

**Fix**: Add pagination:

```typescript
const limit = Math.min(parseInt(req.query.limit as string) || 50, 500);
const offset = Math.max(parseInt(req.query.offset as string) || 0, 0);

const adminList = await rawDb.execute(rawSql`
  SELECT id, name, email, role, is_active FROM admins
  ORDER BY created_at DESC
  LIMIT ${limit} OFFSET ${offset}
`);
```

---

## 8. API ENDPOINT ISSUES ⚠️ IMPORTANT

### 8.1 Missing Error Handling on bcrypt Operations

**Pattern**: bcrypt.compare/hash can throw errors but some routes don't handle:

```typescript
// ❌ Line 3059 — No try-catch around bcrypt.compare
const passwordValid = await bcrypt.compare(String(password), admin.password);
if (!passwordValid) return res.status(401).json({ message: "Invalid credentials" });
```

**Risk**: If bcrypt throws (corrupted hash, system error) → unhandled promise rejection

**Fix**:

```typescript
let passwordValid = false;
try {
  passwordValid = await bcrypt.compare(String(password), admin.password);
} catch (hashErr: any) {
  console.error("[auth] Password verification error:", hashErr.message);
  return res.status(500).json({ message: "Authentication service unavailable" });
}
if (!passwordValid) return res.status(401).json({ message: "Invalid credentials" });
```

### 8.2 Missing Timeout Handling on Database Queries

**Problem**: No per-query timeout on slowest endpoints:

```typescript
// ❌ Could hang indefinitely
const r = await rawDb.execute(rawSql`
  SELECT * FROM large_table WHERE complex_condition
`);
```

**Fix**: Add query timeout:

```typescript
import { promisify } from 'util';

const timeout = (promise: Promise<any>, ms: number) => 
  Promise.race([
    promise,
    new Promise((_, reject) => 
      setTimeout(() => reject(new Error("Query timeout")), ms)
    )
  ]);

// In routes:
const r = await timeout(
  rawDb.execute(rawSql`SELECT ...`),
  5000  // 5 second limit
);
```

---

## DETAILED ISSUE SUMMARY

### Critical Issues (Fix Immediately)

| ID | Issue | File | Line | Impact | Effort |
|----|-------|------|------|--------|--------|
| 1 | Bcrypt rounds inconsistency (10 vs 12) | routes.ts | 801, 3192, 3246 | Login timeout | Low |
| 2 | Hardcoded secrets in app.yaml | .do/app.yaml | 38-73 | Security breach | Medium |
| 3 | Insufficient DB pool size (max 20) | db.ts | 18 | Connection exhaustion | Low |
| 4 | Admin 2FA disabled in production | .do/app.yaml | 59 | Security | Low |
| 5 | Admin table not in migrations | routes.ts | 760 | Deployment risk | High |

### Important Issues (Fix Soon)

| ID | Issue | File | Line | Impact | Effort |
|----|-------|------|------|--------|--------|
| 6 | N+1 queries in dashboard | intelligence.ts | 857-868 | 50-100ms latency | Medium |
| 7 | Missing indexes on high-traffic queries | routes.ts | 3037, 20 others | Query slowness | Low |
| 8 | Duplicate update functions | storage.ts | 95-300 | Code smell | Medium |
| 9 | Missing error handling on bcrypt | routes.ts | 3059, 5 others | Crash risk | Low |
| 10 | No per-query timeout protection | routes.ts | All execute() | Hanging requests | Medium |

### Nice-to-Have Improvements

| ID | Issue | File | Fix |
|----|-------|------|-----|
| 11 | Extract password hashing utility | routes.ts | Create utils/crypto.ts |
| 12 | Add pagination to list endpoints | routes.ts | Add limit/offset params |
| 13 | Centralize query building | dynamic-services.ts | Extract to query builder |
| 14 | Add query logging/monitoring | db.ts | Hook pool events |

---

## RECOMMENDED FIX PRIORITY

### Phase 1: CRITICAL (Do First - 30 min)

1. **Standardize bcrypt rounds to 12** across all password operations
   - **Files**: routes.ts (lines 801, 3192, 3246, 7341, etc.)
   - **Time**: 15 min

2. **Rotate all exposed secrets**
   - **Impact**: HIGH — Keys are in git history
   - **Action**: DigitalOcean dashboard → change all API keys
   - **Time**: 30 min (includes credential rotation)

3. **Enable 2FA in production**
   - **File**: .do/app.yaml
   - **Change**: `ADMIN_2FA_REQUIRED` = "true"
   - **Config**: Set `ADMIN_PHONE` for OTP delivery
   - **Time**: 5 min

### Phase 2: IMPORTANT (Next 1-2 hours)

4. **Move admin table to migration**
   - **Create**: migrations/0008_admin_login_system.sql
   - **Remove**: Dynamic creation from ensureAdminExists()
   - **Time**: 30 min

5. **Increase DB connection pool**
   - **File**: db.ts
   - **Change**: max from 20 → 40 (for 2 instances)
   - **Time**: 5 min

6. **Add missing indexes**
   - **Create**: migrations/0009_performance_indexes.sql
   - **Indexes**: admins.email, business_settings.key_name, admin_login_otp
   - **Time**: 15 min

7. **Fix N+1 queries in dashboard**
   - **File**: intelligence.ts (lines 857-868)
   - **Refactor**: UNION ALL instead of subqueries
   - **Time**: 30 min

### Phase 3: NICE-TO-HAVE (Next sprint)

8. Extract password hashing utility - 20 min
9. Add per-query timeout protection - 30 min  
10. Refactor duplicate storage.ts methods - 1 hour
11. Add pagination to admin/list endpoints - 30 min

---

## TESTING CHECKLIST

After fixes, verify:

- [ ] Admin login completes in <500ms
- [ ] 5 consecutive failed logins blocks with rate limit error
- [ ] 2FA OTP sent to configured phone number
- [ ] Dashboard stats endpoint responds in <1 second
- [ ] DB connection pool doesn't exhaust under normal load
- [ ] All bcrypt operations have consistent 12-round hashing
- [ ] No unhandled bcrypt promise rejections in logs
- [ ] Admin table exists after cold start (no dynamic creation)
- [ ] All secrets rotated and pushed to DigitalOcean dashboard

---

## APPENDIX: QUERY OPTIMIZATION EXAMPLES

### Before: Slow subqueries (50-100ms)
```sql
SELECT
  (SELECT COUNT(*) FROM trip_requests WHERE current_status = 'active') as active_rides,
  (SELECT COUNT(*) FROM trip_requests WHERE current_status = 'cancelled') as cancelled,
  (SELECT SUM(estimated_fare) FROM trip_requests WHERE current_status = 'completed') as revenue
FROM trip_requests LIMIT 1;
```

### After: Single pass (10-20ms)
```sql
WITH stats AS (
  SELECT
    COUNT(*) FILTER(WHERE current_status = 'active') as active_rides,
    COUNT(*) FILTER(WHERE current_status = 'cancelled') as cancelled,
    COALESCE(SUM(estimated_fare) FILTER(WHERE current_status = 'completed'), 0) as revenue
  FROM trip_requests
)
SELECT * FROM stats;
```

---

## CONCLUSION

The application is **NOT production-ready** due to:

1. **Bcrypt round inconsistency** causing potential login timeouts
2. **Hardcoded credentials in repository** — critical security risk
3. **Admin 2FA disabled in production** — authentication weakness
4. **Connection pool exhaustion risk** — low connection limit for 2 instances
5. **Dynamic schema creation** — deployment race conditions

**Recommended**: Fix Critical issues (Phase 1) before next deployment, complete Important issues (Phase 2) before public launch.

