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
  }

  Future<RegisterResponse> register(RegisterRequest request) async {
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
  }
}
