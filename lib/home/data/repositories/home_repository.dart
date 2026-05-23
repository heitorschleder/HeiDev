import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_network_exception.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../income/data/models/income_model.dart';
import '../models/dashboard_data.dart';

@injectable
class DashboardRepository {
  final SupabaseClient _client;

  DashboardRepository(this._client);

  Future<DashboardData> fetchDashboard({required DateTime month}) async {
    try {
      final referenceMonth = '${month.year}-${month.month.toString().padLeft(2, '0')}-01';

      final incomeRaw = await _client.from('incomes').select().maybeSingle();
      final income = incomeRaw != null ? IncomeModel.fromJson(incomeRaw) : null;
      final totalIncome = income?.totalGrossIncome ?? 0;

      final expensesRaw = await _client.from('expenses').select().eq('reference_month', referenceMonth);
      final expenses = (expensesRaw as List).map((e) => ExpenseModel.fromJson(e)).toList();

      final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
      final totalPaid = expenses.where((e) => e.paid).fold<double>(0, (sum, e) => sum + e.amount);
      final totalOpen = totalExpenses - totalPaid;
      final balance = totalIncome - totalExpenses;
      final pctCommitted = totalIncome > 0 ? (totalExpenses / totalIncome * 100).clamp(0, 100) : 0.0;

      final now = DateTime.now();
      final threeDaysLater = now.add(const Duration(days: 3));
      final dueSoon =
          expenses.where((e) => !e.paid && e.dueDate.isBefore(threeDaysLater) && !e.dueDate.isBefore(now)).toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

      return DashboardData(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        totalPaid: totalPaid,
        totalOpen: totalOpen,
        balance: balance,
        pctCommitted: pctCommitted.toDouble(),
        dueSoon: dueSoon,
      );
    } on PostgrestException catch (e) {
      throw AppNetworkException(message: e.message, reason: AppNetworkExceptionReason.serverError);
    } catch (_) {
      throw const AppNetworkException(
        message: 'Erro ao carregar resumo.',
        reason: AppNetworkExceptionReason.unknown,
      );
    }
  }
}
