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

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct Student {
    pub profile_id: Uuid,
    pub gpa: Option<f32>,
    pub city: String,
    pub department: String,
    pub income_status: IncomeLevel,
    pub about: Option<String>,
    #[sqlx(default)]
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct Donor {
    pub profile_id: Uuid,
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
}

#[derive(Debug, Deserialize)]
pub struct UpdateStudentRequest {
    pub gpa: Option<f32>,
    pub city: Option<String>,
    pub department: Option<String>,
    pub income_status: Option<IncomeLevel>,
    pub about: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub email: String,
    pub password: String,
    pub role: UserRole,
    pub city: Option<String>,
    pub department: Option<String>,
    pub income_status: Option<IncomeLevel>,
    pub gpa: Option<f32>,
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
