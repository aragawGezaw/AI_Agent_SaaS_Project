const { query } = require('../db/index.js');

/**
 * Nutrition Service - Phase 4: AI Agent & Glycemic Load Calculation Engine
 *
 * Calculates:
 *   - Net Carbs: (carbs_g - fiber_g) scaled to the consumed portion (grams).
 *   - Glycemic Load (GL): (glycemic_index * netCarbs) / 100.
 */
class NutritionService {
  /**
   * Round to 2 decimal places.
   * @param {number} value
   * @returns {number}
   */
  static _round2(value) {
    return Math.round((value + Number.EPSILON) * 100) / 100;
  }

  /**
   * Calculate Net Carbs for a given food at a specified portion (grams).
   * Net Carbs = (carbs_per_100g - fiber_per_100g) * (portion_g / 100)
   *
   * @param {Object} food - Food record with carbs_g and fiber_g per 100g
   * @param {number} portionG - Portion in grams
   * @returns {number} Net carbs in grams
   */
  static calculateNetCarbs(food, portionG) {
    const carbsPer100g = Number(food.carbs_g) || 0;
    const fiberPer100g = Number(food.fiber_g) || 0;
    const scale = portionG / 100;
    const netCarbsPer100g = carbsPer100g - fiberPer100g;
    const netCarbs = netCarbsPer100g * scale;
    return this._round2(Math.max(0, netCarbs));
  }

  /**
   * Calculate Glycemic Load (GL) for a given food at a specified portion (grams).
   * GL = (glycemic_index * netCarbs) / 100
   *
   * @param {Object} food - Food record with glycemic_index
   * @param {number} portionG - Portion in grams
   * @returns {number} Glycemic Load value
   */
  static calculateGlycemicLoad(food, portionG) {
    const gi = food.glycemic_index !== null && food.glycemic_index !== undefined
      ? Number(food.glycemic_index)
      : 0;
    const netCarbs = this.calculateNetCarbs(food, portionG);
    const gl = (gi * netCarbs) / 100;
    return this._round2(gl);
  }

  /**
   * Scale a per-100g nutrient to the consumed portion (grams).
   * @param {number} per100g - Nutrient value per 100g
   * @param {number} portionG - Portion in grams
   * @returns {number} Scaled value rounded to 2 decimal places
   */
  static scaleToPortion(per100g, portionG) {
    return this._round2((Number(per100g) || 0) * (portionG / 100));
  }

  /**
   * Classify Glycemic Load value using user-defined thresholds.
   * Falls back to defaults (low=10, medium=20) when thresholds are null/undefined.
   * @param {number} gl
   * @param {Object} thresholds - { lowThreshold: number, mediumThreshold: number }
   * @returns {string} 'low' | 'medium' | 'high'
   */
  static classifyGlycemicLoad(gl, thresholds = {}) {
    const lowThreshold = thresholds.lowThreshold ?? 10;
    const mediumThreshold = thresholds.mediumThreshold ?? 19;
    if (gl <= lowThreshold) return 'low';
    if (gl <= mediumThreshold) return 'medium';
    return 'high';
  }

