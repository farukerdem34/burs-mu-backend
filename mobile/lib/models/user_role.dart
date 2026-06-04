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
