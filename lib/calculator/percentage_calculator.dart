import 'package:flutter/material.dart';
import '../core_constants.dart';
import 'calculator_components.dart';

class PercentageCalculator extends StatefulWidget {
  const PercentageCalculator({super.key});

  @override
  State<PercentageCalculator> createState() => _PercentageCalculatorState();
}

class _PercentageCalculatorState extends State<PercentageCalculator> {
  final _val1Controller = TextEditingController();
  final _val2Controller = TextEditingController();

  int _mode = 0; // 0: What is X% of Y?, 1: X is what % of Y?, 2: % Increase/Decrease, 3: % Difference
  String _incDecMode = 'increase'; // 'increase' or 'decrease'
  Map<String, dynamic>? _result;

  void _calculate() {
    double v1 = double.tryParse(_val1Controller.text.replaceAll(',', '')) ?? 0;
    double v2 = double.tryParse(_val2Controller.text.replaceAll(',', '')) ?? 0;

    setState(() {
      if (_mode == 0) {
        // What is X% of Y? (v1 % of v2)
        double ans = (v1 * v2) / 100;
        _result = {
          'primary': ans,
          'title': '$v1% of $v2',
          'description': '$v1 percent of $v2 is $ans',
        };
      } else if (_mode == 1) {
        // X is what % of Y? (v1 is what % of v2)
        if (v2 == 0) return;
        double ans = (v1 / v2) * 100;
        _result = {
          'primary': ans,
          'title': '$v1 is what % of $v2',
          'description': '$v1 is ${ans.toStringAsFixed(2)}% of $v2',
          'isPercent': true,
        };
      } else if (_mode == 2) {
        // Percentage Increase / Decrease from v1 to v2 (or v1 by v2%)
        if (_incDecMode == 'increase') {
          double finalVal = v1 + (v1 * v2 / 100);
          double diff = v1 * v2 / 100;
          _result = {
            'primary': finalVal,
            'diff': diff,
            'title': 'Increase $v1 by $v2%',
            'description': 'Increased value is $finalVal (Difference: +$diff)',
          };
        } else {
          double finalVal = v1 - (v1 * v2 / 100);
          double diff = v1 * v2 / 100;
          _result = {
            'primary': finalVal,
            'diff': diff,
            'title': 'Decrease $v1 by $v2%',
            'description': 'Decreased value is $finalVal (Difference: -$diff)',
          };
        }
      } else {
        // Percentage Difference between v1 and v2
        if (v1 + v2 == 0) return;
        double diff = (v1 - v2).abs();
        double avg = (v1 + v2) / 2;
        double ans = (diff / avg) * 100;
        _result = {
          'primary': ans,
          'diff': diff,
          'title': 'Percentage Difference between $v1 and $v2',
          'description': 'The difference is ${ans.toStringAsFixed(2)}% (Absolute diff: $diff)',
          'isPercent': true,
        };
      }
    });

    if (_result != null && mounted) {
      showCalcResultBottomSheet(
        context: context,
        title: 'Percentage Calculation Result',
        icon: Icons.percent,
        themeColor: ktCyan,
        resultWidget: _buildResults(),
      );
    }
  }

  void _clear() {
    setState(() {
      _val1Controller.clear();
      _val2Controller.clear();
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'Percentage Calculator',
      inputs: [
        _buildModeSelector(),
        const SizedBox(height: 24),
        if (_mode == 2) ...[
          _buildIncDecToggle(),
          const SizedBox(height: 16),
        ],
        CalcInput(
          label: _mode == 0 ? 'Percentage (%)' : (_mode == 1 ? 'Part Value (X)' : (_mode == 2 ? 'Initial Value' : 'Value A')),
          controller: _val1Controller,
          hint: 'e.g. 15',
          suffix: _mode == 0 ? const Padding(padding: EdgeInsets.all(16), child: Text('%', style: TextStyle(color: ktTextGray400))) : null,
        ),
        const SizedBox(height: 12),
        CalcInput(
          label: _mode == 0 ? 'Whole Value (Y)' : (_mode == 1 ? 'Whole Value (Y)' : (_mode == 2 ? 'Percentage Increase/Decrease (%)' : 'Value B')),
          controller: _val2Controller,
          hint: 'e.g. 200',
          suffix: _mode == 2 ? const Padding(padding: EdgeInsets.all(16), child: Text('%', style: TextStyle(color: ktTextGray400))) : null,
        ),
      ],
      actions: [
        CalcButton(label: 'Reset', icon: Icons.refresh, color: ktBorderWhite5, onPressed: _clear),
        CalcButton(label: 'Calculate', icon: Icons.calculate, color: ktCyan, onPressed: _calculate),
      ],
    );
  }

  Widget _buildModeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _modeBtn(0, 'What is X% of Y?'),
          const SizedBox(width: 8),
          _modeBtn(1, 'X is what % of Y?'),
          const SizedBox(width: 8),
          _modeBtn(2, '% Increase / Decrease'),
          const SizedBox(width: 8),
          _modeBtn(3, '% Difference'),
        ],
      ),
    );
  }

  Widget _modeBtn(int index, String label) {
    final isActive = _mode == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () => setState(() {
        _mode = index;
        _result = null;
        _val1Controller.clear();
        _val2Controller.clear();
      }),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? ktCyan.withValues(alpha: 0.2) : (isDark ? ktBorderWhite5 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isActive ? ktCyan : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? ktCyan : (isDark ? ktTextWhite : Colors.black87),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildIncDecToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: ktBorderWhite5, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _incDecMode = 'increase'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _incDecMode == 'increase' ? ktEmerald : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text('Increase', style: TextStyle(color: _incDecMode == 'increase' ? Colors.white : ktTextGray400, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _incDecMode = 'decrease'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _incDecMode == 'decrease' ? ktRose : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text('Decrease', style: TextStyle(color: _incDecMode == 'decrease' ? Colors.white : ktTextGray400, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final primary = _result!['primary'] as double;
    final isPercent = _result!['isPercent'] == true;
    final formattedPrimary = isPercent ? '${primary.toStringAsFixed(2)}%' : primary.toStringAsFixed(2);

    return CalcResultCard(
      title: _result!['title'],
      children: [
        CalcResultRow(
          label: 'Result',
          value: formattedPrimary,
          color: ktCyan,
        ),
        if (_result!['diff'] != null) ...[
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(
            label: 'Difference',
            value: (_result!['diff'] as double).toStringAsFixed(2),
            color: ktOrange,
          ),
        ],
        const Divider(color: ktBorderWhite5, height: 24),
        Text(
          _result!['description'],
          style: const TextStyle(color: ktTextGray400, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }
}
