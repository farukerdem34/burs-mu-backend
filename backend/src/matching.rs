use crate::engine;
use crate::models::{Scholarship, ScholarshipRule, Student};
use crate::state::AppState;
use uuid::Uuid;

pub async fn run_matching(state: &AppState) -> Result<usize, String> {
    let scholarships = sqlx::query_as::<_, Scholarship>(
        r#"SELECT id, donor_id, title, quota, is_active, min_gpa::float4,
           target_cities, target_departments, target_income_levels, created_at
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
        r#"SELECT profile_id, gpa::float4, city, department, income_status, about, created_at
           FROM students"#,
    )
    .fetch_all(&state.db_pool)
    .await
    .map_err(|e| format!("Öğrenciler alınamadı: {}", e))?;

    let mut scored: Vec<(Uuid, f32)> = students
        .iter()
        .filter_map(|st| {
            engine::calculate_match_score(st, rule, &state.config)
                .map(|score| (st.profile_id, score))
        })
        .collect();

    scored.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));

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
    for (student_id, _) in &scored {
        if count >= remaining {
            break;
        }
        if existing_ids.contains(student_id) {
            continue;
        }
        let res = sqlx::query(
            "INSERT INTO matches (scholarship_id, student_id, status) VALUES ($1, $2, 'matched') ON CONFLICT (scholarship_id, student_id) DO NOTHING",
        )
        .bind(scholarship_id)
        .bind(student_id)
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
