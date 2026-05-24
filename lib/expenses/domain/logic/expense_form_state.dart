import 'package:equatable/equatable.dart';

class ExpenseFormState extends Equatable {
  final bool isSaving;
  final bool savedSuccess;
  final bool deleteSuccess;
  final String? errorMessage;

  const ExpenseFormState({
    this.isSaving = false,
    this.savedSuccess = false,
    this.deleteSuccess = false,
    this.errorMessage,
  });

  factory ExpenseFormState.initial() => const ExpenseFormState();

  ExpenseFormState copyWith({
    bool? isSaving,
    bool? savedSuccess,
    bool? deleteSuccess,
    String? errorMessage,
    bool resetError = false,
  }) {
    return ExpenseFormState(
      isSaving: isSaving ?? this.isSaving,
      savedSuccess: savedSuccess ?? false,
      deleteSuccess: deleteSuccess ?? false,
      errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isSaving, savedSuccess, deleteSuccess, errorMessage];
}
