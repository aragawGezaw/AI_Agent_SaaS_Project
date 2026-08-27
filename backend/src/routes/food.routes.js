const express = require('express');
const router = express.Router();
const FoodService = require('../services/food.service.js');

/**
 * @route GET /api/foods/search
 * @desc Search for foods by name with optional source filtering
 * @access Public
 * @queryParam q - Search query string (required)
 * @queryParam lang - Language code 'en' or 'am' (default: 'en')
 * @queryParam source - Filter by source 'EPHI' (Ethiopian) or 'USDA' (Global)
 * @queryParam limit - Maximum results to return (default: 20)
 */
router.get('/search', async (req, res, next) => {
  try {
    const { q, lang = 'en', source, limit = 20 } = req.query;

    // Validate search query
    if (!q || typeof q !== 'string' || q.trim() === '') {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Search query parameter "q" is required and must be a non-empty string'
      });
    }

    // Validate language
    const validLang = (lang === 'en' || lang === 'am') ? lang : 'en';

    // Validate source filter
    const validSource = (source === 'EPHI' || source === 'USDA') ? source : null;

    // Validate limit
    const numericLimit = parseInt(limit, 10);
    const limitValue = (!isNaN(numericLimit) && numericLimit > 0) ? Math.min(numericLimit, 100) : 20;

    // Search foods
    const foods = await FoodService.searchFoods(q.trim(), validLang, validSource, limitValue);

    // Format response
    const response = {
      results: foods.map(food => ({
        id: food.id,
        name_en: food.name_en,
        name_am: food.name_am,
        calories_per_100g: parseFloat(food.calories_per_100g),
        protein_g: parseFloat(food.protein_g),
        carbs_g: parseFloat(food.carbs_g),
        fiber_g: parseFloat(food.fiber_g),
        fat_g: parseFloat(food.fat_g),
        glycemic_index: food.glycemic_index ? parseFloat(food.glycemic_index) : null,
        source: food.source,
        created_at: food.created_at,
        updated_at: food.updated_at,
      })),
      count: foods.length,
      query: q,
    };

    return res.status(200).json(response);
  } catch (error) {
    next(error);
  }
});

/**
 * @route GET /api/foods/:id
 * @desc Get a single food item by ID
 * @access Public
 */
router.get('/:id', async (req, res, next) => {
  try {
    const { id } = req.params;

    // Validate UUID format
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    if (!id || !uuidRegex.test(id)) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Food item not found'
      });
    }

    const food = await FoodService.getFoodById(id);

    if (!food) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Food item not found'
      });
    }

    return res.status(200).json({
      id: food.id,
      name_en: food.name_en,
      name_am: food.name_am,
      calories_per_100g: parseFloat(food.calories_per_100g),
      protein_g: parseFloat(food.protein_g),
      carbs_g: parseFloat(food.carbs_g),
      fiber_g: parseFloat(food.fiber_g),
      fat_g: parseFloat(food.fat_g),
      glycemic_index: food.glycemic_index ? parseFloat(food.glycemic_index) : null,
      source: food.source,
      created_at: food.created_at,
      updated_at: food.updated_at,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route GET /api/foods/source/:source
 * @desc Get all foods filtered by source (EPHI for Ethiopian, USDA for Global)
 * @access Public
 */
router.get('/source/:source', async (req, res, next) => {
  try {
    const { source } = req.params;

    // Validate source parameter
    if (source !== 'EPHI' && source !== 'USDA') {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Source must be either "EPHI" (Ethiopian) or "USDA" (Global)'
      });
    }

    const foods = await FoodService.getAllFoods(source);

    return res.status(200).json({
      source,
      count: foods.length,
      results: foods.map(food => ({
        id: food.id,
        name_en: food.name_en,
        name_am: food.name_am,
        calories_per_100g: parseFloat(food.calories_per_100g),
        protein_g: parseFloat(food.protein_g),
        carbs_g: parseFloat(food.carbs_g),
        fiber_g: parseFloat(food.fiber_g),
        fat_g: parseFloat(food.fat_g),
        glycemic_index: food.glycemic_index ? parseFloat(food.glycemic_index) : null,
      })),
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;