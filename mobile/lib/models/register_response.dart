import 'package:json_annotation/json_annotation.dart';
import 'user_role.dart';

part 'register_response.g.dart';

@JsonSerializable()
class RegisterResponse {
  final String? id;
  final String? email;
  final UserRole? role;
  final String? message;

  RegisterResponse({this.id, this.email, this.role, this.message});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      _$RegisterResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RegisterResponseToJson(this);
}
