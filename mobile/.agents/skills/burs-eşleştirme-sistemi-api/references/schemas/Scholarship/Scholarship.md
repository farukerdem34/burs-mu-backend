# Scholarship

**Type:** object

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string (uuid) | No |  |
| `donor_id` | string (uuid) | No |  |
| `title` | string | No |  |
| `quota` | integer | No |  |
| `is_active` | boolean | No |  |
| `min_gpa` | number (float) | No |  |
| `target_cities` | string[] | No | Boş array = tüm şehirler |
| `target_departments` | string[] | No | Boş array = tüm departmanlar |
| `target_income_levels` | IncomeLevel[] | No | Boş array = tüm gelir düzeyleri |
| `created_at` | string (date-time) | No |  |

