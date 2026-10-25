const axios = require('axios');
const { query } = require('../db');

/// Initialize Chapa v2 payment session (Supports ETB and USD in cents)
const initializePayment = async (req, res) => {
  try {
    const { amount = '99', currency = 'ETB', moduleType = 'subscription' } = req.body;
    const userId = req.user?.id;
    const email = req.user?.email || 'user@example.com';
    const firstName = req.user?.first_name || 'Valued';
    const lastName = req.user?.last_name || 'Customer';

    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized user' });
    }

    const txRef = `tx-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

    // Save pending transaction in PostgreSQL
    await query(
      `INSERT INTO transactions (tx_ref, user_id, amount, currency, status, module_type) VALUES ($1, $2, $3, $4, $5, $6)`,
      [txRef, userId, amount, currency, 'pending', moduleType]
    );

    const frontendUrl = process.env.FRONTEND_URL || 'http://localhost:58460';

    // Convert amount to cents (e.g., 99 -> 9900) as required by Chapa v2
    const amountInCents = Math.round(Number(amount) * 100);

    const chapaResponse = await axios.post(
      'https://api.chapa.global/v2/payments/hosted',
      {
        amount: amountInCents,
        currency: currency.toUpperCase(),
        customer: {
          email,
          first_name: firstName,
          last_name: lastName
        },
        customization: {
          title: 'Smart Nutrition and Health',
          description: 'Premium Subscription'
        },
        meta: {
          tx_ref: txRef
        },
        return_url: `${frontendUrl}/payment-success?tx_ref=${txRef}`
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.CHAPA_SECRET_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );

    const responseData = chapaResponse.data;
    const checkoutUrl = responseData?.data?.checkout_url || responseData?.checkout_url;

    if (chapaResponse.status === 200 && checkoutUrl) {
      return res.status(200).json({
        success: true,
        checkoutUrl,
        txRef
      });
    } else {
      return res.status(400).json({ success: false, message: 'Failed to initialize Chapa payment session' });
    }
  } catch (error) {
    console.error('Initialize payment error:', error.response?.data || error.message);
    return res.status(500).json({ 
      success: false, 
      message: error.response?.data?.message || error.message || 'Payment initialization failed' 
    });
  }
};

/// Verify Chapa v2 transaction and upgrade user subscription
const verifyPayment = async (req, res) => {
  try {
    const { txRef } = req.params;

    const verifyResponse = await axios.get(
      `https://api.chapa.global/v2/payments/${txRef}/verify`,
      {
        headers: {
          Authorization: `Bearer ${process.env.CHAPA_SECRET_KEY}`
        }
      }
    );

    const paymentStatus = verifyResponse.data?.status || verifyResponse.data?.data?.status;

    if (verifyResponse.status === 200 && paymentStatus === 'success') {
      await query(
        `UPDATE transactions SET status = 'success' WHERE tx_ref = $1`,
        [txRef]
      );

      const txResult = await query(`SELECT user_id FROM transactions WHERE tx_ref = $1`, [txRef]);
      if (txResult.rows.length > 0) {
        const userId = txResult.rows[0].user_id;

        await query(
          `INSERT INTO subscriptions (user_id, plan_type, status, start_date, end_date) 
           VALUES ($1, 'premium', 'active', NOW(), NOW() + INTERVAL '30 days')
           ON CONFLICT (user_id) 
           DO UPDATE SET plan_type = 'premium', status = 'active', start_date = NOW(), end_date = NOW() + INTERVAL '30 days'`,
          [userId]
        );
      }

      return res.status(200).json({ success: true, message: 'Payment verified successfully' });
    } else {
      return res.status(400).json({ success: false, message: 'Payment verification failed with Chapa' });
    }
  } catch (error) {
    console.error('Verify payment error:', error.response?.data || error.message);
    return res.status(500).json({ 
      success: false, 
      message: error.response?.data?.message || error.message || 'Payment verification error' 
    });
  }
};

module.exports = {
  initializePayment,
  verifyPayment
};