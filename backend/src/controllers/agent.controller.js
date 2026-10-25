const { query, pool } = require('../db/index.js');
const { GoogleGenerativeAI } = require('@google/generative-ai');

/**
 * Agent Controller - Phase 9: AI Meal Planning Module
 * Handles AI-generated personalized meal plan generation with support for:
 * - Ethiopian Orthodox fasting awareness (የጾም ወቅት / የጾም ቀን)
 * - Glycemic load optimization & 30g protein clinical threshold per main meal
 * - Strict localized language enforcement (English / Amharic)
 * - Unique, dish-specific recipes, ingredients, and instructions
 */

// Fetch user context for meal plan generation
const fetchUserContext = async (userId) => {
  const defaults = {
    goals: { daily_calorie_target: null, daily_protein_target_g: null, daily_carbs_target_g: null,
      daily_fat_target_g: null, glycemic_load_low_threshold: 10, glycemic_load_medium_threshold: 19,
      preferred_language: 'am', goal_focus: 'maintenance' },
    healthProfile: { age: null, gender: null, height_cm: null, weight_kg: null, activity_level: 'moderate' }
  };

  try {
    const g = await query('SELECT * FROM user_goals WHERE user_id = $1', [userId]);
    if (g.rows.length > 0) defaults.goals = { ...defaults.goals, ...g.rows[0] };
  } catch (_) {}

  try {
    const p = await query('SELECT * FROM health_profiles WHERE user_id = $1', [userId]);
    if (p.rows.length > 0) defaults.healthProfile = { ...defaults.healthProfile, ...p.rows[0] };
  } catch (_) {}

  let recentMeals = [];
  try {
    const m = await query(`SELECT meal_type, food_name, calories FROM user_meals WHERE user_id = $1 AND logged_at >= NOW() - INTERVAL '7 days' ORDER BY logged_at DESC LIMIT 20`, [userId]);
    recentMeals = m.rows;
  } catch (_) {}

  let foods = [];
  try {
    const f = await query(`SELECT id, name, calories, protein_g, carbs_g, fat_g, serving_size FROM food_items ORDER BY name->>'en' LIMIT 50`);
    foods = f.rows;
  } catch (_) {}

  return { goals: defaults.goals, healthProfile: defaults.healthProfile, recentMeals, availableFoods: foods };
};

