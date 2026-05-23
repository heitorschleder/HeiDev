import 'package:equatable/equatable.dart';

import '../../data/models/expense_model.dart';
import '../expense_category.dart';

class ExpenseListState extends Equatable {
  final bool isLoading;
  final List<ExpenseModel> expenses;
  final DateTime selectedMonth;
  final ExpenseCategory? categoryFilter;
  final String? errorMessage;

  const ExpenseListState({
    this.isLoading = false,
    this.expenses = const [],
    required this.selectedMonth,
    this.categoryFilter,
    this.errorMessage,
  });

  factory ExpenseListState.initial() => ExpenseListState(
    isLoading: true,
    selectedMonth: DateTime(DateTime.now().year, DateTime.now().month),
  );

  List<ExpenseModel> get filtered =>
      categoryFilter == null ? expenses : expenses.where((e) => e.category == categoryFilter).toList();

  ExpenseListState copyWith({
    bool? isLoading,
    List<ExpenseModel>? expenses,
    DateTime? selectedMonth,
    ExpenseCategory? categoryFilter,
    bool clearFilter = false,
    String? errorMessage,
    bool resetError = false,
  }) {
    return ExpenseListState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      categoryFilter: clearFilter ? null : categoryFilter ?? this.categoryFilter,
      errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, expenses, selectedMonth, categoryFilter, errorMessage];
}
