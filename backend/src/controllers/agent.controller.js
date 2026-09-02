const { query, pool } = require('../db/index.js');
const { GoogleGenerativeAI } = require('@google/generative-ai');

/**
 * Agent Controller - Phase 9: AI Meal Planning Module
 * Handles AI-generated personalized meal plan generation with support for:
 * - Ethiopian Orthodox fasting awareness (የጾም ወቅት)
 * - Glycemic load optimization
 * - Bilingual content (English/Amharic)
 */

// Fetch user context for meal plan generation
const fetchUserContext = async (userId) => {
  // Default values
  const defaults = {
    goals: { daily_calorie_target: null, daily_protein_target_g: null, daily_carbs_target_g: null,
      daily_fat_target_g: null, glycemic_load_low_threshold: 10, glycemic_load_medium_threshold: 19,
      preferred_language: 'en', goal_focus: 'maintenance' },
    healthProfile: { age: null, gender: null, height_cm: null, weight_kg: null, activity_level: 'moderate' }
  };

  // Fetch user goals
  try {
    const g = await query('SELECT * FROM user_goals WHERE user_id = $1', [userId]);
    if (g.rows.length > 0) defaults.goals = { ...defaults.goals, ...g.rows[0] };
  } catch (_) {}

  // Fetch health profile
  try {
    const p = await query('SELECT * FROM health_profiles WHERE user_id = $1', [userId]);
    if (p.rows.length > 0) defaults.healthProfile = { ...defaults.healthProfile, ...p.rows[0] };
  } catch (_) {}

  // Fetch recent meals
  let recentMeals = [];
  try {
    const m = await query(`SELECT meal_type, food_name, calories FROM user_meals WHERE user_id = $1 AND logged_at >= NOW() - INTERVAL '7 days' ORDER BY logged_at DESC LIMIT 20`, [userId]);
    recentMeals = m.rows;
  } catch (_) {}

  // Fetch available foods
  let foods = [];
  try {
    const f = await query(`SELECT id, name, calories, protein_g, carbs_g, fat_g, serving_size FROM food_items ORDER BY name->>'en' LIMIT 50`);
    foods = f.rows;
  } catch (_) {}

  return { goals: defaults.goals, healthProfile: defaults.healthProfile, recentMeals, availableFoods: foods };
};

// Construct culturally-aware prompt for Gemini AI meal plan generation
const constructMealPlanPrompt = (userContext, planDate, isFastingDay = false) => {
  const { goals, healthProfile, recentMeals, availableFoods } = userContext;
  const foodsList = availableFoods.map(f => ({
    id: f.id, name: f.name, calories: f.calories,
    protein_g: f.protein_g, carbs_g: f.carbs_g, fat_g: f.fat_g
  }));
  const mealStyle = isFastingDay
    ? 'FASTING_COMPLIANT (vegan/vegetarian - Ethiopian Orthodox fasting)'
    : 'BALANCED (includes proteins)';

  return `You are an expert nutrition advisor for Ethiopian cuisine.
Date: ${planDate}${isFastingDay ? '\n⚠️ FASTING DAY - all meals must be plant-based.' : ''}

## USER PROFILE
- Age: ${healthProfile.age || 'N/A'}, Gender: ${healthProfile.gender || 'N/A'}
- Weight: ${healthProfile.weight_kg ? `${healthProfile.weight_kg} kg` : 'N/A'}, Activity: ${healthProfile.activity_level || 'moderate'}
- Goal: ${goals.goal_focus || 'maintenance'}, Language: ${goals.preferred_language || 'en'}

## NUTRITIONAL TARGETS
- Calories: ${goals.daily_calorie_target || '2000'}, Protein: ${goals.daily_protein_target_g || 'N/A'}g
- GL Thresholds: Low ≤ ${goals.glycemic_load_low_threshold}, Medium ≤ ${goals.glycemic_load_medium_threshold}

## AVAILABLE FOODS
${JSON.stringify(foodsList, null, 2)}

## RECENT MEALS
${recentMeals.length > 0 ? recentMeals.slice(0, 5).map(m => `- ${m.meal_type}: ${m.food_name}`).join('\n') : 'None'}

## TASK
Generate a daily meal plan (${mealStyle}) with breakfast, lunch, dinner, snack.
Each meal needs: food_name, name_am, recipe_id (or null), calories, glycemic_load, macronutrients {protein_g, carbs_g, fat_g}, description.

## OUTPUT (JSON ONLY)
{
  "is_fasting_meal": ${isFastingDay},
  "recommendation_source": "gemini_ai",
  "meals": [
    {"meal_type": "breakfast", "food_name": "...", "name_am": "...", "recipe_id": null, "calories": 0.00, "glycemic_load": 0.00, "macronutrients": {"protein_g": 0, "carbs_g": 0, "fat_g": 0}, "description": "..."},
    {"meal_type": "lunch", "food_name": "...", "name_am": "...", "recipe_id": null, "calories": 0.00, "glycemic_load": 0.00, "macronutrients": {"protein_g": 0, "carbs_g": 0, "fat_g": 0}, "description": "..."},
    {"meal_type": "dinner", "food_name": "...", "name_am": "...", "recipe_id": null, "calories": 0.00, "glycemic_load": 0.00, "macronutrients": {"protein_g": 0, "carbs_g": 0, "fat_g": 0}, "description": "..."},
    {"meal_type": "snack", "food_name": "...", "name_am": "...", "recipe_id": null, "calories": 0.00, "glycemic_load": 0.00, "macronutrients": {"protein_g": 0, "carbs_g": 0, "fat_g": 0}, "description": "..."}
  ]
}
Use Ethiopian staples (teff, injera, shiro, legumes). Return ONLY JSON.`;
};

