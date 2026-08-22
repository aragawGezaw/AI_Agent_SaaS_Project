const express = require('express');
const router = express.Router();
const stripeService = require('../services/stripe.service');
const authMiddleware = require('../middleware/auth.middleware');
const { query } = require('../db');

/**
 * @route GET /api/subscription/status
 * @desc Get current user subscription status
 * @access Private
 */
router.get('/status', authMiddleware, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const result = await query(
      'SELECT plan_type, status, current_period_end FROM subscriptions WHERE user_id = $1',
      [userId]
    );

    const subscription = result.rows[0] || { plan_type: 'free', status: 'active' };

    res.status(200).json(subscription);
  } catch (error) {
    next(error);
  }
});

/**
 * @route POST /api/subscription/checkout
 * @desc Create a Stripe checkout session for premium subscription
 * @access Private
 */
router.post('/checkout', authMiddleware, async (req, res, next) => {
  try {
    const userId = req.user.id;
    // We need the user email to create a Stripe customer
    const userRes = await query('SELECT email FROM users WHERE id = $1', [userId]);
    const email = userRes.rows[0]?.email;

    if (!email) {
      return res.status(404).json({ error: 'User email not found' });
    }

    const session = await stripeService.createCheckoutSession(userId, email);
    res.status(200).json({ url: session.url });
  } catch (error) {
    next(error);
  }
});

/**
 * @route POST /api/subscription/portal
 * @desc Create a Stripe billing portal session
 * @access Private
 */
router.post('/portal', authMiddleware, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const session = await stripeService.createPortalSession(userId);
    res.status(200).json({ url: session.url });
  } catch (error) {
    next(error);
  }
});

/**
 * @route POST /api/subscription/webhook
 * @desc Handle Stripe webhook events
 * @access Public (Stripe Signature required)
 */
router.post('/webhook', express.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const payload = req.body;

  try {
    await stripeService.handleWebhook(payload, sig);
    res.status(200).json({ received: true });
  } catch (error) {
    console.error('Webhook Error:', error.message);
    res.status(400).send(`Webhook Error: ${error.message}`);
  }
});

module.exports = router;
