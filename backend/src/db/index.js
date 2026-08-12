require('dotenv').config();
const { Pool } = require('pg');

/**
 * PostgreSQL connection configuration
 * Uses DATABASE_URL if available, otherwise falls back to individual components
 */
const poolConfig = process.env.DATABASE_URL
  ? { connectionString: String(process.env.DATABASE_URL || '') }
  : {
      user: process.env.DB_USER,
      host: process.env.DB_HOST,
      database: process.env.DB_NAME,
      password: String(process.env.DB_PASSWORD || ''),
      port: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 5432,
    };

const pool = new Pool(poolConfig);

// Error handling on the pool
pool.on('error', (err, client) => {
  console.error('Unexpected error on idle PostgreSQL client', err);
  process.exit(-1);
});

/**
 * Executes a database query
 * @param {string} text - SQL query text
 * @param {Array} params - Query parameters
 * @returns {Promise<Object>} - Query result
 */
const query = async (text, params) => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    // Log query execution if needed (can be toggled with env var)
    if (process.env.DEBUG_DB === 'true') {
      console.log('executed query', { text, duration, rows: res.rowCount });
    }
    return res;
  } catch (error) {
    console.error('Database query error:', error);
    throw error;
  }
};

module.exports = {
  query,
  pool, // Exporting pool just in case client acquisition is needed elsewhere
};
