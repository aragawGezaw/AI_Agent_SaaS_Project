const fs = require('fs');
const path = require('path');
const { pool } = require('./index');

/**
 * Runs the meal_plans table migration script (Migration 009)
 * Creates the AI-generated meal recommendations table with nutritional data.
 * 
 * This table supports:
 * - AI-generated personalized meal plans
 * - Fasting-aware meal recommendations (Ethiopian Orthodox fasting periods)
 * - Glycemic load tracking and macronutrient breakdowns
 * - Bilingual content support through linked food items
 */
const runMigration = async () => {
  const migrationPath = path.join(__dirname, 'migrations', '009_create_meal_plans_table.sql');
  
  // Verify migration file exists
  if (!fs.existsSync(migrationPath)) {
    console.error(`Migration file not found: ${migrationPath}`);
    process.exit(1);
  }
  
  const sql = fs.readFileSync(migrationPath, 'utf8');

  const client = await pool.connect();
  try {
    console.log('Starting migration: 009_create_meal_plans_table.sql...');
    console.log('This migration creates the meal_plans table for AI-generated meal recommendations.');
    
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');
    
    console.log('Migration successful: meal_plans table has been created.');
    console.log('  - Table includes glycemic_load, calories, and JSONB macronutrients columns');
    console.log('  - Supports fasting-aware meal planning (is_fasting_meal flag)');
    console.log('  - Indexes created for efficient user/date/meal_type queries');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Migration failed:', error.message);
    console.error('Error details:', error);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
};

// Run migration if executed directly
if (require.main === module) {
  console.log('='.repeat(60));
  console.log('Meal Plans Table Migration (009)');
  console.log('='.repeat(60));
  runMigration()
    .then(() => {
      console.log('Migration completed successfully.');
      process.exit(0);
    })
    .catch((error) => {
      console.error('Migration error:', error);
      process.exit(1);
    });
}

module.exports = runMigration;
