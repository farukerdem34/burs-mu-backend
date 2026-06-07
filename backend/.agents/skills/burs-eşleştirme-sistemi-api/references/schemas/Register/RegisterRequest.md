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
| `semester` | integer | No | Kaçıncı dönem (opsiyonel) |
| `family_income` | number (double) | No | Aylık aile geliri TL (opsiyonel) |
| `household_size` | integer | No | Hanedeki kişi sayısı (opsiyonel) |
| `num_siblings_in_education` | integer | No | Eğitimdeki kardeş sayısı (opsiyonel) |
| `has_disability` | boolean | No | Engellilik durumu (opsiyonel) |
| `is_orphan` | boolean | No | Yetim/öksüz durumu (opsiyonel) |
| `is_refugee` | boolean | No | Mülteci durumu (opsiyonel) |
| `academic_standing` | [AcademicStanding](AcademicStanding.md) | No |  |
| `extracurricular_score` | integer | No | Sosyal/ekstra-aktif puanı 0-10 (opsiyonel) |

