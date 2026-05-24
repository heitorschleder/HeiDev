import 'package:json_annotation/json_annotation.dart';

enum ExpensePaymentMethod {
  @JsonValue('dinheiro')
  dinheiro,
  @JsonValue('credito')
  credito,
  @JsonValue('debito')
  debito,
  @JsonValue('vale_alimentacao')
  valeAlimentacao,
  @JsonValue('vale_refeicao')
  valeRefeicao,
}
