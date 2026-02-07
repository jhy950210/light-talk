-- Add tag column
ALTER TABLE users ADD COLUMN tag VARCHAR(4);

-- Generate tags for existing users (sequential per nickname)
WITH ranked AS (
    SELECT id, nickname, ROW_NUMBER() OVER (PARTITION BY nickname ORDER BY id) AS rn
    FROM users
)
UPDATE users SET tag = LPAD(ranked.rn::text, 4, '0')
FROM ranked WHERE users.id = ranked.id;

-- Make tag NOT NULL after backfill
ALTER TABLE users ALTER COLUMN tag SET NOT NULL;

-- Drop email column and its index
DROP INDEX IF EXISTS idx_users_email;
ALTER TABLE users DROP COLUMN IF EXISTS email;

-- Add unique constraint on (nickname, tag)
CREATE UNIQUE INDEX idx_users_nickname_tag ON users (nickname, tag);
