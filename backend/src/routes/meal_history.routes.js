const express = require('express');
const router = express.Router();
const { query } = require('../db/index.js');
const authenticateToken = require('../middleware/auth.middleware.js');

/**
 * @route GET /api/meal-history
 * @desc Get all meal history entries for the current user with pagination and filtering
 * @access Private
 */
router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const {
      limit = 50,
      offset = 0,
      meal_type,
      start_date,
      end_date,
    } = req.query;

    let whereConditions = ['user_id = $1'];
    let values = [userId];
    let paramIndex = 2;

    if (meal_type) {
      whereConditions.push(`meal_type = $${paramIndex++}`);
      values.push(meal_type);
    }

    if (start_date) {
      whereConditions.push(`logged_at >= $${paramIndex++}::timestamp`);
      values.push(start_date);
    }

    if (end_date) {
      whereConditions.push(`logged_at <= $${paramIndex++}::timestamp`);
      values.push(end_date);
    }

    const countQuery = `SELECT COUNT(*) FROM user_meals WHERE ${whereConditions.join(' AND ')}`;
    const countResult = await query(countQuery, values);
    const totalCount = parseInt(countResult.rows[0].count, 10);

    const dataQuery = `
      SELECT id, user_id, meal_type, food_name, food_ids, calories, macros,
        total_glycemic_load, net_carbs_g, gl_class, logged_at, created_at, updated_at
      FROM user_meals 
      WHERE ${whereConditions.join(' AND ')}
      ORDER BY logged_at DESC
      LIMIT $${paramIndex++} OFFSET $${paramIndex++}
    `;
    values.push(parseInt(limit, 10), parseInt(offset, 10));

    const result = await query(dataQuery, values);

    return res.status(200).json({
      meals: result.rows,
      pagination: {
        total: totalCount,
        limit: parseInt(limit, 10),
        offset: parseInt(offset, 10),
        hasMore: parseInt(offset, 10) + result.rows.length < totalCount,
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route GET /api/meal-history/trends
 * @desc Compute daily totals for calories and glycemic load over the past 7 days
 * @access Private
 */
router.get('/trends', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;

    // Compute the date range for the past 7 days (today included)
    const today = new Date();
    const sevenDaysAgo = new Date(today);
    sevenDaysAgo.setDate(today.getDate() - 6); // Include today, go back 6 more days

    // Format dates for PostgreSQL: YYYY-MM-DD
    const formatDate = (d) => d.toISOString().split('T')[0];
    const startDate = formatDate(sevenDaysAgo);
    const endDate = formatDate(today);

    const trendsQuery = `
      SELECT 
        TO_CHAR(logged_at AT TIME ZONE 'Africa/Addis_Ababa', 'YYYY-MM-DD') AS day,
        COALESCE(SUM(calories), 0)::INTEGER AS total_calories,
        COALESCE(SUM(total_glycemic_load), 0)::NUMERIC(10,2) AS total_glycemic_load
      FROM user_meals
      WHERE user_id = $1
        AND (logged_at AT TIME ZONE 'Africa/Addis_Ababa')::date >= $2::date
        AND (logged_at AT TIME ZONE 'Africa/Addis_Ababa')::date <= $3::date
      GROUP BY TO_CHAR(logged_at AT TIME ZONE 'Africa/Addis_Ababa', 'YYYY-MM-DD')
      ORDER BY day ASC
    `;

    const result = await query(trendsQuery, [userId, startDate, endDate]);

    // Build a map of existing data for quick lookup
    const dataMap = new Map();
    result.rows.forEach((row) => {
      dataMap.set(row.day, {
        total_calories: parseInt(row.total_calories, 10),
        total_glycemic_load: parseFloat(row.total_glycemic_load),
      });
    });

    // Fill in all 7 days so the chart always shows a full week
    const trends = [];
    for (let i = 0; i < 7; i++) {
      const d = new Date(sevenDaysAgo);
      d.setDate(sevenDaysAgo.getDate() + i);
      const dayStr = formatDate(d);
      const entry = dataMap.get(dayStr);
      trends.push({
        day: dayStr, // "YYYY-MM-DD"
        total_calories: entry ? entry.total_calories : 0,
        total_glycemic_load: entry ? parseFloat(entry.total_glycemic_load.toFixed(2)) : 0.0,
      });
    }

    return res.status(200).json({ trends });
  } catch (error) {
    next(error);
  }
});

/**
 * @route GET /api/meal-history/:id
 * @desc Get a single meal history entry by ID
 * @access Private
 */
router.get('/:id', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!id || !uuidRegex.test(id)) {
      return res.status(404).json({ error: 'Not Found', message: 'Meal history entry not found' });
    }

    const result = await query(
      `SELECT id, user_id, meal_type, food_name, food_ids, calories, macros,
        total_glycemic_load, net_carbs_g, gl_class, logged_at, created_at, updated_at
       FROM user_meals WHERE id = $1 AND user_id = $2`,
      [id, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Meal history entry not found or does not belong to user' });
    }

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});
/**
 * @route POST /api/meal-history
 * @desc Create a new meal history entry
 * @access Private
 */
