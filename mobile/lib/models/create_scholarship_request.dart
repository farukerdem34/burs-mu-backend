import 'package:json_annotation/json_annotation.dart';
import 'income_level.dart';

part 'create_scholarship_request.g.dart';

@JsonSerializable()
class CreateScholarshipRequest {
  @JsonKey(name: 'donor_id')
  final String? donorId;
  final String title;
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

  CreateScholarshipRequest({
    this.donorId,
    required this.title,
    this.quota,
    this.isActive,
    this.minGpa,
    this.targetCities,
    this.targetDepartments,
    this.targetIncomeLevels,
  });

  factory CreateScholarshipRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateScholarshipRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateScholarshipRequestToJson(this);
}
