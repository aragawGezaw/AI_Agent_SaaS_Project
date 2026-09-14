const { pool, query } = require('./src/db');

async function main() {
  try {
    // Check if table exists
    const checkResult = await query(
      `SELECT table_name FROM information_schema.tables 
       WHERE table_schema='public' AND table_name='notification_preferences'`
    );
    console.log('Existing tables check:', checkResult.rows);

    if (checkResult.rows.length === 0) {
      console.log('Table notification_preferences does not exist. Creating...');
      
      // Create the notification_preferences table
      await query(`
        CREATE TABLE notification_preferences (
            id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
            user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            fasting_reminders BOOLEAN NOT NULL DEFAULT true,
            meal_reminders BOOLEAN NOT NULL DEFAULT true,
            weekly_summary BOOLEAN NOT NULL DEFAULT true,
            educational_tips BOOLEAN NOT NULL DEFAULT true,
            reminder_time TIME DEFAULT '07:00',
            fasting_reminder_enabled BOOLEAN NOT NULL DEFAULT true,
            fasting_day_notice_hours INTEGER DEFAULT 18,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        )
      `);
      console.log('Table notification_preferences created successfully.');

      // Create the trigger function if not exists
      await query(`
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = CURRENT_TIMESTAMP;
            RETURN NEW;
        END;
        $$ language 'plpgsql'
      `);

      // Create trigger
      await query(`
        DROP TRIGGER IF EXISTS update_notification_preferences_updated_at ON notification_preferences;
        CREATE TRIGGER update_notification_preferences_updated_at
        BEFORE UPDATE ON notification_preferences
        FOR EACH ROW EXECUTE PROCEDURE update_updated_at_column();
      `);
      console.log('Trigger created successfully.');
    } else {
      console.log('Table notification_preferences already exists.');
    }

    // Verify by listing all tables
    const allTables = await query(
      `SELECT table_name FROM information_schema.tables WHERE table_schema='public' ORDER BY table_name`
    );
    console.log('All tables:', allTables.rows.map(r => r.table_name));

    await pool.end();
    console.log('Done.');
  } catch (err) {
    console.error('Error:', err);
    await pool.end();
    process.exit(1);
  }
}

main();
