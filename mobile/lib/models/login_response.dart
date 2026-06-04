import 'package:json_annotation/json_annotation.dart';
import 'user_role.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  final String? id;
  final UserRole? role;
  final String? message;

  LoginResponse({this.id, this.role, this.message});

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}
