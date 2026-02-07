-- chat_members: add created_at, updated_at (BaseEntity 상속 대응)
ALTER TABLE chat_members ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT now();
ALTER TABLE chat_members ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT now();

-- chat_rooms: add updated_at
ALTER TABLE chat_rooms ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT now();

-- messages: add updated_at
ALTER TABLE messages ADD COLUMN updated_at TIMESTAMP NOT NULL DEFAULT now();
