-- Migration 010: Add subscription feature gating
-- Adds feature_gating JSONB column and indexes for premium access control

ALTER TABLE subscriptions ADD COLUMN IF NOT EXISTS feature_gating JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE subscriptions ADD CONSTRAINT chk_valid_feature_gating
CHECK (feature_gating IS NULL OR feature_gating::text = '{}' OR jsonb_typeof(feature_gating) = 'object');

CREATE INDEX IF NOT EXISTS idx_subscriptions_plan_type ON subscriptions(plan_type);

CREATE INDEX IF NOT EXISTS idx_subscriptions_active_premium ON subscriptions(user_id, plan_type) WHERE plan_type = 'premium' AND status = 'active';

UPDATE subscriptions SET feature_gating = '{}'::jsonb WHERE feature_gating IS NULL;
