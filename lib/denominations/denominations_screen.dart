import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const _denomEndpoint =
    'https://script.google.com/macros/s/AKfycbyPA-Tg-g8MhrdMZPNIKFfNvU691amfVEd751V-PwVh7FmZm_HmPBiVhLSr8d25R1qUlg/exec';

const _bg = Color(0xFF080C14);
const _border = Color(0x1FFFFFFF);
const _text = Color(0xFFF1F5F9);
const _muted = Color(0xFF64748B);
const _primary = Color(0xFF6366F1);
const _panelBg = Color(0xCC141B33);
const _panelBg2 = Color(0xCC121A2F);
const _line = Color(0x2AFFFFFF);

class DenominationsScreen extends StatefulWidget {
  const DenominationsScreen({super.key});

  @override
  State<DenominationsScreen> createState() => _DenominationsScreenState();
}

class _DenominationsScreenState extends State<DenominationsScreen> {
  static const _notes = [500, 200, 100, 50, 20, 10];
  static const _coins = [5, 2, 1];

  final _weekCtrl = TextEditingController();
  final _adjustCtrl = TextEditingController();
  final _atmCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final Map<int, TextEditingController> _qtyCtrls = {
    for (final v in [..._notes, ..._coins]) v: TextEditingController(),
  };

  bool _loading = false;
  bool _argsApplied = false;
  bool _showAvailable = false;
  DateTime _selectedDate = DateTime.now();
  int? _editingRowIndex;
  double _previousBalance = 0;

  double _notesTotal = 0;
  double _coinsTotal = 0;
  double _grandTotal = 0;
  double _acPaid = 0;
  double _available = 0;

