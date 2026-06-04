use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use serde_json::json;
use uuid::Uuid;

use crate::auth::AuthUser;
use crate::engine;
use crate::models::{
    City, CreateProfileRequest, CreateScholarshipRequest, CreateStudentRequest, Department,
    Donor, IncomeLevelRow, LoginRequest, LoginResponse, MatchResult, Profile, RegisterRequest,
    RegisterResponse, Scholarship, ScholarshipRule, Student, UpdateStudentRequest, UserRole,
    UserRoleRow,
};
use crate::state::AppState;

pub async fn match_student(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(student_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth.role != UserRole::Admin {
        return (
            StatusCode::FORBIDDEN,
            Json("Sadece yöneticiler eşleştirme yapabilir"),
        )
            .into_response();
    }

    let student = match sqlx::query_as::<_, Student>(
        "SELECT profile_id, gpa::float4, city, department, income_status, about, created_at FROM students WHERE profile_id = $1",
    )
    .bind(student_id)
    .fetch_one(&state.db_pool)
    .await
    {
        Ok(s) => s,
        Err(_) => {
            return (
                StatusCode::NOT_FOUND,
                Json(vec![MatchResult {
                    scholarship_id: student_id,
                    score: 0.0,
                }]),
            )
                .into_response()
        }
    };

    let scholarships = match sqlx::query_as::<_, ScholarshipRule>(
        "SELECT id, min_gpa::float4, target_cities, target_departments, target_income_levels FROM scholarships WHERE is_active = true",
    )
    .fetch_all(&state.db_pool)
    .await
    {
        Ok(s) => s,
        Err(_) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(vec![MatchResult {
                    scholarship_id: student_id,
                    score: 0.0,
                }]),
            )
                .into_response()
        }
    };

    let mut results: Vec<MatchResult> = scholarships
        .iter()
        .filter_map(|rule| {
            engine::calculate_match_score(&student, rule, &state.config)
                .map(|score| MatchResult {
                    scholarship_id: rule.id,
                    score,
                })
        })
        .collect();

    results.sort_by(|a, b| {
        b.score
            .partial_cmp(&a.score)
            .unwrap_or(std::cmp::Ordering::Equal)
    });

    (StatusCode::OK, Json(results)).into_response()
}

// --- AUTH ---

pub async fn login(
    State(state): State<AppState>,
    Json(body): Json<LoginRequest>,
) -> impl IntoResponse {
    let result = sqlx::query_as::<_, (Uuid,)>(
        r#"
        SELECT id FROM auth.users
        WHERE email = $1 AND encrypted_password = crypt($2, encrypted_password)
        "#,
    )
    .bind(&body.email)
    .bind(&body.password)
    .fetch_optional(&state.db_pool)
    .await;

    let (user_id,) = match result {
        Ok(Some(id)) => id,
        Ok(None) => {
            return (StatusCode::UNAUTHORIZED, Json("E-posta veya şifre hatalı")).into_response();
        }
        Err(e) => {
            tracing::error!("Login error: {}", e);
            return (StatusCode::INTERNAL_SERVER_ERROR, Json("Giriş yapılamadı")).into_response();
        }
    };

    let profile = sqlx::query_as::<_, (Uuid, UserRole)>(
        "SELECT id, role FROM profiles WHERE id = $1",
    )
    .bind(user_id)
    .fetch_one(&state.db_pool)
    .await;

    match profile {
        Ok((id, role)) => (
            StatusCode::OK,
            Json(LoginResponse {
                id,
                role,
                message: "Giriş başarılı".to_string(),
            }),
        )
            .into_response(),
        Err(e) => {
            tracing::error!("Login profile fetch error: {}", e);
            (StatusCode::INTERNAL_SERVER_ERROR, Json("Profil bilgisi alınamadı")).into_response()
        }
    }
}

// --- PROFILES ---

