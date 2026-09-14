-- Migration 011: Push notification infrastructure
-- FCM token storage + user notification preferences + fasting schedule tracking

-- FCM tokens: one row per device; multiple devices per user supported
CREATE TABLE IF NOT EXISTS fcm_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    device_type VARCHAR(20) CHECK (device_type IN ('android', 'ios', 'web')),
    device_name VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, token)
);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id);

-- Notification preferences: one row per user
CREATE TABLE IF NOT EXISTS notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fasting_reminders BOOLEAN NOT NULL DEFAULT true,
    meal_reminders BOOLEAN NOT NULL DEFAULT true,
    weekly_summary BOOLEAN NOT NULL DEFAULT true,
    educational_tips BOOLEAN NOT NULL DEFAULT true,
    reminder_time TIME DEFAULT '07:00',  -- local time for daily reminder
    fasting_reminder_enabled BOOLEAN NOT NULL DEFAULT true,
    fasting_day_notice_hours INTEGER DEFAULT 18,  -- hours before to send fasting reminder
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Fasting schedule: tracks upcoming Ethiopian Orthodox fasting days per user
CREATE TABLE IF NOT EXISTS fasting_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fasting_date DATE NOT NULL,
    fasting_name VARCHAR(255),   -- e.g. 'Wednesdays & Fridays', 'Tahsas Fast', 'Lent'
    is_notified BOOLEAN NOT NULL DEFAULT false,
    notification_sent_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, fasting_date)
);
CREATE INDEX IF NOT EXISTS idx_fasting_schedules_user_date
    ON fasting_schedules(user_id, fasting_date) WHERE is_notified = false;

-- Notification log: audit trail for all sent notifications
CREATE TABLE IF NOT EXISTS notification_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    fcm_token_id UUID REFERENCES fcm_tokens(id) ON DELETE SET NULL,
    notification_type VARCHAR(50) NOT NULL,  -- fasting_reminder, meal_reminder, etc.
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data_payload JSONB,  -- deep-link data: {route, mealId, planId}
    status VARCHAR(20) NOT NULL DEFAULT 'sent',  -- sent, failed, opened
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    opened_at TIMESTAMP WITH TIME ZONE
);
CREATE INDEX IF NOT EXISTS idx_notification_log_user_type
    ON notification_log(user_id, notification_type, sent_at DESC);

-- Trigger for updated_at on fcm_tokens
DROP TRIGGER IF EXISTS update_fcm_tokens_updated_at ON fcm_tokens;
CREATE TRIGGER update_fcm_tokens_updated_at
BEFORE UPDATE ON fcm_tokens
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();

-- Trigger for updated_at on notification_preferences
DROP TRIGGER IF EXISTS update_notification_preferences_updated_at ON notification_preferences;
CREATE TRIGGER update_notification_preferences_updated_at
BEFORE UPDATE ON notification_preferences
FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
