#!/usr/bin/env bash
set -o pipefail

BASE="http://localhost:8080"
PASS=0
FAIL=0
ERRORS=""

# use a temp file for storing tokens/responses
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

ok()   { PASS=$((PASS+1)); echo "  ✅ $1"; }
fail() { FAIL=$((FAIL+1)); echo "  ❌ $1"; ERRORS+="  ❌ $1${2:+" -> $2"}"$'\n'; }

header() { echo ""; echo "━━━ $1 ━━━"; }

# ──────────────────────────────────────────────
# 1. REFERENCE ENDPOINTS
# ──────────────────────────────────────────────
header "REFERENCE ENDPOINTS"

echo "→ GET /cities"
resp=$(curl -sf "$BASE/cities" 2>&1) && {
  count=$(echo "$resp" | jq length)
  [[ "$count" -ge 80 ]] && ok "/cities → $count cities (≥80)" || fail "/cities → only $count cities"
} || fail "/cities" "$resp"

echo "→ GET /departments"
resp=$(curl -sf "$BASE/departments" 2>&1) && {
  count=$(echo "$resp" | jq length)
  [[ "$count" -ge 5 ]] && ok "/departments → $count departments (≥5)" || fail "/departments → only $count"
} || fail "/departments" "$resp"

echo "→ GET /income-levels"
resp=$(curl -sf "$BASE/income-levels" 2>&1) && {
  count=$(echo "$resp" | jq length)
  [[ "$count" -eq 3 ]] && ok "/income-levels → 3 levels" || fail "/income-levels → $count (expected 3)"
} || fail "/income-levels" "$resp"

echo "→ GET /user-roles"
resp=$(curl -sf "$BASE/user-roles" 2>&1) && {
  count=$(echo "$resp" | jq length)
  [[ "$count" -eq 3 ]] && ok "/user-roles → 3 roles (student, donor, admin)" || fail "/user-roles → $count (expected 3)"
} || fail "/user-roles" "$resp"

# ──────────────────────────────────────────────
# 2. AUTH ENDPOINTS
# ──────────────────────────────────────────────
header "AUTH ENDPOINTS"

echo "→ POST /register (student)"
STUDENT_EMAIL="test_student_$(date +%s)@test.com"
resp=$(curl -sf -X POST "$BASE/register" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$STUDENT_EMAIL\",\"password\":\"Test123456!\",\"role\":\"student\",\"city\":\"İstanbul\",\"department\":\"Bilgisayar Mühendisliği\",\"income_status\":\"low\",\"gpa\":3.5}" 2>&1) && {
  STUDENT_ID=$(echo "$resp" | jq -r '.id')
  STUDENT_ROLE=$(echo "$resp" | jq -r '.role')
  echo "$STUDENT_ID" > "$TMPDIR/student_id"
  echo "$resp" | jq .
  [[ -n "$STUDENT_ID" && "$STUDENT_ID" != "null" ]] && ok "/register (student) → id=$STUDENT_ID" || fail "/register (student)" "$resp"
  [[ "$STUDENT_ROLE" == "student" ]] && ok "/register → role is student" || fail "/register → role mismatch: $STUDENT_ROLE"
} || fail "/register (student)" "$resp"

echo "→ POST /register (donor)"
DONOR_EMAIL="test_donor_$(date +%s)@test.com"
resp=$(curl -sf -X POST "$BASE/register" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$DONOR_EMAIL\",\"password\":\"Test123456!\",\"role\":\"donor\"}" 2>&1) && {
  DONOR_ID=$(echo "$resp" | jq -r '.id')
  DONOR_ROLE=$(echo "$resp" | jq -r '.role')
  echo "$DONOR_ID" > "$TMPDIR/donor_id"
  echo "$resp" | jq .
  [[ -n "$DONOR_ID" && "$DONOR_ID" != "null" ]] && ok "/register (donor) → id=$DONOR_ID" || fail "/register (donor)" "$resp"
  [[ "$DONOR_ROLE" == "donor" ]] && ok "/register → role is donor" || fail "/register → role mismatch: $DONOR_ROLE"
} || fail "/register (donor)" "$resp"

