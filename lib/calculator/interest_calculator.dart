import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core_constants.dart';

class InterestCalculator extends StatefulWidget {
  const InterestCalculator({super.key});

  @override
  State<InterestCalculator> createState() => _InterestCalculatorState();
}

class _InterestCalculatorState extends State<InterestCalculator> {
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _yearsController = TextEditingController();
  final _monthsController = TextEditingController();
  final _gstController = TextEditingController(text: '18');

  String _mode = 'flat';
  Map<String, dynamic>? _result;

  void _calculate() {
    double P = double.tryParse(_principalController.text) ?? 0;
    double R = double.tryParse(_rateController.text) ?? 0;
    double G = double.tryParse(_gstController.text) ?? 0;
    double y = double.tryParse(_yearsController.text) ?? 0;
    double m = double.tryParse(_monthsController.text) ?? 0;

    if (P <= 0 || R <= 0 || (y <= 0 && m <= 0)) return;

    double totalMonths = y > 0 ? y * 12 : m;
    double T = totalMonths / 12;

    setState(() {
      if (_mode == 'flat') {
        double interest = (P * R * T) / 100;
        double totalGst = (interest * G) / 100;
        _result = {
          'interest': interest,
          'gst': totalGst,
          'total': P + interest + totalGst,
          'emi': (P + interest + totalGst) / totalMonths,
        };
      } else {
        double r = R / (12 * 100);
        double emi = (P * r * math.pow(1 + r, totalMonths)) / (math.pow(1 + r, totalMonths) - 1);
        double totalPaid = emi * totalMonths;
        double interest = totalPaid - P;
        double totalGst = (interest * G) / 100;
        _result = {
          'interest': interest,
          'gst': totalGst,
          'total': P + interest + totalGst,
          'emi': emi,
        };
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ktBgDark,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Interest Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTabs(),
            const SizedBox(height: 24),
            _buildInputs(),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: ktSecondary, foregroundColor: ktTextWhite, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Calculate', style: TextStyle(fontWeight: FontWeight.bold)))),
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: ktBorderWhite5, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: _TabBtn(label: 'Flat Rate', isActive: _mode == 'flat', onTap: () => setState(() { _mode = 'flat'; _result = null; }))),
        Expanded(child: _TabBtn(label: 'Reducing', isActive: _mode == 'float', onTap: () => setState(() { _mode = 'float'; _result = null; }))),
      ]),
    );
  }

  Widget _buildInputs() {
    return Column(children: [
      _Input(label: 'Principal Amount', controller: _principalController),
      const SizedBox(height: 16),
      _Input(label: 'Interest Rate % p.a.', controller: _rateController),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: _Input(label: 'Tenure (Years)', controller: _yearsController, onChanged: (v) => _monthsController.clear())),
        const SizedBox(width: 12),
        Expanded(child: _Input(label: 'Tenure (Months)', controller: _monthsController, onChanged: (v) => _yearsController.clear())),
      ]),
      const SizedBox(height: 16),
      _Input(label: 'GST on Interest %', controller: _gstController),
    ]);
  }

  Widget _buildResults() {
    final f = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 2);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ktCardBg,
        border: Border.all(color: ktSecondary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
        _ResRow(label: 'Total Interest', value: f.format(_result!['interest']), color: ktOrange),
        _ResRow(label: 'GST on Interest', value: f.format(_result!['gst'])),
        const Divider(color: ktBorderWhite10, height: 32),
        _ResRow(label: 'Total Amount', value: f.format(_result!['total']), isBold: true, color: ktEmerald),
        _ResRow(label: 'Monthly EMI', value: f.format(_result!['emi']), color: ktCyan),
      ]),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label; final bool isActive; final VoidCallback onTap;
  const _TabBtn({required this.label, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: isActive ? ktSecondary : Colors.transparent, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(label, style: TextStyle(color: isActive ? ktTextWhite : Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)))));
  }
}

class _Input extends StatelessWidget {
  final String label; final TextEditingController controller; final ValueChanged<String>? onChanged;
  const _Input({required this.label, required this.controller, this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      TextField(controller: controller, onChanged: onChanged, keyboardType: TextInputType.number, style: const TextStyle(color: ktTextWhite), decoration: InputDecoration(filled: true, fillColor: ktBorderWhite5, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
    ]);
  }
}

class _ResRow extends StatelessWidget {
  final String label, value; final bool isBold; final Color? color;
  const _ResRow({required this.label, required this.value, this.isBold = false, this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
      Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: isBold ? 20 : 15, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold)),
    ]));
  }
}
