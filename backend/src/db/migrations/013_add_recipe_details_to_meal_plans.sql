-- Migration 013: Add ingredients and instructions to meal_plans
ALTER TABLE meal_plans 
ADD COLUMN IF NOT EXISTS ingredients JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS instructions JSONB DEFAULT '[]'::jsonb;