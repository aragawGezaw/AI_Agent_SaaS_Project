// Load environment variables BEFORE initializing Stripe so STRIPE_SECRET_KEY is available.
require('dotenv').config();

const stripeSecretKey = process.env.STRIPE_SECRET_KEY;
if (!stripeSecretKey) {
  console.error('[StripeService] FATAL: process.env.STRIPE_SECRET_KEY is not set. Stripe is not configured.');
}

const stripe = require('stripe')(stripeSecretKey || 'sk_test_placeholder_invalid_key');
const { query } = require('../db');

/**
 * Stripe Service for handling subscription operations
 */
class StripeService {
  /**
   * Create or retrieve a Stripe customer for a user
   * @param {string} userId - Internal user ID
   * @param {string} email - User email
   * @returns {Promise<string>} - Stripe Customer ID
   */
  async getOrCreateCustomer(userId, email) {
    // Check if user already has a stripe_customer_id in our DB
    const res = await query('SELECT stripe_customer_id FROM subscriptions WHERE user_id = $1', [userId]);
    
    if (res.rows[0]?.stripe_customer_id) {
      return res.rows[0].stripe_customer_id;
    }

    // Create new customer in Stripe
    const customer = await stripe.customers.create({
      email,
      metadata: { userId }
    });

    // Update or insert into subscriptions table
    await query(
      `INSERT INTO subscriptions (user_id, stripe_customer_id) 
       VALUES ($1, $2) 
       ON CONFLICT (user_id) DO UPDATE SET stripe_customer_id = $2`,
      [userId, customer.id]
    );

    return customer.id;
  }

  /**
   * Create a checkout session for a subscription
   * @param {string} userId - User ID
   * @param {string} email - User email
   * @returns {Promise<Object>} - Checkout Session object
   */
  async createCheckoutSession(userId, email) {
    const customerId = await this.getOrCreateCustomer(userId, email);

    const session = await stripe.checkout.sessions.create({
      customer: customerId,
      payment_method_types: ['card'],
      line_items: [
        {
          price: process.env.STRIPE_PREMIUM_PRICE_ID,
          quantity: 1,
        },
      ],
      mode: 'subscription',
      success_url: `${process.env.FRONTEND_URL}/subscription/success?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${process.env.FRONTEND_URL}/subscription/cancel`,
      metadata: { userId }
    });

    return session;
  }