router.post('/', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const {
      meal_type,
      food_name,
      food_ids = [],
      calories,
      macros = { protein_g: 0, carbs_g: 0, fat_g: 0 },
      total_glycemic_load = 0,
      net_carbs_g = 0,
      gl_class = 'low',
    } = req.body || {};

    if (!meal_type || typeof meal_type !== 'string' || meal_type.trim() === '') {
      return res.status(400).json({ error: 'Invalid input', message: 'meal_type is required and must be a non-empty string' });
    }

    if (!food_name || typeof food_name !== 'string' || food_name.trim() === '') {
      return res.status(400).json({ error: 'Invalid input', message: 'food_name is required and must be a non-empty string' });
    }

    if (calories === undefined || calories === null || typeof calories !== 'number' || calories < 0) {
      return res.status(400).json({ error: 'Invalid input', message: 'calories must be a non-negative number' });
    }

    const validGlClass = ['low', 'medium', 'high'];
    if (!validGlClass.includes(gl_class)) {
      return res.status(400).json({ error: 'Invalid input', message: `gl_class must be one of: ${validGlClass.join(', ')}` });
    }

    const macrosObj = {
      protein_g: typeof macros?.protein_g === 'number' ? macros.protein_g : 0,
      carbs_g: typeof macros?.carbs_g === 'number' ? macros.carbs_g : 0,
      fat_g: typeof macros?.fat_g === 'number' ? macros.fat_g : 0,
    };

    const foodIdsArray = Array.isArray(food_ids) && food_ids.length > 0 ? food_ids : [];

    const insertQuery = `
      INSERT INTO user_meals 
      (user_id, meal_type, food_name, food_ids, calories, macros, total_glycemic_load, net_carbs_g, gl_class)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING id, user_id, meal_type, food_name, food_ids, calories, macros,
        total_glycemic_load, net_carbs_g, gl_class, logged_at
    `;

    const result = await query(insertQuery, [
      userId, meal_type.trim(), food_name.trim(), foodIdsArray, calories,
      JSON.stringify(macrosObj), total_glycemic_load, net_carbs_g, gl_class,
    ]);

    return res.status(201).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

/**
 * @route DELETE /api/meal-history/:id
 * @desc Delete a meal history entry by ID
 * @access Private
 */
router.delete('/:id', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { id } = req.params;

    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!id || !uuidRegex.test(id)) {
      return res.status(404).json({ error: 'Not Found', message: 'Meal history entry not found' });
    }

    const deleteQuery = 'DELETE FROM user_meals WHERE id = $1 AND user_id = $2 RETURNING id';
    const result = await query(deleteQuery, [id, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Not Found', message: 'Meal history entry not found or does not belong to user' });
    }

    return res.status(200).json({ message: 'Meal history entry deleted successfully', deletedId: result.rows[0].id });
  } catch (error) {
    next(error);
  }
});



module.exports = router;