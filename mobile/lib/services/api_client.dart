import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/secure_storage.dart';

class ApiClient {
  static Dio create() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!options.path.contains('/login') &&
            !options.path.contains('/register')) {
          try {
            final token = await SecureStorage.getToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {
            // SecureStorage not available (e.g. macOS without entitlements)
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        handler.next(error);
      },
    ));

    return dio;
  }
}
