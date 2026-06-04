import 'package:json_annotation/json_annotation.dart';

part 'donor.g.dart';

@JsonSerializable()
class Donor {
  @JsonKey(name: 'profile_id')
  final String? profileId;
  @JsonKey(name: 'is_verified')
  final bool? isVerified;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  Donor({
    this.profileId,
    this.isVerified,
    this.createdAt,
  });

  factory Donor.fromJson(Map<String, dynamic> json) => _$DonorFromJson(json);

  Map<String, dynamic> toJson() => _$DonorToJson(this);
}
