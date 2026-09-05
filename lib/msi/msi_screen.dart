import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core_constants.dart';
import 'msi_service.dart';

class MsiScreen extends StatefulWidget {
  const MsiScreen({super.key});

  @override
  State<MsiScreen> createState() => _MsiScreenState();
}

class _MsiScreenState extends State<MsiScreen> {
  final _years = ktYears;

  bool _loading = false;
  bool _argsApplied = false;
  bool _isEdit = false;
  String _user = 'Kalyan';
  late String _month;
  late String _year;

  late final Map<String, TextEditingController> _controllers;
  final _service = MsiService();

  static final Map<String, Map<String, double>> _defaults = {
    'Kalyan': {
      'coin_quantum_liquid': 1331, 'coin_navi_nifty': 1331, 'coin_invesco_small': 1331, 'coin_axis_nifty': 1331,
      'coin_birla_nifty': 1331, 'coin_dsp_nifty': 1331, 'coin_edelweiss_bond': 1331, 'coin_canara_small': 6655,
      'coin_quant_small': 0, 'coin_birla_psu': 0, 'coin_power_grid': 0, 'nps_tier1': 5500, 'nps_tier2': 0,
      'ssa_account': 2500, 'ppf_account': 10000,
    },
    'Layan': {
      'ind_jio_flexi': 0, 'ind_bandhan_small': 0, 'ind_ntpc_green': 0,
    },
  };

  static final Map<String, List<_FieldSpec>> _sections = {
    'Kalyan': [
      _FieldSpec(
        title: 'Coin',
        icon: Icons.currency_bitcoin,
        fields: [
          _FieldItem('coin_quantum_liquid', 'Quantum Liquid Debt Fund Max -10%'),
          _FieldItem('coin_navi_nifty', 'Navi Nifty 50 Index Funds'),
          _FieldItem('coin_invesco_small', 'Invesco India Small Cap Fund'),
          _FieldItem('coin_axis_nifty', 'Axis Nifty 100 Index Fund'),
          _FieldItem('coin_birla_nifty', 'Aditya Birla Sun Life Nifty 50 Index'),
          _FieldItem('coin_dsp_nifty', 'DSP Nifty 50 Index Fund'),
          _FieldItem('coin_edelweiss_bond', 'EdelWeiss Bharat Bond FOF - Apr 2031'),
        ],
      ),
      _FieldSpec(
        title: 'Groww',
        icon: Icons.eco,
        fields: [
          _FieldItem('coin_canara_small', 'Canara Robeco Small Cap Fund Direct'),
          _FieldItem('coin_quant_small', 'Quant Small Cap Fund Direct Plan[Lum-sum]'),
          _FieldItem('coin_birla_psu', 'Aditya Birla Sun Life PSU Equity Direct[Lum-sum]'),
          _FieldItem('coin_power_grid', 'Power Grid Corp(Stock)'),
        ],
      ),
      _FieldSpec(
        title: 'Govt Investments',
        icon: Icons.account_balance,
        fields: [
          _FieldItem('nps_tier1', 'NPS Tier - 1'),
          _FieldItem('nps_tier2', 'NPS Tier - 2'),
          _FieldItem('ssa_account', 'Sukanya Samriddhi Account (SSA)'),
          _FieldItem('ppf_account', 'PPF'),
        ],
      ),
      _FieldSpec(
        title: 'NJ Wealth',
        icon: Icons.work,
        fields: [
          _FieldItem('nj_dsp_midcap', 'Dsp Midcap'),
          _FieldItem('nj_axis_midcap', 'Axis Midcap'),
          _FieldItem('nj_invesco_midcap', 'Invesco Midcap'),
          _FieldItem('nj_kotak_emerging', 'Kotak Emerging'),
          _FieldItem('nj_nippon_growth', 'Nippon Growth'),
        ],
      ),
    ],
    'Layan': [
      _FieldSpec(
        title: 'INDMoney',
        icon: Icons.show_chart,
        fields: [
          _FieldItem('ind_jio_flexi', 'JioBlackRock Flexi Cap Fund'),
          _FieldItem('ind_bandhan_small', 'Bandhan Small Cap Fund'),
          _FieldItem('ind_ntpc_green', 'NTPC Green Stock'),
        ],
      ),
    ],
  };

