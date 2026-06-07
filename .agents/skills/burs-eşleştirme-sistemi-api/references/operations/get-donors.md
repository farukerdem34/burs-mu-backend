# GET /donors

**Resource:** [Donorlar](../resources/Donorlar.md)
**Tüm donorları listele (admin)**
**Operation ID:** `get--donors`

## Responses

| Status | Description |
|--------|-------------|
| 200 | Donor listesi |
| 403 | Sadece yöneticiler burs verenleri görüntüleyebilir |

**Success Response Schema:**

Array of [Donor](../schemas/Donor/Donor.md)

## Security

- **BearerAuth**
