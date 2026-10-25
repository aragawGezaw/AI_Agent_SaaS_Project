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
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name_en           VARCHAR(255) NOT NULL UNIQUE, -- UNIQUE ensures clean re-runs without duplicates
    name_am           VARCHAR(255) NOT NULL,
    calories_per_100g NUMERIC(6, 2) NOT NULL DEFAULT 0,
    protein_g         NUMERIC(6, 2) NOT NULL DEFAULT 0,
    carbs_g           NUMERIC(6, 2) NOT NULL DEFAULT 0,
    fiber_g           NUMERIC(6, 2) NOT NULL DEFAULT 0,
    fat_g             NUMERIC(6, 2) NOT NULL DEFAULT 0,
    glycemic_index    NUMERIC(5, 2),
    source            VARCHAR(50) NOT NULL DEFAULT 'EPHI' CHECK (source IN ('EPHI', 'USDA')),
    created_at        TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at        TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
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
-- ============================================================
CREATE TRIGGER update_foods_updated_at
    BEFORE UPDATE ON foods
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- Seed Data: Comprehensive Ethiopian Staples (EPHI) & Global Foods (USDA)
-- Values normalized per 100g portion size
-- ============================================================
INSERT INTO foods (name_en, name_am, calories_per_100g, protein_g, carbs_g, fiber_g, fat_g, glycemic_index, source) VALUES
-- Ethiopian Staples & Traditional Dishes (EPHI)
('Teff Injera', 'የተፍ እንጀራ', 170.00, 4.50, 34.00, 3.20, 1.00, 45.00, 'EPHI'),
('Shiro Wat (Chickpea Stew)', 'ሽንሮ ወጥ', 150.00, 7.00, 18.00, 5.00, 6.00, 35.00, 'EPHI'),
('Bozena Shiro (Shiro with Minced Meat)', 'ቦዘና ሽሮ', 185.00, 11.50, 16.00, 4.50, 8.50, 38.00, 'EPHI'),
('Misir Wat (Split Lentil Stew)', 'ምስር ወጥ', 116.00, 8.00, 20.00, 7.00, 1.50, 32.00, 'EPHI'),
('Kik Alicha (Yellow Split Pea Stew)', 'ክክ አልጫ', 110.00, 7.50, 19.00, 5.50, 1.20, 34.00, 'EPHI'),
('Gomen (Collard Greens)', 'ጎመን', 40.00, 3.00, 6.00, 4.00, 0.80, 15.00, 'EPHI'),
('Doro Wat (Chicken Stew)', 'ዶሮ ወጥ', 210.00, 18.00, 6.00, 1.50, 13.00, 40.00, 'EPHI'),
('Kitfo (Lean Minced Beef)', 'ክትፎ', 290.00, 24.00, 1.00, 0.00, 21.00, 0.00, 'EPHI'),
('Ful Medames (Fava Bean Stew)', 'ፉል', 115.00, 7.50, 18.00, 5.00, 2.00, 35.00, 'EPHI'),
('Injera Firfir', 'እንጀራ ፍርፍር', 220.00, 4.00, 36.00, 3.00, 6.50, 48.00, 'EPHI'),
('Kocho (Enset Bread)', 'ቆጮ', 135.00, 1.20, 31.00, 4.50, 0.50, 52.00, 'EPHI'),
('Ayibe (Traditional Cottage Cheese)', 'አይብ', 105.00, 18.00, 3.50, 0.00, 2.50, 10.00, 'EPHI'),
('Ergo (Traditional Yogurt)', 'እርጎ', 65.00, 3.50, 4.80, 0.00, 3.80, 35.00, 'EPHI'),
('Niter Kibbeh (Spiced Clarified Butter)', 'ነጭ ቅቤ', 880.00, 0.50, 0.00, 0.00, 99.50, 0.00, 'EPHI'),
('Genfo (Traditional Porridge)', 'ገንፎ', 150.00, 4.00, 30.00, 2.50, 2.00, 58.00, 'EPHI'),
('Qinchie (Cracked Wheat Porridge)', 'ቅንጬ', 130.00, 3.80, 27.00, 3.00, 1.20, 50.00, 'EPHI'),
('Atkilt Wat (Cabbage and Potato Stew)', 'አትክልት ወጥ', 75.00, 2.00, 12.00, 3.00, 2.50, 48.00, 'EPHI'),