  static const _editMapping = {
    'quantum_liquid': 'coin_quantum_liquid', 'navi_nifty': 'coin_navi_nifty', 'invesco_small': 'coin_invesco_small',
    'axis_nifty': 'coin_axis_nifty', 'birla_nifty': 'coin_birla_nifty', 'dsp_nifty': 'coin_dsp_nifty',
    'edelweiss_bond': 'coin_edelweiss_bond', 'canara_small': 'coin_canara_small', 'quant_small': 'coin_quant_small',
    'birla_psu': 'coin_birla_psu', 'power_grid': 'coin_power_grid', 'ssa': 'ssa_account', 'ppf': 'ppf_account',
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = ktMonths[now.month - 1];
    _year = '${now.year}';
    _controllers = { for (final field in _allKeys) field: TextEditingController() };
    _loadDefaultsForUser(_user);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    _argsApplied = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) _applyEditData(args);
  }

  @override
  void dispose() { for (final c in _controllers.values) c.dispose(); super.dispose(); }

  static Iterable<String> get _allKeys => {
    ..._sections.values.expand((s) => s).expand((s) => s.fields).map((f) => f.key),
    'nj_dsp_midcap', 'nj_axis_midcap', 'nj_invesco_midcap', 'nj_kotak_emerging', 'nj_nippon_growth'
  };

  void _loadDefaultsForUser(String user) {
    final defaults = _defaults[user] ?? const <String, double>{};
    for (final c in _controllers.values) c.clear();
    for (final e in defaults.entries) {
       if (_controllers.containsKey(e.key)) {
         _controllers[e.key]!.text = e.value == 0 ? '0' : e.value.toStringAsFixed(0);
       }
    }
    setState(() {});
  }

  void _applyEditData(Map<String, dynamic> row) {
    _isEdit = true;
    final userArg = (row['user'] ?? row['user_select'] ?? '').toString();
    if (userArg == 'Kalyan' || userArg == 'Layan') _user = userArg;
    _month = (row['month'] ?? _month).toString();
    _year = (row['year'] ?? _year).toString();
    _loadDefaultsForUser(_user);
    for (final entry in row.entries) {
      final key = _editMapping[entry.key] ?? entry.key;
      final ctrl = _controllers[key];
      if (ctrl == null) continue;
      final n = double.tryParse('${entry.value}');
      if (n != null) ctrl.text = n.toStringAsFixed(0);
    }
  }

  String _sanitize(String input) {
    final clean = input.replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = clean.split('.');
    return parts.length <= 1 ? clean : '${parts.first}.${parts.skip(1).join()}';
  }

  double _parse(String value) => double.tryParse(value.replaceAll(',', '')) ?? 0;
  String _fmt(double value) => NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 2).format(value);

  List<_FieldItem> get _activeFields => _sections[_user]!.expand((s) => s.fields).toList();

  double get _total {
    double t = 0.0;
    for (final f in _activeFields) t += _parse(_controllers[f.key]!.text);
    return t;
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final body = <String, dynamic>{'type': 'msi', 'action': _isEdit ? 'update' : 'add', 'month': _month, 'year': _year, 'user_select': _user};
    for (final f in _activeFields) body[f.key] = _parse(_controllers[f.key]!.text);
    try {
      await _service.saveData(body);
      if (mounted) _showToast('Investment details saved for $_month $_year ($_user).');
    } catch (e) {
      if (mounted) _showToast('Failed to save data: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)))]),
        backgroundColor: isError ? ktRose : ktEmerald, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), duration: const Duration(seconds: 3)));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070B14),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF3299FF), surface: Color(0xFF0E1321)),
      ),
      child: Scaffold(
        appBar: _buildAppBar(),
        body: Stack(children: [
          Positioned.fill(child: _buildGlowEffect()),
          Positioned.fill(child: CustomPaint(painter: GridPainter())),
          ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 120), children: [
            const SizedBox(height: 20),
            _buildHeaderConfigCard(),
            const SizedBox(height: 40),
            ..._sections[_user]!.map(_buildSection),
          ]),
          if (_loading) Container(color: Colors.black54, child: const Center(child: CircularProgressIndicator(color: Color(0xFF3299FF)))),
        ]),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _loading ? null : _save,
          label: Text(_isEdit ? 'UPDATE MSI' : 'SAVE MSI', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          icon: const Icon(Icons.check_circle_outline),
          backgroundColor: const Color(0xFF3299FF),
        ),
      ),
    );
  }

  Widget _buildGlowEffect() => Container(
    decoration: const BoxDecoration(
      gradient: RadialGradient(center: Alignment(-0.8, -0.2), radius: 1.2, colors: [Color(0x153299FF), Colors.transparent]),
    ),
  );

  AppBar _buildAppBar() => AppBar(
    backgroundColor: const Color(0xFF0B1322), elevation: 0, toolbarHeight: 70,
    leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
    title: Row(children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.settings, color: Colors.white, size: 18)),
      const SizedBox(width: 12),
      const Text('MSI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
    ]),
    actions: [
      _actionIcon(Icons.pie_chart, () => Navigator.pushNamed(context, '/report/msi')),
      _actionIcon(Icons.home, () => Navigator.pushNamed(context, '/')),
      const SizedBox(width: 16),
    ],
  );

  Widget _actionIcon(IconData icon, VoidCallback onTap) => IconButton(icon: Icon(icon, color: Colors.white, size: 20), onPressed: onTap);

  Widget _buildHeaderConfigCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: _configItem('Select User', _buildUserDropdown())),
        const SizedBox(width: 16),
        Expanded(child: _configItem('Select Month', _buildMonthDropdown())),
        const SizedBox(width: 16),
        Expanded(child: _configItem('Select Year', _buildYearDropdown())),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: _configItem('Total Investment', _buildTotalDisplay())),
      ]),
    );
  }

  Widget _configItem(String label, Widget child) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w700)),
    const SizedBox(height: 10),
    child,
  ]);

  Widget _buildUserDropdown() => _selectorContainer(DropdownButtonHideUnderline(child: DropdownButton<String>(
    value: _user, dropdownColor: const Color(0xFF161C2C), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white24),
    items: const [DropdownMenuItem(value: 'Kalyan', child: Text('Kalyan')), DropdownMenuItem(value: 'Layan', child: Text('Layan'))],
    onChanged: (v) { if (v != null) { setState(() => _user = v); _loadDefaultsForUser(v); } },
  )));

  Widget _buildMonthDropdown() => _selectorContainer(DropdownButtonHideUnderline(child: DropdownButton<String>(
    value: _month, dropdownColor: const Color(0xFF161C2C), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white24),
    items: ktMonths.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
    onChanged: (v) { if (v != null) setState(() => _month = v); },
  )));

  Widget _buildYearDropdown() => _selectorContainer(DropdownButtonHideUnderline(child: DropdownButton<String>(
    value: _year, dropdownColor: const Color(0xFF161C2C), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600), isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white24),
    items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y))).toList(),
    onChanged: (v) { if (v != null) setState(() => _year = v); },
  )));

  Widget _buildTotalDisplay() => Container(
    height: 44, padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.08))),
    alignment: Alignment.centerLeft,
    child: Text(_fmt(_total), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
  );

  Widget _selectorContainer(Widget child) => Container(
    height: 44, padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: const Color(0xFF161C2C), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.08))),
    child: child,
  );

  Widget _buildSection(_FieldSpec section) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Icon(section.icon, color: Colors.white30, size: 20),
      const SizedBox(width: 12),
      Text(section.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
    ]),
    const SizedBox(height: 24),
    GridView.builder(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 16, crossAxisSpacing: 16, mainAxisExtent: 100),
      itemCount: section.fields.length,
      itemBuilder: (context, i) => _buildFundCard(section.fields[i]),
    ),
    const SizedBox(height: 40),
  ]);

  Widget _buildFundCard(_FieldItem fund) {
    final ctrl = _controllers[fund.key]!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0E1321), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(fund.label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
        const Spacer(),
        Container(
          height: 36, padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.white.withOpacity(0.04))),
          child: Row(children: [
            const Text('₹', style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: ctrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, fontFamily: 'monospace'),
              onChanged: (v) { setState(() {}); },
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
            )),
          ]),
        ),
      ]),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(color: const Color(0xFF0E1321), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.08)));
}

class _FieldSpec {
  const _FieldSpec({required this.title, required this.icon, required this.fields});
  final String title; final IconData icon; final List<_FieldItem> fields;
}

class _FieldItem {
  const _FieldItem(this.key, this.label);
  final String key; final String label;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 0.5;
    const double step = 20.0;
    for (double i = 0; i < size.width; i += step) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += step) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
