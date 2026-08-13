import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/denomination_record.dart';
import '../services/api_service.dart';

class DenominationsScreen extends StatefulWidget {
  const DenominationsScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<DenominationsScreen> createState() => _DenominationsScreenState();
}

class _DenominationsScreenState extends State<DenominationsScreen> {
  static const _denoms = <int>[500, 200, 100, 50, 20, 10, 5, 2, 1];

  final Map<int, TextEditingController> _countCtrls = {
    for (final v in _denoms) v: TextEditingController(),
  };

  final _weekCtrl = TextEditingController();
  final _adjustCtrl = TextEditingController();
  final _atmCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  bool _loading = true;
  bool _saving = false;
  double _prevBalance = 0;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _load();
    for (final c in _countCtrls.values) {
      c.addListener(_refresh);
    }
    _weekCtrl.addListener(_refresh);
    _adjustCtrl.addListener(_refresh);
  }

  @override
  void dispose() {
    for (final c in _countCtrls.values) {
      c.dispose();
    }
    _weekCtrl.dispose();
    _adjustCtrl.dispose();
    _atmCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  String get _dateText => DateFormat('dd/MMM/yyyy').format(_date);

  int _intFrom(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;
  double _numFrom(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  Map<int, int> get _counts => {
        for (final e in _countCtrls.entries) e.key: _intFrom(e.value),
      };

  double get _total => ApiService.computeDenominationTotal(_counts);
  double get _weekExpenses => _numFrom(_weekCtrl);
  double get _adjust => _numFrom(_adjustCtrl);
  double get _acPaid => (_total + _adjust) - _weekExpenses;
  double get _availableBalance => _prevBalance + _acPaid;

  Future<void> _load() async {
    setState(() => _loading = true);
    final prevBal =
        await ApiService.fetchDenominationPreviousBalance(_dateText);
    final row = await ApiService.fetchDenominationByDate(_dateText);

    if (row == null) {
      for (final c in _countCtrls.values) {
        c.text = '';
      }
      _weekCtrl.clear();
      _adjustCtrl.clear();
      _atmCtrl.clear();
      _remarksCtrl.clear();
    } else {
      for (final d in _denoms) {
        final count = row.counts[d] ?? 0;
        _countCtrls[d]!.text = count == 0 ? '' : '$count';
      }
      _weekCtrl.text =
          row.weekExpenses == 0 ? '' : row.weekExpenses.toStringAsFixed(0);
      _adjustCtrl.text =
          row.adjustAmount == 0 ? '' : row.adjustAmount.toStringAsFixed(0);
      _atmCtrl.text =
          row.atmWithdrawal == 0 ? '' : row.atmWithdrawal.toStringAsFixed(0);
      _remarksCtrl.text = row.remarks;
    }

    if (!mounted) return;
    setState(() {
      _prevBalance = prevBal;
      _loading = false;
    });
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _date = picked);
    await _load();
  }

  void _shiftDay(int delta) {
    setState(() => _date = _date.add(Duration(days: delta)));
    _load();
  }

  void _clear() {
    for (final c in _countCtrls.values) {
      c.clear();
    }
    _weekCtrl.clear();
    _adjustCtrl.clear();
    _atmCtrl.clear();
    _remarksCtrl.clear();
    setState(() {});
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final record = DenominationRecord(
      date: _dateText,
      counts: _counts,
      weekExpenses: _weekExpenses,
      adjustAmount: _adjust,
      atmWithdrawal: _numFrom(_atmCtrl),
      acPaid: _acPaid,
      availableBalance: _availableBalance,
      remarks: _remarksCtrl.text.trim(),
      total: _total,
    );

    await ApiService.saveDenominationRecord(record);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Denomination record saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080C14),
        title: const Text("Denom's"),
        actions: [
          IconButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/report/denominations'),
            icon: const Icon(Icons.pie_chart_outline_rounded),
          ),
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 120),
              children: [
                _dateHeader(),
                const SizedBox(height: 10),
                _totalCard(),
                const SizedBox(height: 10),
                _denomGrid(),
                const SizedBox(height: 10),
                _extraFields(),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          border: Border(top: BorderSide(color: Color(0x22334155))),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _clear,
                  icon: const Icon(Icons.cleaning_services_rounded),
                  label: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateHeader() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x661E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _shiftDay(-1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: InkWell(
              onTap: _pickDate,
              child: Column(
                children: [
                  const Text('Date',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                  Text(_dateText,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () => _shiftDay(1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _totalCard() {
    final nf =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x661E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Cash in Hand',
              style: TextStyle(
                  color: Color(0xFF94A3B8), fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            nf.format(_total),
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _pill('Prev Bal', nf.format(_prevBalance))),
              const SizedBox(width: 8),
              Expanded(child: _pill('A/C Paid', nf.format(_acPaid))),
              const SizedBox(width: 8),
              Expanded(child: _pill('Avail Bal', nf.format(_availableBalance))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x401E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _denomGrid() {
    return GridView.builder(
      itemCount: _denoms.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final denom = _denoms[index];
        final ctrl = _countCtrls[denom]!;
        final count = _intFrom(ctrl);
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0x661E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: count > 0
                  ? const Color(0xFF6366F1).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('₹$denom',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '0',
                ),
              ),
              const Spacer(),
              Text(
                NumberFormat('#,##0', 'en_IN').format(count * denom),
                style: const TextStyle(
                    color: Color(0xFF94A3B8), fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _extraFields() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x661E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _input('Week Expenses', _weekCtrl)),
              const SizedBox(width: 8),
              Expanded(child: _input('Adjust Amount', _adjustCtrl)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _input('ATM Withdrawal', _atmCtrl)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  readOnly: true,
                  controller:
                      TextEditingController(text: _acPaid.toStringAsFixed(2)),
                  decoration: const InputDecoration(labelText: 'A/C Paid'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _remarksCtrl,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Remarks'),
          ),
        ],
      ),
    );
  }

  Widget _input(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
    );
  }
}
