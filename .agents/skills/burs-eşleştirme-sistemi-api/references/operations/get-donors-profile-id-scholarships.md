# GET /donors/{profile_id}/scholarships

**Resource:** [Donorlar](../resources/Donorlar.md)
**Donora ait bursları listele**
**Operation ID:** `get--donors-{profile_id}-scholarships`

Belirtilen donora ait tüm bursları getirir.

## Parameters

| Name | In | Type | Required | Description |
|------|------|------|----------|-------------|
| `profile_id` | path | string (uuid) | Yes |  |

## Responses

| Status | Description |
|--------|-------------|
| 200 | Donora ait burs listesi |
| 500 | Burslar alınamadı |

**Success Response Schema:**

Array of [Scholarship](../schemas/Scholarship/Scholarship.md)

