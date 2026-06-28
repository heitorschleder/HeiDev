import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/di/injectable.dart';
import '../../../core/l10n/l10n.dart';
import '../../data/models/bill_template_model.dart';
import '../../data/models/expense_model.dart';
import '../../domain/expense_category.dart';
import '../../domain/expense_payment_method.dart';
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
  final _totalAmountCtrl = TextEditingController();
  final _installmentsCtrl = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.outros;
  ExpensePaymentMethod _paymentMethod = ExpensePaymentMethod.dinheiro;
  bool _isEssential = true;
  bool _isInstallment = false;
  DateTime _dueDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _vm = getIt<ExpenseFormViewModel>();
    _vm.state.addListener(_onStateChanged);
    unawaited(_vm.init());
    _templateVm = getIt<BillTemplateListViewModel>();
    unawaited(_templateVm.init());

    _totalAmountCtrl.addListener(() => setState(() {}));
    _installmentsCtrl.addListener(() => setState(() {}));

    final e = widget.expense;
    if (e != null) {
      _titleCtrl.text = e.title;
      _amountCtrl.text = e.amount.toStringAsFixed(2);
      _notesCtrl.text = e.notes ?? '';
      _category = e.category;
      _paymentMethod = e.paymentMethod ?? ExpensePaymentMethod.dinheiro;
      _isEssential = e.isEssential;
      _dueDate = e.dueDate;
    }
  }

  void _onStateChanged() {
    if (!mounted) return;
    setState(() {});
    final state = _vm.state.value;
    if (state.savedSuccess || state.deleteSuccess) {
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

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.expenseDeleteConfirm),
        content: Text(widget.expense!.title),
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
    if (ok ?? false) unawaited(_vm.delete(widget.expense!.id));
  }

  @override
  void dispose() {
    _vm.state.removeListener(_onStateChanged);
    _vm.onDisposed();
    _templateVm.onDisposed();
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    _totalAmountCtrl.dispose();
    _installmentsCtrl.dispose();
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
    final totalAmount = double.tryParse(_totalAmountCtrl.text.replaceAll(',', '.')) ?? 0;
    final installments = int.tryParse(_installmentsCtrl.text) ?? 1;
    final referenceMonth = DateTime(_dueDate.year, _dueDate.month);
    await _vm.save(
      title: _titleCtrl.text.trim(),
      category: _category,
      isEssential: _isEssential,
      amount: _isInstallment ? totalAmount / installments : amount,
      dueDate: _dueDate,
      priority: ExpensePriority.media,
      referenceMonth: referenceMonth,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      paymentMethod: _paymentMethod,
      isInstallment: _isInstallment,
      totalAmount: totalAmount,
      installments: installments,
      existing: widget.expense,
    );
  }

  double get _perInstallment {
    final total = double.tryParse(_totalAmountCtrl.text.replaceAll(',', '.')) ?? 0;
    final n = int.tryParse(_installmentsCtrl.text) ?? 1;
    return n > 0 ? (total / n * 100).round() / 100 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    final expense = widget.expense;
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.expenseEditExpense : l10n.expenseNewExpense),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(labelText: l10n.expenseExpenseName),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => (v == null || v.trim().isEmpty) ? l10n.appGeneralError : null,
                  ),
                ),
                if (isEditing && expense?.totalInstallments != null) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('${expense!.installmentNumber}/${expense.totalInstallments}'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (!_isInstallment)
              TextFormField(
                controller: _amountCtrl,
                decoration: InputDecoration(labelText: l10n.expenseAmount, prefixText: 'R\$ '),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
                validator: (v) {
                  if (_isInstallment) return null;
                  if (v == null || v.trim().isEmpty) return l10n.appGeneralError;
                  if ((double.tryParse(v.replaceAll(',', '.')) ?? -1) < 0) return l10n.appGeneralError;
                  return null;
                },
              ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.expenseDueDate),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('dd/MM/yyyy').format(_dueDate)),
                  if (_isInstallment)
                    Text(
                      l10n.expenseInstallmentDateHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const Divider(),
            _CategoryDropdown(
              value: _category,
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 12),
            _PaymentMethodDropdown(
              value: _paymentMethod,
              onChanged: (v) => setState(() => _paymentMethod = v),
              allowedMethods: _vm.state.value.allowedPaymentMethods,
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_isEssential ? l10n.expenseEssential : l10n.expenseNotEssential),
              value: _isEssential,
              onChanged: (v) => setState(() => _isEssential = v),
            ),
            if (!isEditing) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.expenseInstallment),
                value: _isInstallment,
                onChanged: (v) => setState(() => _isInstallment = v),
              ),
              if (_isInstallment) ...[
                TextFormField(
                  controller: _totalAmountCtrl,
                  decoration: InputDecoration(labelText: l10n.expenseInstallmentTotal, prefixText: 'R\$ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
                  validator: (v) {
                    if (!_isInstallment) return null;
                    if (v == null || v.trim().isEmpty) return l10n.appGeneralError;
                    if ((double.tryParse(v.replaceAll(',', '.')) ?? -1) <= 0) return l10n.appGeneralError;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _installmentsCtrl,
                  decoration: InputDecoration(labelText: l10n.expenseInstallmentCount),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (!_isInstallment) return null;
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 2 || n > 60) return l10n.appGeneralError;
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                if (_perInstallment > 0)
                  Text(
                    '${fmt.format(_perInstallment)} ${l10n.expenseInstallmentPer}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ],
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
    ExpenseCategory.vestuario => l10n.expenseCatVestuario,
    ExpenseCategory.cosmeticos => l10n.expenseCatCosmeticos,
    ExpenseCategory.assinaturas => l10n.expenseCatAssinaturas,
    ExpenseCategory.pet => l10n.expenseCatPet,
    ExpenseCategory.outros => l10n.expenseCatOutros,
  };
}

class _PaymentMethodDropdown extends StatelessWidget {
  const _PaymentMethodDropdown({
    required this.value,
    required this.onChanged,
    required this.allowedMethods,
  });

  final ExpensePaymentMethod value;
  final ValueChanged<ExpensePaymentMethod> onChanged;
  final List<ExpensePaymentMethod> allowedMethods;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = allowedMethods.contains(value) ? value : allowedMethods.first;
    return DropdownButtonFormField<ExpensePaymentMethod>(
      key: ValueKey(effectiveValue),
      initialValue: effectiveValue,
      decoration: InputDecoration(labelText: l10n.expensePaymentMethod),
      items: allowedMethods.map((m) => DropdownMenuItem(value: m, child: Text(_label(m)))).toList(),
      onChanged: (v) => onChanged(v!),
    );
  }

  String _label(ExpensePaymentMethod m) => switch (m) {
    ExpensePaymentMethod.dinheiro => l10n.expensePayMethodDinheiro,
    ExpensePaymentMethod.credito => l10n.expensePayMethodCredito,
    ExpensePaymentMethod.debito => l10n.expensePayMethodDebito,
    ExpensePaymentMethod.valeAlimentacao => l10n.expensePayMethodValeAlim,
    ExpensePaymentMethod.valeRefeicao => l10n.expensePayMethodValeRef,
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
