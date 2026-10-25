const express = require('express');
const router = express.Router();

// Safely require auth middleware (handles both object and direct function exports)
const authModule = require('../middleware/auth.middleware');
const authenticateToken = typeof authModule === 'function' ? authModule : authModule.authenticateToken;

// Require controllers
const { initializePayment, verifyPayment } = require('../controllers/payment.controller');

// POST /api/payment/initialize
router.post('/initialize', authenticateToken, initializePayment);

// GET /api/payment/verify/:txRef
router.get('/verify/:txRef', authenticateToken, verifyPayment);

module.exports = router;