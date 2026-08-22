const { query } = require('../db');
const { GoogleGenerativeAI } = require('@google/generative-ai');

/**
 * Generates an AI response for the user's chat session using Google Gemini API.
 * 
 * @param {Object} params
 * @param {string} params.userId - The ID of the user
 * @param {string} params.sessionId - The ID of the chat session
 * @param {string} params.promptText - The user's latest message text
 * @returns {Promise<string>} - The AI generated response
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

module.exports = {
  generateAgentResponse,
};
