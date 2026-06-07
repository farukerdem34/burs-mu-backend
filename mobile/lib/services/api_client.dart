import 'package:dio/dio.dart';
import '../core/api_config.dart';
import '../core/constants.dart';

class ApiClient {
  static String? _token;

  static String? _customBaseUrl;

  static String get baseUrl => _customBaseUrl ?? AppConfig.baseUrl;

  static void setToken(String? token) {
    _token = token;
  }

  static void setBaseUrl(ApiConfig config) {
    _customBaseUrl = config.baseUrl;
  }

  static void resetBaseUrl() {
    _customBaseUrl = null;
  }

  static Dio create() {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
    ));

    return dio;
  }

  static void updateDioBaseUrl(Dio dio, ApiConfig config) {
    final url = config.baseUrl;
    dio.options.baseUrl = url;
    _customBaseUrl = url;
  }
}
