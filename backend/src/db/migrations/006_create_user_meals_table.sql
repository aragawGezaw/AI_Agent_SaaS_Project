-- ============================================================
-- Phase 6: Persistent Meal History
-- Migration 006: Create `user_meals` table for logged meal history
-- ============================================================

-- Enable uuid-ossp extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create user_meals table for persistent meal history
CREATE TABLE IF NOT EXISTS user_meals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    meal_type VARCHAR(50) NOT NULL,
    food_name VARCHAR(255) NOT NULL,
    food_ids UUID[] DEFAULT ARRAY[]::UUID[],  -- Array of food IDs used in this meal
    calories INT NOT NULL CHECK (calories >= 0),
    macros JSONB NOT NULL DEFAULT '{"protein_g": 0, "carbs_g": 0, "fat_g": 0}'::jsonb,
    total_glycemic_load DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    net_carbs_g DECIMAL(8, 2) NOT NULL DEFAULT 0.00,
    gl_class VARCHAR(10) NOT NULL DEFAULT 'low',  -- low, medium, high
    logged_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_meals_user_id ON user_meals(user_id);
CREATE INDEX IF NOT EXISTS idx_user_meals_logged_at ON user_meals(logged_at);
CREATE INDEX IF NOT EXISTS idx_user_meals_user_logged ON user_meals(user_id, logged_at DESC);

-- Trigger for automatically updating updated_at timestamp
DROP TRIGGER IF EXISTS update_user_meals_updated_at ON user_meals;
CREATE TRIGGER update_user_meals_updated_at
    BEFORE UPDATE ON user_meals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- End of Migration 006
-- ============================================================