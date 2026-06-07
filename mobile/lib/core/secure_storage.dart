import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_config.dart';

class SecureStorage {
  static final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';
  static const _apiConfigKey = 'api_config';

  static final Map<String, String> _fallback = {};

  static Future<void> saveToken(String token) async {
    _fallback[_tokenKey] = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      // fallback already written
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return _fallback[_tokenKey];
    }
  }

  static Future<void> saveRole(String role) async {
    _fallback[_roleKey] = role;
    try {
      await _storage.write(key: _roleKey, value: role);
    } catch (_) {
      // fallback already written
    }
  }

  static Future<String?> getRole() async {
    try {
      return await _storage.read(key: _roleKey);
    } catch (_) {
      return _fallback[_roleKey];
    }
  }

  static Future<void> saveApiConfig(ApiConfig config) async {
    final data = config.encode();
    try {
      await _storage.write(key: _apiConfigKey, value: data);
    } catch (_) {}
  }

  static Future<ApiConfig?> getApiConfig() async {
    try {
      final data = await _storage.read(key: _apiConfigKey);
      if (data != null) return ApiConfig.decode(data);
    } catch (_) {}
    return null;
  }

  static Future<void> clear() async {
    try {
      await _storage.deleteAll();
    } catch (_) {
      _fallback.clear();
    }
    _fallback.clear();
  }
}
