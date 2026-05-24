import 'package:equatable/equatable.dart';

import '../../data/models/income_event_model.dart';
import '../../data/models/income_model.dart';

class IncomeState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final bool isSavingEvent;
  final IncomeModel? income;
  final List<IncomeEventModel> events;
  final DateTime selectedMonth;
  final String? errorMessage;
  final bool savedSuccess;

  const IncomeState({
    this.isLoading = false,
    this.isSaving = false,
    this.isSavingEvent = false,
    this.income,
    this.events = const [],
    required this.selectedMonth,
    this.errorMessage,
    this.savedSuccess = false,
  });

  factory IncomeState.initial() => IncomeState(
    isLoading: true,
    selectedMonth: DateTime(DateTime.now().year, DateTime.now().month),
  );

  double get eventsTotal => events.fold(0, (s, e) => s + e.amount);
  double get monthlyTotal => (income?.totalGrossIncome ?? 0) + eventsTotal;

  IncomeState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isSavingEvent,
    IncomeModel? income,
    bool clearIncome = false,
    List<IncomeEventModel>? events,
    DateTime? selectedMonth,
    String? errorMessage,
    bool resetError = false,
    bool? savedSuccess,
  }) {
    return IncomeState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isSavingEvent: isSavingEvent ?? this.isSavingEvent,
      income: clearIncome ? null : income ?? this.income,
      events: events ?? this.events,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
      savedSuccess: savedSuccess ?? false,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSaving,
    isSavingEvent,
    income,
    events,
    selectedMonth,
    errorMessage,
    savedSuccess,
  ];
}
