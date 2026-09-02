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

  factory UserGoals.fromJson(Map<String, dynamic> json) {
    return UserGoals(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      dailyCalorieTarget: json['daily_calorie_target'] as int?,
      dailyProteinTargetG: (json['daily_protein_target_g'] as num?)?.toDouble(),
      dailyCarbsTargetG: (json['daily_carbs_target_g'] as num?)?.toDouble(),
      dailyFatTargetG: (json['daily_fat_target_g'] as num?)?.toDouble(),
      glycemicLoadLowThreshold: (json['glycemic_load_low_threshold'] as num?)?.toDouble() ?? 10.0,
      glycemicLoadMediumThreshold: (json['glycemic_load_medium_threshold'] as num?)?.toDouble() ?? 19.0,
      dailyGlycemicLoadLimit: (json['daily_glycemic_load_limit'] as num?)?.toDouble(),
      preferredLanguage: json['preferred_language'] as String,
      goalFocus: json['goal_focus'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
      glycemicLoadLowThreshold: glycemicLoadLowThreshold ?? this.glycemicLoadLowThreshold,
      glycemicLoadMediumThreshold: glycemicLoadMediumThreshold ?? this.glycemicLoadMediumThreshold,
      dailyGlycemicLoadLimit: dailyGlycemicLoadLimit ?? this.dailyGlycemicLoadLimit,
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