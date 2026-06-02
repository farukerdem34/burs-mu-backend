use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use uuid::Uuid;

use crate::engine;
use crate::models::{
    CreateProfileRequest, CreateScholarshipRequest, CreateStudentRequest, MatchResult, Profile,
    Scholarship, ScholarshipRule, Student,
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

pub async fn create_student(
    State(state): State<AppState>,
    Json(body): Json<CreateStudentRequest>,
) -> impl IntoResponse {
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
