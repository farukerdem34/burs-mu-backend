# Burs Eşleştirme Motoru (Scholarship Matching Engine)

A Rust + Axum backend that matches students to scholarships using a weighted geometric-mean scoring algorithm with sigmoid transformations. Uses Supabase (PostgreSQL) for data storage, with Bearer-UUID authentication and role-based access control.

## Prerequisites

- Rust 1.85+ (edition 2021)
- A Supabase project with PostgreSQL
- Database schema applied (see `migrations/001.sql` for reference)

## Quick Start

### 1. Apply the database migration

Run the migration SQL (`migrations/001.sql`) in your Supabase SQL editor or via `psql`. Note that the migration uses `USER-DEFINED` types that must be created beforehand — the file is a reference schema.

### 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env` with your Supabase credentials and desired scoring weights.

### 3. Run the server

```bash
cargo run
```

The server starts at `http://0.0.0.0:8080`.

### 4. API docs (optional)

```bash
docker compose up -d
```

Serves Swagger UI on `http://localhost:8081` from `openapi.yaml`.

## Configuration

All variables are loaded from environment (see `.env.example`).

### Required

| Variable | Description |
|---|---|
| `DATABASE_URL` | Supabase PostgreSQL connection string |
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anon key |

### Server

| Variable | Default | Description |
|---|---|---|
| `HOST` | `0.0.0.0` | Server bind host |
| `SERVER_PORT` | `8080` | Server listen port |

### Database pool

| Variable | Default | Description |
|---|---|---|
| `DB_POOL_MIN` | `1` | Minimum pool connections |
| `DB_POOL_MAX` | `5` | Maximum pool connections |
| `DB_ACQUIRE_TIMEOUT_SECS` | `30` | Connection acquire timeout |
| `DB_TEST_BEFORE_ACQUIRE` | `false` | Test connection before use |

### Matching weights

Weights are normalized to sum to 1.0 before computing the weighted geometric mean.

| Variable | Default | Category |
|---|---|---|
| `WEIGHT_DEMO` | `0.30` | Demographic (city, income-level match) |
| `WEIGHT_ACADEMIC` | `0.30` | Academic (GPA, semester, standing) |
| `WEIGHT_NEED` | `0.25` | Financial need (family income, siblings, orphan/refugee) |
| `WEIGHT_EXTRA` | `0.15` | Extracurricular activities |

### Scheduling

| Variable | Default | Description |
|---|---|---|
| `MATCHING_INTERVAL_MINUTES` | `30` | Periodic batch-matching interval |
| `DEPARTMENT_SIMILARITY_THRESHOLD` | `0.8` | Levenshtein ratio for fuzzy department matching |

### Other

| Variable | Default | Description |
|---|---|---|
| `ALLOWED_ORIGINS` | `*` | CORS allowlist (comma-separated) |
| `LOG_LEVEL` | `info` | Tracing/log level |

## API

**Auth:** Most endpoints require a `Bearer <UUID>` token in the `Authorization` header. The UUID is the user's profile ID obtained from `/login` or `/register`. Three roles: `student`, `donor`, `admin`.

Full OpenAPI spec available at `openapi.yaml` (served via Swagger UI with `docker compose`).

### Authentication

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/register` | No | Create account (email, password, role). Optionally includes student/donor fields |
| `POST` | `/login` | No | Login with email/password. Returns `{ id, role, message }` |
| `GET` | `/health` | No | Health check |

### Profiles

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/profiles` | Admin | List all profiles |
| `POST` | `/profiles` | No | Create a profile manually |
| `GET` | `/profiles/:id` | No | Get profile by ID |

### Students

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/students` | Admin | List all students |
| `POST` | `/students` | Self/Admin | Create student record |
| `GET` | `/students/:profile_id` | No | Get single student |
| `PUT` | `/students/:profile_id` | Self/Admin | Update student (upsert) |
| `GET` | `/students/:profile_id/matches` | Self/Admin | Get live match results for a student |

### Donors

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/donors` | Admin | List all donors |
| `GET` | `/donors/:profile_id` | No | Get single donor |
| `GET` | `/donors/:profile_id/scholarships` | No | List scholarships by donor |
| `POST` | `/donors/:profile_id/verify` | Admin | Verify a donor |

