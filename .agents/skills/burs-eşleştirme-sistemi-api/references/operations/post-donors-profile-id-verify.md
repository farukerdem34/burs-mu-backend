# POST /donors/{profile_id}/verify

**Resource:** [Donorlar](../resources/Donorlar.md)
**Donoru yönetici onayı ile doğrula**
**Operation ID:** `post--donors-{profile_id}-verify`

## Parameters

| Name | In | Type | Required | Description |
|------|------|------|----------|-------------|
| `profile_id` | path | string (uuid) | Yes |  |

## Responses

| Status | Description |
|--------|-------------|
| 200 | Donor başarıyla doğrulandı |
| 403 | Sadece yöneticiler burs verenleri onaylayabilir |
| 404 | Donor bulunamadı |

**Success Response Schema:**

[Donor](../schemas/Donor/Donor.md)

## Security

- **BearerAuth**
