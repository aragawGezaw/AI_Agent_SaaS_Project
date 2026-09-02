/// Represents an educational resource in the Smart Nutrition & Health app.
/// Maps to the backend `educational_resources` table.
class EducationalResource {
  final String id;
  final String title;
  final String category;
  final String? summary;
  final String? contentBody;
  final String? videoUrl;
  final int? videoDurationSeconds;
  final String? thumbnailUrl;
  final String language;
  final bool isFeatured;
  final int viewCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const EducationalResource({
    required this.id,
    required this.title,
    required this.category,
    this.summary,
    this.contentBody,
    this.videoUrl,
    this.videoDurationSeconds,
    this.thumbnailUrl,
    required this.language,
    required this.isFeatured,
    required this.viewCount,
    required this.createdAt,
    this.updatedAt,
  });

  factory EducationalResource.fromJson(Map<String, dynamic> json) {
    return EducationalResource(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      summary: json['summary'] as String?,
      contentBody: json['content_body'] as String?,
      videoUrl: json['video_url'] as String?,
      videoDurationSeconds: json['video_duration_seconds'] as int?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      language: (json['language'] as String?) ?? 'en',
      isFeatured: (json['is_featured'] as bool?) ?? false,
      viewCount: (json['view_count'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Returns true if the resource has a video URL.
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  /// Returns formatted duration (MM:SS) if a video is present.
  String? get formattedDuration {
    if (videoDurationSeconds == null) return null;
    final mins = videoDurationSeconds! ~/ 60;
    final secs = videoDurationSeconds! % 60;
    return '$mins:' '${secs.toString().padLeft(2, '0')}';
  }

  /// Returns a category icon identifier used for UI rendering.
  String get categoryIcon {
    switch (category) {
      case 'nutrition':
        return 'restaurant_menu';
      case 'glycemic_index':
        return 'analytics';
      case 'fasting':
        return 'schedule';
      case 'recipes':
        return 'menu_book';
      case 'health_tips':
        return 'lightbulb';
      case 'exercise':
        return 'fitness_center';
      default:
        return 'article';
    }
  }

  /// Returns a human-readable category label key for localization.
  String get categoryLabelKey {
    return 'eduCategory_$category';
  }
}

/// Available resource categories.
class ResourceCategory {
  final String id;
  final String labelKey;
  final int count;

  const ResourceCategory({
    required this.id,
    required this.labelKey,
    this.count = 0,
  });

  factory ResourceCategory.fromJson(Map<String, dynamic> json) {
    return ResourceCategory(
      id: json['category'] as String,
      labelKey: 'eduCategory_${json['category']}',
      count: (json['count'] as int?) ?? 0,
    );
  }
}
