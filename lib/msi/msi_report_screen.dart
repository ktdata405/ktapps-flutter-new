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
    'quantum_liquid': ['quantum_liquid', 'coin_quantum_liquid'],
    'navi_nifty': ['navi_nifty', 'coin_navi_nifty'],
    'invesco_small': ['invesco_small', 'coin_invesco_small'],
    'axis_nifty': ['axis_nifty', 'coin_axis_nifty'],
    'birla_nifty': ['birla_nifty', 'coin_birla_nifty'],
    'dsp_nifty': ['dsp_nifty', 'coin_dsp_nifty'],
    'edelweiss_bond': ['edelweiss_bond', 'coin_edelweiss_bond'],
    'canara_small': ['canara_small', 'coin_canara_small'],
    'quant_small': ['quant_small', 'coin_quant_small'],
    'birla_psu': ['birla_psu', 'coin_birla_psu'],
    'power_grid': ['power_grid', 'coin_power_grid'],
    'ppf': ['ppf', 'ppf_account'],
    'ssa': ['ssa', 'ssa_account'],
    'nps_tier1': ['nps_tier1'],
    'nps_tier2': ['nps_tier2'],
    'ind_jio_flexi': ['ind_jio_flexi'],
    'ind_bandhan_small': ['ind_bandhan_small'],
    'ind_ntpc_green': ['ind_ntpc_green'],
  };

  static const _platformsKalyan = {
    'coin': _Platform(
      'Zerodha Coin',
      Icons.monetization_on_outlined,
      Color(0xFF3B82F6),
      [
        'quantum_liquid',
        'navi_nifty',
        'invesco_small',
        'axis_nifty',
        'birla_nifty',
        'dsp_nifty',
        'edelweiss_bond'
      ],
    ),
    'groww': _Platform(
      'Groww',
      Icons.grass,
      Color(0xFF10B981),
      ['canara_small', 'quant_small', 'birla_psu', 'power_grid'],
    ),
    'govt': _Platform(
      'Govt. Schemes',
      Icons.account_balance_outlined,
      Color(0xFFF59E0B),
      ['ppf', 'ssa', 'nps_tier1', 'nps_tier2'],
    ),
  };

  static const _platformsLayan = {
    'indmoney': _Platform(
      'INDMoney',
      Icons.show_chart,
      Color(0xFF8B5CF6),
      ['ind_jio_flexi', 'ind_bandhan_small', 'ind_ntpc_green'],
    ),
  };

  bool _loading = true;
  bool _showTotal = false;
  String _user = 'Kalyan';
  int _tab = 0;
  int _monthIndex = -1;
  String _historyCategory = 'all';
  bool _historyOnlyData = false;
  bool _historyAsc = false;
  List<Map<String, dynamic>> _rows = [];

  Map<String, _Platform> get _activePlatforms =>
      _user == 'Layan' ? _platformsLayan : _platformsKalyan;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  String _currency(num amount, {int decimals = 0}) {
    return NumberFormat.currency(
            locale: 'en_IN', symbol: 'Rs. ', decimalDigits: decimals)
        .format(amount);
  }

  double _num(Object? v) => double.tryParse('${v ?? 0}') ?? 0;

  String _label(String key) {
    const labels = {
      'quantum_liquid': 'Quantum Liquid',
      'navi_nifty': 'Navi Nifty 50',
      'invesco_small': 'Invesco Small Cap',
      'axis_nifty': 'Axis Nifty 50',
      'birla_nifty': 'Birla Nifty 50',
      'dsp_nifty': 'DSP Nifty 50',
      'edelweiss_bond': 'Edelweiss Bond',
      'canara_small': 'Canara Small Cap',
      'quant_small': 'Quant Small Cap',
      'birla_psu': 'Birla PSU',
      'power_grid': 'Power Grid',
      'ppf': 'PPF',
      'ssa': 'SSA',
      'nps_tier1': 'NPS Tier 1',
      'nps_tier2': 'NPS Tier 2',
      'ind_jio_flexi': 'Jio Flexi',
      'ind_bandhan_small': 'Bandhan Small',
      'ind_ntpc_green': 'NTPC Green',
    };
    return labels[key] ?? key;
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);

    try {
      dynamic data = await _service.fetchReport();
      if (data is Map) {
        data = data['data'] ?? data['records'] ?? data['result'] ?? const [];
      }
      if (data is! List) throw Exception('Invalid data response');

      final rows = data
          .whereType<Map>()
          .map((e) => _normalize(Map<String, dynamic>.from(e)))
          .where((e) => e['month'] != null && e['year'] != null)
          .toList();

      rows.sort((a, b) {
        final av = (_toInt(a['year']) * 100) + ktMonths.indexOf(a['month'].toString());
        final bv = (_toInt(b['year']) * 100) + ktMonths.indexOf(b['month'].toString());
        return av.compareTo(bv);
      });

      setState(() {
        _rows = rows;
        _monthIndex = _rows.isEmpty ? -1 : _defaultMonthIndex(_rows);
        if (_historyCategory != 'all' &&
            !_activePlatforms.containsKey(_historyCategory)) {
          _historyCategory = 'all';
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Sync failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _toInt(Object? v) => int.tryParse('${v ?? 0}') ?? 0;

  int _defaultMonthIndex(List<Map<String, dynamic>> rows) {
    final now = DateTime.now();
    final m = DateFormat('MMM').format(now);
    final y = '${now.year}';
    final idx = rows.indexWhere((r) => r['month'] == m && '${r['year']}' == y);
    return idx == -1 ? rows.length - 1 : idx;
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> row) {
    final keys = row.keys.toList();

    dynamic find(String field) {
      final aliases = _aliases[field] ?? [field];
      for (final a in aliases) {
        if (row.containsKey(a)) return row[a];
        final lowA = a.toLowerCase();
        final exact = keys.firstWhere(
          (k) => k.toLowerCase() == lowA,
          orElse: () => '',
        );
        if (exact.isNotEmpty) return row[exact];

        final stripped = lowA.replaceAll(RegExp(r'[^a-z0-9]'), '');
        final normalized = keys.firstWhere(
          (k) =>
              k.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') == stripped,
          orElse: () => '',
        );
        if (normalized.isNotEmpty) return row[normalized];
      }
      return null;
    }

    final out = <String, dynamic>{
      'month': find('month'),
      'year': find('year'),
      'total_investment': find('total_investment'),
    };

    for (final p in _activePlatforms.values) {
      for (final f in p.fields) {
        out[f] = find(f) ?? 0;
      }
    }

    return out;
  }

  List<Map<String, dynamic>> _historyRows() {
    final rows = _historyAsc ? [..._rows] : _rows.reversed.toList();

    final entries = _historyCategory == 'all'
        ? _activePlatforms.entries
        : _activePlatforms.entries.where((e) => e.key == _historyCategory);

    if (_historyOnlyData) {
      return rows.where((row) {
        var total = 0.0;
        for (final e in entries) {
          for (final f in e.value.fields) {
            total += _num(row[f]);
          }
        }
        return total > 0;
      }).toList();
    }

    return rows;
  }

  double _rowTotal(Map<String, dynamic> row, {String? category}) {
    final entries = category == null
        ? _activePlatforms.entries
        : _activePlatforms.entries.where((e) => e.key == category);
    var total = 0.0;
    for (final e in entries) {
      for (final f in e.value.fields) {
        total += _num(row[f]);
      }
    }
    return total;
  }

  Future<void> _editMonth(Map<String, dynamic> row) async {
    final args = {...row, 'user': _user};
    await Navigator.pushNamed(context, '/msi', arguments: args);
    if (!mounted) return;
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ktBgDark,
      appBar: AppBar(
        backgroundColor: ktBgDark,
        title: const Text('MSI Report',
            style: TextStyle(color: ktTextWhite, fontWeight: FontWeight.w800)),
        iconTheme: const IconThemeData(color: ktTextWhite),
        actions: [
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh)),
          IconButton(
              onPressed: () => Navigator.pushNamed(context, '/msi'),
              icon: const Icon(Icons.add)),
          IconButton(
              onPressed: () => Navigator.pushNamed(context, '/'),
              icon: const Icon(Icons.home_outlined)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/msi'),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _heroCard(),
                  const SizedBox(height: 12),
                  _tabs(),
                  const SizedBox(height: 10),
                  if (_tab == 0) _overviewView(),
                  if (_tab == 1) _allTimeView(),
                  if (_tab == 2) _historyView(),
                  const SizedBox(height: 90),
                ],
              ),
            ),
    );
  }

  Widget _heroCard() {
    final total = _rows.fold<double>(0, (s, r) => s + _rowTotal(r));
    final monthRow = (_monthIndex >= 0 && _monthIndex < _rows.length)
        ? _rows[_monthIndex]
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ktBorderWhite10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Total Investments',
                  style: TextStyle(
                      color: ktTextGray400,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() => _showTotal = !_showTotal),
                icon: Icon(_showTotal ? Icons.visibility_off : Icons.visibility,
                    color: ktTextGray400),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _user,
                dropdownColor: ktCardBg,
                style: const TextStyle(color: ktTextWhite),
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 'Kalyan', child: Text('Kalyan')),
                  DropdownMenuItem(value: 'Layan', child: Text('Layan')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _user = v);
                  _fetch();
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _showTotal ? _currency(total) : '****',
            style: const TextStyle(
                color: ktTextWhite, fontSize: 34, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: (_monthIndex > 0)
                    ? () => setState(() => _monthIndex--)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                monthRow == null
                    ? '-'
                    : '${monthRow['month']} ${monthRow['year']}',
                style:
                    const TextStyle(color: ktTextWhite, fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: (_monthIndex >= 0 && _monthIndex < _rows.length - 1)
                    ? () => setState(() => _monthIndex++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
              const SizedBox(width: 8),
              if (monthRow != null)
                OutlinedButton.icon(
                  onPressed: () => _editMonth(monthRow),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: ktTextWhite,
                      side: const BorderSide(color: ktBorderWhite10)),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
            ],
          ),
          if (monthRow != null)
            Text(
              '${_currency(_rowTotal(monthRow))} invested',
              style: const TextStyle(color: ktTextGray400, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _tabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ktCardBg,
        border: Border.all(color: ktBorderWhite10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _tabBtn(0, 'This Month'),
          _tabBtn(1, 'All'),
          _tabBtn(2, 'History'),
        ],
      ),
    );
  }

  Widget _tabBtn(int idx, String text) {
    final active = _tab == idx;
    return Expanded(
      child: TextButton(
        onPressed: () => setState(() => _tab = idx),
        style: TextButton.styleFrom(
          backgroundColor: active ? ktPrimary : Colors.transparent,
          foregroundColor: active ? Colors.white : ktTextGray400,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _overviewView() {
    if (_monthIndex < 0 || _monthIndex >= _rows.length) {
      return const Center(
          child: Text('No data', style: TextStyle(color: ktTextGray400)));
    }
    return _platformCards(_rows[_monthIndex], 'Current Month');
  }

  Widget _allTimeView() {
    final totals = <String, double>{};
    for (final p in _activePlatforms.values) {
      for (final f in p.fields) {
        totals[f] = 0;
      }
    }

    for (final row in _rows) {
      for (final e in totals.entries.toList()) {
        totals[e.key] = (totals[e.key] ?? 0) + _num(row[e.key]);
      }
    }

    final obj = <String, dynamic>{
      for (final e in totals.entries) e.key: e.value
    };
    return _platformCards(obj, 'All Time Total');
  }

  Widget _platformCards(Map<String, dynamic> row, String periodText) {
    return Column(
      children: [
        for (final platform in _activePlatforms.values)
          Builder(
            builder: (context) {
              final fields = platform.fields
                  .map((f) => MapEntry(f, _num(row[f])))
                  .where((e) => e.value > 0)
                  .toList();
              final total = fields.fold<double>(0, (s, e) => s + e.value);
              if (total == 0) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ktCardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ktBorderWhite10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: platform.color.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(platform.icon, color: platform.color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(platform.name,
                              style: const TextStyle(
                                  color: ktTextWhite,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800)),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(periodText,
                                style: const TextStyle(
                                    color: ktTextGray400, fontSize: 11)),
                            Text(_currency(total),
                                style: TextStyle(
                                    color: platform.color,
                                    fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final e in fields)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(_label(e.key),
                                  style: const TextStyle(
                                      color: ktTextGray400, fontSize: 12)),
                            ),
                            Text(_currency(e.value),
                                style: const TextStyle(
                                    color: ktTextWhite, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _historyView() {
    final entries = _historyCategory == 'all'
        ? _activePlatforms.entries.toList()
        : _activePlatforms.entries
            .where((e) => e.key == _historyCategory)
            .toList();
    final rows = _historyRows();

    return Container(
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ktBorderWhite10),
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _historyCategoryChip('all', 'All'),
                for (final e in _activePlatforms.entries)
                  _historyCategoryChip(e.key, e.value.name),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _historyOnlyData ? 'available' : 'all',
                    dropdownColor: ktCardBg,
                    style: const TextStyle(color: ktTextWhite),
                    decoration: _inputDec('Data'),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Rows')),
                      DropdownMenuItem(
                          value: 'available', child: Text('With Data')),
                    ],
                    onChanged: (v) =>
                        setState(() => _historyOnlyData = v == 'available'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _historyAsc ? 'asc' : 'desc',
                    dropdownColor: ktCardBg,
                    style: const TextStyle(color: ktTextWhite),
                    decoration: _inputDec('Date'),
                    items: const [
                      DropdownMenuItem(
                          value: 'desc', child: Text('Newest First')),
                      DropdownMenuItem(
                          value: 'asc', child: Text('Oldest First')),
                    ],
                    onChanged: (v) => setState(() => _historyAsc = v == 'asc'),
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFF202024)),
              columns: [
                const DataColumn(
                    label: Text('Period', style: TextStyle(color: ktTextGray400))),
                const DataColumn(
                    label: Text('Total', style: TextStyle(color: ktTextGray400))),
                for (final p in entries)
                  for (final f in p.value.fields)
                    DataColumn(
                        label: Text(_label(f),
                            style:
                                TextStyle(color: p.value.color, fontSize: 11))),
              ],
              rows: rows.map((row) {
                final total = _historyCategory == 'all'
                    ? _rowTotal(row)
                    : _rowTotal(row, category: _historyCategory);
                return DataRow(cells: [
                  DataCell(Row(
                    children: [
                      Text('${row['month']} ${row['year']}',
                          style: const TextStyle(color: ktTextWhite)),
                      IconButton(
                        onPressed: () => _editMonth(row),
                        icon: const Icon(Icons.edit, size: 16, color: ktTextGray400),
                      ),
                    ],
                  )),
                  DataCell(Text(NumberFormat('#,##0', 'en_IN').format(total),
                      style: const TextStyle(
                          color: Color(0xFF7DD3FC),
                          fontWeight: FontWeight.w700))),
                  for (final p in entries)
                    for (final f in p.value.fields)
                      DataCell(Text(
                        NumberFormat('#,##0', 'en_IN').format(_num(row[f])),
                        style: TextStyle(
                          color: _num(row[f]) > 0
                              ? ktTextWhite
                              : const Color(0xFF52525B),
                          fontWeight: _num(row[f]) > 0
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      )),
                ]);
              }).toList(),
            ),
          ),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text('No records', style: TextStyle(color: ktTextGray400)),
            ),
        ],
      ),
    );
  }

  Widget _historyCategoryChip(String key, String label) {
    final active = _historyCategory == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        selected: active,
        label: Text(label),
        onSelected: (_) => setState(() => _historyCategory = key),
        selectedColor: const Color(0x2F6366F1),
        backgroundColor: const Color(0xFF151519),
        side: BorderSide(color: active ? ktPrimary : ktBorderWhite10),
        labelStyle: TextStyle(
            color: active ? ktTextWhite : ktTextGray400,
            fontSize: 12,
            fontWeight: FontWeight.w700),
      ),
    );
  }

  InputDecoration _inputDec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: ktTextGray400, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ktBorderWhite10)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ktBorderWhite10)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: ktPrimary)),
    );
  }
}

class _Platform {
  const _Platform(this.name, this.icon, this.color, this.fields);

  final String name;
  final IconData icon;
  final Color color;
  final List<String> fields;
}
