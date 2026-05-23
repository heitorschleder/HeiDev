import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injectable.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/routing/route_repository.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../data/models/dashboard_data.dart';
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
            onAddExpense: () async {
              await AppRouter.push(RouteRepository.expenseFormScreen.makeNavigation(null));
              unawaited(_vm.init());
            },
          );
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.dashboard, required this.onAddExpense});

  final DashboardData dashboard;
  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            label: l10n.dashboardIncome,
            value: fmt.format(dashboard.totalIncome),
            icon: Icons.account_balance_wallet_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          _ExpensesCard(dashboard: dashboard, fmt: fmt),
          const SizedBox(height: 12),
          _BalanceCard(dashboard: dashboard, fmt: fmt),
          if (dashboard.dueSoon.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(l10n.dashboardDueSoon, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            ...dashboard.dueSoon.map((e) => _DueSoonTile(expense: e, fmt: fmt)),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
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

class _ExpensesCard extends StatelessWidget {
  const _ExpensesCard({required this.dashboard, required this.fmt});

  final DashboardData dashboard;
  final NumberFormat fmt;

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
              fmt.format(dashboard.totalExpenses),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AmountLabel(
                    label: l10n.dashboardPaid,
                    value: fmt.format(dashboard.totalPaid),
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: _AmountLabel(
                    label: l10n.dashboardOpen,
                    value: fmt.format(dashboard.totalOpen),
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
  const _BalanceCard({required this.dashboard, required this.fmt});

  final DashboardData dashboard;
  final NumberFormat fmt;

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
                      fmt.format(dashboard.balance),
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
  const _DueSoonTile({required this.expense, required this.fmt});

  final ExpenseModel expense;
  final NumberFormat fmt;

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
            Text(fmt.format(expense.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(daysLeft == 0 ? 'Hoje' : 'em $daysLeft d', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
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
