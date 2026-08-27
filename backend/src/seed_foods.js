const { query, pool } = require('./db/index.js');

/**
 * Seed script to populate indigenous Ethiopian foods and global foods
 * into the `foods` table.
 *
 * Run with: node src/seed_foods.js
 */

const indigenousEthiopianFoods = [
  {
    name_en: 'Injera',
    name_am: 'እንጋራ',
    calories_per_100g: 38.0,
    protein_g: 3.3,
    carbs_g: 79.0,
    fiber_g: 2.7,
    fat_g: 1.0,
    glycemic_index: 75.0,
    source: 'EPHI',
  },
  {
    name_en: 'Shiro',
    name_am: 'ሽር',
    calories_per_100g: 158.0,
    protein_g: 11.0,
    carbs_g: 11.0,
    fiber_g: 3.0,
    fat_g: 7.0,
    glycemic_index: 55.0,
    source: 'EPHI',
  },
  {
    name_en: 'Teff',
    name_am: 'ተፍ',
    calories_per_100g: 367.0,
    protein_g: 13.3,
    carbs_g: 73.0,
    fiber_g: 8.0,
    fat_g: 2.0,
    glycemic_index: 75.0,
    source: 'EPHI',
  },
  {
    name_en: 'Kocho',
    name_am: 'ቆጦ',
    calories_per_100g: 120.0,
    protein_g: 2.5,
    carbs_g: 27.0,
    fiber_g: 2.0,
    fat_g: 0.5,
    glycemic_index: 85.0,
    source: 'EPHI',
  },
];

const globalFoods = [
  {
    name_en: 'Brown Rice',
    name_am: 'ቅርብ ሲሊሰር',
    calories_per_100g: 111.0,
    protein_g: 2.6,
    carbs_g: 23.0,
    fiber_g: 1.8,
    fat_g: 0.9,
    glycemic_index: 66.0,
    source: 'USDA',
  },
  {
    name_en: 'White Rice',
    name_am: 'ቅርብ ቁልቲ',
    calories_per_100g: 130.0,
    protein_g: 2.7,
    carbs_g: 28.0,
    fiber_g: 0.4,
    fat_g: 0.3,
    glycemic_index: 73.0,
    source: 'USDA',
  },
  {
    name_en: 'Wheat Flour',
    name_am: 'ጣራ ብሩት',
    calories_per_100g: 364.0,
    protein_g: 10.3,
    carbs_g: 76.0,
    fiber_g: 2.7,
    fat_g: 1.0,
    glycemic_index: 71.0,
    source: 'USDA',
  },
  {
    name_en: 'Lentils',
    name_am: 'ርግጥ',
    calories_per_100g: 116.0,
    protein_g: 9.0,
    carbs_g: 20.0,
    fiber_g: 7.0,
    fat_g: 0.4,
    glycemic_index: 30.0,
    source: 'USDA',
  },
  {
    name_en: 'Banana',
    name_am: 'ጦታ',
    calories_per_100g: 89.0,
    protein_g: 1.1,
    carbs_g: 22.8,
    fiber_g: 2.6,
    fat_g: 0.3,
    glycemic_index: 51.0,
    source: 'USDA',
  },
];

const insertFoodQuery = `
  INSERT INTO foods (name_en, name_am, calories_per_100g, protein_g, carbs_g, fiber_g, fat_g, glycemic_index, source)
  VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
  ON CONFLICT DO NOTHING;
`;

/**
 * Seeds the `foods` table with indigenous Ethiopian and global food data.
 */
const seedFoods = async () => {
  const allFoods = [...indigenousEthiopianFoods, ...globalFoods];

  const client = await pool.connect();
  try {
    console.log('Starting food database seeding...');
    await client.query('BEGIN');

    for (const food of allFoods) {
      await client.query(insertFoodQuery, [
        food.name_en,
        food.name_am,
        food.calories_per_100g,
        food.protein_g,
        food.carbs_g,
        food.fiber_g,
        food.fat_g,
        food.glycemic_index,
        food.source,
      ]);
    }

    await client.query('COMMIT');
    console.log(`Successfully seeded ${allFoods.length} foods into the database.`);
    console.log(` - ${indigenousEthiopianFoods.length} indigenous Ethiopian foods (EPHI)`);
    console.log(` - ${globalFoods.length} global foods (USDA)`);
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Failed to seed foods:', error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
};

if (require.main === module) {
  seedFoods();
}

module.exports = seedFoods;