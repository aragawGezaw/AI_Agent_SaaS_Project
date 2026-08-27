-- ============================================================
-- Phase 3: Food Database Engine
-- Migration 004: Create `foods` table for EPHI + USDA data
-- ============================================================

-- gen_random_uuid() requires the pgcrypto extension (PostgreSQL 13+ default)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- pg_trgm extension for trigram operator class (gin_trgm_ops)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ============================================================
-- Foods Table
-- Stores both Ethiopian (EPHI) and Global (USDA) food items
-- with full nutrient profile and Glycemic Load support fields.
-- ============================================================
CREATE TABLE IF NOT EXISTS foods (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_en         VARCHAR(255) NOT NULL,
    name_am         VARCHAR(255) NOT NULL,
    calories_per_100g NUMERIC(6, 2) NOT NULL DEFAULT 0,
    protein_g       NUMERIC(6, 2) NOT NULL DEFAULT 0,
    carbs_g         NUMERIC(6, 2) NOT NULL DEFAULT 0,
    fiber_g         NUMERIC(6, 2) NOT NULL DEFAULT 0,
    fat_g           NUMERIC(6, 2) NOT NULL DEFAULT 0,
    glycemic_index  NUMERIC(5, 2),
    source          VARCHAR(50) NOT NULL DEFAULT 'EPHI' CHECK (source IN ('EPHI', 'USDA')),
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- Indexes for efficient search and filtering
-- ============================================================

-- Composite index to accelerate ILIKE searches on both names
CREATE INDEX IF NOT EXISTS idx_foods_name_en_trgm ON foods USING gin (name_en gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_foods_name_am_trgm ON foods USING gin (name_am gin_trgm_ops);

-- B-tree indexes for source filtering
CREATE INDEX IF NOT EXISTS idx_foods_source ON foods(source);

-- Index on glycemic_index for GL-based queries
CREATE INDEX IF NOT EXISTS idx_foods_glycemic_index ON foods(glycemic_index);

-- ============================================================
-- Indexes for full-text search (optional, improves accuracy)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_foods_name_en_fts ON foods USING gin (to_tsvector('english', name_en));
CREATE INDEX IF NOT EXISTS idx_foods_name_am_fts ON foods USING gin (to_tsvector('english', name_am));

-- ============================================================
-- Trigger: auto-update updated_at on row modification
-- Reuses the update_updated_at_column() function created
-- in migration 001 (init_db.sql)
-- ============================================================
CREATE TRIGGER update_foods_updated_at
    BEFORE UPDATE ON foods
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
