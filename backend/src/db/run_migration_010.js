const fs = require('fs');
const path = require('path');
const { pool, query } = require('./index');

async function main() {
  const file = path.join(__dirname, 'migrations', '010_add_subscription_gating.sql');
  const sql = fs.readFileSync(file, 'utf8');
  console.log('Running migration 010...');
  await query(sql);
  console.log('Migration 010 completed.');
  await pool.end();
}

main().catch((err) => { console.error('Migration 010 failed:', err); process.exit(1); });
