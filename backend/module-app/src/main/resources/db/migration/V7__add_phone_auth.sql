-- Add phone auth columns
ALTER TABLE users ADD COLUMN phone_blind_index CHAR(64);
ALTER TABLE users ALTER COLUMN email DROP NOT NULL;
CREATE UNIQUE INDEX idx_users_phone_blind_index ON users (phone_blind_index) WHERE phone_blind_index IS NOT NULL;

-- OTP verification tracking table
CREATE TABLE otp_verifications (
    id          BIGSERIAL   PRIMARY KEY,
    phone_hash  CHAR(64)    NOT NULL,
    code        VARCHAR(6)  NOT NULL,
    token       VARCHAR(36),
    verified    BOOLEAN     NOT NULL DEFAULT false,
    attempts    INT         NOT NULL DEFAULT 0,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    expires_at  TIMESTAMP   NOT NULL
);
CREATE INDEX idx_otp_phone_hash ON otp_verifications (phone_hash);
