import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injectable.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/routing/route_repository.dart';
import '../../../core/routing/app_router.dart';
import '../../data/models/expense_model.dart';
import '../../domain/expense_category.dart';
import '../../domain/logic/expense_list_state.dart';
import '../../domain/logic/expense_list_view_model.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  late final ExpenseListViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = getIt<ExpenseListViewModel>();
    unawaited(_vm.init());
  }

  @override
  void dispose() {
    _vm.onDisposed();
    super.dispose();
  }

  Future<void> _openForm(ExpenseModel? expense) async {
    await AppRouter.push(RouteRepository.expenseFormScreen.makeNavigation(expense));
    unawaited(_vm.refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.expenseTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: l10n.billTemplatesTitle,
            onPressed: () async {
              await AppRouter.push(RouteRepository.billTemplatesScreen.makeNavigation());
              unawaited(_vm.refresh());
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<ExpenseListState>(
        valueListenable: _vm.state,
        builder: (context, state, _) {
          return Column(
            children: [
              _MonthNav(
                month: state.selectedMonth,
                onPrev: () => _vm.changeMonth(
                  DateTime(state.selectedMonth.year, state.selectedMonth.month - 1),
                ),
                onNext: () => _vm.changeMonth(
                  DateTime(state.selectedMonth.year, state.selectedMonth.month + 1),
                ),
              ),
              _CategoryFilterBar(
                selected: state.categoryFilter,
                onSelected: _vm.filterByCategory,
              ),
              Expanded(child: _buildBody(state)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ExpenseListState state) {
    if (state.isLoading) return const Center(child: CircularProgressIndicator());
    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.errorMessage!),
            const SizedBox(height: 12),
            FilledButton(onPressed: _vm.refresh, child: Text(l10n.appGeneralRetry)),
          ],
        ),
      );
    }
    final items = state.filtered;
    if (items.isEmpty) {
      return Center(child: Text(l10n.expenseNoExpenses));
    }
    return RefreshIndicator(
      onRefresh: _vm.refresh,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) => _ExpenseTile(
          expense: items[i],
          onTap: () => _openForm(items[i]),
          onTogglePaid: () => _vm.togglePaid(items[i]),
          onDelete: () => _confirmDelete(items[i]),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ExpenseModel expense) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.expenseDeleteConfirm),
        content: Text(expense.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.appGeneralCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.appGeneralDelete),
          ),
        ],
      ),
    );
    if (ok ?? false) unawaited(_vm.deleteExpense(expense.id));
  }
}

class _MonthNav extends StatelessWidget {
  const _MonthNav({required this.month, required this.onPrev, required this.onNext});

  final DateTime month;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('MMMM yyyy', Intl.defaultLocale).format(month);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({required this.selected, required this.onSelected});

  final ExpenseCategory? selected;
  final ValueChanged<ExpenseCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Icon(Icons.clear, size: 16),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...ExpenseCategory.values.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_categoryLabel(cat)),
                selected: selected == cat,
                onSelected: (_) => onSelected(selected == cat ? null : cat),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(ExpenseCategory cat) {
    return switch (cat) {
      ExpenseCategory.casa => l10n.expenseCatCasa,
      ExpenseCategory.transporte => l10n.expenseCatTransporte,
      ExpenseCategory.alimentacao => l10n.expenseCatAlimentacao,
      ExpenseCategory.saude => l10n.expenseCatSaude,
      ExpenseCategory.lazer => l10n.expenseCatLazer,
      ExpenseCategory.impostos => l10n.expenseCatImpostos,
      ExpenseCategory.outros => l10n.expenseCatOutros,
    };
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({
    required this.expense,
    required this.onTap,
    required this.onTogglePaid,
    required this.onDelete,
  });

  final ExpenseModel expense;
  final VoidCallback onTap;
  final VoidCallback onTogglePaid;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dismissible(
      key: ValueKey(expense.id),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onTogglePaid();
          return false;
        }
        onDelete();
        return false;
      },
      child: ListTile(
        onTap: onTap,
        leading: IconButton(
          icon: Icon(
            expense.paid ? Icons.check_circle : Icons.radio_button_unchecked,
            color: expense.paid ? Colors.green : colorScheme.outline,
          ),
          onPressed: onTogglePaid,
        ),
        title: Text(
          expense.title,
          style: expense.paid ? TextStyle(decoration: TextDecoration.lineThrough, color: colorScheme.outline) : null,
        ),
        subtitle: Text(
          DateFormat('dd/MM').format(expense.dueDate),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          'R\$ ${expense.amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: expense.paid ? colorScheme.outline : colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
