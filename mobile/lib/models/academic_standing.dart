import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum AcademicStanding {
  @JsonValue('probation')
  probation,
  @JsonValue('good')
  good,
  @JsonValue('honor')
  honor,
  @JsonValue('high_honor')
  highHonor;

  String get displayName {
    switch (this) {
      case AcademicStanding.probation:
        return 'Şartlı';
      case AcademicStanding.good:
        return 'İyi';
      case AcademicStanding.honor:
        return 'Onur';
      case AcademicStanding.highHonor:
        return 'Yüksek Onur';
    }
  }
}
