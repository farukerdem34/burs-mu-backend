// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'donor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Donor _$DonorFromJson(Map<String, dynamic> json) => Donor(
  profileId: json['profile_id'] as String?,
  isVerified: json['is_verified'] as bool?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$DonorToJson(Donor instance) => <String, dynamic>{
  'profile_id': instance.profileId,
  'is_verified': instance.isVerified,
  'created_at': instance.createdAt?.toIso8601String(),
};
