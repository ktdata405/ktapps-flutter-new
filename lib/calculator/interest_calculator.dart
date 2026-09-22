import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core_constants.dart';
import 'calculator_components.dart';
import 'calculator_utils.dart';

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
    double P = double.tryParse(_principalController.text.replaceAll(',', '')) ?? 0;
    double R = double.tryParse(_rateController.text.replaceAll(',', '')) ?? 0;
    double G = double.tryParse(_gstController.text.replaceAll(',', '')) ?? 0;
    double y = double.tryParse(_yearsController.text.replaceAll(',', '')) ?? 0;
    double m = double.tryParse(_monthsController.text.replaceAll(',', '')) ?? 0;

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

    if (_result != null && mounted) {
      showCalcResultBottomSheet(
        context: context,
        title: 'Interest Calculation Result',
        icon: Icons.percent,
        themeColor: ktSecondary,
        resultWidget: _buildResults(),
      );
    }
  }

  void _clear() {
    setState(() {
      _principalController.clear();
      _rateController.clear();
      _yearsController.clear();
      _monthsController.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'Interest Calculator',
      inputs: [
        _buildTabs(),
        const SizedBox(height: 24),
        CalcInput(
          label: 'Principal Amount', 
          controller: _principalController, 
          hint: 'e.g. 5,00,000', 
          prefix: const Icon(Icons.currency_rupee, size: 20, color: ktTextGray400),
          isCurrency: true,
        ),
        CalcInput(label: 'Interest Rate % p.a.', controller: _rateController, hint: 'e.g. 12', suffix: const Padding(padding: EdgeInsets.all(16), child: Text('%', style: TextStyle(color: ktTextGray400)))),
        Row(children: [
          Expanded(child: CalcInput(label: 'Tenure (Years)', controller: _yearsController, hint: '0', onChanged: (v) => _monthsController.clear())),
          const SizedBox(width: 16),
          Expanded(child: CalcInput(label: 'Tenure (Months)', controller: _monthsController, hint: '0', onChanged: (v) => _yearsController.clear())),
        ]),
        CalcInput(label: 'GST on Interest %', controller: _gstController, hint: '18'),
      ],
      actions: [
        CalcButton(label: 'Reset', icon: Icons.refresh, color: ktBorderWhite5, onPressed: _clear),
        CalcButton(label: 'Calculate', icon: Icons.calculate, color: ktSecondary, onPressed: _calculate),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: ktBorderWhite5, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Expanded(child: _TabBtn(label: 'Flat Rate', isActive: _mode == 'flat', onTap: () => setState(() { _mode = 'flat'; _result = null; }))),
        Expanded(child: _TabBtn(label: 'Reducing Balance', isActive: _mode == 'float', onTap: () => setState(() { _mode = 'float'; _result = null; }))),
      ]),
    );
  }

  Widget _buildResults() {
    return CalcResultCard(
      title: 'Loan Summary',
      children: [
        CalcResultRow(label: 'Monthly EMI', value: CalculatorUtils.formatCurrency(_result!['emi']), color: ktCyan),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'Total Interest', value: CalculatorUtils.formatCurrency(_result!['interest']), color: ktOrange),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'GST on Interest', value: CalculatorUtils.formatCurrency(_result!['gst']), color: ktTextGray400),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'Total Repayment', value: CalculatorUtils.formatCurrency(_result!['total']), color: ktEmerald),
      ],
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label; final bool isActive; final VoidCallback onTap;
  const _TabBtn({required this.label, required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: isActive ? ktSecondary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(label, style: TextStyle(color: isActive ? ktTextWhite : ktTextGray400, fontSize: 13, fontWeight: FontWeight.bold))),
      ),
    );
  }
}
