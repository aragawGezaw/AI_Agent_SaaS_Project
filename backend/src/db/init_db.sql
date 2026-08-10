-- Enable uuid-ossp extension for UUID primary keys
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    preferred_language VARCHAR(10) DEFAULT 'am' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Food Items Table
-- name and description are JSONB to support bilingual data: {"am": "...", "en": "..."}
CREATE TABLE IF NOT EXISTS food_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name JSONB NOT NULL,
    description JSONB,
    calories DECIMAL(10, 2) NOT NULL DEFAULT 0,
    protein_g DECIMAL(10, 2) NOT NULL DEFAULT 0,
    carbs_g DECIMAL(10, 2) NOT NULL DEFAULT 0,
    fat_g DECIMAL(10, 2) NOT NULL DEFAULT 0,
    fiber_g DECIMAL(10, 2) NOT NULL DEFAULT 0,
    serving_size VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indices for JSONB language querying
CREATE INDEX IF NOT EXISTS idx_food_items_name_en ON food_items USING GIN ((name ->> 'en'));
CREATE INDEX IF NOT EXISTS idx_food_items_name_am ON food_items USING GIN ((name ->> 'am'));

-- Trigger for automatically updating updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
CREATE TRIGGER update_food_items_updated_at BEFORE UPDATE ON food_items FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
