# Task 08: Admin Feature

## Goal
Create admin-only screens: donor verification and department management.

## Files to Create

### `lib/features/admin/donor_verify_screen.dart`
- List of unverified donors.
- "Doğrula" button next to each.
- Confirmation dialog before verifying.
- Refresh list after verification.

### `lib/features/admin/department_manage_screen.dart`
- List all departments (from GET /departments).
- Swipe-to-delete with confirmation.
- Show snackbar on success/failure.
- Note: DELETE /departments/{name} requires admin auth.

## Verification
- Admin can see unverified donors.
- Admin can verify a donor.
- Admin can delete a department.
- Non-admin users get 403 on these actions.