// Construct culturally-aware, clinically guarded prompt for Gemini AI meal plan generation
const constructMealPlanPrompt = (userContext, planDate, isFastingDay = false, requestedLang = 'am') => {
  const { goals, healthProfile, recentMeals, availableFoods } = userContext;
  const foodsList = availableFoods.map(f => ({
    id: f.id, name: f.name, calories: f.calories,
    protein_g: f.protein_g, carbs_g: f.carbs_g, fat_g: f.fat_g
  }));
  const mealStyle = isFastingDay
    ? 'FASTING_COMPLIANT (100% plant-based/vegan - Ethiopian Orthodox fasting / የጾም ቀን)'
    : 'BALANCED (incorporating complete proteins and local staples)';

  const lang = requestedLang || goals.preferred_language || 'am';
  
  const languageInstruction = lang === 'am'
    ? "CRITICAL LANGUAGE RULE: Write ALL food titles (food_name), descriptions, ingredient items (ingredients), and step-by-step instructions (instructions) 100% in authentic Amharic script (አማርኛ). Do NOT write ingredients or steps in English."
    : "Language Requirement: Write food names, ingredients, and step-by-step instructions in English.";

  return `You are an expert clinical nutritionist and metabolic health AI engine specializing in Ethiopian cuisine.
Date: ${planDate}${isFastingDay ? '\n⚠️ CRITICAL FASTING DAY (የጾም ቀን) - all generated meals must be 100% plant-based, with absolutely zero animal products, dairy, or eggs.' : ''}

## USER PROFILE
- Age: ${healthProfile.age || 'N/A'}, Gender: ${healthProfile.gender || 'N/A'}
- Weight: ${healthProfile.weight_kg ? `${healthProfile.weight_kg} kg` : 'N/A'}, Activity: ${healthProfile.activity_level || 'moderate'}
- Goal: ${goals.goal_focus || 'maintenance'}, Target Language: ${lang}

## CLINICAL GUARDRAILS & NUTRITIONAL TARGETS
- Calories: ${goals.daily_calorie_target || '2000'} kcal
- Protein Distribution Rule: Every main meal (Breakfast, Lunch, Dinner) MUST contain a minimum of 25g to 30g of high-quality protein to support muscle retention and blunt postprandial glucose spikes.
- Glycemic Load (GL) Control: Individual meal GL should remain low-to-moderate (< 15 GL per meal) by pairing complex carbohydrates with adequate fiber and protein. Thresholds: Low ≤ ${goals.glycemic_load_low_threshold}, Medium ≤ ${goals.glycemic_load_medium_threshold}
- UNIQUE RECIPES MANDATE: Each meal (breakfast, lunch, dinner, snack) MUST have completely DISTINCT, dish-specific ingredients and step-by-step cooking instructions corresponding directly to its unique "food_name". NEVER reuse or duplicate generic steps between meals.
- ${languageInstruction}

## AVAILABLE FOODS
${JSON.stringify(foodsList, null, 2)}

## RECENT MEALS
${recentMeals.length > 0 ? recentMeals.slice(0, 5).map(m => `- ${m.meal_type}:${m.food_name}`).join('\n') : 'None'}

## TASK
Generate a daily meal plan (${mealStyle}) with breakfast, lunch, dinner, and snack.
Each meal needs:
- food_name: Dish name in requested target language (${lang === 'am' ? 'አማርኛ' : 'English'})
- name_am: Amharic dish name translation
- recipe_id: null
- calories: number
- glycemic_load: number
- macronutrients: {protein_g, carbs_g, fat_g}
- description: Brief clinical/metabolic benefit description
- ingredients: Array of exact string items with portion weights/units in requested language (e.g., ${lang === 'am' ? '["100g የጤፍ እንጀራ", "50g የሽሮ ዱቄት"]' : '["100g Teff Injera", "50g Shiro flour"]'})
- instructions: Array of step-by-step traditional cooking instructions in requested language specific to this dish

## OUTPUT (JSON ONLY)
{
  "is_fasting_meal": ${isFastingDay},
  "recommendation_source": "gemini_ai",
  "meals": [
    {
      "meal_type": "breakfast",
      "food_name": "...",
      "name_am": "...",
      "recipe_id": null,
      "calories": 0.00,
      "glycemic_load": 0.00,
      "macronutrients": {"protein_g": 0, "carbs_g": 0, "fat_g": 0},
      "description": "...",
      "ingredients": ["...", "..."],
      "instructions": ["...", "..."]
    },
    {
      "meal_type": "lunch",
      "food_name": "...",
      "name_am": "...",
      "recipe_id": null,
      "calories": 0.00,
      "glycemic_load": 0.00,
      "macronutrients": {"protein_g": 0, "carbs_g": 0, "fat_g": 0},
      "description": "...",
      "ingredients": ["...", "..."],
      "instructions": ["...", "..."]
    },
    {
      "meal_type": "dinner",
      "food_name": "...",
      "name_am": "...",
      "recipe_id": null,
      "calories": 0.00,
      "glycemic_load": 0.00,
      "macronutrients": {"protein_g": 0, "carbs_g": 0, "fat_g": 0},
      "description": "...",
      "ingredients": ["...", "..."],
      "instructions": ["...", "..."]
    },
    {
      "meal_type": "snack",
      "food_name": "...",
      "name_am": "...",
      "recipe_id": null,
      "calories": 0.00,
      "glycemic_load": 0.00,
      "macronutrients": {"protein_g": 0, "carbs_g": 0, "fat_g": 0},
      "description": "...",
      "ingredients": ["..."],
      "instructions": ["..."]
    }
  ]
}
Return ONLY strict JSON without markdown formatting or code blocks.`;
};

// Robust AI Content Generation with Automatic Retries & Model Fallbacks
const generateWithRetry = async (genAI, prompt, primaryModelName = 'gemini-2.5-flash', fallbackModelName = 'gemini-1.5-flash', maxRetries = 3) => {
  const modelsToTry = [primaryModelName, fallbackModelName];

  for (const modelName of modelsToTry) {
    let attempts = 0;
    while (attempts < maxRetries) {
      try {
        const model = genAI.getGenerativeModel({ model: modelName });
        const result = await model.generateContent(prompt);
        return result;
      } catch (error) {
        attempts++;
        const errStr = error.message || '';
        const isTransient = errStr.includes('503') || errStr.includes('429') || errStr.includes('high demand') || errStr.includes('Overloaded') || errStr.includes('Service Unavailable');

        if (isTransient && attempts < maxRetries) {
          const delay = Math.pow(2, attempts) * 1000; // Exponential backoff: 2s, 4s, 8s
          console.warn(`⚠️ [Gemini API] Model ${modelName} overloaded (Attempt ${attempts}/${maxRetries}). Retrying in ${delay}ms...`);
          await new Promise(resolve => setTimeout(resolve, delay));
        } else if (!isTransient || attempts >= maxRetries) {
          console.warn(`❌ [Gemini API] Model ${modelName} failed or exhausted retries: ${errStr}`);
          break; // Try next model in fallback list
        }
      }
    }
  }
  throw new Error('All Gemini models and retry attempts failed due to high server demand. Please try again shortly.');
};

