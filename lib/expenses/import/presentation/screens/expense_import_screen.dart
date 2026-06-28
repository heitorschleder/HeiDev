import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injectable.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/routing/app_router.dart';
import '../../../domain/expense_category.dart';
import '../../../domain/expense_payment_method.dart';
import '../../data/models/imported_expense_model.dart';
import '../../domain/logic/expense_import_state.dart';
import '../../domain/logic/expense_import_view_model.dart';

class ExpenseImportScreen extends StatefulWidget {
  const ExpenseImportScreen({super.key});

  @override
  State<ExpenseImportScreen> createState() => _ExpenseImportScreenState();
}

class _ExpenseImportScreenState extends State<ExpenseImportScreen> {
  late final ExpenseImportViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = getIt<ExpenseImportViewModel>();
  }

  @override
  void dispose() {
    _vm.onDisposed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.importTitle)),
      body: ValueListenableBuilder<ExpenseImportState>(
        valueListenable: _vm.state,
        builder: (context, state, _) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator());
          return switch (state.step) {
            ImportStep.picking => _PickingPhase(
              errorMessage: state.errorMessage,
              onPickFile: _vm.pickAndParse,
            ),
            ImportStep.reviewing => _ReviewingPhase(
              key: ValueKey(state.currentIndex),
              state: state,
              onEditCurrent: _vm.editCurrent,
              onSkip: _vm.skip,
              onConfirm: _vm.confirm,
            ),
            ImportStep.done => _DonePhase(
              confirmedCount: state.confirmedCount,
              skippedCount: state.skippedCount,
              onViewExpenses: AppRouter.pop,
            ),
          };
        },
      ),
    );
  }
}

// ── Picking ──────────────────────────────────────────────────────────────────

class _PickingPhase extends StatelessWidget {
  const _PickingPhase({required this.errorMessage, required this.onPickFile});

  final String? errorMessage;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEmptyError = errorMessage == 'vazio';
    final displayError = switch (errorMessage) {
      null => null,
      'vazio' => l10n.importNoItemsFound,
      _ => errorMessage,
    };

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.upload_file_outlined, size: 72, color: cs.primary),
          const SizedBox(height: 24),
          Text(
            l10n.importTitle,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.importDropzoneHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (displayError != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isEmptyError ? cs.surfaceContainerHighest : cs.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayError,
                style: TextStyle(color: isEmptyError ? cs.onSurfaceVariant : cs.onErrorContainer),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: onPickFile,
            icon: const Icon(Icons.folder_open_outlined),
            label: Text(l10n.importSelectFile),
          ),
        ],
      ),
    );
  }
}

// ── Reviewing ────────────────────────────────────────────────────────────────

class _ReviewingPhase extends StatefulWidget {
  const _ReviewingPhase({
    super.key,
    required this.state,
    required this.onEditCurrent,
    required this.onSkip,
    required this.onConfirm,
  });

  final ExpenseImportState state;
  final void Function({
    String? title,
    ExpenseCategory? category,
    double? amount,
    DateTime? date,
    bool? isEssential,
    Object? paymentMethod,
  })
  onEditCurrent;
  final VoidCallback onSkip;
  final Future<void> Function() onConfirm;

  @override
  State<_ReviewingPhase> createState() => _ReviewingPhaseState();
}

class _ReviewingPhaseState extends State<_ReviewingPhase> {
  late TextEditingController _titleCtrl;
  late TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers(widget.state.currentItem!);
  }

  void _initControllers(ImportedExpenseModel item) {
    _titleCtrl = TextEditingController(text: item.title);
    _amountCtrl = TextEditingController(text: item.amount.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final item = state.currentItem!;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: state.progress),
          const SizedBox(height: 4),
          Text(
            '${state.currentIndex + 1} / ${state.items.length}',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.end,
          ),
          const SizedBox(height: 12),
          if (item.isDuplicate) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                border: Border.all(color: Colors.amber.shade600),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    l10n.importDuplicate,
                    style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(labelText: l10n.expenseExpenseName),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (v) => widget.onEditCurrent(title: v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ExpenseCategory>(
                    initialValue: item.category,
                    decoration: InputDecoration(labelText: l10n.expenseCategory),
                    items: ExpenseCategory.values
                        .map((c) => DropdownMenuItem(value: c, child: Text(_categoryLabel(c))))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) widget.onEditCurrent(category: v);
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountCtrl,
                          decoration: InputDecoration(labelText: l10n.expenseAmount, prefixText: 'R\$ '),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (v) {
                            final amount = double.tryParse(v.replaceAll(',', '.'));
                            if (amount != null && amount > 0) widget.onEditCurrent(amount: amount);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: item.date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) widget.onEditCurrent(date: picked);
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(labelText: l10n.expenseDueDate),
                            child: Text(DateFormat('dd/MM/yyyy').format(item.date)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ExpensePaymentMethod?>(
                    initialValue: item.paymentMethod,
                    decoration: InputDecoration(labelText: l10n.expensePaymentMethod),
                    items: [
                      DropdownMenuItem(value: null, child: Text('— ${l10n.expensePaymentMethod} —')),
                      ...ExpensePaymentMethod.values.map(
                        (m) => DropdownMenuItem(value: m, child: Text(_paymentLabel(m))),
                      ),
                    ],
                    onChanged: (v) => widget.onEditCurrent(paymentMethod: v),
                  ),
                  const SizedBox(height: 4),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.isEssential ? l10n.expenseEssential : l10n.expenseNotEssential),
                    value: item.isEssential,
                    onChanged: (v) => widget.onEditCurrent(isEssential: v),
                  ),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage!,
                      style: TextStyle(color: cs.error, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onSkip,
                  child: Text(l10n.importSkip),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: widget.onConfirm,
                  child: Text(l10n.importConfirm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Done ─────────────────────────────────────────────────────────────────────

class _DonePhase extends StatelessWidget {
  const _DonePhase({required this.confirmedCount, required this.skippedCount, required this.onViewExpenses});

  final int confirmedCount;
  final int skippedCount;
  final VoidCallback onViewExpenses;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.check_circle_outline, size: 72, color: cs.primary),
          const SizedBox(height: 24),
          Text(
            l10n.importDoneTitle,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _SummaryRow(
            icon: Icons.check,
            color: Colors.green,
            label: '$confirmedCount ${l10n.importConfirmedCount}',
          ),
          const SizedBox(height: 8),
          _SummaryRow(
            icon: Icons.skip_next,
            color: cs.onSurfaceVariant,
            label: '$skippedCount ${l10n.importSkippedCount}',
          ),
          const SizedBox(height: 40),
          FilledButton(
            onPressed: onViewExpenses,
            child: Text(l10n.importViewExpenses),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.icon, required this.color, required this.label});

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _categoryLabel(ExpenseCategory cat) => switch (cat) {
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

String _paymentLabel(ExpensePaymentMethod m) => switch (m) {
  ExpensePaymentMethod.dinheiro => l10n.expensePayMethodDinheiro,
  ExpensePaymentMethod.credito => l10n.expensePayMethodCredito,
  ExpensePaymentMethod.debito => l10n.expensePayMethodDebito,
  ExpensePaymentMethod.valeAlimentacao => l10n.expensePayMethodValeAlim,
  ExpensePaymentMethod.valeRefeicao => l10n.expensePayMethodValeRef,
};
