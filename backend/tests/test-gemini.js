require('dotenv').config();
const { GoogleGenerativeAI } = require('@google/generative-ai');

async function test() {
  try {
    console.log("Testing key:", process.env.GEMINI_API_KEY ? "Key Found" : "Key Missing");
    console.log("Testing model:", process.env.GEMINI_MODEL);
    
    const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY?.trim());
    const model = genAI.getGenerativeModel({ model: process.env.GEMINI_MODEL || 'gemini-3.6-flash' });
    
    const result = await model.generateContent("Say hello");
    console.log("SUCCESS Response:", await result.response.text());
  } catch (err) {
    console.error("\n--- EXACT GEMINI ERROR START ---");
    console.error(err);
    console.error("--- EXACT GEMINI ERROR END ---\n");
  }
}

test();