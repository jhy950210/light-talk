-- Add GROUP chat support

-- 1) Update chat_rooms type constraint to allow GROUP
ALTER TABLE chat_rooms DROP CONSTRAINT chk_chat_room_type;
ALTER TABLE chat_rooms ADD CONSTRAINT chk_chat_room_type CHECK (type IN ('DIRECT', 'GROUP'));

-- 2) Add group chat metadata columns to chat_rooms
ALTER TABLE chat_rooms ADD COLUMN name VARCHAR(100) DEFAULT NULL;
ALTER TABLE chat_rooms ADD COLUMN owner_id BIGINT DEFAULT NULL REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE chat_rooms ADD COLUMN max_members INT NOT NULL DEFAULT 2;
ALTER TABLE chat_rooms ADD COLUMN image_url TEXT DEFAULT NULL;

-- 3) Add role and left_at to chat_members
ALTER TABLE chat_members ADD COLUMN role VARCHAR(10) NOT NULL DEFAULT 'MEMBER';
ALTER TABLE chat_members ADD CONSTRAINT chk_member_role CHECK (role IN ('OWNER', 'ADMIN', 'MEMBER'));
ALTER TABLE chat_members ADD COLUMN left_at TIMESTAMP DEFAULT NULL;

-- 4) Index for active members lookup
CREATE INDEX idx_chat_members_active ON chat_members (chat_room_id) WHERE left_at IS NULL;
