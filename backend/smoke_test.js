const app = require('./src/app.js');
const http = require('http');

function request({ method, path, body, token }) {
  return new Promise((resolve, reject) => {
    const server = app.listen(0, () => {
      const port = server.address().port;
      const headers = { 'Content-Type': 'application/json' };
      if (token) headers['Authorization'] = 'Bearer ' + token;
      const req = http.request(
        { hostname: '127.0.0.1', port, method, path, headers },
        (res) => {
          let data = '';
          res.on('data', (chunk) => (data += chunk));
          res.on('end', () => {
            server.close();
            try { resolve({ status: res.statusCode, body: JSON.parse(data) }); }
            catch { resolve({ status: res.statusCode, body: data }); }
          });
        }
      );
      req.on('error', reject);
      if (body) req.write(JSON.stringify(body));
      req.end();
    });
  });
}

(async () => {
  const email = 'smoke_' + Date.now() + '@example.com';
  const password = 'SmokeTest123!';

  // 1. Register a fresh user
  console.log('--- Step 1: Register fresh user ---');
  const reg = await request({
    method: 'POST',
    path: '/api/auth/register',
    body: { email, password, full_name: 'Smoke Test', preferred_language: 'en' },
  });
  console.log('Status:', reg.status);
  if (reg.status !== 201 && reg.status !== 200) {
    console.log('Register failed:', JSON.stringify(reg.body));
    return;
  }
  const token = reg.body.token || (reg.body.data && reg.body.data.token);
  console.log('Got token:', token ? token.slice(0, 24) + '...' : '(none)');

  // 2. Save a meal via POST /api/meal-history
  console.log('\n--- Step 2: POST /api/meal-history ---');
  const save = await request({
    method: 'POST',
    path: '/api/meal-history',
    token,
    body: {
      meal_type: 'lunch',
      food_name: 'Injera with Shiro',
      food_ids: [],
      calories: 450,
      macros: { protein_g: 18, carbs_g: 65, fat_g: 12 },
      total_glycemic_load: 22.5,
      net_carbs_g: 58.0,
      gl_class: 'high',
    },
  });
  console.log('Status:', save.status);
  console.log('Response body keys:', Object.keys(save.body || {}).join(','));
  console.log('food_name:', save.body && save.body.food_name);
  console.log('calories:', save.body && save.body.calories);
  console.log('gl_class:', save.body && save.body.gl_class);
  if (save.status !== 201) {
    console.log('Save failed:', JSON.stringify(save.body));
    return;
  }
  const mealId = save.body.id;

  // 3. Fetch the saved meal back
  console.log('\n--- Step 3: GET /api/meal-history/' + mealId + ' ---');
  const get = await request({
    method: 'GET',
    path: '/api/meal-history/' + mealId,
    token,
  });
  console.log('Status:', get.status);
  console.log('food_name:', get.body && get.body.food_name);
  console.log('calories:', get.body && get.body.calories);

  // 4. List all meals for this user
  console.log('\n--- Step 4: GET /api/meal-history ---');
  const list = await request({
    method: 'GET',
    path: '/api/meal-history?limit=5',
    token,
  });
  console.log('Status:', list.status);
  console.log('Returned meals:', (list.body && list.body.meals || []).length);

  // 5. Delete the test meal
  console.log('\n--- Step 5: DELETE /api/meal-history/' + mealId + ' ---');
  const del = await request({
    method: 'DELETE',
    path: '/api/meal-history/' + mealId,
    token,
  });
  console.log('Status:', del.status);

  console.log('\n✅ END-TO-END SMOKE TEST PASSED');
})().catch((e) => {
  console.error('Smoke test error:', e);
  process.exit(1);
});
