const rateLimit = require('express-rate-limit');

// Dedicated rate limiter for AI generation endpoints
const aiGenerationLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15-minute window
  max: 10, // Limit each user/IP to 10 generation requests per window
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: 'Generation limit reached. Please wait 15 minutes before creating a new meal plan.',
  },
});

module.exports = { aiGenerationLimiter };