import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_network_exception.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/models/expense_model.dart';
import '../expense_category.dart';
import 'expense_list_state.dart';

@injectable
class ExpenseListViewModel {
  final ExpenseRepository _repository;

  ExpenseListViewModel(this._repository);

  final ValueNotifier<ExpenseListState> _state = ValueNotifier(ExpenseListState.initial());

  ValueListenable<ExpenseListState> get state => _state;

  Future<void> init() async => _load(_state.value.selectedMonth);

  Future<void> changeMonth(DateTime month) async {
    _state.value = _state.value.copyWith(selectedMonth: month, isLoading: true, clearFilter: true);
    await _load(month);
  }

  Future<void> refresh() async => _load(_state.value.selectedMonth);

  Future<void> togglePaid(ExpenseModel expense) async {
    try {
      await _repository.togglePaid(expense.id, paid: !expense.paid);
      await _load(_state.value.selectedMonth);
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(errorMessage: 'Erro ao atualizar despesa.');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _repository.deleteExpense(id);
      await _load(_state.value.selectedMonth);
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(errorMessage: 'Erro ao excluir despesa.');
    }
  }

  void filterByCategory(ExpenseCategory? category) {
    if (category == null) {
      _state.value = _state.value.copyWith(clearFilter: true);
    } else {
      _state.value = _state.value.copyWith(categoryFilter: category);
    }
  }

  Future<void> _load(DateTime month) async {
    _state.value = _state.value.copyWith(isLoading: true, resetError: true);
    try {
      final expenses = await _repository.fetchExpenses(month: month);
      _state.value = _state.value.copyWith(isLoading: false, expenses: expenses);
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: 'Erro ao carregar despesas.');
    }
  }

  void onDisposed() => _state.dispose();
}