echo "→ POST /register (duplicate email — expect 409)"
resp=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/register" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$STUDENT_EMAIL\",\"password\":\"Test123456!\",\"role\":\"student\"}" 2>&1) && {
  [[ "$resp" == "409" ]] && ok "/register (duplicate) → 409" || fail "/register (duplicate) → got $resp (expected 409)"
} || fail "/register (duplicate)" "$resp"

echo "→ POST /login (student)"
resp=$(curl -sf -X POST "$BASE/login" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$STUDENT_EMAIL\",\"password\":\"Test123456!\"}" 2>&1) && {
  LOGIN_ID=$(echo "$resp" | jq -r '.id')
  LOGIN_ROLE=$(echo "$resp" | jq -r '.role')
  echo "$resp" | jq .
  [[ "$LOGIN_ID" == "$STUDENT_ID" ]] && ok "/login → id matches" || fail "/login → id mismatch: $LOGIN_ID vs $STUDENT_ID"
  [[ "$LOGIN_ROLE" == "student" ]] && ok "/login → role is student" || fail "/login → role mismatch: $LOGIN_ROLE"
} || fail "/login (student)" "$resp"

echo "→ POST /login (donor)"
resp=$(curl -sf -X POST "$BASE/login" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$DONOR_EMAIL\",\"password\":\"Test123456!\"}" 2>&1) && {
  LOGIN_DID=$(echo "$resp" | jq -r '.id')
  LOGIN_DROLE=$(echo "$resp" | jq -r '.role')
  echo "$resp" | jq .
  [[ "$LOGIN_DID" == "$DONOR_ID" ]] && ok "/login donor → id matches" || fail "/login donor → id mismatch"
  [[ "$LOGIN_DROLE" == "donor" ]] && ok "/login donor → role is donor" || fail "/login donor → role mismatch"
} || fail "/login (donor)" "$resp"

echo "→ POST /login (wrong password — expect 401)"
resp=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/login" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$STUDENT_EMAIL\",\"password\":\"wrongpassword\"}" 2>&1) && {
  [[ "$resp" == "401" ]] && ok "/login (wrong pw) → 401" || fail "/login (wrong pw) → got $resp (expected 401)"
} || fail "/login (wrong pw)" "$resp"

echo "→ POST /login (nonexistent email — expect 401)"
resp=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/login" \
  -H 'Content-Type: application/json' \
  -d '{"email":"noone@nonexistent.com","password":"Test123456!"}' 2>&1) && {
  [[ "$resp" == "401" ]] && ok "/login (nonexistent) → 401" || fail "/login (nonexistent) → got $resp (expected 401)"
} || fail "/login (nonexistent)" "$resp"

# ──────────────────────────────────────────────
# 3. PROFILE ENDPOINTS
# ──────────────────────────────────────────────
header "PROFILE ENDPOINTS"

echo "→ GET /profiles"
resp=$(curl -sf "$BASE/profiles" 2>&1) && {
  count=$(echo "$resp" | jq length)
  [[ "$count" -ge 8 ]] && ok "/profiles → $count profiles (≥8)" || fail "/profiles → only $count"
  # check response structure
  first_id=$(echo "$resp" | jq -r '.[0].id')
  [[ -n "$first_id" && "$first_id" != "null" ]] && ok "/profiles → has valid id field" || fail "/profiles → missing id"
} || fail "/profiles" "$resp"

echo "→ GET /profiles/{student_id} (existing)"
resp=$(curl -sf "$BASE/profiles/$STUDENT_ID" 2>&1) && {
  pid=$(echo "$resp" | jq -r '.id')
  prole=$(echo "$resp" | jq -r '.role')
  [[ "$pid" == "$STUDENT_ID" ]] && ok "/profiles/$STUDENT_ID → id matches" || fail "/profiles/{id} → id mismatch"
  [[ "$prole" == "student" ]] && ok "/profiles/$STUDENT_ID → role is student" || fail "/profiles/{id} → role mismatch"
} || fail "/profiles/$STUDENT_ID" "$resp"

echo "→ GET /profiles/{non-existent} (expect 404)"
resp=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/profiles/00000000-0000-0000-0000-000000000000" 2>&1) && {
  [[ "$resp" == "404" ]] && ok "/profiles/nonexistent → 404" || fail "/profiles/nonexistent → got $resp (expected 404)"
} || fail "/profiles/nonexistent" "$resp"

