const express = require('express');
const router = express.Router();
const authenticateToken = require('../middleware/auth.middleware.js');
const { aiGenerationLimiter } = require('../middleware/rateLimiter');
const { generateMealPlan, getMealPlans, deleteMealPlan } = require('../controllers/agent.controller.js');

/**
 * @route POST /api/agent/generate-meal-plan
 * @desc Generate an AI-powered personalized meal plan and save it to the database
 * @access Private (requires JWT token + Rate Limiting)
 * 
 * Body:
 * {
 *   "plan_date": "YYYY-MM-DD" (optional, defaults to today),
 *   "is_fasting_day": boolean (optional, defaults to false - for Ethiopian Orthodox fasting / የጾም ቀን)
 * }
 */
router.post('/generate-meal-plan', authenticateToken, aiGenerationLimiter, generateMealPlan);

/**
 * @route GET /api/agent/meal-plans
 * @desc Get user's meal plans with optional date filtering
 * @access Private
 * 
 * Query params:
 * - start_date: YYYY-MM-DD (optional)
 * - end_date: YYYY-MM-DD (optional)
 * - limit: number (optional, default 50)
 */
router.get('/meal-plans', authenticateToken, getMealPlans);

/**
 * @route DELETE /api/agent/meal-plans/:id
 * @desc Delete a specific meal plan entry by ID
 * @access Private
 */
router.delete('/meal-plans/:id', authenticateToken, deleteMealPlan);

module.exports = router;