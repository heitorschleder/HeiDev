import 'package:json_annotation/json_annotation.dart';

import '../../domain/expense_category.dart';

part 'bill_template_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class BillTemplateModel {
  final String id;
  final String title;
  final ExpenseCategory category;
  final bool isEssential;
  final double defaultAmount;

  const BillTemplateModel({
    required this.id,
    required this.title,
    required this.category,
    required this.isEssential,
    required this.defaultAmount,
  });

  factory BillTemplateModel.fromJson(Map<String, dynamic> json) => _$BillTemplateModelFromJson(json);
  Map<String, dynamic> toJson() => _$BillTemplateModelToJson(this);

  BillTemplateModel copyWith({
    String? id,
    String? title,
    ExpenseCategory? category,
    bool? isEssential,
    double? defaultAmount,
  }) {
    return BillTemplateModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      isEssential: isEssential ?? this.isEssential,
      defaultAmount: defaultAmount ?? this.defaultAmount,
    );
  }
}
