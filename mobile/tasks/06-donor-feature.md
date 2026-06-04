# Task 06: Donor Feature

## Goal
Create donor list and detail screens.

## Files to Create

### `lib/providers/donor_provider.dart`
- `donorListProvider` — FutureProvider for all donors.
- `donorDetailProvider` — FutureProvider.family.

### `lib/features/donor/donor_list_screen.dart`
- ListView of all donors.
- Show verified status (badge/icon).
- Tap to navigate to detail.

### `lib/features/donor/donor_detail_screen.dart`
- Profile ID, verified status, created date.
- If admin: show "Doğrula" button (POST /donors/{profile_id}/verify).
- Donor's scholarships list (fetched separately).

## Verification
- Donor list loads correctly.
- Verified/unverified status is visible.
- Admin can verify a donor.
