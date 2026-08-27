const fs = require('fs');
const path = require('path');
const { pool } = require('./index');

/**
 * Runs the foods table migration script (Migration 004)
 */
const runMigration = async () => {
  const migrationPath = path.join(__dirname, 'migrations', '004_create_foods_table.sql');
  const sql = fs.readFileSync(migrationPath, 'utf8');

  const client = await pool.connect();
  try {
    console.log('Starting migration: 004_create_foods_table.sql...');
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');
    console.log('Migration successful: foods table has been created/verified.');
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