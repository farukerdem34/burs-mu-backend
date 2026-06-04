// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Student _$StudentFromJson(Map<String, dynamic> json) => Student(
  profileId: json['profile_id'] as String?,
  gpa: (json['gpa'] as num?)?.toDouble(),
  city: json['city'] as String?,
  department: json['department'] as String?,
  incomeStatus: $enumDecodeNullable(
    _$IncomeLevelEnumMap,
    json['income_status'],
  ),
  about: json['about'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$StudentToJson(Student instance) => <String, dynamic>{
  'profile_id': instance.profileId,
  'gpa': instance.gpa,
  'city': instance.city,
  'department': instance.department,
  'income_status': _$IncomeLevelEnumMap[instance.incomeStatus],
  'about': instance.about,
  'created_at': instance.createdAt?.toIso8601String(),
};

const _$IncomeLevelEnumMap = {
  IncomeLevel.low: 0,
  IncomeLevel.medium: 1,
  IncomeLevel.high: 2,
};
