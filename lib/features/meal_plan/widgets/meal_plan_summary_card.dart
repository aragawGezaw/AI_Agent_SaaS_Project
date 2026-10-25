import 'package:flutter/material.dart';
import '../services/meal_plan_api_service.dart';

class MealPlanSummaryCard extends StatelessWidget {
  final MealPlanResponse plan;

  const MealPlanSummaryCard({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final isAm = Localizations.localeOf(context).languageCode == 'am';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D32),
                size: 20,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isAm ? 'የዛሬው እቅድ' : 'Latest Plan',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (plan.isFastingMeal) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFFFB300)),
                  ),
                  child: Text(
                    isAm ? 'የጾም' : 'Fasting',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF57F17),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _summaryItem(
                  isAm ? 'ካሎሪ' : 'Calories',
                  plan.summary.totalCalories.toStringAsFixed(0),
                  'kcal',
                  const Color(0xFFF57C00),
                ),
              ),
              Expanded(
                child: _summaryItem(
                  isAm ? 'ግላይሴሚክ ሸክላ' : 'Glycemic Load',
                  plan.summary.totalGlycemicLoad.toStringAsFixed(1),
                  'GL',
                  const Color(0xFF2E7D32),
                ),
              ),
              Expanded(
                child: _summaryItem(
                  isAm ? 'ምግቦች' : 'Meals',
                  plan.summary.mealCount.toString(),
                  '',
                  const Color(0xFF1976D2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, String unit, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          unit.isNotEmpty ? '$value $unit' : value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
