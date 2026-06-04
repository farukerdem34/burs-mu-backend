# POST /scholarships

**Resource:** [Burslar](../resources/Burslar.md)
**Yeni burs oluştur**
**Operation ID:** `post--scholarships`

## Request Body

**Required:** Yes

**Content Types:** `application/json`

**Schema:** [CreateScholarshipRequest](../schemas/Create/CreateScholarshipRequest.md)

## Responses

| Status | Description |
|--------|-------------|
| 201 | Burs oluşturuldu |
| 400 | Geçersiz şehir, departman veya gelir düzeyi |
| 403 | Sadece burs verenler burs oluşturabilir |

**Success Response Schema:**

[Scholarship](../schemas/Scholarship/Scholarship.md)

## Security

- **BearerAuth**
