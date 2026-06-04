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
    };

const _$UserRoleEnumMap = {
  UserRole.student: 'student',
  UserRole.donor: 'donor',
  UserRole.admin: 'admin',
};

const _$IncomeLevelEnumMap = {
  IncomeLevel.low: 'low',
  IncomeLevel.medium: 'medium',
  IncomeLevel.high: 'high',
};
