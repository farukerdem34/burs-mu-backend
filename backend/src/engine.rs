use crate::config::AppConfig;
use crate::models::{AcademicStanding, IncomeLevel, ScholarshipRule, ScoreBreakdown, Student};

pub fn calculate_match_score(
    student: &Student,
    rule: &ScholarshipRule,
    config: &AppConfig,
) -> Option<f32> {
    let breakdown = calculate_breakdown(student, rule, config)?;
    let total = breakdown.demo + breakdown.academic + breakdown.need + breakdown.extra;
    Some((total * 100.0).min(100.0))
}

pub fn calculate_match_score_detailed(
    student: &Student,
    rule: &ScholarshipRule,
    config: &AppConfig,
) -> Option<(f32, ScoreBreakdown)> {
    let breakdown = calculate_breakdown(student, rule, config)?;
    let total = breakdown.demo + breakdown.academic + breakdown.need + breakdown.extra;
    Some(((total * 100.0).min(100.0), breakdown))
}

fn calculate_breakdown(
    student: &Student,
    rule: &ScholarshipRule,
    config: &AppConfig,
) -> Option<ScoreBreakdown> {
    // ── Elimination Phase ──────────────────────────────────
    if let Some(ref target_cities) = rule.target_cities {
        if !target_cities.is_empty() && !target_cities.contains(&student.city) {
            return None;
        }
    }

    if let Some(ref target_departments) = rule.target_departments {
        if !target_departments.is_empty() && !target_departments.contains(&student.department) {
            return None;
        }
    }

    if let Some(ref target_income_levels) = rule.target_income_levels {
        if !target_income_levels.is_empty()
            && !target_income_levels.contains(&student.income_status)
        {
            return None;
        }
    }

    if let Some(min_gpa) = rule.min_gpa {
        if min_gpa > 0.0 {
            if let Some(gpa) = student.gpa {
                if gpa < min_gpa {
                    return None;
                }
            } else {
                return None;
            }
        }
    }

    if let Some(ref preferred_gender) = rule.preferred_gender {
        if !preferred_gender.is_empty() {
            let student_gender = student_gender_from_about(student);
            if let Some(ref sg) = student_gender {
                if sg != preferred_gender {
                    return None;
                }
            }
        }
    }

    if let Some(max_sem) = rule.max_semester {
        if max_sem > 0 {
            if let Some(sem) = student.semester {
                if sem > max_sem {
                    return None;
                }
            }
        }
    }

    if let Some(min_extra) = rule.min_extracurricular_score {
        if min_extra > 0 {
            if let Some(extra) = student.extracurricular_score {
                if extra < min_extra {
                    return None;
                }
            }
        }
    }

    if let Some(max_income) = rule.max_household_income {
        if max_income > 0.0 {
            if let Some(fam_income) = student.family_income {
                if fam_income > max_income {
                    return None;
                }
            }
        }
    }

    if let Some(accepts) = rule.accepts_disability {
        if !accepts && student.has_disability.unwrap_or(false) {
            return None;
        }
    }

    if let Some(accepts) = rule.accepts_orphan {
        if !accepts && student.is_orphan.unwrap_or(false) {
            return None;
        }
    }

    if let Some(accepts) = rule.accepts_refugee {
        if !accepts && student.is_refugee.unwrap_or(false) {
            return None;
        }
    }

    // ── Scoring Phase ──────────────────────────────────────
    let (w_demo, w_academic, w_need, w_extra) = config.normalized_weights();

    // 1. Demographic Fit
    let demo = demographic_score(student, rule) * w_demo;

    // 2. Academic Fit
    let academic = academic_score(student, rule) * w_academic;

    // 3. Financial Need
    let need = financial_need_score(student, rule) * w_need;

    // 4. Extra-curricular
    let extra = extracurricular_score(student, rule) * w_extra;

    Some(ScoreBreakdown {
        demo,
        academic,
        need,
        extra,
    })
}

// ── Category helpers ──────────────────────────────────────

