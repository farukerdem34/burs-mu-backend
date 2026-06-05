# Burs Eşleştirme Sistemi — Agent Guide

## Stack
- **Backend**: Rust 2021, Axum 0.7, sqlx 0.8 (PostgreSQL via Supabase)
- **Mobile**: Flutter (Dart ^3.12.1), Riverpod, Dio, go_router, json_serializable, flutter_secure_storage
- Skills: `supabase`, `supabase-postgres-best-practices` (`backend/.agents/skills/`)

## Structure
```
├── backend/              # Rust API (complete)
│   ├── src/
│   │   ├── main.rs       # TcpListener, bg matching spawn
│   │   ├── lib.rs        # build_router() — all routes, CorsLayer
│   │   ├── auth.rs       # AuthUser extractor (Bearer <uuid>)
│   │   ├── config.rs     # AppConfig::from_env()
│   │   ├── state.rs      # AppState { PgPool, AppConfig }
│   │   ├── models.rs     # Student, Donor, Profile, Scholarship + request/response types
│   │   ├── engine.rs     # calculate_match_score()
│   │   ├── handlers.rs   # All route handlers
│   │   └── matching.rs   # Background matching: run_matching(), start_matching_scheduler()
│   ├── migrations/001.sql
│   ├── openapi.yaml      # Swagger/OpenAPI spec
│   ├── docker-compose.yml # Swagger UI (localhost:8081)
│   └── Cargo.toml
├── mobile/               # Flutter app (scaffold + tasks)
│   ├── lib/
│   │   ├── main.dart + app.dart
│   │   ├── core/         # constants, theme, secure_storage
│   │   ├── models/       # 15 DTOs (json_serializable, .g.dart committed)
│   │   ├── services/     # Dio + 6 service classes
│   │   ├── providers/    # 5 Riverpod providers
│   │   ├── features/     # auth, home, student, donor, scholarship, admin
│   │   └── widgets/      # 3 shared widgets
│   ├── tasks/            # 9 task files (implementation steps)
│   ├── AGENTS.md         # Mobile-specific guide
│   └── KNOWN_BUGS.md
├── PROGRESS.md
└── .opencode/skills/burs-eşleştirme-sistemi-api/
```

## Commands

| Action | Where | Command |
|---|---|---|
| Run server | `backend/` | `cargo run` |
| Build | `backend/` | `cargo build` |
| Apply migration | root | `psql "$DATABASE_URL" -f backend/migrations/001.sql` |
| Swagger UI | root | `docker compose up` → http://localhost:8081 |
| Get deps | `mobile/` | `flutter pub get` |
| Run app | `mobile/` | `flutter run` |
| Generate models | `mobile/` | `dart run build_runner build --delete-conflicting-outputs` |
| Analyze | `mobile/` | `dart analyze` |

No test suite exists yet (no `tests/` directory in `backend/`, no `test/` files written in `mobile/`).

## Auth (non-standard)
- **No JWT.** `Authorization: Bearer <uuid>` where `<uuid>` is the profile UUID from `POST /login` or `POST /register`.
- Login checks `auth.users` via `crypt()`, returns `{ id, role }`.
- `AuthUser` extractor (`auth.rs:20`) parses Bearer token as UUID, verifies it in `profiles` table. No signature, expiry, or refresh.
- Register creates user in `auth.users` with `crypt()/gen_salt('bf')`, profile, and optionally student/donor record.
- Mobile stores UUID in `flutter_secure_storage`; logout = delete + clear Dio headers.

## API routes

| Method | Path | Auth |
|---|---|---|
| POST | `/register` | No |
| POST | `/login` | No |
| POST | `/match/:student_id` | Admin |
| POST | `/match/run` | Admin |
| POST | `/profiles` | No |
| GET | `/profiles` | Admin |
| GET | `/profiles/:id` | No |
| POST | `/students` | Yes (owner or admin) |
| GET | `/students` | Admin |
| GET | `/students/:profile_id` | No |
| PUT | `/students/:profile_id` | Yes (owner or admin) |
| GET | `/students/:profile_id/matches` | Yes (owner or admin) |
| GET | `/donors` | Admin |
| GET | `/donors/:profile_id` | No |
| POST | `/donors/:profile_id/verify` | Admin |
| POST | `/scholarships` | Admin |
| GET | `/scholarships` | No |
| GET | `/scholarships/:id` | No |
| POST | `/departments` | Admin |
| GET | `/departments` | No |
| DELETE | `/departments/:name` | Admin |
| GET | `/cities` | No |
| GET | `/income-levels` | No |
| GET | `/user-roles` | No |

## Key conventions & gotchas
- **CORS**: `CorsLayer::permissive()` — wide open.
- **Connection pool**: 1-5 connections, `test_before_acquire(false)`.
- **GPA**: stored as `NUMERIC(3,2)`, cast via `::float4` in all queries. `target_*` arrays default to `'{}'`, not NULL.
- **Empty target arrays** (`[]`) = no filter (all pass), checked after `Option.is_some()`.
- **New departments** auto-inserted (`ON CONFLICT DO NOTHING`) when creating students or scholarships. Fuzzy matching via `strsim::normalized_levenshtein` (threshold > 0.8).
- `CreateScholarshipRequest` fetches back by `title` (not returned ID) — fragile with duplicate titles.
- `delete_department` uses manual transaction: removes from scholarship arrays, deletes students, then deletes department.
- **Background matching**: `matching.rs:125` runs every `MATCHING_INTERVAL_MINUTES` (default 30), spawned in `main.rs:15`.
- **Score weights** from env: `WEIGHT_DEMO` (0.30), `WEIGHT_ACADEMIC` (0.30), `WEIGHT_NEED` (0.25), `WEIGHT_EXTRA` (0.15). Normalized to sum 1.0.
- **`.env.example` is stale** — omits `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and uses wrong weight names (`WEIGHT_CITY` etc.). Actual required vars per `config.rs`: `DATABASE_URL`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`.
- **Error strings**: Turkish for user-facing, English for technical errors.
- **Mobile API base**: default `http://127.0.0.1:8080`, overridable via `--dart-define=API_BASE_URL=...`.
- **Mobile KNOWN_BUGS.md**: admin account gets 401 everywhere.
- **Implementation status**: Backend complete. Mobile scaffolded with all 9 task files in `mobile/tasks/`; feature screens, models, services, providers, and widgets are written.
