# Burs Eşleştirme Sistemi — Agent Guide

## Stack
- **Rust** (edition 2021, not 2024) + **Axum 0.7** + **sqlx 0.8** (PostgreSQL)
- **Supabase** for Postgres + `auth.users` table
- Skills: `supabase`, `supabase-postgres-best-practices` (`backend/.agents/skills/`)

## Structure
```
backend/          # All Rust code
  src/
    main.rs       # Entrypoint, router, TcpListener
    auth.rs       # AuthUser extractor: reads Authorization: Bearer <uuid>, looks up profiles table
    config.rs     # AppConfig::from_env() — panics if DATABASE_URL, SUPABASE_URL, or SUPABASE_ANON_KEY missing
    state.rs      # AppState { db_pool: PgPool, config: AppConfig }
    models.rs     # Student, Donor, Profile, Scholarship, ScholarshipRule + request/response types
    engine.rs     # calculate_match_score() — elimination then weighted scoring
    handlers.rs   # All route handlers (~920 lines)
  migrations/001.sql   # Full schema + seed data
  Cargo.toml
  Cargo.lock
```

## Commands
| Action | Command |
|---|---|
| Run server | `cargo run` (in `backend/`) |
| Apply migration | `psql "$DATABASE_URL" -f migrations/001.sql` |
| Swagger UI | `docker compose up` serves at `http://localhost:8081` |
| Build | `cargo build` (in `backend/`) |

## Auth (critical — non-standard)
- **No JWT, no session, no real tokens.** `Authorization: Bearer <uuid>` where `<uuid>` is the user's profile UUID returned by `POST /login` or `POST /register`.
- Login at `POST /login` checks `auth.users` via `crypt()` and returns `{ id, role }`.
- `AuthUser` extractor (`auth.rs:20`) parses the Bearer token as a UUID and verifies it exists in `profiles` table. No signature, expiry, or refresh.
- Some handlers use `auth: AuthUser` for authorization (create_student, update_student, create_scholarship, verify_donor, delete_department). Others are unprotected.
- The `register` handler (not `AuthUser`-guarded) creates user in `auth.users` with `crypt()/gen_salt('bf')`, creates profile, and optionally creates student/donor record.

## API routes
| Method | Path | Auth? |
|---|---|---|
| POST | `/register` | No |
| POST | `/login` | No |
| POST | `/match/:student_id` | No |
| POST/GET | `/profiles` | No |
| GET | `/profiles/:id` | No |
| POST/GET | `/students` | Yes (POST) / No (GET) |
| GET/PUT | `/students/:profile_id` | Yes (PUT) / No (GET) |
| GET | `/donors` | No |
| GET | `/donors/:profile_id` | No |
| POST | `/donors/:profile_id/verify` | Yes (Admin only) |
| POST/GET | `/scholarships` | Yes (POST) / No (GET) |
| GET | `/scholarships/:id` | No |
| GET | `/cities` | No |
| GET | `/departments` | No |
| DELETE | `/departments/:name` | Yes (Admin only) |
| GET | `/income-levels` | No |
| GET | `/user-roles` | No |

## Key conventions & gotchas
- **No tests exist** — `todo.md` lists manual testing tasks. No test framework configured.
- **CORS**: `CorsLayer::permissive()` — wide open.
- **Connection pool**: `PgPoolOptions` with 1-5 connections, `test_before_acquire(false)`.
- **Scoring engine**: Empty target arrays (`[]`) = no filter (all pass). Elimination checks `is_empty()` after checking `is_some()`. GPA minimum check in elimination phase.
- **Schema**: `GPA` stored as `NUMERIC(3,2)`, cast via `::float4` in queries. `target_*` arrays default to `'{}'` not NULL. `matches` table exists in schema but has **no handler** yet.
- **Error strings**: Mix of Turkish and English.
- `CreateScholarshipRequest` fetches back by `title` (not returned ID) — fragile with duplicate titles.
- `delete_department` uses manual transaction: removes from scholarship arrays, deletes referencing students, then deletes department.
- New departments auto-inserted (`ON CONFLICT DO NOTHING`) when creating students or scholarships.
- **`.env.example` is incomplete** — it omits `SUPABASE_URL` and `SUPABASE_ANON_KEY`, but `AppConfig::from_env()` panics without them. Copy from `.env` or add them manually.
- `.env` is gitignored; use `.env.example` as template (but add the two Supabase vars).
