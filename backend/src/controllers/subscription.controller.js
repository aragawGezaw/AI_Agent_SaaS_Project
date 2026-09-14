// Ensure env vars are loaded before any module that reads them is required.
require('dotenv').config();

const stripeService = require('../services/stripe.service');
const { query } = require('../db');

/**
 * Subscription Controller
 * Handles subscription-related HTTP requests for Stripe integration
 * and PostgreSQL subscription status management.
 */
class SubscriptionController {
  /**
   * @route POST /api/subscription/checkout
   * @desc Create a Stripe checkout session for premium subscription
   * @access Private (requires authentication)
   * 
   * Uses process.env.STRIPE_PREMIUM_PRICE_ID to create a checkout session.
   * Returns the Stripe checkout URL for the frontend to redirect the user.
   */
  async createCheckoutSession(req, res, next) {
    try {
      const userId = req.user.id;

      // Validate Stripe configuration
      if (!process.env.STRIPE_SECRET_KEY) {
        console.error('[SubscriptionController] Stripe secret key not configured');
        return res.status(500).json({
          error: 'Payment service not configured',
          message: 'Stripe is not properly configured on the server'
        });
      }

      if (!process.env.STRIPE_PREMIUM_PRICE_ID || process.env.STRIPE_PREMIUM_PRICE_ID === 'price_placeholder') {
        console.error('[SubscriptionController] Stripe price ID not configured');
        return res.status(500).json({
          error: 'Payment plan not configured',
          message: 'Premium subscription price is not set up on the server'
        });
      }

      // Fetch user email from database
      const userResult = await query('SELECT email FROM users WHERE id = $1', [userId]);
      const email = userResult.rows[0]?.email;

      if (!email) {
        console.error(`[SubscriptionController] User email not found for userId: ${userId}`);
        return res.status(404).json({
          error: 'User not found',
          message: 'Could not find user email address'
        });
      }

      console.log(`[SubscriptionController] Creating checkout session for user ${userId} (${email})`);

      // Create Stripe checkout session
      const session = await stripeService.createCheckoutSession(userId, email);

      console.log(`[SubscriptionController] Checkout session created: ${session.id}`);
      res.status(200).json({ url: session.url });

    } catch (error) {
      // Diagnostic catch: surface the real exception to the client AND the server log.
      // This intentionally overrides the global "Internal Server Error" handler so the
      // Flutter app can display the actual cause instead of a generic toast.
      console.error('DETAILED CHECKOUT ERROR:', error);
      return res.status(500).json({
        error: error.message,
        stack: error.stack,
      });
    }
  }

  /**
   * @route POST /api/subscription/portal
   * @desc Create a Stripe billing portal session for managing subscriptions
   * @access Private (requires authentication)
   * 
   * Creates a Stripe Customer Portal session allowing users to:
   * - View subscription details
   * - Update payment methods
   * - Cancel or pause subscriptions
   * - Download invoices
   */
  async openBillingPortal(req, res, next) {
    try {
      const userId = req.user.id;

      // Validate Stripe configuration
      if (!process.env.STRIPE_SECRET_KEY) {
        console.error('[SubscriptionController] Stripe secret key not configured');
        return res.status(500).json({ 
          error: 'Payment service not configured',
          message: 'Stripe is not properly configured on the server'
        });
      }

      console.log(`[SubscriptionController] Creating billing portal session for user ${userId}`);

      // Create Stripe portal session
      const session = await stripeService.createPortalSession(userId);
      
      console.log(`[SubscriptionController] Billing portal session created: ${session.id}`);
      res.status(200).json({ url: session.url });

    } catch (error) {
      console.error('[SubscriptionController] openBillingPortal error:', error.message);
      
      // Handle specific Stripe errors
      if (error.message === 'User has no Stripe customer record') {
        return res.status(404).json({ 
          error: 'No subscription found',
          message: 'No active Stripe customer found. Please subscribe first.'
        });
      }
      
      next(error);
    }
  }


  /**
   * @route GET /api/subscription/status
   * @desc Get current user's subscription status and feature gating
   * @access Private (requires authentication)
   * 
   * Queries PostgreSQL for the user's subscription record.
   * Returns plan type, status, period end, and feature gating flags.
   * Returns a default 'free' subscription object if no record exists.
   */
  async getSubscriptionStatus(req, res, next) {
    try {
      const userId = req.user.id;

      console.log(`[SubscriptionController] Fetching subscription status for user ${userId}`);

      const result = await query(
        `SELECT 
           id, 
           user_id, 
           plan_type, 
           status, 
           current_period_end,
           stripe_customer_id, 
           stripe_subscription_id,
           created_at, 
           updated_at, 
           feature_gating
         FROM subscriptions 
         WHERE user_id = $1`,
        [userId]
      );

      const subscription = result.rows[0];

      if (!subscription) {
        // Return default free subscription for users without a record
        console.log(`[SubscriptionController] No subscription record for user ${userId}, returning default free plan`);
        return res.status(200).json({
          id: null,
          user_id: userId,
          plan_type: 'free',
          status: 'active',
          current_period_end: null,
          stripe_customer_id: null,
          stripe_subscription_id: null,
          created_at: new Date().toISOString(),
          updated_at: null,
          feature_gating: {
            generate_meal_plan: false,
            full_gl_tracking: false,
            advanced_analytics: false,
            fasting_tracking: false
          }
        });
      }

      // Ensure feature_gating has defaults for older records
      const featureGating = subscription.feature_gating || {};
      subscription.feature_gating = {
        generate_meal_plan: featureGating.generate_meal_plan ?? false,
        full_gl_tracking: featureGating.full_gl_tracking ?? false,
        advanced_analytics: featureGating.advanced_analytics ?? false,
        fasting_tracking: featureGating.fasting_tracking ?? false,
        ...featureGating
      };

      console.log(`[SubscriptionController] Subscription status for user ${userId}: ${subscription.plan_type}/${subscription.status}`);
      res.status(200).json(subscription);

    } catch (error) {
      console.error('[SubscriptionController] getSubscriptionStatus error:', error.message);
      next(error);
    }
  }

  /**
   * @route POST /api/subscription/webhook
   * @desc Handle incoming Stripe webhook events
   * @access Public (Stripe signature verification required)
   * 
   * Processes the following Stripe events:
   * - checkout.session.completed: Activates premium subscription
   * - customer.subscription.updated: Syncs subscription status changes
   * - customer.subscription.deleted: Marks subscription as cancelled
   * - invoice.payment_succeeded: Updates subscription as active
   * - invoice.payment_failed: Marks subscription as unpaid
   */
  async handleStripeWebhook(req, res, next) {
    const sig = req.headers['stripe-signature'];

    // Validate webhook secret configuration
    if (!process.env.STRIPE_WEBHOOK_SECRET) {
      console.error('[SubscriptionController] Stripe webhook secret not configured');
      return res.status(500).json({ 
        error: 'Webhook not configured',
        message: 'Stripe webhook secret is not set up on the server'
      });
    }

    try {
      const payload = req.body; // Raw body already parsed by middleware
      console.log(`[SubscriptionController] Processing Stripe webhook, signature: ${sig ? 'present' : 'missing'}`);

      await stripeService.handleWebhook(payload, sig);
      
      console.log('[SubscriptionController] Webhook processed successfully');
      res.status(200).json({ received: true });

    } catch (error) {
      console.error('[SubscriptionController] handleStripeWebhook error:', error.message);
      console.error('[SubscriptionController] Webhook payload verification failed - possible tampering or wrong secret');
      res.status(400).send(`Webhook Error: ${error.message}`);
    }
  }
}

module.exports = new SubscriptionController();