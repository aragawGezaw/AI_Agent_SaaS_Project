require('dotenv').config();
const { GoogleGenerativeAI } = require('@google/generative-ai');

async function test() {
  try {
    const apiKey = process.env.GEMINI_API_KEY?.trim();
    console.log('Using API Key:', apiKey ? 'FOUND (trimmed)' : 'NOT FOUND');
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY is not defined or is empty');
    }
    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });
    const result = await model.generateContent("Hello");
    console.log('Response:', result.response.text());
  } catch (err) {
    console.error('Error:', err);
  }
}

test();
