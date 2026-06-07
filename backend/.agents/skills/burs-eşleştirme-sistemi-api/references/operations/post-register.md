# POST /register

**Resource:** [Auth](../resources/Auth.md)
**Yeni kullanıcı kaydet**
**Operation ID:** `post--register`

Supabase Auth üzerinden kullanıcı oluşturur, email'i otomatik onaylar
ve profiles tablosuna kaydı ekler.
Öğrenciye ait alanlar (şehir, departman, GPA vb.) opsiyoneldir;
kayıt anında girilebileceği gibi sonradan PUT /students/{profile_id} ile de eklenebilir.


## Request Body

**Required:** Yes

**Content Types:** `application/json`

**Schema:** [RegisterRequest](../schemas/Register/RegisterRequest.md)

## Responses

| Status | Description |
|--------|-------------|
| 201 | Kullanıcı başarıyla oluşturuldu |
| 400 | Yönetici kaydı yapılamaz |
| 409 | Bu email zaten kayıtlı |
| 500 | Kullanıcı oluşturulamadı veya profil kaydedilemedi |

**Success Response Schema:**

[RegisterResponse](../schemas/Register/RegisterResponse.md)

