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
  @JsonValue('vestuario')
  vestuario,
  @JsonValue('cosmeticos')
  cosmeticos,
  @JsonValue('assinaturas')
  assinaturas,
  @JsonValue('pet')
  pet,
  @JsonValue('outros')
  outros,
}
