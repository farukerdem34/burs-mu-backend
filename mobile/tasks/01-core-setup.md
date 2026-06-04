# Task 01: Core Setup

## Goal
Initialize the Flutter project structure, add dependencies, create core utilities.

## Steps

### 1. Add dependencies to `pubspec.yaml`
Add these under `dependencies:`:
- `dio: ^5.4.0`
- `flutter_riverpod: ^2.5.0`
- `go_router: ^14.0.0`
- `flutter_secure_storage: ^9.2.0`
- `json_annotation: ^4.9.0`

Add these under `dev_dependencies:`:
- `json_serializable: ^6.8.0`
- `build_runner: ^2.4.0`

Run `flutter pub get`.

### 2. Create directory structure
Create all directories under `lib/`:
```
lib/core/
lib/models/
lib/services/
lib/providers/
lib/features/auth/
lib/features/home/
lib/features/student/
lib/features/donor/
lib/features/scholarship/
lib/features/admin/
lib/widgets/
```

### 3. Create `lib/core/constants.dart`
```dart
class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  // Auth
  static const String login = '/login';
  static const String register = '/register';

  // Students
  static const String students = '/students';

  // Profiles
  static const String profiles = '/profiles';

  // Donors
  static const String donors = '/donors';

  // Scholarships
  static const String scholarships = '/scholarships';

  // Match
  static const String match = '/match';

  // References
  static const String cities = '/cities';
  static const String departments = '/departments';
  static const String incomeLevels = '/income-levels';
  static const String userRoles = '/user-roles';
}
```

### 4. Create `lib/core/theme.dart`
Define a Material 3 theme with:
- Primary color: deep purple or teal (burs/money theme)
- Card themes with elevation
- Consistent text theme
- Input decoration theme
- Elevated button theme

### 5. Create `lib/core/secure_storage.dart`
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _roleKey = 'user_role';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> saveRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  static Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
```

## Verification
- Run `dart analyze` — zero errors.
- Run `flutter pub get` succeeds.
- Project structure matches the AGENTS.md specification.
