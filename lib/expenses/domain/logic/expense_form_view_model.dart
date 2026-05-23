import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_network_exception.dart';
import '../../data/models/expense_model.dart';
import '../../data/repositories/expense_repository.dart';
import '../expense_category.dart';
import '../expense_priority.dart';
import 'expense_form_state.dart';

@injectable
class ExpenseFormViewModel {
  final ExpenseRepository _repository;

  ExpenseFormViewModel(this._repository);

  final ValueNotifier<ExpenseFormState> _state = ValueNotifier(ExpenseFormState.initial());

  ValueListenable<ExpenseFormState> get state => _state;

  Future<void> save({
    required String title,
    required ExpenseCategory category,
    required bool isEssential,
    required double amount,
    required DateTime dueDate,
    required ExpensePriority priority,
    required DateTime referenceMonth,
    String? notes,
    ExpenseModel? existing,
  }) async {
    _state.value = _state.value.copyWith(isSaving: true, resetError: true);
    try {
      if (existing != null) {
        await _repository.updateExpense(
          existing.copyWith(
            title: title,
            category: category,
            isEssential: isEssential,
            amount: amount,
            dueDate: dueDate,
            priority: priority,
            notes: notes,
          ),
        );
      } else {
        await _repository.saveExpense(
          title: title,
          category: category,
          isEssential: isEssential,
          amount: amount,
          dueDate: dueDate,
          priority: priority,
          referenceMonth: referenceMonth,
          notes: notes,
        );
      }
      _state.value = _state.value.copyWith(isSaving: false, savedSuccess: true);
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(isSaving: false, errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(isSaving: false, errorMessage: 'Erro ao salvar despesa.');
    }
  }

  void onDisposed() => _state.dispose();
}