echo "→ POST /profiles (random UUID — expect 500 FK error)"
resp=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/profiles" \
  -H 'Content-Type: application/json' \
  -d "{\"id\":\"00000000-0000-0000-0000-000000000001\",\"role\":\"student\"}" 2>&1) && {
  [[ "$resp" == "500" ]] && ok "POST /profiles (no auth user) → 500 (FK constraint)" || fail "POST /profiles (no auth user) → got $resp (expected 500)"
} || fail "POST /profiles" "$resp"

echo "→ POST /profiles (admin role — expect 400)"
resp=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/profiles" \
  -H 'Content-Type: application/json' \
  -d "{\"id\":\"$STUDENT_ID\",\"role\":\"admin\"}" 2>&1) && {
  [[ "$resp" == "400" ]] && ok "POST /profiles (admin role) → 400" || fail "POST /profiles (admin role) → got $resp (expected 400)"
} || fail "POST /profiles (admin)" "$resp"

# ──────────────────────────────────────────────
# 4. STUDENT ENDPOINTS
# ──────────────────────────────────────────────
header "STUDENT ENDPOINTS"

echo "→ GET /students"
resp=$(curl -sf "$BASE/students" 2>&1) && {
  count=$(echo "$resp" | jq length)
  [[ "$count" -ge 2 ]] && ok "/students → $count students (≥2)" || fail "/students → only $count"
} || fail "/students" "$resp"

echo "→ GET /students/{profile_id} (existing)"
resp=$(curl -sf "$BASE/students/$STUDENT_ID" 2>&1) && {
  sid=$(echo "$resp" | jq -r '.profile_id')
  scity=$(echo "$resp" | jq -r '.city')
  [[ "$sid" == "$STUDENT_ID" ]] && ok "/students/$STUDENT_ID → profile_id matches" || fail "/students/{id} → profile_id mismatch"
  [[ "$scity" == "İstanbul" ]] && ok "/students/$STUDENT_ID → city is İstanbul" || fail "/students/{id} → city: $scity"
} || fail "/students/$STUDENT_ID" "$resp"

echo "→ GET /students/{non-existent} (expect 404)"
resp=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/students/00000000-0000-0000-0000-000000000000" 2>&1) && {
  [[ "$resp" == "404" ]] && ok "/students/nonexistent → 404" || fail "/students/nonexistent → got $resp (expected 404)"
} || fail "/students/nonexistent" "$resp"

echo "→ PUT /students/{profile_id} (update — add GPA and about)"
resp=$(curl -sf -X PUT "$BASE/students/$STUDENT_ID" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $STUDENT_ID" \
  -d '{"gpa":3.8,"about":"Test ogrenciyim"}' 2>&1) && {
  ugpa=$(echo "$resp" | jq -r '.gpa')
  uabout=$(echo "$resp" | jq -r '.about')
  echo "$resp" | jq .
  [[ "$ugpa" == "3.8" ]] && ok "PUT /students → GPA updated to 3.8" || fail "PUT /students → GPA: $ugpa"
  [[ "$uabout" == "Test ogrenciyim" ]] && ok "PUT /students → about set" || fail "PUT /students → about: $uabout"
} || fail "PUT /students" "$resp"

echo "→ PUT /students/{profile_id} (partial update — only about)"
resp=$(curl -sf -X PUT "$BASE/students/$STUDENT_ID" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $STUDENT_ID" \
  -d '{"about":"Guncellenen metin"}' 2>&1) && {
  ugpa2=$(echo "$resp" | jq -r '.gpa')
  uabout2=$(echo "$resp" | jq -r '.about')
  [[ "$ugpa2" == "3.8" ]] && ok "PUT /students (partial) → GPA preserved" || fail "PUT /students (partial) → GPA changed to $ugpa2"
  [[ "$uabout2" == "Guncellenen metin" ]] && ok "PUT /students (partial) → about updated" || fail "PUT /students (partial) → about: $uabout2"
} || fail "PUT /students (partial)" "$resp"

echo "→ POST /students (create new student record for existing profile)"
# We need a separate student profile that doesn't have a student record yet
# Register a new student WITHOUT city/department so no student record is created
POST_STUDENT_EMAIL="post_student_$(date +%s)@test.com"
resp=$(curl -sf -X POST "$BASE/register" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$POST_STUDENT_EMAIL\",\"password\":\"Test123456!\",\"role\":\"student\"}" 2>&1) && {
  POST_STUDENT_ID=$(echo "$resp" | jq -r '.id')
  echo "$resp" | jq .
  ok "/register (no student record) → id=$POST_STUDENT_ID"
} || fail "/register (post student)" "$resp"

