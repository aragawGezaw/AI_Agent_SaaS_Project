const axios = require('axios');

const API_URL = 'http://localhost:5000/api';

async function runTests() {
  console.log('--- Starting Backend Route Tests ---');
  
  const testEmail = `test_${Date.now()}@example.com`;
  const testPassword = 'password123';
  let token = '';

  try {
    // 1. Register User
    console.log('\n1. Testing Registration...');
    try {
      const regRes = await axios.post(`${API_URL}/auth/register`, {
        email: testEmail,
        password: testPassword,
        full_name: 'Test User'
      });
      console.log(`Registration Status: ${regRes.status}`);
    } catch (error) {
      console.log(`Registration Failed: ${error.response?.status || error.message}`);
      if (error.response?.data) console.log('Response:', error.response.data);
    }

    // 2. Login User
    console.log('\n2. Testing Login...');
    try {
      const loginRes = await axios.post(`${API_URL}/auth/login`, {
        email: testEmail,
        password: testPassword
      });
      console.log(`Login Status: ${loginRes.status}`);
      token = loginRes.data.token;
      console.log('JWT Captured.');
    } catch (error) {
      console.log(`Login Failed: ${error.response?.status || error.message}`);
      return; // Can't continue without token
    }

    const config = {
      headers: { Authorization: `Bearer ${token}` }
    };

    // 3. Test Chat
    console.log('\n3. Testing Chat Endpoint...');
    try {
      // 3a. Create a session
      console.log('3a. Creating Chat Session...');
      const sessionRes = await axios.post(`${API_URL}/chat/sessions`, {
        title: 'Test Session',
        agent_type: 'nutrition_advisor'
      }, config);
      console.log(`Session Status: ${sessionRes.status}`);
      const sessionId = sessionRes.data.id;

      // 3b. Generate a message
      console.log('3b. Generating Chat Response...');
      const chatRes = await axios.post(`${API_URL}/chat/sessions/${sessionId}/generate`, {
        content: 'Hello, I want to lose weight. Can you help?'
      }, config);
      console.log(`Chat Status: ${chatRes.status}`);
      console.log('Agent Reply:', chatRes.data.agentMessage.content.substring(0, 100) + '...');
    } catch (error) {
      console.log(`Chat Failed: ${error.response?.status || error.message}`);
      if (error.response?.data) console.log('Response:', error.response.data);
    }

    // 4. Test Subscription
    console.log('\n4. Testing Subscription Endpoint...');
    try {
      const subRes = await axios.get(`${API_URL}/subscription/status`, config);
      console.log(`Subscription Status: ${subRes.status}`);
      console.log('Data:', subRes.data);
    } catch (error) {
      console.log(`Subscription Failed: ${error.response?.status || error.message}`);
      if (error.response?.data) console.log('Response:', error.response.data);
    }

  } catch (error) {
    console.error('Test Execution Error:', error.message);
  }
}

runTests();
