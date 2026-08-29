import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core_constants.dart';

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
      double l = double.tryParse(_lengthController.text) ?? 0;
      double w = double.tryParse(_widthController.text) ?? 0;
      if (l > 0 && w > 0) totalSqFt = l * w;
    } else {
      double l1 = double.tryParse(_length1Controller.text) ?? 0;
      double l2 = double.tryParse(_length2Controller.text) ?? 0;
      double w1 = double.tryParse(_width1Controller.text) ?? 0;
      double w2 = double.tryParse(_width2Controller.text) ?? 0;
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
          'date': DateFormat('hh:mm a').format(DateTime.now()),
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
    return Scaffold(
      backgroundColor: ktBgDark,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('AP Land Converter'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildTabs(),
            const SizedBox(height: 24),
            _buildInputs(),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: ElevatedButton(onPressed: _calculate, style: ElevatedButton.styleFrom(backgroundColor: ktPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Calculate Area', style: TextStyle(fontWeight: FontWeight.bold)))),
              const SizedBox(width: 12),
              IconButton(onPressed: _clear, icon: const Icon(Icons.refresh), style: IconButton.styleFrom(backgroundColor: ktBorderWhite5, padding: const EdgeInsets.all(16))),
            ]),
            if (_calculated) ...[
              const SizedBox(height: 24),
              _buildResults(),
              const SizedBox(height: 24),
              _buildHistory(),
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
        Expanded(child: _TabBtn(label: 'Regular', isActive: _isRegular, onTap: () => setState(() => _isRegular = true))),
        Expanded(child: _TabBtn(label: 'Irregular', isActive: !_isRegular, onTap: () => setState(() => _isRegular = false))),
      ]),
    );
  }

  Widget _buildInputs() {
    if (_isRegular) {
      return Row(children: [
        Expanded(child: _Input(label: 'Length (ft)', controller: _lengthController)),
        const SizedBox(width: 12),
        Expanded(child: _Input(label: 'Width (ft)', controller: _widthController)),
      ]);
    } else {
      return Column(children: [
        Row(children: [
          Expanded(child: _Input(label: 'Length 1 (ft)', controller: _length1Controller)),
          const SizedBox(width: 12),
          Expanded(child: _Input(label: 'Length 2 (ft)', controller: _length2Controller)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _Input(label: 'Width 1 (ft)', controller: _width1Controller)),
          const SizedBox(width: 12),
          Expanded(child: _Input(label: 'Width 2 (ft)', controller: _width2Controller)),
        ]),
      ]);
    }
  }

  Widget _buildResults() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: ktBorderWhite5)),
      child: Column(children: [
        _ResultRow(label: 'Cents', value: _cents.toStringAsFixed(3), color: ktRose),
        _ResultRow(label: 'Total Sq. Ft', value: NumberFormat('#,###.##').format(_sqft), color: ktCyan),
        _ResultRow(label: 'Gajalu (Sq. Yds)', value: _gajalu.toStringAsFixed(2), color: ktOrange),
        _ResultRow(label: 'Ankanams', value: _ankanam.toStringAsFixed(2), color: ktSecondary),
      ]),
    );
  }

  Widget _buildHistory() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Recent Calculations', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      ..._history.take(5).map((h) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${h['date']} • ${h['mode']}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
          Text('${NumberFormat('#,###').format(h['sqft'])} ft² / ${h['cents'].toStringAsFixed(2)} cents', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
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
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: isActive ? ktPrimary : Colors.transparent, borderRadius: BorderRadius.circular(10)), child: Center(child: Text(label, style: TextStyle(color: isActive ? ktTextWhite : Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)))));
  }
}

class _Input extends StatelessWidget {
  final String label; final TextEditingController controller;
  const _Input({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
      const SizedBox(height: 6),
      TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), style: const TextStyle(color: ktTextWhite, fontSize: 16), decoration: InputDecoration(filled: true, fillColor: ktBorderWhite5, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
    ]);
  }
}

class _ResultRow extends StatelessWidget {
  final String label, value; final Color color;
  const _ResultRow({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ]),
    );
  }
}
