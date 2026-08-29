import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      _selectedDate = DateTime.now();
    }

    _amountController.addListener(() {
      _updateAmountInWords(_amountController.text);
    });
  }

  DateTime _parseDate(String dateStr) {
    try {
      return DateFormat('dd/MMM/yyyy').parse(dateStr);
    } catch (e) {
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return DateTime.now();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final loan = LoanRecord(
      id: widget.editRecord?.id,
      date: DateFormat('dd/MMM/yyyy').format(_selectedDate),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.editRecord != null ? 'Loan updated successfully!' : 'Loan saved successfully!')),
      );
      if (widget.editRecord != null) {
        Navigator.pop(context, true);
      } else {
        _formKey.currentState!.reset();
        setState(() {
          _selectedDate = DateTime.now();
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
                      horizontal: isDesktop ? MediaQuery.of(context).size.width * 0.1 : 16,
                      vertical: 20,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildMainCard(isDesktop),
                          const SizedBox(height: 20),
                          _buildActions(isDesktop),
                          const SizedBox(height: 100),
                        ],
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
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 12),
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
          _buildTopIcon(Icons.pie_chart_outline, onTap: () => Navigator.pushNamed(context, '/report/loan')),
          const SizedBox(width: 8),
          _buildTopIcon(Icons.home_outlined, onTap: () => Navigator.popUntil(context, (route) => route.isFirst)),
        ],
      ),
    );
  }

  Widget _buildTopIcon(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
      ),
    );
  }

  Widget _buildMainCard(bool isDesktop) {
    return Container(
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
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [ktPrimary, Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.payments, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.editRecord != null ? 'Edit Loan Transaction' : 'New Loan Entry',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter all loan related details to keep your records organized',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildInputGrid(isDesktop),
        ],
      ),
    );
  }

  Widget _buildInputGrid(bool isDesktop) {
    return Column(
      children: [
        if (isDesktop) ...[
          Row(
            children: [
              Expanded(child: _buildDatePicker()),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField('Name', _nameController, Icons.person, hint: 'Who is involved?')),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildAmountField()),
              const SizedBox(width: 20),
              Expanded(child: _buildTextField('Interest Rate (%)', _interestRateController, Icons.percent, hint: '5.5', keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildTenureField()),
              const SizedBox(width: 20),
              Expanded(child: _buildDropdownField('Transaction Type', _type, ['Given', 'Taken'], Icons.swap_horiz, (val) => setState(() => _type = val!))),
            ],
          ),
        ] else ...[
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
          _buildDropdownField('Transaction Type', _type, ['Given', 'Taken'], Icons.swap_horiz, (val) => setState(() => _type = val!)),
        ],
        const SizedBox(height: 16),
        _buildDropdownField('Status', _status, ['Active', 'Closed', 'Defaulted'], Icons.info_outline, (val) => setState(() => _status = val!)),
        const SizedBox(height: 16),
        _buildTextField('Remarks (Optional)', _remarksController, Icons.notes, hint: 'Any additional notes...', maxLines: 3),
      ],
    );
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
            DateFormat('dd/MMM/yyyy').format(_selectedDate),
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
