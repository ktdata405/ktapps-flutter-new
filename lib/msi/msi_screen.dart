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
  String _user = 'Kalyan';
  late String _month;
  late String _year;

  late final Map<String, TextEditingController> _controllers;
  final _service = MsiService();

  static final Map<String, Map<String, double>> _defaults = {
    'Kalyan': {
      'coin_quantum_liquid': 1331,
      'coin_navi_nifty': 1331,
      'coin_invesco_small': 1331,
      'coin_axis_nifty': 1331,
      'coin_birla_nifty': 1331,
      'coin_dsp_nifty': 1331,
      'coin_edelweiss_bond': 1331,
      'coin_canara_small': 6050,
      'coin_quant_small': 0,
      'coin_birla_psu': 0,
      'coin_power_grid': 0,
      'nps_tier1': 5500,
      'nps_tier2': 0,
      'ssa_account': 2500,
      'ppf_account': 10000,
    },
    'Layan': {
      'ind_jio_flexi': 0,
      'ind_bandhan_small': 0,
      'ind_ntpc_green': 0,
    },
  };

  static final Map<String, List<_FieldSpec>> _sections = {
    'Kalyan': [
      _FieldSpec(
        title: 'Coin',
        icon: Icons.monetization_on_outlined,
        fields: [
          _FieldItem(
              'coin_quantum_liquid', 'Quantum Liquid Debt Fund Max -10%'),
          _FieldItem('coin_navi_nifty', 'Navi Nifty 50 Index Funds'),
          _FieldItem('coin_invesco_small', 'Invesco India Small Cap Fund'),
          _FieldItem('coin_axis_nifty', 'Axis Nifty 100 Index Fund'),
          _FieldItem(
              'coin_birla_nifty', 'Aditya Birla Sun Life Nifty 50 Index'),
          _FieldItem('coin_dsp_nifty', 'DSP Nifty 50 Index Fund'),
          _FieldItem(
              'coin_edelweiss_bond', 'EdelWeiss Bharat Bond FOF - Apr 2031'),
        ],
      ),
      _FieldSpec(
        title: 'Groww',
        icon: Icons.grass,
        fields: [
          _FieldItem(
              'coin_canara_small', 'Canara Robeco Small Cap Fund Direct'),
          _FieldItem(
              'coin_quant_small', 'Quant Small Cap Fund Direct Plan[Lum-sum]'),
          _FieldItem('coin_birla_psu',
              'Aditya Birla Sun Life PSU Equity Direct[Lum-sum]'),
          _FieldItem('coin_power_grid', 'Power Grid Corp(Stock)'),
        ],
      ),
      _FieldSpec(
        title: 'Govt Investments',
        icon: Icons.account_balance_outlined,
        fields: [
          _FieldItem('nps_tier1', 'NPS Tier - 1'),
          _FieldItem('nps_tier2', 'NPS Tier - 2'),
          _FieldItem('ssa_account', 'Sukanya Samriddhi Account (SSA)'),
          _FieldItem('ppf_account', 'PPF'),
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
    'quantum_liquid': 'coin_quantum_liquid',
    'navi_nifty': 'coin_navi_nifty',
    'invesco_small': 'coin_invesco_small',
    'axis_nifty': 'coin_axis_nifty',
    'birla_nifty': 'coin_birla_nifty',
    'dsp_nifty': 'coin_dsp_nifty',
    'edelweiss_bond': 'coin_edelweiss_bond',
    'canara_small': 'coin_canara_small',
    'quant_small': 'coin_quant_small',
    'birla_psu': 'coin_birla_psu',
    'power_grid': 'coin_power_grid',
    'ssa': 'ssa_account',
    'ppf': 'ppf_account',
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = ktMonths[now.month - 1];
    _year = '${now.year}';
    _controllers = {
      for (final field in _allKeys) field: TextEditingController(),
    };
    _loadDefaultsForUser(_user);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    _argsApplied = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _applyEditData(args);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  static Iterable<String> get _allKeys => _sections.values
      .expand((s) => s)
      .expand((s) => s.fields)
      .map((f) => f.key);

  void _loadDefaultsForUser(String user) {
    final defaults = _defaults[user] ?? const <String, double>{};
    for (final c in _controllers.values) {
      c.clear();
    }
    for (final e in defaults.entries) {
      _controllers[e.key]!.text =
          e.value == 0 ? '' : e.value.toStringAsFixed(2);
    }
    setState(() {});
  }

  void _applyEditData(Map<String, dynamic> row) {
    final userArg = (row['user'] ?? row['user_select'] ?? '').toString();
    if (userArg == 'Kalyan' || userArg == 'Layan') {
      _user = userArg;
    }

    _month = (row['month'] ?? _month).toString();
    _year = (row['year'] ?? _year).toString();

    _loadDefaultsForUser(_user);

    for (final entry in row.entries) {
      final source = entry.key;
      final key = _editMapping[source] ?? source;
      final ctrl = _controllers[key];
      if (ctrl == null) continue;
      final n = double.tryParse('${entry.value}');
      if (n != null) ctrl.text = n == 0 ? '' : n.toStringAsFixed(2);
    }
  }

  String _sanitize(String input) {
    final clean = input.replaceAll(RegExp(r'[^\d.]'), '');
    final parts = clean.split('.');
    if (parts.length <= 1) return clean;
    return '${parts.first}.${parts.skip(1).join()}';
  }

  double _parse(String value) =>
      double.tryParse(value.replaceAll(',', '')) ?? 0;

  String _fmtIn(double value) => NumberFormat.currency(
        locale: 'en_IN',
        symbol: '\u20B9',
        decimalDigits: 2,
      ).format(value);

  List<_FieldItem> get _activeFields =>
      _sections[_user]!.expand((s) => s.fields).toList();

  double get _total {
    var total = 0.0;
    for (final f in _activeFields) {
      total += _parse(_controllers[f.key]!.text);
    }
    return total;
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final body = <String, dynamic>{
      'month': _month,
      'year': _year,
      'user_select': _user,
    };
    for (final f in _activeFields) {
      body[f.key] = _parse(_controllers[f.key]!.text);
    }

    try {
      await _service.saveData(body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Investment details saved for $_month $_year ($_user).')),
      );
      Navigator.pushReplacementNamed(context, '/report/msi');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ktBgDark,
      appBar: AppBar(
        backgroundColor: ktCardBg,
        title: const Text('MSI',
            style: TextStyle(color: ktTextWhite, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: ktTextWhite),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/report/msi'),
            icon: const Icon(Icons.pie_chart_outline),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/'),
            icon: const Icon(Icons.home_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(14),
            children: [
              _topControlCard(),
              const SizedBox(height: 16),
              ..._sections[_user]!.map(_sectionCard),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _save,
                  icon: const Icon(Icons.save),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ktPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99)),
                  ),
                  label: const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
          if (_loading)
            Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _topControlCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ktBorderWhite10),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _dropdownCard(
            label: 'Select User',
            child: DropdownButton<String>(
              value: _user,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: ktTextWhite),
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 'Kalyan', child: Text('Kalyan')),
                DropdownMenuItem(value: 'Layan', child: Text('Layan')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _user = v);
                _loadDefaultsForUser(v);
              },
            ),
          ),
          _dropdownCard(
            label: 'Select Month',
            child: DropdownButton<String>(
              value: _month,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: ktTextWhite),
              underline: const SizedBox.shrink(),
              items: ktMonths
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _month = v ?? _month),
            ),
          ),
          _dropdownCard(
            label: 'Select Year',
            child: DropdownButton<String>(
              value: _year,
              isExpanded: true,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: ktTextWhite),
              underline: const SizedBox.shrink(),
              items: _years
                  .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                  .toList(),
              onChanged: (v) => setState(() => _year = v ?? _year),
            ),
          ),
          Container(
            width: 200,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ktBorderWhite10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Investment',
                    style: TextStyle(
                        color: ktTextGray400,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(_fmtIn(_total),
                    style: const TextStyle(
                        color: ktTextWhite,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownCard({required String label, required Widget child}) {
    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ktBorderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: ktTextGray400, fontSize: 12, fontWeight: FontWeight.w700)),
          child,
        ],
      ),
    );
  }

  Widget _sectionCard(_FieldSpec section) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, color: ktPrimary, size: 18),
              const SizedBox(width: 8),
              Text(section.title,
                  style: const TextStyle(
                      color: ktPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 17)),
            ],
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              mainAxisExtent: 120,
            ),
            itemCount: section.fields.length,
            itemBuilder: (context, i) {
              final f = section.fields[i];
              final ctrl = _controllers[f.key]!;
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ktCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ktBorderWhite10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.label,
                        style: const TextStyle(
                            color: ktTextWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: ctrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                          color: ktTextWhite, fontWeight: FontWeight.w700),
                      onChanged: (v) {
                        final next = _sanitize(v);
                        if (next != v) {
                          ctrl.value = TextEditingValue(
                            text: next,
                            selection:
                                TextSelection.collapsed(offset: next.length),
                          );
                        }
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        prefixText: '\u20B9 ',
                        prefixStyle: const TextStyle(color: ktTextGray400),
                        hintText: '0.00',
                        hintStyle: const TextStyle(color: ktTextGray400),
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.25),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: ktBorderWhite10)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: ktBorderWhite10)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: ktPrimary)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FieldSpec {
  const _FieldSpec(
      {required this.title, required this.icon, required this.fields});

  final String title;
  final IconData icon;
  final List<_FieldItem> fields;
}

class _FieldItem {
  const _FieldItem(this.key, this.label);

  final String key;
  final String label;
}
