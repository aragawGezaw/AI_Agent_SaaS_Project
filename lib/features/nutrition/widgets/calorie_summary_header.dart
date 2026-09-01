import 'package:flutter/material.dart';

/// Header card showing today's calories, total calories, total glycemic load,
/// and the number of meals in the current view.
///
/// All labels support English and Amharic (handled internally based on the
/// current [Locale]).
class CalorieSummaryHeader extends StatelessWidget {
  final int todayCalories;
  final int totalCalories;
  final double todayGL;
  final double totalGL;
  final int mealCount;

  const CalorieSummaryHeader({
    super.key,
    required this.todayCalories,
    required this.totalCalories,
    required this.todayGL,
    required this.totalGL,
    required this.mealCount,
  });

  @override
  Widget build(BuildContext context) {
    final isAm = Localizations.localeOf(context).languageCode == 'am';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                isAm ? 'ዛም ካሎሪ' : "Today's Calories",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$todayCalories kcal',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryStat(
                  label: isAm ? 'ጠቅላላ ካሎሪ' : 'Total kcal',
                  value: '$totalCalories',
                  icon: Icons.restaurant_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryStat(
                  label: isAm ? 'ጠቅላላ GL' : 'Total GL',
                  value: totalGL.toStringAsFixed(1),
                  icon: Icons.speed_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryStat(
                  label: isAm ? 'ምግቦች' : 'Meals',
                  value: '$mealCount',
                  icon: Icons.list_alt_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
