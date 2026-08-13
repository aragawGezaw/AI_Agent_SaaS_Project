const fs = require('fs');
const path = require('path');
const { pool } = require('./index');

/**
 * Runs the core tables migration script
 */
const runMigration = async () => {
  const migrationPath = path.join(__dirname, 'migrations', '002_create_core_tables.sql');
  const sql = fs.readFileSync(migrationPath, 'utf8');

  const client = await pool.connect();
  try {
    console.log('Starting migration: 002_create_core_tables.sql...');
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');
    console.log('Migration successful: health_profiles, nutrition_logs, chat_sessions, and chat_messages tables have been created/verified.');
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Migration failed:', error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
};

if (require.main === module) {
  runMigration();
}

module.exports = runMigration;
