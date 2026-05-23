import 'package:equatable/equatable.dart';

class ExpenseFormState extends Equatable {
  final bool isSaving;
  final bool savedSuccess;
  final String? errorMessage;

  const ExpenseFormState({
    this.isSaving = false,
    this.savedSuccess = false,
    this.errorMessage,
  });

  factory ExpenseFormState.initial() => const ExpenseFormState();

  ExpenseFormState copyWith({
    bool? isSaving,
    bool? savedSuccess,
    String? errorMessage,
    bool resetError = false,
  }) {
    return ExpenseFormState(
      isSaving: isSaving ?? this.isSaving,
      savedSuccess: savedSuccess ?? false,
      errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isSaving, savedSuccess, errorMessage];
}
