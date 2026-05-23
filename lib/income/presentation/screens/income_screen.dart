import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/di/injectable.dart';
import '../../../core/l10n/l10n.dart';
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
  final _formKey = GlobalKey<FormState>();

  IncomeType _type = IncomeType.clt;
  bool _receivesVr = false;
  bool _receivesVa = false;

  final _grossSalaryCtrl = TextEditingController();
  final _vrAmountCtrl = TextEditingController();
  final _vaAmountCtrl = TextEditingController();
  final _commissionCtrl = TextEditingController();
  final _bonusCtrl = TextEditingController();
  final _otherIncomeCtrl = TextEditingController();

  final _totalNotifier = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _vm = getIt<IncomeViewModel>();
    unawaited(_vm.init());
    _vm.state.addListener(_onStateChanged);
    for (final ctrl in _allControllers) {
      ctrl.addListener(_updateTotal);
    }
  }

  List<TextEditingController> get _allControllers => [
    _grossSalaryCtrl,
    _vrAmountCtrl,
    _vaAmountCtrl,
    _commissionCtrl,
    _bonusCtrl,
    _otherIncomeCtrl,
  ];

  void _onStateChanged() {
    final income = _vm.state.value.income;
    if (income != null && _grossSalaryCtrl.text.isEmpty) {
      _populateForm(income);
    }
    if (_vm.state.value.savedSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.incomeSavedSuccess)));
    }
    if (_vm.state.value.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_vm.state.value.errorMessage!), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  void _populateForm(IncomeModel income) {
    setState(() => _type = income.type);
    _grossSalaryCtrl.text = _formatAmount(income.grossSalary);
    setState(() => _receivesVr = income.receivesVr);
    _vrAmountCtrl.text = _formatAmount(income.vrAmount);
    setState(() => _receivesVa = income.receivesVa);
    _vaAmountCtrl.text = _formatAmount(income.vaAmount);
    _commissionCtrl.text = _formatAmount(income.commission);
    _bonusCtrl.text = _formatAmount(income.bonus);
    _otherIncomeCtrl.text = _formatAmount(income.otherIncome);
  }

  String _formatAmount(double value) => value == 0 ? '' : value.toStringAsFixed(2);

  void _updateTotal() {
    final gross = _parseAmount(_grossSalaryCtrl.text);
    final vr = _receivesVr ? _parseAmount(_vrAmountCtrl.text) : 0.0;
    final va = _receivesVa ? _parseAmount(_vaAmountCtrl.text) : 0.0;
    final commission = _parseAmount(_commissionCtrl.text);
    final bonus = _parseAmount(_bonusCtrl.text);
    final other = _parseAmount(_otherIncomeCtrl.text);
    _totalNotifier.value = gross + vr + va + commission + bonus + other;
  }

  double _parseAmount(String text) => double.tryParse(text.replaceAll(',', '.')) ?? 0.0;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await _vm.save(
      type: _type,
      grossSalary: _parseAmount(_grossSalaryCtrl.text),
      receivesVr: _receivesVr,
      vrAmount: _parseAmount(_vrAmountCtrl.text),
      receivesVa: _receivesVa,
      vaAmount: _parseAmount(_vaAmountCtrl.text),
      commission: _parseAmount(_commissionCtrl.text),
      bonus: _parseAmount(_bonusCtrl.text),
      otherIncome: _parseAmount(_otherIncomeCtrl.text),
    );
  }

  @override
  void dispose() {
    _vm.state.removeListener(_onStateChanged);
    _vm.onDisposed();
    for (final ctrl in _allControllers) {
      ctrl.dispose();
    }
    _totalNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(l10n.incomeTitle)),
      body: ValueListenableBuilder<IncomeState>(
        valueListenable: _vm.state,
        builder: (context, state, _) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator());
          return _buildForm(state);
        },
      ),
    );
  }

  Widget _buildForm(IncomeState state) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TypeSegment(
            selected: _type,
            onChanged: (t) => setState(() {
              _type = t;
              _updateTotal();
            }),
          ),
          const SizedBox(height: 16),
          _AmountField(controller: _grossSalaryCtrl, label: l10n.incomeGrossSalary, required: true),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.incomeVr),
            value: _receivesVr,
            onChanged: (v) => setState(() {
              _receivesVr = v;
              _updateTotal();
            }),
          ),
          if (_receivesVr) ...[
            _AmountField(controller: _vrAmountCtrl, label: l10n.incomeVrAmount),
            const SizedBox(height: 8),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.incomeVa),
            value: _receivesVa,
            onChanged: (v) => setState(() {
              _receivesVa = v;
              _updateTotal();
            }),
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
          const SizedBox(height: 24),
          _TotalCard(totalNotifier: _totalNotifier),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.isSaving ? null : _submit,
            child: state.isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.incomeSave),
          ),
        ],
      ),
    );
  }
}

class _TypeSegment extends StatelessWidget {
  const _TypeSegment({required this.selected, required this.onChanged});

  final IncomeType selected;
  final ValueChanged<IncomeType> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<IncomeType>(
      segments: [
        ButtonSegment(value: IncomeType.clt, label: Text(l10n.incomeClt)),
        ButtonSegment(value: IncomeType.pj, label: Text(l10n.incomePj)),
        ButtonSegment(value: IncomeType.autonomo, label: Text(l10n.incomeAutonomo)),
      ],
      selected: {selected},
      onSelectionChanged: (set) => onChanged(set.first),
    );
  }
}

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

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.totalNotifier});

  final ValueNotifier<double> totalNotifier;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.incomeTotalIncome, style: Theme.of(context).textTheme.titleMedium),
            ValueListenableBuilder<double>(
              valueListenable: totalNotifier,
              builder: (_, total, __) => Text(
                'R\$ ${total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
