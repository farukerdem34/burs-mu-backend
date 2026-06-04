# CreateScholarshipRequest

**Type:** object

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `donor_id` | string (uuid) | No |  |
| `title` | string | Yes |  |
| `quota` | integer | No |  |
| `is_active` | boolean | No |  |
| `min_gpa` | number (float) | No |  |
| `target_cities` | string[] | No | Boş veya null = tüm şehirler. Yeni şehirler otomatik eklenir. |
| `target_departments` | string[] | No | Boş veya null = tüm departmanlar |
| `target_income_levels` | IncomeLevel[] | No | Boş veya null = tüm gelir düzeyleri |

