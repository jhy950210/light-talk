-- Fix phone_blind_index type: CHAR(64) → VARCHAR(64) to match JPA entity
ALTER TABLE users ALTER COLUMN phone_blind_index TYPE VARCHAR(64);
ALTER TABLE otp_verifications ALTER COLUMN phone_hash TYPE VARCHAR(64);
