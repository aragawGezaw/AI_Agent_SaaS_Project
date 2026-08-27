import 'package:flutter/material.dart';
import '../models/meal_analysis.dart';
import 'glycemic_load_badge.dart';

class NutritionSummaryCard extends StatelessWidget {
  final MealAnalysis analysis;

  const NutritionSummaryCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final totals = analysis.totals;
    final eval = analysis.evaluationNote;

    final totalMacroG = (totals.proteinG + totals.carbsG + totals.fatG).clamp(1.0, 500.0);
    final proteinFraction = (totals.proteinG / totalMacroG).clamp(0.0, 1.0);
    final carbsFraction = (totals.carbsG / totalMacroG).clamp(0.0, 1.0);
    final fatFraction = (totals.fatG / totalMacroG).clamp(0.0, 1.0);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    langCode == 'am' ? 'የምግብ ንጥረ ነገር ማጠቃለያ' : 'Meal Summary',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
                  ),
                ),
                GlycemicLoadBadge(glycemicLoad: analysis.totalGlycemicLoad),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroItem(
                  langCode == 'am' ? 'ካሎሪ' : 'Calories',
                  '${totals.calories.toStringAsFixed(0)} kcal',
                  Colors.amber.shade800,
                ),
                _buildMacroItem(
                  langCode == 'am' ? 'ፕሮቲን' : 'Protein',
                  '${totals.proteinG.toStringAsFixed(1)}g',
                  Colors.blue.shade700,
                ),
                _buildMacroItem(
                  langCode == 'am' ? 'ካርቦሃይድሬት' : 'Carbs',
                  '${totals.carbsG.toStringAsFixed(1)}g',
                  Colors.green.shade700,
                ),
                _buildMacroItem(
                  langCode == 'am' ? 'ስብ' : 'Fat',
                  '${totals.fatG.toStringAsFixed(1)}g',
                  Colors.purple.shade700,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  langCode == 'am' ? 'የማክሮ ንጥረ ነገሮች ምጣኔ' : 'Macros Ratio',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                ),
                Text(
                  'Net Carbs: ${totals.netCarbsG.toStringAsFixed(1)}g',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 10,
                child: Row(
                  children: [
                    Expanded(
                      flex: (proteinFraction * 100).round().clamp(1, 100),
                      child: Container(color: Colors.blue.shade700),
                    ),
                    Expanded(
                      flex: (carbsFraction * 100).round().clamp(1, 100),
                      child: Container(color: Colors.green.shade700),
                    ),
                    Expanded(
                      flex: (fatFraction * 100).round().clamp(1, 100),
                      child: Container(color: Colors.purple.shade700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.psychology_rounded, color: Colors.blue.shade800, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          langCode == 'am' ? 'የ AI ግምገማ እና ምክር' : 'AI Evaluation',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue.shade900, height: 1.4),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          eval.recommendation,
                          style: TextStyle(fontSize: 13, color: Colors.blue.shade900, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

