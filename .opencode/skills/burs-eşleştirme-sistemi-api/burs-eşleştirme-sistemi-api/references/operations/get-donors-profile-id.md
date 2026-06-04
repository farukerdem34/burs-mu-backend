# GET /donors/{profile_id}

**Resource:** [Donorlar](../resources/Donorlar.md)
**Profile ID'ye göre donor getir**
**Operation ID:** `get--donors-{profile_id}`

## Parameters

| Name | In | Type | Required | Description |
|------|------|------|----------|-------------|
| `profile_id` | path | string (uuid) | Yes |  |

## Responses

| Status | Description |
|--------|-------------|
| 200 | Donor bilgisi |
| 404 | Donor bulunamadı |

**Success Response Schema:**

[Donor](../schemas/Donor/Donor.md)

