const fs = require('fs');
const path = require('path');
const { pool } = require('./index');

/**
 * Runs the subscriptions table migration script
 */
const runMigration = async () => {
  const migrationPath = path.join(__dirname, 'migrations', '003_create_subscriptions_table.sql');
  const sql = fs.readFileSync(migrationPath, 'utf8');

  const client = await pool.connect();
  try {
    console.log('Starting migration: 003_create_subscriptions_table.sql...');
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');
    console.log('Migration successful: subscriptions table has been created/verified.');
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
