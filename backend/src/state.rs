use sqlx::PgPool;

use crate::config::AppConfig;

#[derive(Clone)]
pub struct AppState {
    pub db_pool: PgPool,
    pub config: AppConfig,
}

impl AppState {
    pub async fn new(config: AppConfig) -> Self {
        let db_pool = PgPool::connect(&config.database_url)
            .await
            .expect("Failed to connect to database");
        Self { db_pool, config }
    }
}
