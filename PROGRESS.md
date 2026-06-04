# Burs Eşleştirme Sistemi — Progress

## Project State
- **Backend** (Rust/Axum): Complete — see `AGENTS.md` for details.
- **Mobile** (Flutter): Scaffold created, agent tasks defined.

## Current Sprint: Mobile App — Agent Task Definitions

### Completed — `mobile/` directory
| File | Description |
|---|---|
| `AGENTS.md` | Master agent guide: stack, structure, commands, auth, API routes |
| `tasks/01-core-setup.md` | Project init, dependencies, constants, theme, secure storage |
| `tasks/02-models.md` | All DTOs (15 model files) with json_serializable |
| `tasks/03-api-services.md` | Dio client + 6 service classes (auth, student, donor, scholarship, match, reference) |
| `tasks/04-auth-flow.md` | Login, register screens + Riverpod auth provider + session management |
| `tasks/05-student-feature.md` | Student list/detail/edit/match-result screens + providers |
| `tasks/06-donor-feature.md` | Donor list/detail screens + provider |
| `tasks/07-scholarship-feature.md` | Scholarship list/detail/create screens + provider |
| `tasks/08-admin-feature.md` | Donor verify + department management screens |
| `tasks/09-navigation-theme.md` | GoRouter, theme, shared widgets, app entry point |

### Next Steps (execution order)
1. `01-core-setup.md` — Add deps to pubspec.yaml, create core/ files
2. `02-models.md` — Write all model classes, run build_runner
3. `03-api-services.md` — Implement HTTP client and services
4. `04-auth-flow.md` — Auth UI + provider + session
5. `05-student-feature.md` — Student screens
6. `06-donor-feature.md` — Donor screens
7. `07-scholarship-feature.md` — Scholarship screens
8. `08-admin-feature.md` — Admin screens
9. `09-navigation-theme.md` — Routing + theme polish

## Architecture Decisions
- **State management**: Riverpod (flutter_riverpod)
- **HTTP**: Dio with Bearer token interceptor
- **Routing**: go_router
- **Token storage**: flutter_secure_storage (profile UUID, no JWT)
- **Serialization**: json_annotation + json_serializable
- **API base**: `http://10.0.2.2:8080` (Android emulator), configurable via `--dart-define`

## Key Constraints
- Auth: `Authorization: Bearer <uuid>` — no JWT, no expiry
- 3 roles: student, donor, admin — role-based UI
- Turkish UI strings, English code identifiers
- Matches schema: empty target arrays = no filter
