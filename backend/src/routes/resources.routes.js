const express = require('express');
const router = express.Router();
const { query } = require('../db/index.js');

// Valid categories
const VALID_CATEGORIES = ['nutrition', 'glycemic_index', 'fasting', 'recipes', 'health_tips', 'exercise'];

/**
 * @route GET /api/resources
 * @desc Get all educational resources with optional category filtering
 * @access Public (no auth required for reading resources)
 */
router.get('/', async (req, res, next) => {
  try {
    const { category, language, featured, limit = 50, offset = 0 } = req.query;

    // Build dynamic query
    let sql = `
      SELECT 
        id, title, category, summary, video_url, thumbnail_url,
        language, is_featured, view_count, created_at
      FROM educational_resources
      WHERE is_published = TRUE
    `;
    const params = [];
    let paramIndex = 1;

    // Filter by category
    if (category) {
      if (!VALID_CATEGORIES.includes(category)) {
        return res.status(400).json({ error: 'Invalid category' });
      }
      sql += ` AND category = $${paramIndex++}`;
      params.push(category);
    }

    // Filter by language
    if (language) {
      if (!['en', 'am', 'both'].includes(language)) {
        return res.status(400).json({ error: 'Invalid language' });
      }
      sql += ` AND (language = $${paramIndex++} OR language = 'both')`;
      params.push(language);
    }

    // Filter featured only
    if (featured === 'true') {
      sql += ' AND is_featured = TRUE';
    }

    // Ordering and pagination
    sql += ` ORDER BY is_featured DESC, created_at DESC`;
    sql += ` LIMIT $${paramIndex++} OFFSET $${paramIndex++}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await query(sql, params);

    // Get total count for pagination
    let countSql = 'SELECT COUNT(*) FROM educational_resources WHERE is_published = TRUE';
    const countParams = [];
    let countParamIndex = 1;

    if (category) {
      countSql += ` AND category = $${countParamIndex++}`;
      countParams.push(category);
    }
    if (language) {
      countSql += ` AND (language = $${countParamIndex++} OR language = 'both')`;
      countParams.push(language);
    }
    if (featured === 'true') {
      countSql += ' AND is_featured = TRUE';
    }

    const countResult = await query(countSql, countParams);
    const total = parseInt(countResult.rows[0].count);

    return res.status(200).json({
      data: result.rows,
      pagination: {
        total,
        limit: parseInt(limit),
        offset: parseInt(offset),
        hasMore: parseInt(offset) + result.rows.length < total
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route GET /api/resources/categories
 * @desc Get list of available categories with resource counts
 * @access Public
 */
router.get('/categories', async (req, res, next) => {
  try {
    const sql = `
      SELECT category, COUNT(*) as count
      FROM educational_resources
      WHERE is_published = TRUE
      GROUP BY category
      ORDER BY category
    `;
    const result = await query(sql);

    return res.status(200).json({
      categories: result.rows
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route GET /api/resources/search/:term
 * @desc Search resources by title or content
 * @access Public
 */
router.get('/search/:term', async (req, res, next) => {
  try {
    const { term } = req.params;
    const { language, limit = 20 } = req.query;

    let sql = `
      SELECT 
        id, title, category, summary, video_url, thumbnail_url,
        language, is_featured, view_count, created_at
      FROM educational_resources
      WHERE is_published = TRUE
        AND (title ILIKE $1 OR summary ILIKE $1 OR content_body ILIKE $1)
    `;
    const params = [`%${term}%`];
    let paramIndex = 2;

    if (language) {
      sql += ` AND (language = $${paramIndex++} OR language = 'both')`;
      params.push(language);
    }

    sql += ` ORDER BY is_featured DESC, view_count DESC LIMIT $${paramIndex}`;
    params.push(parseInt(limit));

    const result = await query(sql, params);

    return res.status(200).json({
      data: result.rows,
      query: term,
      count: result.rows.length
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route GET /api/resources/:id
 * @desc Get a single educational resource by ID
 * @access Public
 */
router.get('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;

    // Get resource
    const sql = `
      SELECT *
      FROM educational_resources
      WHERE id = $1 AND is_published = TRUE
    `;
    const result = await query(sql, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Resource not found' });
    }

    // Increment view count
    await query(
      'UPDATE educational_resources SET view_count = view_count + 1 WHERE id = $1',
      [id]
    );

    return res.status(200).json(result.rows[0]);
  } catch (error) {
    next(error);
  }
});

module.exports = router;