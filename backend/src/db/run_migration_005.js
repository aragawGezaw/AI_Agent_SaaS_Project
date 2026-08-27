const fs = require('fs');
const path = require('path');
const { pool } = require('./index');

/**
 * Runs the Amharic translation fix migration (Migration 005)
 * Updates the `name_am` column for known seed foods with
 * culturally accurate Amharic names.
 */
const runMigration = async () => {
  const migrationPath = path.join(__dirname, 'migrations', '005_fix_amharic_translations.sql');
  const sql = fs.readFileSync(migrationPath, 'utf8');

  const client = await pool.connect();
  try {
    console.log('Starting migration: 005_fix_amharic_translations.sql...');
    await client.query(sql);
    console.log('Migration successful: Amharic translations have been corrected.');
  } catch (error) {
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
