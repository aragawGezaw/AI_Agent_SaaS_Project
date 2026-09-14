import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/dashboard_summary.dart';

/// Service to handle network integration for the Health Dashboard & Analytics.
class DashboardApiService {
  final ApiClient _apiClient;

  DashboardApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetch the rolling 7-day unified health analytics and progress metrics.
  /// Hits GET /api/analytics/summary.
  Future<DashboardSummary> getAnalyticsSummary() async {
    try {
      final response = await _apiClient.dio.get('/analytics/summary');

      if (response.statusCode == 200 && response.data != null) {
        return DashboardSummary.fromJson(response.data as Map<String, dynamic>);
      }
      throw Exception(
        'Failed to fetch dashboard analytics: Invalid response (${response.statusCode})',
      );
    } on DioException catch (e) {
      throw Exception(_extractDioMessage(e, 'Failed to fetch dashboard analytics'));
    } catch (e) {
      throw Exception('Unexpected error fetching dashboard analytics: $e');
    }
  }

  String _extractDioMessage(DioException e, String fallback) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map;
      final msg = data['message'] ?? data['error'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
    return e.message ?? fallback;
  }
}
