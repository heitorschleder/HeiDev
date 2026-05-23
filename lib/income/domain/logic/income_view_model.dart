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
    try {
      final income = await _repository.fetchIncome();
      _state.value = _state.value.copyWith(isLoading: false, income: income, resetError: true);
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: 'Erro ao carregar renda.');
    }
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
      );
      await init();
      _state.value = _state.value.copyWith(isSaving: false, savedSuccess: true);
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(isSaving: false, errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(isSaving: false, errorMessage: 'Erro ao salvar renda.');
    }
  }

  void onDisposed() => _state.dispose();
}
