import 'package:json_annotation/json_annotation.dart';
import 'income_level.dart';

part 'scholarship.g.dart';

@JsonSerializable()
class Scholarship {
  final String? id;
  @JsonKey(name: 'donor_id')
  final String? donorId;
  final String? title;
  final int? quota;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'min_gpa')
  final double? minGpa;
  @JsonKey(name: 'target_cities')
  final List<String>? targetCities;
  @JsonKey(name: 'target_departments')
  final List<String>? targetDepartments;
  @JsonKey(name: 'target_income_levels')
  final List<IncomeLevel>? targetIncomeLevels;
  @JsonKey(name: 'amount_per_year')
  final double? amountPerYear;
  @JsonKey(name: 'duration_months')
  final int? durationMonths;
  @JsonKey(name: 'scholarship_type')
  final String? scholarshipType;
  @JsonKey(name: 'preferred_gender')
  final String? preferredGender;
  @JsonKey(name: 'requires_essay')
  final bool? requiresEssay;
  @JsonKey(name: 'requires_interview')
  final bool? requiresInterview;
  @JsonKey(name: 'accepts_disability')
  final bool? acceptsDisability;
  @JsonKey(name: 'accepts_orphan')
  final bool? acceptsOrphan;
  @JsonKey(name: 'accepts_refugee')
  final bool? acceptsRefugee;
  @JsonKey(name: 'max_semester')
  final int? maxSemester;
  @JsonKey(name: 'min_extracurricular_score')
  final int? minExtracurricularScore;
  @JsonKey(name: 'max_household_income')
  final double? maxHouseholdIncome;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  Scholarship({
    this.id,
    this.donorId,
    this.title,
    this.quota,
    this.isActive,
    this.minGpa,
    this.targetCities,
    this.targetDepartments,
    this.targetIncomeLevels,
    this.amountPerYear,
    this.durationMonths,
    this.scholarshipType,
    this.preferredGender,
    this.requiresEssay,
    this.requiresInterview,
    this.acceptsDisability,
    this.acceptsOrphan,
    this.acceptsRefugee,
    this.maxSemester,
    this.minExtracurricularScore,
    this.maxHouseholdIncome,
    this.createdAt,
  });

  factory Scholarship.fromJson(Map<String, dynamic> json) =>
      _$ScholarshipFromJson(json);

  Map<String, dynamic> toJson() => _$ScholarshipToJson(this);
}