resp=$(curl -sf -X POST "$BASE/students" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $POST_STUDENT_ID" \
  -d "{\"profile_id\":\"$POST_STUDENT_ID\",\"city\":\"Ankara\",\"department\":\"Elektrik Mühendisliği\",\"income_status\":\"medium\",\"gpa\":2.5}" 2>&1) && {
  spid=$(echo "$resp" | jq -r '.profile_id')
  scity=$(echo "$resp" | jq -r '.city')
  sdpt=$(echo "$resp" | jq -r '.department')
  echo "$resp" | jq .
  [[ "$spid" == "$POST_STUDENT_ID" ]] && ok "POST /students → profile_id matches" || fail "POST /students → profile_id mismatch"
  [[ "$scity" == "Ankara" ]] && ok "POST /students → city is Ankara" || fail "POST /students → city: $scity"
  [[ "$sdpt" == "Elektrik Mühendisliği" ]] && ok "POST /students → department matches" || fail "POST /students → department: $sdpt"
} || fail "POST /students" "$resp"

# ──────────────────────────────────────────────
# 5. DONOR ENDPOINTS
# ──────────────────────────────────────────────
header "DONOR ENDPOINTS"

echo "→ GET /donors"
resp=$(curl -sf "$BASE/donors" 2>&1) && {
  count=$(echo "$resp" | jq length)
  [[ "$count" -ge 2 ]] && ok "/donors → $count donors (≥2)" || fail "/donors → only $count"
} || fail "/donors" "$resp"

echo "→ GET /donors/{profile_id} (existing)"
resp=$(curl -sf "$BASE/donors/$DONOR_ID" 2>&1) && {
  did=$(echo "$resp" | jq -r '.profile_id')
  [[ "$did" == "$DONOR_ID" ]] && ok "/donors/$DONOR_ID → profile_id matches" || fail "/donors/{id} → profile_id mismatch"
} || fail "/donors/$DONOR_ID" "$resp"

echo "→ GET /donors/{non-existent} (expect 404)"
resp=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/donors/00000000-0000-0000-0000-000000000000" 2>&1) && {
  [[ "$resp" == "404" ]] && ok "/donors/nonexistent → 404" || fail "/donors/nonexistent → got $resp (expected 404)"
} || fail "/donors/nonexistent" "$resp"

echo "→ POST /donors/{profile_id}/verify (admin — needs admin auth)"
# Use the first donor in DB as "admin" for verify
ADMIN_DONOR_ID="b3aecf7e-f3de-4dad-9ca8-7e538bd34900"
resp=$(curl -sf -X POST "$BASE/donors/$DONOR_ID/verify" \
  -H "Authorization: Bearer $ADMIN_DONOR_ID" 2>&1) && {
  visVerified=$(echo "$resp" | jq -r '.is_verified')
  echo "$resp" | jq .
  [[ "$visVerified" == "true" ]] && ok "/donors/{id}/verify → donor verified" || fail "/donors/{id}/verify → is_verified=$visVerified"
} || fail "/donors/{id}/verify" "$resp"

echo "→ POST /donors/{profile_id}/verify (non-admin — expect 403 or error)"
resp=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/donors/$DONOR_ID/verify" \
  -H "Authorization: Bearer $STUDENT_ID" 2>&1) && {
  [[ "$resp" == "403" || "$resp" == "401" ]] && ok "/donors/{id}/verify (non-admin) → $resp" || fail "/donors/{id}/verify (non-admin) → got $resp (expected 403)"
} || fail "/donors/{id}/verify (non-admin) request failed" "$resp"

# ──────────────────────────────────────────────
# 6. SCHOLARSHIP ENDPOINTS
# ──────────────────────────────────────────────
header "SCHOLARSHIP ENDPOINTS"

echo "→ GET /scholarships (initial)"
resp=$(curl -sf "$BASE/scholarships" 2>&1) && {
  INITIAL_SCHOLARSHIP_COUNT=$(echo "$resp" | jq length)
  ok "/scholarships → $INITIAL_SCHOLARSHIP_COUNT existing"
} || fail "/scholarships" "$resp"

