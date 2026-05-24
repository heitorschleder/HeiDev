import 'package:equatable/equatable.dart';

import '../../data/models/expense_model.dart';
import '../expense_category.dart';
import '../expense_payment_method.dart';

class ExpenseListState extends Equatable {
  final bool isLoading;
  final List<ExpenseModel> expenses;
  final DateTime selectedMonth;
  final Set<ExpenseCategory> categoryFilters;
  final String textQuery;
  final Set<ExpensePaymentMethod> paymentFilters;
  final bool? essentialFilter;
  final bool installmentFilter;
  final String? errorMessage;

  const ExpenseListState({
    this.isLoading = false,
    this.expenses = const [],
    required this.selectedMonth,
    this.categoryFilters = const {},
    this.textQuery = '',
    this.paymentFilters = const {},
    this.essentialFilter,
    this.installmentFilter = false,
    this.errorMessage,
  });

  factory ExpenseListState.initial() => ExpenseListState(
    isLoading: true,
    selectedMonth: DateTime(DateTime.now().year, DateTime.now().month),
  );

  List<ExpenseModel> get filtered {
    var list = expenses;
    if (categoryFilters.isNotEmpty) {
      list = list.where((e) => categoryFilters.contains(e.category)).toList();
    }
    if (textQuery.isNotEmpty) {
      final q = textQuery.toLowerCase();
      list = list.where((e) => e.title.toLowerCase().contains(q)).toList();
    }
    if (paymentFilters.isNotEmpty) {
      list = list.where((e) => paymentFilters.contains(e.paymentMethod ?? ExpensePaymentMethod.dinheiro)).toList();
    }
    if (essentialFilter != null) list = list.where((e) => e.isEssential == essentialFilter).toList();
    if (installmentFilter) list = list.where((e) => e.totalInstallments != null).toList();
    return list;
  }

  ExpenseListState copyWith({
    bool? isLoading,
    List<ExpenseModel>? expenses,
    DateTime? selectedMonth,
    Set<ExpenseCategory>? categoryFilters,
    String? textQuery,
    Set<ExpensePaymentMethod>? paymentFilters,
    bool? essentialFilter,
    bool clearEssentialFilter = false,
    bool? installmentFilter,
    String? errorMessage,
    bool resetError = false,
    bool clearFilters = false,
  }) {
    return ExpenseListState(
      isLoading: isLoading ?? this.isLoading,
      expenses: expenses ?? this.expenses,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      categoryFilters: clearFilters ? const {} : categoryFilters ?? this.categoryFilters,
      textQuery: clearFilters ? '' : textQuery ?? this.textQuery,
      paymentFilters: clearFilters ? const {} : paymentFilters ?? this.paymentFilters,
      essentialFilter: clearFilters || clearEssentialFilter ? null : essentialFilter ?? this.essentialFilter,
      installmentFilter: clearFilters ? false : installmentFilter ?? this.installmentFilter,
      errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    expenses,
    selectedMonth,
    categoryFilters,
    textQuery,
    paymentFilters,
    essentialFilter,
    installmentFilter,
    errorMessage,
  ];
}
