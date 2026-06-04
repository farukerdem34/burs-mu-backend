import 'package:json_annotation/json_annotation.dart';
import 'income_level.dart';

part 'create_student_request.g.dart';

@JsonSerializable()
class CreateStudentRequest {
  @JsonKey(name: 'profile_id')
  final String profileId;
  final double? gpa;
  final String city;
  final String department;
  @JsonKey(name: 'income_status')
  final IncomeLevel incomeStatus;

  CreateStudentRequest({
    required this.profileId,
    this.gpa,
    required this.city,
    required this.department,
    required this.incomeStatus,
  });

  factory CreateStudentRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateStudentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateStudentRequestToJson(this);
}
