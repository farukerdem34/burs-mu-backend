import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';

  static final Map<String, String> _fallback = {};

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {
      _fallback[_tokenKey] = token;
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
    try {
      await _storage.write(key: _roleKey, value: role);
    } catch (_) {
      _fallback[_roleKey] = role;
    }
  }

  static Future<String?> getRole() async {
    try {
      return await _storage.read(key: _roleKey);
    } catch (_) {
      return _fallback[_roleKey];
    }
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
