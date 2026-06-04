// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchResult _$MatchResultFromJson(Map<String, dynamic> json) => MatchResult(
  scholarshipId: json['scholarship_id'] as String?,
  score: (json['score'] as num?)?.toDouble(),
);

Map<String, dynamic> _$MatchResultToJson(MatchResult instance) =>
    <String, dynamic>{
      'scholarship_id': instance.scholarshipId,
      'score': instance.score,
    };
