import 'package:json_annotation/json_annotation.dart';
import 'income_level.dart';
import 'user_role.dart';

part 'register_request.g.dart';

@JsonSerializable()
class RegisterRequest {
  final String email;
  final String password;
  final UserRole role;
  final String? city;
  final String? department;
  @JsonKey(name: 'income_status')
  final IncomeLevel? incomeStatus;
  final double? gpa;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.role,
    this.city,
    this.department,
    this.incomeStatus,
    this.gpa,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}
