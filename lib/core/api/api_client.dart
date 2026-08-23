import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import '../storage/secure_storage_service.dart';

/// Exception thrown when an HTTP request fails with a non-2xx status code.
class HttpException extends DioException {
  HttpException(String message, [int? statusCode])
    : super(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        message: message,
        response: Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: statusCode,
        ),
      );
}

/// Exception thrown when the user is not authenticated (401).
class UnauthorizedException extends DioException {
  UnauthorizedException(String message)
    : super(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.badResponse,
        message: message,
      );
}

/// Singleton Dio client configured with base URL, interceptors, and error handling.
class ApiClient {
  static final ApiClient _instance = ApiClient._init();

  /// Get the singleton instance of ApiClient
  factory ApiClient() {
    return _instance;
  }

  static final Logger _logger = Logger('ApiClient');

  late final Dio _dio;
  final SecureStorageService _storage = SecureStorageService();

  Dio get dio => _dio;

  ApiClient._init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'http://localhost:5000/api',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(AuthInterceptor(_storage));
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
        responseBody: true,
        logPrint: (obj) => _logger.info(obj),
      ),
    );
    _dio.interceptors.add(_ErrorInterceptor());
  }
}

/// Interceptor that attaches the JWT token to every outgoing request.
class AuthInterceptor extends Interceptor {
  final SecureStorageService _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Interceptor that converts non-2xx responses into typed exceptions.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final statusCode = err.response?.statusCode;

    if (statusCode == 401) {
      // Clear stored credentials and propagate an UnauthorizedException
      final storage = SecureStorageService();
      await storage.removeToken();
      await storage.removeSession();
      handler.next(
        UnauthorizedException('Session expired. Please log in again.'),
      );
      return;
    }

    final message = _extractErrorMessage(err);
    handler.next(HttpException(message, statusCode));
  }

  String _extractErrorMessage(DioException err) {
    if (err.response?.data is Map) {
      final data = err.response!.data as Map;
      if (data['message'] is String) {
        return data['message'] as String;
      }
    }
    return err.message ?? 'An unexpected error occurred';
  }
}
