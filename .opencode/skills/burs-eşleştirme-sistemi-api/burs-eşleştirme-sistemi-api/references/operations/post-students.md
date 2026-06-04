# POST /students

**Resource:** [Öğrenciler](../resources/Öğrenciler.md)
**Yeni öğrenci oluştur**
**Operation ID:** `post--students`

## Request Body

**Required:** Yes

**Content Types:** `application/json`

**Schema:** [CreateStudentRequest](../schemas/Create/CreateStudentRequest.md)

## Responses

| Status | Description |
|--------|-------------|
| 201 | Öğrenci oluşturuldu |
| 400 | Geçersiz şehir veya departman |
| 403 | Kendi hesabınızı düzenleyebilirsiniz |

**Success Response Schema:**

[Student](../schemas/Student/Student.md)

## Security

- **BearerAuth**
