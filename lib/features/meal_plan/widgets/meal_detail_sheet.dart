import 'package:flutter/material.dart';
import '../models/meal_plan.dart';

void showMealDetailSheet(BuildContext context, MealPlan meal) {
  final isAm = Localizations.localeOf(context).languageCode == 'am';
  final foodNameLower = (meal.foodName ?? '').toLowerCase();
  final isFasting = meal.isFastingMeal;

  // 1. Prioritize model/database ingredients & instructions first
  List<String> ingredients = List<String>.from(meal.ingredients);
  List<String> instructions = List<String>.from(meal.instructions);

  // 2. Smart fallback dictionary only if model lists are empty
  if (ingredients.isEmpty) {
    if (isFasting) {
      if (foodNameLower.contains('ful') || foodNameLower.contains('fava')) {
        ingredients = isAm
            ? [
                '200g የተከተፈ የባቄላ ጥራጥሬ (Ful) (~14g ፕሮቲን)',
                '2 የሾርባ ማንኪያ የጸሃይ አበባ ቅባት (Sunflower Paste) (~6g ፕሮቲን)',
                '1 መካከለኛ የጤፍ እንጀራ (~3g ፕሮቲን)',
                'ቀይ ሽንኩርት፣ ቲማቲም፣ ሎሚ እና አረንጓዴ በርበሬ',
              ]
            : [
                '200g Stewed Fava Beans (Ful) (~14g plant protein)',
                '2 tbsp Sunflower Seed Paste / Tahini (~6g protein)',
                '1 Medium Teff Injera piece (~3g protein, Low GL)',
                'Fresh red onion, tomato, lemon juice, and green chili',
              ];
      } else {
        ingredients = isAm
            ? [
                '100g የደረቀ ምስር ወይም ሽሮ ዱቄት (~22g ከፍተኛ የእጽዋት ፕሮቲን)',
                '1 መካከለኛ የጤፍ እንጀራ (~3g ፕሮቲን)',
                'ነጭ ሽንኩርት፣ ዝንጅብል፣ ሽንኩርት እና በርበሬ',
              ]
            : [
                '100g Dry Red Lentils or Shiro Chickpea flour (~22g protein)',
                '1 Medium Teff Injera piece (~3g protein, Low GL)',
                'Garlic, ginger, onions, and Berbere spice blend',
              ];
      }
    } else {
      if (foodNameLower.contains('enkulal') || foodNameLower.contains('egg')) {
        ingredients = isAm
            ? [
                '3 ትላልቅ ሙሉ እንቁላሎች (~18g ፕሮቲን)',
                '50g ፍጹም አይብ/አሬራ (~9g ፕሮቲን)',
                '1 መካከለኛ የጤፍ እንጀራ (~3g ፕሮቲን)',
              ]
            : [
                '3 Large Whole Eggs (~18g protein)',
                '50g Fresh Ayib / Ethiopian Cottage Cheese (~9g protein)',
                '1 Medium Teff Injera piece (~3g protein, Low GL)',
              ];
      } else {
        ingredients = isAm
            ? [
                '120g ስብ የሌለው ከርሥ ስጋ/ጥጃ ስጋ (~30g ፕሮቲን)',
                '1 ኩባያ የተጣራ ጎመን',
                '1 መካከለኛ የጤፍ እንጀራ (~3g ፕሮቲን)',
              ]
            : [
                '120g Lean Beef cubes, trimmed of fat (~30g protein)',
                '1 Cup Steamed Gomen / Collard Greens',
                '1 Medium Teff Injera piece (~3g protein, Low GL)',
              ];
      }
    }
  }

  if (instructions.isEmpty) {
    instructions = isAm
        ? [
            'ግብዓቶችን በትክክለኛው መጠን ማዘጋጀት።',
            'ጤናማ በሆነ የዝግጅት ዘዴ ማብሰል እና ማጣፈጥ።',
            'ከጤፍ እንጀራ ጋር አቅርቦ መመገብ።',
          ]
        : [
            'Prepare ingredients according to precise portion sizes.',
            'Cook gently using healthy low-glycemic methods.',
            'Serve warm with Teff Injera.',
          ];
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(20),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              meal.foodName ?? (isAm ? 'ባህላዊ ምግብ' : 'Traditional Meal'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(label: Text('${meal.calories.toStringAsFixed(0)} kcal')),
                const SizedBox(width: 8),
                Chip(
                  label: Text(
                    isAm
                        ? 'GL ${meal.glycemicLoad.toStringAsFixed(1)} (ዝቅተኛ)'
                        : 'GL ${meal.glycemicLoad.toStringAsFixed(1)} (Low)',
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  backgroundColor: isFasting
                      ? Colors.amber
                      : Colors.green.shade700,
                  label: Text(
                    isFasting
                        ? (isAm
                              ? 'የጾም ምግብ (እጽዋታዊ)'
                              : 'Fasting Meal (Plant-Based)')
                        : (isAm ? 'የፈታ ምግብ (እንስሳዊ)' : 'Non-Fasting Meal'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              isAm
                  ? 'የክሊኒካል ማክሮዎች እና የሰውነት ማስተካከል ግብ'
                  : 'Clinical Macros & Body Recomposition Target',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A1B9A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isAm
                  ? '• ፕሮቲን: ${meal.proteinG.toStringAsFixed(1)}g (ግብ: ~30g ለእያንዳንዱ ምግብ)'
                  : '• Protein: ${meal.proteinG.toStringAsFixed(1)}g (Target: ~30g per meal for muscle retention)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              isAm
                  ? '• ካርቦሃይድሬት: ${meal.carbsG.toStringAsFixed(1)}g (ጤናማ የጤፍ ካርብ)'
                  : '• Carbohydrates: ${meal.carbsG.toStringAsFixed(1)}g (Slow-release Teff carbs)',
            ),
            Text(
              isAm
                  ? '• ስብ: ${meal.fatG.toStringAsFixed(1)}g'
                  : '• Fat: ${meal.fatG.toStringAsFixed(1)}g',
            ),
            const SizedBox(height: 16),
            Text(
              isAm
                  ? 'ትክክለኛ ግብዓቶች እና የምግብ መጠን ክፍፍል'
                  : 'Exact Ingredients & Portion Breakdown',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...ingredients.map(
              (ing) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Expanded(
                      child: Text(ing, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isAm
                  ? 'ባህላዊ የአዘገጃጀት እና የማብሰያ መመሪያዎች'
                  : 'Traditional Preparation & Cooking Instructions',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...instructions.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  '${entry.key + 1}. ${entry.value}',
                  style: const TextStyle(fontSize: 14, height: 1.3),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
