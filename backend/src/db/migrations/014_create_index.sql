-- Index to quickly fetch a user's meal plans by user ID and specific dates
CREATE INDEX IF NOT EXISTS idx_meal_plans_user_date ON meal_plans(user_id, plan_date);

-- Index for meal history filtering
CREATE INDEX IF NOT EXISTS idx_meal_history_user_date ON meal_history(user_id, logged_at);

-- Index for user goals quick lookups
CREATE INDEX IF NOT EXISTS idx_user_goals_user_id ON user_goals(user_id);