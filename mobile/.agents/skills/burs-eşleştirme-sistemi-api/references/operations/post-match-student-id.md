# POST /match/{student_id}

**Resource:** [Eşleştirme](../resources/Eşleştirme.md)
**Öğrenciyi aktif burslarla eşleştir (admin)**
**Operation ID:** `post--match-{student_id}`

4 kategoride gelişmiş skorlama yapar: demografik uyum (%30),
akademik uyum (%30), finansal ihtiyaç (%25), sosyal/ekstra-aktif (%15).
Skor 0-100 arası normalize edilir.


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
