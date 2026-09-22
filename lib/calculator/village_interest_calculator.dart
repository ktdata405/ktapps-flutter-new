import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core_constants.dart';
import 'calculator_components.dart';
import 'calculator_utils.dart';

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
    double P = double.tryParse(_principalController.text.replaceAll(',', '')) ?? 0;
    double R = double.tryParse(_rateController.text.replaceAll(',', '')) ?? 0;

    if (P <= 0 || R <= 0) return;

    double totalMonths = 0;
    String durationText = "";

    if (_mode == 'months') {
      totalMonths = double.tryParse(_monthsController.text.replaceAll(',', '')) ?? 0;
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

    if (_result != null && mounted) {
      showCalcResultBottomSheet(
        context: context,
        title: 'Village Interest Result',
        icon: Icons.people,
        themeColor: ktSecondary,
        resultWidget: _buildResults(),
      );
    }
  }

  void _clear() {
    setState(() {
      _principalController.clear();
      _rateController.clear();
      _monthsController.clear();
      _startDate = null;
      _endDate = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'Village Interest',
      inputs: [
        _buildTabs(),
        const SizedBox(height: 24),
        CalcInput(
          label: 'Principal Amount',
          controller: _principalController,
          hint: 'e.g. 1,00,000',
          prefix: const Icon(Icons.currency_rupee, size: 20, color: ktTextGray400),
          isCurrency: true,
        ),
        CalcInput(
          label: 'Interest Rate (per 100)',
          controller: _rateController,
          hint: 'e.g. 2 (for 2 rupees per 100)',
          suffix: const Padding(padding: EdgeInsets.all(16), child: Text('/ 100', style: TextStyle(color: ktTextGray400))),
        ),
        if (_mode == 'months')
          CalcInput(label: 'Duration in Months', controller: _monthsController, hint: 'e.g. 12')
        else ...[
          const Text('DURATION', style: TextStyle(color: ktTextGray400, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _DateBtn(label: 'Start Date', date: _startDate, onTap: () async {
              final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
              if(d!=null) setState(()=>_startDate=d);
            })),
            const SizedBox(width: 16),
            Expanded(child: _DateBtn(label: 'End Date', date: _endDate, onTap: () async {
              final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
              if(d!=null) setState(()=>_endDate=d);
            })),
          ]),
          const SizedBox(height: 16),
        ],
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
        Expanded(child: _TabBtn(label: 'By Months', isActive: _mode == 'months', onTap: () => setState(() { _mode = 'months'; _result = null; }))),
        Expanded(child: _TabBtn(label: 'By Dates', isActive: _mode == 'date', onTap: () => setState(() { _mode = 'date'; _result = null; }))),
      ]),
    );
  }

  Widget _buildResults() {
    return CalcResultCard(
      title: 'Calculation Summary',
      children: [
        CalcResultRow(label: 'Duration', value: _result!['duration'], color: ktTextWhite),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'Monthly Interest', value: CalculatorUtils.formatCurrency(_result!['monthlyInterest']), color: ktOrange),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'Total Interest', value: CalculatorUtils.formatCurrency(_result!['interest']), color: ktRose),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'Total Amount', value: CalculatorUtils.formatCurrency(_result!['total']), color: ktEmerald),
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

class _DateBtn extends StatelessWidget {
  final String label; final DateTime? date; final VoidCallback onTap;
  const _DateBtn({required this.label, required this.date, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(color: ktBorderWhite5, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: ktTextGray400, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? DateFormat('dd MMM yyyy').format(date!) : label,
                style: TextStyle(color: date != null ? ktTextWhite : ktTextGray400, fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
