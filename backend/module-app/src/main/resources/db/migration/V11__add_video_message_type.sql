-- Add VIDEO to message type CHECK constraint
ALTER TABLE messages DROP CONSTRAINT chk_message_type;
ALTER TABLE messages ADD CONSTRAINT chk_message_type CHECK (type IN ('TEXT', 'IMAGE', 'VIDEO', 'SYSTEM'));
