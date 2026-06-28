import 'package:equatable/equatable.dart';

import '../../data/models/imported_expense_model.dart';

enum ImportStep { picking, reviewing, done }

class ExpenseImportState extends Equatable {
  final ImportStep step;
  final List<ImportedExpenseModel> items;
  final int currentIndex;
  final bool isLoading;
  final String? errorMessage;
  final int confirmedCount;
  final int skippedCount;

  const ExpenseImportState({
    this.step = ImportStep.picking,
    this.items = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.errorMessage,
    this.confirmedCount = 0,
    this.skippedCount = 0,
  });

  factory ExpenseImportState.initial() => const ExpenseImportState();

  ImportedExpenseModel? get currentItem => currentIndex < items.length ? items[currentIndex] : null;

  double get progress => items.isEmpty ? 0.0 : currentIndex / items.length;

  ExpenseImportState copyWith({
    ImportStep? step,
    List<ImportedExpenseModel>? items,
    int? currentIndex,
    bool? isLoading,
    String? errorMessage,
    bool resetError = false,
    int? confirmedCount,
    int? skippedCount,
  }) {
    return ExpenseImportState(
      step: step ?? this.step,
      items: items ?? this.items,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
      confirmedCount: confirmedCount ?? this.confirmedCount,
      skippedCount: skippedCount ?? this.skippedCount,
    );
  }

  @override
  List<Object?> get props => [step, items, currentIndex, isLoading, errorMessage, confirmedCount, skippedCount];
}
