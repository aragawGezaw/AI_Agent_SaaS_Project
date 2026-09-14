const { query } = require('../db');

const VALID_ERROR_CODES = [
  'SUBSCRIPTION_REQUIRED',
  'PREMIUM_REQUIRED',
  'SUBSCRIPTION_INACTIVE',
  'SUBSCRIPTION_EXPIRED',
  'FEATURE_NOT_AVAILABLE',
];

async function subscriptionMiddleware(requiredFeatures = []) {
  return async (req, res, next) => {
    try {
      if (!req.user || !req.user.id) {
        return res.status(401).json({ code: 'UNAUTHORIZED', message: 'Authentication required' });
      }

      const result = await query(
        'SELECT plan_type, status, current_period_end, feature_gating FROM subscriptions WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1',
        [req.user.id]
      );

      const sub = result.rows[0];

      if (!sub) {
        return res.status(403).json({ code: 'SUBSCRIPTION_REQUIRED', message: 'No subscription found' });
      }

      if (sub.status === 'cancelled' || sub.status === 'inactive') {
        return res.status(403).json({ code: 'SUBSCRIPTION_INACTIVE', message: 'Subscription is inactive' });
      }

      if (sub.status === 'expired' || (sub.current_period_end && new Date(sub.current_period_end) < new Date())) {
        return res.status(403).json({ code: 'SUBSCRIPTION_EXPIRED', message: 'Subscription has expired' });
      }

      if (sub.plan_type !== 'premium' && sub.plan_type !== 'admin') {
        return res.status(403).json({ code: 'PREMIUM_REQUIRED', message: 'Premium subscription required', features: requiredFeatures });
      }

      if (requiredFeatures.length > 0) {
        const features = sub.feature_gating || {};
        const missing = requiredFeatures.filter(f => !features[f]);
        if (missing.length > 0) {
          return res.status(403).json({ code: 'FEATURE_NOT_AVAILABLE', message: 'Feature not available', features: requiredFeatures, missing_features: missing });
        }
      }

      req.subscription = sub;
      next();
    } catch (err) {
      console.error('Subscription middleware error:', err);
      res.status(500).json({ code: 'INTERNAL_ERROR', message: 'Failed to verify subscription' });
    }
  };
}

module.exports = { subscriptionMiddleware };
