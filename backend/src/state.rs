use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;

use crate::config::AppConfig;

#[derive(Clone)]
pub struct AppState {
    pub db_pool: PgPool,
    pub config: AppConfig,
}

impl AppState {
    pub async fn new(config: AppConfig) -> Self {
        let db_pool = PgPoolOptions::new()
            .min_connections(config.db_pool_min)
            .max_connections(config.db_pool_max)
            .acquire_timeout(std::time::Duration::from_secs(config.db_acquire_timeout_secs))
            .test_before_acquire(config.db_test_before_acquire)
            .connect(&config.database_url)
            .await
            .expect("Failed to connect to database");
        Self { db_pool, config }
    }
}
