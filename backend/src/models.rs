use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::Type;
use uuid::Uuid;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Type)]
#[sqlx(type_name = "income_level", rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum IncomeLevel {
    Low,
    Medium,
    High,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Type)]
#[sqlx(type_name = "user_role", rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum UserRole {
    Student,
    Donor,
}

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct Student {
    pub profile_id: Uuid,
    pub gpa: Option<f32>,
    pub city: String,
    pub department: String,
    pub income_status: IncomeLevel,
    #[sqlx(default)]
    pub is_verified: Option<bool>,
    #[sqlx(default)]
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct Profile {
    pub id: Uuid,
    pub role: UserRole,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct Scholarship {
    pub id: Uuid,
    pub donor_id: Option<Uuid>,
    pub title: String,
    pub quota: i32,
    pub is_active: Option<bool>,
    pub min_gpa: Option<f32>,
    pub target_cities: Option<Vec<String>>,
    pub target_departments: Option<Vec<String>>,
    pub target_income_levels: Option<Vec<IncomeLevel>>,
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct ScholarshipRule {
    pub id: Uuid,
    pub min_gpa: Option<f32>,
    pub target_cities: Option<Vec<String>>,
    pub target_departments: Option<Vec<String>>,
    pub target_income_levels: Option<Vec<IncomeLevel>>,
}

#[derive(Debug, Deserialize)]
pub struct CreateProfileRequest {
    pub id: Uuid,
    pub role: UserRole,
}

#[derive(Debug, Deserialize)]
pub struct CreateStudentRequest {
    pub profile_id: Uuid,
    pub gpa: Option<f32>,
    pub city: String,
    pub department: String,
    pub income_status: IncomeLevel,
    pub is_verified: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct CreateScholarshipRequest {
    pub donor_id: Option<Uuid>,
    pub title: String,
    pub quota: Option<i32>,
    pub is_active: Option<bool>,
    pub min_gpa: Option<f32>,
    pub target_cities: Option<Vec<String>>,
    pub target_departments: Option<Vec<String>>,
    pub target_income_levels: Option<Vec<IncomeLevel>>,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct City {
    pub name: String,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct Department {
    pub name: String,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct IncomeLevelRow {
    pub name: String,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct UserRoleRow {
    pub name: String,
}

#[derive(Debug, Serialize)]
pub struct MatchResult {
    pub scholarship_id: Uuid,
    pub score: f32,
}
