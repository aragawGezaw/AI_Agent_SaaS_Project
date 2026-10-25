const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const { pool, query } = require('./db/index.js');

// 1. Initialize Express app FIRST
const app = express();

// 2. Configure CORS
app.use(cors({
  origin: process.env.CORS_ORIGIN || '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

// 3. Configure JSON body parser middleware
app.use((req, res, next) => {
  if (req.originalUrl === '/api/subscription/webhook') {
    next();
  } else {
    express.json()(req, res, next);
  }
});

// 4. Request logging middleware
app.use(morgan('dev'));

// 5. Import all route modules
const authRouter = require('./routes/auth.routes.js');
const profileRouter = require('./routes/profile.routes.js');
const nutritionRouter = require('./routes/nutrition.routes.js');
const chatRouter = require('./routes/chat.routes.js');
const subscriptionRouter = require('./routes/subscription.routes.js');
const foodRouter = require('./routes/food.routes.js');
const mealHistoryRouter = require('./routes/meal_history.routes.js');
const userGoalsRouter = require('./routes/user_goals.routes.js');
const resourcesRouter = require('./routes/resources.routes.js');
const agentRouter = require('./routes/agent.routes.js');
const analyticsRouter = require('./routes/analytics.routes.js');
const notificationsRouter = require('./routes/notifications.routes.js');
const paymentRoutes = require('./routes/payment.routes.js'); // Added Chapa/Telebirr payment routes

// 6. Mount all routes cleanly on `app`
app.use('/api/auth', authRouter);
app.use('/api/profile', profileRouter);
app.use('/api/nutrition', nutritionRouter);
app.use('/api/chat', chatRouter);
app.use('/api/subscription', subscriptionRouter);
app.use('/api/foods', foodRouter);
app.use('/api/meal-history', mealHistoryRouter);
app.use('/api/user/goals', userGoalsRouter);
app.use('/api/resources', resourcesRouter);
app.use('/api/agent', agentRouter);
app.use('/api/analytics', analyticsRouter);
app.use('/api/notifications', notificationsRouter);
app.use('/api/payment', paymentRoutes); // Mounted Chapa payment gateway

/**
 * @route GET /api/health
 * @desc Basic health-check route verifying server uptime and database connectivity
 * @access Public
 */
app.get('/api/health', async (req, res) => {
  try {
    const dbResult = await query('SELECT NOW()');
    
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

// Start notification scheduler (only when server is the entry point)
try {
  const { startScheduler } = require('./services/notification.scheduler.js');
  startScheduler();
} catch (err) {
  console.error('Failed to start notification scheduler:', err.message);
}

// Start server if this file is executed directly
if (require.main === module) {
  const PORT = process.env.PORT || 5000;
  app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
  });
}