# CreateStudentRequest

**Type:** object

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `profile_id` | string (uuid) | Yes |  |
| `gpa` | number (float) | No |  |
| `city` | string | Yes | Geçerli bir Türkiye şehri |
| `department` | string | Yes | Mevcut bir departman (FK) |
| `income_status` | [IncomeLevel](IncomeLevel.md) | Yes |  |

