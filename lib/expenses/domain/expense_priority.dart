import 'package:json_annotation/json_annotation.dart';

enum ExpensePriority {
  @JsonValue('alta')
  alta,
  @JsonValue('media')
  media,
  @JsonValue('baixa')
  baixa,
}