// Parse & validate AI response JSON
const parseAiResponse = (responseText) => {
  try {
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
      
      const parsedIngredients = Array.isArray(meal.ingredients) 
        ? meal.ingredients.map(e => String(e).trim()).filter(e => e.length > 0)
        : [];

      const parsedInstructions = Array.isArray(meal.instructions) 
        ? meal.instructions.map(e => String(e).trim()).filter(e => e.length > 0)
        : [];

      validatedMeals.push({
        meal_type: meal.meal_type,
        food_name: meal.food_name || meal.name_am || 'Traditional Ethiopian Meal',
        name_am: meal.name_am || null,
        recipe_id: meal.recipe_id || null,
        calories: parseFloat(meal.calories) || 0,
        glycemic_load: parseFloat(meal.glycemic_load) || 0,
        macronutrients: {
          protein_g: parseFloat(meal.macronutrients?.protein_g) || 0,
          carbs_g: parseFloat(meal.macronutrients?.carbs_g) || 0,
          fat_g: parseFloat(meal.macronutrients?.fat_g) || 0
        },
        description: meal.description || '',
        ingredients: parsedIngredients,
        instructions: parsedInstructions
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

// Insert meal plan rows into meal_plans table (Including ingredients and instructions JSONB columns)
const insertMealPlanRows = async (userId, planDate, mealPlan) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const insertedMeals = [];

    for (const meal of mealPlan.meals) {
      const result = await client.query(`
        INSERT INTO meal_plans (
          user_id, plan_date, meal_type, recipe_id, food_name, glycemic_load,
          calories, macronutrients, is_fasting_meal, recommendation_source, description, ingredients, instructions
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
        RETURNING id, user_id, plan_date, meal_type, recipe_id, food_name, glycemic_load, calories, macronutrients, is_fasting_meal, recommendation_source, description, ingredients, instructions, created_at
      `, [
        userId, planDate, meal.meal_type, meal.recipe_id || null,
        meal.food_name, meal.glycemic_load, meal.calories,
        JSON.stringify(meal.macronutrients), mealPlan.is_fasting_meal,
        mealPlan.recommendation_source, meal.description,
        JSON.stringify(meal.ingredients), JSON.stringify(meal.instructions)
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
    const { plan_date, is_fasting_day = false, language = 'am' } = req.body || {};

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
      // Use local date instead of UTC toISOString() to prevent timezone drift
      const now = new Date();
      const year = now.getFullYear();
      const month = String(now.getMonth() + 1).padStart(2, '0');
      const day = String(now.getDate()).padStart(2, '0');
      planDate = `${year}-${month}-${day}`;
    }

    const userContext = await fetchUserContext(userId);
    const requestedLanguage = language || userContext.goals.preferred_language || 'am';
    
    const prompt = constructMealPlanPrompt(userContext, planDate, is_fasting_day, requestedLanguage);

    const apiKey = process.env.GEMINI_API_KEY?.trim();
    if (!apiKey) throw new Error('GEMINI_API_KEY is not defined');

    const genAI = new GoogleGenerativeAI(apiKey);
    const primaryModel = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
    const fallbackModel = 'gemini-1.5-flash';

    let result;
    try {
      result = await generateWithRetry(genAI, prompt, primaryModel, fallbackModel, 3);
    } catch (apiError) {
      return res.status(503).json({
        error: 'Service Unavailable',
        message: 'AI servers are currently experiencing high demand. Please try again in a few seconds.',
        details: apiError.message
      });
    }

    const responseText = result.response.text();
    if (!responseText) throw new Error('No response from Gemini API');

    const mealPlan = parseAiResponse(responseText);
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
      SELECT id, plan_date, meal_type, recipe_id, food_name, glycemic_load, calories, macronutrients, is_fasting_meal, recommendation_source, description, ingredients, instructions, created_at, updated_at
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
  fetchUserContext, constructMealPlanPrompt, parseAiResponse, insertMealPlanRows, generateWithRetry
};