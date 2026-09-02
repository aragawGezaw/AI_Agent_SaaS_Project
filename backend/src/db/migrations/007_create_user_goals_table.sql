-- ============================================================
-- Migration 007: Personalized User Goals & Thresholds
-- ============================================================
-- Stores per-user health objectives and custom glycemic thresholds
-- (e.g., target daily calories/macros, custom GL boundary limits).
-- One row per user; created on first read if missing (defaults applied).
-- ============================================================

CREATE TABLE IF NOT EXISTS user_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Daily macro / calorie targets
    daily_calorie_target INT,
    daily_protein_target_g DECIMAL(6, 2),
    daily_carbs_target_g DECIMAL(6, 2),
    daily_fat_target_g DECIMAL(6, 2),

    -- Glycemic Load classification thresholds (per-meal)
    -- Defaults: low <= 10, medium <= 19, high > 19
    glycemic_load_low_threshold DECIMAL(5, 2) NOT NULL DEFAULT 10.00
        CHECK (glycemic_load_low_threshold >= 0),
    glycemic_load_medium_threshold DECIMAL(5, 2) NOT NULL DEFAULT 19.00
        CHECK (glycemic_load_medium_threshold >= 0),

    -- Daily Glycemic Load boundary limit (sum across all meals of the day)
    daily_glycemic_load_limit DECIMAL(7, 2)
        CHECK (daily_glycemic_load_limit IS NULL OR daily_glycemic_load_limit >= 0),

    -- User preference metadata
    preferred_language VARCHAR(5) NOT NULL DEFAULT 'en'
        CHECK (preferred_language IN ('en', 'am')),
    goal_focus VARCHAR(30) NOT NULL DEFAULT 'maintenance'
        CHECK (goal_focus IN ('weight_loss', 'maintenance', 'muscle_gain', 'fasting_support', 'diabetes_management')),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,

    -- Sanity: medium must be >= low
    CONSTRAINT chk_gl_thresholds_order
        CHECK (glycemic_load_medium_threshold >= glycemic_load_low_threshold)
);

-- Index for fast per-user lookup
CREATE INDEX IF NOT EXISTS idx_user_goals_user_id ON user_goals(user_id);

-- Auto-update updated_at
CREATE TRIGGER update_user_goals_updated_at
BEFORE UPDATE ON user_goals
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