### Scholarships

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/scholarships` | No | List all scholarships |
| `POST` | `/scholarships` | Admin | Create a scholarship |
| `GET` | `/scholarships/:id` | No | Get single scholarship |

### Matching

| Method | Path | Auth | Description |
|---|---|---|---|
| `POST` | `/match/:student_id` | Admin | Match a single student against all active scholarships |
| `POST` | `/match/run` | Admin | Run batch matching for all students. Stores results in `matches` table |

### Reference data

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/cities` | No | List Turkish cities |
| `GET` | `/departments` | No | List departments |
| `POST` | `/departments` | Admin | Create a department |
| `DELETE` | `/departments/:name` | Admin | Delete department (cascade to students/scholarships) |
| `GET` | `/income-levels` | No | List income level enums |
| `GET` | `/user-roles` | No | List user role enums |

## Scoring Algorithm

1. **Elimination** — A student is rejected if they fail any of these scholarship filters:
   - `target_cities`, `target_departments`, `target_income_levels` (must match one, empty = no filter)
   - `min_gpa`, `max_semester`, `min_extracurricular_score`, `max_household_income`
   - `preferred_gender` (heuristic from Turkish keywords in `about` text)
   - `accepts_disability`, `accepts_orphan`, `accepts_refugee`

2. **Per-category scores** (each normalized 0–1):
   - **Demographic** — average of city match and income-level match
   - **Academic** — sigmoid-weighted combination of GPA (0.6), semester progression (0.2), and academic standing (0.2)
   - **Financial need** — sigmoid-transformed income ratio (0.4), income level (0.25), siblings in education (0.15), orphan/refugee flags (0.10 each)
   - **Extracurricular** — sigmoid of extracurricular score

3. **Final score** = weighted geometric mean of the four categories (using normalized weights), multiplied by 100.
   ```
   score = exp(w_demo·ln(demo+ε) + w_academic·ln(academic+ε) + w_need·ln(need+ε) + w_extra·ln(extra+ε)) × 100
   ```

4. **Result** — Passing students receive a score; results are sorted descending.

## Project Structure

```
backend/
├── migrations/
│   └── 001.sql                  # Database schema (reference)
├── src/
│   ├── main.rs                  # Server entrypoint
│   ├── lib.rs                   # Module declarations, router, CORS
│   ├── config.rs                # Environment config (18+ variables)
│   ├── state.rs                 # App state (DB pool + config)
│   ├── auth.rs                  # Bearer UUID authentication extractor
│   ├── models.rs                # Data structs (Student, Scholarship, etc.)
│   ├── engine.rs                # Scoring algorithm (geometric mean, sigmoid)
│   ├── handlers.rs              # All API endpoint handlers
│   └── matching.rs              # Batch matching scheduler
├── .env.example                 # Environment template
├── docker-compose.yml           # Swagger UI service
├── openapi.yaml                 # Full OpenAPI 3.0.3 spec
├── Cargo.toml
├── PROGRESS.md                  # Build task tracking (Turkish)
└── README.md
```

## Department Fuzzy Matching

When creating or updating a student or scholarship, department names are normalized (Turkish character folding) and matched against existing departments using `normalized_levenshtein` from the `strsim` crate. If the similarity exceeds `DEPARTMENT_SIMILARITY_THRESHOLD` (default 0.8), the existing department name is used; otherwise, a new department is inserted.

## Periodic Scheduler

A background tokio task runs `run_matching()` at the interval specified by `MATCHING_INTERVAL_MINUTES`. It iterates all active scholarships, scores all students, and persists results to the `matches` table with JSONB `score_breakdown`. The scheduler starts automatically on server boot.
