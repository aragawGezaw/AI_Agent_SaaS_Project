import 'package:flutter/material.dart';
import '../models/meal_plan.dart';

/// Reusable card widget that displays a single meal from an AI-generated meal plan.
class MealCard extends StatelessWidget {
  final MealPlan meal;
  final VoidCallback? onDelete;
  final bool showDeleteAction;

  const MealCard({
    super.key,
    required this.meal,
    this.onDelete,
    this.showDeleteAction = false,
  });

  IconData _mealIcon() {
    switch (meal.mealType.toLowerCase()) {
      case 'breakfast': return Icons.free_breakfast_rounded;
      case 'lunch':     return Icons.lunch_dining_rounded;
      case 'dinner':    return Icons.dinner_dining_rounded;
      case 'snack':     return Icons.cookie_rounded;
      default:          return Icons.restaurant_rounded;
    }
  }

  Color _mealColor() => Color(meal.getMealTypeColor());

  Color _glColor() {
    final gl = meal.glycemicLoad;
    if (gl <= 10.0) return const Color(0xFF2E7D32);
    if (gl <= 19.99) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  Color _glBg() {
    final gl = meal.glycemicLoad;
    if (gl <= 10.0) return const Color(0xFFE8F5E9);
    if (gl <= 19.99) return const Color(0xFFFFF3E0);
    return const Color(0xFFFFEBEE);
  }

  @override
  Widget build(BuildContext context) {
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final mealColor = _mealColor();
    final glColor = _glColor();
    final glBg = _glBg();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isAm, mealColor, glColor, glBg),
            if (meal.isFastingMeal) ..._buildFastingBadge(isAm),
            if (meal.proteinG > 0 || meal.carbsG > 0 || meal.fatG > 0) ..._buildMacros(isAm),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Private Build Helpers
  // ---------------------------------------------------------------------------

  Widget _buildHeader(bool isAm, Color mealColor, Color glColor, Color glBg) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: mealColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_mealIcon(), color: mealColor, size: 22),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(meal.getMealTypeLabel(isAm ? 'am' : 'en'), style: TextStyle(fontSize: 12, color: mealColor, fontWeight: FontWeight.w600)),
            Text('${meal.calories.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: glBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: glColor.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.bolt_rounded, size: 14, color: glColor),
          const SizedBox(width: 4),
          Text('GL ${meal.glycemicLoad.toStringAsFixed(1)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: glColor)),
        ]),
      ),
    ]);
  }

  List<Widget> _buildFastingBadge(bool isAm) => [
    const SizedBox(height: 8),
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.5)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.schedule_rounded, size: 12, color: Color(0xFFF57F17)),
        const SizedBox(width: 4),
        Text(isAm ? 'የጾም ምግብ' : 'Fasting Meal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF57F17))),
      ]),
    ),
  ];

  List<Widget> _buildMacros(bool isAm) => [
    const SizedBox(height: 10),
    const Divider(height: 1, thickness: 0.5),
    const SizedBox(height: 8),
    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      MacroChip(label: isAm ? 'ፕሮቲን' : 'Protein', value: '${meal.proteinG.toStringAsFixed(1)}g', color: const Color(0xFFD32F2F)),
      MacroChip(label: isAm ? 'ካርብስ' : 'Carbs', value: '${meal.carbsG.toStringAsFixed(1)}g', color: const Color(0xFFF57C00)),
      MacroChip(label: isAm ? 'ስብ' : 'Fat', value: '${meal.fatG.toStringAsFixed(1)}g', color: const Color(0xFF1976D2)),
    ]),
  ];
}

/// Tiny row showing a single macro nutrient label + value.
class MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const MacroChip({super.key, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
      Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF212121), fontWeight: FontWeight.w700)),
    ]);
  }
}
