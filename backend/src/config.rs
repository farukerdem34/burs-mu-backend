use std::env;

#[derive(Debug, Clone)]
pub struct AppConfig {
    pub database_url: String,
    pub server_port: u16,
    pub supabase_url: String,
    pub supabase_anon_key: String,
    pub weight_demo: f32,
    pub weight_academic: f32,
    pub weight_need: f32,
    pub weight_extra: f32,
    pub matching_interval_minutes: u64,
}

impl AppConfig {
    pub fn from_env() -> Self {
        Self {
            database_url: env::var("DATABASE_URL").expect("DATABASE_URL must be set"),
            server_port: env::var("SERVER_PORT")
                .unwrap_or_else(|_| "8080".to_string())
                .parse()
                .expect("SERVER_PORT must be a valid port number"),
            supabase_url: env::var("SUPABASE_URL").expect("SUPABASE_URL must be set"),
            supabase_anon_key: env::var("SUPABASE_ANON_KEY")
                .expect("SUPABASE_ANON_KEY must be set"),
            weight_demo: env::var("WEIGHT_DEMO")
                .unwrap_or_else(|_| "0.30".to_string())
                .parse()
                .expect("WEIGHT_DEMO must be a valid f32"),
            weight_academic: env::var("WEIGHT_ACADEMIC")
                .unwrap_or_else(|_| "0.30".to_string())
                .parse()
                .expect("WEIGHT_ACADEMIC must be a valid f32"),
            weight_need: env::var("WEIGHT_NEED")
                .unwrap_or_else(|_| "0.25".to_string())
                .parse()
                .expect("WEIGHT_NEED must be a valid f32"),
            weight_extra: env::var("WEIGHT_EXTRA")
                .unwrap_or_else(|_| "0.15".to_string())
                .parse()
                .expect("WEIGHT_EXTRA must be a valid f32"),
            matching_interval_minutes: env::var("MATCHING_INTERVAL_MINUTES")
                .unwrap_or_else(|_| "30".to_string())
                .parse()
                .expect("MATCHING_INTERVAL_MINUTES must be a valid u64"),
        }
    }
}
