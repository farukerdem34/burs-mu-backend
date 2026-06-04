# GET /students/{profile_id}

**Resource:** [Öğrenciler](../resources/Öğrenciler.md)
**Profile ID'ye göre öğrenci getir**
**Operation ID:** `get--students-{profile_id}`

## Parameters

| Name | In | Type | Required | Description |
|------|------|------|----------|-------------|
| `profile_id` | path | string (uuid) | Yes |  |

## Responses

| Status | Description |
|--------|-------------|
| 200 | Öğrenci bilgisi |
| 404 | Öğrenci bulunamadı |

**Success Response Schema:**

[Student](../schemas/Student/Student.md)

