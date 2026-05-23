import 'package:json_annotation/json_annotation.dart';

import '../../domain/income_type.dart';

part 'income_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class IncomeModel {
  final String id;
  final IncomeType type;
  final double grossSalary;
  final bool receivesVr;
  final double vrAmount;
  final bool receivesVa;
  final double vaAmount;
  final double commission;
  final double bonus;
  final double otherIncome;

  const IncomeModel({
    required this.id,
    required this.type,
    required this.grossSalary,
    required this.receivesVr,
    required this.vrAmount,
    required this.receivesVa,
    required this.vaAmount,
    required this.commission,
    required this.bonus,
    required this.otherIncome,
  });

  double get totalGrossIncome =>
      grossSalary + (receivesVr ? vrAmount : 0) + (receivesVa ? vaAmount : 0) + commission + bonus + otherIncome;

  factory IncomeModel.fromJson(Map<String, dynamic> json) => _$IncomeModelFromJson(json);
  Map<String, dynamic> toJson() => _$IncomeModelToJson(this);

  IncomeModel copyWith({
    String? id,
    IncomeType? type,
    double? grossSalary,
    bool? receivesVr,
    double? vrAmount,
    bool? receivesVa,
    double? vaAmount,
    double? commission,
    double? bonus,
    double? otherIncome,
  }) {
    return IncomeModel(
      id: id ?? this.id,
      type: type ?? this.type,
      grossSalary: grossSalary ?? this.grossSalary,
      receivesVr: receivesVr ?? this.receivesVr,
      vrAmount: vrAmount ?? this.vrAmount,
      receivesVa: receivesVa ?? this.receivesVa,
      vaAmount: vaAmount ?? this.vaAmount,
      commission: commission ?? this.commission,
      bonus: bonus ?? this.bonus,
      otherIncome: otherIncome ?? this.otherIncome,
    );
  }
}
