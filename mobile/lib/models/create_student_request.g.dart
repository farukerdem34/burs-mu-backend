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
  semester: (json['semester'] as num?)?.toInt(),
  familyIncome: (json['family_income'] as num?)?.toDouble(),
  householdSize: (json['household_size'] as num?)?.toInt(),
  numSiblingsInEducation: (json['num_siblings_in_education'] as num?)?.toInt(),
  hasDisability: json['has_disability'] as bool?,
  isOrphan: json['is_orphan'] as bool?,
  isRefugee: json['is_refugee'] as bool?,
  academicStanding: json['academic_standing'] as String?,
  extracurricularScore: (json['extracurricular_score'] as num?)?.toInt(),
);

Map<String, dynamic> _$CreateStudentRequestToJson(
  CreateStudentRequest instance,
) => <String, dynamic>{
  'profile_id': instance.profileId,
  'gpa': instance.gpa,
  'city': instance.city,
  'department': instance.department,
  'income_status': _$IncomeLevelEnumMap[instance.incomeStatus]!,
  'semester': instance.semester,
  'family_income': instance.familyIncome,
  'household_size': instance.householdSize,
  'num_siblings_in_education': instance.numSiblingsInEducation,
  'has_disability': instance.hasDisability,
  'is_orphan': instance.isOrphan,
  'is_refugee': instance.isRefugee,
  'academic_standing': instance.academicStanding,
  'extracurricular_score': instance.extracurricularScore,
};

const _$IncomeLevelEnumMap = {
  IncomeLevel.low: 0,
  IncomeLevel.medium: 1,
  IncomeLevel.high: 2,
};
