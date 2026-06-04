import 'package:json_annotation/json_annotation.dart';

part 'named_item.g.dart';

@JsonSerializable()
class NamedItem {
  final String? name;

  NamedItem({this.name});

  factory NamedItem.fromJson(Map<String, dynamic> json) =>
      _$NamedItemFromJson(json);

  Map<String, dynamic> toJson() => _$NamedItemToJson(this);
}
