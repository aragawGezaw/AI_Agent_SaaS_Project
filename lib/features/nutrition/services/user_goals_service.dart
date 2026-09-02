import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/user_goals_model.dart';

/// Service for fetching and updating user-specific health goals and thresholds.
class UserGoalsService {
  final ApiClient _apiClient;

  UserGoalsService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetch the current user's personalized goals.
  /// Creates a default entry if none exists (backend auto-creates).
  Future<UserGoals> getUserGoals() async {
    try {
      final response = await _apiClient.dio.get('/user/goals');

      if (response.statusCode == 200 && response.data != null) {
        return UserGoals.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to fetch user goals: Invalid server response');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch user goals');
    } catch (e) {
      throw Exception('Unexpected error fetching user goals: $e');
    }
  }

  /// Update the current user's goals. Performs a partial update (upsert).
  /// Only fields provided will be updated; omitted fields retain their existing values.
  Future<UserGoals> updateUserGoals(Map<String, dynamic> updates) async {
    try {
      final response = await _apiClient.dio.put(
        '/user/goals',
        data: updates,
      );

      if (response.statusCode == 200 && response.data != null) {
        return UserGoals.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception('Failed to update user goals: Invalid server response');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to update user goals');
    } catch (e) {
      throw Exception('Unexpected error updating user goals: $e');
    }
  }
}