import 'package:json_annotation/json_annotation.dart';

enum IncomeType {
  @JsonValue('CLT')
  clt,
  @JsonValue('PJ')
  pj,
  @JsonValue('autonomo')
  autonomo,
}
