# Task 04: Auth Flow

## Goal
Implement login, register, and session management with Riverpod providers and UI screens.

## Files to Create

### `lib/providers/auth_provider.dart`
- `authTokenProvider` — StateNotifier that reads/writes SecureStorage.
- `authStateProvider` — exposes current auth state (logged in / role / loading / error).
- On app init: check SecureStorage for existing token, validate by calling GET /profiles.
- On login success: save token + role.
- On logout: clear storage, reset state.

### `lib/features/auth/login_screen.dart`
- Email + password fields.
- "Giriş Yap" button.
- Link to register screen.
- Show loading indicator during API call.
- Show error messages (SnackBar) on failure.
- On success: navigate to home screen based on role.

### `lib/features/auth/register_screen.dart`
- Email + password fields.
- Role selector (student / donor dropdown).
- If student selected: show optional city, department, income level, GPA fields.
- "Kayıt Ol" button.
- Link to login screen.
- On success: auto-login (save token), navigate to home.

### `lib/features/home/home_screen.dart`
- Role-based dashboard:
  - **Student**: "Bursları Gör" button, "Profilimi Düzenle", "Eşleşme Sonuçları".
  - **Donor**: "Burslarım" button, "Yeni Burs Oluştur".
  - **Admin**: "Tüm Öğrenciler", "Tüm Donorlar", "Donor Doğrula", "Departmanlar".
- Drawer or bottom nav with logout option.
- AppBar with user role indicator.

## Verification
- Can register a new student user.
- Can register a new donor user.
- Can login with registered credentials.
- Token persists across app restarts.
- Logout clears session.
- Role-based navigation works correctly.
