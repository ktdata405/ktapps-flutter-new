import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core_constants.dart';

class LAMFCalculator extends StatefulWidget {
  const LAMFCalculator({super.key});

  @override
  State<LAMFCalculator> createState() => _LAMFCalculatorState();
}

class _LAMFCalculatorState extends State<LAMFCalculator> {
  final _portfolioController = TextEditingController();
  final _ltvController = TextEditingController(text: '45');
  final _rateController = TextEditingController(text: '10.5');
  String _fundType = '45';

  Map<String, dynamic>? _result;

  void _calculate() {
    double portfolioValue = double.tryParse(_portfolioController.text.replaceAll(',', '')) ?? 0;
    double ltv = double.tryParse(_ltvController.text) ?? 0;
    double annualRate = double.tryParse(_rateController.text) ?? 0;

    if (portfolioValue <= 0) return;

    setState(() {
      double loanLimit = portfolioValue * (ltv / 100);
      double yearlyInterest = (loanLimit * annualRate) / 100;
      _result = {
        'limit': loanLimit,
        'daily': yearlyInterest / 365,
        'monthly': yearlyInterest / 12,
        'yearly': yearlyInterest,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ktBgDark,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('LAMF Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInputs(),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: ktOrange, foregroundColor: ktTextWhite, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Calculate', style: TextStyle(fontWeight: FontWeight.bold)))),
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResults(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputs() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(24), border: Border.all(color: ktBorderWhite5)),
      child: Column(children: [
        _Input(label: 'Portfolio Value (₹)', controller: _portfolioController),
        const SizedBox(height: 16),
        _Dropdown(label: 'Fund Type', value: _fundType, options: const {'45': 'Equity (Max 45% LTV)', '80': 'Debt (Max 80% LTV)', '50': 'Hybrid (Max 50% LTV)'}, onChanged: (v) => setState(() { _fundType = v!; _ltvController.text = v; })),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _Input(label: 'LTV Ratio %', controller: _ltvController)),
          const SizedBox(width: 12),
          Expanded(child: _Input(label: 'Interest Rate %', controller: _rateController)),
        ]),
      ]),
    );
  }

  Widget _buildResults() {
    final f = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: ktCardBg, borderRadius: BorderRadius.circular(24), border: Border.all(color: ktOrange.withValues(alpha: 0.2))),
      child: Column(children: [
        _ResRow(label: 'Eligible Loan Limit', value: f.format(_result!['limit']), isBold: true, color: ktOrange),
        const Divider(color: ktBorderWhite10, height: 32),
        _ResRow(label: 'Daily Interest', value: f.format(_result!['daily'])),
        _ResRow(label: 'Monthly Interest', value: f.format(_result!['monthly'])),
        _ResRow(label: 'Yearly Interest', value: f.format(_result!['yearly'])),
      ]),
    );
  }
}

class _Input extends StatelessWidget {
  final String label; final TextEditingController controller;
  const _Input({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      TextField(controller: controller, keyboardType: TextInputType.number, style: const TextStyle(color: ktTextWhite), decoration: InputDecoration(filled: true, fillColor: const Color(0x33000000), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
    ]);
  }
}

class _Dropdown extends StatelessWidget {
  final String label, value; final Map<String, String> options; final ValueChanged<String?> onChanged;
  const _Dropdown({required this.label, required this.value, required this.options, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      Container(padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: const Color(0x33000000), borderRadius: BorderRadius.circular(12)), child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, dropdownColor: const Color(0xFF1E293B), style: const TextStyle(color: ktTextWhite), items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(), onChanged: onChanged))),
    ]);
  }
}

class _ResRow extends StatelessWidget {
  final String label, value; final bool isBold; final Color? color;
  const _ResRow({required this.label, required this.value, this.isBold = false, this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 13)),
      Text(value, style: TextStyle(color: color ?? Colors.white, fontSize: isBold ? 18 : 14, fontWeight: isBold ? FontWeight.w900 : FontWeight.bold)),
    ]));
  }
}
