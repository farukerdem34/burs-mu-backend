import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum UserRole {
  @JsonValue('student')
  student,
  @JsonValue('donor')
  donor,
  @JsonValue('admin')
  admin;

  String get displayName {
    switch (this) {
      case UserRole.student:
        return 'Öğrenci';
      case UserRole.donor:
        return 'Bağışçı';
      case UserRole.admin:
        return 'Admin';
    }
  }
}
