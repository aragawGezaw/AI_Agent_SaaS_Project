const { pool, query } = require('./src/db');

async function main() {
  try {
    // Add language_preference column if not exists
    console.log('Adding language_preference column to users table...');
    await query(`ALTER TABLE users ADD COLUMN IF NOT EXISTS language_preference VARCHAR(50) DEFAULT 'en'`);
    console.log('Column added successfully.');

    // Verify the column exists
    const result = await query(`
      SELECT column_name, data_type, column_default 
      FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'language_preference'
    `);
    console.log('Verification:', result.rows);

    await pool.end();
    console.log('Done.');
  } catch (err) {
    console.error('Error:', err.message);
    await pool.end();
    process.exit(1);
  }
}

main();
