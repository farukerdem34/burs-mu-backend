# DELETE /departments/{name}

**Resource:** [Referanslar](../resources/Referanslar.md)
**Departman sil (sadece yönetici)**
**Operation ID:** `delete--departments-{name}`

Departmanı ve ona bağlı öğrenci kayıtlarını siler,
ayrıca bursların target_departments array'inden kaldırır.


## Parameters

| Name | In | Type | Required | Description |
|------|------|------|----------|-------------|
| `name` | path | string | Yes |  |

## Responses

| Status | Description |
|--------|-------------|
| 200 | Departman başarıyla silindi |
| 401 | Geçersiz veya eksik token |
| 403 | Sadece yöneticiler departman silebilir |
| 404 | Departman bulunamadı |

## Security

- **BearerAuth**
