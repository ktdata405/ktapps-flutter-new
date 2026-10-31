import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core_utils.dart';
import '../core_ui_utils.dart';
import 'package:ktppsflutter/core_constants.dart';
import 'loan_models.dart';
import 'loan_service.dart';

class LoanScreen extends StatefulWidget {
  final LoanRecord? editRecord;
  const LoanScreen({super.key, this.editRecord});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  final LoanService _service = LoanService();
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _tenureController = TextEditingController();
  String _tenureType = 'Months';
  String _type = 'Given';
  String _status = 'Active';
  final TextEditingController _remarksController = TextEditingController();

  String _amountInWords = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editRecord != null) {
      final r = widget.editRecord!;
      _selectedDate = _parseDate(r.date);
      _nameController.text = r.name;
      _amountController.text = r.amount.toString();
      _interestRateController.text = r.interestRate.toString();
      final tenureParts = r.tenure.split(' ');
      if (tenureParts.length == 2) {
        _tenureController.text = tenureParts[0];
        _tenureType = tenureParts[1];
      }
      _type = r.type;
      _status = r.status;
      _remarksController.text = r.remarks;
      _updateAmountInWords(r.amount.toString());
    } else {
      _selectedDate = getIndiaTime();
    }

    _amountController.addListener(() => setState(() {
      _updateAmountInWords(_amountController.text);
    }));
    _interestRateController.addListener(() => setState(() {}));
    _tenureController.addListener(() => setState(() {}));
  }

  DateTime _parseDate(String dateStr) {
    try {
      return DateFormat('dd/MMM/yyyy').parse(dateStr);
    } catch (e) {
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return getIndiaTime();
      }
    }
  }

  void _updateAmountInWords(String value) {
    final cleanValue = value.replaceAll(',', '');
    final numVal = double.tryParse(cleanValue);
    if (numVal != null) {
      setState(() {
        _amountInWords = '${_numberToText(numVal.toInt())} Rupees Only';
      });
    } else {
      setState(() {
        _amountInWords = '';
      });
    }
  }

  String _numberToText(int n) {
    if (n < 0) return "Minus ${_numberToText(-n)}";
    if (n == 0) return "Zero";

    const units = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
    const tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];

    String convert(int num) {
      if (num < 20) return units[num];
      if (num < 100) return tens[num ~/ 10] + (num % 10 != 0 ? " ${units[num % 10]}" : "");
      if (num < 1000) return "${units[num ~/ 100]} Hundred${num % 100 != 0 ? " and ${convert(num % 100)}" : ""}";
      if (num < 100000) return "${convert(num ~/ 1000)} Thousand${num % 1000 != 0 ? " ${convert(num % 1000)}" : ""}";
      if (num < 10000000) return "${convert(num ~/ 100000)} Lakh${num % 100000 != 0 ? " ${convert(num % 100000)}" : ""}";
      return "${convert(num ~/ 10000000)} Crore${num % 10000000 != 0 ? " ${convert(num % 10000000)}" : ""}";
    }

    return convert(n);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: ktPrimary,
            onPrimary: Colors.white,
            surface: Color(0xFF1E293B),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  double _getCalculatedAmount() {
    return double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
  }

  double _getCalculatedInterestRate() {
    return double.tryParse(_interestRateController.text) ?? 0.0;
  }

  int _getCalculatedTenureMonths() {
    final t = int.tryParse(_tenureController.text) ?? 0;
    if (_tenureType == 'Years') return t * 12;
    return t;
  }

  double _getCalculatedTotalInterest() {
    final amount = _getCalculatedAmount();
    final rate = _getCalculatedInterestRate();
    final months = _getCalculatedTenureMonths();
    return (amount * rate * months) / 1200;
  }

  double _getCalculatedGstOnInterest() {
    return _getCalculatedTotalInterest() * 0.18;
  }

  double _getCalculatedTotalPayable() {
    final amount = _getCalculatedAmount();
    final interest = _getCalculatedTotalInterest();
    final gst = _getCalculatedGstOnInterest();
    return amount + interest + gst;
  }

  double _getCalculatedMonthlyEmi() {
    final months = _getCalculatedTenureMonths();
    final payable = _getCalculatedTotalPayable();
    return months > 0 ? payable / months : 0.0;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final loan = LoanRecord(
      id: widget.editRecord?.id,
      date: ktFormatDateForSheet(_selectedDate),
      name: _nameController.text,
      amount: double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0,
      interestRate: double.tryParse(_interestRateController.text) ?? 0.0,
      tenure: '${_tenureController.text} $_tenureType',
      type: _type,
      status: _status,
      remarks: _remarksController.text,
    );

    bool success;
    if (widget.editRecord != null) {
      success = await _service.updateLoan(loan);
    } else {
      success = await _service.addLoan(loan);
    }

    setState(() => _loading = false);
    if (success) {
      if (!mounted) return;
      ktShowCustomToast(
        context,
        widget.editRecord != null ? 'Loan updated successfully!' : 'Loan saved successfully!',
      );
      if (widget.editRecord != null) {
        Navigator.pop(context, true);
      } else {
        _formKey.currentState!.reset();
        setState(() {
          _selectedDate = getIndiaTime();
          _nameController.clear();
          _amountController.clear();
          _interestRateController.clear();
          _tenureController.clear();
          _remarksController.clear();
          _amountInWords = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF030305),
      body: Stack(
        children: [
          const _GridBackground(),
          _buildBackgroundOrbs(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 24 : 16,
                      vertical: 20,
                    ),
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(maxWidth: isDesktop ? 760 : double.infinity),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildMainCard(isDesktop),
                              const SizedBox(height: 24),
                              _buildActions(isDesktop),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_loading) _buildLoader(),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Loan Entry',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Track Lending & Borrowing',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          ktHeaderIcon(Icons.bar_chart_rounded, () => Navigator.pushReplacementNamed(context, '/report/loan')),
          const SizedBox(width: 8),
          ktHeaderIcon(Icons.home, () => Navigator.pushNamed(context, '/')),
        ],
      ),
    );
  }


  Widget _buildMainCard(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLiveCalculationCard(isDesktop),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0x990F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildInputGrid(isDesktop),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveCalculationCard(bool isDesktop) {
    final amount = _getCalculatedAmount();
    final interest = _getCalculatedTotalInterest();
    final gst = _getCalculatedGstOnInterest();
    final payable = _getCalculatedTotalPayable();
    final months = _getCalculatedTenureMonths();
    final emi = _getCalculatedMonthlyEmi();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ktPrimary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'LOAN EMI + 18% GST',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Icon(Icons.analytics_rounded, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'ESTIMATED MONTHLY PAYMENT',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '₹${NumberFormat('#,##,###').format(emi)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '/ month${months > 0 ? ' x $months M' : ''}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Total Interest',
                  '₹${NumberFormat('#,##,###').format(interest)}',
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildMetricItem(
                    'Govt. GST (18%)',
                    '₹${NumberFormat('#,##,###').format(gst)}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Principal Amount',
                  '₹${NumberFormat('#,##,###').format(amount)}',
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildMetricItem(
                    'Final Payable (Incl. GST)',
                    '₹${NumberFormat('#,##,###').format(payable)}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildTypeToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TRANSACTION TYPE', style: TextStyle(color: ktTextGray400, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _type = 'Given'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: _type == 'Given' ? ktEmerald.withValues(alpha: 0.1) : const Color(0x1F000000),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _type == 'Given' ? ktEmerald : Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.trending_up, color: _type == 'Given' ? ktEmerald : Colors.white38, size: 18),
                      const SizedBox(width: 8),
                      Text('Given', style: TextStyle(color: _type == 'Given' ? ktEmerald : Colors.white38, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _type = 'Taken'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: _type == 'Taken' ? ktRose.withValues(alpha: 0.1) : const Color(0x1F000000),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _type == 'Taken' ? ktRose : Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.trending_down, color: _type == 'Taken' ? ktRose : Colors.white38, size: 18),
                      const SizedBox(width: 8),
                      Text('Taken', style: TextStyle(color: _type == 'Taken' ? ktRose : Colors.white38, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputGrid(bool isDesktop) {
    if (isDesktop) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDatePicker()),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField('Name', _nameController, Icons.person, hint: 'Who is involved?')),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAmountField()),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField('Interest Rate (%)', _interestRateController, Icons.percent, hint: '5.5', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTenureField()),
              const SizedBox(width: 20),
              Expanded(child: _buildTypeToggle()),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildDropdownField('Status', _status, ['Active', 'Closed', 'Defaulted'], Icons.info_outline, (val) => setState(() => _status = val!))),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField('Remarks (Optional)', _remarksController, Icons.notes, hint: 'Any additional notes...', maxLines: 3)),
            ],
          ),
        ],
      );
    } else {
      return Column(
        children: [
          _buildDatePicker(),
          const SizedBox(height: 16),
          _buildTextField('Name', _nameController, Icons.person, hint: 'Who is involved?'),
          const SizedBox(height: 16),
          _buildAmountField(),
          const SizedBox(height: 16),
          _buildTextField('Interest Rate (%)', _interestRateController, Icons.percent, hint: '5.5', keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildTenureField(),
          const SizedBox(height: 16),
          _buildTypeToggle(),
          const SizedBox(height: 16),
          _buildDropdownField('Status', _status, ['Active', 'Closed', 'Defaulted'], Icons.info_outline, (val) => setState(() => _status = val!)),
          const SizedBox(height: 16),
          _buildTextField('Remarks (Optional)', _remarksController, Icons.notes, hint: 'Any additional notes...', maxLines: 3),
        ],
      );
    }
  }


  Widget _buildDatePicker() {
    return _InputWrapper(
      label: 'DATE',
      icon: Icons.calendar_today,
      child: InkWell(
        onTap: () => _selectDate(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            ktFormatDate(_selectedDate),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {String? hint, TextInputType? keyboardType, int maxLines = 1}) {
    return _InputWrapper(
      label: label.toUpperCase(),
      icon: icon,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField('Amount', _amountController, Icons.currency_rupee, hint: '0.00', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        if (_amountInWords.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(_amountInWords, style: const TextStyle(color: Color(0xFF00D2FC), fontSize: 11, fontStyle: FontStyle.italic)),
          ),
      ],
    );
  }

  Widget _buildTenureField() {
    return _InputWrapper(
      label: 'TENURE',
      icon: Icons.timer_outlined,
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _tenureController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Duration',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                border: InputBorder.none,
                isDense: true,
              ),
              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
            ),
          ),
          DropdownButton<String>(
            value: _tenureType,
            dropdownColor: const Color(0xFF1E293B),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            items: ['Months', 'Years'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => _tenureType = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> options, IconData icon, ValueChanged<String?> onChanged) {
    return _InputWrapper(
      label: label.toUpperCase(),
      icon: icon,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActions(bool isDesktop) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            _formKey.currentState!.reset();
            setState(() {
              _selectedDate = getIndiaTime();
              _nameController.clear();
              _amountController.clear();
              _interestRateController.clear();
              _tenureController.clear();
              _remarksController.clear();
              _amountInWords = '';
            });
          },
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.refresh_rounded, color: Colors.white60),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [ktPrimary, Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: ktPrimary.withValues(alpha: 0.3), blurRadius: 20)],
            ),
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_outlined, size: 20),
              label: Text(widget.editRecord != null ? 'Update Transaction' : 'Save Transaction', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoader() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: const Center(child: CircularProgressIndicator(color: ktPrimary)),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(top: -100, left: -100, child: _Orb(color: ktPrimary.withValues(alpha: 0.2), size: 500)),
        Positioned(bottom: -100, right: -100, child: _Orb(color: const Color(0xFF8B5CF6).withValues(alpha: 0.15), size: 500)),
      ],
    );
  }
}

class _InputWrapper extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  const _InputWrapper({required this.label, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: ktTextGray400, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.5), size: 20),
              const SizedBox(width: 12),
              Expanded(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
    );
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.infinite, painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.02)..strokeWidth = 1.0;
    const step = 40.0;
    for (double i = 0; i < size.width; i += step) { canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint); }
    for (double i = 0; i < size.height; i += step) { canvas.drawLine(Offset(0, i), Offset(size.width, i), paint); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
