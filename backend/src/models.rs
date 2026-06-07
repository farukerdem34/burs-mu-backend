use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use sqlx::Type;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq)]
#[repr(i16)]
pub enum IncomeLevel {
    Low = 0,
    Medium = 1,
    High = 2,
}

impl Serialize for IncomeLevel {
    fn serialize<S: serde::Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        serializer.serialize_i16(*self as i16)
    }
}

impl<'de> Deserialize<'de> for IncomeLevel {
    fn deserialize<D: serde::Deserializer<'de>>(deserializer: D) -> Result<Self, D::Error> {
        let val = i16::deserialize(deserializer)?;
        match val {
            0 => Ok(Self::Low),
            1 => Ok(Self::Medium),
            2 => Ok(Self::High),
            _ => Err(serde::de::Error::custom(format!(
                "invalid income level: {}",
                val
            ))),
        }
    }
}

impl sqlx::Type<sqlx::Postgres> for IncomeLevel {
    fn type_info() -> <sqlx::Postgres as sqlx::Database>::TypeInfo {
        <i16 as sqlx::Type<sqlx::Postgres>>::type_info()
    }
}

impl sqlx::Encode<'_, sqlx::Postgres> for IncomeLevel {
    fn encode_by_ref(
        &self,
        buf: &mut sqlx::postgres::PgArgumentBuffer,
    ) -> Result<sqlx::encode::IsNull, Box<dyn std::error::Error + Send + Sync>> {
        <i16 as sqlx::Encode<sqlx::Postgres>>::encode(*self as i16, buf)
    }
}

impl sqlx::Decode<'_, sqlx::Postgres> for IncomeLevel {
    fn decode(
        value: sqlx::postgres::PgValueRef<'_>,
    ) -> Result<Self, Box<dyn std::error::Error + Send + Sync>> {
        let val: i16 = <i16 as sqlx::Decode<sqlx::Postgres>>::decode(value)?;
        match val {
            0 => Ok(Self::Low),
            1 => Ok(Self::Medium),
            2 => Ok(Self::High),
            _ => Err(format!("invalid income level: {}", val).into()),
        }
    }
}

impl sqlx::postgres::PgHasArrayType for IncomeLevel {
    fn array_type_info() -> sqlx::postgres::PgTypeInfo {
        <i16 as sqlx::postgres::PgHasArrayType>::array_type_info()
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, Type)]
#[sqlx(type_name = "user_role", rename_all = "lowercase")]
#[serde(rename_all = "lowercase")]
pub enum UserRole {
    Student,
    Donor,
    Admin,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AcademicStanding {
    Probation,
    Good,
    Honor,
    HighHonor,
}

impl sqlx::Type<sqlx::Postgres> for AcademicStanding {
    fn type_info() -> <sqlx::Postgres as sqlx::Database>::TypeInfo {
        <String as sqlx::Type<sqlx::Postgres>>::type_info()
    }
}

impl sqlx::Encode<'_, sqlx::Postgres> for AcademicStanding {
    fn encode_by_ref(
        &self,
        buf: &mut sqlx::postgres::PgArgumentBuffer,
    ) -> Result<sqlx::encode::IsNull, Box<dyn std::error::Error + Send + Sync>> {
        let s = serde_json::to_value(self)
            .and_then(serde_json::from_value::<String>)
            .unwrap_or_else(|_| "good".to_string());
        <String as sqlx::Encode<sqlx::Postgres>>::encode(s, buf)
    }
}

