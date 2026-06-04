import 'package:json_annotation/json_annotation.dart';
import 'income_level.dart';

part 'student.g.dart';

@JsonSerializable()
class Student {
  @JsonKey(name: 'profile_id')
  final String? profileId;
  final double? gpa;
  final String? city;
  final String? department;
  @JsonKey(name: 'income_status')
  final IncomeLevel? incomeStatus;
  final String? about;
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
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  Student({
    this.profileId,
    this.gpa,
    this.city,
    this.department,
    this.incomeStatus,
    this.about,
    this.semester,
    this.familyIncome,
    this.householdSize,
    this.numSiblingsInEducation,
    this.hasDisability,
    this.isOrphan,
    this.isRefugee,
    this.academicStanding,
    this.extracurricularScore,
    this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) =>
      _$StudentFromJson(json);

  Map<String, dynamic> toJson() => _$StudentToJson(this);
}
