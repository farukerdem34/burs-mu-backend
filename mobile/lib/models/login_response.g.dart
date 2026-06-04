// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      id: json['id'] as String?,
      role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']),
      message: json['message'] as String?,
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': _$UserRoleEnumMap[instance.role],
      'message': instance.message,
    };

const _$UserRoleEnumMap = {
  UserRole.student: 'student',
  UserRole.donor: 'donor',
  UserRole.admin: 'admin',
};
