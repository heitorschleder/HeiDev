import 'package:equatable/equatable.dart';

import '../expense_payment_method.dart';

class ExpenseFormState extends Equatable {
  final bool isSaving;
  final bool savedSuccess;
  final bool deleteSuccess;
  final String? errorMessage;
  final List<ExpensePaymentMethod> allowedPaymentMethods;

  const ExpenseFormState({
    this.isSaving = false,
    this.savedSuccess = false,
    this.deleteSuccess = false,
    this.errorMessage,
    this.allowedPaymentMethods = ExpensePaymentMethod.values,
  });

  factory ExpenseFormState.initial() => const ExpenseFormState();

  ExpenseFormState copyWith({
    bool? isSaving,
    bool? savedSuccess,
    bool? deleteSuccess,
    String? errorMessage,
    bool resetError = false,
    List<ExpensePaymentMethod>? allowedPaymentMethods,
  }) {
    return ExpenseFormState(
      isSaving: isSaving ?? this.isSaving,
      savedSuccess: savedSuccess ?? false,
      deleteSuccess: deleteSuccess ?? false,
      errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
      allowedPaymentMethods: allowedPaymentMethods ?? this.allowedPaymentMethods,
    );
  }

  @override
  List<Object?> get props => [isSaving, savedSuccess, deleteSuccess, errorMessage, allowedPaymentMethods];
}
