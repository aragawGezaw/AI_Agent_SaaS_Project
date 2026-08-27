import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/food_item.dart';
import '../models/meal_analysis.dart';

class FoodApiService {
  final ApiClient _apiClient;

  FoodApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Search foods by name or Amharic characters
  Future<List<FoodItem>> searchFoods(
    String query, {
    String lang = 'en',
    String? source,
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final queryParams = <String, dynamic>{
        'q': query.trim(),
        'lang': lang,
        'limit': limit,
      };
      if (source != null) {
        queryParams['source'] = source;
      }

      final response = await _apiClient.dio.get(
        '/foods/search',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        return results
            .map((item) => FoodItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to search foods');
    } catch (e) {
      throw Exception('Unexpected error searching foods: $e');
    }
  }

  /// Analyze a composite meal and compute Glycemic Load and total macros
  Future<MealAnalysis> analyzeMeal(List<Map<String, dynamic>> items) async {
    if (items.isEmpty) {
      throw ArgumentError('Items list cannot be empty');
    }

    try {
      final response = await _apiClient.dio.post(
        '/nutrition/analyze-meal',
        data: {'items': items},
      );

      if (response.statusCode == 200 && response.data != null) {
        return MealAnalysis.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to analyze meal: Invalid server response');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to analyze meal');
    } catch (e) {
      throw Exception('Unexpected error analyzing meal: $e');
    }
  }
}
