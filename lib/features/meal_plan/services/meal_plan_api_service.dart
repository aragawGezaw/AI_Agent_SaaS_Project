import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/meal_plan.dart';

/// Service for interacting with the AI meal planning backend endpoints
/// (`/api/agent/generate-meal-plan`, `/api/agent/meal-plans`).
class MealPlanApiService {
  final ApiClient _apiClient;

  MealPlanApiService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// Generate a new AI-powered meal plan from the backend.
  /// Hits POST /api/agent/generate-meal-plan.
  ///
  /// Returns a [MealPlanResponse] containing the list of generated meals
  /// and summary totals.
  Future<MealPlanResponse> generateMealPlan({
    String? planDate, // YYYY-MM-DD; null defaults to today (server side)
    bool isFastingDay = false,
    String language = 'am', // Added language code parameter ('am' or 'en')
  }) async {
    try {
      final body = <String, dynamic>{
        'is_fasting_day': isFastingDay,
        'language': language, // <-- Transmits active language code to backend
      };
      if (planDate != null && planDate.isNotEmpty) {
        body['plan_date'] = planDate;
      }

      final response = await _apiClient.dio.post(
        '/agent/generate-meal-plan',
        data: body,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return MealPlanResponse.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception(
        'Failed to generate meal plan: Invalid server response (${response.statusCode})',
      );
    } on DioException catch (e) {
      throw Exception(
        _extractDioMessage(
          e,
          'Failed to generate meal plan. Please try again.',
        ),
      );
    } catch (e) {
      throw Exception('Unexpected error generating meal plan: $e');
    }
  }

  /// Fetch all saved meal plans for the current user.
  /// Hits GET /api/agent/meal-plans.
  Future<List<MealPlan>> getMealPlans({
    String? startDate,
    String? endDate,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{'limit': limit};
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }

      final response = await _apiClient.dio.get(
        '/agent/meal-plans',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final list = (data['meal_plans'] as List<dynamic>? ?? [])
            .map((e) => MealPlan.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception(
        'Failed to fetch meal plans: Invalid server response (${response.statusCode})',
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e, 'Failed to fetch meal plans.'));
    } catch (e) {
      throw Exception('Unexpected error fetching meal plans: $e');
    }
  }

  /// Delete a specific meal plan entry by its numeric ID.
  /// Hits DELETE /api/agent/meal-plans/:id.
  Future<bool> deleteMealPlan(int id) async {
    try {
      final response = await _apiClient.dio.delete('/agent/meal-plans/$id');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      }
      throw Exception('Failed to delete meal plan');
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e, 'Failed to delete meal plan.'));
    } catch (e) {
      throw Exception('Unexpected error deleting meal plan: $e');
    }
  }

  /// Helper to extract a friendly message from a DioException across devices.
  String _extractDioMessage(DioException e, String fallback) {
    if (e.response?.data != null) {
      final responseData = e.response!.data;
      if (responseData is Map) {
        final msg = responseData['message'] ?? responseData['error'];
        if (msg is String && msg.isNotEmpty) return msg;
        if (msg is List && msg.isNotEmpty) return msg.join(', ');
      } else if (responseData is String && responseData.isNotEmpty) {
        return responseData;
      }
    }

    // Fallback based on Dio error type for better user context
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your network connection.';
      case DioExceptionType.connectionError:
        return 'Unable to connect to server. Please ensure your backend is running.';
      case DioExceptionType.badResponse:
        return 'Server error (${e.response?.statusCode ?? "unknown"}). Please try again later.';
      default:
        return e.message ?? fallback;
    }
  }
}

/// Wrapper around the response body of POST /api/agent/generate-meal-plan.
class MealPlanResponse {
  final bool success;
  final String message;
  final String planDate;
  final bool isFastingMeal;
  final String recommendationSource;
  final List<MealPlan> meals;
  final MealPlanSummary summary;

  const MealPlanResponse({
    required this.success,
    required this.message,
    required this.planDate,
    required this.isFastingMeal,
    required this.recommendationSource,
    required this.meals,
    required this.summary,
  });

  factory MealPlanResponse.fromJson(Map<String, dynamic> json) {
    final mealsJson = json['meals'] as List<dynamic>? ?? const [];
    return MealPlanResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String? ?? '',
      planDate: json['plan_date'] as String? ?? '',
      isFastingMeal: json['is_fasting_meal'] as bool? ?? false,
      recommendationSource:
          json['recommendation_source'] as String? ?? 'gemini_ai',
      meals: mealsJson
          .map((e) => MealPlan.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: MealPlanSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

/// Aggregated daily totals returned by the backend along with the meal list.
class MealPlanSummary {
  final double totalCalories;
  final double totalGlycemicLoad;
  final int mealCount;

  const MealPlanSummary({
    required this.totalCalories,
    required this.totalGlycemicLoad,
    required this.mealCount,
  });

  factory MealPlanSummary.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return MealPlanSummary(
      totalCalories: parseNum(json['total_calories']),
      totalGlycemicLoad: parseNum(json['total_glycemic_load']),
      mealCount: (json['meal_count'] as int?) ?? 0,
    );
  }
}
