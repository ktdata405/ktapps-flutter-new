import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/rent_record.dart';
import '../services/api_service.dart';

class RentScreen extends StatefulWidget {
  const RentScreen({super.key, this.editRecord});

  final RentRecord? editRecord;

  @override
  State<RentScreen> createState() => _RentScreenState();
}

class _RentScreenState extends State<RentScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _dateCtrl;
  late final TextEditingController _rentCtrl;
  late final TextEditingController _paidCtrl;
  late final TextEditingController _balanceCtrl;
  late final TextEditingController _powerCtrl;
  late final TextEditingController _waterCtrl;
  late final TextEditingController _remarksCtrl;

  String _side = 'Kalyan';
  bool _saving = false;

  bool get _isEdit => widget.editRecord != null;

  @override
  void initState() {
    super.initState();
    final record = widget.editRecord;

    _dateCtrl = TextEditingController(
      text: record?.date ?? DateFormat('dd/MMM/yyyy').format(DateTime.now()),
    );
    _rentCtrl = TextEditingController(text: '${record?.rentAmount ?? 0}'.replaceAll('.0', ''));
    _paidCtrl = TextEditingController(text: '${record?.paidAmount ?? 0}'.replaceAll('.0', ''));
    _balanceCtrl = TextEditingController(text: '${record?.balanceAmount ?? 0}'.replaceAll('.0', ''));
    _powerCtrl = TextEditingController(text: '${record?.powerBill ?? 0}'.replaceAll('.0', ''));
    _waterCtrl = TextEditingController(text: '${record?.waterBill ?? 0}'.replaceAll('.0', ''));
    _remarksCtrl = TextEditingController(text: record?.remarks == '-' ? '' : (record?.remarks ?? ''));
    _side = record?.side ?? _side;
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _rentCtrl.dispose();
    _paidCtrl.dispose();
    _balanceCtrl.dispose();
    _powerCtrl.dispose();
    _waterCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  double _num(TextEditingController c) => double.tryParse(c.text.trim()) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'action': _isEdit ? 'update' : 'create',
      'originalDate': widget.editRecord?.date,
      'originalSide': widget.editRecord?.side,
      'date': _dateCtrl.text.trim(),
      'side': _side,
      'rentAmount': _num(_rentCtrl),
      'paidAmount': _num(_paidCtrl),
      'balanceAmount': _num(_balanceCtrl),
      'powerBill': _num(_powerCtrl),
      'waterBill': _num(_waterCtrl),
      'remarks': _remarksCtrl.text.trim().isEmpty ? '-' : _remarksCtrl.text.trim(),
    };

    try {
      await ApiService.saveRentPayload(payload);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save record')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Rent Entry' : 'New Rent Entry'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _side,
              decoration: const InputDecoration(labelText: 'Side'),
              items: const [
                DropdownMenuItem(value: 'Kalyan', child: Text('Kalyan')),
                DropdownMenuItem(value: 'Srikanth', child: Text('Srikanth')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _side = value);
              },
            ),
            const SizedBox(height: 12),
            _input('Date (dd/MMM/yyyy)', _dateCtrl),
            const SizedBox(height: 12),
            _input('Rent Amount', _rentCtrl, numeric: true),
            const SizedBox(height: 12),
            _input('Paid Amount', _paidCtrl, numeric: true),
            const SizedBox(height: 12),
            _input('Balance Amount', _balanceCtrl, numeric: true),
            const SizedBox(height: 12),
            _input('Power Bill', _powerCtrl, numeric: true),
            const SizedBox(height: 12),
            _input('Water Bill', _waterCtrl, numeric: true),
            const SizedBox(height: 12),
            _input('Remarks', _remarksCtrl, maxLines: 3),
            const SizedBox(height: 20),
            FilledButton.icon(
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
          ],
        ),
      ),
    );
  }

  Widget _input(
    String label,
    TextEditingController controller, {
    bool numeric = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if ((value ?? '').trim().isEmpty && maxLines == 1) {
          return 'Required';
        }
        return null;
      },
    );
  }
}
