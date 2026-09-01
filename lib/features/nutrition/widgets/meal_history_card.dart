import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../models/meal_history_item.dart';
import 'glycemic_load_badge.dart';

/// Safely reads a macro value (protein_g / carbs_g / fat_g) from a
/// `macros` JSON map.
///
/// The server stores `macros` in a PostgreSQL `JSONB` column.  When
/// `node-postgres` serialises JSONB back to the client, numeric leaf values
/// may come back as either `num` (e.g. `12`) or `String` (e.g. `"12.5"`).
/// Casting with `as num?` would throw on the `String` form, so this helper
/// normalises both shapes to a `double`.
double _readMacro(Map<String, dynamic> macros, String key) {
  final value = macros[key];
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

/// Card representing a single meal history entry.
class MealHistoryCard extends StatelessWidget {
  final MealHistoryItem meal;
  final VoidCallback? onDelete;

  const MealHistoryCard({
    super.key,
    required this.meal,
    this.onDelete,
  });

  IconData _getMealTypeIcon() {
    switch (meal.mealType.toLowerCase()) {
      case 'breakfast': return Icons.free_breakfast_rounded;
      case 'lunch':     return Icons.lunch_dining_rounded;
      case 'dinner':    return Icons.dinner_dining_rounded;
      case 'snack':     return Icons.cookie_rounded;
      default:          return Icons.restaurant_rounded;
    }
  }

  Color _getMealTypeColor() {
    switch (meal.mealType.toLowerCase()) {
      case 'breakfast': return const Color(0xFFFB8C00);
      case 'lunch':     return const Color(0xFF2E7D32);
      case 'dinner':    return const Color(0xFF6A1B9A);
      case 'snack':     return const Color(0xFFD81B60);
      default:          return const Color(0xFF455A64);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAm = Localizations.localeOf(context).languageCode == 'am';
    final timeStr = DateFormat('MMM d, HH:mm').format(meal.loggedAt.toLocal());

    // Safely coerce macro values: PostgreSQL JSONB numeric values may be
    // returned as either `num` (JSON int) or `String` (pg DECIMAL-backed JSON).
    final protein = _readMacro(meal.macros, 'protein_g');
    final carbs   = _readMacro(meal.macros, 'carbs_g');
    final fat     = _readMacro(meal.macros, 'fat_g');

    return Dismissible(
      key: ValueKey(meal.id),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: _buildDismissBg(isAm),
      confirmDismiss: (_) async {
        if (onDelete == null) return false;
        return await _showDeleteDialog(context, isAm) ?? false;
      },
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
              _headerRow(isAm),
              const SizedBox(height: 10),
              _footerRow(isAm, timeStr, protein, carbs, fat),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerRow(bool isAm) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getMealTypeColor().withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getMealTypeIcon(),
              color: _getMealTypeColor(), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal.getMealTypeDisplay(isAm ? 'am' : 'en'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getMealTypeColor(),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                meal.foodName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF212121),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${meal.calories}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2E7D32),
                height: 1.2,
              ),
            ),
            const Text('kcal',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF757575),
                )),
          ],
        ),
      ],
    );
  }

  Widget _footerRow(bool isAm, String timeStr,
      double protein, double carbs, double fat) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.access_time_rounded,
                size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(timeStr,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                )),
            const Spacer(),
            GlycemicLoadBadge(
              glycemicLoad: meal.totalGlycemicLoad,
              isCompact: true,
            ),
          ],
        ),
        if (protein > 0 || carbs > 0 || fat > 0) ...[
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.5),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroChip(label: isAm ? 'ፕሮቲን' : 'Protein',
                  value: '${protein.toStringAsFixed(1)}g',
                  color: const Color(0xFFD32F2F)),
              _MacroChip(label: isAm ? 'ካርብስ' : 'Carbs',
                  value: '${carbs.toStringAsFixed(1)}g',
                  color: const Color(0xFFF57C00)),
              _MacroChip(label: isAm ? 'ስብ' : 'Fat',
                  value: '${fat.toStringAsFixed(1)}g',
                  color: const Color(0xFF1976D2)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDismissBg(bool isAm) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade400,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_rounded, color: Colors.white),
          const SizedBox(width: 6),
          Text(isAm ? 'ሰርዝ' : 'Delete',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context, bool isAm) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAm ? 'ምግብ ሰርዝ?' : 'Delete meal?'),
        content: Text(
          isAm
              ? 'ይህን ምግብ ከታሪክዎ ለማስወገድ እርግጠኛ ነዎት?'
              : 'Remove this meal from your history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isAm ? 'ተመለስ' : 'Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isAm ? 'ሰርዝ' : 'Delete'),
          ),
        ],
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF212121),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
