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
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  Student({
    this.profileId,
    this.gpa,
    this.city,
    this.department,
    this.incomeStatus,
    this.about,
    this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) =>
      _$StudentFromJson(json);

  Map<String, dynamic> toJson() => _$StudentToJson(this);
}
