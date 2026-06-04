# Burs Eşleştirme Sistemi — Mobile Agent Guide

## Stack
- **Flutter** (Dart SDK ^3.12.1)
- State management: **Riverpod** (flutter_riverpod)
- HTTP client: **dio**
- Routing: **go_router**
- Secure storage: **flutter_secure_storage**
- Serialization: **json_annotation** + **json_serializable**

## Structure
```
lib/
├── main.dart                    # Entry point, ProviderScope
├── app.dart                     # MaterialApp.router, theme
├── core/
│   ├── constants.dart           # API base URL, endpoint paths
│   ├── theme.dart               # App theme, colors, text styles
│   └── secure_storage.dart      # Token (profile UUID) management
├── models/                      # All DTOs (json_serializable)
│   ├── user_role.dart
│   ├── income_level.dart
│   ├── profile.dart
│   ├── student.dart
│   ├── donor.dart
│   ├── scholarship.dart
│   ├── match_result.dart
│   ├── named_item.dart
│   ├── login_request.dart
│   ├── login_response.dart
│   ├── register_request.dart
│   ├── register_response.dart
│   ├── create_student_request.dart
│   ├── update_student_request.dart
│   └── create_scholarship_request.dart
├── services/
│   ├── api_client.dart          # Dio instance, Bearer interceptor
│   ├── auth_service.dart        # login, register, getCurrentProfile
│   ├── student_service.dart     # CRUD students
│   ├── donor_service.dart       # list, getById
│   ├── scholarship_service.dart # CRUD scholarships
│   ├── match_service.dart       # POST /match/{student_id}
│   └── reference_service.dart   # cities, departments, income levels, roles
├── providers/
│   ├── auth_provider.dart
│   ├── student_provider.dart
│   ├── donor_provider.dart
│   ├── scholarship_provider.dart
│   └── match_provider.dart
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart         # Role-based dashboard
│   ├── student/
│   │   ├── student_list_screen.dart
│   │   ├── student_detail_screen.dart
│   │   ├── student_edit_screen.dart
│   │   └── match_result_screen.dart
│   ├── donor/
│   │   ├── donor_list_screen.dart
│   │   └── donor_detail_screen.dart
│   ├── scholarship/
│   │   ├── scholarship_list_screen.dart
│   │   ├── scholarship_detail_screen.dart
│   │   └── scholarship_create_screen.dart
│   └── admin/
│       ├── donor_verify_screen.dart
│       └── department_manage_screen.dart
└── widgets/
    ├── loading_widget.dart
    ├── error_widget.dart
    └── custom_app_bar.dart
```

## Commands
| Action | Command (in `mobile/`) |
|---|---|
| Get dependencies | `flutter pub get` |
| Run app | `flutter run` |
| Build APK | `flutter build apk` |
| Run tests | `flutter test` |
| Generate models | `dart run build_runner build --delete-conflicting-outputs` |
| Analyze | `dart analyze` |

## Auth (critical — matches backend)
- **No JWT.** `Authorization: Bearer <uuid>` where `<uuid>` is the profile UUID returned by `POST /login` or `POST /register`.
- Store the UUID in `flutter_secure_storage` after login/register.
- On app start, check secure storage for existing token; if found, set it as the default Bearer header.
- Logout = delete from secure storage + clear Dio headers.

## API Base URL
- Default: `http://10.0.2.2:8080` (Android emulator → host)
- iOS simulator: `http://localhost:8080`
- Physical device: use your machine's local IP
- Store in `core/constants.dart` as configurable.

## API Routes Summary
| Method | Path | Auth? |
|---|---|---|
| POST | `/register` | No |
| POST | `/login` | No |
| POST | `/match/:student_id` | No |
| GET | `/profiles` | No |
| GET | `/profiles/:id` | No |
| POST | `/students` | Yes |
| GET | `/students` | No |
| PUT | `/students/:profile_id` | Yes |
| GET | `/students/:profile_id` | No |
| GET | `/donors` | No |
| GET | `/donors/:profile_id` | No |
| POST | `/donors/:profile_id/verify` | Yes (Admin) |
| POST | `/scholarships` | Yes |
| GET | `/scholarships` | No |
| GET | `/scholarships/:id` | No |
| GET | `/cities` | No |
| GET | `/departments` | No |
| DELETE | `/departments/:name` | Yes (Admin) |
| GET | `/income-levels` | No |
| GET | `/user-roles` | No |

## Key Conventions
- All API models use `json_serializable` (`@JsonSerializable` + `@JsonKey`).
- Enums (`UserRole`, `IncomeLevel`) use `@JsonEnum(valueField:)` or manual `fromJson`/`toJson`.
- All service methods return `Future<ApiResponse<T>>` where `ApiResponse` wraps success/data/error.
- Turkish strings for user-facing UI, English for code identifiers.
- Error handling: Dio exceptions caught in services, rethrown as typed app exceptions.
- Match results displayed as a scored list (highest first).
- Empty target arrays (`[]`) in scholarships = no filter (all pass).
