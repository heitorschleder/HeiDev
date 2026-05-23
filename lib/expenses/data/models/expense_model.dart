import 'package:json_annotation/json_annotation.dart';

import '../../domain/expense_category.dart';
import '../../domain/expense_priority.dart';

part 'expense_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class ExpenseModel {
  final String id;
  final String? templateId;
  final String title;
  final ExpenseCategory category;
  final bool isEssential;
  final double amount;
  final DateTime dueDate;
  final bool paid;
  final DateTime? paidAt;
  final ExpensePriority priority;
  final DateTime referenceMonth;
  final String? notes;

  const ExpenseModel({
    required this.id,
    this.templateId,
    required this.title,
    required this.category,
    required this.isEssential,
    required this.amount,
    required this.dueDate,
    required this.paid,
    this.paidAt,
    required this.priority,
    required this.referenceMonth,
    this.notes,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => _$ExpenseModelFromJson(json);
  Map<String, dynamic> toJson() => _$ExpenseModelToJson(this);

  ExpenseModel copyWith({
    String? id,
    String? templateId,
    String? title,
    ExpenseCategory? category,
    bool? isEssential,
    double? amount,
    DateTime? dueDate,
    bool? paid,
    DateTime? paidAt,
    ExpensePriority? priority,
    DateTime? referenceMonth,
    String? notes,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      title: title ?? this.title,
      category: category ?? this.category,
      isEssential: isEssential ?? this.isEssential,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paid: paid ?? this.paid,
      paidAt: paidAt ?? this.paidAt,
      priority: priority ?? this.priority,
      referenceMonth: referenceMonth ?? this.referenceMonth,
      notes: notes ?? this.notes,
    );
  }
}
