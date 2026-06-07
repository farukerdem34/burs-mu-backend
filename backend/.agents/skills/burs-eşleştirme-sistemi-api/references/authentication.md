# Authentication

This document describes the authentication methods supported by this API.

## BearerAuth

**Type:** http

Authorization: Bearer `<uuid>` — profile UUID returned by `/register` or `/login`. No JWT, no expiry. The UUID must exist in the `profiles` table.


- **Scheme:** bearer

