import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injectable.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/routing/route_repository.dart';
import '../../../core/routing/app_router.dart';
import '../../data/models/expense_model.dart';
import '../../domain/expense_category.dart';
import '../../domain/expense_payment_method.dart';
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

  Future<void> _openCategorySheet(Set<ExpenseCategory> current) async {
    final result = await showModalBottomSheet<Set<ExpenseCategory>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MultiSelectSheet<ExpenseCategory>(
        title: l10n.expenseCategory,
        options: ExpenseCategory.values,
        initialSelected: current,
        labelOf: _categoryLabel,
      ),
    );
    if (result != null) _vm.setCategoryFilters(result);
  }

  Future<void> _openPaymentSheet(Set<ExpensePaymentMethod> current) async {
    final result = await showModalBottomSheet<Set<ExpensePaymentMethod>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MultiSelectSheet<ExpensePaymentMethod>(
        title: l10n.expensePaymentMethod,
        options: _vm.state.value.allowedPaymentMethods,
        initialSelected: current,
        labelOf: _paymentLabel,
      ),
    );
    if (result != null) _vm.setPaymentFilters(result);
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
              _SearchBar(onChanged: _vm.filterByText),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _FilterButton(
                        label: l10n.expenseCategory,
                        count: state.categoryFilters.length,
                        onTap: () => _openCategorySheet(state.categoryFilters),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterButton(
                        label: l10n.expensePayment,
                        count: state.paymentFilters.length,
                        onTap: () => _openPaymentSheet(state.paymentFilters),
                      ),
                    ),
                  ],
                ),
              ),
              _EssentialFilter(
                value: state.essentialFilter,
                onChange: _vm.filterByEssential,
              ),
              _InstallmentFilter(
                value: state.installmentFilter,
                onChange: _vm.filterByInstallment,
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
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.expenseDeleteConfirm),
        content: Text(expense.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.appGeneralCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error),
            child: Text(l10n.appGeneralDelete),
          ),
        ],
      ),
    );
    if (ok ?? false) unawaited(_vm.deleteExpense(expense.id));
  }
}

String _categoryLabel(ExpenseCategory cat) => switch (cat) {
  ExpenseCategory.casa => l10n.expenseCatCasa,
  ExpenseCategory.transporte => l10n.expenseCatTransporte,
  ExpenseCategory.alimentacao => l10n.expenseCatAlimentacao,
  ExpenseCategory.saude => l10n.expenseCatSaude,
  ExpenseCategory.lazer => l10n.expenseCatLazer,
  ExpenseCategory.impostos => l10n.expenseCatImpostos,
  ExpenseCategory.outros => l10n.expenseCatOutros,
};

String _paymentLabel(ExpensePaymentMethod m) => switch (m) {
  ExpensePaymentMethod.dinheiro => l10n.expensePayMethodDinheiro,
  ExpensePaymentMethod.credito => l10n.expensePayMethodCredito,
  ExpensePaymentMethod.debito => l10n.expensePayMethodDebito,
  ExpensePaymentMethod.valeAlimentacao => l10n.expensePayMethodValeAlim,
  ExpensePaymentMethod.valeRefeicao => l10n.expensePayMethodValeRef,
};

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

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: _ctrl,
        decoration: InputDecoration(
          hintText: l10n.expenseExpenseName,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _ctrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _ctrl.clear();
                    widget.onChanged('');
                  },
                )
              : null,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        onChanged: (v) {
          setState(() {});
          widget.onChanged(v);
        },
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.label, required this.count, required this.onTap});

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasFilter = count > 0;
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: hasFilter ? Theme.of(context).colorScheme.primary : null,
        side: hasFilter ? BorderSide(color: Theme.of(context).colorScheme.primary) : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      icon: const Icon(Icons.filter_list, size: 16),
      label: Text(
        hasFilter ? '$label ($count)' : label,
        overflow: TextOverflow.ellipsis,
      ),
      onPressed: onTap,
    );
  }
}

class _EssentialFilter extends StatelessWidget {
  const _EssentialFilter({required this.value, required this.onChange});

  final bool? value;
  final ValueChanged<bool?> onChange;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = value == null ? 0 : (value! ? 1 : 2);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text('${l10n.expenseEssential}:', style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                ButtonSegment(value: 0, label: Text(l10n.appGeneralAll)),
                ButtonSegment(value: 1, label: Text(l10n.appGeneralYes)),
                ButtonSegment(value: 2, label: Text(l10n.appGeneralNo)),
              ],
              selected: {selectedIndex},
              onSelectionChanged: (s) {
                switch (s.first) {
                  case 0:
                    onChange(null);
                  case 1:
                    onChange(true);
                  default:
                    onChange(false);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InstallmentFilter extends StatelessWidget {
  const _InstallmentFilter({required this.value, required this.onChange});

  final bool value;
  final ValueChanged<bool> onChange;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text('${l10n.expenseInstallmentHeader}:', style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                ButtonSegment(value: false, label: Text(l10n.appGeneralAll)),
                ButtonSegment(value: true, label: Text(l10n.expenseFilterInstallment)),
              ],
              selected: {value},
              onSelectionChanged: (s) => onChange(s.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiSelectSheet<T> extends StatefulWidget {
  const _MultiSelectSheet({
    required this.title,
    required this.options,
    required this.initialSelected,
    required this.labelOf,
  });

  final String title;
  final List<T> options;
  final Set<T> initialSelected;
  final String Function(T) labelOf;

  @override
  State<_MultiSelectSheet<T>> createState() => _MultiSelectSheetState<T>();
}

class _MultiSelectSheetState<T> extends State<_MultiSelectSheet<T>> {
  late final Set<T> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _selected.clear()),
                  child: Text(l10n.appGeneralClear),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...widget.options.map(
            (opt) => CheckboxListTile(
              title: Text(widget.labelOf(opt)),
              value: _selected.contains(opt),
              onChanged: (v) {
                setState(() {
                  if (v ?? false) {
                    _selected.add(opt);
                  } else {
                    _selected.remove(opt);
                  }
                });
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(Set<T>.from(_selected)),
                child: Text(l10n.appGeneralApply),
              ),
            ),
          ),
        ],
      ),
    );
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
