const fs = require('fs');
const path = require('path');
const { pool } = require('./index');

/**
 * Runs the user_goals table migration script (Migration 007)
 * Creates the personalized user goals and thresholds table.
 */
const runMigration = async () => {
  const migrationPath = path.join(__dirname, 'migrations', '007_create_user_goals_table.sql');
  const sql = fs.readFileSync(migrationPath, 'utf8');

  const client = await pool.connect();
  try {
    console.log('Starting migration: 007_create_user_goals_table.sql...');
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');
    console.log('Migration successful: user_goals table has been created.');
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