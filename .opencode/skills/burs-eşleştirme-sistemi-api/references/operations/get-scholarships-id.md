# GET /scholarships/{id}

**Resource:** [Burslar](../resources/Burslar.md)
**ID'ye göre burs getir**
**Operation ID:** `get--scholarships-{id}`

## Parameters

| Name | In | Type | Required | Description |
|------|------|------|----------|-------------|
| `id` | path | string (uuid) | Yes |  |

## Responses

| Status | Description |
|--------|-------------|
| 200 | Burs bilgisi |
| 404 | Burs bulunamadı |

**Success Response Schema:**

[Scholarship](../schemas/Scholarship/Scholarship.md)

