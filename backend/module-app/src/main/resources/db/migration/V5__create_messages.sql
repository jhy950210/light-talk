CREATE TABLE messages (
    id              BIGSERIAL       PRIMARY KEY,
    chat_room_id    BIGINT          NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    sender_id       BIGINT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content         TEXT            NOT NULL,
    type            VARCHAR(20)     NOT NULL DEFAULT 'TEXT',
    created_at      TIMESTAMP       NOT NULL DEFAULT now(),

    CONSTRAINT chk_message_type CHECK (type IN ('TEXT', 'IMAGE', 'SYSTEM'))
);

CREATE INDEX idx_messages_chat_room_id ON messages (chat_room_id);
CREATE INDEX idx_messages_sender_id ON messages (sender_id);
CREATE INDEX idx_messages_chat_room_id_created_at ON messages (chat_room_id, created_at DESC);

-- Add foreign key from chat_members.last_read_message_id to messages.id
ALTER TABLE chat_members
    ADD CONSTRAINT fk_chat_members_last_read_message
    FOREIGN KEY (last_read_message_id) REFERENCES messages(id) ON DELETE SET NULL;
