use axum::{
    extract::{Path, State},
    Json,
};
use uuid::Uuid;

use crate::engine;
use crate::models::{MatchResult, ScholarshipRule, Student};
use crate::state::AppState;

pub async fn match_student(
    State(state): State<AppState>,
    Path(student_id): Path<Uuid>,
) -> Json<Vec<MatchResult>> {
    let student = sqlx::query_as::<_, Student>(
        "SELECT profile_id, gpa::float4, city, department, income_status FROM students WHERE profile_id = $1",
    )
    .bind(student_id)
    .fetch_one(&state.db_pool)
    .await
    .expect("Student not found");

    let scholarships = sqlx::query_as::<_, ScholarshipRule>(
        "SELECT id, min_gpa::float4, target_cities, target_departments, target_income_levels FROM scholarships WHERE is_active = true",
    )
    .fetch_all(&state.db_pool)
    .await
    .expect("Failed to fetch scholarships");

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

    Json(results)
}
