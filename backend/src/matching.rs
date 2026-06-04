use crate::engine;
use crate::models::{Scholarship, ScholarshipRule, ScoreBreakdown, Student};
use crate::state::AppState;
use uuid::Uuid;

pub async fn run_matching(state: &AppState) -> Result<usize, String> {
    let scholarships = sqlx::query_as::<_, Scholarship>(
        r#"SELECT id, donor_id, title, quota, is_active, min_gpa::float4,
           target_cities, target_departments, target_income_levels,
           amount_per_year, duration_months, scholarship_type,
           preferred_gender, requires_essay, requires_interview,
           accepts_disability, accepts_orphan, accepts_refugee,
           max_semester, min_extracurricular_score, max_household_income, created_at
           FROM scholarships WHERE is_active = true"#,
    )
    .fetch_all(&state.db_pool)
    .await
    .map_err(|e| format!("Burslar alınamadı: {}", e))?;

    let mut total = 0;
    for s in &scholarships {
        let rule = ScholarshipRule {
            id: s.id,
            min_gpa: s.min_gpa,
            target_cities: s.target_cities.clone(),
            target_departments: s.target_departments.clone(),
            target_income_levels: s.target_income_levels.clone(),
            preferred_gender: s.preferred_gender.clone(),
            accepts_disability: s.accepts_disability,
            accepts_orphan: s.accepts_orphan,
            accepts_refugee: s.accepts_refugee,
            max_semester: s.max_semester,
            min_extracurricular_score: s.min_extracurricular_score,
            max_household_income: s.max_household_income,
            scholarship_type: s.scholarship_type.clone(),
        };
        total += match_scholarship(state, s.id, s.quota, &rule).await?;
    }
    Ok(total)
}

async fn match_scholarship(
    state: &AppState,
    scholarship_id: Uuid,
    quota: i32,
    rule: &ScholarshipRule,
) -> Result<usize, String> {
    let students = sqlx::query_as::<_, Student>(
        r#"SELECT profile_id, gpa::float4, city, department, income_status, about, created_at,
           semester, family_income, household_size, num_siblings_in_education,
           has_disability, is_orphan, is_refugee, academic_standing, extracurricular_score
           FROM students"#,
    )
    .fetch_all(&state.db_pool)
    .await
    .map_err(|e| format!("Öğrenciler alınamadı: {}", e))?;

    let mut scored: Vec<(Uuid, f32, Option<ScoreBreakdown>)> = students
        .iter()
        .filter_map(|st| {
            engine::calculate_match_score_detailed(st, rule, &state.config)
                .map(|(score, breakdown)| (st.profile_id, score, Some(breakdown)))
        })
        .collect();

    scored.sort_by(|a, b| {
        b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal)
    });

    let existing: i64 = sqlx::query_scalar(
        "SELECT COUNT(*) FROM matches WHERE scholarship_id = $1",
    )
    .bind(scholarship_id)
    .fetch_one(&state.db_pool)
    .await
    .map_err(|e| format!("Mevcut eşleşmeler sayılamadı: {}", e))?;

    let remaining = (quota as i64 - existing).max(0) as usize;
    if remaining == 0 || scored.is_empty() {
        return Ok(0);
    }

    let existing_ids: Vec<Uuid> = sqlx::query_scalar(
        "SELECT student_id FROM matches WHERE scholarship_id = $1",
    )
    .bind(scholarship_id)
    .fetch_all(&state.db_pool)
    .await
    .map_err(|e| format!("Mevcut eşleşme ID'leri alınamadı: {}", e))?;

    let mut count = 0;
    for (student_id, score, breakdown) in &scored {
        if count >= remaining {
            break;
        }
        if existing_ids.contains(student_id) {
            continue;
        }
        let breakdown_json = serde_json::json!({
            "total": score,
            "demo": breakdown.as_ref().map(|b| b.demo),
            "academic": breakdown.as_ref().map(|b| b.academic),
            "need": breakdown.as_ref().map(|b| b.need),
            "extra": breakdown.as_ref().map(|b| b.extra),
        });
        let res = sqlx::query(
            "INSERT INTO matches (scholarship_id, student_id, status, score_breakdown, score_components) VALUES ($1, $2, 'matched', $3, $4) ON CONFLICT (scholarship_id, student_id) DO NOTHING",
        )
        .bind(scholarship_id)
        .bind(student_id)
        .bind(&breakdown_json)
        .bind(&breakdown_json)
        .execute(&state.db_pool)
        .await
        .map_err(|e| format!("Eşleşme kaydedilemedi: {}", e))?;

        if res.rows_affected() > 0 {
            count += 1;
        }
    }

    Ok(count)
}

pub async fn start_matching_scheduler(state: AppState, interval_mins: u64) {
    let mut interval = tokio::time::interval(std::time::Duration::from_secs(interval_mins * 60));
    loop {
        interval.tick().await;
        tracing::info!("Periyodik eşleştirme başlatılıyor...");
        match run_matching(&state).await {
            Ok(n) => tracing::info!("Periyodik eşleştirme tamam: {} yeni eşleşme", n),
            Err(e) => tracing::error!("Periyodik eşleştirme hatası: {}", e),
        }
    }
}
