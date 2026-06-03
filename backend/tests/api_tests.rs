use std::net::SocketAddr;

use axum::Router;
use reqwest::{Client, StatusCode};
use tokio::net::TcpListener;
use uuid::Uuid;

use burs_mu::config::AppConfig;
use burs_mu::state::AppState;

// ── Helpers ──────────────────────────────────────

struct TestContext {
    client: Client,
    base: String,
    admin_id: Uuid,
}

async fn setup() -> TestContext {
    dotenvy::dotenv().ok();
    let config = AppConfig::from_env();
    let state = AppState::new(config).await;
    let app = build_router(state);

    let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr: SocketAddr = listener.local_addr().unwrap();
    let base = format!("http://{}", addr);

    tokio::spawn(async move {
        axum::serve(listener, app).await.unwrap();
    });

    // Give the server a moment to start
    tokio::time::sleep(std::time::Duration::from_millis(100)).await;

    // Admin ID known from our DB seeding
    let admin_id =
        Uuid::parse_str("b3aecf7e-f3de-4dad-9ca8-7e538bd34900").expect("hardcoded admin uuid");
    let binding = TestContext {
        client: Client::new(),
        base,
        admin_id,
    };
    // Confirm server is alive
    let resp = binding
        .client
        .get(&format!("{}/cities", binding.base))
        .send()
        .await
        .expect("server should be reachable");
    assert!(resp.status().is_success(), "server not reachable");
    binding
}

fn build_router(state: AppState) -> Router {
    let cors = tower_http::cors::CorsLayer::permissive();
    Router::new()
        .route("/match/:student_id", axum::routing::post(burs_mu::handlers::match_student))
        .route("/register", axum::routing::post(burs_mu::handlers::register))
        .route("/login", axum::routing::post(burs_mu::handlers::login))
        .route("/profiles", axum::routing::post(burs_mu::handlers::create_profile).get(burs_mu::handlers::get_profiles))
        .route("/profiles/:id", axum::routing::get(burs_mu::handlers::get_profile))
        .route("/students", axum::routing::post(burs_mu::handlers::create_student).get(burs_mu::handlers::get_students))
        .route("/students/:profile_id", axum::routing::get(burs_mu::handlers::get_student).put(burs_mu::handlers::update_student))
        .route("/donors", axum::routing::get(burs_mu::handlers::get_donors))
        .route("/donors/:profile_id", axum::routing::get(burs_mu::handlers::get_donor))
        .route("/donors/:profile_id/verify", axum::routing::post(burs_mu::handlers::verify_donor))
        .route("/scholarships", axum::routing::post(burs_mu::handlers::create_scholarship).get(burs_mu::handlers::get_scholarships))
        .route("/scholarships/:id", axum::routing::get(burs_mu::handlers::get_scholarship))
        .route("/cities", axum::routing::get(burs_mu::handlers::get_cities))
        .route("/departments", axum::routing::get(burs_mu::handlers::get_departments))
        .route("/departments/:name", axum::routing::delete(burs_mu::handlers::delete_department))
        .route("/income-levels", axum::routing::get(burs_mu::handlers::get_income_levels))
        .route("/user-roles", axum::routing::get(burs_mu::handlers::get_user_roles))
        .layer(cors)
        .with_state(state)
}

// ── Test entry point ─────────────────────────────

#[tokio::test]
async fn full_api_test_suite() {
    let ctx = setup().await;

    reference_endpoints(&ctx).await;
    auth_endpoints(&ctx).await;
    profile_endpoints(&ctx).await;
    student_endpoints(&ctx).await;
    donor_endpoints(&ctx).await;
    scholarship_endpoints(&ctx).await;
    match_endpoint(&ctx).await;
    department_delete_endpoint(&ctx).await;
}

// ── 1. Reference Endpoints ───────────────────────

