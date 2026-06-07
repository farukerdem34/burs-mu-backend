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
| `amount_per_year` | number (double) | No | Yıllık burs miktarı (TL) |
| `duration_months` | integer | No | Burs süresi (ay) |
| `scholarship_type` | [ScholarshipType](ScholarshipType.md) | No |  |
| `preferred_gender` | string | No | Cinsiyet tercihi (male/female, null=farketmez) |
| `requires_essay` | boolean | No |  |
| `requires_interview` | boolean | No |  |
| `accepts_disability` | boolean | No |  |
| `accepts_orphan` | boolean | No |  |
| `accepts_refugee` | boolean | No |  |
| `max_semester` | integer | No | Maksimum dönem sınırı |
| `min_extracurricular_score` | integer | No |  |
| `max_household_income` | number (double) | No | Maksimum aile geliri sınırı (TL) |
| `created_at` | string (date-time) | No |  |