pub async fn create_profile(
    State(state): State<AppState>,
    Json(body): Json<CreateProfileRequest>,
) -> impl IntoResponse {
    if body.role == UserRole::Admin {
        return (StatusCode::BAD_REQUEST, Json("Yönetici profili oluşturulamaz")).into_response();
    }

    match sqlx::query(
        "INSERT INTO profiles (id, role) VALUES ($1, $2)",
    )
    .bind(body.id)
    .bind(&body.role)
    .execute(&state.db_pool)
    .await
    {
        Ok(_) => {
            let profile = sqlx::query_as::<_, Profile>(
                "SELECT id, role, created_at, updated_at FROM profiles WHERE id = $1",
            )
            .bind(body.id)
            .fetch_one(&state.db_pool)
            .await;

            match profile {
                Ok(p) => (StatusCode::CREATED, Json(p)).into_response(),
                Err(_) => (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json("Profile created but failed to fetch"),
                )
                    .into_response(),
            }
        }
        Err(e) => {
            tracing::error!("Failed to create profile: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(format!("Failed to create profile: {}", e)),
            )
                .into_response()
        }
    }
}

pub async fn register(
    State(state): State<AppState>,
    Json(body): Json<RegisterRequest>,
) -> impl IntoResponse {
    if body.role == UserRole::Admin {
        return (StatusCode::BAD_REQUEST, Json("Yönetici kaydı yapılamaz")).into_response();
    }

    // Check if email already exists
    let exists: bool = sqlx::query_scalar(
        "SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = $1)",
    )
    .bind(&body.email)
    .fetch_one(&state.db_pool)
    .await
    .unwrap_or(false);

    if exists {
        return (StatusCode::CONFLICT, Json("Bu email zaten kayıtlı")).into_response();
    }

    // Create user directly via SQL with pgcrypto for password hashing
    let result = sqlx::query_as::<_, (Uuid,)>(
        r#"
        INSERT INTO auth.users (
            instance_id, id, aud, role, email,
            encrypted_password, email_confirmed_at, confirmation_sent_at,
            raw_app_meta_data, raw_user_meta_data, created_at, updated_at
        ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            gen_random_uuid(),
            'authenticated',
            'authenticated',
            $1,
            crypt($2, gen_salt('bf')),
            now(), now(),
            jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
            jsonb_build_object('role', $3),
            now(), now()
        )
        RETURNING id
        "#,
    )
    .bind(&body.email)
    .bind(&body.password)
    .bind(&body.role)
    .fetch_one(&state.db_pool)
    .await;

    let user_id = match result {
        Ok((id,)) => id,
        Err(e) => {
            tracing::error!("Failed to create auth user: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json("Kullanıcı oluşturulamadı"),
            )
                .into_response();
        }
    };

    // Insert profile
    if let Err(e) = sqlx::query("INSERT INTO profiles (id, role) VALUES ($1, $2)")
        .bind(user_id)
        .bind(&body.role)
        .execute(&state.db_pool)
        .await
    {
        tracing::error!("Failed to create profile after signup: {}", e);
        let _ = sqlx::query("DELETE FROM auth.users WHERE id = $1")
            .bind(user_id)
            .execute(&state.db_pool)
            .await;
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json("Profil oluşturulamadı, kayıt geri alındı"),
        )
            .into_response();
    }

    // If student role with all required fields, create student record
    if body.role == crate::models::UserRole::Student {
        if let Some(gpa) = body.gpa {
            if let Err(msg) = validate_gpa(gpa, "GPA") {
                return (StatusCode::BAD_REQUEST, Json(msg)).into_response();
            }
        }

        if let (Some(city), Some(department_input), Some(income_status)) =
            (&body.city, &body.department, &body.income_status)
        {
            let department = find_or_create_department(&state, department_input).await;

            if let Err(e) = sqlx::query(
                "INSERT INTO students (profile_id, gpa, city, department, income_status) VALUES ($1, $2, $3, $4, $5)",
            )
            .bind(user_id)
            .bind(body.gpa)
            .bind(city)
            .bind(&department)
            .bind(income_status)
            .execute(&state.db_pool)
            .await
            {
                tracing::error!("Failed to create student after signup: {}", e);
            }
        }
    }

    if body.role == crate::models::UserRole::Donor {
        if let Err(e) = sqlx::query(
            "INSERT INTO donors (profile_id, is_verified) VALUES ($1, FALSE)",
        )
        .bind(user_id)
        .execute(&state.db_pool)
        .await
        {
            tracing::error!("Failed to create donor after signup: {}", e);
            let _ = sqlx::query("DELETE FROM profiles WHERE id = $1")
                .bind(user_id)
                .execute(&state.db_pool)
                .await;
            let _ = sqlx::query("DELETE FROM auth.users WHERE id = $1")
                .bind(user_id)
                .execute(&state.db_pool)
                .await;
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json("Donor kaydı oluşturulamadı, kayıt geri alındı"),
            )
                .into_response();
        }
    }

    (
        StatusCode::CREATED,
        Json(RegisterResponse {
            id: user_id,
            email: body.email,
            role: body.role,
            message: "Kayıt başarılı".to_string(),
        }),
    )
        .into_response()
}

