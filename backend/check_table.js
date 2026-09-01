const {query, pool} = require('./src/db/index.js');
(async () => {
  try {
    const r = await query("SELECT to_regclass('public.user_meals') AS t");
    const exists = r.rows[0].t !== null;
    console.log('user_meals table exists:', exists);
    if (!exists) {
      console.log('>> Run migration 006 first: node src/db/run_migration_006.js');
    }
  } catch (e) {
    console.error('DB error:', e.message);
  } finally {
    await pool.end();
  }
})();
