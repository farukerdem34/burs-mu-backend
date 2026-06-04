// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_scholarship_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateScholarshipRequest _$CreateScholarshipRequestFromJson(
  Map<String, dynamic> json,
) => CreateScholarshipRequest(
  donorId: json['donor_id'] as String?,
  title: json['title'] as String,
  quota: (json['quota'] as num?)?.toInt(),
  isActive: json['is_active'] as bool?,
  minGpa: (json['min_gpa'] as num?)?.toDouble(),
  targetCities: (json['target_cities'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  targetDepartments: (json['target_departments'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  targetIncomeLevels: (json['target_income_levels'] as List<dynamic>?)
      ?.map((e) => $enumDecode(_$IncomeLevelEnumMap, e))
      .toList(),
);

Map<String, dynamic> _$CreateScholarshipRequestToJson(
  CreateScholarshipRequest instance,
) => <String, dynamic>{
  'donor_id': instance.donorId,
  'title': instance.title,
  'quota': instance.quota,
  'is_active': instance.isActive,
  'min_gpa': instance.minGpa,
  'target_cities': instance.targetCities,
  'target_departments': instance.targetDepartments,
  'target_income_levels': instance.targetIncomeLevels
      ?.map((e) => _$IncomeLevelEnumMap[e]!)
      .toList(),
};

const _$IncomeLevelEnumMap = {
  IncomeLevel.low: 0,
  IncomeLevel.medium: 1,
  IncomeLevel.high: 2,
};
