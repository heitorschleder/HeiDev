import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injectable.dart';
import '../../../core/l10n/l10n.dart';
import '../../data/models/bill_template_model.dart';
import '../../data/models/expense_model.dart';
import '../../domain/expense_category.dart';
import '../../domain/expense_priority.dart';
import '../../domain/logic/bill_template_list_state.dart';
import '../../domain/logic/bill_template_list_view_model.dart';
import '../../domain/logic/expense_form_state.dart';
import '../../domain/logic/expense_form_view_model.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.expense});

  final ExpenseModel? expense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  late final ExpenseFormViewModel _vm;
  late final BillTemplateListViewModel _templateVm;

  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.outros;
  ExpensePriority _priority = ExpensePriority.media;
  bool _isEssential = true;
  DateTime _dueDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _vm = getIt<ExpenseFormViewModel>();
    _vm.state.addListener(_onStateChanged);
    _templateVm = getIt<BillTemplateListViewModel>();
    unawaited(_templateVm.init());

    final e = widget.expense;
    if (e != null) {
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _notesCtrl.text = e.notes ?? '';
      _category = e.category;
      _priority = e.priority;
      _isEssential = e.isEssential;
      _dueDate = e.dueDate;
    }
  }

  void _onStateChanged() {
    final state = _vm.state.value;
    if (state.savedSuccess) {
      Navigator.of(context).pop();
      return;
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

  @override
  void dispose() {
    _vm.state.removeListener(_onStateChanged);
    _vm.onDisposed();
    _templateVm.onDisposed();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTemplate() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _TemplatePicker(
        templateVm: _templateVm,
        onSelected: (template) {
          Navigator.pop(ctx);
          setState(() {
            _titleCtrl.text = template.title;
            _amountCtrl.text = template.defaultAmount.toStringAsFixed(2);
            _category = template.category;
            _isEssential = template.isEssential;
          });
        },
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0;
    final referenceMonth = DateTime(_dueDate.year, _dueDate.month);
    await _vm.save(
      title: _titleCtrl.text.trim(),
      category: _category,
      isEssential: _isEssential,
      amount: amount,
      dueDate: _dueDate,
      priority: _priority,
      referenceMonth: referenceMonth,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      existing: widget.expense,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.expenseEditExpense : l10n.expenseNewExpense),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!isEditing)
              OutlinedButton.icon(
                onPressed: _pickTemplate,
                icon: const Icon(Icons.copy_outlined),
                label: Text(l10n.expenseUseTemplate),
              ),
            if (!isEditing) const SizedBox(height: 12),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(labelText: l10n.expenseExpenseName),
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
                if ((double.tryParse(v.replaceAll(',', '.')) ?? -1) < 0) return l10n.appGeneralError;
                return null;
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.expenseDueDate),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(_dueDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const Divider(),
            _CategoryDropdown(
              value: _category,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            _PriorityDropdown(
              value: _priority,
              onChanged: (v) => setState(() => _priority = v),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_isEssential ? l10n.expenseEssential : l10n.expenseNotEssential),
              value: _isEssential,
              onChanged: (v) => setState(() => _isEssential = v),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _notesCtrl,
              decoration: InputDecoration(labelText: l10n.expenseNotes),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ValueListenableBuilder<ExpenseFormState>(
              valueListenable: _vm.state,
              builder: (_, state, __) => FilledButton(
                onPressed: state.isSaving ? null : _submit,
                child: state.isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.expenseSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.value, required this.onChanged});

  final ExpenseCategory value;
  final ValueChanged<ExpenseCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ExpenseCategory>(
      key: ValueKey(value),
      initialValue: value,
      decoration: InputDecoration(labelText: l10n.expenseCategory),
      items: ExpenseCategory.values
          .map(
            (c) => DropdownMenuItem(value: c, child: Text(_label(c))),
          )
          .toList(),
      onChanged: (v) => onChanged(v!),
    );
  }

  String _label(ExpenseCategory c) => switch (c) {
    ExpenseCategory.casa => l10n.expenseCatCasa,
    ExpenseCategory.transporte => l10n.expenseCatTransporte,
    ExpenseCategory.alimentacao => l10n.expenseCatAlimentacao,
    ExpenseCategory.saude => l10n.expenseCatSaude,
    ExpenseCategory.lazer => l10n.expenseCatLazer,
    ExpenseCategory.impostos => l10n.expenseCatImpostos,
    ExpenseCategory.outros => l10n.expenseCatOutros,
  };
}

class _PriorityDropdown extends StatelessWidget {
  const _PriorityDropdown({required this.value, required this.onChanged});

  final ExpensePriority value;
  final ValueChanged<ExpensePriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ExpensePriority>(
      key: ValueKey(value),
      initialValue: value,
      decoration: InputDecoration(labelText: l10n.expensePriority),
      items: ExpensePriority.values
          .map(
            (p) => DropdownMenuItem(value: p, child: Text(_label(p))),
          )
          .toList(),
      onChanged: (v) => onChanged(v!),
    );
  }

  String _label(ExpensePriority p) => switch (p) {
    ExpensePriority.alta => l10n.expensePrioAlta,
    ExpensePriority.media => l10n.expensePrioMedia,
    ExpensePriority.baixa => l10n.expensePrioBaixa,
  };
}

class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker({required this.templateVm, required this.onSelected});

  final BillTemplateListViewModel templateVm;
  final ValueChanged<BillTemplateModel> onSelected;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l10n.expenseUseTemplate, style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: ValueListenableBuilder<BillTemplateListState>(
              valueListenable: templateVm.state,
              builder: (_, state, __) {
                if (state.isLoading) return const Center(child: CircularProgressIndicator());
                if (state.templates.isEmpty) return Center(child: Text(l10n.billTemplatesNoTemplates));
                return ListView.builder(
                  controller: scrollCtrl,
                  itemCount: state.templates.length,
                  itemBuilder: (_, i) {
                    final t = state.templates[i];
                    return ListTile(
                      title: Text(t.title),
                      subtitle: Text('R\$ ${t.defaultAmount.toStringAsFixed(2)}'),
                      onTap: () => onSelected(t),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