pub async fn get_profiles(
    State(state): State<AppState>,
    auth: AuthUser,
) -> impl IntoResponse {
    if auth.role != UserRole::Admin {
        return (
            StatusCode::FORBIDDEN,
            Json("Sadece yöneticiler profilleri görüntüleyebilir"),
        )
            .into_response();
    }

    match sqlx::query_as::<_, Profile>("SELECT id, role, created_at, updated_at FROM profiles ORDER BY created_at DESC")
        .fetch_all(&state.db_pool)
        .await
    {
        Ok(profiles) => (StatusCode::OK, Json(profiles)).into_response(),
        Err(e) => {
            tracing::error!("Failed to fetch profiles: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(format!("Failed to fetch profiles: {}", e)),
            )
                .into_response()
        }
    }
}

pub async fn get_profile(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    match sqlx::query_as::<_, Profile>(
        "SELECT id, role, created_at, updated_at FROM profiles WHERE id = $1",
    )
    .bind(id)
    .fetch_one(&state.db_pool)
    .await
    {
        Ok(profile) => (StatusCode::OK, Json(profile)).into_response(),
        Err(_) => (StatusCode::NOT_FOUND, Json("Profile not found")).into_response(),
    }
}

// --- STUDENTS ---

async fn validate_city(state: &AppState, city: &str) -> Result<(), String> {
    let exists: bool = sqlx::query_scalar(
        "SELECT EXISTS(SELECT 1 FROM cities WHERE name = $1)",
    )
    .bind(city)
    .fetch_one(&state.db_pool)
    .await
    .unwrap_or(false);

    if exists {
        Ok(())
    } else {
        Err(format!("'{}' geçerli bir Türkiye şehri değil", city))
    }
}

async fn validate_cities(state: &AppState, cities: &[String]) -> Result<(), String> {
    for city in cities {
        validate_city(state, city).await?;
    }
    Ok(())
}

fn validate_gpa(gpa: f32, field: &str) -> Result<(), String> {
    if gpa < 0.0 || gpa > 4.0 {
        Err(format!("{} 0.0 ile 4.0 arasında olmalıdır", field))
    } else {
        Ok(())
    }
}

