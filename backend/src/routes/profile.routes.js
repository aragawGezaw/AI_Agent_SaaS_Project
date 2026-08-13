const express = require('express');
const router = express.Router();
const { query } = require('../db/index.js');
const authenticateToken = require('../middleware/auth.middleware.js');

/**
 * @route GET /api/profile
 * @desc Get the current user's health profile
 * @access Private
 */
router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;

    const result = await query(
      'SELECT id, user_id, age, gender, height_cm, weight_kg, activity_level, daily_calorie_target, created_at, updated_at FROM health_profiles WHERE user_id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'No health profile found'
      });
    }

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

/**
 * @route POST /api/profile
 * @desc Create or update the current user's health profile (UPSERT)
 * @access Private
 */
router.post('/', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { age, gender, height_cm, weight_kg, activity_level, daily_calorie_target } = req.body || {};

    // Validate that age, height_cm, and weight_kg are positive numbers
    const ageNum = Number(age);
    const heightNum = Number(height_cm);
    const weightNum = Number(weight_kg);

    if (age === undefined || age === null || isNaN(ageNum) || ageNum <= 0) {
      return res.status(400).json({
        error: 'Invalid input',
        message: 'Age must be a positive number'
      });
    }

    if (height_cm === undefined || height_cm === null || isNaN(heightNum) || heightNum <= 0) {
      return res.status(400).json({
        error: 'Invalid input',
        message: 'Height must be a positive number'
      });
    }

    if (weight_kg === undefined || weight_kg === null || isNaN(weightNum) || weightNum <= 0) {
      return res.status(400).json({
        error: 'Invalid input',
        message: 'Weight must be a positive number'
      });
    }

    const calorieTarget = daily_calorie_target !== undefined && daily_calorie_target !== null 
      ? Number(daily_calorie_target) 
      : null;

    if (calorieTarget !== null && (isNaN(calorieTarget) || calorieTarget < 0)) {
      return res.status(400).json({
        error: 'Invalid input',
        message: 'Daily calorie target must be a non-negative number'
      });
    }

    const upsertQuery = `
      INSERT INTO health_profiles (user_id, age, gender, height_cm, weight_kg, activity_level, daily_calorie_target)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      ON CONFLICT (user_id)
      DO UPDATE SET
        age = EXCLUDED.age,
        gender = EXCLUDED.gender,
        height_cm = EXCLUDED.height_cm,
        weight_kg = EXCLUDED.weight_kg,
        activity_level = EXCLUDED.activity_level,
        daily_calorie_target = EXCLUDED.daily_calorie_target,
        updated_at = CURRENT_TIMESTAMP
      RETURNING id, user_id, age, gender, height_cm, weight_kg, activity_level, daily_calorie_target, created_at, updated_at
    `;

    const values = [
      userId,
      ageNum,
      gender || null,
      heightNum,
      weightNum,
      activity_level || null,
      calorieTarget
    ];

    const result = await query(upsertQuery, values);

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
