# ✅ FIX ADMIN LOGIN - COMPLETE SOLUTION

**Status**: Ready to Fix  
**Your Credentials**:
- Email: `atmakuriarena@gmail.com`
- Password: `Kiran@1986`
- Admin Name: `Jagapro`

---

## 🚀 **EASIEST WAY - Copy & Paste (2 Minutes)**

### Step 1: Open Terminal/SSH
Connect to your DigitalOcean server:
```bash
ssh root@oyster-app-9e9cd.ondigitalocean.app
```

### Step 2: Copy & Paste This ENTIRE Command
```bash
cd /var/www/jago && \
git pull origin master && \
cat > /tmp/admin-setup.js << 'EOF'
const pg = require('pg');
const bcrypt = require('bcryptjs');

(async () => {
  try {
    const pool = new pg.Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    });

    await pool.query(`CREATE TABLE IF NOT EXISTS admins (
      id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name VARCHAR(255), email VARCHAR(191) UNIQUE, password VARCHAR(191),
      role VARCHAR(50) DEFAULT 'admin', is_active BOOLEAN DEFAULT true,
      auth_token VARCHAR(255), auth_token_expires_at TIMESTAMP WITH TIME ZONE,
      created_at TIMESTAMP DEFAULT NOW()
    )`);

    const hash = await bcrypt.hash(process.env.ADMIN_PASSWORD, 12);
    await pool.query(
      `INSERT INTO admins (name, email, password, role, is_active) 
       VALUES ($1, $2, $3, 'admin', true)
       ON CONFLICT (email) DO UPDATE SET password=$3`,
      [process.env.ADMIN_NAME, process.env.ADMIN_EMAIL, hash]
    );

    console.log('✅ Admin created!');
    await pool.end();
  } catch (e) {
    console.error('❌', e.message);
    process.exit(1);
  }
})();
EOF
ADMIN_EMAIL="atmakuriarena@gmail.com" ADMIN_PASSWORD="Kiran@1986" ADMIN_NAME="Jagapro" DATABASE_URL="$DATABASE_URL" node /tmp/admin-setup.js && \
pm2 restart jago-pro && \
pm2 logs jago-pro
```

### Step 3: Wait for Server to Start
You'll see green text showing server is running. Wait 10-15 seconds.

### Step 4: Login
Open: https://jagopro.org/admin/auth/login

**Use these credentials:**
```
Email:    atmakuriarena@gmail.com
Password: Kiran@1986
```

✅ **Should work now!**

---

## 📱 **STEP-BY-STEP (If You Want To Understand)**

1. **SSH into server:**
   ```
   ssh root@oyster-app-9e9cd.ondigitalocean.app
   ```

2. **Go to jago folder:**
   ```
   cd /var/www/jago
   ```

3. **Update code:**
   ```
   git pull origin master
   ```

4. **Create and run admin setup script:**
   - Copy the command from "Step 2" above
   - Paste it all at once (it's one big command)
   - Hit Enter
   - Wait for `✅ Admin created!` message

5. **Restart server:**
   ```
   pm2 restart jago-pro
   ```

6. **Wait 10 seconds, then login:**
   - Go to: https://jagopro.org/admin/auth/login
   - Email: `atmakuriarena@gmail.com`
   - Password: `Kiran@1986`

---

## ❓ **What If Something Goes Wrong?**

### "Command not found"
- You're probably not in the right folder
- Type: `cd /var/www/jago`
- Then try again

### "Database connection error"
- Your database credentials might be wrong
- Check: `echo $DATABASE_URL`
- Should show a long URL like `postgresql://...`

### "Port 3000 already in use"
- Old server is still running
- Kill it: `pm2 kill`
- Then: `pm2 start`

### "Still getting 504 error after login"
- Server still starting up
- Wait 30 seconds
- Refresh page
- If still fails, contact support

---

## 🎯 **What This Does**

| Issue | Solution |
|-------|----------|
| Admin doesn't exist in database | Creates admin with your credentials |
| Old server hanging | Restarts server cleanly |
| Password not hashed properly | Uses bcrypt 12 rounds (secure) |
| Login timeout | Fast direct database insert |

---

## ✅ **Success Indicators**

After running the command, you should see:
```
✅ Admin created!
Restarting app in cluster mode...
```

Then you can login! ✅

---

**Just do the "EASIEST WAY" above and everything will work! 💯**

Questions? Let me know!
