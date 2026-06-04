import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../core/secure_storage.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/register_request.dart';
import '../models/register_response.dart';

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: request.toJson(),
      );
      final loginResponse = LoginResponse.fromJson(response.data!);
      if (loginResponse.id != null) {
        await SecureStorage.saveToken(loginResponse.id!);
        await SecureStorage.saveRole(loginResponse.role!.name);
      }
      return loginResponse;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiConstants.register,
        data: request.toJson(),
      );
      final registerResponse = RegisterResponse.fromJson(response.data!);
      if (registerResponse.id != null) {
        await SecureStorage.saveToken(registerResponse.id!);
        await SecureStorage.saveRole(registerResponse.role!.name);
      }
      return registerResponse;
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  String _extractError(DioException e) {
    if (e.response?.data is String) return e.response!.data as String;
    if (e.response?.data is Map) {
      final map = e.response!.data as Map;
      if (map['error'] is String) return map['error'];
      if (map['message'] is String) return map['message'];
    }
    return 'Bir hata oluştu';
  }
}
