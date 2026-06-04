// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_student_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateStudentRequest _$UpdateStudentRequestFromJson(
  Map<String, dynamic> json,
) => UpdateStudentRequest(
  gpa: (json['gpa'] as num?)?.toDouble(),
  city: json['city'] as String?,
  department: json['department'] as String?,
  incomeStatus: $enumDecodeNullable(
    _$IncomeLevelEnumMap,
    json['income_status'],
  ),
  about: json['about'] as String?,
);

Map<String, dynamic> _$UpdateStudentRequestToJson(
  UpdateStudentRequest instance,
) => <String, dynamic>{
  'gpa': instance.gpa,
  'city': instance.city,
  'department': instance.department,
  'income_status': _$IncomeLevelEnumMap[instance.incomeStatus],
  'about': instance.about,
};

const _$IncomeLevelEnumMap = {
  IncomeLevel.low: 'low',
  IncomeLevel.medium: 'medium',
  IncomeLevel.high: 'high',
};
