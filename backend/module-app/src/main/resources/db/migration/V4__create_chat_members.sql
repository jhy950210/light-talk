CREATE TABLE chat_members (
    id                      BIGSERIAL       PRIMARY KEY,
    chat_room_id            BIGINT          NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    user_id                 BIGINT          NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at               TIMESTAMP       NOT NULL DEFAULT now(),
    last_read_message_id    BIGINT,

    CONSTRAINT uq_chat_member UNIQUE (chat_room_id, user_id)
);

CREATE INDEX idx_chat_members_chat_room_id ON chat_members (chat_room_id);
CREATE INDEX idx_chat_members_user_id ON chat_members (user_id);