// Parse & validate AI response JSON
const parseAiResponse = (responseText) => {
  try {
    // Strip markdown code blocks
    let cleaned = responseText.trim()
      .replace(/^```json\n?/, '')
      .replace(/^```\n?/, '')
      .replace(/\n?```$/, '')
      .trim();

    const parsed = JSON.parse(cleaned);
    if (!parsed.meals || !Array.isArray(parsed.meals) || parsed.meals.length !== 4) {
      throw new Error('Expected 4-element meals array');
    }

    const validTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
    const validatedMeals = [];

    for (const meal of parsed.meals) {
      if (!validTypes.includes(meal.meal_type)) {
        throw new Error(`Invalid meal_type: ${meal.meal_type}`);
      }
      validatedMeals.push({
        meal_type: meal.meal_type,
        food_name: meal.food_name || 'Unknown',
        name_am: meal.name_am || null,
        recipe_id: meal.recipe_id || null,
        calories: parseFloat(meal.calories) || 0,
        glycemic_load: parseFloat(meal.glycemic_load) || 0,
        macronutrients: {
          protein_g: parseFloat(meal.macronutrients?.protein_g) || 0,
          carbs_g: parseFloat(meal.macronutrients?.carbs_g) || 0,
          fat_g: parseFloat(meal.macronutrients?.fat_g) || 0
        },
        description: meal.description || ''
      });
    }

    return {
      is_fasting_meal: parsed.is_fasting_meal === true,
      recommendation_source: parsed.recommendation_source || 'gemini_ai',
      meals: validatedMeals
    };
  } catch (error) {
    throw error instanceof SyntaxError
      ? new Error(`JSON parse error: ${error.message}`)
      : error;
  }
};

// Insert meal plan rows into meal_plans table
const insertMealPlanRows = async (userId, planDate, mealPlan) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const insertedMeals = [];

    for (const meal of mealPlan.meals) {
      const result = await client.query(`
        INSERT INTO meal_plans (
          user_id, plan_date, meal_type, recipe_id, glycemic_load,
          calories, macronutrients, is_fasting_meal, recommendation_source
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
        RETURNING id, user_id, plan_date, meal_type, recipe_id, glycemic_load, calories, macronutrients, is_fasting_meal, recommendation_source, created_at
      `, [
        userId, planDate, meal.meal_type, meal.recipe_id || null,
        meal.glycemic_load, meal.calories, JSON.stringify(meal.macronutrients),
        mealPlan.is_fasting_meal, mealPlan.recommendation_source
      ]);
      insertedMeals.push(result.rows[0]);
    }

    await client.query('COMMIT');
    return insertedMeals;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

// ============================================================================
// Main Controller Functions
// ============================================================================

// POST /api/agent/generate-meal-plan
const generateMealPlan = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { plan_date, is_fasting_day = false } = req.body || {};

    if (typeof is_fasting_day !== 'boolean') {
      return res.status(400).json({ error: 'Invalid input', message: 'is_fasting_day must be a boolean' });
    }

    let planDate;
    if (plan_date) {
      if (!/^\d{4}-\d{2}-\d{2}$/.test(plan_date)) {
        return res.status(400).json({ error: 'Invalid input', message: 'plan_date must be YYYY-MM-DD' });
      }
      planDate = plan_date;
    } else {
      planDate = new Date().toISOString().split('T')[0];
    }

    // Step 1: Fetch user context
    const userContext = await fetchUserContext(userId);
    // Step 2: Construct prompt
    const prompt = constructMealPlanPrompt(userContext, planDate, is_fasting_day);
    // Step 3: Call Gemini API
    const apiKey = process.env.GEMINI_API_KEY?.trim();
    if (!apiKey) throw new Error('GEMINI_API_KEY is not defined');

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: process.env.GEMINI_MODEL || 'gemini-3.6-flash-latest' });

    let result;
    try {
      result = await model.generateContent(prompt);
    } catch (apiError) {
      throw new Error(`Gemini API Error: ${apiError.message}`);
    }

    const responseText = result.response.text();
    if (!responseText) throw new Error('No response from Gemini API');

    // Step 4: Parse AI response
    const mealPlan = parseAiResponse(responseText);
    // Step 5: Insert into database
    const insertedMeals = await insertMealPlanRows(userId, planDate, mealPlan);

    return res.status(201).json({
      success: true, message: 'Meal plan generated and saved',
      plan_date: planDate, is_fasting_meal: mealPlan.is_fasting_meal,
      recommendation_source: mealPlan.recommendation_source,
      meals: insertedMeals,
      summary: {
        total_calories: insertedMeals.reduce((s, m) => s + parseFloat(m.calories), 0).toFixed(2),
        total_glycemic_load: insertedMeals.reduce((s, m) => s + parseFloat(m.glycemic_load), 0).toFixed(2),
        meal_count: insertedMeals.length
      }
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/agent/meal-plans
const getMealPlans = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { start_date, end_date, limit = 50 } = req.query;

    let where = ['user_id = $1'], values = [userId], idx = 2;
    if (start_date) { where.push(`plan_date >= $${idx++}`); values.push(start_date); }
    if (end_date) { where.push(`plan_date <= $${idx++}`); values.push(end_date); }
    values.push(parseInt(limit, 10));

    const result = await query(`
      SELECT id, plan_date, meal_type, recipe_id, glycemic_load, calories, macronutrients, is_fasting_meal, recommendation_source, created_at, updated_at
      FROM meal_plans WHERE ${where.join(' AND ')}
      ORDER BY plan_date DESC, CASE meal_type WHEN 'breakfast' THEN 1 WHEN 'lunch' THEN 2 WHEN 'dinner' THEN 3 WHEN 'snack' THEN 4 END
      LIMIT $${idx}
    `, values);

    return res.status(200).json({ meal_plans: result.rows, count: result.rows.length });
  } catch (error) {
    next(error);
  }
};

// DELETE /api/agent/meal-plans/:id
const deleteMealPlan = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const idNum = parseInt(id, 10);

    if (isNaN(idNum) || idNum <= 0) {
      return res.status(400).json({ error: 'Invalid input', message: 'Invalid meal plan ID' });
    }

    const result = await query('DELETE FROM meal_plans WHERE id = $1 AND user_id = $2 RETURNING id, plan_date, meal_type', [idNum, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Meal plan not found or does not belong to user' });
    }

    return res.status(200).json({ success: true, message: 'Meal plan deleted', deleted: result.rows[0] });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  generateMealPlan, getMealPlans, deleteMealPlan,
  fetchUserContext, constructMealPlanPrompt, parseAiResponse, insertMealPlanRows
};
