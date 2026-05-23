import '../../../expenses/data/models/expense_model.dart';

class DashboardData {
  final double totalIncome;
  final double totalExpenses;
  final double totalPaid;
  final double totalOpen;
  final double balance;
  final double pctCommitted;
  final List<ExpenseModel> dueSoon;

  const DashboardData({
    required this.totalIncome,
    required this.totalExpenses,
    required this.totalPaid,
    required this.totalOpen,
    required this.balance,
    required this.pctCommitted,
    required this.dueSoon,
  });
}