async fn reference_endpoints(ctx: &TestContext) {
    // GET /cities
    let resp = ctx.client.get(&format!("{}/cities", ctx.base)).send().await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let cities: Vec<serde_json::Value> = resp.json().await.unwrap();
    assert!(cities.len() >= 80, "expected ≥80 cities, got {}", cities.len());
    eprintln!("  ✅ /cities → {} cities", cities.len());

    // GET /departments
    let resp = ctx.client.get(&format!("{}/departments", ctx.base)).send().await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let depts: Vec<serde_json::Value> = resp.json().await.unwrap();
    assert!(depts.len() >= 5, "expected ≥5 departments, got {}", depts.len());
    eprintln!("  ✅ /departments → {} departments", depts.len());

    // GET /income-levels
    let resp = ctx.client.get(&format!("{}/income-levels", ctx.base)).send().await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let levels: Vec<serde_json::Value> = resp.json().await.unwrap();
    assert_eq!(levels.len(), 3, "expected 3 income levels");
    eprintln!("  ✅ /income-levels → 3 levels");

    // GET /user-roles
    let resp = ctx.client.get(&format!("{}/user-roles", ctx.base)).send().await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let roles: Vec<serde_json::Value> = resp.json().await.unwrap();
    assert_eq!(roles.len(), 3, "expected 3 roles (student, donor, admin)");
    eprintln!("  ✅ /user-roles → 3 roles");
}

// ── 2. Auth Endpoints ────────────────────────────

