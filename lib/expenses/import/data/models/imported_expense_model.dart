import '../../../domain/expense_category.dart';
import '../../../domain/expense_payment_method.dart';

class ImportedExpenseModel {
  final String rawTitle;
  final double rawAmount;
  final DateTime rawDate;

  final String title;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final bool isEssential;
  final ExpensePaymentMethod? paymentMethod;
  final bool isDuplicate;
  final bool isConfirmed;
  final bool isSkipped;

  const ImportedExpenseModel({
    required this.rawTitle,
    required this.rawAmount,
    required this.rawDate,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.isEssential = false,
    this.paymentMethod,
    this.isDuplicate = false,
    this.isConfirmed = false,
    this.isSkipped = false,
  });

  ImportedExpenseModel copyWith({
    String? title,
    ExpenseCategory? category,
    double? amount,
    DateTime? date,
    bool? isEssential,
    Object? paymentMethod = _sentinel,
    bool? isDuplicate,
    bool? isConfirmed,
    bool? isSkipped,
  }) {
    return ImportedExpenseModel(
      rawTitle: rawTitle,
      rawAmount: rawAmount,
      rawDate: rawDate,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isEssential: isEssential ?? this.isEssential,
      paymentMethod: paymentMethod == _sentinel ? this.paymentMethod : paymentMethod as ExpensePaymentMethod?,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isSkipped: isSkipped ?? this.isSkipped,
    );
  }
}

const _sentinel = Object();
