import 'package:json_annotation/json_annotation.dart';
import 'income_level.dart';

part 'update_student_request.g.dart';

@JsonSerializable()
class UpdateStudentRequest {
  final double? gpa;
  final String? city;
  final String? department;
  @JsonKey(name: 'income_status')
  final IncomeLevel? incomeStatus;
  final String? about;

  UpdateStudentRequest({
    this.gpa,
    this.city,
    this.department,
    this.incomeStatus,
    this.about,
  });

  factory UpdateStudentRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateStudentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateStudentRequestToJson(this);
}
