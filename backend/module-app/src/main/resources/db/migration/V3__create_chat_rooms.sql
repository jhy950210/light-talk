CREATE TABLE chat_rooms (
    id              BIGSERIAL       PRIMARY KEY,
    type            VARCHAR(20)     NOT NULL DEFAULT 'DIRECT',
    created_at      TIMESTAMP       NOT NULL DEFAULT now(),

    CONSTRAINT chk_chat_room_type CHECK (type IN ('DIRECT'))
);
