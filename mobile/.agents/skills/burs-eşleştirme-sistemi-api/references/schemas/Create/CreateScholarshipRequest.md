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
| `target_departments` | string[] | No | Boş veya null = tüm departmanlar. Benzer isimler otomatik eşleştirilir. |
| `target_income_levels` | IncomeLevel[] | No | Boş veya null = tüm gelir düzeyleri |
| `amount_per_year` | number (double) | No | Yıllık burs miktarı (TL) |
| `duration_months` | integer | No |  |
| `scholarship_type` | [ScholarshipType](ScholarshipType.md) | No |  |
| `preferred_gender` | string | No | Cinsiyet tercihi: male veya female (null = farketmez) |
| `requires_essay` | boolean | No |  |
| `requires_interview` | boolean | No |  |
| `accepts_disability` | boolean | No |  |
| `accepts_orphan` | boolean | No |  |
| `accepts_refugee` | boolean | No |  |
| `max_semester` | integer | No | Maksimum dönem sınırı (null = sınırsız) |
| `min_extracurricular_score` | integer | No |  |
| `max_household_income` | number (double) | No | Maksimum aile geliri sınırı TL (null = sınırsız) |

