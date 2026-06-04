# UpdateStudentRequest

**Type:** object

## Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `gpa` | number (float) | No | Not ortalaması (gönderilmezse değişmez) |
| `city` | string | No | Türkiye şehri (yeni kayıtta zorunlu, sonraki güncellemelerde gönderilmezse değişmez) |
| `department` | string | No | Departman (yeni kayıtta zorunlu, sonraki güncellemelerde gönderilmezse değişmez). Benzer isimler otomatik eşleştirilir. |
| `income_status` | [IncomeLevel](IncomeLevel.md) | No |  |
| `about` | string | No | Hakkında metni (gönderilmezse değişmez) |
| `semester` | integer | No | Dönem (gönderilmezse değişmez) |
| `family_income` | number (double) | No | Aylık aile geliri TL (gönderilmezse değişmez) |
| `household_size` | integer | No | Hane büyüklüğü (gönderilmezse değişmez) |
| `num_siblings_in_education` | integer | No | Eğitimdeki kardeşler (gönderilmezse değişmez) |
| `has_disability` | boolean | No | Engellilik (gönderilmezse değişmez) |
| `is_orphan` | boolean | No | Yetim/öksüz (gönderilmezse değişmez) |
| `is_refugee` | boolean | No | Mülteci (gönderilmezse değişmez) |
| `academic_standing` | [AcademicStanding](AcademicStanding.md) | No |  |
| `extracurricular_score` | integer | No | Sosyal puan (gönderilmezse değişmez) |

