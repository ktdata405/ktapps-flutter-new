import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cashew_record.dart';
import '../services/api_service.dart';

class CashewScreen extends StatefulWidget {
  const CashewScreen({super.key, this.initialDate});

  final DateTime? initialDate;

  @override
  State<CashewScreen> createState() => _CashewScreenState();
}

class _CashewScreenState extends State<CashewScreen> {
  static const _categories = <String>[
    'Home',
    'My Personal',
    'My Family',
    'For Latha',
    'Baby',
    'Credit Card',
    'Mutual Funds/Investments',
    'Lap EMI',
  ];

  final _rows = <_ExpenseRow>[];
  DateTime _date = DateTime.now();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateTime.now();
    _loadForDate();
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  String get _dateText => DateFormat('dd/MMM/yyyy').format(_date);

  Future<void> _loadForDate() async {
    setState(() => _loading = true);
    final data = await ApiService.fetchCashewRecordsByDate(_dateText);
    for (final row in _rows) {
      row.dispose();
    }
    _rows.clear();

    if (data.isEmpty) {
      _rows.addAll([
        _ExpenseRow(category: 'Home'),
        _ExpenseRow(category: 'My Personal'),
        _ExpenseRow(category: 'My Family'),
      ]);
    } else {
      _rows.addAll(
        data.map(
          (e) => _ExpenseRow(
            category: e.category,
            amount: e.amount,
            description: e.description,
            status: e.status,
          ),
        ),
      );
    }

    if (mounted) {
      setState(() => _loading = false);
    }
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
    await _loadForDate();
  }

  void _shiftDay(int delta) {
    setState(() => _date = _date.add(Duration(days: delta)));
    _loadForDate();
  }

  double get _total {
    return _rows.fold<double>(
      0,
      (sum, row) => sum + (double.tryParse(row.amount.text.trim()) ?? 0),
    );
  }

  void _addRow() {
    setState(() {
      _rows.add(_ExpenseRow(category: 'Home'));
    });
  }

  void _removeRow(int index) {
    if (_rows.length == 1) {
      _rows.first
        ..amount.clear()
        ..description.clear()
        ..category = 'Home'
        ..status = 'completed';
      setState(() {});
      return;
    }
    final row = _rows.removeAt(index);
    row.dispose();
    setState(() {});
  }

  Future<void> _save(String status) async {
    final records = <CashewRecord>[];
    for (final row in _rows) {
      final amount = double.tryParse(row.amount.text.trim()) ?? 0;
      if (amount <= 0) continue;
      records.add(
        CashewRecord(
          date: _dateText,
          category: row.category,
          description: row.description.text.trim(),
          amount: amount,
          status: status,
        ),
      );
    }

    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one valid expense')),
      );
      return;
    }

    setState(() => _saving = true);
    await ApiService.saveCashewRecordsForDate(
      date: _dateText,
      records: records,
      status: status,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(status == 'draft' ? 'Draft saved' : 'Expenses saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: const Text('Cashew'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/report/cashew'),
            icon: const Icon(Icons.pie_chart_outline_rounded),
          ),
          IconButton(
            onPressed: _loading ? null : _loadForDate,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 130),
              children: [
                _dateHeader(),
                const SizedBox(height: 12),
                ...List.generate(_rows.length, (i) => _expenseCard(i)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addRow,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Expense'),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          border: Border(top: BorderSide(color: Color(0x22334155))),
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Total Expense',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    NumberFormat.currency(
                            locale: 'en_IN', symbol: '₹', decimalDigits: 2)
                        .format(_total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : () => _save('draft'),
                      icon: _saving
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.edit_note_rounded),
                      label: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : () => _save('completed'),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
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
                  const SizedBox(height: 2),
                  Text(
                    _dateText,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
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

  Widget _expenseCard(int index) {
    final row = _rows[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _categories.contains(row.category)
                      ? row.category
                      : _categories.first,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => row.category = v ?? _categories.first,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: row.amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              IconButton(
                onPressed: () => _removeRow(index),
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFFB7185)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: row.description,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'What is this expense for?',
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseRow {
  _ExpenseRow({
    required this.category,
    double? amount,
    String? description,
    this.status = 'completed',
  })  : amount = TextEditingController(
          text: amount == null || amount == 0 ? '' : amount.toStringAsFixed(2),
        ),
        description = TextEditingController(text: description ?? '');

  String category;
  String status;
  final TextEditingController amount;
  final TextEditingController description;

  void dispose() {
    amount.dispose();
    description.dispose();
  }
}
