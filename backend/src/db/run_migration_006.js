const fs = require('fs');
const path = require('path');
const { pool } = require('./index');

/**
 * Runs the user_meals table migration script (Migration 006)
 * Creates the persistent meal history table for logged meals.
 */
const runMigration = async () => {
  const migrationPath = path.join(__dirname, 'migrations', '006_create_user_meals_table.sql');
  const sql = fs.readFileSync(migrationPath, 'utf8');

  const client = await pool.connect();
  try {
    console.log('Starting migration: 006_create_user_meals_table.sql...');
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');
    console.log('Migration successful: user_meals table has been created.');
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