-- Expanded Global Foods (USDA)
('Chicken Breast (Cooked)', 'የዶሮ ጡት', 165.00, 31.00, 0.00, 0.00, 3.60, 0.00, 'USDA'),
('Brown Rice (Cooked)', 'ቡናማ ሩዝ', 112.00, 2.60, 23.50, 1.80, 0.90, 50.00, 'USDA'),
('Oats (Cooked)', 'አጃ (የተቀቀለ)', 71.00, 2.50, 12.00, 1.70, 1.40, 55.00, 'USDA'),
('Salmon (Cooked)', 'ሳልሞን አሳ', 206.00, 22.00, 0.00, 0.00, 12.30, 0.00, 'USDA'),
('Whole Egg (Hard Boiled)', 'እንቁላል', 155.00, 12.60, 1.10, 0.00, 10.60, 0.00, 'USDA'),
('Broccoli (Steamed)', 'ብሮኮሊ', 35.00, 2.40, 7.20, 3.30, 0.40, 15.00, 'USDA'),
('Sweet Potato (Baked)', 'ጣፋጭ ድንች', 90.00, 2.00, 20.70, 3.00, 0.10, 63.00, 'USDA'),
('Banana', 'ሙዝ', 89.00, 1.10, 22.80, 2.60, 0.30, 51.00, 'USDA'),
('Quinoa (Cooked)', 'ኩዊኖአ', 120.00, 4.40, 21.30, 2.80, 1.90, 53.00, 'USDA'),
('Lean Ground Beef (Cooked)', 'የተፈጨ የቀነሰ ስብ ሥጋ', 250.00, 26.00, 0.00, 0.00, 15.00, 0.00, 'USDA'),
('Canned Tuna in Water', 'የጣሳ ቱና አሳ', 116.00, 26.00, 0.00, 0.00, 1.00, 0.00, 'USDA'),
('Firm Tofu', 'ቶፉ', 83.00, 10.00, 2.00, 0.30, 5.00, 15.00, 'USDA'),
('Plain Greek Yogurt', 'ግሪክ እርጎ', 97.00, 9.00, 3.60, 0.00, 5.00, 15.00, 'USDA'),
('Cow Milk (Whole)', 'የቀን ወተት', 61.00, 3.20, 4.80, 0.00, 3.30, 27.00, 'USDA'),
('White Rice (Cooked)', 'ነጭ ሩዝ', 130.00, 2.70, 28.00, 0.40, 0.30, 73.00, 'USDA'),
('Whole Wheat Bread', 'ሙሉ ስንዴ ዳቦ', 247.00, 13.00, 41.00, 7.00, 3.40, 74.00, 'USDA'),
('Pasta (Cooked)', 'ፓስታ', 158.00, 5.80, 31.00, 1.80, 0.90, 50.00, 'USDA'),
('White Potato (Boiled)', 'ነጭ ድንች', 87.00, 1.90, 20.10, 1.80, 0.10, 82.00, 'USDA'),
('Spinach (Raw)', 'ስፒናች', 23.00, 2.90, 3.60, 2.20, 0.40, 15.00, 'USDA'),
('Tomato', 'ቲማቲም', 18.00, 0.90, 3.90, 1.20, 0.20, 15.00, 'USDA'),
('Carrot', 'ካሮት', 41.00, 0.90, 9.60, 2.80, 0.20, 39.00, 'USDA'),
('Onion', 'ሽንኩርት', 40.00, 1.10, 9.30, 1.70, 0.10, 15.00, 'USDA'),
('Bell Pepper', 'ጣፋጭ በርበሬ (ፔፐር)', 31.00, 1.00, 6.00, 2.10, 0.30, 15.00, 'USDA'),
('Apple', 'ፖም', 52.00, 0.30, 13.80, 2.40, 0.20, 36.00, 'USDA'),
('Orange', 'ብርቱካን', 47.00, 0.90, 11.80, 2.40, 0.10, 43.00, 'USDA'),
('Strawberries', 'ስትሮቤሪ', 32.00, 0.70, 7.70, 2.00, 0.30, 41.00, 'USDA'),
('Avocado', 'አቮካዶ', 160.00, 2.00, 8.50, 6.70, 14.70, 15.00, 'USDA'),
('Olive Oil', 'የዘይት ዘይቱን', 884.00, 0.00, 0.00, 0.00, 100.00, 0.00, 'USDA'),
('Peanut Butter', 'የኦቾሎኒ ቅቤ', 588.00, 25.00, 20.00, 6.00, 50.00, 14.00, 'USDA'),
('Almonds', 'ለውዝ', 579.00, 21.00, 22.00, 12.50, 49.90, 15.00, 'USDA')
ON CONFLICT (name_en) DO NOTHING;