pub async fn create_student(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(body): Json<CreateStudentRequest>,
) -> impl IntoResponse {
    if auth.id != body.profile_id && auth.role != UserRole::Admin {
        return (
            StatusCode::FORBIDDEN,
            Json("Kendi hesabınızı düzenleyebilirsiniz"),
        )
            .into_response();
    }

    if let Err(msg) = validate_city(&state, &body.city).await {
        return (StatusCode::BAD_REQUEST, Json(msg)).into_response();
    }

    if let Some(gpa) = body.gpa {
        if let Err(msg) = validate_gpa(gpa, "GPA") {
            return (StatusCode::BAD_REQUEST, Json(msg)).into_response();
        }
    }

    let department = find_or_create_department(&state, &body.department).await;

    match sqlx::query(
        "INSERT INTO students (profile_id, gpa, city, department, income_status) VALUES ($1, $2, $3, $4, $5)",
    )
    .bind(body.profile_id)
    .bind(body.gpa)
    .bind(&body.city)
    .bind(&department)
    .bind(&body.income_status)
    .execute(&state.db_pool)
    .await
    {
        Ok(_) => {
            let student = sqlx::query_as::<_, Student>(
                "SELECT profile_id, gpa::float4, city, department, income_status, about, created_at FROM students WHERE profile_id = $1",
            )
            .bind(body.profile_id)
            .fetch_one(&state.db_pool)
            .await;

            match student {
                Ok(s) => (StatusCode::CREATED, Json(s)).into_response(),
                Err(_) => (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json("Student created but failed to fetch"),
                )
                    .into_response(),
            }
        }
        Err(e) => {
            tracing::error!("Failed to create student: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(format!("Failed to create student: {}", e)),
            )
                .into_response()
        }
    }
}

pub async fn get_students(
    State(state): State<AppState>,
    auth: AuthUser,
) -> impl IntoResponse {
    if auth.role != UserRole::Admin {
        return (
            StatusCode::FORBIDDEN,
            Json("Sadece yöneticiler öğrencileri görüntüleyebilir"),
        )
            .into_response();
    }

    match sqlx::query_as::<_, Student>(
        "SELECT profile_id, gpa::float4, city, department, income_status, about, created_at FROM students ORDER BY created_at DESC",
    )
    .fetch_all(&state.db_pool)
    .await
    {
        Ok(students) => (StatusCode::OK, Json(students)).into_response(),
        Err(e) => {
            tracing::error!("Failed to fetch students: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(format!("Failed to fetch students: {}", e)),
            )
                .into_response()
        }
    }
}

pub async fn get_student(
    State(state): State<AppState>,
    Path(profile_id): Path<Uuid>,
) -> impl IntoResponse {
    match sqlx::query_as::<_, Student>(
        "SELECT profile_id, gpa::float4, city, department, income_status, about, created_at FROM students WHERE profile_id = $1",
    )
    .bind(profile_id)
    .fetch_one(&state.db_pool)
    .await
    {
        Ok(student) => (StatusCode::OK, Json(student)).into_response(),
        Err(_) => (StatusCode::NOT_FOUND, Json("Student not found")).into_response(),
    }
}

pub async fn get_student_matches(
    State(state): State<AppState>,
    Path(profile_id): Path<Uuid>,
) -> impl IntoResponse {
    let student = match sqlx::query_as::<_, Student>(
        "SELECT profile_id, gpa::float4, city, department, income_status, about, created_at FROM students WHERE profile_id = $1",
    )
    .bind(profile_id)
    .fetch_one(&state.db_pool)
    .await
    {
        Ok(s) => s,
        Err(_) => {
            return (StatusCode::NOT_FOUND, Json("Öğrenci bulunamadı")).into_response();
        }
    };

    let scholarships = match sqlx::query_as::<_, ScholarshipRule>(
        "SELECT id, min_gpa::float4, target_cities, target_departments, target_income_levels FROM scholarships WHERE is_active = true",
    )
    .fetch_all(&state.db_pool)
    .await
    {
        Ok(s) => s,
        Err(e) => {
            tracing::error!("Failed to fetch scholarships: {}", e);
            return (StatusCode::INTERNAL_SERVER_ERROR, Json("Burslar alınamadı")).into_response();
        }
    };

    let mut results: Vec<MatchResult> = scholarships
        .iter()
        .filter_map(|rule| {
            engine::calculate_match_score(&student, rule, &state.config)
                .map(|score| MatchResult {
                    scholarship_id: rule.id,
                    score,
                })
        })
        .collect();

    results.sort_by(|a, b| {
        b.score
            .partial_cmp(&a.score)
            .unwrap_or(std::cmp::Ordering::Equal)
    });

    (StatusCode::OK, Json(results)).into_response()
}

