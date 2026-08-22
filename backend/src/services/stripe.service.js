const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
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
   * @param {Buffer} payload - Raw request body
   * @param {string} sig - Stripe signature header
   */
  async handleWebhook(payload, sig) {
    let event;

    try {
      event = stripe.webhooks.constructEvent(payload, sig, process.env.STRIPE_WEBHOOK_SECRET);
    } catch (err) {
      console.error(`Webhook Error: ${err.message}`);
      throw new Error(`Webhook Error: ${err.message}`);
    }

    switch (event.type) {
      case 'checkout.session.completed': {
        const session = event.data.object;
        await this.updateSubscriptionStatus(session.customer, 'premium', 'active');
        break;
      }
      case 'customer.subscription.updated': {
        const subscription = event.data.object;
        const status = subscription.status === 'active' ? 'active' : 'expired';
        await this.updateSubscriptionStatus(subscription.customer, 'premium', status, subscription.current_period_end);
        break;
      }
      case 'customer.subscription.deleted': {
        const subscription = event.data.object;
        await this.updateSubscriptionStatus(subscription.customer, 'free', 'expired');
        break;
      }
      default:
        console.log(`Unhandled event type ${event.type}`);
    }
  }

  /**
   * Update subscription status in the database
   */
  async updateSubscriptionStatus(stripeCustomerId, planType, status, periodEnd = null) {
    const periodEndDate = periodEnd ? new Date(periodEnd * 1000) : null;
    
    await query(
      `UPDATE subscriptions 
       SET plan_type = $2, status = $3, current_period_end = $4, updated_at = CURRENT_TIMESTAMP 
       WHERE stripe_customer_id = $1`,
      [stripeCustomerId, planType, status, periodEndDate]
    );
  }
}

module.exports = new StripeService();
