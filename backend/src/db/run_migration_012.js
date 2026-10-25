const fs = require('fs');
const path = require('path');
const { query } = require('./index');

async function runMigration() {
  try {
    const sqlPath = path.join(__dirname, 'migrations', '012_create_transactions_table.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    
    console.log('Running migration 012...');
    await query(sql);
    console.log('Migration 012 completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Migration failed:', error.message);
    process.exit(1);
  }
}

runMigration();