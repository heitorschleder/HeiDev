import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_network_exception.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../income/data/models/income_model.dart';
import '../models/dashboard_data.dart';
import '../models/monthly_total.dart';

@injectable
class DashboardRepository {
  final SupabaseClient _client;

  DashboardRepository(this._client);

  Future<DashboardData> fetchDashboard({required DateTime month}) async {
    try {
      final referenceMonth = '${month.year}-${month.month.toString().padLeft(2, '0')}-01';

      final incomeRaw = await _client
          .from('incomes')
          .select()
          .lte('effective_from', referenceMonth)
          .order('effective_from', ascending: false)
          .limit(1)
          .maybeSingle();
      final income = incomeRaw != null ? IncomeModel.fromJson(incomeRaw) : null;

      final eventsRaw = await _client.from('income_events').select('amount').eq('reference_month', referenceMonth);
      final eventsSum = (eventsRaw as List).cast<Map<String, dynamic>>().fold<double>(
        0,
        (s, r) => s + (r['amount'] as num).toDouble(),
      );

      final totalIncome = (income?.totalGrossIncome ?? 0.0) + eventsSum;

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

      final monthlyTotals = await fetchMonthlyTotals();

      return DashboardData(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        totalPaid: totalPaid,
        totalOpen: totalOpen,
        balance: balance,
        pctCommitted: pctCommitted.toDouble(),
        dueSoon: dueSoon,
        monthlyTotals: monthlyTotals,
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

  // TODO: optimize with single .inFilter('reference_month', [...keys]) + group-by in Dart
  Future<List<MonthlyTotal>> fetchMonthlyTotals({int months = 6}) async {
    final now = DateTime.now();
    final result = <MonthlyTotal>[];

    for (var i = months - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i);
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}-01';

      final raw = await _client.from('expenses').select('amount, paid').eq('reference_month', key);
      final rows = (raw as List).cast<Map<String, dynamic>>();

      final totalExpenses = rows.fold<double>(0, (s, r) => s + (r['amount'] as num).toDouble());
      final totalPaid = rows
          .where((r) => r['paid'] == true)
          .fold<double>(0, (s, r) => s + (r['amount'] as num).toDouble());

      result.add(MonthlyTotal(month: m, totalExpenses: totalExpenses, totalPaid: totalPaid));
    }

    return result;
  }
}
