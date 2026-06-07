# GET /health

**Resource:** [Sağlık](../resources/Sağlık.md)
**Sunucu sağlık kontrolü**
**Operation ID:** `get--health`

Client-server bağlantısını test etmek için kullanılır.
Authentication gerektirmez. Her zaman 200 döner.


## Responses

| Status | Description |
|--------|-------------|
| 200 | Sunucu çalışıyor |

**Success Response Schema** (inline):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `status` | string | No |  |