echo "→ POST /scholarships (create)"
resp=$(curl -sf -X POST "$BASE/scholarships" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $DONOR_ID" \
  -d "{\"donor_id\":\"$DONOR_ID\",\"title\":\"Test Bursu\",\"quota\":5,\"min_gpa\":2.0,\"target_cities\":[\"İstanbul\"],\"target_departments\":[\"Bilgisayar Mühendisliği\"],\"target_income_levels\":[\"low\"]}" 2>&1) && {
  SCHOLARSHIP_ID=$(echo "$resp" | jq -r '.id')
  echo "$SCHOLARSHIP_ID" > "$TMPDIR/scholarship_id"
  echo "$resp" | jq .
  [[ -n "$SCHOLARSHIP_ID" && "$SCHOLARSHIP_ID" != "null" ]] && ok "POST /scholarships → id=$SCHOLARSHIP_ID" || fail "POST /scholarships" "$resp"
} || fail "POST /scholarships" "$resp"

echo "→ POST /scholarships (second — no target filters = all)"
resp=$(curl -sf -X POST "$BASE/scholarships" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $DONOR_ID" \
  -d "{\"donor_id\":\"$DONOR_ID\",\"title\":\"Genel Burs\",\"quota\":10}" 2>&1) && {
  SCHOLARSHIP_ID2=$(echo "$resp" | jq -r '.id')
  echo "$SCHOLARSHIP_ID2" > "$TMPDIR/scholarship_id2"
  echo "$resp" | jq .
  [[ -n "$SCHOLARSHIP_ID2" && "$SCHOLARSHIP_ID2" != "null" ]] && ok "POST /scholarships (no filters) → id=$SCHOLARSHIP_ID2" || fail "POST /scholarships (no filters)" "$resp"
} || fail "POST /scholarships (no filters)" "$resp"

echo "→ POST /scholarships (invalid city — expect 400)"
resp=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/scholarships" \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $DONOR_ID" \
  -d "{\"donor_id\":\"$DONOR_ID\",\"title\":\"Gecersiz Burs\",\"target_cities\":[\"InvalidCity\"]}" 2>&1) && {
  [[ "$resp" == "400" ]] && ok "POST /scholarships (invalid city) → 400" || fail "POST /scholarships (invalid city) → got $resp (expected 400)"
} || fail "POST /scholarships (invalid city)" "$resp"

echo "→ GET /scholarships/{id}"
sch_id=$(cat "$TMPDIR/scholarship_id")
resp=$(curl -sf "$BASE/scholarships/$sch_id" 2>&1) && {
  sid=$(echo "$resp" | jq -r '.id')
  stitle=$(echo "$resp" | jq -r '.title')
  [[ "$sid" == "$sch_id" ]] && ok "/scholarships/$sch_id → id matches" || fail "/scholarships/{id} → id mismatch"
  [[ "$stitle" == "Test Bursu" ]] && ok "/scholarships/$sch_id → title is 'Test Bursu'" || fail "/scholarships/{id} → title: $stitle"
} || fail "/scholarships/$sch_id" "$resp"

echo "→ GET /scholarships/{non-existent} (expect 404)"
resp=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/scholarships/00000000-0000-0000-0000-000000000000" 2>&1) && {
  [[ "$resp" == "404" ]] && ok "/scholarships/nonexistent → 404" || fail "/scholarships/nonexistent → got $resp (expected 404)"
} || fail "/scholarships/nonexistent" "$resp"

echo "→ GET /scholarships (after create — expect INITIAL+2)"
resp=$(curl -sf "$BASE/scholarships" 2>&1) && {
  count=$(echo "$resp" | jq length)
  expected=$((INITIAL_SCHOLARSHIP_COUNT + 2))
  [[ "$count" -eq "$expected" ]] && ok "/scholarships → $count scholarships (initial+2)" || fail "/scholarships → $count (expected $expected)"
} || fail "/scholarships" "$resp"

# ──────────────────────────────────────────────
# 7. MATCH ENDPOINT
# ──────────────────────────────────────────────
header "MATCH ENDPOINT"

