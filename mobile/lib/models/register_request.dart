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
  final int? semester;
  @JsonKey(name: 'family_income')
  final double? familyIncome;
  @JsonKey(name: 'household_size')
  final int? householdSize;
  @JsonKey(name: 'num_siblings_in_education')
  final int? numSiblingsInEducation;
  @JsonKey(name: 'has_disability')
  final bool? hasDisability;
  @JsonKey(name: 'is_orphan')
  final bool? isOrphan;
  @JsonKey(name: 'is_refugee')
  final bool? isRefugee;
  @JsonKey(name: 'academic_standing')
  final String? academicStanding;
  @JsonKey(name: 'extracurricular_score')
  final int? extracurricularScore;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.role,
    this.city,
    this.department,
    this.incomeStatus,
    this.gpa,
    this.semester,
    this.familyIncome,
    this.householdSize,
    this.numSiblingsInEducation,
    this.hasDisability,
    this.isOrphan,
    this.isRefugee,
    this.academicStanding,
    this.extracurricularScore,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterRequestToJson(this);
}
