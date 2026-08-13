import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/debt_record.dart';
import '../services/api_service.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key, this.editRecord});

  final DebtRecord? editRecord;

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _personCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  String _type = 'given';
  DateTime _date = DateTime.now();
  bool _saving = false;

  bool get _isEdit => widget.editRecord != null;

  @override
  void initState() {
    super.initState();
    final r = widget.editRecord;
    if (r != null) {
      _type = r.type;
      _personCtrl.text = r.person;
      _amountCtrl.text = r.amount.toStringAsFixed(0);
      _remarksCtrl.text = r.remarks;
      _date = _parseDate(r.date);
    }
  }

  @override
  void dispose() {
    _personCtrl.dispose();
    _amountCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  DateTime _parseDate(String s) {
    final m = RegExp(r'^(\d{2})/(\w{3})/(\d{4})$').firstMatch(s);
    if (m == null) return DateTime.now();
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final day = int.tryParse(m.group(1)!) ?? 1;
    final month = months[m.group(2)!] ?? DateTime.now().month;
    final year = int.tryParse(m.group(3)!) ?? DateTime.now().year;
    return DateTime(year, month, day);
  }

  String _fmtDate(DateTime d) => DateFormat('dd/MMM/yyyy').format(d);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll(',', '').trim()) ?? 0;

    final payload = {
      if (_isEdit) 'id': widget.editRecord!.id,
      'date': _fmtDate(_date),
      'type': _type,
      'person': _personCtrl.text.trim(),
      'amount': amount,
      'remarks': _remarksCtrl.text.trim(),
      'status': _isEdit ? widget.editRecord!.status : 'pending',
      'settleRemarks': _isEdit ? widget.editRecord!.settleRemarks : '',
    };

    try {
      await ApiService.saveDebt(payload);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save debt record')),
      );
      setState(() => _saving = false);
    }
  }

  void _clear() {
    setState(() {
      _type = 'given';
      _personCtrl.clear();
      _amountCtrl.clear();
      _remarksCtrl.clear();
      _date = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: Text(_isEdit ? 'Edit Debt Record' : 'Add New Debt'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _typeChip(
                    label: 'Given',
                    icon: Icons.trending_up_rounded,
                    value: 'given',
                    activeColor: const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _typeChip(
                    label: 'Taken',
                    icon: Icons.trending_down_rounded,
                    value: 'taken',
                    activeColor: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _input(
              'Person Name',
              _personCtrl,
              icon: Icons.person_rounded,
            ),
            const SizedBox(height: 12),
            _input(
              'Amount',
              _amountCtrl,
              icon: Icons.currency_rupee_rounded,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                child: Text(_fmtDate(_date)),
              ),
            ),
            const SizedBox(height: 12),
            _input(
              'Remarks',
              _remarksCtrl,
              icon: Icons.notes_rounded,
              maxLines: 3,
              required: false,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _clear,
                    icon: const Icon(Icons.cleaning_services_rounded),
                    label: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
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
                    label: Text(_saving
                        ? (_isEdit ? 'Updating...' : 'Saving...')
                        : (_isEdit ? 'Update Record' : 'Save Record')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required IconData icon,
    required String value,
    required Color activeColor,
  }) {
    final selected = _type == value;
    return InkWell(
      onTap: () => setState(() => _type = value),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? activeColor.withValues(alpha: 0.6) : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? activeColor : Colors.white70),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? activeColor : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController ctrl, {
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = true,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon),
      ),
      validator: (v) {
        if (!required) return null;
        if ((v ?? '').trim().isEmpty) return 'Required';
        if (label == 'Amount' &&
            (double.tryParse((v ?? '').replaceAll(',', '').trim()) == null)) {
          return 'Invalid amount';
        }
        return null;
      },
    );
  }
}

