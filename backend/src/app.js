const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { pool, query } = require('./db/index.js');

const app = express();

// Configure CORS
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// Configure JSON body parser middleware
app.use(express.json());

// Request logging middleware
app.use(morgan('dev'));

// Import routes
const authRouter = require('./routes/auth.routes.js');
const profileRouter = require('./routes/profile.routes.js');
const nutritionRouter = require('./routes/nutrition.routes.js');
const chatRouter = require('./routes/chat.routes.js');

// Mount routes
app.use('/api/auth', authRouter);
app.use('/api/profile', profileRouter);
app.use('/api/nutrition', nutritionRouter);
app.use('/api/chat', chatRouter);

/**
 * @route GET /api/health
 * @desc Basic health-check route verifying server uptime and database connectivity
 * @access Public
 */
app.get('/api/health', async (req, res) => {
  try {
    // Verify database connectivity by running a simple query
    const dbResult = await query('SELECT NOW()');
    
    // If the query succeeds, respond with an UP status and the current time from the DB
    return res.status(200).json({
      status: 'UP',
      timestamp: new Date().toISOString(),
      services: {
        database: {
          status: 'UP',
          time: dbResult.rows[0].now
        }
      }
    });
  } catch (error) {
    // If the database query fails, log the error and respond with a DOWN status
    console.error('Health check failed:', error);
    return res.status(500).json({
      status: 'DOWN',
      timestamp: new Date().toISOString(),
      services: {
        database: {
          status: 'DOWN',
          error: error.message
        }
      }
    });
  }
});

// Global error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  return res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : 'An unexpected error occurred'
  });
});

// Export app for testing and integration
module.exports = app;

// Start server if this file is executed directly
if (require.main === module) {
  const PORT = process.env.PORT || 5000;
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
}
