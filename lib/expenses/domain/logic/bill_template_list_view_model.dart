import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_network_exception.dart';
import '../../data/models/bill_template_model.dart';
import '../../data/repositories/bill_template_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../expense_category.dart';
import 'bill_template_list_state.dart';

@injectable
class BillTemplateListViewModel {
  final BillTemplateRepository _templateRepo;
  final ExpenseRepository _expenseRepo;

  BillTemplateListViewModel(this._templateRepo, this._expenseRepo);

  final ValueNotifier<BillTemplateListState> _state = ValueNotifier(BillTemplateListState.initial());

  ValueListenable<BillTemplateListState> get state => _state;

  Future<void> init() async {
    _state.value = BillTemplateListState.initial();
    try {
      final templates = await _templateRepo.fetchTemplates();
      _state.value = _state.value.copyWith(isLoading: false, templates: templates);
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: 'Erro ao carregar modelos.');
    }
  }

  Future<void> saveTemplate({
    required String title,
    required ExpenseCategory category,
    required bool isEssential,
    required double defaultAmount,
  }) async {
    try {
      await _templateRepo.saveTemplate(
        title: title,
        category: category,
        isEssential: isEssential,
        defaultAmount: defaultAmount,
      );
      await init();
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(errorMessage: 'Erro ao salvar modelo.');
    }
  }

  Future<void> updateTemplate(BillTemplateModel model) async {
    try {
      await _templateRepo.updateTemplate(model);
      await init();
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(errorMessage: 'Erro ao atualizar modelo.');
    }
  }

  Future<void> deleteTemplate(String id) async {
    try {
      await _templateRepo.deleteTemplate(id);
      await init();
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(errorMessage: 'Erro ao excluir modelo.');
    }
  }

  Future<void> launchTemplates({
    required List<String> templateIds,
    required DateTime month,
  }) async {
    try {
      await _expenseRepo.createFromTemplates(templateIds: templateIds, month: month);
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(errorMessage: 'Erro ao lançar modelos.');
    }
  }

  void onDisposed() => _state.dispose();
}
