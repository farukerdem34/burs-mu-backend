mod config;
mod engine;
mod handlers;
mod models;
mod state;

use axum::routing::{get, post};
use axum::Router;
use std::net::SocketAddr;
use tower_http::cors::CorsLayer;
use tracing_subscriber;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    dotenvy::dotenv().ok();

    let config = config::AppConfig::from_env();
    let server_port = config.server_port;
    let state = state::AppState::new(config).await;

    let cors = CorsLayer::permissive();

    let app = Router::new()
        .route("/match/:student_id", post(handlers::match_student))
        // AUTH
        .route("/register", post(handlers::register))
        // PROFILES
        .route("/profiles", post(handlers::create_profile).get(handlers::get_profiles))
        .route("/profiles/:id", get(handlers::get_profile))
        // STUDENTS
        .route("/students", post(handlers::create_student).get(handlers::get_students))
        .route("/students/:profile_id", get(handlers::get_student).put(handlers::update_student))
        // DONORS
        .route("/donors", get(handlers::get_donors))
        .route("/donors/:profile_id", get(handlers::get_donor))
        .route("/donors/:profile_id/verify", post(handlers::verify_donor))
        // SCHOLARSHIPS
        .route("/scholarships", post(handlers::create_scholarship).get(handlers::get_scholarships))
        .route("/scholarships/:id", get(handlers::get_scholarship))
        // REFERENCE TABLES
        .route("/cities", get(handlers::get_cities))
        .route("/departments", get(handlers::get_departments))
        .route("/income-levels", get(handlers::get_income_levels))
        .route("/user-roles", get(handlers::get_user_roles))
        .layer(cors)
        .with_state(state);

    let addr: SocketAddr = format!("0.0.0.0:{}", server_port)
        .parse()
        .expect("Invalid address");

    tracing::info!("Starting server on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr)
        .await
        .expect("Failed to bind");

    axum::serve(listener, app)
        .await
        .expect("Server failed");
}