pub async fn update_student(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(profile_id): Path<Uuid>,
    Json(body): Json<UpdateStudentRequest>,
) -> impl IntoResponse {
    if auth.id != profile_id && auth.role != UserRole::Admin {
        return (
            StatusCode::FORBIDDEN,
            Json("Kendi hesabınızı düzenleyebilirsiniz"),
        )
            .into_response();
    }

    if let Some(gpa) = body.gpa {
        if let Err(msg) = validate_gpa(gpa, "GPA") {
            return (StatusCode::BAD_REQUEST, Json(msg)).into_response();
        }
    }

    let department = if let Some(ref dept) = body.department {
        Some(find_or_create_department(&state, dept).await)
    } else {
        None
    };

    let updated = sqlx::query(
        "UPDATE students SET gpa = COALESCE($1, gpa), city = COALESCE($2, city), department = COALESCE($3, department), income_status = COALESCE($4, income_status), about = COALESCE($5, about) WHERE profile_id = $6",
    )
    .bind(body.gpa)
    .bind(&body.city)
    .bind(&department)
    .bind(&body.income_status)
    .bind(&body.about)
    .bind(profile_id)
    .execute(&state.db_pool)
    .await;

    match updated {
        Ok(res) if res.rows_affected() > 0 => {
            // updated existing row
        }
        _ => {
            // no row to update → insert new
            if body.city.is_none() || body.department.is_none() || body.income_status.is_none() {
                return (StatusCode::BAD_REQUEST, Json("İlk kayıtta şehir, departman ve gelir düzeyi zorunludur")).into_response();
            }
            if let Err(e) = sqlx::query(
                "INSERT INTO students (profile_id, gpa, city, department, income_status, about) VALUES ($1, $2, $3, $4, $5, $6)",
            )
            .bind(profile_id)
            .bind(body.gpa)
            .bind(body.city.as_deref())
            .bind(department.as_deref())
            .bind(&body.income_status)
            .bind(&body.about)
            .execute(&state.db_pool)
            .await
            {
                tracing::error!("Failed to insert student: {}", e);
                return (StatusCode::INTERNAL_SERVER_ERROR, Json(format!("Failed to create student: {}", e))).into_response();
            }
        }
    };

    let student = sqlx::query_as::<_, Student>(
        "SELECT profile_id, gpa::float4, city, department, income_status, about, created_at FROM students WHERE profile_id = $1",
    )
    .bind(profile_id)
    .fetch_one(&state.db_pool)
    .await;

    match student {
        Ok(s) => (StatusCode::OK, Json(s)).into_response(),
        Err(_) => (StatusCode::INTERNAL_SERVER_ERROR, Json("Student updated but failed to fetch")).into_response(),
    }
}

// --- DONORS ---

pub async fn get_donors(
    State(state): State<AppState>,
    auth: AuthUser,
) -> impl IntoResponse {
    if auth.role != UserRole::Admin {
        return (
            StatusCode::FORBIDDEN,
            Json("Sadece yöneticiler burs verenleri görüntüleyebilir"),
        )
            .into_response();
    }

    match sqlx::query_as::<_, Donor>(
        "SELECT profile_id, is_verified, created_at FROM donors ORDER BY created_at DESC",
    )
    .fetch_all(&state.db_pool)
    .await
    {
        Ok(donors) => (StatusCode::OK, Json(donors)).into_response(),
        Err(e) => {
            tracing::error!("Failed to fetch donors: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(format!("Failed to fetch donors: {}", e)),
            )
                .into_response()
        }
    }
}

pub async fn get_donor(
    State(state): State<AppState>,
    Path(profile_id): Path<Uuid>,
) -> impl IntoResponse {
    match sqlx::query_as::<_, Donor>(
        "SELECT profile_id, is_verified, created_at FROM donors WHERE profile_id = $1",
    )
    .bind(profile_id)
    .fetch_one(&state.db_pool)
    .await
    {
        Ok(donor) => (StatusCode::OK, Json(donor)).into_response(),
        Err(_) => (StatusCode::NOT_FOUND, Json("Donor not found")).into_response(),
    }
}

