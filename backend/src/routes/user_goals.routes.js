const express = require('express');
const router = express.Router();
const { query } = require('../db/index.js');
const authenticateToken = require('../middleware/auth.middleware.js');

router.get('/', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    let result = await query('SELECT * FROM user_goals WHERE user_id = $1', [userId]);
    
    if (result.rows.length === 0) {
      await query(
        `INSERT INTO user_goals (user_id, glycemic_load_low_threshold, glycemic_load_medium_threshold, preferred_language, goal_focus)
         VALUES ($1, 10.00, 20.00, 'en', 'maintenance')
         ON CONFLICT (user_id) DO NOTHING`,
        [userId]
      );
      result = await query('SELECT * FROM user_goals WHERE user_id = $1', [userId]);
    }
    
    return res.status(200).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

router.put('/', authenticateToken, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const body = req.body || {};

    // Validate
    if (body.goal_focus && !['weight_loss', 'maintenance', 'muscle_gain', 'fasting_support', 'diabetes_management'].includes(body.goal_focus)) {
      return res.status(400).json({ error: 'Invalid goal_focus' });
    }
    if (body.preferred_language && !['en', 'am'].includes(body.preferred_language)) {
      return res.status(400).json({ error: 'Invalid preferred_language' });
    }
    if (body.glycemic_load_low_threshold !== undefined && body.glycemic_load_medium_threshold !== undefined &&
        body.glycemic_load_medium_threshold < body.glycemic_load_low_threshold) {
      return res.status(400).json({ error: 'GL medium threshold must be >= low threshold' });
    }

    // Fetch existing goals to merge with defaults
    let existing = await query('SELECT * FROM user_goals WHERE user_id = $1', [userId]);
    const defaults = {
      daily_calorie_target: null,
      daily_protein_target_g: null,
      daily_carbs_target_g: null,
      daily_fat_target_g: null,
      glycemic_load_low_threshold: 10.00,
      glycemic_load_medium_threshold: 20.00,
      daily_glycemic_load_limit: null,
      preferred_language: 'en',
      goal_focus: 'maintenance'
    };
    const current = existing.rows.length > 0 ? existing.rows[0] : defaults;

    // Merge provided fields with existing/defaults
    const merged = {
      daily_calorie_target: body.daily_calorie_target !== undefined ? body.daily_calorie_target : current.daily_calorie_target,
      daily_protein_target_g: body.daily_protein_target_g !== undefined ? body.daily_protein_target_g : current.daily_protein_target_g,
      daily_carbs_target_g: body.daily_carbs_target_g !== undefined ? body.daily_carbs_target_g : current.daily_carbs_target_g,
      daily_fat_target_g: body.daily_fat_target_g !== undefined ? body.daily_fat_target_g : current.daily_fat_target_g,
      glycemic_load_low_threshold: body.glycemic_load_low_threshold !== undefined ? body.glycemic_load_low_threshold : current.glycemic_load_low_threshold,
      glycemic_load_medium_threshold: body.glycemic_load_medium_threshold !== undefined ? body.glycemic_load_medium_threshold : current.glycemic_load_medium_threshold,
      daily_glycemic_load_limit: body.daily_glycemic_load_limit !== undefined ? body.daily_glycemic_load_limit : current.daily_glycemic_load_limit,
      preferred_language: body.preferred_language !== undefined ? body.preferred_language : current.preferred_language,
      goal_focus: body.goal_focus !== undefined ? body.goal_focus : current.goal_focus
    };

    const upsertQuery = `
      INSERT INTO user_goals (
        user_id, daily_calorie_target, daily_protein_target_g, daily_carbs_target_g,
        daily_fat_target_g, glycemic_load_low_threshold, glycemic_load_medium_threshold,
        daily_glycemic_load_limit, preferred_language, goal_focus
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      ON CONFLICT (user_id)
      DO UPDATE SET
        daily_calorie_target = EXCLUDED.daily_calorie_target,
        daily_protein_target_g = EXCLUDED.daily_protein_target_g,
        daily_carbs_target_g = EXCLUDED.daily_carbs_target_g,
        daily_fat_target_g = EXCLUDED.daily_fat_target_g,
        glycemic_load_low_threshold = EXCLUDED.glycemic_load_low_threshold,
        glycemic_load_medium_threshold = EXCLUDED.glycemic_load_medium_threshold,
        daily_glycemic_load_limit = EXCLUDED.daily_glycemic_load_limit,
        preferred_language = EXCLUDED.preferred_language,
        goal_focus = EXCLUDED.goal_focus,
        updated_at = CURRENT_TIMESTAMP
      RETURNING id, user_id, daily_calorie_target, daily_protein_target_g, daily_carbs_target_g,
        daily_fat_target_g, glycemic_load_low_threshold, glycemic_load_medium_threshold,
        daily_glycemic_load_limit, preferred_language, goal_focus, created_at, updated_at
    `;

    const values = [
      userId,
      merged.daily_calorie_target,
      merged.daily_protein_target_g,
      merged.daily_carbs_target_g,
      merged.daily_fat_target_g,
      merged.glycemic_load_low_threshold,
      merged.glycemic_load_medium_threshold,
      merged.daily_glycemic_load_limit,
      merged.preferred_language,
      merged.goal_focus
    ];

    const result = await query(upsertQuery, values);
    return res.status(200).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

module.exports = router;