# GET /profiles

**Resource:** [Profiller](../resources/Profiller.md)
**Tüm profilleri listele (admin)**
**Operation ID:** `get--profiles`

## Responses

| Status | Description |
|--------|-------------|
| 200 | Profil listesi |
| 403 | Sadece yöneticiler profilleri görüntüleyebilir |

**Success Response Schema:**

Array of [Profile](../schemas/Profile/Profile.md)

## Security

- **BearerAuth**
