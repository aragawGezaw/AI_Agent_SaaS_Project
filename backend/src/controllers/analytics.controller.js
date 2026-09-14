const { query } = require('../db/index.js');

const getAnalyticsSummary = async (req, res, next) => {
  try {
    const userId = req.user.id;
    let goalsRes = await query('SELECT * FROM user_goals WHERE user_id = $1', [userId]);
    if (goalsRes.rows.length === 0) {
      await query(
        `INSERT INTO user_goals (user_id, glycemic_load_low_threshold, glycemic_load_medium_threshold, preferred_language, goal_focus)
         VALUES ($1, 10.00, 20.00, 'en', 'maintenance') ON CONFLICT (user_id) DO NOTHING`, [userId]
      );
      goalsRes = await query('SELECT * FROM user_goals WHERE user_id = $1', [userId]);
    }
    const goals = goalsRes.rows[0];
    const calTarget = goals.daily_calorie_target || 2000;
    const protTarget = parseFloat(goals.daily_protein_target_g) || 75.0;
    const carbTarget = parseFloat(goals.daily_carbs_target_g) || 250.0;
    const fatTarget = parseFloat(goals.daily_fat_target_g) || 65.0;
    const glLimit = parseFloat(goals.daily_glycemic_load_limit) || 100.0;

    const todayLocal = new Date(new Date().toLocaleString("en-US", { timeZone: "Africa/Addis_Ababa" }));
    const days = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(todayLocal);
      d.setDate(todayLocal.getDate() - i);
      days.push(d.toISOString().split('T')[0]);
    }
    const startDate = days[0];
    const endDate = days[6];

    const trendsQuery = `
      SELECT 
        TO_CHAR(logged_at AT TIME ZONE 'Africa/Addis_Ababa', 'YYYY-MM-DD') AS day,
        COALESCE(SUM(calories), 0)::INTEGER AS total_calories,
        COALESCE(SUM(total_glycemic_load), 0)::NUMERIC(10,2) AS total_glycemic_load,
        COALESCE(SUM((macros->>'protein_g')::numeric), 0)::NUMERIC(10,2) AS total_protein_g,
        COALESCE(SUM((macros->>'carbs_g')::numeric), 0)::NUMERIC(10,2) AS total_carbs_g,
        COALESCE(SUM((macros->>'fat_g')::numeric), 0)::NUMERIC(10,2) AS total_fat_g,
        COUNT(id)::INTEGER AS meal_count
      FROM user_meals
      WHERE user_id = $1
        AND (logged_at AT TIME ZONE 'Africa/Addis_Ababa')::date >= $2::date
        AND (logged_at AT TIME ZONE 'Africa/Addis_Ababa')::date <= $3::date
      GROUP BY TO_CHAR(logged_at AT TIME ZONE 'Africa/Addis_Ababa', 'YYYY-MM-DD')
    `;
    const result = await query(trendsQuery, [userId, startDate, endDate]);
    const trendsMap = {};
    result.rows.forEach(r => {
      trendsMap[r.day] = {
        calories: r.total_calories,
        glycemic_load: parseFloat(r.total_glycemic_load),
        protein_g: parseFloat(r.total_protein_g),
        carbs_g: parseFloat(r.total_carbs_g),
        fat_g: parseFloat(r.total_fat_g),
        meal_count: r.meal_count
      };
    });

    const dailyTrends = days.map(day => {
      const ext = trendsMap[day];
      return {
        date: day,
        calories: ext ? ext.calories : 0,
        glycemic_load: ext ? ext.glycemic_load : 0.0,
        protein_g: ext ? ext.protein_g : 0.0,
        carbs_g: ext ? ext.carbs_g : 0.0,
        fat_g: ext ? ext.fat_g : 0.0,
        meal_count: ext ? ext.meal_count : 0
      };
    });

    const totalCalories = dailyTrends.reduce((sum, d) => sum + d.calories, 0);
    const totalGL = dailyTrends.reduce((sum, d) => sum + d.glycemic_load, 0);
    const totalProt = dailyTrends.reduce((sum, d) => sum + d.protein_g, 0);
    const totalCarb = dailyTrends.reduce((sum, d) => sum + d.carbs_g, 0);
    const totalFat = dailyTrends.reduce((sum, d) => sum + d.fat_g, 0);

    const todaySummary = dailyTrends[6];
    const calPct = calTarget > 0 ? Math.round((todaySummary.calories / calTarget) * 100) : 0;
    const glPct = glLimit > 0 ? Math.round((todaySummary.glycemic_load / glLimit) * 100) : 0;
    const glStatus = todaySummary.glycemic_load > glLimit ? 'exceeded' : (todaySummary.glycemic_load > (glLimit * 0.7) ? 'moderate' : 'low');

    return res.status(200).json({
      summary: {
        period_days: 7,
        total_calories: totalCalories,
        avg_daily_calories: parseFloat((totalCalories / 7).toFixed(1)),
        total_glycemic_load: parseFloat(totalGL.toFixed(2)),
        avg_daily_glycemic_load: parseFloat((totalGL / 7).toFixed(1)),
        total_macros: {
          protein_g: parseFloat(totalProt.toFixed(2)),
          carbs_g: parseFloat(totalCarb.toFixed(2)),
          fat_g: parseFloat(totalFat.toFixed(2))
        },
        avg_daily_macros: {
          protein_g: parseFloat((totalProt / 7).toFixed(1)),
          carbs_g: parseFloat((totalCarb / 7).toFixed(1)),
          fat_g: parseFloat((totalFat / 7).toFixed(1))
        },
        today: {
          date: endDate,
          calories: todaySummary.calories,
          glycemic_load: todaySummary.glycemic_load,
          macros: {
            protein_g: todaySummary.protein_g,
            carbs_g: todaySummary.carbs_g,
            fat_g: todaySummary.fat_g
          },
          meal_count: todaySummary.meal_count
        }
      },
      goals,
      comparisons: {
        calorie_target: calTarget,
        calorie_percentage: calPct,
        glycemic_load_limit: glLimit,
        glycemic_load_percentage: glPct,
        glycemic_status: glStatus,
        protein_target_g: protTarget,
        carbs_target_g: carbTarget,
        fat_target_g: fatTarget,
        protein_percentage: protTarget > 0 ? Math.round((todaySummary.protein_g / protTarget) * 100) : 0,
        carbs_percentage: carbTarget > 0 ? Math.round((todaySummary.carbs_g / carbTarget) * 100) : 0,
        fat_percentage: fatTarget > 0 ? Math.round((todaySummary.fat_g / fatTarget) * 100) : 0,
      },
      daily_trends: dailyTrends
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { getAnalyticsSummary };
