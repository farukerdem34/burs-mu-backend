# CreateStudentRequest

**Type:** object

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `profile_id` | string (uuid) | Yes |  |
| `gpa` | number (float) | No |  |
| `city` | string | Yes | Geçerli bir Türkiye şehri |
| `department` | string | Yes | Departman adı. Benzer isimler otomatik eşleştirilir, yenisi eklenir. |
| `income_status` | [IncomeLevel](IncomeLevel.md) | Yes |  |
| `semester` | integer | No |  |
| `family_income` | number (double) | No |  |
| `household_size` | integer | No |  |
| `num_siblings_in_education` | integer | No |  |
| `has_disability` | boolean | No |  |
| `is_orphan` | boolean | No |  |
| `is_refugee` | boolean | No |  |
| `academic_standing` | [AcademicStanding](AcademicStanding.md) | No |  |
| `extracurricular_score` | integer | No |  |

