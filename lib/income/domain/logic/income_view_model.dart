import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_network_exception.dart';
import '../../data/repositories/income_repository.dart';
import '../income_type.dart';
import 'income_state.dart';

@injectable
class IncomeViewModel {
  final IncomeRepository _repository;

  IncomeViewModel(this._repository);

  final ValueNotifier<IncomeState> _state = ValueNotifier(IncomeState.initial());

  ValueListenable<IncomeState> get state => _state;

  Future<void> init() async {
    _state.value = IncomeState.initial();
    await _load(_state.value.selectedMonth);
  }

  Future<void> changeMonth(DateTime month) async {
    _state.value = _state.value.copyWith(selectedMonth: month, isLoading: true, clearIncome: true);
    await _load(month);
  }

  Future<void> save({
    required IncomeType type,
    required double grossSalary,
    required bool receivesVr,
    required double vrAmount,
    required bool receivesVa,
    required double vaAmount,
    required double commission,
    required double bonus,
    required double otherIncome,
    required DateTime effectiveFrom,
  }) async {
    _state.value = _state.value.copyWith(isSaving: true, resetError: true);
    try {
      await _repository.saveIncome(
        type: type,
        grossSalary: grossSalary,
        receivesVr: receivesVr,
        vrAmount: vrAmount,
        receivesVa: receivesVa,
        vaAmount: vaAmount,
        commission: commission,
        bonus: bonus,
        otherIncome: otherIncome,
        effectiveFrom: effectiveFrom,
      );
      await _load(_state.value.selectedMonth);
      _state.value = _state.value.copyWith(isSaving: false, savedSuccess: true);
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(isSaving: false, errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(isSaving: false, errorMessage: 'Erro ao salvar renda.');
    }
  }

  Future<void> addEvent({required String description, required double amount}) async {
    _state.value = _state.value.copyWith(isSavingEvent: true, resetError: true);
    try {
      await _repository.saveEvent(
        month: _state.value.selectedMonth,
        description: description,
        amount: amount,
      );
      final events = await _repository.fetchEvents(month: _state.value.selectedMonth);
      _state.value = _state.value.copyWith(isSavingEvent: false, events: events);
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(isSavingEvent: false, errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(isSavingEvent: false, errorMessage: 'Erro ao salvar entrada.');
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _repository.deleteEvent(id);
      final events = await _repository.fetchEvents(month: _state.value.selectedMonth);
      _state.value = _state.value.copyWith(events: events);
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(errorMessage: 'Erro ao excluir entrada.');
    }
  }

  Future<void> _load(DateTime month) async {
    try {
      final income = await _repository.fetchIncome(month: month);
      final events = await _repository.fetchEvents(month: month);
      _state.value = _state.value.copyWith(isLoading: false, income: income, events: events, resetError: true);
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: 'Erro ao carregar renda.');
    }
  }

  void onDisposed() => _state.dispose();
}
