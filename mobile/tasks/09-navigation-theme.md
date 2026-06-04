# Task 09: Navigation, Theme, and Final Polish

## Goal
Wire up routing, apply theming, create shared widgets, and finalize.

## Steps

### 1. Create shared widgets

#### `lib/widgets/loading_widget.dart`
- Centered CircularProgressIndicator.

#### `lib/widgets/error_widget.dart`
- Error message with retry button.

#### `lib/widgets/custom_app_bar.dart`
- Consistent AppBar with role badge.

### 2. Create `lib/app.dart`
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/theme.dart';

class BursApp extends StatelessWidget {
  const BursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Burs Eşleştirme',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### 3. Routing (`lib/app.dart` or separate `lib/router.dart`)
Use `GoRouter` with these routes:
- `/login` → LoginScreen
- `/register` → RegisterScreen
- `/` → HomeScreen (redirect to login if not authenticated)
- `/students` → StudentListScreen
- `/students/:id` → StudentDetailScreen
- `/students/:id/edit` → StudentEditScreen
- `/students/:id/match` → MatchResultScreen
- `/donors` → DonorListScreen
- `/donors/:id` → DonorDetailScreen
- `/scholarships` → ScholarshipListScreen
- `/scholarships/:id` → ScholarshipDetailScreen
- `/scholarships/create` → ScholarshipCreateScreen
- `/admin/verify` → DonorVerifyScreen
- `/admin/departments` → DepartmentManageScreen

Redirect logic:
- If not authenticated → `/login`
- If authenticated but on `/login` or `/register` → `/`

### 4. Update `lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BursApp()));
}
```

### 5. Theme polish
- Ensure consistent spacing.
- Add card elevation and border radius.
- Style buttons, inputs, dropdowns.
- Add responsive padding.

## Verification
- `dart analyze` — zero errors.
- All routes work correctly.
- Auth redirect works (unauthenticated → login).
- App runs on Android emulator and iOS simulator.
- Build succeeds: `flutter build apk --debug`.