impl sqlx::Decode<'_, sqlx::Postgres> for AcademicStanding {
    fn decode(
        value: sqlx::postgres::PgValueRef<'_>,
    ) -> Result<Self, Box<dyn std::error::Error + Send + Sync>> {
        let s: String = <String as sqlx::Decode<sqlx::Postgres>>::decode(value)?;
        match s.as_str() {
            "probation" => Ok(Self::Probation),
            "good" => Ok(Self::Good),
            "honor" => Ok(Self::Honor),
            "high_honor" => Ok(Self::HighHonor),
            _ => Ok(Self::Good),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ScholarshipType {
    FullTuition,
    PartialTuition,
    LivingStipend,
    OneTime,
}

impl sqlx::Type<sqlx::Postgres> for ScholarshipType {
    fn type_info() -> <sqlx::Postgres as sqlx::Database>::TypeInfo {
        <String as sqlx::Type<sqlx::Postgres>>::type_info()
    }
}

impl sqlx::Encode<'_, sqlx::Postgres> for ScholarshipType {
    fn encode_by_ref(
        &self,
        buf: &mut sqlx::postgres::PgArgumentBuffer,
    ) -> Result<sqlx::encode::IsNull, Box<dyn std::error::Error + Send + Sync>> {
        let s = serde_json::to_value(self)
            .and_then(serde_json::from_value::<String>)
            .unwrap_or_else(|_| "partial_tuition".to_string());
        <String as sqlx::Encode<sqlx::Postgres>>::encode(s, buf)
    }
}

impl sqlx::Decode<'_, sqlx::Postgres> for ScholarshipType {
    fn decode(
        value: sqlx::postgres::PgValueRef<'_>,
    ) -> Result<Self, Box<dyn std::error::Error + Send + Sync>> {
        let s: String = <String as sqlx::Decode<sqlx::Postgres>>::decode(value)?;
        match s.as_str() {
            "full_tuition" => Ok(Self::FullTuition),
            "partial_tuition" => Ok(Self::PartialTuition),
            "living_stipend" => Ok(Self::LivingStipend),
            "one_time" => Ok(Self::OneTime),
            _ => Ok(Self::PartialTuition),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ApplicationStatus {
    Pending,
    Reviewed,
    Shortlisted,
    Accepted,
    Rejected,
}

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct Student {
    pub profile_id: Uuid,
    pub gpa: Option<f32>,
    pub city: String,
    pub department: String,
    pub income_status: IncomeLevel,
    pub about: Option<String>,
    pub semester: Option<i16>,
    pub family_income: Option<f64>,
    pub household_size: Option<i16>,
    pub num_siblings_in_education: Option<i16>,
    pub has_disability: Option<bool>,
    pub is_orphan: Option<bool>,
    pub is_refugee: Option<bool>,
    pub academic_standing: Option<AcademicStanding>,
    pub extracurricular_score: Option<i16>,
    #[sqlx(default)]
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct Donor {
    pub profile_id: Uuid,
    pub name: Option<String>,
    pub is_verified: bool,
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
    pub amount_per_year: Option<f64>,
    pub duration_months: Option<i32>,
    pub scholarship_type: Option<ScholarshipType>,
    pub preferred_gender: Option<String>,
    pub requires_essay: Option<bool>,
    pub requires_interview: Option<bool>,
    pub accepts_disability: Option<bool>,
    pub accepts_orphan: Option<bool>,
    pub accepts_refugee: Option<bool>,
    pub max_semester: Option<i16>,
    pub min_extracurricular_score: Option<i16>,
    pub max_household_income: Option<f64>,
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, sqlx::FromRow)]
pub struct ScholarshipRule {
    pub id: Uuid,
    pub min_gpa: Option<f32>,
    pub target_cities: Option<Vec<String>>,
    pub target_departments: Option<Vec<String>>,
    pub target_income_levels: Option<Vec<IncomeLevel>>,
    pub preferred_gender: Option<String>,
    pub accepts_disability: Option<bool>,
    pub accepts_orphan: Option<bool>,
    pub accepts_refugee: Option<bool>,
    pub max_semester: Option<i16>,
    pub min_extracurricular_score: Option<i16>,
    pub max_household_income: Option<f64>,
    pub scholarship_type: Option<ScholarshipType>,
}

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct ScholarshipApplication {
    pub id: Uuid,
    pub scholarship_id: Uuid,
    pub student_id: Uuid,
    pub essay_text: Option<String>,
    pub status: Option<String>,
    pub interview_score: Option<i16>,
    pub essay_score: Option<i16>,
    pub applied_at: Option<DateTime<Utc>>,
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
    pub semester: Option<i16>,
    pub family_income: Option<f64>,
    pub household_size: Option<i16>,
    pub num_siblings_in_education: Option<i16>,
    pub has_disability: Option<bool>,
    pub is_orphan: Option<bool>,
    pub is_refugee: Option<bool>,
    pub academic_standing: Option<AcademicStanding>,
    pub extracurricular_score: Option<i16>,
}

#[derive(Debug, Deserialize)]
pub struct UpdateStudentRequest {
    pub gpa: Option<f32>,
    pub city: Option<String>,
    pub department: Option<String>,
    pub income_status: Option<IncomeLevel>,
    pub about: Option<String>,
    pub semester: Option<i16>,
    pub family_income: Option<f64>,
    pub household_size: Option<i16>,
    pub num_siblings_in_education: Option<i16>,
    pub has_disability: Option<bool>,
    pub is_orphan: Option<bool>,
    pub is_refugee: Option<bool>,
    pub academic_standing: Option<AcademicStanding>,
    pub extracurricular_score: Option<i16>,
}

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
    pub role: UserRole,
    pub city: Option<String>,
    pub department: Option<String>,
    pub income_status: Option<IncomeLevel>,
    pub name: Option<String>,
    pub gpa: Option<f32>,
    pub semester: Option<i16>,
    pub family_income: Option<f64>,
    pub household_size: Option<i16>,
    pub num_siblings_in_education: Option<i16>,
    pub has_disability: Option<bool>,
    pub is_orphan: Option<bool>,
    pub is_refugee: Option<bool>,
    pub academic_standing: Option<AcademicStanding>,
    pub extracurricular_score: Option<i16>,
}

#[derive(Debug, Serialize)]
pub struct RegisterResponse {
    pub id: Uuid,
    pub email: String,
    pub role: UserRole,
    pub message: String,
}

#[derive(Debug, Deserialize)]
pub struct CreateScholarshipRequest {
    #[allow(dead_code)]
    pub donor_id: Option<Uuid>,
    pub title: String,
    pub quota: Option<i32>,
    pub is_active: Option<bool>,
    pub min_gpa: Option<f32>,
    pub target_cities: Option<Vec<String>>,
    pub target_departments: Option<Vec<String>>,
    pub target_income_levels: Option<Vec<IncomeLevel>>,
    pub amount_per_year: Option<f64>,
    pub duration_months: Option<i32>,
    pub scholarship_type: Option<ScholarshipType>,
    pub preferred_gender: Option<String>,
    pub requires_essay: Option<bool>,
    pub requires_interview: Option<bool>,
    pub accepts_disability: Option<bool>,
    pub accepts_orphan: Option<bool>,
    pub accepts_refugee: Option<bool>,
    pub max_semester: Option<i16>,
    pub min_extracurricular_score: Option<i16>,
    pub max_household_income: Option<f64>,
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
    pub value: i16,
}

#[derive(Debug, Serialize, sqlx::FromRow)]
pub struct UserRoleRow {
    pub name: String,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct LoginResponse {
    pub id: Uuid,
    pub role: UserRole,
    pub message: String,
}

#[derive(Debug, Serialize)]
pub struct MatchResult {
    pub scholarship_id: Uuid,
    pub score: f32,
}

#[derive(Debug, Serialize)]
pub struct MatchResultDetailed {
    pub scholarship_id: Uuid,
    pub score: f32,
    pub breakdown: ScoreBreakdown,
}

#[derive(Debug, Serialize)]
pub struct ScoreBreakdown {
    pub demo: f32,
    pub academic: f32,
    pub need: f32,
    pub extra: f32,
}
