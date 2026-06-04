import 'package:json_annotation/json_annotation.dart';
import 'user_role.dart';

part 'profile.g.dart';

@JsonSerializable()
class Profile {
  final String? id;
  final UserRole? role;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  Profile({
    this.id,
    this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileToJson(this);
}
