import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../models/educational_resource.dart';

/// Service for interacting with the educational resources backend.
class EducationApiService {
  final ApiClient _apiClient;

  EducationApiService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  /// Fetches the list of educational resources with optional filtering.
  /// Supports filtering by category, language, and pagination.
  Future<ResourceListResult> getResources({
    String? category,
    String? language,
    bool? featured,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (language != null && language.isNotEmpty) {
        queryParams['language'] = language;
      }
      if (featured == true) {
        queryParams['featured'] = 'true';
      }

      final response = await _apiClient.dio.get(
        '/resources',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final list = (data['data'] as List<dynamic>)
            .map((e) => EducationalResource.fromJson(e as Map<String, dynamic>))
            .toList();
        final pagination = data['pagination'] as Map<String, dynamic>?;
        return ResourceListResult(
          resources: list,
          total: (pagination?['total'] as int?) ?? list.length,
          hasMore: (pagination?['hasMore'] as bool?) ?? false,
        );
      }
      throw Exception('Failed to fetch resources: Invalid server response');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch resources');
    } catch (e) {
      throw Exception('Unexpected error fetching resources: $e');
    }
  }

  /// Fetches the list of available categories with their resource counts.
  Future<List<ResourceCategory>> getCategories() async {
    try {
      final response = await _apiClient.dio.get('/resources/categories');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final list = (data['categories'] as List<dynamic>)
            .map((e) => ResourceCategory.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception('Failed to fetch categories');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to fetch categories');
    } catch (e) {
      throw Exception('Unexpected error fetching categories: $e');
    }
  }

  /// Fetches a single educational resource by its ID.
  Future<EducationalResource> getResourceById(String id) async {
    try {
      final response = await _apiClient.dio.get('/resources/$id');

      if (response.statusCode == 200 && response.data != null) {
        return EducationalResource.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to fetch resource: Invalid server response');
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Resource not found');
      }
      throw Exception(e.message ?? 'Failed to fetch resource');
    } catch (e) {
      throw Exception('Unexpected error fetching resource: $e');
    }
  }

  /// Searches for resources by a term.
  Future<List<EducationalResource>> searchResources(
    String term, {
    String? language,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (language != null && language.isNotEmpty) {
        queryParams['language'] = language;
      }

      final response = await _apiClient.dio.get(
        '/resources/search/$term',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final list = (data['data'] as List<dynamic>)
            .map((e) => EducationalResource.fromJson(e as Map<String, dynamic>))
            .toList();
        return list;
      }
      throw Exception('Search failed: Invalid server response');
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Search failed');
    } catch (e) {
      throw Exception('Unexpected error during search: $e');
    }
  }
}

/// Wrapper for paginated resource lists.
class ResourceListResult {
  final List<EducationalResource> resources;
  final int total;
  final bool hasMore;

  const ResourceListResult({
    required this.resources,
    required this.total,
    required this.hasMore,
  });
}
