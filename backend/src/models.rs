use serde::Serialize;
use sqlx::Type;
use uuid::Uuid;

#[derive(Debug, Clone, PartialEq, Serialize, Type)]
#[sqlx(type_name = "income_level", rename_all = "lowercase")]
pub enum IncomeLevel {
    Low,
    Medium,
    High,
}

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct Student {
    pub profile_id: Uuid,
    pub gpa: Option<f32>,
    pub city: String,
    pub department: String,
    pub income_status: IncomeLevel,
}

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct ScholarshipRule {
    pub id: Uuid,
    pub min_gpa: Option<f32>,
    pub target_cities: Option<Vec<String>>,
    pub target_departments: Option<Vec<String>>,
    pub target_income_levels: Option<Vec<IncomeLevel>>,
}

#[derive(Debug, Serialize)]
pub struct MatchResult {
    pub scholarship_id: Uuid,
    pub score: f32,
}
