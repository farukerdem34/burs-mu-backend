use axum::{
    async_trait,
    extract::FromRequestParts,
    http::{request::Parts, StatusCode},
    Json,
};
use serde_json::{json, Value};
use uuid::Uuid;

use crate::models::UserRole;
use crate::state::AppState;

#[derive(Debug, Clone)]
pub struct AuthUser {
    pub id: Uuid,
    pub role: UserRole,
}

#[async_trait]
impl FromRequestParts<AppState> for AuthUser {
    type Rejection = (StatusCode, Json<Value>);

    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        let auth_header = parts
            .headers
            .get("Authorization")
            .and_then(|v| v.to_str().ok())
            .and_then(|v| v.strip_prefix("Bearer "))
            .ok_or_else(|| {
                (
                    StatusCode::UNAUTHORIZED,
                    Json(json!({"error": "Authorization header missing or invalid"})),
                )
            })?;

        let user_id: Uuid = auth_header.parse().map_err(|_| {
            (
                StatusCode::UNAUTHORIZED,
                Json(json!({"error": "Geçersiz token formatı"})),
            )
        })?;

        let profile = sqlx::query_as::<_, (Uuid, UserRole)>(
            "SELECT id, role FROM profiles WHERE id = $1",
        )
        .bind(user_id)
        .fetch_optional(&state.db_pool)
        .await
        .map_err(|_| {
            (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({"error": "Veritabanı hatası"})),
            )
        })?;

        match profile {
            Some((id, role)) => Ok(AuthUser { id, role }),
            None => Err((
                StatusCode::UNAUTHORIZED,
                Json(json!({"error": "Kullanıcı bulunamadı"})),
            )),
        }
    }
}
