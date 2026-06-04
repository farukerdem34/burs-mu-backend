// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scholarship.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Scholarship _$ScholarshipFromJson(Map<String, dynamic> json) => Scholarship(
  id: json['id'] as String?,
  donorId: json['donor_id'] as String?,
  title: json['title'] as String?,
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
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$ScholarshipToJson(Scholarship instance) =>
    <String, dynamic>{
      'id': instance.id,
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
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$IncomeLevelEnumMap = {
  IncomeLevel.low: 'low',
  IncomeLevel.medium: 'medium',
  IncomeLevel.high: 'high',
};
