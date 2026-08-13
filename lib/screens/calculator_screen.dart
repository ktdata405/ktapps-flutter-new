import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // Land
  bool _landCorner = false;
  final _landL = TextEditingController();
  final _landW = TextEditingController();
  final _landL1 = TextEditingController();
  final _landL2 = TextEditingController();
  final _landW1 = TextEditingController();
  final _landW2 = TextEditingController();
  String _landResult = '';

  // Flat/Reducing
  bool _reducingMode = true;
  final _finPrincipal = TextEditingController();
  final _finRate = TextEditingController();
  final _finTenure = TextEditingController();
  bool _finTenureYears = false;
  final _finGst = TextEditingController(text: '18');
  String _finResult = '';

  // Village
  bool _villageByDate = false;
  final _vPrincipal = TextEditingController();
  final _vRate100 = TextEditingController();
  final _vMonths = TextEditingController();
  DateTime _vStart = DateTime.now();
  DateTime _vEnd = DateTime.now().add(const Duration(days: 30));
  String _vResult = '';

  // LAMF
  final _lamfPortfolio = TextEditingController();
  final _lamfRate = TextEditingController(text: '10.5');
  String _lamfFund = 'Equity';
  String _lamfResult = '';

  // Govt schemes
  String _scheme = 'PPF';
  final _s1 = TextEditingController();
  final _s2 = TextEditingController();
  final _s3 = TextEditingController();
  String _schemeResult = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final c in [
      _landL,
      _landW,
      _landL1,
      _landL2,
      _landW1,
      _landW2,
      _finPrincipal,
      _finRate,
      _finTenure,
      _finGst,
      _vPrincipal,
      _vRate100,
      _vMonths,
      _lamfPortfolio,
      _lamfRate,
      _s1,
      _s2,
      _s3,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  int _monthsDiff(DateTime start, DateTime end) {
    if (end.isBefore(start)) return 0;
    final y = end.year - start.year;
    final m = end.month - start.month;
    final d = end.day - start.day;
    return (y * 12 + m) + (d >= 0 ? 0 : -1);
  }

  Future<void> _saveToReport(String module, String input, String result) async {
    await ApiService.saveCalculatorRecord({
      'module': module,
      'createdAt': DateTime.now().toIso8601String(),
      'inputSummary': input,
      'resultSummary': result,
      'note': '',
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved to calculator reports')),
    );
  }

  // ── LAND ────────────────────────────────────────────────────
  void _calcLand() {
    double sqft;
    if (_landCorner) {
      final l1 = _num(_landL1);
      final l2 = _num(_landL2);
      final w1 = _num(_landW1);
      final w2 = _num(_landW2);
      sqft = ((l1 + l2) / 2) * ((w1 + w2) / 2);
      _landResult =
          'Irregular area: ${sqft.toStringAsFixed(2)} sq.ft\n'
          'Cents: ${(sqft / 435.6).toStringAsFixed(2)}\n'
          'Gajalu: ${(sqft / 9).toStringAsFixed(2)}\n'
          'Ankanam: ${(sqft / 72).toStringAsFixed(2)}';
    } else {
      final l = _num(_landL);
      final w = _num(_landW);
      sqft = l * w;
      _landResult =
          'Regular area: ${sqft.toStringAsFixed(2)} sq.ft\n'
          'Cents: ${(sqft / 435.6).toStringAsFixed(2)}\n'
          'Gajalu: ${(sqft / 9).toStringAsFixed(2)}\n'
          'Ankanam: ${(sqft / 72).toStringAsFixed(2)}';
    }
    setState(() {});
  }

  // ── FLAT/REDUCING ───────────────────────────────────────────
  void _calcFinance() {
    final p = _num(_finPrincipal);
    final r = _num(_finRate);
    final tRaw = _num(_finTenure);
    final gst = _num(_finGst);
    final months = _finTenureYears ? (tRaw * 12).round() : tRaw.round();

    if (p <= 0 || r <= 0 || months <= 0) return;

    final mRate = r / 12 / 100;
    double emi;
    double total;
    if (_reducingMode) {
      emi = p * mRate * math.pow(1 + mRate, months) /
          (math.pow(1 + mRate, months) - 1);
      total = emi * months;
    } else {
      final interest = p * r * months / 1200;
      total = p + interest;
      emi = total / months;
    }

    final interestTotal = total - p;
    final gstAmt = interestTotal * gst / 100;
    final totalWithGst = total + gstAmt;

    _finResult =
        'Mode: ${_reducingMode ? 'Reducing' : 'Flat'}\n'
        'EMI: ₹${NumberFormat('#,##0', 'en_IN').format(emi)}\n'
        'Total Interest: ₹${NumberFormat('#,##0', 'en_IN').format(interestTotal)}\n'
        'GST on Interest: ₹${NumberFormat('#,##0', 'en_IN').format(gstAmt)}\n'
        'Total Amount: ₹${NumberFormat('#,##0', 'en_IN').format(totalWithGst)}';
    setState(() {});
  }

  // ── VILLAGE INTEREST ────────────────────────────────────────
  void _calcVillage() {
    final p = _num(_vPrincipal);
    final rate100 = _num(_vRate100);
    final months = _villageByDate ? _monthsDiff(_vStart, _vEnd) : _num(_vMonths).round();
    if (p <= 0 || rate100 <= 0 || months <= 0) return;

    final monthlyInterest = (p / 100) * rate100;
    final totalInterest = monthlyInterest * months;
    final total = p + totalInterest;
    final emi = total / months;

    _vResult =
        'Duration: $months months\n'
        'Monthly Interest: ₹${NumberFormat('#,##0', 'en_IN').format(monthlyInterest)}\n'
        'Total Interest: ₹${NumberFormat('#,##0', 'en_IN').format(totalInterest)}\n'
        'Total Amount: ₹${NumberFormat('#,##0', 'en_IN').format(total)}\n'
        'Monthly EMI: ₹${NumberFormat('#,##0', 'en_IN').format(emi)}';
    setState(() {});
  }

  // ── LAMF ────────────────────────────────────────────────────
  void _calcLamf() {
    final portfolio = _num(_lamfPortfolio);
    final rate = _num(_lamfRate);
    if (portfolio <= 0 || rate <= 0) return;

    final ltv = switch (_lamfFund) {
      'Debt' => 0.7,
      'Hybrid' => 0.6,
      _ => 0.5,
    };

    final eligible = portfolio * ltv;
    final yearlyInterest = eligible * rate / 100;
    final monthlyInterest = yearlyInterest / 12;
    final dailyInterest = yearlyInterest / 365;

    _lamfResult =
        'Fund: $_lamfFund (LTV ${(ltv * 100).toStringAsFixed(0)}%)\n'
        'Eligible Loan: ₹${NumberFormat('#,##0', 'en_IN').format(eligible)}\n'
        'Daily Interest: ₹${NumberFormat('#,##0.00', 'en_IN').format(dailyInterest)}\n'
        'Monthly Interest: ₹${NumberFormat('#,##0', 'en_IN').format(monthlyInterest)}\n'
        'Yearly Interest: ₹${NumberFormat('#,##0', 'en_IN').format(yearlyInterest)}';
    setState(() {});
  }

  // ── GOVT SCHEMES ────────────────────────────────────────────
  void _calcScheme() {
    final a = _num(_s1);
    final b = _num(_s2);
    final c = _num(_s3);
    if (a <= 0) return;

    switch (_scheme) {
      case 'PPF':
        final years = b <= 0 ? 15 : b;
        final rate = c <= 0 ? 7.1 : c;
        final maturity = a * years * (1 + (rate / 100) * 0.5);
        _schemeResult =
            'PPF (${years.toStringAsFixed(0)} yrs @ ${rate.toStringAsFixed(1)}%)\n'
            'Approx Maturity: ₹${NumberFormat('#,##0', 'en_IN').format(maturity)}';
        break;
      case 'SSA':
        final years = 15.0;
        final rate = b <= 0 ? 8.2 : b;
        final maturity = a * years * (1 + (rate / 100) * 0.55);
        _schemeResult =
            'SSA (15 yrs @ ${rate.toStringAsFixed(1)}%)\n'
            'Approx Maturity: ₹${NumberFormat('#,##0', 'en_IN').format(maturity)}';
        break;
      case 'NSC':
        final rate = b <= 0 ? 7.7 : b;
        final maturity = a * math.pow(1 + rate / 100, 5);
        _schemeResult =
            'NSC (5 yrs @ ${rate.toStringAsFixed(1)}%)\n'
            'Maturity: ₹${NumberFormat('#,##0', 'en_IN').format(maturity)}';
        break;
      case 'SCSS':
        final rate = b <= 0 ? 8.2 : b;
        final yearly = a * rate / 100;
        _schemeResult =
            'SCSS @ ${rate.toStringAsFixed(1)}%\n'
            'Yearly Payout: ₹${NumberFormat('#,##0', 'en_IN').format(yearly)}\n'
            'Quarterly: ₹${NumberFormat('#,##0', 'en_IN').format(yearly / 4)}';
        break;
      default:
        final rate = b <= 0 ? 7.0 : b;
        final maturity = a * math.pow(1 + rate / 100, 5);
        _schemeResult =
            '$_scheme @ ${rate.toStringAsFixed(1)}%\n'
            'Approx Value: ₹${NumberFormat('#,##0', 'en_IN').format(maturity)}';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Calculator Suite'),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Land'),
            Tab(text: 'Flat/Float'),
            Tab(text: 'Village'),
            Tab(text: 'LAMF'),
            Tab(text: 'Govt'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildLand(),
          _buildFlatFloat(),
          _buildVillage(),
          _buildLamf(),
          _buildGovt(),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xB31E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ListView(
          children: children,
        ),
      );

  Widget _resultBox(String value) => Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0x1A6366F1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x406366F1)),
        ),
        child: Text(value,
            style: const TextStyle(color: Colors.white, height: 1.45)),
      );

  Widget _buildLand() => _card(children: [
        SwitchListTile(
          value: _landCorner,
          onChanged: (v) => setState(() => _landCorner = v),
          title: const Text('Corner / Irregular Plot'),
        ),
        if (_landCorner) ...[
          _txt(_landL1, 'Length 1 (ft)'),
          _txt(_landL2, 'Length 2 (ft)'),
          _txt(_landW1, 'Width 1 (ft)'),
          _txt(_landW2, 'Width 2 (ft)'),
        ] else ...[
          _txt(_landL, 'Length (ft)'),
          _txt(_landW, 'Width (ft)'),
        ],
        const SizedBox(height: 8),
        _actionRow(
          onCalc: _calcLand,
          onSave: () => _saveToReport(
            'Land',
            _landCorner
                ? 'Irregular L1=${_landL1.text}, L2=${_landL2.text}, W1=${_landW1.text}, W2=${_landW2.text}'
                : 'Regular L=${_landL.text}, W=${_landW.text}',
            _landResult,
          ),
        ),
        if (_landResult.isNotEmpty) _resultBox(_landResult),
      ]);

  Widget _buildFlatFloat() => _card(children: [
        SwitchListTile(
          value: _reducingMode,
          onChanged: (v) => setState(() => _reducingMode = v),
          title: Text(_reducingMode ? 'Reducing Balance Mode' : 'Flat Interest Mode'),
        ),
        _txt(_finPrincipal, 'Principal (₹)'),
        _txt(_finRate, 'Interest Rate %'),
        Row(children: [
          Expanded(child: _txt(_finTenure, 'Tenure')),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<bool>(
              value: _finTenureYears,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Tenure Type'),
              items: const [
                DropdownMenuItem(value: false, child: Text('Months')),
                DropdownMenuItem(value: true, child: Text('Years')),
              ],
              onChanged: (v) => setState(() => _finTenureYears = v ?? false),
            ),
          ),
        ]),
        _txt(_finGst, 'GST % on Interest'),
        const SizedBox(height: 8),
        _actionRow(
          onCalc: _calcFinance,
          onSave: () => _saveToReport(
            'Flat/Reducing',
            '${_reducingMode ? 'Reducing' : 'Flat'} P=${_finPrincipal.text}, R=${_finRate.text}, T=${_finTenure.text}${_finTenureYears ? ' years' : ' months'}',
            _finResult,
          ),
        ),
        if (_finResult.isNotEmpty) _resultBox(_finResult),
      ]);

  Widget _buildVillage() => _card(children: [
        SwitchListTile(
          value: _villageByDate,
          onChanged: (v) => setState(() => _villageByDate = v),
          title: Text(_villageByDate ? 'Date Range Mode' : 'Months Mode'),
        ),
        _txt(_vPrincipal, 'Principal (₹)'),
        _txt(_vRate100, 'Rate per ₹100 / month'),
        if (_villageByDate) ...[
          _dateTile('Start Date', _vStart, (d) => setState(() => _vStart = d)),
          _dateTile('End Date', _vEnd, (d) => setState(() => _vEnd = d)),
        ] else
          _txt(_vMonths, 'Duration (months)'),
        const SizedBox(height: 8),
        _actionRow(
          onCalc: _calcVillage,
          onSave: () => _saveToReport(
            'Village Interest',
            _villageByDate
                ? 'P=${_vPrincipal.text}, R=${_vRate100.text}, ${DateFormat('dd/MMM/yyyy').format(_vStart)} to ${DateFormat('dd/MMM/yyyy').format(_vEnd)}'
                : 'P=${_vPrincipal.text}, R=${_vRate100.text}, M=${_vMonths.text}',
            _vResult,
          ),
        ),
        if (_vResult.isNotEmpty) _resultBox(_vResult),
      ]);

  Widget _buildLamf() => _card(children: [
        _txt(_lamfPortfolio, 'Portfolio Value (₹)'),
        DropdownButtonFormField<String>(
          value: _lamfFund,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white),
          decoration: _dec('Fund Type'),
          items: const [
            DropdownMenuItem(value: 'Equity', child: Text('Equity')),
            DropdownMenuItem(value: 'Debt', child: Text('Debt')),
            DropdownMenuItem(value: 'Hybrid', child: Text('Hybrid')),
          ],
          onChanged: (v) => setState(() => _lamfFund = v ?? 'Equity'),
        ),
        const SizedBox(height: 10),
        _txt(_lamfRate, 'Annual Interest %'),
        const SizedBox(height: 8),
        _actionRow(
          onCalc: _calcLamf,
          onSave: () => _saveToReport(
            'LAMF',
            'Portfolio=${_lamfPortfolio.text}, Fund=$_lamfFund, Rate=${_lamfRate.text}%',
            _lamfResult,
          ),
        ),
        if (_lamfResult.isNotEmpty) _resultBox(_lamfResult),
      ]);

  Widget _buildGovt() => _card(children: [
        DropdownButtonFormField<String>(
          value: _scheme,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: Colors.white),
          decoration: _dec('Scheme'),
          items: const [
            DropdownMenuItem(value: 'PPF', child: Text('PPF')),
            DropdownMenuItem(value: 'SSA', child: Text('SSA')),
            DropdownMenuItem(value: 'NSC', child: Text('NSC')),
            DropdownMenuItem(value: 'SCSS', child: Text('SCSS')),
            DropdownMenuItem(value: 'KVP', child: Text('KVP')),
            DropdownMenuItem(value: 'NPS', child: Text('NPS')),
          ],
          onChanged: (v) => setState(() => _scheme = v ?? 'PPF'),
        ),
        const SizedBox(height: 10),
        _txt(_s1, 'Investment Amount (₹)'),
        _txt(_s2, _scheme == 'PPF' ? 'Duration / Rate' : 'Rate %'),
        _txt(_s3, 'Optional field (if needed)'),
        const SizedBox(height: 8),
        _actionRow(
          onCalc: _calcScheme,
          onSave: () => _saveToReport(
            'Govt Schemes',
            '$_scheme Amount=${_s1.text}, Param2=${_s2.text}, Param3=${_s3.text}',
            _schemeResult,
          ),
        ),
        if (_schemeResult.isNotEmpty) _resultBox(_schemeResult),
      ]);

  Widget _txt(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: _dec(label),
        ),
      );

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      );

  Widget _actionRow({required VoidCallback onCalc, required VoidCallback onSave}) => Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: onCalc,
              icon: const Icon(Icons.calculate_rounded),
              label: const Text('Calculate'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('Save to Report'),
            ),
          ),
        ],
      );

  Widget _dateTile(String label, DateTime val, ValueChanged<DateTime> onSet) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: val,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) onSet(picked);
          },
          child: InputDecorator(
            decoration: _dec(label),
            child: Text(DateFormat('dd/MMM/yyyy').format(val),
                style: const TextStyle(color: Colors.white)),
          ),
        ),
      );
}

