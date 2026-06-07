# Burs Eşleştirme Sistemi — Mobile

See root `AGENTS.md` for the full project guide. This file covers mobile-specific details.

## Commands

| Action | Command |
|---|---|
| Get deps | `flutter pub get` |
| Run | `flutter run` |
| Run with custom API | `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080` |
| Generate models | `dart run build_runner build --delete-conflicting-outputs` |
| Analyze | `dart analyze` |

No meaningful tests. `test/widget_test.dart` is auto-generated.

## Implementation status

| Layer | Status |
|---|---|
| Models (15 DTOs, `json_serializable`) | Written, `*.g.dart` committed |
| Services (Dio + 6 classes) | Written |
| Providers (5 Riverpod providers) | Written |
| Auth (login/register + session) | Written |
| Feature screens | Written (6 feature dirs) |
| Navigation + theme | Written |

Task files in `tasks/` document the implementation steps (already followed).

## Key conventions

- **Auth**: Bearer UUID stored in `flutter_secure_storage`, cached in `ApiClient` static field (not read per-request). Dio interceptor is synchronous.
- **API base**: Default `http://127.0.0.1:8080`. Override via `--dart-define=API_BASE_URL=...`. Android emulator uses `http://10.0.2.2:8080`.
- **State**: Riverpod (`flutter_riverpod`). 5 providers: auth, student, donor, scholarship, match.
- **Routing**: `go_router` with role-based redirects.
- **Serialization**: `json_annotation` + `json_serializable` + build_runner.
- **UI strings**: Turkish (user-facing).
