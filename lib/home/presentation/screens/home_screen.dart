import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injectable.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/route_repository.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/domain/expense_category.dart';
import '../../data/models/dashboard_data.dart';
import '../../data/models/monthly_total.dart';
import '../../domain/logic/home_state.dart';
import '../../domain/logic/home_view_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = getIt<HomeViewModel>();
    unawaited(_vm.init());
  }

  @override
  void dispose() {
    _vm.onDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: [_UserMenuButton(vm: _vm)],
      ),
      body: ValueListenableBuilder<HomeState>(
        valueListenable: _vm.state,
        builder: (context, state, _) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator());
          if (state.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage!),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => unawaited(_vm.init()),
                    child: Text(l10n.appGeneralRetry),
                  ),
                ],
              ),
            );
          }
          return _DashboardBody(
            dashboard: state.dashboard!,
            onRefresh: _vm.refresh,
            onAddExpense: () async {
              await AppRouter.push(RouteRepository.expenseFormScreen.makeNavigation(null));
              unawaited(_vm.refresh());
            },
          );
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.dashboard, required this.onRefresh, required this.onAddExpense});

  final DashboardData dashboard;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            label: l10n.dashboardIncome,
            value: formatBRL(dashboard.totalIncome),
            icon: Icons.account_balance_wallet_outlined,
            color: Theme.of(context).colorScheme.primary,
            obscurable: true,
          ),
          const SizedBox(height: 12),
          _ExpensesCard(dashboard: dashboard),
          const SizedBox(height: 12),
          _BalanceCard(dashboard: dashboard),
          if (dashboard.categoryTotals.isNotEmpty) ...[
            const SizedBox(height: 20),
            _CategoryPieChart(categoryTotals: dashboard.categoryTotals),
          ],
          if (dashboard.monthlyTotals.isNotEmpty) ...[
            const SizedBox(height: 20),
            _MonthlyChart(monthlyTotals: dashboard.monthlyTotals),
          ],
          if (dashboard.dueSoon.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(l10n.dashboardDueSoon, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...dashboard.dueSoon.map((e) => _DueSoonTile(expense: e)),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAddExpense,
            icon: const Icon(Icons.add),
            label: Text(l10n.dashboardAddExpense),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatefulWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.obscurable = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool obscurable;

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final displayValue = widget.obscurable && !_visible ? '*****' : widget.value;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(widget.icon, color: widget.color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    displayValue,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: widget.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.obscurable)
              IconButton(
                icon: Icon(_visible ? Icons.visibility : Icons.visibility_off),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                onPressed: () => setState(() => _visible = !_visible),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpensesCard extends StatelessWidget {
  const _ExpensesCard({required this.dashboard});

  final DashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dashboardTotalExpenses, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              formatBRL(dashboard.totalExpenses),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AmountLabel(
                    label: l10n.dashboardPaid,
                    value: formatBRL(dashboard.totalPaid),
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _AmountLabel(
                    label: l10n.dashboardOpen,
                    value: formatBRL(dashboard.totalOpen),
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.dashboard});

  final DashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    final pct = dashboard.pctCommitted / 100;
    final balanceColor = dashboard.balance >= 0 ? Colors.green : Theme.of(context).colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.dashboardBalance, style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      formatBRL(dashboard.balance),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: balanceColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(l10n.dashboardCommitted, style: Theme.of(context).textTheme.bodySmall),
                    Text(
                      '${dashboard.pctCommitted.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct.clamp(0.0, 1.0),
                minHeight: 8,
                color: pct >= 1 ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountLabel extends StatelessWidget {
  const _AmountLabel({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _DueSoonTile extends StatelessWidget {
  const _DueSoonTile({required this.expense});

  final ExpenseModel expense;

  @override
  Widget build(BuildContext context) {
    final daysLeft = expense.dueDate.difference(DateTime.now()).inDays;
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.warning_amber_rounded),
        title: Text(expense.title),
        subtitle: Text(DateFormat('dd/MM').format(expense.dueDate)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatBRL(expense.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(daysLeft == 0 ? 'Hoje' : 'em $daysLeft d', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _CategoryPieChart extends StatefulWidget {
  const _CategoryPieChart({required this.categoryTotals});

  final Map<ExpenseCategory, double> categoryTotals;

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int? _touchedIndex;

  static const _categoryColors = {
    ExpenseCategory.casa: Color(0xFF4285F4),
    ExpenseCategory.transporte: Color(0xFFFF6D00),
    ExpenseCategory.alimentacao: Color(0xFF34A853),
    ExpenseCategory.saude: Color(0xFFEA4335),
    ExpenseCategory.lazer: Color(0xFF9C27B0),
    ExpenseCategory.impostos: Color(0xFF795548),
    ExpenseCategory.vestuario: Color(0xFFE91E63),
    ExpenseCategory.cosmeticos: Color(0xFFFF4081),
    ExpenseCategory.assinaturas: Color(0xFF00BCD4),
    ExpenseCategory.pet: Color(0xFF8BC34A),
    ExpenseCategory.outros: Color(0xFF9E9E9E),
  };

  String _label(ExpenseCategory cat) => switch (cat) {
    ExpenseCategory.casa => l10n.expenseCatCasa,
    ExpenseCategory.transporte => l10n.expenseCatTransporte,
    ExpenseCategory.alimentacao => l10n.expenseCatAlimentacao,
    ExpenseCategory.saude => l10n.expenseCatSaude,
    ExpenseCategory.lazer => l10n.expenseCatLazer,
    ExpenseCategory.impostos => l10n.expenseCatImpostos,
    ExpenseCategory.vestuario => l10n.expenseCatVestuario,
    ExpenseCategory.cosmeticos => l10n.expenseCatCosmeticos,
    ExpenseCategory.assinaturas => l10n.expenseCatAssinaturas,
    ExpenseCategory.pet => l10n.expenseCatPet,
    ExpenseCategory.outros => l10n.expenseCatOutros,
  };

  @override
  Widget build(BuildContext context) {
    final total = widget.categoryTotals.values.fold<double>(0, (s, v) => s + v);
    if (total == 0) return const SizedBox.shrink();

    final entries = widget.categoryTotals.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = List.generate(entries.length, (i) {
      final entry = entries[i];
      final pct = entry.value / total * 100;
      final color = _categoryColors[entry.key] ?? const Color(0xFF9E9E9E);
      final isTouched = i == _touchedIndex;
      return PieChartSectionData(
        value: entry.value,
        color: color,
        title: isTouched ? formatBRL(entry.value) : (pct >= 6 ? '${pct.toStringAsFixed(0)}%' : ''),
        radius: isTouched ? 68.0 : 56.0,
        titleStyle: TextStyle(
          fontSize: isTouched ? 12 : 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.dashboardByCategory, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: sections,
              sectionsSpace: 2,
              centerSpaceRadius: 44,
              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                    setState(() => _touchedIndex = null);
                    return;
                  }
                  setState(() => _touchedIndex = response.touchedSection!.touchedSectionIndex);
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: List.generate(entries.length, (i) {
            final entry = entries[i];
            final pct = entry.value / total * 100;
            final color = _categoryColors[entry.key] ?? const Color(0xFF9E9E9E);
            final isTouched = i == _touchedIndex;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_label(entry.key)} · ${isTouched ? formatBRL(entry.value) : '${pct.toStringAsFixed(0)}%'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: isTouched ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.monthlyTotals});

  final List<MonthlyTotal> monthlyTotals;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxY = monthlyTotals.fold<double>(0, (m, t) => t.totalExpenses > m ? t.totalExpenses : m);
    final chartMax = maxY > 0 ? maxY * 1.2 : 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.dashboardMonthlyHistory, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: chartMax,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                    formatBRL(rod.toY),
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= monthlyTotals.length) return const SizedBox.shrink();
                      return Text(
                        DateFormat('MMM').format(monthlyTotals[i].month),
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(monthlyTotals.length, (i) {
                final m = monthlyTotals[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: m.totalExpenses,
                      color: colorScheme.surfaceContainerHighest,
                      width: 10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    BarChartRodData(
                      toY: m.totalPaid,
                      color: colorScheme.primary,
                      width: 10,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserMenuButton extends StatelessWidget {
  const _UserMenuButton({required this.vm});

  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final email = vm.userEmail ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PopupMenuButton<_UserMenuAction>(
        tooltip: email,
        offset: const Offset(0, 48),
        itemBuilder: (context) => [
          PopupMenuItem(
            enabled: false,
            child: Text(email, style: Theme.of(context).textTheme.bodySmall),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _UserMenuAction.logout,
            child: Row(
              children: [
                const Icon(Icons.logout),
                const SizedBox(width: 12),
                Text(l10n.homeScreenLogout),
              ],
            ),
          ),
        ],
        onSelected: (action) {
          if (action == _UserMenuAction.logout) unawaited(vm.signOut());
        },
        child: CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}

enum _UserMenuAction { logout }
