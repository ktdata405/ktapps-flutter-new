import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core_constants.dart';
import 'msi_service.dart';

class MsiReportScreen extends StatefulWidget {
  const MsiReportScreen({super.key});

  @override
  State<MsiReportScreen> createState() => _MsiReportScreenState();
}

class _MsiReportScreenState extends State<MsiReportScreen> {
  final _service = MsiService();

  static const _aliases = {
    'coin_quantum_liquid': ['coin_quantum_liquid', 'quantum_liquid', 'Quantum Liquid Debt Fund Max -10%'],
    'coin_navi_nifty': ['coin_navi_nifty', 'navi_nifty', 'Navi Nifty 50 Index Funds'],
    'coin_invesco_small': ['coin_invesco_small', 'invesco_small', 'Invesco India Small Cap Fund'],
    'coin_axis_nifty': ['coin_axis_nifty', 'axis_nifty', 'Axis Nifty 100 Index Fund'],
    'coin_birla_nifty': ['coin_birla_nifty', 'birla_nifty', 'Aditya Birla Sun Life Nifty 50 Index'],
    'coin_dsp_nifty': ['coin_dsp_nifty', 'dsp_nifty', 'DSP Nifty 50 Index Fund'],
    'coin_edelweiss_bond': ['coin_edelweiss_bond', 'edelweiss_bond', 'EdelWeiss Bharat Bond FOF - Apr 2031'],
    'coin_canara_small': ['coin_canara_small', 'canara_small', 'Canara Robeco Small Cap Fund Direct'],
    'coin_quant_small': ['coin_quant_small', 'quant_small', 'Quant Small Cap Fund Direct Plan[Lum-sum]'],
    'coin_birla_psu': ['coin_birla_psu', 'birla_psu', 'Aditya Birla Sun Life PSU Equity Direct[Lum-sum]'],
    'coin_power_grid': ['coin_power_grid', 'power_grid', 'Power Grid Corp(Stock)'],
    'ppf_account': ['ppf_account', 'ppf', 'PPF'],
    'ssa_account': ['ssa_account', 'ssa', 'Sukanya Samriddhi Account (SSA)'],
    'nps_tier1': ['nps_tier1', 'NPS TIER1', 'NPS Tier - 1'],
    'nps_tier2': ['nps_tier2', 'NPS TIER2', 'NPS Tier - 2'],
    'ind_jio_flexi': ['ind_jio_flexi', 'JioBlackRock Flexi Cap Fund'],
    'ind_bandhan_small': ['ind_bandhan_small', 'Bandhan Small Cap Fund'],
    'ind_ntpc_green': ['ind_ntpc_green', 'NTPC Green Stock'],
    'nj_dsp_midcap': ['nj_dsp_midcap', 'Dsp Midcap', 'DSP India Midcap', 'DSP Midcap Fund'],
    'nj_axis_midcap': ['nj_axis_midcap', 'Axis Midcap', 'Axis India Midcap', 'Axis Midcap Fund'],
    'nj_invesco_midcap': ['nj_invesco_midcap', 'Invesco Midcap', 'Invesco India Midcap Fund', 'Invesco'],
    'nj_kotak_emerging': ['nj_kotak_emerging', 'Kotak Emerging', 'Kotak Emerging Equity', 'Kotak'],
    'nj_nippon_growth': ['nj_nippon_growth', 'Nippon Growth', 'Nippon India Growth Fund', 'Nippon'],
  };

  static const _platformsKalyan = {
    'coin': _Platform('Zerodha Coin', Icons.currency_rupee, Color(0xFF3B82F6), ['coin_quantum_liquid', 'coin_navi_nifty', 'coin_invesco_small', 'coin_axis_nifty', 'coin_birla_nifty', 'coin_dsp_nifty', 'coin_edelweiss_bond']),
    'groww': _Platform('Groww', Icons.eco, Color(0xFF10B981), ['coin_canara_small', 'coin_quant_small', 'coin_birla_psu', 'coin_power_grid']),
    'govt': _Platform('Govt. Schemes', Icons.account_balance, Color(0xFFF59E0B), ['ppf_account', 'ssa_account', 'nps_tier1', 'nps_tier2']),
    'nj': _Platform('NJ Wealth', Icons.work, Color(0xFFEF4444), ['nj_dsp_midcap', 'nj_axis_midcap', 'nj_invesco_midcap', 'nj_kotak_emerging', 'nj_nippon_growth']),
  };