  /**
   * Create a Billing Portal session
   * @param {string} userId - User ID
   * @returns {Promise<Object>} - Portal Session object
   */
  async createPortalSession(userId) {
    const res = await query('SELECT stripe_customer_id FROM subscriptions WHERE user_id = $1', [userId]);
    const customerId = res.rows[0]?.stripe_customer_id;

    if (!customerId) {
      throw new Error('User has no Stripe customer record');
    }

    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: `${process.env.FRONTEND_URL}/profile`,
    });

    return session;
  }

  /**
   * Handle Stripe webhook events
   * @param {Buffer|string} payload - Raw request body
   * @param {string} sig - Stripe signature header
   */
  async handleWebhook(payload, sig) {
    let event;

    try {
      event = stripe.webhooks.constructEvent(payload, sig, process.env.STRIPE_WEBHOOK_SECRET);
    } catch (err) {
      console.error(`Webhook Signature Verification Failed: ${err.message}`);
      throw new Error(`Webhook Error: ${err.message}`);
    }

    console.log(`Received Stripe Webhook event: ${event.type}`);

    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object;
        const customerId = session.customer;
        const subscriptionId = session.subscription;
        
        let currentPeriodEnd = null;
        if (subscriptionId) {
          try {
            const sub = await stripe.subscriptions.retrieve(subscriptionId);
            currentPeriodEnd = sub.current_period_end;
          } catch (e) {
            console.error('Failed to retrieve subscription info:', e.message);
          }
        }
        
        await this.updateSubscriptionStatus(
          customerId, 
          'premium', 
          'active', 
          currentPeriodEnd, 
          subscriptionId
        );
        break;
      }
      
      case 'customer.subscription.created': {
        const subscription = event.data.object;
        const customerId = subscription.customer;
        const subscriptionId = subscription.id;
        const status = subscription.status === 'active' ? 'active' : 'pending';
        
        await this.updateSubscriptionStatus(
          customerId,
          'premium',
          status,
          subscription.current_period_end,
          subscriptionId
        );
        break;
      }

      case 'customer.subscription.updated': {
        const subscription = event.data.object;
        const customerId = subscription.customer;
        const subscriptionId = subscription.id;
        const stripeStatus = subscription.status;
        
        let localStatus = 'inactive';
        if (stripeStatus === 'active' || stripeStatus === 'trialing') {
          localStatus = 'active';
        } else if (stripeStatus === 'canceled' || stripeStatus === 'unpaid') {
          localStatus = 'expired';
        } else if (subscription.cancel_at_period_end) {
          localStatus = 'cancelled';
        } else {
          localStatus = 'inactive';
        }

        const planType = (stripeStatus === 'active' || stripeStatus === 'trialing') ? 'premium' : 'free';

        await this.updateSubscriptionStatus(
          customerId,
          planType,
          localStatus,
          subscription.current_period_end,
          subscriptionId
        );
        break;
      }

      case 'customer.subscription.deleted': {
        const subscription = event.data.object;
        const customerId = subscription.customer;
        const subscriptionId = subscription.id;
        
        await this.updateSubscriptionStatus(
          customerId,
          'free',
          'expired',
          null,
          subscriptionId
        );
        break;
      }

      case 'invoice.payment_succeeded': {
        const invoice = event.data.object;
        const customerId = invoice.customer;
        const subscriptionId = invoice.subscription;
        
        if (subscriptionId) {
          let currentPeriodEnd = null;
          try {
            const sub = await stripe.subscriptions.retrieve(subscriptionId);
            currentPeriodEnd = sub.current_period_end;
          } catch (e) {
            console.error('Failed to retrieve subscription info for invoice payment:', e.message);
          }
          
          await this.updateSubscriptionStatus(
            customerId,
            'premium',
            'active',
            currentPeriodEnd,
            subscriptionId
          );
        }
        break;
      }

      case 'invoice.payment_failed': {
        const invoice = event.data.object;
        const customerId = invoice.customer;
        const subscriptionId = invoice.subscription;
        
        console.warn(`Payment failed for customer ${customerId}, subscription ${subscriptionId}`);
        await this.updateSubscriptionStatus(
          customerId,
          'premium',
          'unpaid',
          null,
          subscriptionId
        );
        break;
      }

      default:
        console.log(`Unhandled event type ${event.type}`);
    }
  }

  /**
   * Update subscription status in the database
   */
  async updateSubscriptionStatus(stripeCustomerId, planType, status, periodEnd = null, stripeSubscriptionId = null) {
    const periodEndDate = periodEnd ? new Date(periodEnd * 1000) : null;
    const featureGating = planType === 'premium'
      ? { generate_meal_plan: true, full_gl_tracking: true }
      : { generate_meal_plan: false, full_gl_tracking: false };

    try {
      const res = await query(
        `UPDATE subscriptions 
         SET plan_type = $2, 
             status = $3, 
             current_period_end = $4, 
             stripe_subscription_id = COALESCE($5, stripe_subscription_id),
             feature_gating = $6,
             updated_at = CURRENT_TIMESTAMP 
         WHERE stripe_customer_id = $1
         RETURNING *`,
        [stripeCustomerId, planType, status, periodEndDate, stripeSubscriptionId, JSON.stringify(featureGating)]
      );

      if (res.rows.length === 0) {
        console.warn(`No subscription found with stripe_customer_id = ${stripeCustomerId}. Attempting to locate user via Stripe metadata...`);
        const customer = await stripe.customers.retrieve(stripeCustomerId);
        const userId = customer.metadata?.userId;
        
        if (userId) {
          await query(
            `INSERT INTO subscriptions (user_id, stripe_customer_id, stripe_subscription_id, plan_type, status, current_period_end, feature_gating)
             VALUES ($1, $2, $3, $4, $5, $6, $7)
             ON CONFLICT (user_id) DO UPDATE 
             SET stripe_customer_id = $2,
                 stripe_subscription_id = COALESCE($3, subscriptions.stripe_subscription_id),
                 plan_type = $4,
                 status = $5,
                 current_period_end = $6,
                 feature_gating = $7,
                 updated_at = CURRENT_TIMESTAMP`,
            [userId, stripeCustomerId, stripeSubscriptionId, planType, status, periodEndDate, JSON.stringify(featureGating)]
          );
          console.log(`Successfully synced subscription for user ID ${userId} via metadata fallback.`);
        } else {
          console.error(`Unable to find user for stripe_customer_id = ${stripeCustomerId}. No metadata userId found.`);
        }
      } else {
        console.log(`Successfully updated subscription status for customer ${stripeCustomerId} to plan: ${planType}, status: ${status}`);
      }
    } catch (err) {
      console.error('Error in updateSubscriptionStatus:', err.message);
      throw err;
    }
  }
}

module.exports = new StripeService();
