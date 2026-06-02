use std::env;

#[derive(Debug, Clone)]
pub struct AppConfig {
    pub database_url: String,
    pub server_port: u16,
    pub weight_city: f32,
    pub weight_department: f32,
    pub weight_gpa: f32,
    pub weight_income: f32,
}

impl AppConfig {
    pub fn from_env() -> Self {
        Self {
            database_url: env::var("DATABASE_URL").expect("DATABASE_URL must be set"),
            server_port: env::var("SERVER_PORT")
                .unwrap_or_else(|_| "8080".to_string())
                .parse()
                .expect("SERVER_PORT must be a valid port number"),
            weight_city: env::var("WEIGHT_CITY")
                .unwrap_or_else(|_| "0.3".to_string())
                .parse()
                .expect("WEIGHT_CITY must be a valid f32"),
            weight_department: env::var("WEIGHT_DEPARTMENT")
                .unwrap_or_else(|_| "0.3".to_string())
                .parse()
                .expect("WEIGHT_DEPARTMENT must be a valid f32"),
            weight_gpa: env::var("WEIGHT_GPA")
                .unwrap_or_else(|_| "0.2".to_string())
                .parse()
                .expect("WEIGHT_GPA must be a valid f32"),
            weight_income: env::var("WEIGHT_INCOME")
                .unwrap_or_else(|_| "0.2".to_string())
                .parse()
                .expect("WEIGHT_INCOME must be a valid f32"),
        }
    }
}
