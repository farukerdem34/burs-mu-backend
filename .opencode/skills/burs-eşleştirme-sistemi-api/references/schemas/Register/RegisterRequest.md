# RegisterRequest

**Type:** object

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `email` | string (email) | Yes |  |
| `password` | string | Yes |  |
| `role` | [UserRole](UserRole.md) | Yes |  |
| `city` | string | No | Rol 'student' ise kayıt anında girilebilir, sonradan da eklenebilir. |
| `department` | string | No | Rol 'student' ise kayıt anında girilebilir, sonradan da eklenebilir. Benzer isimler otomatik eşleştirilir. |
| `income_status` | [IncomeLevel](IncomeLevel.md) | No |  |
| `gpa` | number (float) | No | Not ortalaması (opsiyonel) |

