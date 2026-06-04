# Task 03: API Services

## Goal
Create Dio HTTP client with Bearer interceptor and all service classes.

## Files to Create

### `lib/services/api_client.dart`
- Create a Dio instance with base URL from `ApiConstants.baseUrl`.
- Add an interceptor that reads the token from `SecureStorage` and sets `Authorization: Bearer <token>` on every request (unless the endpoint is login/register).
- Handle 401 responses by clearing secure storage.
- Configure timeouts (connect: 10s, receive: 30s).
- Add JSON content type header.

### `lib/services/auth_service.dart`
```dart
class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<LoginResponse> login(LoginRequest request) async { ... }
  Future<RegisterResponse> register(RegisterRequest request) async { ... }
  
  // On success: save token + role to SecureStorage, update Dio headers.
  // On failure: throw typed exception.
}
```

### `lib/services/student_service.dart`
Methods:
- `Future<List<Student>> getAll()`
- `Future<Student> getById(String profileId)`
- `Future<Student> create(CreateStudentRequest request)`
- `Future<Student> update(String profileId, UpdateStudentRequest request)`

### `lib/services/donor_service.dart`
Methods:
- `Future<List<Donor>> getAll()`
- `Future<Donor> getById(String profileId)`
- `Future<Donor> verify(String profileId)` — Admin only, requires auth

### `lib/services/scholarship_service.dart`
Methods:
- `Future<List<Scholarship>> getAll()`
- `Future<Scholarship> getById(String id)`
- `Future<Scholarship> create(CreateScholarshipRequest request)` — requires auth

### `lib/services/match_service.dart`
Methods:
- `Future<List<MatchResult>> matchStudent(String studentId)`

### `lib/services/reference_service.dart`
Methods:
- `Future<List<NamedItem>> getCities()`
- `Future<List<NamedItem>> getDepartments()`
- `Future<List<NamedItem>> getIncomeLevels()`
- `Future<List<NamedItem>> getUserRoles()`

## Verification
- `dart analyze` — zero errors.
- All services can be instantiated (test manually or write smoke test).
