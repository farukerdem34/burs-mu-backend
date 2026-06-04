# GET /students

**Resource:** [Öğrenciler](../resources/Öğrenciler.md)
**Tüm öğrencileri listele (admin)**
**Operation ID:** `get--students`

## Responses

| Status | Description |
|--------|-------------|
| 200 | Öğrenci listesi |
| 403 | Sadece yöneticiler öğrencileri görüntüleyebilir |

**Success Response Schema:**

Array of [Student](../schemas/Student/Student.md)

## Security

- **BearerAuth**
