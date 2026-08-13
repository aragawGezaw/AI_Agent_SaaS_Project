const express = require('express');
const router = express.Router();
const { query } = require('../db/index.js');
const authenticateToken = require('../middleware/auth.middleware.js');

/**
 * @route POST /api/nutrition
 * @desc Create a new nutrition log entry
 * @access Private
 */
router.post('/', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { meal_type, food_name, calories, macros } = req.body || {};

    // Validate existence and types of meal_type, food_name, and calories
    if (!meal_type || typeof meal_type !== 'string' || meal_type.trim() === '') {
      return res.status(400).json({
        error: 'Invalid input',
        message: 'meal_type is required and must be a non-empty string'
      });
    }

    if (!food_name || typeof food_name !== 'string' || food_name.trim() === '') {
      return res.status(400).json({
        error: 'Invalid input',
        message: 'food_name is required and must be a non-empty string'
      });
    }

    if (calories === undefined || calories === null || typeof calories !== 'number' || !Number.isInteger(calories) || calories <= 0) {
      return res.status(400).json({
        error: 'Invalid input',
        message: 'calories is required and must be a positive integer'
      });
    }

    // Process optional macros
    const protein = (macros && macros.protein_g !== undefined && macros.protein_g !== null) ? Number(macros.protein_g) : 0;
    const carbs = (macros && macros.carbs_g !== undefined && macros.carbs_g !== null) ? Number(macros.carbs_g) : 0;
    const fat = (macros && macros.fat_g !== undefined && macros.fat_g !== null) ? Number(macros.fat_g) : 0;

    const macrosObj = {
      protein_g: isNaN(protein) || protein < 0 ? 0 : protein,
      carbs_g: isNaN(carbs) || carbs < 0 ? 0 : carbs,
      fat_g: isNaN(fat) || fat < 0 ? 0 : fat
    };

    const insertQuery = `
      INSERT INTO nutrition_logs (user_id, meal_type, food_name, calories, macros)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, user_id, meal_type, food_name, calories, macros, logged_at
    `;

    const values = [
      userId,
      meal_type.trim(),
      food_name.trim(),
      calories,
      JSON.stringify(macrosObj)
    ];

    const result = await query(insertQuery, values);

    return res.status(201).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

/**
 * @route PUT /api/nutrition/:id
 * @desc Update a nutrition log entry by ID for the current user
 * @access Private
 */
router.put('/:id', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;
    const { meal_type, food_name, calories, macros } = req.body || {};

    // Validate that id is a valid UUID
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!id || !uuidRegex.test(id)) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Nutrition log entry not found'
      });
    }

    // Check if the record exists and belongs to the user
    const checkResult = await query(
      'SELECT macros FROM nutrition_logs WHERE id = $1 AND user_id = $2',
      [id, userId]
    );

    if (checkResult.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Nutrition log entry not found or does not belong to user'
      });
    }

    const currentMacros = checkResult.rows[0].macros || {};

    // Prepare fields for update
    const updateFields = [];
    const values = [];
    let paramIndex = 1;

    if (meal_type !== undefined) {
      updateFields.push(`meal_type = $${paramIndex++}`);
      values.push(meal_type);
    }

    if (food_name !== undefined) {
      updateFields.push(`food_name = $${paramIndex++}`);
      values.push(food_name);
    }

    if (calories !== undefined) {
      updateFields.push(`calories = $${paramIndex++}`);
      values.push(calories);
    }

    if (macros !== undefined) {
      const updatedMacros = {
        protein_g: macros.protein_g !== undefined ? macros.protein_g : currentMacros.protein_g || 0,
        carbs_g: macros.carbs_g !== undefined ? macros.carbs_g : currentMacros.carbs_g || 0,
        fat_g: macros.fat_g !== undefined ? macros.fat_g : currentMacros.fat_g || 0
      };
      updateFields.push(`macros = $${paramIndex++}`);
      values.push(JSON.stringify(updatedMacros));
    }

    if (updateFields.length === 0) {
      return res.status(400).json({
        error: 'Invalid input',
        message: 'No fields provided for update'
      });
    }

    values.push(id);
    values.push(userId);

    const updateQuery = `
      UPDATE nutrition_logs
      SET ${updateFields.join(', ')}
      WHERE id = $${paramIndex++} AND user_id = $${paramIndex++}
      RETURNING id, user_id, meal_type, food_name, calories, macros, logged_at
    `;

    const result = await query(updateQuery, values);

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

/**
 * @route GET /api/nutrition
 * @desc Get all nutrition log entries for the current user, ordered by logged_at DESC
 * @access Private
 */
router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;

    const result = await query(
      'SELECT id, user_id, meal_type, food_name, calories, macros, logged_at FROM nutrition_logs WHERE user_id = $1 ORDER BY logged_at DESC',
      [userId]
    );

    return res.status(200).json(result.rows);
  } catch (error) {
    next(error);
  }
});

/**
 * @route DELETE /api/nutrition/:id
 * @desc Delete a nutrition log entry by ID for the current user
 * @access Private
 */
router.delete('/:id', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    // Validate that id is a valid UUID
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!id || !uuidRegex.test(id)) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Nutrition log entry not found'
      });
    }

    const deleteQuery = 'DELETE FROM nutrition_logs WHERE id = $1 AND user_id = $2 RETURNING id';
    const result = await query(deleteQuery, [id, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Nutrition log entry not found or does not belong to user'
      });
    }

    return res.status(200).json({
      message: 'Nutrition log entry deleted successfully'
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
