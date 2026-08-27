-- ============================================================
-- Phase 5: Localization fix
-- Migration 005: Fix incorrect/garbled Amharic translations
-- in the `foods` table.
--
-- These corrections ensure the bilingual search and meal logger
-- UI surface culturally accurate Amharic names.
-- ============================================================

BEGIN;

-- 1) Deduplicate any existing rows that share the same name_en
--    (keeps the most recently updated row).
DELETE FROM foods a USING foods b
WHERE a.name_en = b.name_en
  AND a.ctid < b.ctid;

-- 2) Add a unique constraint on name_en (idempotent). This is
--    required for the upsert ON CONFLICT (name_en) clause in
--    the seed script to work.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'foods_name_en_unique'
    ) THEN
        ALTER TABLE foods ADD CONSTRAINT foods_name_en_unique UNIQUE (name_en);
    END IF;
END
$$;

UPDATE foods SET name_am = 'ምስር',     updated_at = CURRENT_TIMESTAMP WHERE name_en = 'Lentils';
UPDATE foods SET name_am = 'የስንዴ ዱቄት', updated_at = CURRENT_TIMESTAMP WHERE name_en = 'Wheat Flour';
UPDATE foods SET name_am = 'ቡናማ ሩዝ', updated_at = CURRENT_TIMESTAMP WHERE name_en = 'Brown Rice';
UPDATE foods SET name_am = 'ነጭ ሩዝ',    updated_at = CURRENT_TIMESTAMP WHERE name_en = 'White Rice';
UPDATE foods SET name_am = 'ሙዝ',          updated_at = CURRENT_TIMESTAMP WHERE name_en = 'Banana';
UPDATE foods SET name_am = 'እንጀራ',     updated_at = CURRENT_TIMESTAMP WHERE name_en = 'Injera';
UPDATE foods SET name_am = 'ሽሮ',          updated_at = CURRENT_TIMESTAMP WHERE name_en = 'Shiro';
UPDATE foods SET name_am = 'ጤፍ',          updated_at = CURRENT_TIMESTAMP WHERE name_en = 'Teff';
UPDATE foods SET name_am = 'ቆጮ',          updated_at = CURRENT_TIMESTAMP WHERE name_en = 'Kocho';

COMMIT;
