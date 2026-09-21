import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core_utils.dart';
import '../core_constants.dart';
import 'calculator_components.dart';
import 'calculator_utils.dart';

class LandCalculator extends StatefulWidget {
  const LandCalculator({super.key});

  @override
  State<LandCalculator> createState() => _LandCalculatorState();
}

class _LandCalculatorState extends State<LandCalculator> {
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _length1Controller = TextEditingController();
  final _length2Controller = TextEditingController();
  final _width1Controller = TextEditingController();
  final _width2Controller = TextEditingController();

  bool _isRegular = true;
  double _cents = 0, _sqft = 0, _gajalu = 0, _ankanam = 0;
  bool _calculated = false;
  final List<Map<String, dynamic>> _history = [];

  void _calculate() {
    double totalSqFt = 0;
    if (_isRegular) {
      double l = double.tryParse(_lengthController.text.replaceAll(',', '')) ?? 0;
      double w = double.tryParse(_widthController.text.replaceAll(',', '')) ?? 0;
      if (l > 0 && w > 0) totalSqFt = l * w;
    } else {
      double l1 = double.tryParse(_length1Controller.text.replaceAll(',', '')) ?? 0;
      double l2 = double.tryParse(_length2Controller.text.replaceAll(',', '')) ?? 0;
      double w1 = double.tryParse(_width1Controller.text.replaceAll(',', '')) ?? 0;
      double w2 = double.tryParse(_width2Controller.text.replaceAll(',', '')) ?? 0;
      if (l1 > 0 && l2 > 0 && w1 > 0 && w2 > 0) {
        totalSqFt = ((l1 + l2) / 2) * ((w1 + w2) / 2);
      }
    }

    if (totalSqFt > 0) {
      setState(() {
        _sqft = totalSqFt;
        _cents = totalSqFt / 435.6;
        _gajalu = totalSqFt / 9;
        _ankanam = totalSqFt / 72;
        _calculated = true;
        _history.insert(0, {
          'date': DateFormat('hh:mm a').format(getIndiaTime()),
          'sqft': _sqft,
          'cents': _cents,
          'mode': _isRegular ? 'Regular' : 'Irregular'
        });
      });
    }
  }

  void _clear() {
    setState(() {
      _lengthController.clear(); _widthController.clear();
      _length1Controller.clear(); _length2Controller.clear();
      _width1Controller.clear(); _width2Controller.clear();
      _cents = 0; _sqft = 0; _gajalu = 0; _ankanam = 0;
      _calculated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'AP Land Converter',
      inputs: [
        _buildTabs(),
        const SizedBox(height: 24),
        if (_isRegular) ...[
          Row(children: [
            Expanded(child: CalcInput(label: 'Length (ft)', controller: _lengthController, hint: '0.00', isCurrency: true)),
            const SizedBox(width: 16),
            Expanded(child: CalcInput(label: 'Width (ft)', controller: _widthController, hint: '0.00', isCurrency: true)),
          ]),
        ] else ...[
          Row(children: [
            Expanded(child: CalcInput(label: 'Length 1 (ft)', controller: _length1Controller, hint: '0.00', isCurrency: true)),
            const SizedBox(width: 16),
            Expanded(child: CalcInput(label: 'Length 2 (ft)', controller: _length2Controller, hint: '0.00', isCurrency: true)),
          ]),
          Row(children: [
            Expanded(child: CalcInput(label: 'Width 1 (ft)', controller: _width1Controller, hint: '0.00', isCurrency: true)),
            const SizedBox(width: 16),
            Expanded(child: CalcInput(label: 'Width 2 (ft)', controller: _width2Controller, hint: '0.00', isCurrency: true)),
          ]),
        ],
      ],
      actions: [
        CalcButton(label: 'Calculate', icon: Icons.calculate, onPressed: _calculate),
        const SizedBox(width: 12),
        CalcButton(label: 'Reset', icon: Icons.refresh, color: ktBorderWhite5, onPressed: _clear),
      ],
      results: _calculated ? _buildResults() : null,
      history: _history.isNotEmpty ? [_buildHistory()] : null,
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: ktBorderWhite5, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Expanded(child: _TabBtn(label: 'Regular Shape', isActive: _isRegular, onTap: () => setState(() => _isRegular = true))),
        Expanded(child: _TabBtn(label: 'Irregular Shape', isActive: !_isRegular, onTap: () => setState(() => _isRegular = false))),
      ]),
    );
  }

  Widget _buildResults() {
    return CalcResultCard(
      title: 'Area Analysis',
      children: [
        CalcResultRow(label: 'Cents', value: _cents.toStringAsFixed(3), color: ktRose),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'Total Sq. Ft', value: CalculatorUtils.formatGrouped(_sqft), color: ktCyan),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'Gajalu (Sq. Yds)', value: CalculatorUtils.formatGrouped(_gajalu), color: ktOrange),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'Ankanams', value: CalculatorUtils.formatGrouped(_ankanam), color: ktSecondary),
      ],
    );
  }

  Widget _buildHistory() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('RECENT CALCULATIONS', style: TextStyle(color: ktTextGray400, fontSize: 8.5, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      const SizedBox(height: 16),
      ..._history.take(5).map((h) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ktCardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: ktBorderWhite5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h['mode'], style: const TextStyle(color: ktTextWhite, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(h['date'], style: const TextStyle(color: ktTextGray500, fontSize: 12), overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${CalculatorUtils.formatGrouped(h['sqft'])} ft²', style: const TextStyle(color: ktCyan, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            Text('${h['cents'].toStringAsFixed(2)} cents', style: const TextStyle(color: ktRose, fontSize: 12), overflow: TextOverflow.ellipsis),
          ]),
        ]),
      )),
    ]);
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
        decoration: BoxDecoration(color: isActive ? ktPrimary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(label, style: TextStyle(color: isActive ? ktTextWhite : ktTextGray400, fontSize: 13, fontWeight: FontWeight.bold))),
      ),
    );
  }
}
