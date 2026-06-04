# GET /profiles/{id}

**Resource:** [Profiller](../resources/Profiller.md)
**ID'ye göre profil getir**
**Operation ID:** `get--profiles-{id}`

## Parameters

| Name | In | Type | Required | Description |
|------|------|------|----------|-------------|
| `id` | path | string (uuid) | Yes |  |

## Responses

| Status | Description |
|--------|-------------|
| 200 | Profil bilgisi |
| 404 | Profil bulunamadı |

**Success Response Schema:**

[Profile](../schemas/Profile/Profile.md)

