# POST /match/{student_id}

**Resource:** [Eşleştirme](../resources/Eşleştirme.md)
**Öğrenciyi aktif burslarla eşleştir (admin)**
**Operation ID:** `post--match-{student_id}`

## Parameters

| Name | In | Type | Required | Description |
|------|------|------|----------|-------------|
| `student_id` | path | string (uuid) | Yes | Öğrencinin profile_id'si |

## Responses

| Status | Description |
|--------|-------------|
| 200 | Skorlanmış eşleşme sonuçları (büyükten küçüğe) |
| 403 | Sadece yöneticiler eşleştirme yapabilir |
| 404 | Öğrenci bulunamadı (boş dizi döner) |

**Success Response Schema:**

Array of [MatchResult](../schemas/Match/MatchResult.md)

## Security

- **BearerAuth**