async fn auth_endpoints(ctx: &TestContext) {
    let ts = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs();

    // Register student
    let student_email = format!("test_student_{ts}@test.com");
    let resp = ctx
        .client
        .post(&format!("{}/register", ctx.base))
        .json(&serde_json::json!({
            "email": student_email,
            "password": "Test123456!",
            "role": "student",
            "city": "İstanbul",
            "department": "Bilgisayar Mühendisliği",
            "income_status": "low",
            "gpa": 3.5,
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CREATED);
    let student: serde_json::Value = resp.json().await.unwrap();
    let student_id: Uuid = student["id"].as_str().unwrap().parse().unwrap();
    assert_eq!(student["role"], "student");
    eprintln!("  ✅ /register (student) → id={student_id}");

    // Register donor
    let donor_email = format!("test_donor_{ts}@test.com");
    let resp = ctx
        .client
        .post(&format!("{}/register", ctx.base))
        .json(&serde_json::json!({
            "email": donor_email,
            "password": "Test123456!",
            "role": "donor",
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CREATED);
    let donor: serde_json::Value = resp.json().await.unwrap();
    let donor_id: Uuid = donor["id"].as_str().unwrap().parse().unwrap();
    assert_eq!(donor["role"], "donor");
    eprintln!("  ✅ /register (donor) → id={donor_id}");

    // Duplicate register → 409
    let resp = ctx
        .client
        .post(&format!("{}/register", ctx.base))
        .json(&serde_json::json!({
            "email": student_email,
            "password": "Test123456!",
            "role": "student",
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CONFLICT);
    eprintln!("  ✅ /register (duplicate) → 409");

    // Login student
    let resp = ctx
        .client
        .post(&format!("{}/login", ctx.base))
        .json(&serde_json::json!({
            "email": student_email,
            "password": "Test123456!",
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let login_resp: serde_json::Value = resp.json().await.unwrap();
    let login_id: Uuid = login_resp["id"].as_str().unwrap().parse().unwrap();
    assert_eq!(login_id, student_id);
    assert_eq!(login_resp["role"], "student");
    eprintln!("  ✅ /login (student) → id matches");

    // Login donor
    let resp = ctx
        .client
        .post(&format!("{}/login", ctx.base))
        .json(&serde_json::json!({
            "email": donor_email,
            "password": "Test123456!",
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let login_d: serde_json::Value = resp.json().await.unwrap();
    let login_did: Uuid = login_d["id"].as_str().unwrap().parse().unwrap();
    assert_eq!(login_did, donor_id);
    assert_eq!(login_d["role"], "donor");
    eprintln!("  ✅ /login (donor) → id matches");

    // Login wrong password → 401
    let resp = ctx
        .client
        .post(&format!("{}/login", ctx.base))
        .json(&serde_json::json!({
            "email": student_email,
            "password": "wrongpassword",
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
    eprintln!("  ✅ /login (wrong pw) → 401");

    // Login nonexistent → 401
    let resp = ctx
        .client
        .post(&format!("{}/login", ctx.base))
        .json(&serde_json::json!({
            "email": "noone@nonexistent.com",
            "password": "Test123456!",
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
    eprintln!("  ✅ /login (nonexistent) → 401");
}

// ── 3. Profile Endpoints ─────────────────────────

async fn profile_endpoints(ctx: &TestContext) {
    // GET /profiles
    let resp = ctx.client.get(&format!("{}/profiles", ctx.base)).send().await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let profiles: Vec<serde_json::Value> = resp.json().await.unwrap();
    assert!(profiles.len() >= 8, "expected ≥8 profiles");
    assert!(profiles[0].get("id").unwrap().is_string());
    eprintln!("  ✅ /profiles → {} profiles", profiles.len());

    // GET /profiles/{id} (non-existent) → 404
    let resp = ctx
        .client
        .get(&format!("{}/profiles/00000000-0000-0000-0000-000000000000", ctx.base))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
    eprintln!("  ✅ /profiles (nonexistent) → 404");

    // POST /profiles (no auth user → FK violation → 500)
    let resp = ctx
        .client
        .post(&format!("{}/profiles", ctx.base))
        .json(&serde_json::json!({
            "id": "00000000-0000-0000-0000-000000000001",
            "role": "student",
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::INTERNAL_SERVER_ERROR);
    eprintln!("  ✅ POST /profiles (no auth user) → 500");

    // POST /profiles (admin role → 400)
    let resp = ctx
        .client
        .post(&format!("{}/profiles", ctx.base))
        .json(&serde_json::json!({
            "id": "00000000-0000-0000-0000-000000000001",
            "role": "admin",
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
    eprintln!("  ✅ POST /profiles (admin role) → 400");
}

// ── 4. Student Endpoints ─────────────────────────

async fn student_endpoints(ctx: &TestContext) {
    // Register a fresh student for this test block
    let ts = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs();
    let email = format!("student_test_{ts}@test.com");
    let resp = ctx
        .client
        .post(&format!("{}/register", ctx.base))
        .json(&serde_json::json!({
            "email": email,
            "password": "Test123456!",
            "role": "student",
            "city": "İstanbul",
            "department": "Bilgisayar Mühendisliği",
            "income_status": "low",
            "gpa": 3.5,
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CREATED);
    let student: serde_json::Value = resp.json().await.unwrap();
    let student_id: Uuid = student["id"].as_str().unwrap().parse().unwrap();

    // GET /students
    let resp = ctx.client.get(&format!("{}/students", ctx.base)).send().await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let students: Vec<serde_json::Value> = resp.json().await.unwrap();
    assert!(students.len() >= 2);
    eprintln!("  ✅ /students → {} students", students.len());

    // GET /students/{id}
    let resp = ctx
        .client
        .get(&format!("{}/students/{student_id}", ctx.base))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let s: serde_json::Value = resp.json().await.unwrap();
    assert_eq!(s["profile_id"].as_str().unwrap(), student_id.to_string().as_str());
    assert_eq!(s["city"], "İstanbul");
    eprintln!("  ✅ /students/{student_id} → profile_id matches, city: İstanbul");

    // GET /students (non-existent) → 404
    let resp = ctx
        .client
        .get(&format!("{}/students/00000000-0000-0000-0000-000000000000", ctx.base))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
    eprintln!("  ✅ /students (nonexistent) → 404");

    // PUT /students/{id} (update GPA + about)
    let resp = ctx
        .client
        .put(&format!("{}/students/{student_id}", ctx.base))
        .header("Authorization", format!("Bearer {student_id}"))
        .json(&serde_json::json!({
            "gpa": 3.8,
            "about": "Test ogrenciyim",
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let s: serde_json::Value = resp.json().await.unwrap();
    assert_eq!(s["gpa"].as_f64().unwrap(), 3.8);
    assert_eq!(s["about"], "Test ogrenciyim");
    eprintln!("  ✅ PUT /students → GPA 3.8, about set");

    // PUT /students/{id} (partial update — only about)
    let resp = ctx
        .client
        .put(&format!("{}/students/{student_id}", ctx.base))
        .header("Authorization", format!("Bearer {student_id}"))
        .json(&serde_json::json!({
            "about": "Guncellenen metin",
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let s: serde_json::Value = resp.json().await.unwrap();
    assert_eq!(s["gpa"].as_f64().unwrap(), 3.8, "GPA should be preserved");
    assert_eq!(s["about"], "Guncellenen metin");
    eprintln!("  ✅ PUT /students (partial) → GPA preserved, about updated");

    // POST /students (create for existing profile without student record)
    let email2 = format!("student_post_{ts}@test.com");
    let resp = ctx
        .client
        .post(&format!("{}/register", ctx.base))
        .json(&serde_json::json!({
            "email": email2,
            "password": "Test123456!",
            "role": "student",
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CREATED);
    let s2: serde_json::Value = resp.json().await.unwrap();
    let sid2: Uuid = s2["id"].as_str().unwrap().parse().unwrap();

    let resp = ctx
        .client
        .post(&format!("{}/students", ctx.base))
        .header("Authorization", format!("Bearer {sid2}"))
        .json(&serde_json::json!({
            "profile_id": sid2,
            "city": "Ankara",
            "department": "Elektrik Mühendisliği",
            "income_status": "medium",
            "gpa": 2.5,
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CREATED);
    let s_created: serde_json::Value = resp.json().await.unwrap();
    assert_eq!(s_created["profile_id"].as_str().unwrap(), sid2.to_string().as_str());
    assert_eq!(s_created["city"], "Ankara");
    assert_eq!(s_created["department"], "Elektrik Mühendisliği");
    eprintln!("  ✅ POST /students → created student with Ankara/Elektrik");
}

// ── 5. Donor Endpoints ───────────────────────────

async fn donor_endpoints(ctx: &TestContext) {
    let ts = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs();
    let email = format!("donor_test_{ts}@test.com");
    let resp = ctx
        .client
        .post(&format!("{}/register", ctx.base))
        .json(&serde_json::json!({
            "email": email,
            "password": "Test123456!",
            "role": "donor",
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CREATED);
    let donor: serde_json::Value = resp.json().await.unwrap();
    let donor_id: Uuid = donor["id"].as_str().unwrap().parse().unwrap();

    // GET /donors
    let resp = ctx.client.get(&format!("{}/donors", ctx.base)).send().await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let donors: Vec<serde_json::Value> = resp.json().await.unwrap();
    assert!(donors.len() >= 2);
    eprintln!("  ✅ /donors → {} donors", donors.len());

    // GET /donors/{id}
    let resp = ctx
        .client
        .get(&format!("{}/donors/{donor_id}", ctx.base))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let d: serde_json::Value = resp.json().await.unwrap();
    assert_eq!(d["profile_id"].as_str().unwrap(), donor_id.to_string().as_str());
    eprintln!("  ✅ /donors/{donor_id} → profile_id matches");

    // GET /donors (non-existent) → 404
    let resp = ctx
        .client
        .get(&format!("{}/donors/00000000-0000-0000-0000-000000000000", ctx.base))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
    eprintln!("  ✅ /donors (nonexistent) → 404");

    // POST /donors/{id}/verify (admin)
    let resp = ctx
        .client
        .post(&format!("{}/donors/{donor_id}/verify", ctx.base))
        .header("Authorization", format!("Bearer {}", ctx.admin_id))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v: serde_json::Value = resp.json().await.unwrap();
    assert_eq!(v["is_verified"], true);
    eprintln!("  ✅ /donors/verify (admin) → donor verified");

    // POST /donors/{id}/verify (non-admin → 403)
    let resp = ctx
        .client
        .post(&format!("{}/donors/{donor_id}/verify", ctx.base))
        .header("Authorization", format!("Bearer {donor_id}"))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::FORBIDDEN);
    eprintln!("  ✅ /donors/verify (non-admin) → 403");
}

// ── 6. Scholarship Endpoints ─────────────────────

async fn scholarship_endpoints(ctx: &TestContext) {
    let ts = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs();
    let email = format!("scholar_donor_{ts}@test.com");
    let resp = ctx
        .client
        .post(&format!("{}/register", ctx.base))
        .json(&serde_json::json!({
            "email": email,
            "password": "Test123456!",
            "role": "donor",
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CREATED);
    let donor: serde_json::Value = resp.json().await.unwrap();
    let donor_id: Uuid = donor["id"].as_str().unwrap().parse().unwrap();

    // GET /scholarships (initial count)
    let resp = ctx.client.get(&format!("{}/scholarships", ctx.base)).send().await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let initial: Vec<serde_json::Value> = resp.json().await.unwrap();
    let initial_count = initial.len();
    eprintln!("  ✅ /scholarships → {initial_count} existing");

    // POST /scholarships (create)
    let resp = ctx
        .client
        .post(&format!("{}/scholarships", ctx.base))
        .header("Authorization", format!("Bearer {donor_id}"))
        .json(&serde_json::json!({
            "donor_id": donor_id,
            "title": "Test Bursu",
            "quota": 5,
            "min_gpa": 2.0,
            "target_cities": ["İstanbul"],
            "target_departments": ["Bilgisayar Mühendisliği"],
            "target_income_levels": ["low"],
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CREATED);
    let s1: serde_json::Value = resp.json().await.unwrap();
    let s1_id: Uuid = s1["id"].as_str().unwrap().parse().unwrap();
    assert_eq!(s1["is_active"], true, "is_active should default to true");
    eprintln!("  ✅ POST /scholarships → id={s1_id}, is_active=true");

    // POST /scholarships (no filters = all)
    let resp = ctx
        .client
        .post(&format!("{}/scholarships", ctx.base))
        .header("Authorization", format!("Bearer {donor_id}"))
        .json(&serde_json::json!({
            "donor_id": donor_id,
            "title": "Genel Burs",
            "quota": 10,
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CREATED);
    let s2: serde_json::Value = resp.json().await.unwrap();
    let s2_id: Uuid = s2["id"].as_str().unwrap().parse().unwrap();
    eprintln!("  ✅ POST /scholarships (no filters) → id={s2_id}");

    // POST /scholarships (invalid city → 400)
    let resp = ctx
        .client
        .post(&format!("{}/scholarships", ctx.base))
        .header("Authorization", format!("Bearer {donor_id}"))
        .json(&serde_json::json!({
            "donor_id": donor_id,
            "title": "Gecersiz Burs",
            "target_cities": ["InvalidCity"],
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
    eprintln!("  ✅ POST /scholarships (invalid city) → 400");

    // GET /scholarships/{id}
    let resp = ctx
        .client
        .get(&format!("{}/scholarships/{s1_id}", ctx.base))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let gs: serde_json::Value = resp.json().await.unwrap();
    assert_eq!(gs["id"].as_str().unwrap(), s1_id.to_string().as_str());
    assert_eq!(gs["title"], "Test Bursu");
    eprintln!("  ✅ GET /scholarships/{s1_id} → id matches, title correct");

    // GET /scholarships (non-existent) → 404
    let resp = ctx
        .client
        .get(&format!("{}/scholarships/00000000-0000-0000-0000-000000000000", ctx.base))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
    eprintln!("  ✅ /scholarships (nonexistent) → 404");

    // GET /scholarships (verify count increased by 2)
    let resp = ctx.client.get(&format!("{}/scholarships", ctx.base)).send().await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let all: Vec<serde_json::Value> = resp.json().await.unwrap();
    assert_eq!(all.len(), initial_count + 2, "expected {} scholarships", initial_count + 2);
    eprintln!("  ✅ /scholarships → {} (initial+2)", all.len());
}

// ── 7. Match Endpoint ────────────────────────────

async fn match_endpoint(ctx: &TestContext) {
    let ts = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs();
    let email = format!("match_student_{ts}@test.com");
    let resp = ctx
        .client
        .post(&format!("{}/register", ctx.base))
        .json(&serde_json::json!({
            "email": email,
            "password": "Test123456!",
            "role": "student",
            "city": "İstanbul",
            "department": "Bilgisayar Mühendisliği",
            "income_status": "low",
            "gpa": 3.5,
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CREATED);
    let student: serde_json::Value = resp.json().await.unwrap();
    let student_id: Uuid = student["id"].as_str().unwrap().parse().unwrap();

    // POST /match/{id}
    let resp = ctx
        .client
        .post(&format!("{}/match/{student_id}", ctx.base))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let results: Vec<serde_json::Value> = resp.json().await.unwrap();
    assert!(!results.is_empty(), "expected at least 1 match");
    assert!(results[0].get("scholarship_id").unwrap().is_string());
    assert!(results[0].get("score").unwrap().is_number());
    eprintln!("  ✅ /match/{student_id} → {} matches", results.len());

    // POST /match (non-existent) → 404
    let resp = ctx
        .client
        .post(&format!("{}/match/00000000-0000-0000-0000-000000000000", ctx.base))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
    eprintln!("  ✅ /match (nonexistent) → 404");
}

// ── 8. Department Delete Endpoint ────────────────

async fn department_delete_endpoint(ctx: &TestContext) {
    let ts = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .unwrap()
        .as_secs();

    // Create a temp department by registering a student with a new dept name
    let dept_name = format!("Test Departman_{ts}");
    let email = format!("temp_dept_{ts}@test.com");
    let resp = ctx
        .client
        .post(&format!("{}/register", ctx.base))
        .json(&serde_json::json!({
            "email": email,
            "password": "Test123456!",
            "role": "student",
            "city": "İstanbul",
            "department": dept_name,
            "income_status": "low",
        }))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CREATED);
    eprintln!("  ✅ Created temp department: {dept_name}");

    // DELETE /departments/{name} (as admin)
    let encoded: String = urlencode(&dept_name);
    let resp = ctx
        .client
        .delete(&format!("{}/departments/{encoded}", ctx.base))
        .header("Authorization", format!("Bearer {}", ctx.admin_id))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    eprintln!("  ✅ DELETE /departments (admin) → deleted");

    // DELETE /departments (non-existent) → 404
    let resp = ctx
        .client
        .delete(&format!("{}/departments/NonexistentDepartmentXYZ", ctx.base))
        .header("Authorization", format!("Bearer {}", ctx.admin_id))
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
    eprintln!("  ✅ DELETE /departments (nonexistent) → 404");

    // DELETE /departments/{name} (bad token → 401)
    let resp = ctx
        .client
        .delete(&format!("{}/departments/Uzay%20Mühendisliği", ctx.base))
        .header("Authorization", "Bearer 00000000-0000-0000-0000-000000000000")
        .send()
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
    eprintln!("  ✅ DELETE /departments (bad token) → 401");
}

fn urlencode(s: &str) -> String {
    s.as_bytes()
        .iter()
        .map(|&b| match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                (b as char).to_string()
            }
            _ => format!("%{:02X}", b),
        })
        .collect()
}
