const { query } = require('../db');
const { GoogleGenerativeAI } = require('@google/generative-ai');

/**
 * Generates an AI response for the user's chat session using Google Gemini API.
 * 
 * @param {Object} params
 * @param {string} params.userId The ID of the user
 * @param {string} params.sessionId The ID of the chat session
 * @param {string} params.promptText The user's latest message text
 * @returns {Promise<string>} The AI generated response
 */
const generateAgentResponse = async ({ userId, sessionId, promptText }) => {
  try {
    // 1. Fetch user's latest health profile
    const profileResult = await query(
      'SELECT age, weight_kg, activity_level FROM health_profiles WHERE user_id = $1',
      [userId]
    );
    const profile = profileResult.rows[0] || {};

    // 2. Fetch user's last 5 logged meals
    const mealsResult = await query(
      'SELECT food_name, calories, meal_type, logged_at FROM nutrition_logs WHERE user_id = $1 ORDER BY logged_at DESC LIMIT 5',
      [userId]
    );
    const recentMeals = mealsResult.rows;

    // 3. Fetch last 10 chat messages for the session
    const chatResult = await query(
      'SELECT sender, content FROM chat_messages WHERE session_id = $1 ORDER BY created_at DESC LIMIT 10',
      [sessionId]
    );
    const chatHistory = chatResult.rows.reverse();

    // 4. Construct System Prompt
    const systemPrompt = `You are a helpful nutrition and fitness AI assistant. 
User Profile: Age ${profile.age || 'Unknown'}, Weight ${profile.weight_kg || 'Unknown'}kg, Activity Level: ${profile.activity_level || 'Unknown'}.
Recent Meals: ${recentMeals.length > 0 ? recentMeals.map(m => `${m.food_name} (${m.calories} kcal)`).join(', ') : 'No recent meals logged'}.
Based on this context, provide tailored, helpful nutrition and health advice. Be concise and encouraging.`;

    // 5. Construct request to Google Gemini API
    const apiKey = process.env.GEMINI_API_KEY?.trim();
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY is not defined in environment variables');
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const modelName = process.env.GEMINI_MODEL || 'gemini-3.6-flash-latest';
    const model = genAI.getGenerativeModel({ model: modelName });

    const historyPrompt = chatHistory.map(msg => `${msg.sender === 'user' ? 'User' : 'Assistant'}: ${msg.content}`).join('\n');
    
    const fullPrompt = `${systemPrompt}\n\nChat History:\n${historyPrompt}\nUser: ${promptText}\nAssistant:`;

    let result;
    try {
      result = await model.generateContent(fullPrompt);
    } catch (apiError) {
      console.error('Gemini API SDK Error:', apiError);
      throw new Error(`Gemini API Error: ${apiError.message || apiError}`);
    }

    const responseText = result.response.text();
    if (!responseText) {
      throw new Error("No response content generated from Gemini API");
    }

    return responseText.trim();
  } catch (error) {
    console.error('Gemini API Error Details:', error);
    throw new Error(error.message || 'An error occurred while generating agent response');
  }
};

/**
 * Generates a scientifically accurate, structured daily meal plan with clinical guardrails,
 * exact portion ingredients, and step-by-step traditional cooking instructions.
 * 
 * @param {Object} params
 * @param {string} params.userId The ID of the user
 * @param {number} params.targetCalories Calculated daily caloric target
 * @param {boolean} params.isFasting Whether Ethiopian Orthodox fasting (የጾም ቀን) is active
 * @param {string} params.userGoals User clinical/metabolic goals
 * @param {string} params.language Language preference ('am' or 'en')
 * @returns {Promise<Object>} The structured JSON meal plan object
 */
