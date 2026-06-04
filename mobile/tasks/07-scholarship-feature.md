# Task 07: Scholarship Feature

## Goal
Create scholarship list, detail, and creation screens.

## Files to Create

### `lib/providers/scholarship_provider.dart`
- `scholarshipListProvider` — FutureProvider for all scholarships.
- `scholarshipDetailProvider` — FutureProvider.family.

### `lib/features/scholarship/scholarship_list_screen.dart`
- ListView of all active scholarships.
- Show title, quota, min GPA, target info.
- Tap to navigate to detail.

### `lib/features/scholarship/scholarship_detail_screen.dart`
- Title, donor, quota, active status, min GPA.
- Target cities, departments, income levels as chips.
- Created date.

### `lib/features/scholarship/scholarship_create_screen.dart`
- Donor only (check role).
- Form: title, quota, is_active toggle, min GPA.
- Multi-select: target cities (from API), target departments, income levels.
- Submit → POST /scholarships.
- On success: navigate to scholarship list.

## Verification
- Scholarship list loads.
- Detail shows all fields.
- Donor can create a new scholarship.
