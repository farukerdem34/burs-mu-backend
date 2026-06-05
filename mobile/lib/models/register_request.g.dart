// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'register_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegisterRequest _$RegisterRequestFromJson(Map<String, dynamic> json) =>
    RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      role: $enumDecode(_$UserRoleEnumMap, json['role']),
      city: json['city'] as String?,
      department: json['department'] as String?,
      incomeStatus: $enumDecodeNullable(
        _$IncomeLevelEnumMap,
        json['income_status'],
      ),
      gpa: (json['gpa'] as num?)?.toDouble(),
      semester: (json['semester'] as num?)?.toInt(),
      familyIncome: (json['family_income'] as num?)?.toDouble(),
      householdSize: (json['household_size'] as num?)?.toInt(),
      numSiblingsInEducation: (json['num_siblings_in_education'] as num?)
          ?.toInt(),
      hasDisability: json['has_disability'] as bool?,
      isOrphan: json['is_orphan'] as bool?,
      isRefugee: json['is_refugee'] as bool?,
      academicStanding: $enumDecodeNullable(
        _$AcademicStandingEnumMap,
        json['academic_standing'],
      ),
      extracurricularScore: (json['extracurricular_score'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RegisterRequestToJson(RegisterRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'role': _$UserRoleEnumMap[instance.role]!,
      'city': instance.city,
      'department': instance.department,
      'income_status': _$IncomeLevelEnumMap[instance.incomeStatus],
      'gpa': instance.gpa,
      'semester': instance.semester,
      'family_income': instance.familyIncome,
      'household_size': instance.householdSize,
      'num_siblings_in_education': instance.numSiblingsInEducation,
      'has_disability': instance.hasDisability,
      'is_orphan': instance.isOrphan,
      'is_refugee': instance.isRefugee,
      'academic_standing': _$AcademicStandingEnumMap[instance.academicStanding],
      'extracurricular_score': instance.extracurricularScore,
    };

const _$UserRoleEnumMap = {
  UserRole.student: 'student',
  UserRole.donor: 'donor',
  UserRole.admin: 'admin',
};

const _$IncomeLevelEnumMap = {
  IncomeLevel.low: 0,
  IncomeLevel.medium: 1,
  IncomeLevel.high: 2,
};

const _$AcademicStandingEnumMap = {
  AcademicStanding.probation: 'probation',
  AcademicStanding.good: 'good',
  AcademicStanding.honor: 'honor',
  AcademicStanding.highHonor: 'high_honor',
};
