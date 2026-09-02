import 'package:flutter/material.dart';

/// Represents daily aggregated totals for a single day in the 7-day window.
class DailyTrend {
  final String day; // "YYYY-MM-DD"
  final int totalCalories;
  final double totalGlycemicLoad;

  const DailyTrend({
    required this.day,
    required this.totalCalories,
    required this.totalGlycemicLoad,
  });

  factory DailyTrend.fromJson(Map<String, dynamic> json) {
    String dayVal = json['day'] as String? ?? '';
    if (dayVal.contains('T')) {
      dayVal = dayVal.split('T').first;
    }
    return DailyTrend(
      day: dayVal,
      totalCalories: (json['total_calories'] as num?)?.toInt() ?? 0,
      totalGlycemicLoad:
          (json['total_glycemic_load'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'total_calories': totalCalories,
      'total_glycemic_load': totalGlycemicLoad,
    };
  }
}

/// Response container for the weekly trends endpoint.
class WeeklyTrendResponse {
  final List<DailyTrend> trends;

  const WeeklyTrendResponse({required this.trends});

  factory WeeklyTrendResponse.fromJson(Map<String, dynamic> json) {
    final trendsJson = json['trends'] as List<dynamic>? ?? [];
    return WeeklyTrendResponse(
      trends: trendsJson
          .map((item) => DailyTrend.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Threshold constants used for colour-coding the bar chart.
enum TrendThreshold { low, medium, high }

TrendThreshold classifyGL(double gl) {
  if (gl <= 10) return TrendThreshold.low;
  if (gl <= 20) return TrendThreshold.medium;
  return TrendThreshold.high;
}

Color glThresholdColor(TrendThreshold threshold) {
  switch (threshold) {
    case TrendThreshold.low:
      return const Color(0xFF2E7D32); // Green
    case TrendThreshold.medium:
      return const Color(0xFFE65100); // Orange
    case TrendThreshold.high:
      return const Color(0xFFC62828); // Red
  }
}

/// Classify GL using user-specific thresholds from UserGoals
/// Falls back to defaults (low <= 10, medium <= 19) if goals is null.
TrendThreshold classifyGLWithThresholds(double gl, dynamic userGoals) {
  if (userGoals != null) {
    final lowThreshold = userGoals.glycemicLoadLowThreshold ?? 10.0;
    final mediumThreshold = userGoals.glycemicLoadMediumThreshold ?? 19.0;
    if (gl <= lowThreshold) return TrendThreshold.low;
    if (gl <= mediumThreshold) return TrendThreshold.medium;
    return TrendThreshold.high;
  }
  return classifyGL(gl);
}
