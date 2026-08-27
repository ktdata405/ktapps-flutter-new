import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VillageInterestCalculator extends StatefulWidget {
  const VillageInterestCalculator({super.key});

  @override
  State<VillageInterestCalculator> createState() => _VillageInterestCalculatorState();
}

class _VillageInterestCalculatorState extends State<VillageInterestCalculator> {
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _monthsController = TextEditingController();
  DateTime? _startDate, _endDate;

  String _mode = 'months';
  Map<String, dynamic>? _result;

  void _calculate() {
    double P = double.tryParse(_principalController.text) ?? 0;
    double R = double.tryParse(_rateController.text) ?? 0;

    if (P <= 0 || R <= 0) return;

    double totalMonths = 0;
    String durationText = "";

    if (_mode == 'months') {
      totalMonths = double.tryParse(_monthsController.text) ?? 0;
      durationText = "$totalMonths Months";
    } else if (_startDate != null && _endDate != null) {
      final diff = _endDate!.difference(_startDate!);
      totalMonths = diff.inDays / 30;
      int years = (_endDate!.year - _startDate!.year);
      int months = (_endDate!.month - _startDate!.month);
      int days = (_endDate!.day - _startDate!.day);
      if (days < 0) { months--; days += 30; }
      if (months < 0) { years--; months += 12; }
      durationText = "${years > 0 ? '$years y ' : ''}${months > 0 ? '$months m ' : ''}${days > 0 ? '$days d' : ''}";
    }

    if (totalMonths <= 0) return;

    setState(() {
      double interest = (P * R * totalMonths) / 100;
      _result = {
        'duration': durationText,
        'interest': interest,
        'total': P + interest,
        'monthlyInterest': (P * R) / 100,
        'emi': (P + interest) / totalMonths,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030305),
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Village Interest')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTabs(),
            const SizedBox(height: 24),
            _buildInputs(),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC084FC), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Calculate', style: TextStyle(fontWeight: FontWeight.bold)))),
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
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: _TabBtn(label: 'Months', isActive: _mode == 'months', onTap: () => setState(() { _mode = 'months'; _result = null; }))),
        Expanded(child: _TabBtn(label: 'Dates', isActive: _mode == 'date', onTap: () => setState(() { _mode = 'date'; _result = null; }))),
      ]),
    );
  }

  Widget _buildInputs() {
    return Column(children: [
      _Input(label: 'Principal Amount', controller: _principalController),
      const SizedBox(height: 16),
      _Input(label: 'Interest Rate (per 100)', controller: _rateController, hint: 'e.g. 2 for 2% per month'),
      const SizedBox(height: 16),
      if (_mode == 'months') _Input(label: 'Duration in Months', controller: _monthsController)
      else ...[
        Row(children: [
          Expanded(child: _DateBtn(label: 'Start Date', date: _startDate, onTap: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now()); if(d!=null) setState(()=>_startDate=d); })),
          const SizedBox(width: 12),
          Expanded(child: _DateBtn(label: 'End Date', date: _endDate, onTap: () async { final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100)); if(d!=null) setState(()=>_endDate=d); })),
        ]),
      ],
    ]);
  }

  Widget _buildResults() {
    final f = NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: const Color(0xFF151A25), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFC084FC).withValues(alpha: 0.2))),
      child: Column(children: [
        _ResRow(label: 'Duration', value: _result!['duration']),
        _ResRow(label: 'Total Interest', value: f.format(_result!['interest']), color: const Color(0xFFF472B6)),
        const Divider(color: Colors.white10, height: 32),
        _ResRow(label: 'Total Amount', value: f.format(_result!['total']), isBold: true, color: const Color(0xFF4ADE80)),
        const SizedBox(height: 16),
        _ResRow(label: 'Interest Only /mo', value: f.format(_result!['monthlyInterest']), color: Colors.amberAccent),
        _ResRow(label: 'Interest + Principal (EMI)', value: f.format(_result!['emi']), color: Colors.blueAccent),
      ]),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label; final bool isActive; final VoidCallback onTap;
  const _TabBtn({required this.label, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: isActive ? const Color(0xFFC084FC) : Colors.transparent, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)))));
  }
}

class _Input extends StatelessWidget {
  final String label; final TextEditingController controller; final String? hint;
  const _Input({required this.label, required this.controller, this.hint});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      TextField(controller: controller, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white10, fontSize: 12), filled: true, fillColor: Colors.white.withValues(alpha: 0.05), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
    ]);
  }
}

class _DateBtn extends StatelessWidget {
  final String label; final DateTime? date; final VoidCallback onTap;
  const _DateBtn({required this.label, required this.date, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.calendar_today, color: Colors.white38, size: 14), const SizedBox(width: 8), Text(date != null ? DateFormat('dd/MM/yyyy').format(date!) : 'Select', style: const TextStyle(color: Colors.white, fontSize: 14))]))),
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
