require('dotenv').config();
const { GoogleGenerativeAI } = require('@google/generative-ai');

async function listModels() {
  try {
    const apiKey = process.env.GEMINI_API_KEY?.trim();
    console.log('Using API Key:', apiKey ? 'FOUND (trimmed)' : 'NOT FOUND');
    if (!apiKey) return;
    
    const genAI = new GoogleGenerativeAI(apiKey);
    
    // The SDK version we have might not have listModels on the main class
    // We can try to fetch from the endpoint directly or use the discovery service
    // But let's try a different model name first
    
    const models = [
      'gemini-1.5-flash',
      'gemini-1.5-pro',
      'gemini-pro',
      'gemini-1.0-pro'
    ];

    for (const modelName of models) {
      console.log(`Testing ${modelName}...`);
      try {
        const model = genAI.getGenerativeModel({ model: modelName });
        const result = await model.generateContent("Hi");
        console.log(`${modelName} success:`, result.response.text());
        break;
      } catch (e) {
        console.log(`${modelName} failed:`, e.message);
      }
    }

  } catch (err) {
    console.error('General Error:', err);
  }
}

listModels();
