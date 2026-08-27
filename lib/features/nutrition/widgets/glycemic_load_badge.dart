import 'package:flutter/material.dart';

class GlycemicLoadBadge extends StatelessWidget {
  final double glycemicLoad;
  final String? glClass;
  final bool isCompact;

  const GlycemicLoadBadge({
    super.key,
    required this.glycemicLoad,
    this.glClass,
    this.isCompact = false,
  });

  Color _getBadgeColor() {
    if (glycemicLoad <= 10.0) {
      return const Color(0xFF2E7D32); // Green
    } else if (glycemicLoad <= 19.99) {
      return const Color(0xFFE65100); // Orange
    } else {
      return const Color(0xFFC62828); // Red
    }
  }

  Color _getBadgeBackgroundColor() {
    if (glycemicLoad <= 10.0) {
      return const Color(0xFFE8F5E9); // Light Green
    } else if (glycemicLoad <= 19.99) {
      return const Color(0xFFFFF3E0); // Light Orange
    } else {
      return const Color(0xFFFFEBEE); // Light Red
    }
  }

  String _getGlLabel(String langCode) {
    if (langCode == 'am') {
      if (glycemicLoad <= 10.0) return 'ዝቅተኛ GL (Low)';
      if (glycemicLoad <= 19.99) return 'መካከለኛ GL (Med)';
      return 'ከፍተኛ GL (High)';
    } else {
      if (glycemicLoad <= 10.0) return 'Low GL';
      if (glycemicLoad <= 19.99) return 'Medium GL';
      return 'High GL';
    }
  }

  @override
  Widget build(BuildContext context) {
    final langCode = Localizations.localeOf(context).languageCode;
    final primaryColor = _getBadgeColor();
    final bgColor = _getBadgeBackgroundColor();

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed_rounded, size: 14, color: primaryColor),
            const SizedBox(width: 4),
            Text(
              'GL ${glycemicLoad.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryColor,
                height: 1.3,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Glycemic Load: ${glycemicLoad.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: primaryColor,
                  letterSpacing: -0.2,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _getGlLabel(langCode),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor.withValues(alpha: 0.85),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
