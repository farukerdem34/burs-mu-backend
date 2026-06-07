# GET /students/{profile_id}/matches

**Resource:** [Öğrenciler](../resources/Öğrenciler.md)
**Öğrencinin kendi eşleşmelerini getir**
**Operation ID:** `get--students-{profile_id}-matches`

Öğrenci kendi eşleşme sonuçlarını görüntüler.
Aktif burslar arasında skor hesaplaması yapılır.
Skor 4 kategoride hesaplanır: demografik uyum, akademik uyum,
finansal ihtiyaç ve sosyal/ekstra-aktif.


## Parameters

| Name | In | Type | Required | Description |
|------|------|------|----------|-------------|
| `profile_id` | path | string (uuid) | Yes |  |

## Responses

| Status | Description |
|--------|-------------|
| 200 | Skorlanmış eşleşme sonuçları (büyükten küçüğe) |
| 403 | Kendi eşleşmelerinizi görüntüleyebilirsiniz |
| 404 | Öğrenci bulunamadı |

**Success Response Schema:**

Array of [MatchResult](../schemas/Match/MatchResult.md)

## Security

- **BearerAuth**
