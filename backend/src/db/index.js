require('dotenv').config();
const { Pool } = require('pg');

/**
 * PostgreSQL connection configuration
 * Configured for production deployment with connection limits and SSL support
 */
const poolConfig = process.env.DATABASE_URL
  ? { 
      connectionString: String(process.env.DATABASE_URL || ''),
      // Required for cloud-hosted databases (Supabase, Neon, Render, etc.) in production
      ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
      max: 20,                       // Maximum number of clients in the pool
      idleTimeoutMillis: 30000,      // Close idle clients after 30 seconds
      connectionTimeoutMillis: 2000, // Timeout after 2 seconds if connection fails
    }
  : {
      user: process.env.DB_USER,
      host: process.env.DB_HOST,
      database: process.env.DB_NAME,
      password: String(process.env.DB_PASSWORD || ''),
      port: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 5432,
      max: 20,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 2000,
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
  pool,
};