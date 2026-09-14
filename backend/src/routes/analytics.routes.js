const express = require('express');
const router = express.Router();
const analyticsController = require('../controllers/analytics.controller.js');
const authenticateToken = require('../middleware/auth.middleware.js');

/**
 * @route GET /api/analytics/summary
 * @desc Get Unified Health Summary and Rolling Trends
 * @access Private
 */
router.get('/summary', authenticateToken, analyticsController.getAnalyticsSummary);

module.exports = router;
