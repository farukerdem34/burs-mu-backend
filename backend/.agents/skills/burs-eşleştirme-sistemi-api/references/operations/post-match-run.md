# POST /match/run

**Resource:** [Eşleştirme](../resources/Eşleştirme.md)
**Toplu eşleştirme çalıştır (admin)**
**Operation ID:** `post--match-run`

Tüm aktif burslar için tüm öğrencilerle eşleştirme yapar.
Skorlar score_breakdown JSONB olarak matches tablosuna kaydedilir.


## Responses

| Status | Description |
|--------|-------------|
| 200 | Eşleştirme tamamlandı |
| 403 | Sadece yöneticiler eşleştirme çalıştırabilir |

**Success Response Schema** (inline):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `message` | string | No |  |
| `matched_count` | integer | No |  |

## Security

- **BearerAuth**
