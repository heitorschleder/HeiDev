import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/app_network_exception.dart';
import '../../domain/expense_category.dart';
import '../../domain/expense_payment_method.dart';
import '../../domain/expense_priority.dart';
import '../models/expense_model.dart';

@injectable
class ExpenseRepository {
  final SupabaseClient _client;

  ExpenseRepository(this._client);

  Future<List<ExpenseModel>> fetchExpenses({required DateTime month}) async {
    try {
      final referenceMonth = _monthKey(month);
      final data = await _client.from('expenses').select().eq('reference_month', referenceMonth).order('due_date');
      return (data as List).map((e) => ExpenseModel.fromJson(e)).toList();
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(
        message: 'Erro ao carregar despesas.',
        reason: AppNetworkExceptionReason.unknown,
      );
    }
  }

  Future<void> saveExpense({
    required String title,
    required ExpenseCategory category,
    required bool isEssential,
    required double amount,
    required DateTime dueDate,
    required ExpensePriority priority,
    required DateTime referenceMonth,
    String? templateId,
    String? notes,
    ExpensePaymentMethod? paymentMethod,
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      await _client.from('expenses').insert({
        'user_id': userId,
        'template_id': templateId,
        'title': title,
        'category': category.name,
        'is_essential': isEssential,
        'amount': amount,
        'due_date': dueDate.toIso8601String().substring(0, 10),
        'paid': true,
        'paid_at': dueDate.toIso8601String(),
        'priority': priority.name,
        'reference_month': _monthKey(referenceMonth),
        'notes': notes,
        if (paymentMethod != null) 'payment_method': paymentMethod.name,
      });
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(
        message: 'Erro ao salvar despesa.',
        reason: AppNetworkExceptionReason.unknown,
      );
    }
  }

  Future<void> saveInstallments({
    required String title,
    required ExpenseCategory category,
    required bool isEssential,
    required double totalAmount,
    required int installments,
    required DateTime firstDueDate,
    required ExpensePriority priority,
    String? notes,
    ExpensePaymentMethod? paymentMethod,
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final groupId = const Uuid().v4();
      final perInstallment = (totalAmount / installments * 100).round() / 100;

      final rows = List.generate(installments, (i) {
        final dueDate = i == 0 ? firstDueDate : firstDueDate.add(Duration(days: 30 * i));
        return {
          'user_id': userId,
          'title': '$title (${i + 1}/$installments)',
          'category': category.name,
          'is_essential': isEssential,
          'amount': perInstallment,
          'due_date': dueDate.toIso8601String().substring(0, 10),
          'paid': i == 0,
          'paid_at': i == 0 ? firstDueDate.toIso8601String() : null,
          'priority': priority.name,
          'reference_month': _monthKey(dueDate),
          'notes': notes,
          'installment_group_id': groupId,
          'installment_number': i + 1,
          'total_installments': installments,
          if (paymentMethod != null) 'payment_method': paymentMethod.name,
        };
      });

      await _client.from('expenses').insert(rows);
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(
        message: 'Erro ao salvar parcelas.',
        reason: AppNetworkExceptionReason.unknown,
      );
    }
  }

  Future<void> updateExpense(ExpenseModel model) async {
    try {
      final json = model.toJson()
        ..remove('id')
        ..remove('user_id');
      await _client.from('expenses').update(json).eq('id', model.id);
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(
        message: 'Erro ao atualizar despesa.',
        reason: AppNetworkExceptionReason.unknown,
      );
    }
  }

  Future<void> togglePaid(String id, {required bool paid}) async {
    try {
      await _client
          .from('expenses')
          .update({
            'paid': paid,
            'paid_at': paid ? DateTime.now().toIso8601String() : null,
          })
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(
        message: 'Erro ao atualizar despesa.',
        reason: AppNetworkExceptionReason.unknown,
      );
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _client.from('expenses').delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(
        message: 'Erro ao excluir despesa.',
        reason: AppNetworkExceptionReason.unknown,
      );
    }
  }

  Future<void> createFromTemplates({
    required List<String> templateIds,
    required DateTime month,
  }) async {
    try {
      final userId = _client.auth.currentUser!.id;
      final templates = await _client.from('bill_templates').select().inFilter('id', templateIds);
      final referenceMonth = _monthKey(month);
      final rows = (templates as List)
          .cast<Map<String, dynamic>>()
          .map(
            (t) => {
              'user_id': userId,
              'template_id': t['id'],
              'title': t['title'],
              'category': t['category'],
              'is_essential': t['is_essential'],
              'amount': t['default_amount'],
              'due_date': referenceMonth,
              'reference_month': referenceMonth,
              'priority': 'media',
            },
          )
          .toList();
      await _client.from('expenses').insert(rows);
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(
        message: 'Erro ao lançar modelos.',
        reason: AppNetworkExceptionReason.unknown,
      );
    }
  }

  static String _monthKey(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-01';
}
