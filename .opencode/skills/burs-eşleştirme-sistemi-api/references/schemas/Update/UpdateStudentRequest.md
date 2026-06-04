# UpdateStudentRequest

**Type:** object

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `gpa` | number (float) | No | Not ortalaması (gönderilmezse değişmez) |
| `city` | string | No | Türkiye şehri (yeni kayıtta zorunlu, sonraki güncellemelerde gönderilmezse değişmez) |
| `department` | string | No | Departman (yeni kayıtta zorunlu, sonraki güncellemelerde gönderilmezse değişmez) |
| `income_status` | [IncomeLevel](IncomeLevel.md) | No |  |
| `about` | string | No | Hakkında metni (gönderilmezse değişmez) |

