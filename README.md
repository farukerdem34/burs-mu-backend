# Burs Eşleştirme Sistemi

Öğrencileri, ihtiyaç ve başarı kriterlerine göre uygun bursiyerlerle buluşturan eşleştirme sistemi.

## Mimari

```
final/
├── backend/          # Rust + Axum REST API
│   ├── src/
│   │   ├── main.rs           # Entry point, router, bg matching spawn
│   │   ├── auth.rs           # AuthUser extractor (Bearer <uuid>)
│   │   ├── config.rs         # AppConfig::from_env()
│   │   ├── state.rs          # AppState { PgPool, Config }
│   │   ├── models.rs         # Student, Donor, Profile, Scholarship...
│   │   ├── engine.rs         # calculate_match_score()
│   │   ├── handlers.rs       # Tüm route handler'ları
│   │   ├── matching.rs       # Arka plan eşleştirme motoru
│   │   └── lib.rs            # Kütüphane girişi
│   └── migrations/
│       └── 001.sql           # Şema + seed verisi
├── mobile/           # Flutter mobil uygulama
│   └── lib/
│       ├── main.dart
│       ├── app.dart
│       ├── core/             # constants, theme, secure_storage
│       ├── models/           # DTO'lar (json_serializable)
│       ├── services/         # Dio HTTP servisleri
│       ├── providers/        # Riverpod state yönetimi
│       ├── features/         # auth, home, student, donor, scholarship, admin
│       └── widgets/          # Ortak UI bileşenleri
└── AGENTS.md         # Agent kılavuzu
```

## Backend

- **Dil/Runtime:** Rust (edition 2021), Axum 0.7, Tokio
- **Veritabanı:** PostgreSQL (Supabase), sqlx 0.8
- **Kimlik Doğrulama:** Bearer `<uuid>` (JWT yok, oturum yok)

### Bağımlılıklar

```bash
cd backend
cargo build
```

### Ortam Değişkenleri (`.env`)

```
DATABASE_URL=postgres://postgres:...
SUPABASE_URL=https://...
SUPABASE_ANON_KEY=...
SERVER_PORT=8080
MATCHING_INTERVAL_MINUTES=30
```

### Veritabanı Kurulumu

```bash
psql "$DATABASE_URL" -f backend/migrations/001.sql
```

### Çalıştırma

```bash
cd backend && cargo run
```

### Test

```bash
cd backend && cargo test --test api_tests
```

Swagger UI: `docker compose up` → http://localhost:8081

## Mobile (Flutter)

- **State yönetimi:** Riverpod (flutter_riverpod)
- **HTTP:** Dio + Bearer interceptor
- **Routing:** go_router
- **Token depolama:** flutter_secure_storage

### Bağımlılıklar

```bash
cd mobile
flutter pub get
```

### Çalıştırma

```bash
cd mobile && flutter run
```

### Model üretimi

```bash
cd mobile && dart run build_runner build --delete-conflicting-outputs
```

### Analiz

```bash
cd mobile && dart analyze
```

## API Routes

| Metot | Path | Auth |
|---|---|---|
| POST | `/register` | - |
| POST | `/login` | - |
| POST | `/match/:student_id` | - |
| POST | `/match/run` | Admin |
| GET | `/profiles` | - |
| GET | `/profiles/:id` | - |
| POST | `/students` | Evet |
| GET | `/students` | - |
| PUT | `/students/:profile_id` | Evet |
| GET | `/students/:profile_id/matches` | - |
| GET | `/donors` | - |
| GET | `/donors/:profile_id` | - |
| POST | `/donors/:profile_id/verify` | Admin |
| POST | `/scholarships` | Evet |
| GET | `/scholarships` | - |
| GET | `/scholarships/:id` | - |
| GET | `/cities` | - |
| GET | `/departments` | - |
| DELETE | `/departments/:name` | Admin |
| GET | `/income-levels` | - |
| GET | `/user-roles` | - |

## Veri Modeli

- **Roller:** student, donor, admin
- **Kriterler:** şehir, bölüm, gelir düzeyi (0/1/2), GPA (0.00–4.00)
- **Eşleştirme:** eliminasyon → ağırlıklı skorlama; boş hedef dizileri filtre uygulamaz
- **Match durumları:** matched, applied, under_review, approved, rejected

## Lisans

GNU General Public License v3.0
