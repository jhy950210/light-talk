-- Performance indexes for unread count queries and membership lookups

-- Composite index for active membership lookups (user_id + left_at filter)
CREATE INDEX idx_chat_members_user_active ON chat_members (user_id, left_at)
    WHERE left_at IS NULL;

-- Composite index for room membership checks (chat_room_id + user_id + left_at)
CREATE INDEX idx_chat_members_room_user_active ON chat_members (chat_room_id, user_id, left_at)
    WHERE left_at IS NULL;
