const fs = require('fs');
const path = require('path');
const { pool, query } = require('./index.js');

async function main() {
  const file = path.join(__dirname, 'migrations', '011_create_notification_tables.sql');
  const sql = fs.readFileSync(file, 'utf8');
  console.log('Running migration 011 (notification tables)...');
  await query(sql);
  console.log('Migration 011 completed.');
  await pool.end();
}

main().catch((err) => {
  console.error('Migration 011 failed:', err);
  process.exit(1);
});
