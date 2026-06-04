pub mod auth;
pub mod config;
pub mod engine;
pub mod handlers;
pub mod matching;
pub mod models;
pub mod state;

use axum::routing::{delete, get, post};
use axum::Router;
use tower_http::cors::CorsLayer;

pub fn build_router(state: state::AppState) -> Router {
    let cors = CorsLayer::permissive();

    Router::new()
        .route("/match/run", post(handlers::run_matching_handler))
        .route("/match/:student_id", post(handlers::match_student))
        .route("/register", post(handlers::register))
        .route("/login", post(handlers::login))
        .route(
            "/profiles",
            post(handlers::create_profile).get(handlers::get_profiles),
        )
        .route("/profiles/:id", get(handlers::get_profile))
        .route(
            "/students",
            post(handlers::create_student).get(handlers::get_students),
        )
        .route(
            "/students/:profile_id",
            get(handlers::get_student).put(handlers::update_student),
        )
        .route("/students/:profile_id/matches", get(handlers::get_student_matches))
        .route("/donors", get(handlers::get_donors))
        .route("/donors/:profile_id", get(handlers::get_donor))
        .route("/donors/:profile_id/verify", post(handlers::verify_donor))
        .route(
            "/scholarships",
            post(handlers::create_scholarship).get(handlers::get_scholarships),
        )
        .route("/scholarships/:id", get(handlers::get_scholarship))
        .route("/cities", get(handlers::get_cities))
        .route(
            "/departments",
            post(handlers::create_department).get(handlers::get_departments),
        )
        .route("/departments/:name", delete(handlers::delete_department))
        .route("/income-levels", get(handlers::get_income_levels))
        .route("/user-roles", get(handlers::get_user_roles))
        .layer(cors)
        .with_state(state)
}