  /**
   * Build an AI-structured evaluation note for a meal analysis.
   * Uses user-defined GL thresholds when provided.
   * @param {Object} summary - Meal summary with totals and per-item breakdown
   * @param {Object} thresholds - { lowThreshold: number, mediumThreshold: number }
   * @returns {Object} AI-structured evaluation note
   */
  static buildEvaluationNote(summary, thresholds = {}) {
    const { totals, total_glycemic_load, items } = summary;
    const glClass = this.classifyGlycemicLoad(total_glycemic_load, thresholds);

    const sortedByGl = [...items].sort((a, b) => b.glycemic_load - a.glycemic_load);
    const topContributor = sortedByGl[0];

    let recommendation;
    if (glClass === 'high') {
      recommendation = `This meal has a HIGH Glycemic Load (${total_glycemic_load}). Consider pairing with fiber-rich legumes, vegetables, or healthy fats (e.g., Shiro, lentils) to slow glucose absorption. For Ethiopian meals, balance Injera portions with protein-rich Shiro or legumes.`;
    } else if (glClass === 'medium') {
      recommendation = `This meal has a MEDIUM Glycemic Load (${total_glycemic_load}). Adding more protein, fiber, or healthy fats can stabilize post-meal blood sugar. Traditional Ethiopian sides like legumes or vegetables complement this well.`;
    } else {
      recommendation = `This meal has a LOW Glycemic Load (${total_glycemic_load}). It is balanced for steady blood sugar. Good pairing with fasting-friendly Ethiopian staples such as Shiro, lentils, and vegetables.`;
    }

    return {
      glycemic_load_class: glClass,
      total_glycemic_load,
      top_contributor: topContributor && topContributor.glycemic_load > 0
        ? {
            food_id: topContributor.food_id,
            name_en: topContributor.name_en,
            name_am: topContributor.name_am,
            portion_g: topContributor.portion_g,
            glycemic_load: topContributor.glycemic_load,
          }
        : null,
      totals: {
        calories: totals.calories,
        protein_g: totals.protein_g,
        carbs_g: totals.carbs_g,
        fiber_g: totals.fiber_g,
        fat_g: totals.fat_g,
        net_carbs_g: totals.net_carbs_g,
      },
      recommendation,
    };
  }

  /**
   * Analyze a meal given a list of food IDs and portion weights (grams).
   * Optionally pass user-specific GL thresholds for classification.
   * @param {Array<{food_id: string, portion_g: number}>} mealItems
   * @param {Object} thresholds - { lowThreshold: number, mediumThreshold: number }
   * @returns {Promise<Object>} Meal analysis result
   */
  static async analyzeMeal(mealItems, thresholds = {}) {
    const ids = mealItems.map((item) => item.food_id);
    const foodsResult = await query(
      'SELECT * FROM foods WHERE id = ANY($1::uuid[])',
      [ids]
    );
    const foodsMap = new Map(foodsResult.rows.map((f) => [f.id, f]));

    const items = [];
    const totals = {
      calories: 0,
      protein_g: 0,
      carbs_g: 0,
      fiber_g: 0,
      fat_g: 0,
      net_carbs_g: 0,
    };

    for (const item of mealItems) {
      const food = foodsMap.get(item.food_id);
      if (!food) continue;

      const portionG = Number(item.portion_g) || 0;
      const calories = this.scaleToPortion(food.calories_per_100g, portionG);
      const protein = this.scaleToPortion(food.protein_g, portionG);
      const carbs = this.scaleToPortion(food.carbs_g, portionG);
      const fiber = this.scaleToPortion(food.fiber_g, portionG);
      const fat = this.scaleToPortion(food.fat_g, portionG);
      const netCarbs = this.calculateNetCarbs(food, portionG);
      const glycemicLoad = this.calculateGlycemicLoad(food, portionG);

      items.push({
        food_id: food.id,
        name_en: food.name_en,
        name_am: food.name_am,
        source: food.source,
        portion_g: portionG,
        calories,
        protein_g: protein,
        carbs_g: carbs,
        fiber_g: fiber,
        fat_g: fat,
        net_carbs_g: netCarbs,
        glycemic_load: glycemicLoad,
      });

      totals.calories += calories;
      totals.protein_g += protein;
      totals.carbs_g += carbs;
      totals.fiber_g += fiber;
      totals.fat_g += fat;
      totals.net_carbs_g += netCarbs;
    }

    totals.calories = this._round2(totals.calories);
    totals.protein_g = this._round2(totals.protein_g);
    totals.carbs_g = this._round2(totals.carbs_g);
    totals.fiber_g = this._round2(totals.fiber_g);
    totals.fat_g = this._round2(totals.fat_g);
    totals.net_carbs_g = this._round2(totals.net_carbs_g);

    const total_glycemic_load = this._round2(
      items.reduce((sum, it) => sum + it.glycemic_load, 0)
    );

    const evaluationNote = this.buildEvaluationNote({
      totals,
      total_glycemic_load,
      items,
    }, thresholds);

    return {
      items,
      totals,
      total_glycemic_load,
      evaluation_note: evaluationNote,
    };
  }
}

module.exports = NutritionService;