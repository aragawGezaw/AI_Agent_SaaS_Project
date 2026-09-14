const fs = require('fs');
const path = require('path');
const a = path.join('lib', 'l10n', 'app_am.arb');
const k = {
  healthDashboard: 'የጠና ዳሽቦርድ',
  weeklyOverview: 'የ7-ቀን እይታ',
  todaysProgress: 'የዛምሻው ግብረመልስ',
  calories: 'ካሎሪ',
  glycemicLoad: 'የግላይሲሚክ ሸካራነት',
  protein: 'ፅሮቲን',
  carbs: 'ካርቦሻይድ',
  fat: 'ሲብ',
  mealsLogged: 'የተመዘገቡ ምግቦች',
  avgDaily: 'አማካኝ / ቀን',
  total: 'ጠቅላላ',
  target: 'ግብ',
  ofTarget: '{value}% የግብ',
  glycemicLoadLow: 'ዝቅተኚ ግል',
  glycemicLoadModerate: 'መካከሊኚ ግል',
  glycemicLoadExceeded: 'ግል ተሻግሯል',
  kcal: 'ኪካሎ',
  g: 'ግ',
  noAnalyticsData: 'የታኒቲክስ ውሂብ የሉም',
  startTrackingMeals: 'የእርስዎን የታኒቲክስ ለማየት ምግቦችን ማስጀመር ጀምሩ',
  viewTodaysMealPlan: 'የዛምሻውን የምጋብ እቅድ ይመልከቱ',
  viewFoodLog: 'የምጋብ ታሪክ ይመልከቱ',
  metabolicHealth: 'የሜታቦሊክ ጠና',
  nutrientBreakdown: 'የአመጋወብ ዝርዝር',
  macrosDistribution: 'የማክሮ ስርጭት'
};
let r = fs.readFileSync(a, 'utf8');
r = r.replace(/^(\s*"@@locale":\s*"am",?\s*)$/m, '').replace(/\n\n+/g, '\n').trim();
let d = JSON.parse(r);
Object.assign(d, k);
fs.writeFileSync(a, JSON.stringify(d, null, 2) + '\n', 'utf8');
console.log('Updated', a);
