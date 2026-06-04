// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_student_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateStudentRequest _$CreateStudentRequestFromJson(
  Map<String, dynamic> json,
) => CreateStudentRequest(
  profileId: json['profile_id'] as String,
  gpa: (json['gpa'] as num?)?.toDouble(),
  city: json['city'] as String,
  department: json['department'] as String,
  incomeStatus: $enumDecode(_$IncomeLevelEnumMap, json['income_status']),
);

Map<String, dynamic> _$CreateStudentRequestToJson(
  CreateStudentRequest instance,
) => <String, dynamic>{
  'profile_id': instance.profileId,
  'gpa': instance.gpa,
  'city': instance.city,
  'department': instance.department,
  'income_status': _$IncomeLevelEnumMap[instance.incomeStatus]!,
};

const _$IncomeLevelEnumMap = {
  IncomeLevel.low: 0,
  IncomeLevel.medium: 1,
  IncomeLevel.high: 2,
};