  static const _platformsLayan = {
    'indmoney': _Platform('INDMoney', Icons.show_chart, Color(0xFF8B5CF6), ['ind_jio_flexi', 'ind_bandhan_small', 'ind_ntpc_green']),
  };

  bool _loading = true;
  bool _showTotal = false;
  String _user = 'Kalyan';
  int _tab = 0; // 0=This Month, 1=All Time, 2=Transaction History
  int _monthIndex = -1;
  List<Map<String, dynamic>> _rows = [];
  final Set<String> _expandedPlatforms = {};

  Map<String, _Platform> get _activePlatforms => _user == 'Layan' ? _platformsLayan : _platformsKalyan;

  @override
  void initState() { super.initState(); _fetch(); }

  String _currency(num amount, {bool symbol = true, bool compact = false}) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: symbol ? 'Rs. ' : '', decimalDigits: 0);
    return compact ? NumberFormat('#,##0', 'en_IN').format(amount) : fmt.format(amount);
  }

  double _num(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(s) ?? 0;
  }

  String _label(String key) {
    const labels = {
      'coin_quantum_liquid': 'Quantum Liquid', 'coin_navi_nifty': 'Navi Nifty 50', 'coin_invesco_small': 'Invesco Small Cap', 'coin_axis_nifty': 'Axis Nifty 50', 'coin_birla_nifty': 'Birla Nifty 50', 'coin_dsp_nifty': 'DSP Nifty 50', 'coin_edelweiss_bond': 'Edelweiss Bond', 'coin_canara_small': 'Canara Small', 'coin_quant_small': 'Quant Small', 'coin_birla_psu': 'Birla Psu', 'coin_power_grid': 'Power Grid', 'ppf_account': 'PPF', 'ssa_account': 'SSA', 'nps_tier1': 'NPS TIER1', 'nps_tier2': 'NPS TIER2', 'ind_jio_flexi': 'Jio Flexi', 'ind_bandhan_small': 'Bandhan Small', 'ind_ntpc_green': 'NTPC Green', 'nj_dsp_midcap': 'Dsp Midcap', 'nj_axis_midcap': 'Axis Midcap', 'nj_invesco_midcap': 'Invesco Midcap', 'nj_kotak_emerging': 'Kotak Emerging', 'nj_nippon_growth': 'Nippon Growth',
    };
    if (labels.containsKey(key)) return labels[key]!;
    String s = key.replaceAll('coin_', '').replaceAll('ind_', '').replaceAll('_', ' ').trim();
    if (s.isEmpty) return key;
    return s.split(' ').map((w) => w.isEmpty ? '' : "${w[0].toUpperCase()}${w.substring(1)}").join(' ');
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      dynamic data = await _service.fetchReport();
      List<dynamic> list = [];
      if (data is Map) {
        list = data['data'] ?? data['records'] ?? data['result'] ?? data['rows'] ?? [];
      } else if (data is List) {
        list = data;
      }

      final normalizedRows = list.whereType<Map>().map((e) => _normalize(Map<String, dynamic>.from(e))).where((e) => e['month'] != null && e['year'] != null).toList();

      final allPlatforms = {..._platformsKalyan, ..._platformsLayan};
      final allKnownFields = allPlatforms.values.expand((p) => p.fields).toSet();
      
      final mergedMap = <String, Map<String, dynamic>>{};
      for (final r in normalizedRows) {
        final key = "${r['user_select']}_${r['month']}_${r['year']}".toLowerCase().trim();
        if (mergedMap.containsKey(key)) {
          final existing = mergedMap[key]!;
          for (final f in r.keys) {
            if (f == 'month' || f == 'year' || f == 'user_select' || f == 'total_investment') continue;
            final val = _num(r[f]);
            if (val > 0) existing[f] = (existing[f] ?? 0) + val;
          }
        } else {
          mergedMap[key] = Map<String, dynamic>.from(r);
        }
      }

      for (final r in mergedMap.values) {
        double total = 0;
        for (final f in allKnownFields) {
          total += _num(r[f]);
        }
        r['total_investment'] = total;
      }

      final finalRows = mergedMap.values.toList();
      finalRows.sort((a, b) {
        final ay = _toInt(a['year']), by = _toInt(b['year']);
        if (ay != by) return ay.compareTo(by);
        return ktMonths.indexOf(a['month'].toString()).compareTo(ktMonths.indexOf(b['month'].toString()));
      });

      setState(() { _rows = finalRows; _updateMonthIndex(); });
    } catch (e) {
      if (mounted) _showToast('Failed to load report: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _updateMonthIndex() {
    final userRows = _userRows();
    if (userRows.isEmpty) { _monthIndex = -1; return; }
    final now = DateTime.now();
    final m = ktMonths[now.month - 1], y = '${now.year}';
    final idx = userRows.indexWhere((r) => r['month'] == m && '${r['year']}' == y);
    final targetRow = idx == -1 ? userRows.last : userRows[idx];
    _monthIndex = _rows.indexOf(targetRow);
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 20), const SizedBox(width: 12), Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)))]),
        backgroundColor: isError ? ktRose : ktEmerald, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), duration: const Duration(seconds: 3)));
  }

  int _toInt(Object? v) => int.tryParse('${v ?? 0}') ?? 0;

  Map<String, dynamic> _normalize(Map<String, dynamic> row) {
    final keys = row.keys.toList();
    dynamic find(String field) {
      final aliases = _aliases[field] ?? [field];
      for (final a in aliases) {
        if (row.containsKey(a)) return row[a];
        final lowA = a.toLowerCase().trim();
        final exact = keys.firstWhere((k) => k.toLowerCase().trim() == lowA, orElse: () => '');
        if (exact.isNotEmpty) return row[exact];
        final fuzzyKey = keys.firstWhere((k) {
          final normK = k.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          final normA = lowA.replaceAll(RegExp(r'[^a-z0-9]'), '');
          return (normK.isNotEmpty && normA.isNotEmpty) && (normK.contains(normA) || normA.contains(normK));
        }, orElse: () => '');
        if (fuzzyKey.isNotEmpty) return row[fuzzyKey];
      }
      return null;
    }

    String? normMonth(dynamic m) {
      if (m == null) return null;
      if (m is int && m >= 1 && m <= 12) return ktMonths[m - 1];
      final s = m.toString().toLowerCase().trim();
      final lettersOnly = s.replaceAll(RegExp(r'[^a-z]'), '');
      if (lettersOnly.length >= 3) {
        final prefix = lettersOnly.substring(0, 3);
        for (final km in ktMonths) {
          if (km.toLowerCase() == prefix) {
            return km;
          }
        }
      }
      return null;
    }

    String? normYear(dynamic y) {
      if (y == null) return null;
      final match = RegExp(r'\b(20\d{2})\b').firstMatch(y.toString().trim());
      return match?.group(1);
    }

    final rawMonth = find('month') ?? find('Month') ?? find('MONTH') ?? find('Period') ?? find('PERIOD');
    final rawYear = find('year') ?? find('Year') ?? find('YEAR') ?? find('Period') ?? find('PERIOD');
    final out = <String, dynamic>{
      'month': normMonth(rawMonth), 'year': normYear(rawYear),
      'user_select': (find('user_select') ?? find('user') ?? find('User') ?? find('USER') ?? 'Kalyan').toString().trim(),
    };
    final allPlatforms = {..._platformsKalyan, ..._platformsLayan};
    for (final p in allPlatforms.values) {
      for (final f in p.fields) {
        out[f] = _num(find(f));
      }
    }
    return out;
  }

  List<Map<String, dynamic>> _userRows() {
    return _rows.where((r) {
      final u = r['user_select'].toString().toLowerCase().trim(), target = _user.toLowerCase();
      return u.isEmpty || u == target || u.startsWith(target.substring(0, 3)) || target.startsWith(u);
    }).toList();
  }

  double _rowTotal(Map<String, dynamic> row, {String? category}) {
    if (category == null) return _num(row['total_investment']);
    final platform = _activePlatforms[category];
    return platform == null ? 0 : platform.fields.fold<double>(0, (s, f) => s + _num(row[f]));
  }


  Future<void> _editMonth(Map<String, dynamic> row) async {
    await Navigator.pushNamed(context, '/msi', arguments: {...row, 'user': _user});
    if (mounted) _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070B14),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF3299FF), surface: Color(0xFF0E1321)),
      ),
      child: Scaffold(
        appBar: _buildTopBar(),
        body: _loading ? _buildLoader() : LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 750;
            return _buildBody(isMobile, constraints.maxWidth);
          }
        ),
      ),
    );
  }

  AppBar _buildTopBar() => AppBar(
    backgroundColor: Colors.transparent, elevation: 0, toolbarHeight: 80,
    title: Row(children: [
      const Icon(Icons.settings, color: Colors.white, size: 24),
      const SizedBox(width: 12),
      const Text('MSIReport', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.5)),
    ]),
    actions: [
      _actionIcon(Icons.refresh, _fetch),
      _actionIcon(Icons.home, () => Navigator.pushNamed(context, '/')),
      const SizedBox(width: 16),
    ],
  );

  Widget _actionIcon(IconData icon, VoidCallback onTap) => Container(
    margin: const EdgeInsets.only(left: 8),
    width: 40, height: 40,
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
    child: IconButton(icon: Icon(icon, color: Colors.white, size: 18), onPressed: onTap, padding: EdgeInsets.zero),
  );

  Widget _buildLoader() => const Center(child: CircularProgressIndicator(color: Color(0xFF3299FF)));

  Widget _buildBody(bool isMobile, double width) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 0, isMobile ? 16 : 24, 24),
      child: Column(children: [
        if (isMobile) ...[
          _buildHeroCard(isMobile),
          const SizedBox(height: 16),
          _buildControlCard(isMobile),
        ] else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 5, child: _buildHeroCard(isMobile)),
            const SizedBox(width: 24),
            Expanded(flex: 5, child: _buildControlCard(isMobile)),
          ]),
        const SizedBox(height: 32),
        if (_tab == 2) _buildTransactionHistory(isMobile)
        else _buildPlatformGrid(isMobile, width),
      ]),
    );
  }

  Widget _buildHeroCard(bool isMobile) {
    final total = _userRows().fold<double>(0, (s, r) => s + _rowTotal(r));
    return Container(
      height: isMobile ? 220 : 280,
      decoration: _cardDecoration(grid: true),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isMobile ? 24 : 32),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: GridPainter())),
          Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('TOTAL INVESTMENT', style: TextStyle(color: Colors.white30, fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const SizedBox(width: 16),
              _smallIconBtn(Icons.visibility_off_outlined, () => setState(() => _showTotal = !_showTotal)),
            ]),
            const SizedBox(height: 20),
            Text(_showTotal ? _currency(total) : 'Rs. ••,••,•••', style: TextStyle(color: Colors.white, fontSize: isMobile ? 36 : 48, fontWeight: FontWeight.w900, fontFamily: 'monospace', letterSpacing: -1)),
          ])),
        ]),
      ),
    );
  }

  Widget _buildControlCard(bool isMobile) {
    final userRows = _userRows();
    final monthRow = (_monthIndex >= 0 && _monthIndex < _rows.length) ? _rows[_monthIndex] : null;
    final currentIdx = monthRow != null ? userRows.indexOf(monthRow) : -1;

    return Container(
      height: isMobile ? null : 280, padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: _cardDecoration(),
      child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Select User', style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w700)),
          _buildUserDropdown(),
        ]),
        const SizedBox(height: 20),
        _buildTabSwitcher(isMobile),
        const SizedBox(height: 20),
        Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
             _navIcon(Icons.chevron_left, (currentIdx > 0) ? () => setState(() => _monthIndex = _rows.indexOf(userRows[currentIdx - 1])) : null),
             Container(
               width: 120, height: 44, alignment: Alignment.center,
               decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
               child: Text(monthRow != null ? "${monthRow['month']} ${monthRow['year']}" : "---", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
             ),
             _navIcon(Icons.chevron_right, (currentIdx >= 0 && currentIdx < userRows.length - 1) ? () => setState(() => _monthIndex = _rows.indexOf(userRows[currentIdx + 1])) : null),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _buildInvestedBadge(monthRow != null ? _rowTotal(monthRow) : 0),
          ]),
        ]),
      ]),
    );
  }

  Widget _buildTabSwitcher(bool isMobile) => Container(
    padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: const Color(0xFF161C2C), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
    child: Row(children: [
      _tabPill(0, 'Month', isMobile), _tabPill(1, 'All Time', isMobile), _tabPill(2, 'History', isMobile),
    ]),
  );

  Widget _tabPill(int idx, String label, bool isMobile) {
    final active = _tab == idx;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12), alignment: Alignment.center,
        decoration: BoxDecoration(color: active ? const Color(0xFF3299FF) : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: active ? [BoxShadow(color: const Color(0xFF3299FF).withValues(alpha: 0.2), blurRadius: 10)] : null),
        child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.white54, fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
      ),
    ));
  }

  Widget _buildPlatformGrid(bool isMobile, double width) {
    final monthRow = (_monthIndex >= 0 && _monthIndex < _rows.length) ? _rows[_monthIndex] : null;
    final allTimeTotals = <String, double>{};
    if (_tab == 1) {
      for (final r in _userRows()) {
        for (final k in r.keys) {
          if (k != 'month' && k != 'year' && k != 'user_select' && k != 'total_investment') {
            allTimeTotals[k] = (allTimeTotals[k] ?? 0) + _num(r[k]);
          }
        }
      }
    }
    final dataMap = _tab == 0 ? (monthRow ?? {}) : allTimeTotals;
    final platforms = _activePlatforms.values.toList();

    if (isMobile) {
      return Column(children: [
        for (final p in platforms) ...[
          _buildPlatformCard(p, dataMap, double.infinity),
          const SizedBox(height: 16),
        ]
      ]);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < platforms.length; i++)
            Padding(
              padding: EdgeInsets.only(right: i == platforms.length - 1 ? 0 : 24),
              child: _buildPlatformCard(platforms[i], dataMap, 360.0),
            ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard(_Platform platform, Map<String, dynamic> data, double width) {
    final total = platform.fields.fold<double>(0, (s, f) => s + _num(data[f]));
    final fundRows = platform.fields.map((f) => MapEntry(_label(f), _num(data[f]))).toList();
    final dotColors = [Colors.blue, Colors.red, Colors.green, Colors.amber, Colors.purple, Colors.orange, Colors.cyan, Colors.pink];
    final isExpanded = _expandedPlatforms.contains(platform.name);

    return Container(
      width: width, padding: const EdgeInsets.all(28), decoration: _cardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedPlatforms.remove(platform.name);
              } else {
                _expandedPlatforms.add(platform.name);
              }
            });
          },
          behavior: HitTestBehavior.opaque,
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: platform.color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: Icon(platform.icon, color: platform.color, size: 24)),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(platform.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                Text(_tab == 0 ? 'Current Month' : 'All Time Total', style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ]),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_currency(total, symbol: true), style: TextStyle(color: platform.color, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
              Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white30, size: 18),
            ]),
          ]),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 28),
          for (int i = 0; i < fundRows.length; i++) Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColors[i % dotColors.length])),
              const SizedBox(width: 14),
              Expanded(child: Text(fundRows[i].key, style: TextStyle(color: fundRows[i].value > 0 ? platform.color : Colors.white24, fontSize: 13, fontWeight: FontWeight.w700))),
              Text(fundRows[i].value > 0 ? NumberFormat('#,##0').format(fundRows[i].value) : '-', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildTransactionHistory(bool isMobile) {
    final rows = _historyRows();
    if (_rows.isEmpty) return const Center(child: Text('No History Available'));
    
    if (isMobile) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('HISTORY', style: TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
        const SizedBox(height: 20),
        for (final r in rows) _buildTransactionCard(r),
      ]);
    }

    final platforms = _activePlatforms.values.toList();
    final allFields = platforms.expand((p) => p.fields).toList();

    return Container(
      width: double.infinity, decoration: _cardDecoration(), padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
             _filterChip('All', true),
             for (final p in platforms) _filterChip(p.name, false),
          ]),
        ),
        const SizedBox(height: 32),
        Row(children: [
           const Text('DATA  ', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900)),
           _smallDrop('All Rows'),
           const SizedBox(width: 24),
           const Text('DATE  ', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900)),
           _smallDrop('Newest First'),
        ]),
        const SizedBox(height: 40),
        SingleChildScrollView(scrollDirection: Axis.horizontal, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _th('PERIOD', 160), _th('TOTAL', 120),
            for (final p in platforms) _thPlatform(p),
          ]),
          Row(children: [
            _th('', 160), _th('', 120),
            for (final f in allFields) _thField(_label(f)),
          ]),
          const SizedBox(height: 12),
          for (final r in rows) Container(
            margin: const EdgeInsets.only(bottom: 1), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03)))),
            child: Row(children: [
              _tdPeriod(r), _tdTotal(_rowTotal(r)),
              ...allFields.asMap().entries.map((e) => _tdNum(_num(r[e.value]), e.key)),
            ]),
          ),
        ])),
      ]),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> r) {
    final total = _rowTotal(r);
    return GestureDetector(
      onTap: () => _showHistoryDetailsSheet(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("${r['month']} ${r['year']}", style: const TextStyle(color: Color(0xFF3299FF), fontSize: 16, fontWeight: FontWeight.w900)),
              const Text('Investment Period', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          ]),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.white10)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('TOTAL AMOUNT', style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            Text(_currency(total), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
          ]),
        ]),
      ),
    );
  }

  void _showHistoryDetailsSheet(Map<String, dynamic> r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF0E1321),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("${r['month']} ${r['year']}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const Text('Investment Breakdown', style: TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.w700)),
              ]),
              Text(_currency(_rowTotal(r)), style: const TextStyle(color: Color(0xFF3299FF), fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              children: [
                for (final entry in _activePlatforms.entries) ...[
                  if (_rowTotal(r, category: entry.key) > 0)
                    _buildPlatformSummaryItem(entry.value, r, entry.key),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
            child: Row(children: [
              Expanded(child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 13)),
                ),
              )),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _editMonth(r);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3299FF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.edit_document, color: Colors.white, size: 18),
                  label: const Text('EDIT RECORD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 13)),
                ),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildPlatformSummaryItem(_Platform platform, Map<String, dynamic> data, String categoryKey) {
    final total = _rowTotal(data, category: categoryKey);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(platform.icon, color: platform.color, size: 18),
          const SizedBox(width: 12),
          Text(platform.name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          const Spacer(),
          Text(_currency(total), style: TextStyle(color: platform.color, fontSize: 14, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
        ]),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white10, height: 1)),
        for (final field in platform.fields)
          if (_num(data[field]) > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(child: Text(_label(field), style: const TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(_currency(_num(data[field]), symbol: false), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
              ]),
            ),
      ]),
    );
  }


  Widget _buildUserDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    decoration: BoxDecoration(color: const Color(0xFF161C2C), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: _user, dropdownColor: const Color(0xFF161C2C), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700), icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white30),
      items: const [DropdownMenuItem(value: 'Kalyan', child: Text('Kalyan')), DropdownMenuItem(value: 'Layan', child: Text('Layan'))],
      onChanged: (v) { if (v != null) setState(() { _user = v; _updateMonthIndex(); }); },
    )),
  );

  Widget _buildInvestedBadge(double amount) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
    child: Row(children: [
      const Icon(Icons.layers_rounded, color: Color(0xFF3299FF), size: 14),
      const SizedBox(width: 10),
      Text(_currency(amount), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
      const SizedBox(width: 8),
      const Text('Invested', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w700)),
    ]),
  );

  List<Map<String, dynamic>> _historyRows() {
    final filtered = _userRows();
    final rows = _historyAsc ? [...filtered] : filtered.reversed.toList();
    return rows;
  }

  bool get _historyAsc => false;

  Widget _thPlatform(_Platform p) => Container(
    width: (p.fields.length * 150.0), height: 40, alignment: Alignment.center,
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.05)), bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)))),
    child: Text(p.name.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
  );

  Widget _thField(String label) => Container(width: 150, padding: const EdgeInsets.all(12), alignment: Alignment.center, child: Text(label.toUpperCase(), style: const TextStyle(color: Colors.white12, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)));

  Widget _th(String label, double width) => Container(width: width, padding: const EdgeInsets.all(16), alignment: Alignment.centerLeft, child: Text(label, style: const TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)));

  Widget _tdPeriod(Map<String, dynamic> r) => Container(width: 160, padding: const EdgeInsets.all(16), child: Row(children: [
    Text("${r['month']} ${r['year']}", style: const TextStyle(color: Color(0xFF3299FF), fontSize: 13, fontWeight: FontWeight.w800)),
  ]));

  Widget _tdTotal(double total) => Container(width: 120, padding: const EdgeInsets.all(16), alignment: Alignment.center, child: Text(NumberFormat('#,##0').format(total), style: const TextStyle(color: Color(0xFF3299FF), fontWeight: FontWeight.w900, fontSize: 14, fontFamily: 'monospace')));

  Widget _tdNum(double val, int index) {
    final colors = [
      const Color(0xFF60A5FA), // Blue
      const Color(0xFF34D399), // Emerald
      const Color(0xFFFBBF24), // Amber
      const Color(0xFFF472B6), // Pink
      const Color(0xFFA78BFA), // Violet
      const Color(0xFF2DD4BF), // Teal
      const Color(0xFFFB7185), // Rose
    ];
    final textColor = val > 0 ? colors[index % colors.length] : Colors.white.withValues(alpha: 0.03);
    return Container(
      width: 150, padding: const EdgeInsets.all(16), alignment: Alignment.center,
      child: Text(
        val > 0 ? NumberFormat('#,##0').format(val) : '-',
        style: TextStyle(color: textColor, fontWeight: FontWeight.w800, fontSize: 13, fontFamily: 'monospace'),
      ),
    );
  }

  Widget _filterChip(String label, bool active) => Container(
    margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(color: active ? const Color(0xFF1E2638) : Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: active ? const Color(0xFF3299FF).withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05))),
    child: Text(label, style: TextStyle(color: active ? Colors.white : Colors.white24, fontSize: 11, fontWeight: FontWeight.w800)),
  );

  Widget _smallDrop(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFF161C2C), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
    child: Row(children: [Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)), const SizedBox(width: 12), const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.white30)]),
  );

  BoxDecoration _cardDecoration({bool grid = false}) => BoxDecoration(
    color: const Color(0xFF0E1321), borderRadius: BorderRadius.circular(32), border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 20))],
  );

  Widget _smallIconBtn(IconData icon, VoidCallback? onTap) => GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.05))), child: Icon(icon, color: Colors.white54, size: 18)));
  Widget _navIcon(IconData icon, VoidCallback? onTap) => IconButton(icon: Icon(icon, color: onTap == null ? Colors.white10 : Colors.white, size: 22), onPressed: onTap);
}

class _Platform {
  const _Platform(this.name, this.icon, this.color, this.fields);
  final String name; final IconData icon; final Color color; final List<String> fields;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.03)..strokeWidth = 0.5;
    const double step = 20.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
