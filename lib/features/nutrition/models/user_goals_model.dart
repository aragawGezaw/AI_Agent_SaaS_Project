/// Represents the user's personalized health objectives and custom glycemic thresholds.
class UserGoals {
  final String id;
  final String userId;
  final int? dailyCalorieTarget;
  final double? dailyProteinTargetG;
  final double? dailyCarbsTargetG;
  final double? dailyFatTargetG;
  final double glycemicLoadLowThreshold;
  final double glycemicLoadMediumThreshold;
  final double? dailyGlycemicLoadLimit;
  final String preferredLanguage;
  final String goalFocus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserGoals({
    required this.id,
    required this.userId,
    this.dailyCalorieTarget,
    this.dailyProteinTargetG,
    this.dailyCarbsTargetG,
    this.dailyFatTargetG,
    required this.glycemicLoadLowThreshold,
    required this.glycemicLoadMediumThreshold,
    this.dailyGlycemicLoadLimit,
    required this.preferredLanguage,
    required this.goalFocus,
    required this.createdAt,
    required this.updatedAt,
  });

  // Safe helper to parse integers from dynamic JSON values (int, num, or String)
  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String)
      return int.tryParse(val) ?? double.tryParse(val)?.toInt();
    return null;
  }

  // Safe helper to parse doubles from dynamic JSON values (double, num, or String)
  static double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  factory UserGoals.fromJson(Map<String, dynamic> json) {
    return UserGoals(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      dailyCalorieTarget: _parseInt(json['daily_calorie_target']),
      dailyProteinTargetG: _parseDouble(json['daily_protein_target_g']),
      dailyCarbsTargetG: _parseDouble(json['daily_carbs_target_g']),
      dailyFatTargetG: _parseDouble(json['daily_fat_target_g']),
      glycemicLoadLowThreshold:
          _parseDouble(json['glycemic_load_low_threshold']) ?? 10.0,
      glycemicLoadMediumThreshold:
          _parseDouble(json['glycemic_load_medium_threshold']) ?? 19.0,
      dailyGlycemicLoadLimit: _parseDouble(json['daily_glycemic_load_limit']),
      preferredLanguage: json['preferred_language']?.toString() ?? 'en',
      goalFocus: json['goal_focus']?.toString() ?? 'maintenance',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'daily_calorie_target': dailyCalorieTarget,
      'daily_protein_target_g': dailyProteinTargetG,
      'daily_carbs_target_g': dailyCarbsTargetG,
      'daily_fat_target_g': dailyFatTargetG,
      'glycemic_load_low_threshold': glycemicLoadLowThreshold,
      'glycemic_load_medium_threshold': glycemicLoadMediumThreshold,
      'daily_glycemic_load_limit': dailyGlycemicLoadLimit,
      'preferred_language': preferredLanguage,
      'goal_focus': goalFocus,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// CopyWith method for immutable updates
  UserGoals copyWith({
    String? id,
    String? userId,
    int? dailyCalorieTarget,
    double? dailyProteinTargetG,
    double? dailyCarbsTargetG,
    double? dailyFatTargetG,
    double? glycemicLoadLowThreshold,
    double? glycemicLoadMediumThreshold,
    double? dailyGlycemicLoadLimit,
    String? preferredLanguage,
    String? goalFocus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserGoals(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      dailyProteinTargetG: dailyProteinTargetG ?? this.dailyProteinTargetG,
      dailyCarbsTargetG: dailyCarbsTargetG ?? this.dailyCarbsTargetG,
      dailyFatTargetG: dailyFatTargetG ?? this.dailyFatTargetG,
      glycemicLoadLowThreshold:
          glycemicLoadLowThreshold ?? this.glycemicLoadLowThreshold,
      glycemicLoadMediumThreshold:
          glycemicLoadMediumThreshold ?? this.glycemicLoadMediumThreshold,
      dailyGlycemicLoadLimit:
          dailyGlycemicLoadLimit ?? this.dailyGlycemicLoadLimit,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      goalFocus: goalFocus ?? this.goalFocus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Represents thresholds used for Glycemic Load classification
class GLThresholds {
  final double lowThreshold;
  final double mediumThreshold;

  const GLThresholds({
    required this.lowThreshold,
    required this.mediumThreshold,
  });

  factory GLThresholds.fromUserGoals(UserGoals goals) {
    return GLThresholds(
      lowThreshold: goals.glycemicLoadLowThreshold,
      mediumThreshold: goals.glycemicLoadMediumThreshold,
    );
  }

  /// Returns GL classification based on these thresholds
  String classifyGL(double glValue) {
    if (glValue <= lowThreshold) return 'low';
    if (glValue <= mediumThreshold) return 'medium';
    return 'high';
  }
}
