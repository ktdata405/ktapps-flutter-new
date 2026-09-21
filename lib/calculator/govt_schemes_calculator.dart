import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core_utils.dart';
import '../core_constants.dart';
import 'calculator_components.dart';
import 'calculator_utils.dart';

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
  final _startYearController = TextEditingController(text: getIndiaTime().year.toString());

  Map<String, dynamic>? _result;

  void _calculate() {
    final investment = double.tryParse(_investmentController.text.replaceAll(',', '')) ?? 0;
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
    int startYear = int.tryParse(_startYearController.text.replaceAll(',', '')) ?? getIndiaTime().year;
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
    int age = int.tryParse(_ageController.text.replaceAll(',', '')) ?? 30;
    double rate = double.tryParse(_returnController.text.replaceAll(',', '')) ?? 10;
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

  void _clear() {
    setState(() {
      _investmentController.clear();
      _ageController.clear();
      _returnController.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'Govt Savings Schemes',
      inputs: [
        _buildTabs(),
        const SizedBox(height: 24),
        CalcInput(
          label: _selectedTab == 'nps' || _selectedTab == 'pomis' ? 'Monthly Investment' : 'Investment Amount',
          controller: _investmentController,
          hint: 'e.g. 5,000',
          prefix: const Icon(Icons.currency_rupee, size: 20, color: ktTextGray400),
          isCurrency: true,
        ),
        if (_selectedTab == 'ssa') ...[
          CalcInput(label: "Girl's Current Age", controller: _ageController, hint: 'e.g. 5'),
          CalcInput(label: "Start Year", controller: _startYearController, hint: '2024'),
        ],
        if (_selectedTab == 'nps') ...[
          CalcInput(label: "Current Age", controller: _ageController, hint: 'e.g. 30'),
          CalcInput(label: "Expected Return %", controller: _returnController, hint: '10', suffix: const Padding(padding: EdgeInsets.all(16), child: Text('%', style: TextStyle(color: ktTextGray400)))),
        ],
      ],
      actions: [
        CalcButton(label: 'Calculate', icon: Icons.calculate, color: ktOrange, onPressed: _calculate),
        const SizedBox(width: 12),
        CalcButton(label: 'Reset', icon: Icons.refresh, color: ktBorderWhite5, onPressed: _clear),
      ],
      results: _result != null ? _buildResults() : null,
    );
  }

  Widget _buildTabs() {
    final schemes = [
      {'id': 'ssa', 'name': 'SSA'},
      {'id': 'ppf', 'name': 'PPF'},
      {'id': 'nps', 'name': 'NPS'},
      {'id': 'nsc', 'name': 'NSC'},
      {'id': 'kvp', 'name': 'KVP'},
      {'id': 'scss', 'name': 'SCSS'},
      {'id': 'pomis', 'name': 'POMIS'},
      {'id': 'mssc', 'name': 'MSSC'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: schemes.map((s) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(s['name']!, style: TextStyle(color: _selectedTab == s['id'] ? Colors.black : ktTextGray400, fontWeight: FontWeight.bold, fontSize: 11)),
            selected: _selectedTab == s['id'],
            onSelected: (v) {
              if (v) setState(() { _selectedTab = s['id']!; _result = null; _clear(); });
            },
            selectedColor: ktOrange,
            backgroundColor: ktBorderWhite5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildResults() {
    return CalcResultCard(
      title: 'Investment Summary',
      children: [
        CalcResultRow(label: 'Total Investment', value: CalculatorUtils.formatCurrency(_result!['totalInvest']), color: ktTextWhite),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'Total Interest', value: CalculatorUtils.formatCurrency(_result!['interest']), color: ktCyan),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'Maturity Amount', value: CalculatorUtils.formatCurrency(_result!['maturity']), color: ktOrange),
        if (_result!['year'] != null) ...[
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Maturity Year', value: _result!['year'].toString(), color: ktTextWhite),
        ],
        if (_result!['monthly'] != null) ...[
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Monthly Payout', value: CalculatorUtils.formatCurrency(_result!['monthly']), color: ktCyan),
        ],
        if (_result!['quarterly'] != null) ...[
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Quarterly Payout', value: CalculatorUtils.formatCurrency(_result!['quarterly']), color: ktCyan),
        ],
      ],
    );
  }
}
