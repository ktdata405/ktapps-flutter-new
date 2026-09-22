import 'package:flutter/material.dart';
import '../core_constants.dart';
import 'calculator_components.dart';
import 'calculator_utils.dart';

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
    double ltv = double.tryParse(_ltvController.text.replaceAll(',', '')) ?? 0;
    double annualRate = double.tryParse(_rateController.text.replaceAll(',', '')) ?? 0;

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

    if (_result != null && mounted) {
      showCalcResultBottomSheet(
        context: context,
        title: 'LAMF Loan Limit Result',
        icon: Icons.savings,
        themeColor: ktOrange,
        resultWidget: _buildResults(),
      );
    }
  }

  void _clear() {
    setState(() {
      _portfolioController.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'LAMF Calculator',
      inputs: [
        CalcInput(
          label: 'Portfolio Value (₹)',
          controller: _portfolioController,
          hint: 'e.g. 10,00,000',
          prefix: const Icon(Icons.account_balance_wallet, size: 20, color: ktTextGray400),
          isCurrency: true,
        ),
        _buildDropdown(),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: CalcInput(label: 'LTV Ratio %', controller: _ltvController, hint: '45')),
          const SizedBox(width: 16),
          Expanded(child: CalcInput(label: 'Interest Rate %', controller: _rateController, hint: '10.5')),
        ]),
      ],
      actions: [
        CalcButton(label: 'Calculate Limit', icon: Icons.calculate, color: ktOrange, onPressed: _calculate),
        const SizedBox(width: 12),
        CalcButton(label: 'Reset', icon: Icons.refresh, color: ktBorderWhite5, onPressed: _clear),
      ],
      results: _result != null ? _buildResults() : null,
    );
  }

  Widget _buildDropdown() {
    final options = {'45': 'Equity (Max 45% LTV)', '80': 'Debt (Max 80% LTV)', '50': 'Hybrid (Max 50% LTV)'};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('FUND TYPE', style: TextStyle(color: ktTextGray400, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: ktBorderWhite5, borderRadius: BorderRadius.circular(16)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _fundType,
              isExpanded: true,
              dropdownColor: ktCardBg,
              style: const TextStyle(color: ktTextWhite, fontSize: 16),
              items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
              onChanged: (v) => setState(() { _fundType = v!; _ltvController.text = v; }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    return CalcResultCard(
      title: 'Loan Eligibility',
      children: [
        CalcResultRow(label: 'Loan Limit', value: CalculatorUtils.formatCurrency(_result!['limit']), color: ktOrange),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'Monthly Interest', value: CalculatorUtils.formatCurrency(_result!['monthly']), color: ktCyan),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'Daily Interest', value: CalculatorUtils.formatCurrency(_result!['daily']), color: ktTextWhite),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'Yearly Interest', value: CalculatorUtils.formatCurrency(_result!['yearly']), color: ktTextWhite),
      ],
    );
  }
}
