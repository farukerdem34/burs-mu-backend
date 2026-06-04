use std::net::SocketAddr;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    dotenvy::dotenv().ok();

    let config = burs_mu::config::AppConfig::from_env();
    let server_port = config.server_port;
    let state = burs_mu::state::AppState::new(config).await;

    let matching_interval = state.config.matching_interval_minutes;
    let bg_state = state.clone();
    tokio::spawn(async move {
        burs_mu::matching::start_matching_scheduler(bg_state, matching_interval).await;
    });

    let app = burs_mu::build_router(state);

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
