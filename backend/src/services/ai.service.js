const { GoogleGenerativeAI } = require('@google/generative-ai');
const { query } = require('../db/index.js');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

/**
 * Generates an AI response for a user based on their health profile, recent meals, and chat history.
 * 
 * @param {Object} params
 * @param {string} params.userId - The ID of the user.
 * @param {string} params.sessionId - The ID of the current chat session.
 * @param {string} params.promptText - The user's latest message content.
 * @returns {Promise<string>} The generated assistant response.
 */
async function generateAgentResponse({ userId, sessionId, promptText }) {
  try {
    // 1. Fetch user's latest health profile
    const profileResult = await query(
      'SELECT age, gender, height_cm, weight_kg, activity_level, daily_calorie_target FROM health_profiles WHERE user_id = $1',
      [userId]
    );
    const profile = profileResult.rows[0] || {};

    // 2. Fetch user's last 5 logged meals
    const mealsResult = await query(
      'SELECT meal_type, food_name, calories, macros, logged_at FROM nutrition_logs WHERE user_id = $1 ORDER BY logged_at DESC LIMIT 5',
      [userId]
    );
    const recentMeals = mealsResult.rows;

    // 3. Fetch last 10 chat messages for the session
    const messagesResult = await query(
      'SELECT sender, content FROM chat_messages WHERE session_id = $1 ORDER BY created_at DESC LIMIT 10',
      [sessionId]
    );
    // Reverse to get chronological order for the AI
    const history = messagesResult.rows.reverse();

    // 4. Construct System Prompt
    const systemPrompt = `
You are a helpful and knowledgeable Nutrition & Wellness Advisor. Your goal is to provide tailored, actionable advice based on the user's health profile and recent nutritional data.

USER CONTEXT:
- Age: ${profile.age || 'Not provided'}
- Weight: ${profile.weight_kg ? profile.weight_kg + 'kg' : 'Not provided'}
- Activity Level: ${profile.activity_level || 'Not provided'}
- Daily Calorie Target: ${profile.daily_calorie_target || 'Not provided'}

RECENT MEALS:
${recentMeals.length > 0 
  ? recentMeals.map(m => `- ${m.meal_type}: ${m.food_name} (${m.calories} kcal)`).join('\n')
  : 'No recent meals logged.'}

INSTRUCTIONS:
1. Use the context above to make your responses highly relevant.
2. Be encouraging but professional.
3. If the user asks for nutritional advice, consider their recent meals and calorie target.
4. Keep responses concise and easy to read.
`;

    // 5. Call Gemini API
    const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

    // Format history for Gemini chat
    // Note: Gemini expects 'user' and 'model' roles. We map 'agent' to 'model'.
    const chatHistory = history.map(msg => ({
      role: msg.sender === 'agent' ? 'model' : 'user',
      parts: [{ text: msg.content }],
    }));

    // Start a chat session with history
    const chat = model.startChat({
      history: chatHistory,
      systemInstruction: systemPrompt,
    });

    const result = await chat.sendMessage(promptText);
    const response = await result.response;
    const text = response.text();

    return text;
  } catch (error) {
    console.error('Error in generateAgentResponse:', error);
    throw new Error('Failed to generate AI response');
  }
}

module.exports = {
  generateAgentResponse,
};