echo "→ POST /match/{student_id}"
resp=$(curl -sf -X POST "$BASE/match/$STUDENT_ID" 2>&1) && {
  count=$(echo "$resp" | jq length)
  echo "$resp" | jq .
  # Student has low income, İstanbul, Bilg. Müh., GPA 3.8
  # Should match Test Bursu (targets: İstanbul, Bilg. Müh., low)
  # Should also match Genel Burs (no filters)
  [[ "$count" -ge 1 ]] && ok "/match/$STUDENT_ID → $count matches (≥1)" || fail "/match/$STUDENT_ID → 0 matches (expected ≥1)"
  # Verify structure
  has_scholarship_id=$(echo "$resp" | jq '.[0] | has("scholarship_id")')
  has_score=$(echo "$resp" | jq '.[0] | has("score")')
  [[ "$has_scholarship_id" == "true" && "$has_score" == "true" ]] && ok "/match → response has scholarship_id and score" || fail "/match → bad response structure"
} || fail "/match/$STUDENT_ID" "$resp"

echo "→ POST /match/{non-existent} (expect 404)"
resp=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/match/00000000-0000-0000-0000-000000000000" 2>&1) && {
  [[ "$resp" == "404" ]] && ok "/match/nonexistent → 404" || fail "/match/nonexistent → got $resp (expected 404)"
} || fail "/match/nonexistent" "$resp"

# ──────────────────────────────────────────────
# 8. DEPARTMENT DELETE ENDPOINT
# ──────────────────────────────────────────────
header "DEPARTMENT DELETE ENDPOINT"

# First create a temp department to delete
echo "→ Creating department for delete test via student with new department"
# We'll create a student with a unique temp department
TEMP_DEPT="Test Departman_$(date +%s)"
TEMP_EMAIL="temp_dept_$(date +%s)@test.com"
resp=$(curl -sf -X POST "$BASE/register" \
  -H 'Content-Type: application/json' \
  -d "{\"email\":\"$TEMP_EMAIL\",\"password\":\"Test123456!\",\"role\":\"student\",\"city\":\"İstanbul\",\"department\":\"$TEMP_DEPT\",\"income_status\":\"low\"}" 2>&1) && {
  DEPT_STUDENT_ID=$(echo "$resp" | jq -r '.id')
  echo "$resp" | jq .
  ok "/register (with temp dept) → $TEMP_DEPT"
} || fail "/register (temp dept)" "$resp"

echo "→ DELETE /departments/{name} (as admin)"
# URL-encode the department name
TEMP_DEPT_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$TEMP_DEPT'))")
resp=$(curl -sf -X DELETE "$BASE/departments/$TEMP_DEPT_ENCODED" \
  -H "Authorization: Bearer $ADMIN_DONOR_ID" 2>&1) && {
  msg=$(echo "$resp" | jq -R .)
  echo "$resp"
  # The response is a plain string like "Department '...' deleted"
  [[ "$resp" == *"deleted"* ]] && ok "DELETE /departments → deleted successfully" || fail "DELETE /departments → response: $resp"
} || fail "DELETE /departments" "$resp"

echo "→ DELETE /departments/{non-existent} (expect 404)"
resp=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE/departments/NonexistentDepartmentXYZ" \
  -H "Authorization: Bearer $ADMIN_DONOR_ID" 2>&1) && {
  [[ "$resp" == "404" ]] && ok "DELETE /departments (nonexistent) → 404" || fail "DELETE /departments (nonexistent) → got $resp (expected 404)"
} || fail "DELETE /departments (nonexistent)" "$resp"

echo "→ DELETE /departments/{name} (non-admin — expect 403)"
resp=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE/departments/Uzay%20Mühendisliği" \
  -H "Authorization: Bearer $STUDENT_ID" 2>&1) && {
  [[ "$resp" == "403" || "$resp" == "401" ]] && ok "DELETE /departments (non-admin) → $resp" || fail "DELETE /departments (non-admin) → got $resp (expected 403)"
} || fail "DELETE /departments (non-admin)" "$resp"

# ──────────────────────────────────────────────
# SUMMARY
# ──────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════"
echo "  RESULTS: $PASS passed, $FAIL failed"
echo "═══════════════════════════════════════"
if [[ -n "$ERRORS" ]]; then
  echo ""
  echo "$ERRORS"
fi

exit $FAIL