  @override
  void initState() {
    super.initState();
    for (final c in _qtyCtrls.values) {
      c.addListener(_recalc);
    }
    _weekCtrl.addListener(_recalc);
    _adjustCtrl.addListener(_recalc);
    _atmCtrl.addListener(_recalc);
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _fetchPreviousBalance());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsApplied) return;
    _argsApplied = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic>) {
      _applyEditPayload(args);
    }
  }

  @override
  void dispose() {
    _weekCtrl.dispose();
    _adjustCtrl.dispose();
    _atmCtrl.dispose();
    _remarksCtrl.dispose();
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _applyEditPayload(Map<String, dynamic> row) {
    _editingRowIndex = _toInt(row['rowIndex']);
    final dt = _parseFlexibleDate(row['Date']?.toString());
    if (dt != null) {
      _selectedDate = dt;
    }

    for (final v in [..._notes, ..._coins]) {
      _qtyCtrls[v]!.text = _toInt(row['$v']).toString();
    }

    _weekCtrl.text = _toDouble(row['Week Expenses']).toStringAsFixed(2);
    _adjustCtrl.text = _toDouble(row['Adjust Amount']).toStringAsFixed(2);
    _atmCtrl.text = _toDouble(row['ATM Withdrawal']).toStringAsFixed(2);
    _remarksCtrl.text = (row['Remarks'] ?? '').toString();
    _recalc();
    _fetchPreviousBalance();
  }

  int _toInt(Object? v) => int.tryParse('${v ?? 0}') ?? 0;

  double _toDouble(Object? v) => double.tryParse('${v ?? 0}') ?? 0;

  String _fmtCurrency(num amount, {bool decimal = false}) {
    final f = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '\u20B9',
      decimalDigits: decimal ? 2 : 0,
    );
    return f.format(amount);
  }

  String _fmtDateDisplay(DateTime d) => DateFormat('dd/MMM/yyyy').format(d);

  String _fmtDateIso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _sheetName(DateTime d) => DateFormat('MMM yyyy').format(d);

  DateTime? _parseFlexibleDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final txt = raw.trim();
    final direct = DateTime.tryParse(txt);
    if (direct != null) return DateTime(direct.year, direct.month, direct.day);

    for (final p in ['dd/MMM/yyyy', 'dd-MMM-yyyy', 'dd/MM/yyyy']) {
      try {
        final d = DateFormat(p).parseStrict(txt);
        return DateTime(d.year, d.month, d.day);
      } catch (_) {}
    }
    return null;
  }

  double _prevBalanceFromRow(Map<String, dynamic> row) {
    for (final e in row.entries) {
      final key = e.key.toLowerCase();
      if (key.contains('prev bal') ||
          key.contains('available balance') ||
          key.contains('avl bal') ||
          key.contains('closing')) {
        final n = _toDouble(e.value);
        if (n != 0) return n;
      }
    }
    return 0;
  }

  Future<void> _fetchPreviousBalance() async {
    final selected = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final uri = Uri.parse(
      '$_denomEndpoint?sheetName=${Uri.encodeComponent(_sheetName(_selectedDate))}',
    );

    try {
      final res = await http.get(uri);
      final payload = jsonDecode(res.body);
      final rowsRaw = (payload is Map)
          ? (payload['data'] ?? payload['reports'] ?? const [])
          : const [];
      final rows = (rowsRaw as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      Map<String, dynamic>? best;
      DateTime? bestDate;
      for (final row in rows) {
        final dt = _parseFlexibleDate(
            row['Date']?.toString() ?? row['date']?.toString());
        if (dt == null || !dt.isBefore(selected)) continue;
        if (bestDate == null || dt.isAfter(bestDate)) {
          bestDate = dt;
          best = row;
        }
      }

      setState(() {
        if (best != null) {
          _previousBalance = _prevBalanceFromRow(best);
        } else {
          _previousBalance =
              _toDouble((payload is Map) ? payload['sheet2Data'] : 0);
        }
      });
      _recalc();
    } catch (_) {
      setState(() => _previousBalance = 0);
      _recalc();
    }
  }

  void _recalc() {
    double notes = 0;
    double coins = 0;

    for (final v in _notes) {
      notes += v * _toInt(_qtyCtrls[v]!.text);
    }
    for (final v in _coins) {
      coins += v * _toInt(_qtyCtrls[v]!.text);
    }

    final grand = notes + coins;
    final week = _toDouble(_weekCtrl.text);
    final adjust = _toDouble(_adjustCtrl.text);
    final acPaid = (grand + adjust) - week;

    setState(() {
      _notesTotal = notes;
      _coinsTotal = coins;
      _grandTotal = grand;
      _acPaid = acPaid;
      _available = _previousBalance + acPaid;
    });
  }

  void _clearAll() {
    for (final c in _qtyCtrls.values) {
      c.clear();
    }
    _weekCtrl.clear();
    _adjustCtrl.clear();
    _atmCtrl.clear();
    _remarksCtrl.clear();
    _editingRowIndex = null;
    _recalc();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final payload = <String, dynamic>{
      'date': _editingRowIndex == null
          ? _fmtDateDisplay(_selectedDate)
          : _fmtDateIso(_selectedDate),
      'weekExpenses': _toDouble(_weekCtrl.text),
      'adjustAmount': _toDouble(_adjustCtrl.text),
      'atmWithdrawal': _toDouble(_atmCtrl.text),
      'acPaid': _acPaid,
      'remarks': _remarksCtrl.text.trim(),
      'd500': _toInt(_qtyCtrls[500]!.text),
      'd200': _toInt(_qtyCtrls[200]!.text),
      'd100': _toInt(_qtyCtrls[100]!.text),
      'd50': _toInt(_qtyCtrls[50]!.text),
      'd20': _toInt(_qtyCtrls[20]!.text),
      'd10': _toInt(_qtyCtrls[10]!.text),
      'd5': _toInt(_qtyCtrls[5]!.text),
      'd2': _toInt(_qtyCtrls[2]!.text),
      'd1': _toInt(_qtyCtrls[1]!.text),
      'total': _grandTotal.round(),
    };

    if (_editingRowIndex != null) {
      payload['action'] = 'update';
      payload['rowIndex'] = _editingRowIndex;
    }

    try {
      await http.post(
        Uri.parse(_denomEndpoint),
        headers: const {'Content-Type': 'text/plain'},
        body: jsonEncode(payload),
      );

      if (!mounted) return;
      final msg = _editingRowIndex == null
          ? 'Data saved successfully'
          : 'Data updated successfully';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

      if (_editingRowIndex == null) {
        _clearAll();
      } else {
        Navigator.pushReplacementNamed(context, '/report/denominations');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save data: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCalculator() async {
    String expr = '';
    String output = '0';

    double? evalExpr(String value) {
      final safe = value.replaceAll(' ', '');
      final token = RegExp(r'(-?\d+(?:\.\d+)?)|[+\-*/]');
      final tokens = token
          .allMatches(safe)
          .map((m) => m.group(0)!)
          .toList(growable: false);
      if (tokens.isEmpty) return null;

      final numbers = <double>[];
      final ops = <String>[];
      int i = 0;
      while (i < tokens.length) {
        final t = tokens[i];
        final n = double.tryParse(t);
        if (n != null) {
          numbers.add(n);
          i++;
          continue;
        }
        if (['*', '/'].contains(t) &&
            numbers.isNotEmpty &&
            i + 1 < tokens.length) {
          final r = double.tryParse(tokens[i + 1]);
          if (r == null) return null;
          final l = numbers.removeLast();
          numbers.add(t == '*' ? l * r : l / r);
          i += 2;
          continue;
        }
        ops.add(t);
        i++;
      }

      double acc = numbers.firstOrNull ?? 0;
      for (var j = 0; j < ops.length; j++) {
        if (j + 1 >= numbers.length) break;
        acc = ops[j] == '+' ? acc + numbers[j + 1] : acc - numbers[j + 1];
      }
      return acc;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInner) {
            void append(String t) {
              setInner(() {
                expr += t;
                output = expr;
              });
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0C111C),
              title: const Text('Calculator', style: TextStyle(color: _text)),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        output,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            color: _text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final key in [
                          '7',
                          '8',
                          '9',
                          '/',
                          '4',
                          '5',
                          '6',
                          '*',
                          '1',
                          '2',
                          '3',
                          '-',
                          '0',
                          '.',
                          'C',
                          '+'
                        ])
                          SizedBox(
                            width: 62,
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0x14FFFFFF),
                                foregroundColor: _text,
                              ),
                              onPressed: () {
                                if (key == 'C') {
                                  setInner(() {
                                    expr = '';
                                    output = '0';
                                  });
                                  return;
                                }
                                append(key);
                              },
                              child: Text(key),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    final result = evalExpr(expr);
                    if (result == null) {
                      setInner(() => output = 'Error');
                    } else {
                      setInner(() {
                        output = result.toStringAsFixed(
                            result.truncateToDouble() == result ? 0 : 2);
                        expr = output;
                      });
                    }
                  },
                  child: const Text('='),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalActive = [..._notes, ..._coins]
        .where((v) => _toInt(_qtyCtrls[v]!.text) > 0)
        .length;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned(
            left: -220,
            top: -120,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withValues(alpha: 0.22),
              ),
            ),
          ),
          Positioned(
            right: -180,
            bottom: -240,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEC4899).withValues(alpha: 0.16),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1360),
                  child: Column(
                    children: [
                      _buildTopHeader(),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, c) {
                          final isWide = c.maxWidth >= 1120;
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildNotesCoinsPanel(
                                    totalActive,
                                    crossAxisCount: 3,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 340,
                                  child: Column(
                                    children: [
                                      _buildTotalsCard(),
                                      const SizedBox(height: 12),
                                      _buildDetailsCard(),
                                      const SizedBox(height: 12),
                                      _buildActionButtons(),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              _buildNotesCoinsPanel(totalActive,
                                  crossAxisCount: 2),
                              const SizedBox(height: 12),
                              _buildTotalsCard(),
                              const SizedBox(height: 12),
                              _buildDetailsCard(),
                              const SizedBox(height: 12),
                              _buildActionButtons(),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
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

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
            ),
            child:
                const Icon(Icons.currency_rupee, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Denom's",
                    style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                Text('Denomination Manager',
                    style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Row(
            children: [
              _headerIcon(Icons.download_outlined,
                  () => Navigator.pushNamed(context, '/denominations/install')),
              _headerIcon(Icons.calculate_outlined, _openCalculator),
              _headerIcon(Icons.description_outlined,
                  () => Navigator.pushNamed(context, '/report/denominations')),
              _headerIcon(Icons.pie_chart,
                  () => Navigator.pushNamed(context, '/report/denominations')),
              _headerIcon(
                  Icons.home_filled, () => Navigator.pushNamed(context, '/')),
              _headerIcon(Icons.settings,
                  () => Navigator.pushNamed(context, '/settings')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _line),
          ),
          child: Icon(icon, size: 16, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildNotesCoinsPanel(int totalActive, {required int crossAxisCount}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: _panelBg2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: _primary.withValues(alpha: 0.45)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.payments_outlined,
                        size: 14, color: Color(0xFFA5B4FC)),
                    SizedBox(width: 8),
                    Text('NOTES & COINS',
                        style: TextStyle(
                            color: Color(0xFFA5B4FC),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Divider(color: _line, height: 1)),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('$totalActive active',
                    style: const TextStyle(
                        color: Color(0xFFA5B4FC),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: crossAxisCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.68,
            children: [
              for (final v in [..._notes, ..._coins]) _buildDenomCard(v),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateCard() {
    final today = DateTime.now();
    final canGoNext =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)
            .isBefore(DateTime(today.year, today.month, today.day));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _navCircleButton(
          icon: Icons.chevron_left,
          onTap: () {
            setState(() => _selectedDate =
                _selectedDate.subtract(const Duration(days: 1)));
            _fetchPreviousBalance();
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () {
              showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now())
                  .then((picked) {
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                  _fetchPreviousBalance();
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _line),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_fmtDateDisplay(_selectedDate),
                      style: const TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today,
                      color: Colors.white70, size: 16),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _navCircleButton(
          icon: Icons.chevron_right,
          onTap: canGoNext
              ? () {
                  setState(() => _selectedDate =
                      _selectedDate.add(const Duration(days: 1)));
                  _fetchPreviousBalance();
                }
              : null,
        ),
      ],
    );
  }

  Widget _navCircleButton(
      {required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF203A66)
                  .withValues(alpha: onTap == null ? 0.35 : 0.72),
              const Color(0xFF1A546A)
                  .withValues(alpha: onTap == null ? 0.35 : 0.72),
            ],
          ),
          border: Border.all(color: _line),
        ),
        child:
            Icon(icon, color: onTap == null ? Colors.white30 : Colors.white70),
      ),
    );
  }

  Widget _buildTotalsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          _buildDateCard(),
          const SizedBox(height: 14),
          const Text('Total Cash in Hand',
              style: TextStyle(
                  color: Color(0xFF97A3B6),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Text(
            _fmtCurrency(_grandTotal),
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Color(0xFFA5B4FC),
              height: 0.96,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _numberToWords(_grandTotal.toInt()),
            style: const TextStyle(color: _muted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Divider(color: _line, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _chip('Notes', _fmtCurrency(_notesTotal),
                      const Color(0xFFA5B4FC))),
              const SizedBox(width: 8),
              Expanded(
                  child: _chip('Coins', _fmtCurrency(_coinsTotal),
                      const Color(0xFFFBBF24))),
              const SizedBox(width: 8),
              Expanded(
                  child: _chip('A/C Paid', _fmtCurrency(_acPaid, decimal: true),
                      const Color(0xFF34D399))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF97A3B6),
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }

  LinearGradient _denomGradient(int value) {
    switch (value) {
      case 500:
        return const LinearGradient(
            colors: [Color(0xFF1A1000), Color(0xFF4A2E00)]);
      case 200:
        return const LinearGradient(
            colors: [Color(0xFF001A0D), Color(0xFF004422)]);
      case 100:
        return const LinearGradient(
            colors: [Color(0xFF000F29), Color(0xFF002A6E)]);
      case 50:
        return const LinearGradient(
            colors: [Color(0xFF1A0900), Color(0xFF4A2000)]);
      case 20:
        return const LinearGradient(
            colors: [Color(0xFF1A0000), Color(0xFF4A0808)]);
      case 10:
        return const LinearGradient(
            colors: [Color(0xFF001A00), Color(0xFF004400)]);
      case 5:
        return const LinearGradient(
            colors: [Color(0xFF111111), Color(0xFF333333)]);
      case 2:
        return const LinearGradient(
            colors: [Color(0xFF1A1000), Color(0xFF3E2B00)]);
      default:
        return const LinearGradient(
            colors: [Color(0xFF111111), Color(0xFF2A2A2A)]);
    }
  }

  Color _denomAccent(int value) {
    switch (value) {
      case 500:
        return const Color(0xFFFBBF24);
      case 200:
        return const Color(0xFF34D399);
      case 100:
        return const Color(0xFF60A5FA);
      case 50:
        return const Color(0xFFFB923C);
      case 20:
        return const Color(0xFFF87171);
      case 10:
        return const Color(0xFF86EFAC);
      case 5:
        return const Color(0xFFD4D4D4);
      case 2:
        return const Color(0xFFFCD34D);
      default:
        return const Color(0xFFA8A29E);
    }
  }

  Widget _buildDenomCard(int value) {
    final c = _qtyCtrls[value]!;
    final qty = _toInt(c.text);
    final active = qty > 0;
    final accent = _denomAccent(value);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: active
                ? _primary.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.17)),
        gradient: _denomGradient(value),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('$value',
              style: const TextStyle(
                  color: _text, fontWeight: FontWeight.w900, fontSize: 24)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stepButton(Icons.remove, () {
                final next = (qty - 1).clamp(0, 999999);
                c.text = '$next';
              }),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: c,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      color: _text, fontWeight: FontWeight.w800, fontSize: 16),
                  decoration: InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0x3AFFFFFF))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0x3AFFFFFF))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: _primary.withValues(alpha: 0.6))),
                    fillColor: Colors.black.withValues(alpha: 0.24),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    hintText: '0',
                    hintStyle: TextStyle(color: _muted),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _stepButton(Icons.add, () {
                c.text = '${qty + 1}';
              }),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            NumberFormat('#,##0', 'en_IN').format(qty * value),
            style: TextStyle(
                color: active ? accent : Colors.white38,
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 18, color: Colors.white70),
      ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: _panelBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.edit_note_rounded, color: Color(0xFFA5B4FC), size: 16),
              SizedBox(width: 6),
              Text('Additional Details',
                  style: TextStyle(color: _text, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _numField('WEEK EXPENSES', _weekCtrl)),
              const SizedBox(width: 10),
              Expanded(child: _numField('ADJUST AMOUNT', _adjustCtrl)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _numField('ATM WITHDRAWAL', _atmCtrl)),
              const SizedBox(width: 10),
              Expanded(child: _roField('A/C PAID', _acPaid.toStringAsFixed(2))),
            ],
          ),
          const SizedBox(height: 10),
          _roField(
            'AVAILABLE BALANCE',
            _showAvailable ? _fmtCurrency(_available, decimal: true) : '****',
            trailing: IconButton(
              onPressed: () => setState(() => _showAvailable = !_showAvailable),
              icon: Icon(
                  _showAvailable ? Icons.visibility : Icons.visibility_off,
                  color: _muted,
                  size: 18),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _remarksCtrl,
            minLines: 3,
            maxLines: 3,
            style: const TextStyle(color: _text),
            decoration: InputDecoration(
              hintText: 'Enter remarks...',
              hintStyle: const TextStyle(color: _muted),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.2),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: _line)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: _line)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: _text, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: const TextStyle(color: _muted),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: _line)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: _line)),
          ),
        ),
      ],
    );
  }

  Widget _roField(String label, String value, {Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _line),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(value,
                    style: const TextStyle(
                        color: Color(0xFFA5B4FC),
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _save,
            icon: const Icon(Icons.save),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A5DF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            label: Text(
                _editingRowIndex == null ? 'Save Record' : 'Update Record',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loading ? null : _clearAll,
            icon: const Icon(Icons.restart_alt),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFF87171),
              side: const BorderSide(color: Color(0x55EF4444)),
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              backgroundColor: const Color(0x22000000),
            ),
            label: const Text('Reset All',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  String _numberToWords(int value) {
    if (value <= 0) return 'Zero Rupees Only';
    const ones = [
      '',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
      'eleven',
      'twelve',
      'thirteen',
      'fourteen',
      'fifteen',
      'sixteen',
      'seventeen',
      'eighteen',
      'nineteen'
    ];
    const tens = [
      '',
      '',
      'twenty',
      'thirty',
      'forty',
      'fifty',
      'sixty',
      'seventy',
      'eighty',
      'ninety'
    ];

    String twoDigits(int n) {
      if (n < 20) return ones[n];
      return '${tens[n ~/ 10]}${n % 10 > 0 ? ' ${ones[n % 10]}' : ''}';
    }

    String threeDigits(int n) {
      final h = n ~/ 100;
      final rem = n % 100;
      final start = h > 0 ? '${ones[h]} Hundred' : '';
      final end = rem > 0 ? twoDigits(rem) : '';
      if (start.isNotEmpty && end.isNotEmpty) return '$start and $end';
      return '$start$end';
    }

    final crore = value ~/ 10000000;
    final lakh = (value % 10000000) ~/ 100000;
    final thousand = (value % 100000) ~/ 1000;
    final rest = value % 1000;

    final parts = <String>[];
    if (crore > 0) parts.add('${twoDigits(crore)} Crore');
    if (lakh > 0) parts.add('${twoDigits(lakh)} Lakh');
    if (thousand > 0) parts.add('${twoDigits(thousand)} Thousand');
    if (rest > 0) parts.add(threeDigits(rest));

    final rupeeWord = value == 1 ? 'Rupee' : 'Rupees';
    return '${parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim()} $rupeeWord Only';
  }
}
