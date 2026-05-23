import 'package:equatable/equatable.dart';

import '../../data/models/income_model.dart';

class IncomeState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final IncomeModel? income;
  final String? errorMessage;
  final bool savedSuccess;

  const IncomeState({
    this.isLoading = false,
    this.isSaving = false,
    this.income,
    this.errorMessage,
    this.savedSuccess = false,
  });

  factory IncomeState.initial() => const IncomeState(isLoading: true);

  IncomeState copyWith({
    bool? isLoading,
    bool? isSaving,
    IncomeModel? income,
    String? errorMessage,
    bool resetError = false,
    bool? savedSuccess,
  }) {
    return IncomeState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      income: income ?? this.income,
      errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
      savedSuccess: savedSuccess ?? false,
    );
  }

  @override
  List<Object?> get props => [isLoading, isSaving, income, errorMessage, savedSuccess];
}
