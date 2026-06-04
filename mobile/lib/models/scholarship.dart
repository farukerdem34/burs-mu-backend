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
    this.createdAt,
  });

  factory Scholarship.fromJson(Map<String, dynamic> json) =>
      _$ScholarshipFromJson(json);

  Map<String, dynamic> toJson() => _$ScholarshipToJson(this);
}
