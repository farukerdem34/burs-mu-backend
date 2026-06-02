# Burs Eşleştirme Motoru (Scholarship Matching Engine)

A Rust + Axum backend that matches students to scholarships using a weighted scoring algorithm. Uses Supabase (PostgreSQL) for data storage.

## Prerequisites

- Rust 1.85+ (edition 2024)
- A Supabase project with PostgreSQL
- SQL migration applied (see `migrations/001.sql`)

## Quick Start

### 1. Apply the database migration

Run the migration SQL (`migrations/001.sql`) in your Supabase SQL editor or via `psql`:

```bash
psql "$DATABASE_URL" -f migrations/001.sql
```

### 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env` with your Supabase credentials and desired scoring weights:

| Variable | Default | Description |
|----------|---------|-------------|
| `DATABASE_URL` | — | Supabase PostgreSQL connection string |
| `SERVER_PORT` | `8080` | Server listen port |
| `WEIGHT_CITY` | `0.3` | Weight for city match in score |
| `WEIGHT_DEPARTMENT` | `0.3` | Weight for department match in score |
| `WEIGHT_GPA` | `0.2` | Weight for GPA in score |
| `WEIGHT_INCOME` | `0.2` | Weight for income level match in score |

### 3. Run the server

```bash
cargo run
```

The server starts at `http://0.0.0.0:8080`.

## API

### Match a student with scholarships

```
POST /match/:student_id
```

**Path parameter:** `student_id` — UUID of the student's profile

**Response:** JSON array of matches, sorted by score descending

```json
[
  { "scholarship_id": "uuid-...", "score": 85.5 },
  { "scholarship_id": "uuid-...", "score": 72.3 }
]
```

## Scoring Algorithm

1. **Elimination** — If a scholarship specifies `target_cities`, `target_departments`, or `target_income_levels`, the student is immediately rejected if they don't match any of the listed values. Empty/unset lists are treated as "no filter".
2. **Weighted score** — Matches on city, department, and income level each contribute `100 × weight` points. GPA contributes `(gpa / 4.0) × 100 × WEIGHT_GPA`.
3. **Result** — Passing students receive a score; results are sorted descending.

## Project Structure

```
backend/
├── migrations/
│   └── 001.sql            # Database schema
├── src/
│   ├── main.rs            # Server entrypoint
│   ├── config.rs          # Environment configuration
│   ├── state.rs           # App state (DB pool + config)
│   ├── models.rs          # Data structs (Student, Scholarship)
│   ├── engine.rs          # Matching & scoring algorithm
│   └── handlers.rs        # API endpoint handlers
├── .env.example           # Environment template
├── Cargo.toml
└── README.md
```
