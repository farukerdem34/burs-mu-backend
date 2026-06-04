# Task 05: Student Feature

## Goal
Create student list, detail, edit screens, and match results display.

## Files to Create

### `lib/providers/student_provider.dart`
- `studentListProvider` — FutureProvider that fetches all students.
- `studentDetailProvider` — FutureProvider.family for a single student.
- `currentStudentProvider` — fetches student by current user's profile ID.

### `lib/features/student/student_list_screen.dart`
- ListView of all students.
- Each tile shows: city, department, GPA, income level.
- Tap to navigate to detail screen.

### `lib/features/student/student_detail_screen.dart`
- Profile ID, city, department, GPA, income level, about text.
- "Eşleşme Sonuçlarını Gör" button → navigates to match screen.
- "Düzenle" button (only if it's the current user's profile).

### `lib/features/student/student_edit_screen.dart`
- Form with fields: city (dropdown from API), department (dropdown), income level (dropdown), GPA (numeric), about (text).
- Pre-populate with existing values.
- Save button → PUT /students/{profile_id}.
- Show success SnackBar, pop back.

### `lib/providers/match_provider.dart`
- `matchResultsProvider` — FutureProvider.family that calls match service.

### `lib/features/student/match_result_screen.dart`
- List of matched scholarships sorted by score (descending).
- Each card shows: scholarship title, score (as percentage or bar).
- Tap to navigate to scholarship detail.

## Verification
- Student list loads from API.
- Student detail shows correct data.
- Editing a student saves changes.
- Match results display with scores.
