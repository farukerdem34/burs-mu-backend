use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use uuid::Uuid;

use crate::engine;
use crate::models::{
    City, CreateProfileRequest, CreateScholarshipRequest, CreateStudentRequest, Department,
    IncomeLevelRow, MatchResult, Profile, RegisterRequest, RegisterResponse, Scholarship,
    ScholarshipRule, Student, UserRoleRow,
};
use crate::state::AppState;

pub async fn match_student(
    State(state): State<AppState>,
    Path(student_id): Path<Uuid>,
) -> impl IntoResponse {
    let student = match sqlx::query_as::<_, Student>(
        "SELECT profile_id, gpa::float4, city, department, income_status FROM students WHERE profile_id = $1",
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

// --- PROFILES ---

pub async fn create_profile(
    State(state): State<AppState>,
    Json(body): Json<CreateProfileRequest>,
) -> impl IntoResponse {
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

    // If student role, also insert into students table
    if body.role == crate::models::UserRole::Student {
        let city = match &body.city {
            Some(c) => c.clone(),
            None => {
                let _ = sqlx::query("DELETE FROM profiles WHERE id = $1")
                    .bind(user_id)
                    .execute(&state.db_pool)
                    .await;
                let _ = sqlx::query("DELETE FROM auth.users WHERE id = $1")
                    .bind(user_id)
                    .execute(&state.db_pool)
                    .await;
                return (StatusCode::BAD_REQUEST, Json("Öğrenci kaydı için şehir gerekli")).into_response();
            }
        };
        let department = match &body.department {
            Some(d) => d.clone(),
            None => {
                let _ = sqlx::query("DELETE FROM profiles WHERE id = $1")
                    .bind(user_id)
                    .execute(&state.db_pool)
                    .await;
                let _ = sqlx::query("DELETE FROM auth.users WHERE id = $1")
                    .bind(user_id)
                    .execute(&state.db_pool)
                    .await;
                return (StatusCode::BAD_REQUEST, Json("Öğrenci kaydı için departman gerekli")).into_response();
            }
        };
        let income_status = match &body.income_status {
            Some(i) => i.clone(),
            None => {
                let _ = sqlx::query("DELETE FROM profiles WHERE id = $1")
                    .bind(user_id)
                    .execute(&state.db_pool)
                    .await;
                let _ = sqlx::query("DELETE FROM auth.users WHERE id = $1")
                    .bind(user_id)
                    .execute(&state.db_pool)
                    .await;
                return (StatusCode::BAD_REQUEST, Json("Öğrenci kaydı için gelir düzeyi gerekli")).into_response();
            }
        };

        if let Err(e) = sqlx::query(
            "INSERT INTO students (profile_id, city, department, income_status) VALUES ($1, $2, $3, $4)",
        )
        .bind(user_id)
        .bind(&city)
        .bind(&department)
        .bind(&income_status)
        .execute(&state.db_pool)
        .await
        {
            tracing::error!("Failed to create student after signup: {}", e);
            let _ = sqlx::query("DELETE FROM profiles WHERE id = $1")
                .bind(user_id)
                .execute(&state.db_pool)
                .await;
            let _ = sqlx::query("DELETE FROM auth.users WHERE id = $1")
                .bind(user_id)
                .execute(&state.db_pool)
                .await;
            return (
                StatusCode::BAD_REQUEST,
                Json(format!("Öğrenci kaydı oluşturulamadı: {}", e)),
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

pub async fn get_profiles(State(state): State<AppState>) -> impl IntoResponse {
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

pub async fn create_student(
    State(state): State<AppState>,
    Json(body): Json<CreateStudentRequest>,
) -> impl IntoResponse {
    if let Err(msg) = validate_city(&state, &body.city).await {
        return (StatusCode::BAD_REQUEST, Json(msg)).into_response();
    }

    match sqlx::query(
        "INSERT INTO students (profile_id, gpa, city, department, income_status, is_verified) VALUES ($1, $2, $3, $4, $5, $6)",
    )
    .bind(body.profile_id)
    .bind(body.gpa)
    .bind(&body.city)
    .bind(&body.department)
    .bind(&body.income_status)
    .bind(body.is_verified)
    .execute(&state.db_pool)
    .await
    {
        Ok(_) => {
            let student = sqlx::query_as::<_, Student>(
                "SELECT profile_id, gpa::float4, city, department, income_status, is_verified, created_at FROM students WHERE profile_id = $1",
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

pub async fn get_students(State(state): State<AppState>) -> impl IntoResponse {
    match sqlx::query_as::<_, Student>(
        "SELECT profile_id, gpa::float4, city, department, income_status, is_verified, created_at FROM students ORDER BY created_at DESC",
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
        "SELECT profile_id, gpa::float4, city, department, income_status, is_verified, created_at FROM students WHERE profile_id = $1",
    )
    .bind(profile_id)
    .fetch_one(&state.db_pool)
    .await
    {
        Ok(student) => (StatusCode::OK, Json(student)).into_response(),
        Err(_) => (StatusCode::NOT_FOUND, Json("Student not found")).into_response(),
    }
}

// --- SCHOLARSHIPS ---

pub async fn create_scholarship(
    State(state): State<AppState>,
    Json(body): Json<CreateScholarshipRequest>,
) -> impl IntoResponse {
    if let Some(ref cities) = body.target_cities {
        if !cities.is_empty() {
            if let Err(msg) = validate_cities(&state, cities).await {
                return (StatusCode::BAD_REQUEST, Json(msg)).into_response();
            }
        }
    }

    // Auto-insert new departments into the departments table
    if let Some(ref deps) = body.target_departments {
        if !deps.is_empty() {
            for dep in deps {
                let _ = sqlx::query("INSERT INTO departments (name) VALUES ($1) ON CONFLICT (name) DO NOTHING")
                    .bind(dep)
                    .execute(&state.db_pool)
                    .await;
            }
        }
    }

    match sqlx::query(
        "INSERT INTO scholarships (donor_id, title, quota, is_active, min_gpa, target_cities, target_departments, target_income_levels) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)",
    )
    .bind(body.donor_id)
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
            tracing::info!("create_scholarship: rows_affected={:?}, donor_id={:?}, title={:?}", res.rows_affected(), body.donor_id, body.title);
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
    match sqlx::query_as::<_, IncomeLevelRow>("SELECT name FROM income_levels ORDER BY name")
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
