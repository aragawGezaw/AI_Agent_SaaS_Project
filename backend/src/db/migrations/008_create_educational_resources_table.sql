-- ============================================================
-- Migration 008: Educational Resources Hub
-- ============================================================
-- Stores health and nutrition educational content including
-- articles, guides, and video resources for users.
-- ============================================================

CREATE TABLE IF NOT EXISTS educational_resources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

    -- Core content fields
    title VARCHAR(255) NOT NULL,
    category VARCHAR(50) NOT NULL
        CHECK (category IN ('nutrition', 'glycemic_index', 'fasting', 'recipes', 'health_tips', 'exercise')),
    summary TEXT,
    content_body TEXT NOT NULL,

    -- Optional video content
    video_url VARCHAR(500),
    video_duration_seconds INT,

    -- Optional thumbnail/featured image
    thumbnail_url VARCHAR(500),

    -- Localization support
    language VARCHAR(5) NOT NULL DEFAULT 'en'
        CHECK (language IN ('en', 'am', 'both')),

    -- Metadata
    is_featured BOOLEAN DEFAULT FALSE,
    is_published BOOLEAN DEFAULT TRUE,
    view_count INT DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for efficient querying
CREATE INDEX IF NOT EXISTS idx_resources_category ON educational_resources(category);
CREATE INDEX IF NOT EXISTS idx_resources_language ON educational_resources(language);
CREATE INDEX IF NOT EXISTS idx_resources_published ON educational_resources(is_published) WHERE is_published = TRUE;
CREATE INDEX IF NOT EXISTS idx_resources_featured ON educational_resources(is_featured) WHERE is_featured = TRUE;

-- Auto-update updated_at
CREATE TRIGGER update_educational_resources_updated_at
BEFORE UPDATE ON educational_resources
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
