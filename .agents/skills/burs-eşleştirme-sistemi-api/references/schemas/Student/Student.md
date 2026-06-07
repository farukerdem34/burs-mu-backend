# Student

**Type:** object

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `profile_id` | string (uuid) | No |  |
| `gpa` | number (float) | No |  |
| `city` | string | No | Türkiye şehri |
| `department` | string | No |  |
| `income_status` | [IncomeLevel](IncomeLevel.md) | No |  |
| `about` | string | No | Öğrencinin kendisi hakkında yazdığı metin |
| `semester` | integer | No | Kaçıncı dönem (1-12) |
| `family_income` | number (double) | No | Aylık aile geliri (TL) |
| `household_size` | integer | No | Hanedeki kişi sayısı |
| `num_siblings_in_education` | integer | No | Eğitimdeki kardeş sayısı |
| `has_disability` | boolean | No | Engellilik durumu |
| `is_orphan` | boolean | No | Yetim/öksüz durumu |
| `is_refugee` | boolean | No | Mülteci durumu |
| `academic_standing` | [AcademicStanding](AcademicStanding.md) | No |  |
| `extracurricular_score` | integer | No | Sosyal/ekstra-aktif puanı (0-10) |
| `created_at` | string (date-time) | No |  |

