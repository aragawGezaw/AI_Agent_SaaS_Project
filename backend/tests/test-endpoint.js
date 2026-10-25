require('dotenv').config();
const jwt = require('jsonwebtoken');

async function runTest() {
  const userId = '857759aa-dcab-4487-8308-8bdc6a77fd6d';
  const secret = process.env.JWT_SECRET || 'supersecretkey123';
  const token = jwt.sign({ id: userId }, secret, { expiresIn: '1h' });

  const url = 'http://localhost:5000/api/chat/sessions/669ed135-c1c2-40c4-9df6-5beb9250e2b7/generate';
  const payload = {
    content: "Based on my health profile and recent meals, what should I eat for dinner?"
  };

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      },
      body: JSON.stringify(payload)
    });

    console.log(`Status Code: ${res.status}`);
    const data = await res.json();
    console.log('Response JSON:', JSON.stringify(data, null, 2));
  } catch (error) {
    console.error('Error running test request:', error);
  }
}

runTest();