fn demographic_score(student: &Student, rule: &ScholarshipRule) -> f32 {
    let mut score = 0.0;
    let mut count = 0;

    // City match
    if let Some(ref target_cities) = rule.target_cities {
        if !target_cities.is_empty() {
            if target_cities.contains(&student.city) {
                score += 1.0;
            }
            count += 1;
        }
    }

    // Income level match
    if let Some(ref target_income) = rule.target_income_levels {
        if !target_income.is_empty() {
            if target_income.contains(&student.income_status) {
                score += 1.0;
            }
            count += 1;
        }
    }

    if count == 0 {
        return 1.0;
    }

    score / count as f32
}

fn academic_score(student: &Student, rule: &ScholarshipRule) -> f32 {
    let mut components = Vec::new();

    // GPA (proportional above minimum)
    if let Some(gpa) = student.gpa {
        let min_gpa = rule.min_gpa.unwrap_or(0.0);
        let raw = if min_gpa > 0.0 && gpa >= min_gpa {
            ((gpa - min_gpa) / (4.0 - min_gpa)) * 100.0 / 100.0
        } else {
            (gpa / 4.0) * 100.0 / 100.0
        };
        components.push((raw, 0.6));
    }

    // Semester position (earlier = more benefit time)
    if let Some(sem) = student.semester {
        let sem_score = (8.0_f32.max(0.0) - sem as f32).max(0.0) / 8.0;
        components.push((sem_score, 0.2));
    }

    // Academic standing bonus
    if let Some(ref standing) = student.academic_standing {
        let bonus = match standing {
            AcademicStanding::HighHonor => 0.2,
            AcademicStanding::Honor => 0.1,
            AcademicStanding::Good => 0.0,
            AcademicStanding::Probation => -0.3,
        };
        components.push((1.0 + bonus, 0.2));
    }

    if components.is_empty() {
        return 0.5;
    }

    let total_weight: f32 = components.iter().map(|(_, w)| w).sum();
    let weighted: f32 = components.iter().map(|(s, w)| s * w).sum();
    (weighted / total_weight).clamp(0.0, 1.0)
}

fn financial_need_score(student: &Student, rule: &ScholarshipRule) -> f32 {
    let mut components = Vec::new();

    // Family income vs max household income
    if let Some(fam_income) = student.family_income {
        let max_income = rule.max_household_income.unwrap_or(500000.0);
        if max_income > 0.0 && fam_income < max_income {
            let ratio = 1.0 - (fam_income / max_income) as f32;
            components.push((ratio, 0.40));
        } else if max_income > 0.0 {
            components.push((0.0, 0.40));
        }
    }

    // Income level
    let inc_score = match student.income_status {
        IncomeLevel::Low => 1.0,
        IncomeLevel::Medium => 0.5,
        IncomeLevel::High => 0.0,
    };
    components.push((inc_score, 0.25));

    // Num siblings in education
    if let Some(sibs) = student.num_siblings_in_education {
        let sib_score = (sibs as f32).min(5.0) / 5.0;
        components.push((sib_score, 0.15));
    }

    // Orphan bonus
    if student.is_orphan.unwrap_or(false) {
        components.push((1.0, 0.10));
    }

    // Refugee bonus
    if student.is_refugee.unwrap_or(false) {
        components.push((1.0, 0.10));
    }

    if components.is_empty() {
        return 0.5;
    }

    let total_weight: f32 = components.iter().map(|(_, w)| w).sum();
    let weighted: f32 = components.iter().map(|(s, w)| s * w).sum();
    (weighted / total_weight).clamp(0.0, 1.0)
}

fn extracurricular_score(_student: &Student, _rule: &ScholarshipRule) -> f32 {
    let extra = _student.extracurricular_score.unwrap_or(0) as f32;
    extra / 10.0
}

fn student_gender_from_about(student: &Student) -> Option<String> {
    if let Some(ref about) = student.about {
        let lower = about.to_lowercase();
        if lower.contains("kadın") || lower.contains("kiz") || lower.contains("kadın") {
            return Some("female".to_string());
        }
        if lower.contains("erkek") || lower.contains("adam") {
            return Some("male".to_string());
        }
    }
    None
}
