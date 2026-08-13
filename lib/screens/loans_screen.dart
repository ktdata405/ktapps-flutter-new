import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/loan_record.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────
// Loans Entry Screen  (converted from loan.html)
// ─────────────────────────────────────────────────────────────
class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key, this.editRecord});
  final LoanRecord? editRecord;

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _interestCtrl;
  late final TextEditingController _tenureCtrl;
  late final TextEditingController _remarksCtrl;

  DateTime _date = DateTime.now();
  String _tenureType = 'Months';
  String _type = 'Given';
  String _status = 'Active';
  String _amountWords = '';
  bool _saving = false;

  bool get _isEdit => widget.editRecord != null;

  @override
  void initState() {
    super.initState();
    final r = widget.editRecord;

    _nameCtrl = TextEditingController(text: r?.name ?? '');
    _amountCtrl = TextEditingController(
      text: r != null ? r.amount.toStringAsFixed(0) : '',
    );
    _interestCtrl = TextEditingController(
      text: r != null ? r.interestRate.toString() : '',
    );
    _tenureCtrl = TextEditingController(
      text: r != null ? r.tenureValue.toString() : '',
    );
    _remarksCtrl = TextEditingController(text: r?.remarks ?? '');

    if (r != null) {
      _date = _parseDate(r.date);
      _tenureType = r.tenureType;
      _type = r.type;
      _status = r.status;
    }

    _amountCtrl.addListener(_updateAmountWords);
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_updateAmountWords);
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _interestCtrl.dispose();
    _tenureCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  DateTime _parseDate(String s) {
    try {
      return DateFormat('dd/MMM/yyyy').parse(s);
    } catch (_) {
      return DateTime.now();
    }
  }

  String _fmtDate(DateTime d) => DateFormat('dd/MMM/yyyy').format(d);

  void _updateAmountWords() {
    final raw = _amountCtrl.text.replaceAll(',', '').trim();
    final n = int.tryParse(raw) ?? 0;
    if (n == 0) {
      if (mounted) setState(() => _amountWords = '');
      return;
    }
    final words = _numToWords(n);
    if (mounted) setState(() => _amountWords = '$words Rupees Only');
  }

  String _numToWords(int n) {
    if (n == 0) return 'Zero';
    const u = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight',
      'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen',
      'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'
    ];
    const t = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty',
      'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String conv(int x) {
      if (x < 20) return u[x];
      if (x < 100) return '${t[x ~/ 10]}${x % 10 != 0 ? ' ${u[x % 10]}' : ''}';
      if (x < 1000) {
        return '${u[x ~/ 100]} Hundred${x % 100 != 0 ? ' and ${conv(x % 100)}' : ''}';
      }
      if (x < 100000) {
        return '${conv(x ~/ 1000)} Thousand${x % 1000 != 0 ? ' ${conv(x % 1000)}' : ''}';
      }
      if (x < 10000000) {
        return '${conv(x ~/ 100000)} Lakh${x % 100000 != 0 ? ' ${conv(x % 100000)}' : ''}';
      }
      return '${conv(x ~/ 10000000)} Crore${x % 10000000 != 0 ? ' ${conv(x % 10000000)}' : ''}';
    }

    return conv(n);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'action': _isEdit ? 'updateLoan' : 'addLoan',
      if (_isEdit) 'id': widget.editRecord!.id,
      'date': _fmtDate(_date),
      'name': _nameCtrl.text.trim(),
      'amount':
          double.tryParse(_amountCtrl.text.replaceAll(',', '').trim()) ?? 0,
      'interestRate':
          double.tryParse(_interestCtrl.text.trim()) ?? 0,
      'tenure': '${_tenureCtrl.text.trim()} $_tenureType',
      'type': _type,
      'status': _status,
      'remarks': _remarksCtrl.text.trim(),
    };

    try {
      await ApiService.saveLoan(payload);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save loan')),
      );
      setState(() => _saving = false);
    }
  }

  void _clear() {
    setState(() {
      _date = DateTime.now();
      _type = 'Given';
      _status = 'Active';
      _tenureType = 'Months';
      _amountWords = '';
    });
    _nameCtrl.clear();
    _amountCtrl.clear();
    _interestCtrl.clear();
    _tenureCtrl.clear();
    _remarksCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(children: [
        // Background gradient orbs
        Positioned(
          left: -80, top: -80,
          child: _orb(360, const Color(0x266C63FF)),
        ),
        Positioned(
          right: -60, bottom: -60,
          child: _orb(300, const Color(0x26EC4899)),
        ),
        SafeArea(
          child: Column(children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date + Name
                          _twoColRow([
                            _dateField(),
                            _input('Name', _nameCtrl,
                                icon: Icons.person_rounded,
                                hint: 'Who is involved?'),
                          ]),
                          const SizedBox(height: 16),

                          // Amount
                          _input('Amount', _amountCtrl,
                              icon: Icons.currency_rupee_rounded,
                              hint: '0.00',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true)),
                          if (_amountWords.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(_amountWords,
                                style: const TextStyle(
                                    color: Color(0xFF00D2FC),
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic)),
                          ],
                          const SizedBox(height: 16),

                          // Interest Rate
                          _twoColRow([
                            _input('Interest Rate (%)', _interestCtrl,
                                icon: Icons.percent_rounded,
                                hint: '5.5',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true)),
                            // Tenure
                            _tenureRow(),
                          ]),
                          const SizedBox(height: 16),

                          // Type + Status
                          _twoColRow([
                            _dropdown<String>(
                              label: 'Transaction Type',
                              icon: Icons.swap_horiz_rounded,
                              value: _type,
                              items: const ['Given', 'Taken'],
                              onChanged: (v) =>
                                  setState(() => _type = v ?? _type),
                            ),
                            _dropdown<String>(
                              label: 'Status',
                              icon: Icons.info_outline_rounded,
                              value: _status,
                              items: const [
                                'Active', 'Closed', 'Defaulted'
                              ],
                              onChanged: (v) =>
                                  setState(() => _status = v ?? _status),
                            ),
                          ]),
                          const SizedBox(height: 16),

                          // Remarks
                          _input('Remarks (Optional)', _remarksCtrl,
                              icon: Icons.notes_rounded,
                              maxLines: 3,
                              required: false),
                          const SizedBox(height: 24),

                          // Buttons
                          Row(children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _saving ? null : _clear,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white70,
                                  side: const BorderSide(color: Colors.white24),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.cleaning_services_rounded, size: 16),
                                label: const Text('Clear'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: _saving
                                    ? const SizedBox(
                                        width: 14, height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.save_rounded, size: 16),
                                label: Text(_saving
                                    ? (_isEdit ? 'Updating...' : 'Saving...')
                                    : (_isEdit
                                        ? 'Update Transaction'
                                        : 'Save Transaction')),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildHeader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x990B0F19),
          border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF9333EA)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.savings_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEdit ? 'Edit Loan Entry' : 'New Loan Entry',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          _hBtn(Icons.home_rounded, 'Home',
              () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ]),
      );

  Widget _hBtn(IconData icon, String tip, VoidCallback onTap) => Tooltip(
        message: tip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, size: 17, color: Colors.white70),
          ),
        ),
      );

  Widget _twoColRow(List<Widget> children) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: children[0]),
          if (children.length > 1) ...[
            const SizedBox(width: 12),
            Expanded(child: children[1]),
          ],
        ],
      );

  Widget _dateField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Date',
              style: TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: Colors.white54),
                const SizedBox(width: 8),
                Text(
                  _fmtDate(_date),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ]),
            ),
          ),
        ],
      );

  Widget _tenureRow() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tenure',
              style: TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: _tenureCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Duration',
                  hintStyle: const TextStyle(color: Colors.white30),
                  prefixIcon: const Icon(Icons.schedule_rounded,
                      color: Colors.white38, size: 18),
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Required' : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _tenureType,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(value: 'Months', child: Text('Months')),
                  DropdownMenuItem(value: 'Years', child: Text('Years')),
                ],
                onChanged: (v) =>
                    setState(() => _tenureType = v ?? _tenureType),
              ),
            ),
          ]),
        ],
      );

  Widget _input(
    String label,
    TextEditingController ctrl, {
    IconData? icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool required = true,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white30),
              prefixIcon: icon == null
                  ? null
                  : Icon(icon, color: Colors.white38, size: 18),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF6C63FF)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            validator: (v) {
              if (!required) return null;
              if ((v ?? '').trim().isEmpty) return 'Required';
              return null;
            },
          ),
        ],
      );

  Widget _dropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xE6FFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            value: value,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: Colors.white38, size: 18),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: items
                .map((e) => DropdownMenuItem<T>(
                    value: e, child: Text('$e')))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      );

  Widget _orb(double size, Color color) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withValues(alpha: 0.5),
            Colors.transparent,
          ]),
        ),
      );
}