pub async fn verify_donor(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(profile_id): Path<Uuid>,
) -> impl IntoResponse {
    if auth.role != UserRole::Admin {
        return (
            StatusCode::FORBIDDEN,
            Json("Sadece yöneticiler burs verenleri onaylayabilir"),
        )
            .into_response();
    }

    match sqlx::query("UPDATE donors SET is_verified = TRUE WHERE profile_id = $1")
        .bind(profile_id)
        .execute(&state.db_pool)
        .await
    {
        Ok(res) if res.rows_affected() > 0 => {
            let donor = sqlx::query_as::<_, Donor>(
                "SELECT profile_id, is_verified, created_at FROM donors WHERE profile_id = $1",
            )
            .bind(profile_id)
            .fetch_one(&state.db_pool)
            .await;

            match donor {
                Ok(d) => (StatusCode::OK, Json(d)).into_response(),
                Err(_) => (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    Json("Donor updated but failed to fetch"),
                )
                    .into_response(),
            }
        }
        Ok(_) => (StatusCode::NOT_FOUND, Json("Donor not found")).into_response(),
        Err(e) => {
            tracing::error!("Failed to verify donor: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(format!("Failed to verify donor: {}", e)),
            )
                .into_response()
        }
    }
}

// --- SCHOLARSHIPS ---

pub async fn create_scholarship(
    State(state): State<AppState>,
    auth: AuthUser,
    Json(mut body): Json<CreateScholarshipRequest>,
) -> impl IntoResponse {
    if auth.role != UserRole::Admin {
        return (
            StatusCode::FORBIDDEN,
            Json("Sadece yöneticiler burs oluşturabilir"),
        )
            .into_response();
    }

    let donor_id = auth.id;

    if let Some(ref cities) = body.target_cities {
        if !cities.is_empty() {
            if let Err(msg) = validate_cities(&state, cities).await {
                return (StatusCode::BAD_REQUEST, Json(msg)).into_response();
            }
        }
    }

    if let Some(min_gpa) = body.min_gpa {
        if let Err(msg) = validate_gpa(min_gpa, "Minimum GPA") {
            return (StatusCode::BAD_REQUEST, Json(msg)).into_response();
        }
    }

    // Resolve department names: find existing similar or insert new
    if let Some(ref mut deps) = body.target_departments {
        if !deps.is_empty() {
            for dep in deps.iter_mut() {
                *dep = find_or_create_department(&state, dep).await;
            }
        }
    }

    match sqlx::query(
        "INSERT INTO scholarships (donor_id, title, quota, is_active, min_gpa, target_cities, target_departments, target_income_levels) VALUES ($1, $2, COALESCE($3, 1), COALESCE($4, true), $5, $6, $7, $8)",
    )
    .bind(donor_id)
    .bind(&body.title)
    .bind(body.quota)
    .bind(body.is_active)
    .bind(body.min_gpa)
    .bind(&body.target_cities)
    .bind(&body.target_departments)
    .bind(&body.target_income_levels)
    .execute(&state.db_pool)
    .await
    {
        Ok(res) => {
            tracing::info!("create_scholarship: rows_affected={:?}, donor_id={:?}, title={:?}", res.rows_affected(), donor_id, body.title);
            // Fetch back by title + donor_id since we have no id yet
            let scholarship = sqlx::query_as::<_, Scholarship>(
                "SELECT id, donor_id, title, quota, is_active, min_gpa::float4, target_cities, target_departments, target_income_levels, created_at FROM scholarships WHERE title = $1 ORDER BY created_at DESC LIMIT 1",
            )
            .bind(&body.title)
            .fetch_one(&state.db_pool)
            .await;

            match scholarship {
                Ok(s) => (StatusCode::CREATED, Json(s)).into_response(),
                Err(e) => {
                    tracing::error!("Failed to fetch created scholarship: {}", e);
                    (
                        StatusCode::INTERNAL_SERVER_ERROR,
                        Json(format!("Scholarship created but failed to fetch: {}", e)),
                    )
                        .into_response()
                }
            }
        }
        Err(e) => {
            tracing::error!("Failed to create scholarship: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(format!("Failed to create scholarship: {}", e)),
            )
                .into_response()
        }
    }
}

