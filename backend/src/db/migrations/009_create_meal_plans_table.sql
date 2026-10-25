-- ============================================================
-- Phase 9: AI-Generated Meal Plans
-- Migration 009: Create `meal_plans` table for AI-generated meal recommendations
-- ============================================================

-- Ensure uuid-ossp extension is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create meal_plans table for AI-generated meal recommendations
CREATE TABLE IF NOT EXISTS meal_plans (
    id SERIAL PRIMARY KEY,
    
    -- User reference (UUID to match users table schema)
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Plan date for the meal (date-only, no time component)
    plan_date DATE NOT NULL,
    
    -- Meal type classification
    meal_type VARCHAR(50) NOT NULL
        CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    
    -- Optional recipe/food reference & Practical dish details
    recipe_id UUID REFERENCES food_items(id) ON DELETE SET NULL,
    food_name VARCHAR(255),
    description TEXT,
    
    -- Nutritional metrics
    glycemic_load NUMERIC(5, 2)
        CHECK (glycemic_load IS NULL OR glycemic_load >= 0),
    calories NUMERIC(6, 2)
        CHECK (calories IS NULL OR calories >= 0),
    
    -- Macronutrient breakdown stored as JSONB
    macronutrients JSONB NOT NULL DEFAULT '{"protein_g": 0, "carbs_g": 0, "fat_g": 0}'::jsonb,
    
    -- AI recommendation metadata
    is_fasting_meal BOOLEAN DEFAULT FALSE,
    recommendation_source VARCHAR(100),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CONSTRAINT chk_valid_macros_nutrients
        CHECK (
            macronutrients ? 'protein_g' AND
            macronutrients ? 'carbs_g' AND
            macronutrients ? 'fat_g'
        )
);

-- ============================================================
-- Indexes for efficient querying
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_meal_plans_user_id ON meal_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_plans_plan_date ON meal_plans(plan_date);
CREATE INDEX IF NOT EXISTS idx_meal_plans_user_date ON meal_plans(user_id, plan_date);
CREATE INDEX IF NOT EXISTS idx_meal_plans_meal_type ON meal_plans(meal_type);
CREATE INDEX IF NOT EXISTS idx_meal_plans_recipe_id ON meal_plans(recipe_id) WHERE recipe_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_meal_plans_fasting ON meal_plans(user_id, plan_date) WHERE is_fasting_meal = TRUE;

-- ============================================================
-- Auto-update updated_at trigger
-- ============================================================

DROP TRIGGER IF EXISTS update_meal_plans_updated_at ON meal_plans;
CREATE TRIGGER update_meal_plans_updated_at
    BEFORE UPDATE ON meal_plans
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- End of Migration 009
-- ============================================================