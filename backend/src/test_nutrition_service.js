const { query, pool } = require('./db/index.js');
const NutritionService = require('./services/nutrition.service.js');

/**
 * Phase 4 Verification: Nutrition Service Glycemic Load Calculation Engine
 *
 * Tests:
 *  - Net Carbs formula: (carbs - fiber) scaled to portion
 *  - Glycemic Load formula: (GI * netCarbs) / 100
 *  - analyzeMeal aggregation with Ethiopian staples (Injera, Shiro)
 *
 * Run with: node src/test_nutrition_service.js
 */

let passed = 0;
let failed = 0;

const assert = (condition, message) => {
  if (condition) {
    passed++;
    console.log(`  \u2713 ${message}`);
  } else {
    failed++;
    console.error(`  \u2717 ${message}`);
  }
};

const assertApprox = (actual, expected, tolerance, message) => {
  const diff = Math.abs(actual - expected);
  if (diff <= tolerance) {
    passed++;
    console.log(`  \u2713 ${message} (actual=${actual}, expected~${expected})`);
  } else {
    failed++;
    console.error(`  \u2717 ${message} (actual=${actual}, expected~${expected}, diff=${diff})`);
  }
};

async function fetchFoodsByNames(names) {
  const result = await query(
    'SELECT * FROM foods WHERE name_en = ANY($1::text[])',
    [names]
  );
  return result.rows;
}

async function testPureCalculationLogic() {
  console.log('\n--- Pure calculation logic (no DB) ---');

  // Injera 200g: per100g carbs=79, fiber=2.7, GI=75
  //   scale=2.0; netCarbsPer100g=76.3; netCarbs=152.6
  //   GL = (75 * 152.6) / 100 = 114.45
  const injera200 = { carbs_g: 79.0, fiber_g: 2.7, glycemic_index: 75.0 };
  const netCarbs = NutritionService.calculateNetCarbs(injera200, 200);
  const gl = NutritionService.calculateGlycemicLoad(injera200, 200);
  assertApprox(netCarbs, 152.6, 0.01, 'Injera 200g: net carbs = 152.6g');
  assertApprox(gl, 114.45, 0.01, 'Injera 200g: glycemic load = 114.45');

  // Shiro 100g: carbs=11, fiber=3, GI=55
  //   netCarbs=(11-3)*1=8; GL=(55*8)/100=4.4
  const shiro100 = { carbs_g: 11, fiber_g: 3, glycemic_index: 55 };
  const shiroNet = NutritionService.calculateNetCarbs(shiro100, 100);
  const shiroGl = NutritionService.calculateGlycemicLoad(shiro100, 100);
  assertApprox(shiroNet, 8, 0.01, 'Shiro 100g: net carbs = 8g');
  assertApprox(shiroGl, 4.4, 0.01, 'Shiro 100g: glycemic load = 4.4');

  // Edge cases
  const zeroGl = NutritionService.calculateGlycemicLoad(injera200, 0);
  assert(zeroGl === 0, 'Zero portion yields GL=0');
  const noGi = { carbs_g: 20, fiber_g: 2, glycemic_index: null };
  const noGiGl = NutritionService.calculateGlycemicLoad(noGi, 100);
  assert(noGiGl === 0, 'Missing GI yields GL=0');
}

async function testClassificationBoundaries() {
  console.log('\n--- Glycemic Load classification ---');
  assert(NutritionService.classifyGlycemicLoad(0) === 'low', 'GL=0 -> low');
  assert(NutritionService.classifyGlycemicLoad(10) === 'low', 'GL=10 -> low');
  assert(NutritionService.classifyGlycemicLoad(11) === 'medium', 'GL=11 -> medium');
  assert(NutritionService.classifyGlycemicLoad(19) === 'medium', 'GL=19 -> medium');
  assert(NutritionService.classifyGlycemicLoad(20) === 'high', 'GL=20 -> high');
  assert(NutritionService.classifyGlycemicLoad(50) === 'high', 'GL=50 -> high');
}

async function testAnalyzeMealWithDatabase() {
  console.log('\n--- analyzeMeal() with database (Injera + Shiro) ---');

  const foods = await fetchFoodsByNames(['Injera', 'Shiro']);
  const injera = foods.find((f) => f.name_en === 'Injera');
  const shiro = foods.find((f) => f.name_en === 'Shiro');

  if (!injera || !shiro) {
    failed++;
    console.error('  [FAIL] Injera/Shiro not found in database. Run seed first.');
    return;
  }

  // Typical Ethiopian meal: 200g Injera + 100g Shiro
  // Injera 200g: cal=76, protein=6.6, carbs=158, fiber=5.4, fat=2.0, netCarbs=152.6, GL=114.45
  // Shiro  100g: cal=158, protein=11, carbs=11, fiber=3, fat=7, netCarbs=8, GL=4.4
  // Totals:      cal=234, protein=17.6, netCarbs=160.6, total GL=118.85
  const result = await NutritionService.analyzeMeal([
    { food_id: injera.id, portion_g: 200 },
    { food_id: shiro.id, portion_g: 100 },
  ]);

  const injeraItem = result.items.find((it) => it.name_en === 'Injera');
  const shiroItem = result.items.find((it) => it.name_en === 'Shiro');

  assertApprox(injeraItem.calories, 76, 0.01, 'Injera 200g calories = 76');
  assertApprox(injeraItem.protein_g, 6.6, 0.01, 'Injera 200g protein = 6.6g');
  assertApprox(injeraItem.net_carbs_g, 152.6, 0.01, 'Injera 200g net carbs = 152.6g');
  assertApprox(injeraItem.glycemic_load, 114.45, 0.01, 'Injera 200g GL = 114.45');

  assertApprox(shiroItem.calories, 158, 0.01, 'Shiro 100g calories = 158');
  assertApprox(shiroItem.net_carbs_g, 8, 0.01, 'Shiro 100g net carbs = 8g');
  assertApprox(shiroItem.glycemic_load, 4.4, 0.01, 'Shiro 100g GL = 4.4');

  assertApprox(result.totals.calories, 234, 0.01, 'Total meal calories = 234');
  assertApprox(result.totals.protein_g, 17.6, 0.01, 'Total meal protein = 17.6g');
  assertApprox(result.totals.net_carbs_g, 160.6, 0.01, 'Total net carbs = 160.6g');
  assertApprox(result.total_glycemic_load, 118.85, 0.01, 'Total meal GL = 118.85');

  assert(result.total_glycemic_load > 20, 'GL class should be HIGH for this meal');
  assert(
    result.evaluation_note.glycemic_load_class === 'high',
    'GL classification = high'
  );
  assert(
    result.evaluation_note.top_contributor &&
      result.evaluation_note.top_contributor.name_en === 'Injera',
    'Injera is the top GL contributor'
  );
  assert(typeof result.evaluation_note.recommendation === 'string', 'Recommendation text present');
}

async function main() {
  try {
    await testPureCalculationLogic();
    await testClassificationBoundaries();
    await testAnalyzeMealWithDatabase();
  } catch (error) {
    console.error('Test runner error:', error);
    failed++;
  } finally {
    await pool.end();
  }

  console.log('\n========================================');
  console.log('Tests passed: ' + passed);
  console.log('Tests failed: ' + failed);
  console.log('========================================');
  process.exit(failed === 0 ? 0 : 1);
}

main();