// --- MATCHING ---

pub async fn run_matching_handler(
    State(state): State<AppState>,
    auth: AuthUser,
) -> impl IntoResponse {
    if auth.role != UserRole::Admin {
        return (
            StatusCode::FORBIDDEN,
            Json("Sadece yöneticiler eşleştirme çalıştırabilir"),
        )
            .into_response();
    }

    match crate::matching::run_matching(&state).await {
        Ok(count) => (
            StatusCode::OK,
            Json(json!({
                "message": format!("{} eşleşme oluşturuldu", count),
                "matched_count": count
            })),
        )
            .into_response(),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(json!({"error": e})),
        )
            .into_response(),
    }
}

fn normalize_department(s: &str) -> String {
    s.chars()
        .map(|c| match c {
            'ü' | 'û' | 'Ü' | 'Û' => 'u',
            'ö' | 'ô' | 'Ö' | 'Ô' => 'o',
            'ç' | 'Ç' => 'c',
            'ş' | 'Ş' => 's',
            'ğ' | 'Ğ' => 'g',
            'ı' | 'I' | 'İ' => 'i',
            _ => c.to_ascii_lowercase(),
        })
        .collect()
}

async fn find_or_create_department(state: &AppState, department: &str) -> String {
    let departments = sqlx::query_as::<_, Department>("SELECT name FROM departments")
        .fetch_all(&state.db_pool)
        .await
        .unwrap_or_default();

    let normalized_input = normalize_department(department);

    for existing in &departments {
        let similarity =
            strsim::normalized_levenshtein(&normalized_input, &normalize_department(&existing.name));
        if similarity > 0.8 {
            return existing.name.clone();
        }
    }

    let _ = sqlx::query("INSERT INTO departments (name) VALUES ($1) ON CONFLICT (name) DO NOTHING")
        .bind(department)
        .execute(&state.db_pool)
        .await;

    department.to_string()
}

pub async fn get_scholarships(State(state): State<AppState>) -> impl IntoResponse {
    match sqlx::query_as::<_, Scholarship>(
        "SELECT id, donor_id, title, quota, is_active, min_gpa::float4, target_cities, target_departments, target_income_levels, created_at FROM scholarships ORDER BY created_at DESC",
    )
    .fetch_all(&state.db_pool)
    .await
    {
        Ok(scholarships) => (StatusCode::OK, Json(scholarships)).into_response(),
        Err(e) => {
            tracing::error!("Failed to fetch scholarships: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(format!("Failed to fetch scholarships: {}", e)),
            )
                .into_response()
        }
    }
}

pub async fn get_scholarship(
    State(state): State<AppState>,
    Path(id): Path<Uuid>,
) -> impl IntoResponse {
    match sqlx::query_as::<_, Scholarship>(
        "SELECT id, donor_id, title, quota, is_active, min_gpa::float4, target_cities, target_departments, target_income_levels, created_at FROM scholarships WHERE id = $1",
    )
    .bind(id)
    .fetch_one(&state.db_pool)
    .await
    {
        Ok(scholarship) => (StatusCode::OK, Json(scholarship)).into_response(),
        Err(_) => (StatusCode::NOT_FOUND, Json("Scholarship not found")).into_response(),
    }
}

// --- CITIES & DEPARTMENTS ---

pub async fn get_cities(State(state): State<AppState>) -> impl IntoResponse {
    match sqlx::query_as::<_, City>("SELECT name FROM cities ORDER BY name")
        .fetch_all(&state.db_pool)
        .await
    {
        Ok(cities) => (StatusCode::OK, Json(cities)).into_response(),
        Err(e) => {
            tracing::error!("Failed to fetch cities: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(format!("Failed to fetch cities: {}", e)),
            )
                .into_response()
        }
    }
}

