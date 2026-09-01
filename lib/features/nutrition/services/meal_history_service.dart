import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/meal_history_item.dart';
import '../models/weekly_trend_data.dart';

class MealHistoryService {
  final ApiClient _apiClient;

  MealHistoryService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetch meal history with pagination and filtering
  Future<Map<String, dynamic>> getHistory({
    int limit = 50,
    int offset = 0,
    String? mealType,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (mealType != null && mealType.isNotEmpty) {
        queryParams['meal_type'] = mealType;
      }
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['start_date'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['end_date'] = endDate;
      }

      final response = await _apiClient.dio.get(
        '/meal-history',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final mealsJson = data['meals'] as List<dynamic>? ?? [];
        final meals = mealsJson
            .map((item) => MealHistoryItem.fromJson(item as Map<String, dynamic>))
            .toList();

        return {
          'meals': meals,
          'pagination': data['pagination'] as Map<String, dynamic>? ?? {},
        };
      }
      throw Exception('Failed to fetch meal history');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch meal history');
    } catch (e) {
      throw Exception('Unexpected error fetching meal history: $e');
    }
  }

  /// Fetch a single meal by ID
  Future<MealHistoryItem> getMealById(String id) async {
    try {
      final response = await _apiClient.dio.get('/meal-history/$id');

      if (response.statusCode == 200 && response.data != null) {
        return MealHistoryItem.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to fetch meal details');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch meal details');
    } catch (e) {
      throw Exception('Unexpected error fetching meal details: $e');
    }
  }

  /// Fetch 7-day weekly trend aggregates (calories & glycemic load)
  Future<WeeklyTrendResponse> getWeeklyTrends() async {
    try {
      final response = await _apiClient.dio.get('/meal-history/trends');

      if (response.statusCode == 200 && response.data != null) {
        return WeeklyTrendResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to fetch weekly trends');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch weekly trends');
    } catch (e) {
      throw Exception('Unexpected error fetching weekly trends: $e');
    }
  }

  /// Save a new meal entry (log a meal)
  Future<MealHistoryItem> saveMeal(Map<String, dynamic> mealData) async {
    try {
      final response = await _apiClient.dio.post(
        '/meal-history',
        data: mealData,
      );

      if (response.statusCode == 201 && response.data != null) {
        return MealHistoryItem.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to save meal');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to save meal');
    } catch (e) {
      throw Exception('Unexpected error saving meal: $e');
    }
  }

  /// Delete a meal by ID
  Future<bool> deleteMeal(String id) async {
    try {
      final response = await _apiClient.dio.delete('/meal-history/$id');

      if (response.statusCode == 200) {
        return true;
      }
      throw Exception('Failed to delete meal');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to delete meal');
    } catch (e) {
      throw Exception('Unexpected error deleting meal: $e');
    }
  }

  /// Delete all meal history for current user
  Future<bool> deleteAllMeals() async {
    try {
      final response = await _apiClient.dio.delete('/meal-history');

      if (response.statusCode == 200) {
        return true;
      }
      throw Exception('Failed to delete all meals');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to delete all meals');
    } catch (e) {
      throw Exception('Unexpected error deleting all meals: $e');
    }
  }
}