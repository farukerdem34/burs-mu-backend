---
name: burs-eşleştirme-sistemi-api
description: Backend API for the scholarship matching system.. Use when working with the Burs Eşleştirme Sistemi API or when the user needs to interact with this API.
metadata:
  api-version: "2.0.0"
  openapi-version: "3.0.3"
---

# Burs Eşleştirme Sistemi API

Backend API for the scholarship matching system.

## How to Use This Skill

This API documentation is split into multiple files for on-demand loading.

**Directory structure:**
```
references/
├── resources/      # 8 resource index files
├── operations/     # 25 operation detail files
└── schemas/        # 15 schema groups, 22 schema files
```

**Navigation flow:**
1. Find the resource you need in the list below
2. Read `references/resources/<resource>.md` to see available operations
3. Read `references/operations/<operation>.md` for full details
4. If an operation references a schema, read `references/schemas/<prefix>/<schema>.md`

## Base URL

- `http://localhost:8080` - Local development (direct)
- `http://host.docker.internal:8080` - Local development (Docker)

## Authentication

Supported methods: **BearerAuth**. See `references/authentication.md` for details.

## Resources

- **Öğrenciler** → `references/resources/Öğrenciler.md` (5 ops)
- **Referanslar** → `references/resources/Referanslar.md` (5 ops)
- **Donorlar** → `references/resources/Donorlar.md` (4 ops)
- **Profiller** → `references/resources/Profiller.md` (3 ops)
- **Burslar** → `references/resources/Burslar.md` (3 ops)
- **Auth** → `references/resources/Auth.md` (2 ops)
- **Eşleştirme** → `references/resources/Eşleştirme.md` (2 ops)
- **Sağlık** → `references/resources/Sağlık.md` (1 ops)
