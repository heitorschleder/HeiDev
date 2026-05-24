import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injectable.dart';
import '../../../core/l10n/l10n.dart';
import '../../data/models/income_event_model.dart';
import '../../data/models/income_model.dart';
import '../../domain/income_type.dart';
import '../../domain/logic/income_state.dart';
import '../../domain/logic/income_view_model.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  late final IncomeViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = getIt<IncomeViewModel>();
    _vm.state.addListener(_onStateChanged);
    unawaited(_vm.init());
  }

  @override
  void dispose() {
    _vm.state.removeListener(_onStateChanged);
    _vm.onDisposed();
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;
    final state = _vm.state.value;
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _openSalaryForm() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _SalaryFormSheet(vm: _vm),
      ),
    );
  }

  Future<void> _openAddEventSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _AddEventSheet(
        onSave: (description, amount) async {
          await _vm.addEvent(description: description, amount: amount);
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  Future<void> _confirmDeleteEvent(IncomeEventModel event) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.incomeDeleteEvent),
        content: Text(event.description),
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
    if (ok ?? false) unawaited(_vm.deleteEvent(event.id));
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Scaffold(
      appBar: AppBar(title: Text(l10n.incomeTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddEventSheet,
        tooltip: l10n.incomeExtraIncome,
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder<IncomeState>(
        valueListenable: _vm.state,
        builder: (context, state, _) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator());
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
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  children: [
                    _SalaryCard(
                      income: state.income,
                      fmt: fmt,
                      onEdit: _openSalaryForm,
                    ),
                    const SizedBox(height: 16),
                    _EventsSection(
                      events: state.events,
                      fmt: fmt,
                      onDelete: _confirmDeleteEvent,
                    ),
                    const SizedBox(height: 16),
                    _MonthlyTotalCard(total: state.monthlyTotal, fmt: fmt),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Month Navigation ────────────────────────────────────────────────────────

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

// ─── Salary Card ─────────────────────────────────────────────────────────────

class _SalaryCard extends StatelessWidget {
  const _SalaryCard({required this.income, required this.fmt, required this.onEdit});

  final IncomeModel? income;
  final NumberFormat fmt;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (income == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 48, color: colorScheme.outline),
              const SizedBox(height: 12),
              Text(l10n.incomeNoIncome, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.add),
                label: Text(l10n.incomeNoIncomeCta),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(l10n.incomeBaseSalary, style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(l10n.incomeEditBase),
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _IncomeRow(label: l10n.incomeGrossSalary, value: fmt.format(income!.grossSalary)),
            if (income!.receivesVr) _IncomeRow(label: l10n.incomeVr, value: fmt.format(income!.vrAmount)),
            if (income!.receivesVa) _IncomeRow(label: l10n.incomeVa, value: fmt.format(income!.vaAmount)),
            if (income!.commission > 0) _IncomeRow(label: l10n.incomeCommission, value: fmt.format(income!.commission)),
            if (income!.bonus > 0) _IncomeRow(label: l10n.incomeBonus, value: fmt.format(income!.bonus)),
            if (income!.otherIncome > 0)
              _IncomeRow(label: l10n.incomeOtherIncome, value: fmt.format(income!.otherIncome)),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.incomeFixedTotal, style: Theme.of(context).textTheme.labelLarge),
                Text(
                  fmt.format(income!.totalGrossIncome),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colorScheme.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IncomeRow extends StatelessWidget {
  const _IncomeRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ─── Events Section ───────────────────────────────────────────────────────────

class _EventsSection extends StatelessWidget {
  const _EventsSection({required this.events, required this.fmt, required this.onDelete});

  final List<IncomeEventModel> events;
  final NumberFormat fmt;
  final ValueChanged<IncomeEventModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(l10n.incomeExtraIncome, style: Theme.of(context).textTheme.titleSmall),
        ),
        if (events.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '—',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            ),
          )
        else
          Card(
            clipBehavior: Clip.hardEdge,
            child: Column(
              children: events
                  .map(
                    (event) => Dismissible(
                      key: ValueKey(event.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Theme.of(context).colorScheme.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        onDelete(event);
                        return false;
                      },
                      child: ListTile(
                        title: Text(event.description),
                        trailing: Text(
                          fmt.format(event.amount),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}

// ─── Monthly Total Card ───────────────────────────────────────────────────────

class _MonthlyTotalCard extends StatelessWidget {
  const _MonthlyTotalCard({required this.total, required this.fmt});
  final double total;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.incomeMonthlyTotal, style: Theme.of(context).textTheme.titleMedium),
            Text(
              fmt.format(total),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Salary Form Bottom Sheet ─────────────────────────────────────────────────

class _SalaryFormSheet extends StatefulWidget {
  const _SalaryFormSheet({required this.vm});
  final IncomeViewModel vm;

  @override
  State<_SalaryFormSheet> createState() => _SalaryFormSheetState();
}

class _SalaryFormSheetState extends State<_SalaryFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late DateTime _effectiveFrom;
  IncomeType _type = IncomeType.clt;
  bool _receivesVr = false;
  bool _receivesVa = false;

  final _grossSalaryCtrl = TextEditingController();
  final _vrAmountCtrl = TextEditingController();
  final _vaAmountCtrl = TextEditingController();
  final _commissionCtrl = TextEditingController();
  final _bonusCtrl = TextEditingController();
  final _otherIncomeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _effectiveFrom = widget.vm.state.value.selectedMonth;
    final income = widget.vm.state.value.income;
    if (income != null) {
      _type = income.type;
      _receivesVr = income.receivesVr;
      _receivesVa = income.receivesVa;
      _grossSalaryCtrl.text = _fmt(income.grossSalary);
      _vrAmountCtrl.text = _fmt(income.vrAmount);
      _vaAmountCtrl.text = _fmt(income.vaAmount);
      _commissionCtrl.text = _fmt(income.commission);
      _bonusCtrl.text = _fmt(income.bonus);
      _otherIncomeCtrl.text = _fmt(income.otherIncome);
    }
    widget.vm.state.addListener(_onVmState);
  }

  @override
  void dispose() {
    widget.vm.state.removeListener(_onVmState);
    _grossSalaryCtrl.dispose();
    _vrAmountCtrl.dispose();
    _vaAmountCtrl.dispose();
    _commissionCtrl.dispose();
    _bonusCtrl.dispose();
    _otherIncomeCtrl.dispose();
    super.dispose();
  }

  void _onVmState() {
    if (!mounted) return;
    final state = widget.vm.state.value;
    if (state.savedSuccess) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.incomeSavedSuccess)));
    }
    if (state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _fmt(double v) => v == 0 ? '' : v.toStringAsFixed(2);
  double _parse(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0.0;

  Future<void> _pickEffectiveFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) setState(() => _effectiveFrom = DateTime(picked.year, picked.month));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget.vm.save(
      type: _type,
      grossSalary: _parse(_grossSalaryCtrl.text),
      receivesVr: _receivesVr,
      vrAmount: _parse(_vrAmountCtrl.text),
      receivesVa: _receivesVa,
      vaAmount: _parse(_vaAmountCtrl.text),
      commission: _parse(_commissionCtrl.text),
      bonus: _parse(_bonusCtrl.text),
      otherIncome: _parse(_otherIncomeCtrl.text),
      effectiveFrom: _effectiveFrom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<IncomeState>(
      valueListenable: widget.vm.state,
      builder: (_, state, __) => Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          shrinkWrap: true,
          children: [
            Text(l10n.incomeEditBase, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SegmentedButton<IncomeType>(
              segments: [
                ButtonSegment(value: IncomeType.clt, label: Text(l10n.incomeClt)),
                ButtonSegment(value: IncomeType.pj, label: Text(l10n.incomePj)),
                ButtonSegment(value: IncomeType.autonomo, label: Text(l10n.incomeAutonomo)),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 12),
            _AmountField(controller: _grossSalaryCtrl, label: l10n.incomeGrossSalary, required: true),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.incomeVr),
              value: _receivesVr,
              onChanged: (v) => setState(() => _receivesVr = v),
            ),
            if (_receivesVr) ...[
              _AmountField(controller: _vrAmountCtrl, label: l10n.incomeVrAmount),
              const SizedBox(height: 8),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.incomeVa),
              value: _receivesVa,
              onChanged: (v) => setState(() => _receivesVa = v),
            ),
            if (_receivesVa) ...[
              _AmountField(controller: _vaAmountCtrl, label: l10n.incomeVaAmount),
              const SizedBox(height: 8),
            ],
            _AmountField(controller: _commissionCtrl, label: l10n.incomeCommission),
            const SizedBox(height: 8),
            _AmountField(controller: _bonusCtrl, label: l10n.incomeBonus),
            const SizedBox(height: 8),
            _AmountField(controller: _otherIncomeCtrl, label: l10n.incomeOtherIncome),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.incomeEffectiveFrom),
              subtitle: Text(DateFormat('MMMM yyyy', Intl.defaultLocale).format(_effectiveFrom)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickEffectiveFrom,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: state.isSaving ? null : _submit,
              child: state.isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.incomeSave),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Event Bottom Sheet ───────────────────────────────────────────────────

class _AddEventSheet extends StatefulWidget {
  const _AddEventSheet({required this.onSave});
  final Future<void> Function(String description, double amount) onSave;

  @override
  State<_AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<_AddEventSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    await widget.onSave(_descCtrl.text.trim(), amount);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.incomeExtraIncome, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: InputDecoration(labelText: l10n.incomeExtraDescription),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.appGeneralError : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              decoration: InputDecoration(labelText: l10n.expenseAmount, prefixText: 'R\$ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.appGeneralError;
                if ((double.tryParse(v.replaceAll(',', '.')) ?? -1) <= 0) return l10n.appGeneralError;
                return null;
              },
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.appGeneralApply),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Amount Field ──────────────────────────────────────────────────────

class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, required this.label, this.required = false});

  final TextEditingController controller;
  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixText: 'R\$ '),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
      validator: required
          ? (v) {
              if (v == null || v.trim().isEmpty) return l10n.appGeneralError;
              if ((double.tryParse(v.replaceAll(',', '.')) ?? -1) < 0) return l10n.appGeneralError;
              return null;
            }
          : null,
    );
  }
}
