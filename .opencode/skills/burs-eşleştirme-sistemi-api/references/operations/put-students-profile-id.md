# PUT /students/{profile_id}

**Resource:** [Öğrenciler](../resources/Öğrenciler.md)
**Öğrenci profilini güncelle**
**Operation ID:** `put--students-{profile_id}`

Öğrenci kendi profil bilgilerini güncelleyebilir.
Varolan kayıt güncellenir; kayıt yoksa INSERT yapılır.
Gönderilmeyen alanlar mevcut değerini korur.


## Parameters

| Name | In | Type | Required | Description |
|------|------|------|----------|-------------|
| `profile_id` | path | string (uuid) | Yes |  |

## Request Body

**Required:** Yes

**Content Types:** `application/json`

**Schema:** [UpdateStudentRequest](../schemas/Update/UpdateStudentRequest.md)

## Responses

| Status | Description |
|--------|-------------|
| 200 | Öğrenci başarıyla güncellendi |
| 403 | Kendi hesabınızı düzenleyebilirsiniz |
| 404 | Öğrenci bulunamadı |

**Success Response Schema:**

[Student](../schemas/Student/Student.md)

## Security

- **BearerAuth**
