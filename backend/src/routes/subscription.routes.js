const express = require('express');
const router = express.Router();
const subscriptionController = require('../controllers/subscription.controller');
const authMiddleware = require('../middleware/auth.middleware');

/**
 * @route GET /api/subscription/status
 * @desc Get current user subscription status and feature gating
 * @access Private (requires authentication)
 */
router.get('/status', authMiddleware, subscriptionController.getSubscriptionStatus);

/**
 * @route POST /api/subscription/checkout
 * @desc Create a checkout session for premium subscription upgrade
 * @access Private (requires authentication)
 */
router.post('/checkout', authMiddleware, subscriptionController.createCheckoutSession);

/**
 * @route POST /api/subscription/portal
 * @desc Create a billing portal session for managing subscriptions
 * @access Private (requires authentication)
 */
router.post('/portal', authMiddleware, subscriptionController.openBillingPortal);

/**
 * @route POST /api/subscription/cancel
 * @desc Cancel the user's active subscription (sets status to 'cancelled')
 * @access Private (requires authentication)
 */
router.post('/cancel', authMiddleware, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { query } = require('../db');
    const result = await query(
      `UPDATE subscriptions
       SET status = 'cancelled', updated_at = NOW()
       WHERE user_id = $1 AND status = 'active'
       RETURNING *`,
      [userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ code: 'NO_ACTIVE_SUBSCRIPTION', message: 'No active subscription found' });
    }
    res.status(200).json({ success: true, message: 'Subscription cancelled' });
  } catch (error) {
    next(error);
  }
});

/**
 * @route POST /api/subscription/resume
 * @desc Resume a previously cancelled subscription
 * @access Private (requires authentication)
 */
router.post('/resume', authMiddleware, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { query } = require('../db');
    const result = await query(
      `UPDATE subscriptions
       SET status = 'active', updated_at = NOW()
       WHERE user_id = $1 AND status = 'cancelled'
       RETURNING *`,
      [userId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ code: 'NO_CANCELLED_SUBSCRIPTION', message: 'No cancelled subscription found' });
    }
    res.status(200).json({ success: true, message: 'Subscription resumed' });
  } catch (error) {
    next(error);
  }
});

/**
 * @route POST /api/subscription/webhook
 * @desc Handle payment webhook events
 * @access Public (Signature required)
 */
router.post(
  '/webhook',
  express.raw({ type: 'application/json' }),
  subscriptionController.handleStripeWebhook
);

module.exports = router;