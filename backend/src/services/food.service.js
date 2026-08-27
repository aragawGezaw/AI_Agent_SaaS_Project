const { query } = require('../db/index.js');

/**
 * Food Service - handles business logic for food search and retrieval
 * Supports bilingual search (Amharic & English) and filtering by source
 */
class FoodService {
  /**
   * Search foods by name (supports partial match, case-insensitive)
   * @param {string} searchQuery - Search term
   * @param {string} lang - Language code ('en' or 'am')
   * @param {string} source - Filter by source ('EPHI', 'USDA', or null for all)
   * @param {number} limit - Maximum number of results
   * @returns {Promise<Array>} - Array of matching food items
   */
  static async searchFoods(searchQuery, lang = 'en', source = null, limit = 20) {
    let sql, params;

    if (source) {
      sql = `
        SELECT * FROM foods
        WHERE (name_en ILIKE $1 OR name_am ILIKE $1) AND source = $2
        ORDER BY name_en ASC
        LIMIT $3
      `;
      params = [`%${searchQuery}%`, source, limit];
    } else {
      sql = `
        SELECT * FROM foods
        WHERE (name_en ILIKE $1 OR name_am ILIKE $1)
        ORDER BY name_en ASC
        LIMIT $2
      `;
      params = [`%${searchQuery}%`, limit];
    }

    const result = await query(sql, params);
    return result.rows;
  }

  /**
   * Get food by ID
   * @param {string} id - Food UUID
   * @returns {Promise<Object|null>} - Food item or null
   */
  static async getFoodById(id) {
    const sql = 'SELECT * FROM foods WHERE id = $1';
    const result = await query(sql, [id]);
    return result.rows[0] || null;
  }

  /**
   * Get all foods, optionally filtered by source
   * @param {string} source - Filter by source ('EPHI', 'USDA', or null for all)
   * @param {number} limit - Maximum number of results
   * @returns {Promise<Array>} - Array of food items
   */
  static async getAllFoods(source = null, limit = 100) {
    let sql, params;

    if (source) {
      sql = 'SELECT * FROM foods WHERE source = $1 ORDER BY name_en ASC LIMIT $2';
      params = [source, limit];
    } else {
      sql = 'SELECT * FROM foods ORDER BY name_en ASC LIMIT $1';
      params = [limit];
    }

    const result = await query(sql, params);
    return result.rows;
  }
}

module.exports = FoodService;