import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/app_network_exception.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../domain/expense_category.dart';
import '../../../domain/expense_priority.dart';
import '../../data/models/imported_expense_model.dart';
import '../../data/parsers/nubank_csv_parser.dart';
import 'expense_import_state.dart';

const _noChange = Object();

@injectable
class ExpenseImportViewModel {
  final ExpenseRepository _repository;

  ExpenseImportViewModel(this._repository);

  final ValueNotifier<ExpenseImportState> _state = ValueNotifier(ExpenseImportState.initial());

  ValueListenable<ExpenseImportState> get state => _state;

  Future<void> pickAndParse() async {
    _state.value = _state.value.copyWith(isLoading: true, resetError: true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        _state.value = _state.value.copyWith(isLoading: false);
        return;
      }

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        _state.value = _state.value.copyWith(isLoading: false, errorMessage: 'Erro ao ler o arquivo.');
        return;
      }

      final content = utf8.decode(bytes, allowMalformed: true);
      List<ImportedExpenseModel> parsed;
      try {
        parsed = NubankCsvParser.parse(content);
      } on FormatException {
        _state.value = _state.value.copyWith(
          isLoading: false,
          errorMessage: 'Formato não reconhecido. Verifique se é um CSV exportado pelo Nubank.',
        );
        return;
      }

      if (parsed.isEmpty) {
        _state.value = _state.value.copyWith(isLoading: false, errorMessage: 'vazio');
        return;
      }

      final dates = parsed.map((e) => e.date).toList()..sort();
      final rangeStart = dates.first.subtract(const Duration(days: 1));
      final rangeEnd = dates.last.add(const Duration(days: 1));

      final existing = await _repository.fetchExpensesForRange(rangeStart, rangeEnd);

      final itemsWithDedup = parsed.map((item) {
        final isDuplicate = existing.any(
          (e) => (e.amount - item.amount).abs() < 0.01 && e.dueDate.difference(item.date).inDays.abs() <= 1,
        );
        return isDuplicate ? item.copyWith(isDuplicate: true) : item;
      }).toList();

      _state.value = _state.value.copyWith(
        isLoading: false,
        step: ImportStep.reviewing,
        items: itemsWithDedup,
        currentIndex: 0,
      );
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: 'Erro inesperado. Tente novamente.');
    }
  }

  void editCurrent({
    String? title,
    ExpenseCategory? category,
    double? amount,
    DateTime? date,
    bool? isEssential,
    Object? paymentMethod = _noChange,
  }) {
    final item = _state.value.currentItem;
    if (item == null) return;
    final updated = item.copyWith(
      title: title,
      category: category,
      amount: amount,
      date: date,
      isEssential: isEssential,
      paymentMethod: paymentMethod,
    );
    final items = List<ImportedExpenseModel>.from(_state.value.items);
    items[_state.value.currentIndex] = updated;
    _state.value = _state.value.copyWith(items: items);
  }

  Future<void> confirm() async {
    final item = _state.value.currentItem;
    if (item == null) return;

    _state.value = _state.value.copyWith(isLoading: true, resetError: true);
    try {
      await _repository.saveExpense(
        title: item.title,
        category: item.category,
        isEssential: item.isEssential,
        amount: item.amount,
        dueDate: item.date,
        priority: ExpensePriority.media,
        referenceMonth: DateTime(item.date.year, item.date.month),
        paymentMethod: item.paymentMethod,
      );
      _advance(confirmedDelta: 1);
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: 'Erro ao salvar despesa. Tente novamente.');
    }
  }

  void skip() {
    if (_state.value.currentItem == null) return;
    _advance(skippedDelta: 1);
  }

  void _advance({int confirmedDelta = 0, int skippedDelta = 0}) {
    final next = _state.value.currentIndex + 1;
    final isDone = next >= _state.value.items.length;
    _state.value = _state.value.copyWith(
      isLoading: false,
      currentIndex: next,
      confirmedCount: _state.value.confirmedCount + confirmedDelta,
      skippedCount: _state.value.skippedCount + skippedDelta,
      step: isDone ? ImportStep.done : null,
    );
  }

  void onDisposed() => _state.dispose();
}
