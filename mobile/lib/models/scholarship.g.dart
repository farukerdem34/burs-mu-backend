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
  amountPerYear: (json['amount_per_year'] as num?)?.toDouble(),
  durationMonths: (json['duration_months'] as num?)?.toInt(),
  scholarshipType: json['scholarship_type'] as String?,
  preferredGender: json['preferred_gender'] as String?,
  requiresEssay: json['requires_essay'] as bool?,
  requiresInterview: json['requires_interview'] as bool?,
  acceptsDisability: json['accepts_disability'] as bool?,
  acceptsOrphan: json['accepts_orphan'] as bool?,
  acceptsRefugee: json['accepts_refugee'] as bool?,
  maxSemester: (json['max_semester'] as num?)?.toInt(),
  minExtracurricularScore: (json['min_extracurricular_score'] as num?)?.toInt(),
  maxHouseholdIncome: (json['max_household_income'] as num?)?.toDouble(),
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
      'amount_per_year': instance.amountPerYear,
      'duration_months': instance.durationMonths,
      'scholarship_type': instance.scholarshipType,
      'preferred_gender': instance.preferredGender,
      'requires_essay': instance.requiresEssay,
      'requires_interview': instance.requiresInterview,
      'accepts_disability': instance.acceptsDisability,
      'accepts_orphan': instance.acceptsOrphan,
      'accepts_refugee': instance.acceptsRefugee,
      'max_semester': instance.maxSemester,
      'min_extracurricular_score': instance.minExtracurricularScore,
      'max_household_income': instance.maxHouseholdIncome,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$IncomeLevelEnumMap = {
  IncomeLevel.low: 0,
  IncomeLevel.medium: 1,
  IncomeLevel.high: 2,
};
