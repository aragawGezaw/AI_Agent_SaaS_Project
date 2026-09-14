const d = require('../lib/l10n/app_am.arb');
const needed = ['healthDashboard','weeklyOverview','todaysProgress','calories','glycemicLoad','protein','carbs','fat','mealsLogged','avgDaily','total','target','ofTarget','glycemicLoadLow','glycemicLoadModerate','glycemicLoadExceeded','kcal','g','noAnalyticsData','startTrackingMeals','viewTodaysMealPlan','viewFoodLog','metabolicHealth','nutrientBreakdown','macrosDistribution'];
const missing = needed.filter(k => !d[k]);
console.log('Total keys:', Object.keys(d).length);
console.log('Missing:', missing);
console.log('Sample:', { healthDashboard: d.healthDashboard, glycemicLoadExceeded: d.glycemicLoadExceeded, macrosDistribution: d.macrosDistribution });
console.log('Valid JSON: yes (loaded successfully)');
