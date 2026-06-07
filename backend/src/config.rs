use serde::Deserialize;

fn default_host() -> String { "0.0.0.0".into() }
fn default_server_port() -> u16 { 8080 }
fn default_db_pool_min() -> u32 { 1 }
fn default_db_pool_max() -> u32 { 5 }
fn default_db_acquire_timeout() -> u64 { 30 }
fn default_db_test_before_acquire() -> bool { false }
fn default_weight() -> f32 { 0.30 }
fn default_weight_need() -> f32 { 0.25 }
fn default_weight_extra() -> f32 { 0.15 }
fn default_matching_interval() -> u64 { 30 }
fn default_department_similarity() -> f64 { 0.8 }
fn default_allowed_origins() -> Vec<String> { vec!["*".into()] }
fn default_log_level() -> String { "info".into() }

fn from_comma_list<'de, D>(deserializer: D) -> Result<Vec<String>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    let s = String::deserialize(deserializer)?;
    if s.trim() == "*" {
        return Ok(vec!["*".to_string()]);
    }
    Ok(s.split(',')
        .map(|part| part.trim().to_string())
        .filter(|part| !part.is_empty())
        .collect())
}

#[derive(Debug, Clone, Deserialize)]
pub struct AppConfig {
    #[serde(default = "default_host")]
    pub host: String,

    #[serde(default = "default_server_port")]
    pub server_port: u16,

    pub database_url: String,

    #[serde(default = "default_db_pool_min")]
    pub db_pool_min: u32,

    #[serde(default = "default_db_pool_max")]
    pub db_pool_max: u32,

    #[serde(default = "default_db_acquire_timeout")]
    pub db_acquire_timeout_secs: u64,

    #[serde(default = "default_db_test_before_acquire")]
    pub db_test_before_acquire: bool,

    pub supabase_url: String,
    pub supabase_anon_key: String,

    #[serde(default = "default_weight")]
    pub weight_demo: f32,

    #[serde(default = "default_weight")]
    pub weight_academic: f32,

    #[serde(default = "default_weight_need")]
    pub weight_need: f32,

    #[serde(default = "default_weight_extra")]
    pub weight_extra: f32,

    #[serde(default = "default_matching_interval")]
    pub matching_interval_minutes: u64,

    #[serde(default = "default_department_similarity")]
    pub department_similarity_threshold: f64,

    #[serde(default = "default_allowed_origins", deserialize_with = "from_comma_list")]
    pub allowed_origins: Vec<String>,

    #[serde(default = "default_log_level")]
    pub log_level: String,
}

impl AppConfig {
    pub fn from_env() -> Self {
        envy::from_env().expect("Failed to load configuration from environment variables")
    }

    pub fn normalized_weights(&self) -> (f32, f32, f32, f32) {
        let norm = self.weight_demo + self.weight_academic + self.weight_need + self.weight_extra;
        if norm == 0.0 {
            return (0.25, 0.25, 0.25, 0.25);
        }
        (
            self.weight_demo / norm,
            self.weight_academic / norm,
            self.weight_need / norm,
            self.weight_extra / norm,
        )
    }
}
