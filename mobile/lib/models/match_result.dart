import 'package:json_annotation/json_annotation.dart';

part 'match_result.g.dart';

@JsonSerializable()
class MatchResult {
  @JsonKey(name: 'scholarship_id')
  final String? scholarshipId;
  final double? score;

  MatchResult({
    this.scholarshipId,
    this.score,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) =>
      _$MatchResultFromJson(json);

  Map<String, dynamic> toJson() => _$MatchResultToJson(this);
}
