require('dotenv').config();
const jwt = require('jsonwebtoken');

async function testSubscriptions() {
  const userId = '857759aa-dcab-4487-8308-8bdc6a77fd6d'; // Use a test user ID
  const secret = process.env.JWT_SECRET || 'supersecretkey123';
  const token = jwt.sign({ id: userId }, secret, { expiresIn: '1h' });

  const baseUrl = 'http://localhost:5000/api/subscription';

  try {
    console.log('--- Testing /api/subscription/status ---');
    const statusRes = await fetch(`${baseUrl}/status`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });
    console.log(`Status Code: ${statusRes.status}`);
    const statusData = await statusRes.json();
    console.log('Response:', JSON.stringify(statusData, null, 2));

    console.log('\n--- Testing /api/subscription/checkout ---');
    const checkoutRes = await fetch(`${baseUrl}/checkout`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    console.log(`Status Code: ${checkoutRes.status}`);
    const checkoutData = await checkoutRes.json();
    console.log('Response:', JSON.stringify(checkoutData, null, 2));

  } catch (error) {
    console.error('Error running test:', error);
  }
}

testSubscriptions();
