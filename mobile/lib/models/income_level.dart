import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum IncomeLevel {
  @JsonValue(0)
  low,
  @JsonValue(1)
  medium,
  @JsonValue(2)
  high;

  String get displayName {
    switch (this) {
      case IncomeLevel.low:
        return 'Düşük';
      case IncomeLevel.medium:
        return 'Orta';
      case IncomeLevel.high:
        return 'Yüksek';
    }
  }
}