const generateMealPlan = async ({ userId, targetCalories, isFasting, userGoals, language = 'am' }) => {
  try {
    // 1. Fetch curated food database items for clinical context
    const foodsResult = await query('SELECT name, calories, protein, carbs, fat FROM foods LIMIT 50');
    const availableFoods = foodsResult.rows;

    // 2. Set up Fasting and Clinical Rules
    const fastingInstruction = isFasting
      ? "CRITICAL RULE: The user is observing Ethiopian Orthodox fasting (የጾም ቀን). All generated meals must be 100% plant-based/vegan, with absolutely zero animal products, dairy (Ayib), eggs (Enkulal), butter (Niter Kibbeh), or meat."
      : "Dietary profile: Standard balanced nutrition incorporating Ethiopian and global clinical staples with lean animal proteins and dairy.";

    const languageInstruction = language === 'am'
      ? "Language Requirement: Write ALL food names, ingredient descriptions, and step-by-step instructions directly in Amharic (አማርኛ)."
      : "Language Requirement: Write food names, ingredient descriptions, and step-by-step instructions in English.";

    // 3. Construct Clinical Prompt with Unique Recipe Enforcement
    const prompt = `
You are an expert clinical nutritionist and metabolic health AI engine specialized in Ethiopian cuisine. Your task is to generate a scientifically balanced, culturally appropriate daily meal plan in strict JSON format.

### Patient Target & Profile:
- Target Daily Calories: ${targetCalories || 2000} kcal
- Clinical Goal: ${userGoals || 'Glycemic stability, body recomposition, and muscle protein synthesis'}
- Religious/Context: ${fastingInstruction}
- ${languageInstruction}

### Clinical Guardrails & Mandatory Rules:
- Protein Distribution: Every main meal (Breakfast, Lunch, Dinner) MUST target 25g to 30g of protein to support muscle retention and blunt postprandial glucose spikes.
- Glycemic Load (GL) Control: Individual meal GL should remain low (< 10-12 per meal) by pairing complex carbohydrates with high fiber and protein.
- UNIQUE RECIPES MANDATE: Each meal (breakfast, lunch, dinner, snack) MUST have completely DISTINCT, dish-specific ingredients and step-by-step cooking instructions corresponding directly to its unique "food_name". NEVER reuse or duplicate generic steps between meals.
- Ingredients & Portions: Provide exact quantities and weights for every ingredient (e.g., "120g lean beef", "3 whole eggs", "90g dry lentils", "1 medium Teff injera").

### Approved Food Database Context:
${JSON.stringify(availableFoods, null, 2)}

### Required Output Format:
Return ONLY a valid, strict JSON object (no markdown code blocks, no backticks, no extra text) matching this exact schema:
{
  "total_calories": ${targetCalories || 2000},
  "total_glycemic_load": 32.5,
  "meal_count": 4,
  "meals": [
    {
      "meal_type": "breakfast",
      "food_name": "Unique meal name",
      "calories": 400,
      "protein": 28.0,
      "carbs": 36.0,
      "fat": 15.0,
      "glycemic_load": 8.5,
      "is_fasting_meal": ${isFasting},
      "ingredients": ["Specific ingredient 1 with quantity", "Specific ingredient 2 with quantity"],
      "instructions": ["Step 1 specific to this dish", "Step 2 specific to this dish"]
    },
    {
      "meal_type": "lunch",
      "food_name": "Unique meal name",
      "calories": 470,
      "protein": 33.0,
      "carbs": 48.0,
      "fat": 14.0,
      "glycemic_load": 10.2,
      "is_fasting_meal": ${isFasting},
      "ingredients": ["Specific ingredient 1 with quantity", "Specific ingredient 2 with quantity"],
      "instructions": ["Step 1 specific to this dish", "Step 2 specific to this dish"]
    },
    {
      "meal_type": "dinner",
      "food_name": "Unique meal name",
      "calories": 450,
      "protein": 30.0,
      "carbs": 44.0,
      "fat": 16.0,
      "glycemic_load": 9.1,
      "is_fasting_meal": ${isFasting},
      "ingredients": ["Specific ingredient 1 with quantity", "Specific ingredient 2 with quantity"],
      "instructions": ["Step 1 specific to this dish", "Step 2 specific to this dish"]
    },
    {
      "meal_type": "snack",
      "food_name": "Unique meal name",
      "calories": 200,
      "protein": 8.0,
      "carbs": 23.0,
      "fat": 8.0,
      "glycemic_load": 5.8,
      "is_fasting_meal": ${isFasting},
      "ingredients": ["Specific ingredient 1 with quantity", "Specific ingredient 2 with quantity"],
      "instructions": ["Step 1 specific to this dish", "Step 2 specific to this dish"]
    }
  ]
}
    `.trim();

    // 4. Call Gemini API
    const apiKey = process.env.GEMINI_API_KEY?.trim();
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY is not defined in environment variables');
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const modelName = process.env.GEMINI_MODEL || 'gemini-3.6-flash-latest';
    const model = genAI.getGenerativeModel({ model: modelName });

    const result = await model.generateContent(prompt);
    let responseText = result.response.text();
    if (!responseText) {
      throw new Error("No response content generated from Gemini API");
    }

    // Clean markdown code blocks if present
    responseText = responseText.replace(/```json/g, '').replace(/```/g, '').trim();

    const parsedPlan = JSON.parse(responseText);

    // --- DETERMINISTIC FASTING SAFETY GUARD ---
    if (isFasting) {
      const animalKeywords = ['beef', 'meat', 'chicken', 'doro', 'egg', 'enkulal', 'ayib', 'cheese', 'milk', 'butter', 'kibbeh', 'fish', 'sega'];
      parsedPlan.meals = parsedPlan.meals.map(meal => {
        meal.is_fasting_meal = true;
        meal.ingredients = meal.ingredients.filter(ing => {
          const lower = ing.toLowerCase();
          return !animalKeywords.some(animal => lower.includes(animal));
        });
        return meal;
      });
    }

    return parsedPlan;
  } catch (error) {
    console.error('Gemini Meal Plan Generation Error:', error);
    throw new Error(error.message || 'An error occurred while generating the meal plan');
  }
};

module.exports = {
  generateAgentResponse,
  generateMealPlan,
};