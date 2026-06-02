use crate::config::AppConfig;
use crate::models::{ScholarshipRule, Student};

pub fn calculate_match_score(
    student: &Student,
    rule: &ScholarshipRule,
    config: &AppConfig,
) -> Option<f32> {
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

    let mut score = 0.0;

    if let Some(ref target_cities) = rule.target_cities {
        if target_cities.contains(&student.city) {
            score += 100.0 * config.weight_city;
        }
    }

    if let Some(ref target_departments) = rule.target_departments {
        if target_departments.contains(&student.department) {
            score += 100.0 * config.weight_department;
        }
    }

    if let Some(ref target_income_levels) = rule.target_income_levels {
        if target_income_levels.contains(&student.income_status) {
            score += 100.0 * config.weight_income;
        }
    }

    if let Some(gpa) = student.gpa {
        let gpa_score = (gpa / 4.0) * 100.0 * config.weight_gpa;
        score += gpa_score;
    }

    Some(score)
}
