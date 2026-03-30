# Email Verification Database Migration

Run this SQL to add email verification columns to the `cribs_users` table:

```sql
ALTER TABLE cribs_users 
ADD COLUMN email_verified TINYINT(1) DEFAULT 0 AFTER email,
ADD COLUMN email_verification_code VARCHAR(4) NULL AFTER email_verified,
ADD COLUMN email_verification_expires_at TIMESTAMP NULL AFTER email_verification_code;

-- Add index for faster lookups
CREATE INDEX idx_email_verification ON cribs_users(email, email_verification_code);
```

## Columns Added:

1. **email_verified** - Boolean (0 = not verified, 1 = verified)
2. **email_verification_code** - 4-digit code sent to user's email
3. **email_verification_expires_at** - Code expiry timestamp (15 minutes)

## How to Run:

### Option 1: MySQL Command Line
```bash
mysql -u root -p cribs_arena < add_email_verification.sql
```

### Option 2: phpMyAdmin
1. Open phpMyAdmin
2. Select `cribs_arena` database
3. Go to SQL tab
4. Paste and execute the SQL above

### Option 3: Laravel Artisan (if using migrations)
```bash
php artisan migrate
```

## Verify Changes:

```sql
DESCRIBE cribs_users;
```

You should see the new columns:
- email_verified
- email_verification_code
- email_verification_expires_at
