-- Performance index for message queries (cursor pagination, latest message, unread count)
CREATE INDEX idx_messages_room_id ON messages (chat_room_id, id DESC);
