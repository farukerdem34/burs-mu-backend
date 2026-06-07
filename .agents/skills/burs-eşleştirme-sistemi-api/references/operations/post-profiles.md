# POST /profiles

**Resource:** [Profiller](../resources/Profiller.md)
**Yeni profil oluştur**
**Operation ID:** `post--profiles`

## Request Body

**Required:** Yes

**Content Types:** `application/json`

**Schema:** [CreateProfileRequest](../schemas/Create/CreateProfileRequest.md)

## Responses

| Status | Description |
|--------|-------------|
| 201 | Profil oluşturuldu |
| 400 | Geçersiz rol veya yönetici profili oluşturulamaz |
| 422 | Doğrulama hatası |

**Success Response Schema:**

[Profile](../schemas/Profile/Profile.md)

