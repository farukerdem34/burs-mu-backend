mod config;
mod engine;
mod handlers;
mod models;
mod state;

use axum::routing::post;
use axum::Router;
use std::net::SocketAddr;
use tracing_subscriber;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    dotenvy::dotenv().ok();

    let config = config::AppConfig::from_env();
    let server_port = config.server_port;
    let state = state::AppState::new(config).await;

    let app = Router::new()
        .route("/match/:student_id", post(handlers::match_student))
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
