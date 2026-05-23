import 'package:json_annotation/json_annotation.dart';

enum ExpenseCategory {
  @JsonValue('casa')
  casa,
  @JsonValue('transporte')
  transporte,
  @JsonValue('alimentacao')
  alimentacao,
  @JsonValue('saude')
  saude,
  @JsonValue('lazer')
  lazer,
  @JsonValue('impostos')
  impostos,
  @JsonValue('outros')
  outros,
}
