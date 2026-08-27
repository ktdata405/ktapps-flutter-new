import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GovtSchemesCalculator extends StatefulWidget {
  const GovtSchemesCalculator({super.key});

  @override
  State<GovtSchemesCalculator> createState() => _GovtSchemesCalculatorState();
}

class _GovtSchemesCalculatorState extends State<GovtSchemesCalculator> {
  String _selectedTab = 'ssa';
  final _investmentController = TextEditingController();
  final _ageController = TextEditingController();
  final _returnController = TextEditingController();
  final _startYearController = TextEditingController(text: DateTime.now().year.toString());

  Map<String, dynamic>? _result;

  void _calculate() {
    final investment = double.tryParse(_investmentController.text) ?? 0;
    if (investment <= 0) return;

    setState(() {
      switch (_selectedTab) {
        case 'ssa':
          _calculateSSA(investment); break;
        case 'ppf':
          _calculatePPF(investment); break;
        case 'nps':
          _calculateNPS(investment); break;
        case 'nsc':
          _calculateNSC(investment); break;
        case 'kvp':
          _calculateKVP(investment); break;
        case 'scss':
          _calculateSCSS(investment); break;
        case 'pomis':
          _calculatePOMIS(investment); break;
        case 'mssc':
          _calculateMSSC(investment); break;
      }
    });
  }

  void _calculateSSA(double invest) {
    const rate = 8.2;
    int startYear = int.tryParse(_startYearController.text) ?? DateTime.now().year;
    double totalInvest = 0, balance = 0;
    for (int i = 0; i < 21; i++) {
      if (i < 15) { balance += invest; totalInvest += invest; }
      balance += (balance * rate) / 100;
    }
    _result = {'totalInvest': totalInvest, 'interest': balance - totalInvest, 'maturity': balance, 'year': startYear + 21};
  }

  void _calculatePPF(double invest) {
    const rate = 7.1, duration = 15;
    double balance = 0;
    for (int i = 0; i < duration; i++) { balance += invest; balance += (balance * rate) / 100; }
    _result = {'totalInvest': invest * duration, 'interest': balance - (invest * duration), 'maturity': balance};
  }

  void _calculateNPS(double monthly) {
    int age = int.tryParse(_ageController.text) ?? 30;
    double rate = double.tryParse(_returnController.text) ?? 10;
    int months = (60 - age) * 12;
    double r = rate / 12 / 100;
    double maturity = monthly * ((math.pow(1 + r, months) - 1) / r) * (1 + r);
    _result = {'totalInvest': monthly * months, 'interest': maturity - (monthly * months), 'maturity': maturity};
  }

  void _calculateNSC(double invest) {
    const rate = 7.7, years = 5;
    double maturity = invest * math.pow(1 + rate / 100, years);
    _result = {'totalInvest': invest, 'interest': maturity - invest, 'maturity': maturity};
  }

  void _calculateKVP(double invest) {
    _result = {'totalInvest': invest, 'interest': invest, 'maturity': invest * 2, 'tenure': '115 Months'};
  }

  void _calculateSCSS(double invest) {
    const rate = 8.2, years = 5;
    double quarterly = (invest * rate / 100) / 4;
    _result = {'totalInvest': invest, 'interest': quarterly * 4 * years, 'maturity': invest, 'quarterly': quarterly};
  }

  void _calculatePOMIS(double invest) {
    const rate = 7.4;
    double monthly = (invest * rate / 100) / 12;
    _result = {'totalInvest': invest, 'interest': monthly * 60, 'maturity': invest, 'monthly': monthly};
  }

  void _calculateMSSC(double invest) {
    const rate = 7.5, years = 2;
    double maturity = invest * math.pow(1 + (rate / 4) / 100, years * 4);
    _result = {'totalInvest': invest, 'interest': maturity - invest, 'maturity': maturity};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030305),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Govt Schemes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTabs(),
            const SizedBox(height: 24),
            _buildInputs(),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBBF24), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Calculate', style: TextStyle(fontWeight: FontWeight.bold)))),
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
    final tabs = ['ssa', 'ppf', 'nps', 'nsc', 'kvp', 'scss', 'pomis', 'mssc'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: tabs.map((t) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(t.toUpperCase(), style: TextStyle(color: _selectedTab == t ? Colors.black : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          selected: _selectedTab == t,
          onSelected: (v) { if(v) setState(() { _selectedTab = t; _result = null; _investmentController.clear(); }); },
          selectedColor: const Color(0xFFFBBF24),
          backgroundColor: Colors.white.withValues(alpha: 0.05),
        ),
      )).toList()),
    );
  }

  Widget _buildInputs() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(
        children: [
          _InputField(label: _selectedTab == 'nps' || _selectedTab == 'pomis' ? 'Monthly Investment' : 'Investment Amount', controller: _investmentController),
          if (_selectedTab == 'ssa') ...[const SizedBox(height: 16), _InputField(label: "Girl's Age", controller: _ageController), const SizedBox(height: 16), _InputField(label: "Start Year", controller: _startYearController)],
          if (_selectedTab == 'nps') ...[const SizedBox(height: 16), _InputField(label: "Current Age", controller: _ageController), const SizedBox(height: 16), _InputField(label: "Expected Return %", controller: _returnController)],
        ],
      ),
    );
  }

  Widget _buildResults() {
    final f = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF151A25), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.2))),
      child: Column(
        children: [
          _ResRow(label: 'Total Investment', value: f.format(_result!['totalInvest'])),
          _ResRow(label: 'Total Interest', value: f.format(_result!['interest'])),
          const Divider(color: Colors.white10, height: 32),
          _ResRow(label: 'Maturity Amount', value: f.format(_result!['maturity']), isBold: true, color: const Color(0xFFFBBF24)),
          if (_result!['year'] != null) _ResRow(label: 'Maturity Year', value: _result!['year'].toString()),
          if (_result!['monthly'] != null) _ResRow(label: 'Monthly Payout', value: f.format(_result!['monthly']), color: Colors.tealAccent),
          if (_result!['quarterly'] != null) _ResRow(label: 'Quarterly Payout', value: f.format(_result!['quarterly']), color: Colors.tealAccent),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label; final TextEditingController controller;
  const _InputField({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextField(controller: controller, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: InputDecoration(filled: true, fillColor: const Color(0x33000000), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
    ]);
  }
}

class _ResRow extends StatelessWidget {
  final String label, value; final bool isBold; final Color? color;
  const _ResRow({required this.label, required this.value, this.isBold = false, this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
        Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: isBold ? 20 : 15, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold)),
      ]),
    );
  }
}
