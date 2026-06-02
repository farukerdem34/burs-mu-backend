# Burs Eşleştirme Sistemi — Agent Guide

## Stack
- **Rust** (edition 2021, not 2024) + **Axum 0.7** + **sqlx 0.8** (PostgreSQL)
- **Supabase** for Postgres + auth.users table
- Skills loaded: `supabase`, `supabase-postgres-best-practices` (`backend/.agents/skills/`)

## Structure
```
backend/          # All application code (monorepo root is just .serena/ + backend/)
  src/
    main.rs       # Entrypoint, router setup, TcpListener
    config.rs     # AppConfig::from_env() — panics on missing DATABASE_URL, SUPABASE_URL, SUPABASE_ANON_KEY
    state.rs      # AppState { db_pool: PgPool, config: AppConfig }
    models.rs     # Student, Donor, Profile, Scholarship, ScholarshipRule + request/response types
    engine.rs     # calculate_match_score() — elimination then weighted scoring
    handlers.rs   # All route handlers (~800 lines)
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

## Key conventions
- **No tests exist** — `todo.md` lists pending test tasks. No test framework configured.
- **Auth**: Registration goes through raw `auth.users` table with `crypt()/gen_salt('bf')`, email auto-confirmed. No JWT middleware.
- **CORS**: `CorsLayer::permissive()` — wide open.
- **Connection pool**: `PgPoolOptions` with 1-5 connections, `test_before_acquire(false)`.
- **Scoring engine**: Empty target arrays (`[]`) = no filter (all pass). Elimination checks `is_empty()` to distinguish "no filter" from actual values. GPA minimum check also in elimination phase.
- **Schema quirks**: `GPA` stored as `NUMERIC(3,2)`, cast via `::float4` in SQL queries. `target_*` arrays default to `'{}'` not NULL.
- **Error strings**: Mix of Turkish and English in responses.
- **Architecture**: Monolithic single binary. All routes, state, and business logic in one crate. No middleware layers beyond CORS.

## API routes (all under `backend/`)
| Method | Path | Handler |
|---|---|---|
| POST | `/register` | register |
| POST | `/match/:student_id` | match_student |
| POST/GET | `/profiles` | create_profile / get_profiles |
| GET | `/profiles/:id` | get_profile |
| POST/GET | `/students` | create_student / get_students |
| GET/PUT | `/students/:profile_id` | get_student / update_student |
| GET | `/donors` | get_donors |
| GET | `/donors/:profile_id` | get_donor |
| POST | `/donors/:profile_id/verify` | verify_donor |
| POST/GET | `/scholarships` | create_scholarship / get_scholarships |
| GET | `/scholarships/:id` | get_scholarship |
| GET | `/cities` | get_cities |
| GET | `/departments` | get_departments |
| DELETE | `/departments/:name` | delete_department |
| GET | `/income-levels` | get_income_levels |
| GET | `/user-roles` | get_user_roles |

## Gotchas
- `CreateScholarshipRequest` returns the created row matched by `title` (not by returned ID) — fragile if duplicate titles.
- `delete_department` uses a manual transaction: removes from scholarship arrays, deletes referencing students, then deletes the department.
- New departments are auto-inserted (with `ON CONFLICT DO NOTHING`) when creating students or scholarships.
- `.env` is gitignored; use `.env.example` as template.
