# Task 02: Models

## Goal
Create all DTO classes with `json_serializable` annotations.

## Models to Create

### `lib/models/user_role.dart`
```dart
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum UserRole {
  @JsonValue('student')
  student,
  @JsonValue('donor')
  donor,
  @JsonValue('admin')
  admin;
}
```

### `lib/models/income_level.dart`
```dart
import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum IncomeLevel {
  @JsonValue('low')
  low,
  @JsonValue('medium')
  medium,
  @JsonValue('high')
  high;
}
```

### `lib/models/profile.dart`
Fields: `id` (String?), `role` (UserRole?), `createdAt` (DateTime?), `updatedAt` (DateTime?)
Use `@JsonKey(name: 'created_at')` etc. for snake_case mapping.
Annotate with `@JsonSerializable()`, include `fromJson`/`toJson` methods.

### `lib/models/student.dart`
Fields: `profileId` (String?), `gpa` (double?), `city` (String?), `department` (String?), `incomeStatus` (IncomeLevel?), `about` (String?), `createdAt` (DateTime?)

### `lib/models/donor.dart`
Fields: `profileId` (String?), `isVerified` (bool?), `createdAt` (DateTime?)

### `lib/models/scholarship.dart`
Fields: `id` (String?), `donorId` (String?), `title` (String?), `quota` (int?), `isActive` (bool?), `minGpa` (double?), `targetCities` (List<String>?), `targetDepartments` (List<String>?), `targetIncomeLevels` (List<IncomeLevel>?), `createdAt` (DateTime?)

### `lib/models/match_result.dart`
Fields: `scholarshipId` (String?), `score` (double?)

### `lib/models/named_item.dart`
Fields: `name` (String?) — used for cities, departments, income levels, user roles.

### `lib/models/login_request.dart`
Fields: `email` (String), `password` (String)

### `lib/models/login_response.dart`
Fields: `id` (String?), `role` (UserRole?), `message` (String?)

### `lib/models/register_request.dart`
Fields: `email` (String), `password` (String), `role` (UserRole), `city` (String?), `department` (String?), `incomeStatus` (IncomeLevel?), `gpa` (double?)

### `lib/models/register_response.dart`
Fields: `id` (String?), `email` (String?), `role` (UserRole?), `message` (String?)

### `lib/models/create_student_request.dart`
Fields: `profileId` (String), `gpa` (double?), `city` (String), `department` (String), `incomeStatus` (IncomeLevel)

### `lib/models/update_student_request.dart`
Fields: `gpa` (double?), `city` (String?), `department` (String?), `incomeStatus` (IncomeLevel?), `about` (String?)

### `lib/models/create_scholarship_request.dart`
Fields: `donorId` (String?), `title` (String), `quota` (int?), `isActive` (bool?), `minGpa` (double?), `targetCities` (List<String>?), `targetDepartments` (List<String>?), `targetIncomeLevels` (List<IncomeLevel>?)

## Verification
- Run `dart run build_runner build --delete-conflicting-outputs` — all `.g.dart` files generated.
- Run `dart analyze` — zero errors.
