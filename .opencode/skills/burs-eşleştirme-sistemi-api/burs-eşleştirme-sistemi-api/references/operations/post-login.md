# POST /login

**Resource:** [Auth](../resources/Auth.md)
**Kullanıcı girişi**
**Operation ID:** `post--login`

Email ve şifre ile giriş yapar. Supabase auth.users tablosunda
crypt() doğrulaması yapılır. Başarılı girişte profil UUID'si döner.


## Request Body

**Required:** Yes

**Content Types:** `application/json`

**Schema:** [LoginRequest](../schemas/Login/LoginRequest.md)

## Responses

| Status | Description |
|--------|-------------|
| 200 | Giriş başarılı |
| 401 | E-posta veya şifre hatalı |
| 500 | Giriş yapılamadı |

**Success Response Schema:**

[LoginResponse](../schemas/Login/LoginResponse.md)

