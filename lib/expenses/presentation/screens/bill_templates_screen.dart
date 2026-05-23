import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/di/injectable.dart';
import '../../../core/l10n/l10n.dart';
import '../../data/models/bill_template_model.dart';
import '../../domain/expense_category.dart';
import '../../domain/logic/bill_template_list_state.dart';
import '../../domain/logic/bill_template_list_view_model.dart';

class BillTemplatesScreen extends StatefulWidget {
  const BillTemplatesScreen({super.key});

  @override
  State<BillTemplatesScreen> createState() => _BillTemplatesScreenState();
}

class _BillTemplatesScreenState extends State<BillTemplatesScreen> {
  late final BillTemplateListViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = getIt<BillTemplateListViewModel>();
    unawaited(_vm.init());
    _vm.state.addListener(_onError);
  }

  void _onError() {
    final msg = _vm.state.value.errorMessage;
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  void dispose() {
    _vm.state.removeListener(_onError);
    _vm.onDisposed();
    super.dispose();
  }

  Future<void> _openForm([BillTemplateModel? template]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TemplateForm(
        template: template,
        onSave: ({required title, required category, required isEssential, required defaultAmount}) async {
          if (template == null) {
            await _vm.saveTemplate(
              title: title,
              category: category,
              isEssential: isEssential,
              defaultAmount: defaultAmount,
            );
          } else {
            await _vm.updateTemplate(
              template.copyWith(
                title: title,
                category: category,
                isEssential: isEssential,
                defaultAmount: defaultAmount,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(BillTemplateModel template) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.billTemplatesDeleteConfirm),
        content: Text(template.title),
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
    if (ok ?? false) unawaited(_vm.deleteTemplate(template.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.billTemplatesTitle)),
      body: ValueListenableBuilder<BillTemplateListState>(
        valueListenable: _vm.state,
        builder: (context, state, _) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator());
          if (state.templates.isEmpty) return Center(child: Text(l10n.billTemplatesNoTemplates));
          return ListView.builder(
            itemCount: state.templates.length,
            itemBuilder: (_, i) {
              final t = state.templates[i];
              return ListTile(
                title: Text(t.title),
                subtitle: Text('R\$ ${t.defaultAmount.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _openForm(t)),
                    IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmDelete(t)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TemplateForm extends StatefulWidget {
  const _TemplateForm({this.template, required this.onSave});

  final BillTemplateModel? template;
  final Future<void> Function({
    required String title,
    required ExpenseCategory category,
    required bool isEssential,
    required double defaultAmount,
  })
  onSave;

  @override
  State<_TemplateForm> createState() => _TemplateFormState();
}

class _TemplateFormState extends State<_TemplateForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _amountCtrl;
  late ExpenseCategory _category;
  late bool _isEssential;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _amountCtrl = TextEditingController(text: t != null ? t.defaultAmount.toStringAsFixed(2) : '');
    _category = t?.category ?? ExpenseCategory.outros;
    _isEssential = t?.isEssential ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await widget.onSave(
      title: _titleCtrl.text.trim(),
      category: _category,
      isEssential: _isEssential,
      defaultAmount: double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.template != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEditing ? l10n.billTemplatesEditTemplate : l10n.billTemplatesNewTemplate,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: InputDecoration(labelText: l10n.expenseExpenseName),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.appGeneralError : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              decoration: InputDecoration(
                labelText: l10n.billTemplatesDefaultAmount,
                prefixText: 'R\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              key: ValueKey(_category),
              initialValue: _category,
              decoration: InputDecoration(labelText: l10n.expenseCategory),
              items: ExpenseCategory.values
                  .map(
                    (c) => DropdownMenuItem(value: c, child: Text(_categoryLabel(c))),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_isEssential ? l10n.expenseEssential : l10n.expenseNotEssential),
              value: _isEssential,
              onChanged: (v) => setState(() => _isEssential = v),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.billTemplatesSaveTemplate),
            ),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(ExpenseCategory c) => switch (c) {
    ExpenseCategory.casa => l10n.expenseCatCasa,
    ExpenseCategory.transporte => l10n.expenseCatTransporte,
    ExpenseCategory.alimentacao => l10n.expenseCatAlimentacao,
    ExpenseCategory.saude => l10n.expenseCatSaude,
    ExpenseCategory.lazer => l10n.expenseCatLazer,
    ExpenseCategory.impostos => l10n.expenseCatImpostos,
    ExpenseCategory.outros => l10n.expenseCatOutros,
  };
}
