use crate::config::AppConfig;
use crate::models::{AcademicStanding, IncomeLevel, ScholarshipRule, ScoreBreakdown, Student};
use std::f32::consts::E;

const EPSILON: f32 = 1e-7;

pub fn calculate_match_score(
    student: &Student,
    rule: &ScholarshipRule,
    config: &AppConfig,
) -> Option<f32> {
    let breakdown = calculate_breakdown(student, rule)?;
    let total = weighted_geometric_mean(
        breakdown.demo,
        breakdown.academic,
        breakdown.need,
        breakdown.extra,
        config,
    );
    Some((total * 100.0).min(100.0))
}

pub fn calculate_match_score_detailed(
    student: &Student,
    rule: &ScholarshipRule,
    config: &AppConfig,
) -> Option<(f32, ScoreBreakdown)> {
    let breakdown = calculate_breakdown(student, rule)?;
    let total = weighted_geometric_mean(
        breakdown.demo,
        breakdown.academic,
        breakdown.need,
        breakdown.extra,
        config,
    );
    Some(((total * 100.0).min(100.0), breakdown))
}

fn weighted_geometric_mean(
    demo: f32,
    academic: f32,
    need: f32,
    extra: f32,
    config: &AppConfig,
) -> f32 {
    let (w_demo, w_academic, w_need, w_extra) = config.normalized_weights();
    let log_sum = w_demo * (demo + EPSILON).ln()
        + w_academic * (academic + EPSILON).ln()
        + w_need * (need + EPSILON).ln()
        + w_extra * (extra + EPSILON).ln();
    log_sum.exp()
}

fn sigmoid(value: f32, midpoint: f32, steepness: f32) -> f32 {
    1.0 / (1.0 + E.powf(-steepness * (value - midpoint)))
}

fn calculate_breakdown(
    student: &Student,
    rule: &ScholarshipRule,
) -> Option<ScoreBreakdown> {
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

    let demo = demographic_score(student, rule);
    let academic = academic_score(student, rule);
    let need = financial_need_score(student, rule);
    let extra = extracurricular_score(student, rule);

    Some(ScoreBreakdown {
        demo,
        academic,
        need,
        extra,
    })
}

fn demographic_score(student: &Student, rule: &ScholarshipRule) -> f32 {
    let mut score = 0.0;
    let mut count = 0;

    if let Some(ref target_cities) = rule.target_cities {
        if !target_cities.is_empty() {
            if target_cities.contains(&student.city) {
                score += 1.0;
            }
            count += 1;
        }
    }

    if let Some(ref target_income) = rule.target_income_levels {
        if !target_income.is_empty() {
            if target_income.contains(&student.income_status) {
                score += 1.0;
            }
            count += 1;
        }
    }

    if count == 0 {
        return 0.5;
    }

    score / count as f32
}

fn academic_score(student: &Student, rule: &ScholarshipRule) -> f32 {
    let mut components = Vec::new();

    if let Some(gpa) = student.gpa {
        let min_gpa = rule.min_gpa.unwrap_or(0.0);
        let (midpoint, k) = if min_gpa > 0.0 {
            (min_gpa + (4.0 - min_gpa) * 0.3, 4.0)
        } else {
            (2.5, 2.5)
        };
        let gpa_score = sigmoid(gpa, midpoint, k);
        components.push((gpa_score, 0.6));
    }

    if let Some(sem) = student.semester {
        if sem > 0 {
            let sem_score = sigmoid(sem as f32, 4.0, -0.4);
            components.push((sem_score, 0.2));
        }
    }

    if let Some(ref standing) = student.academic_standing {
        let standing_score = match standing {
            AcademicStanding::HighHonor => 1.0,
            AcademicStanding::Honor => 0.8,
            AcademicStanding::Good => 0.5,
            AcademicStanding::Probation => 0.1,
        };
        components.push((standing_score, 0.2));
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

    if let Some(fam_income) = student.family_income {
        let max_income = rule.max_household_income.unwrap_or(500000.0);
        if max_income > 0.0 {
            let ratio = fam_income as f32 / max_income as f32;
            let need_score = 1.0 - sigmoid(ratio, 0.5, 5.0);
            components.push((need_score, 0.40));
        }
    }

    let inc_score = match student.income_status {
        IncomeLevel::Low => 1.0,
        IncomeLevel::Medium => 0.5,
        IncomeLevel::High => 0.05,
    };
    components.push((inc_score, 0.25));

    if let Some(sibs) = student.num_siblings_in_education {
        let sib_score = (sibs as f32).min(5.0) / 5.0;
        components.push((sib_score, 0.15));
    }

    if student.is_orphan.unwrap_or(false) {
        components.push((1.0, 0.10));
    }

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

fn extracurricular_score(student: &Student, _rule: &ScholarshipRule) -> f32 {
    let score = student.extracurricular_score.unwrap_or(0) as f32;
    sigmoid(score, 5.0, 1.0)
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