pub async fn get_user_roles(State(state): State<AppState>) -> impl IntoResponse {
    match sqlx::query_as::<_, UserRoleRow>("SELECT name FROM user_roles ORDER BY name")
        .fetch_all(&state.db_pool)
        .await
    {
        Ok(roles) => (StatusCode::OK, Json(roles)).into_response(),
        Err(e) => {
            tracing::error!("Failed to fetch user_roles: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(format!("Failed to fetch user_roles: {}", e)),
            )
                .into_response()
        }
    }
}

pub async fn get_income_levels(State(state): State<AppState>) -> impl IntoResponse {
    match sqlx::query_as::<_, IncomeLevelRow>("SELECT value FROM income_levels ORDER BY value")
        .fetch_all(&state.db_pool)
        .await
    {
        Ok(levels) => (StatusCode::OK, Json(levels)).into_response(),
        Err(e) => {
            tracing::error!("Failed to fetch income_levels: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(format!("Failed to fetch income_levels: {}", e)),
            )
                .into_response()
        }
    }
}

pub async fn get_departments(State(state): State<AppState>) -> impl IntoResponse {
    match sqlx::query_as::<_, Department>("SELECT name FROM departments ORDER BY name")
        .fetch_all(&state.db_pool)
        .await
    {
        Ok(departments) => (StatusCode::OK, Json(departments)).into_response(),
        Err(e) => {
            tracing::error!("Failed to fetch departments: {}", e);
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(format!("Failed to fetch departments: {}", e)),
            )
                .into_response()
        }
    }
}

pub async fn delete_department(
    State(state): State<AppState>,
    auth: AuthUser,
    Path(name): Path<String>,
) -> impl IntoResponse {
    if auth.role != UserRole::Admin {
        return (
            StatusCode::FORBIDDEN,
            Json("Sadece yöneticiler departman silebilir"),
        )
            .into_response();
    }

    let mut tx = match state.db_pool.begin().await {
        Ok(tx) => tx,
        Err(e) => {
            tracing::error!("Failed to begin transaction: {}", e);
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json("Failed to begin transaction".to_string()),
            )
                .into_response();
        }
    };

    // Remove department from scholarship target arrays
    if let Err(e) = sqlx::query(
        "UPDATE scholarships SET target_departments = array_remove(target_departments, $1)",
    )
    .bind(&name)
    .execute(&mut *tx)
    .await
    {
        tracing::error!("Failed to update scholarships: {}", e);
        let _ = tx.rollback().await;
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(format!("Failed to update scholarships: {}", e)),
        )
            .into_response();
    }

    // Delete students referencing this department
    if let Err(e) = sqlx::query("DELETE FROM students WHERE department = $1")
        .bind(&name)
        .execute(&mut *tx)
        .await
    {
        tracing::error!("Failed to delete students: {}", e);
        let _ = tx.rollback().await;
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            Json(format!("Failed to delete students: {}", e)),
        )
            .into_response();
    }

    // Delete the department itself
    match sqlx::query("DELETE FROM departments WHERE name = $1")
        .bind(&name)
        .execute(&mut *tx)
        .await
    {
        Ok(result) if result.rows_affected() == 0 => {
            let _ = tx.rollback().await;
            (
                StatusCode::NOT_FOUND,
                Json(format!("Department '{}' not found", name)),
            )
                .into_response()
        }
        Ok(_) => {
            tx.commit().await.unwrap_or_else(|e| {
                tracing::error!("Failed to commit transaction: {}", e);
            });
            (StatusCode::OK, Json(format!("Department '{}' deleted", name))).into_response()
        }
        Err(e) => {
            tracing::error!("Failed to delete department: {}", e);
            let _ = tx.rollback().await;
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(format!("Failed to delete department: {}", e)),
            )
                .into_response()
        }
    }
}
