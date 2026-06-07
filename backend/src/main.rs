use std::net::SocketAddr;

#[tokio::main]
async fn main() {
    dotenvy::dotenv().ok();

    let config = burs_mu::config::AppConfig::from_env();

    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::new(&config.log_level))
        .init();

    let host = config.host.clone();
    let server_port = config.server_port;
    let matching_interval = config.matching_interval_minutes;

    let state = burs_mu::state::AppState::new(config).await;

    let bg_state = state.clone();
    tokio::spawn(async move {
        burs_mu::matching::start_matching_scheduler(bg_state, matching_interval).await;
    });

    let app = burs_mu::build_router(state);

    let addr: SocketAddr = format!("{}:{}", host, server_port)
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
