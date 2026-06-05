import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/secure_storage.dart';
import '../models/login_request.dart';
import '../models/register_request.dart';
import '../models/user_role.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

final dioProvider = Provider<Dio>((ref) => ApiClient.create());

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(dioProvider));
});

enum AuthStatus { unauthenticated, authenticated, loading }

class AuthState {
  final AuthStatus status;
  final String? token;
  final UserRole? role;
  final String? error;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.token,
    this.role,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? token,
    UserRole? role,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      token: token ?? this.token,
      role: role ?? this.role,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    final token = await SecureStorage.getToken();
    if (token != null) {
      ApiClient.setToken(token);
      final roleStr = await SecureStorage.getRole();
      state = AuthState(
        status: AuthStatus.authenticated,
        token: token,
        role: roleStr != null ? UserRole.values.firstWhere((r) => r.name == roleStr) : null,
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final response = await _authService.login(
        LoginRequest(email: email, password: password),
      );
      state = AuthState(
        status: AuthStatus.authenticated,
        token: response.id,
        role: response.role,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> register(RegisterRequest request) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final response = await _authService.register(request);
      state = AuthState(
        status: AuthStatus.authenticated,
        token: response.id,
        role: response.role,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    ApiClient.setToken(null);
    await SecureStorage.clear();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
