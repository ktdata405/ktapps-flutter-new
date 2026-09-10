import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../core_constants.dart';
import '../core_utils.dart';
import '../core_ui_utils.dart';
import 'denominations_service.dart';
import 'denoms_keyboard.dart';

class DenominationsScreen extends StatefulWidget {
  const DenominationsScreen({super.key});

  @override
  State<DenominationsScreen> createState() => _DenominationsScreenState();
}

class _DenominationsScreenState extends State<DenominationsScreen> {
  final _service = DenominationsService();
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
  int _uiType = 0;
  int? _focusedDenomIndex;
  DateTime _selectedDate = getIndiaTime();
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
    _loadUiType();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _fetchPreviousBalance(),
    );
  }

  Future<void> _loadUiType() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _uiType = prefs.getInt('denominations_ui_type') ?? 0;
    });
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

  String _fmtDateDisplay(DateTime d) => ktFormatDate(d);

  String _fmtDateIso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String _sheetName(DateTime d) => DateFormat('MMM yyyy').format(d);

  DateTime? _parseFlexibleDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final txt = raw.trim();
    final direct = DateTime.tryParse(txt);
    if (direct != null) {
      final dt = direct.toLocal();
      return DateTime(dt.year, dt.month, dt.day);
    }

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

    try {
      final payload = await _service.fetchSheetData(_sheetName(_selectedDate));
      final rowsRaw = payload['data'] ?? payload['reports'] ?? const [];
      final rows =
          rowsRaw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

      Map<String, dynamic>? best;
      DateTime? bestDate;
      for (final row in rows) {
        final dt = _parseFlexibleDate(
          row['Date']?.toString() ?? row['date']?.toString(),
        );
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
          _previousBalance = _toDouble(payload['sheet2Data']);
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
      'date':
          _editingRowIndex == null
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
      await _service.saveData(payload);

      if (!mounted) return;
      final msg =
          _editingRowIndex == null
              ? KtStrings.dataSaved
              : KtStrings.dataUpdated;
      ktShowCustomToast(context, msg);

      if (_editingRowIndex == null) {
        _clearAll();
      } else {
        Navigator.pushReplacementNamed(context, '/report/denominations');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${KtStrings.saveFailed}: $e')));
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
              backgroundColor: ktDarkBlue,
              title: const Text(KtStrings.calculator, style: TextStyle(color: ktTextWhite)),
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
                        border: Border.all(color: ktBorderWhite10),
                      ),
                      child: Text(
                        output,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: ktTextWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
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
                          '+',
                        ])
                          SizedBox(
                            width: 62,
                            height: 44,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0x14FFFFFF),
                                foregroundColor: ktTextWhite,
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
                          result.truncateToDouble() == result ? 0 : 2,
                        );
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
    final totalActive =
        [
          ..._notes,
          ..._coins,
        ].where((v) => _toInt(_qtyCtrls[v]!.text) > 0).length;

    return Scaffold(
      backgroundColor: ktBgDark,
      resizeToAvoidBottomInset: false, // Prevents keyboard from pushing up and causing overflow
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
                color: ktPrimary.withValues(alpha: 0.22),
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
                color: ktPink.withValues(alpha: 0.16),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(12, 6, 12, _focusedDenomIndex != null ? 350 : 20),
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
                                      if (_uiType != 2) _buildTotalsCard(),
                                      const SizedBox(height: 12),
                                      _buildDetailsCard(),
                                      const SizedBox(height: 12),
                                      _buildDateCard(), // Date moved here
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
                              _buildNotesCoinsPanel(
                                totalActive,
                                crossAxisCount: 2,
                              ),
                              const SizedBox(height: 12),
                              if (_uiType != 2) ...[
                                _buildTotalsCard(),
                                const SizedBox(height: 12),
                              ],
                              _buildDetailsCard(),
                              const SizedBox(height: 12),
                              _buildDateCard(), // Date moved here
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
          if (_focusedDenomIndex != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: DenomsKeyboard(
                currentDenom: [..._notes, ..._coins][_focusedDenomIndex!].toString(),
                currentCount: _qtyCtrls[[..._notes, ..._coins][_focusedDenomIndex!]]!.text,
                onUp: _handleKeyboardUp,
                onDown: _handleKeyboardDown,
                onKeyPress: _handleKeyboardKeyPress,
                onClear: _handleKeyboardClear,
                onBackspace: _handleKeyboardBackspace,
                onIncrement: _handleKeyboardIncrement,
                onDone: () => setState(() => _focusedDenomIndex = null),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _uiType == 1 ? _buildFooterSecondUI() : null,
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _uiType == 1 ? const Color(0xFFFF5722) : ktCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _uiType == 1 ? Colors.transparent : ktPanelBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: _uiType == 1 ? null : const LinearGradient(
                colors: [ktPrimary, ktViolet],
              ),
              color: _uiType == 1 ? Colors.white.withValues(alpha: 0.2) : null,
            ),
            child: const Icon(
              Icons.currency_rupee,
              color: ktWhite,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  KtStrings.denominationsTitle,
                  style: TextStyle(
                    color: ktTextWhite,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  KtStrings.denominationManager,
                  style: TextStyle(
                    color: ktTextGray500,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 6,
                runSpacing: 6,
                children: [
                  ktHeaderIcon(Icons.calculate_outlined, _openCalculator),
                  ktHeaderIcon(
                    Icons.bar_chart,
                    () => Navigator.pushNamed(context, '/report/denominations'),
                  ),
                  ktHeaderIcon(
                    Icons.home_filled,
                    () => Navigator.pushNamed(context, '/'),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildNotesCoinsPanel(int totalActive, {required int crossAxisCount}) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final baseAspect = crossAxisCount == 2 ? 1.34 : 1.5;
    final adjustedAspect = (baseAspect - ((textScale - 1) * 0.22)).clamp(
      1.12,
      1.6,
    );

    return Container(
      padding: _uiType == 2 ? EdgeInsets.zero : const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: _uiType == 2 ? Colors.transparent : ktCardBg,
        borderRadius: BorderRadius.circular(18),
        border: _uiType == 2 ? null : Border.all(color: ktPanelBorder),
      ),
      child: Column(
        children: [
          if (_uiType != 2)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: ktPrimary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: ktPrimary.withValues(alpha: 0.45)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 14,
                        color: ktIndigo300,
                      ),
                      SizedBox(width: 8),
                      Text(
                        KtStrings.notesAndCoins,
                        style: TextStyle(
                          color: ktIndigo300,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: ktPrimary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$totalActive active',
                    style: const TextStyle(
                      color: Color(0xFFA5B4FC),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          if (_uiType == 0)
            GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: adjustedAspect,
              children: [
                for (final v in [..._notes, ..._coins]) _buildDenomCard(v),
              ],
            )
          else if (_uiType == 1)
            Column(
              children: [
                _buildWordsHeaderSecondUI(),
                const SizedBox(height: 8),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: [..._notes, ..._coins].length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final v = [..._notes, ..._coins][idx];
                    return _buildDenomRowSecondUI(v);
                  },
                ),
              ],
            )
          else
            _buildProCounterUI(crossAxisCount),
        ],
      ),
    );
  }

  Widget _buildDenomRowSecondUI(int value) {
    final all = [..._notes, ..._coins];
    final index = all.indexOf(value);
    final c = _qtyCtrls[value]!;
    final qty = _toInt(c.text);
    final isFocused = _focusedDenomIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _focusedDenomIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isFocused
              ? ktPrimary.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isFocused ? ktPrimary : ktBorderWhite10,
              width: isFocused ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFFFF5722),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$value',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '$qty',
                style: const TextStyle(
                  color: ktTextWhite,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            Text(
              '= ${_fmtCurrency(qty * value)}',
              style: const TextStyle(
                color: ktTextWhite,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    final today = getIndiaTime();
    final canGoNext = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    ).isBefore(DateTime(today.year, today.month, today.day));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _navCircleButton(
          icon: Icons.chevron_left,
          onTap: () {
            setState(
              () =>
                  _selectedDate = _selectedDate.subtract(
                    const Duration(days: 1),
                  ),
            );
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
                lastDate: getIndiaTime(),
              ).then((picked) {
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
                border: Border.all(color: ktPanelBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _fmtDateDisplay(_selectedDate),
                    style: const TextStyle(
                      color: ktTextWhite,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.calendar_today,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _navCircleButton(
          icon: Icons.chevron_right,
          onTap:
              canGoNext
                  ? () {
                    setState(
                      () =>
                          _selectedDate = _selectedDate.add(
                            const Duration(days: 1),
                          ),
                    );
                    _fetchPreviousBalance();
                  }
                  : null,
        ),
      ],
    );
  }

  Widget _navCircleButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
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
              const Color(
                0xFF203A66,
              ).withValues(alpha: onTap == null ? 0.35 : 0.72),
              const Color(
                0xFF1A546A,
              ).withValues(alpha: onTap == null ? 0.35 : 0.72),
            ],
          ),
          border: Border.all(color: ktPanelBorder),
        ),
        child: Icon(
          icon,
          color: onTap == null ? Colors.white30 : Colors.white70,
        ),
      ),
    );
  }

  Widget _buildTotalsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ktPanelBorder),
      ),
      child: Column(
        children: [
          const Text(
            KtStrings.totalCashInHand,
            style: TextStyle(
              color: Color(0xFF97A3B6),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _fmtCurrency(_grandTotal),
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: ktIndigo300,
              height: 0.96,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _numberToWords(_grandTotal.toInt()),
            style: const TextStyle(color: ktTextGray500, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Divider(color: ktPanelBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _chip(
                  KtStrings.notes,
                  _fmtCurrency(_notesTotal),
                  ktIndigo300,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chip(
                  KtStrings.coins,
                  _fmtCurrency(_coinsTotal),
                  ktAmber400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _chip(
                  KtStrings.acPaid,
                  _fmtCurrency(_acPaid, decimal: true),
                  ktEmerald400,
                ),
              ),
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
        border: Border.all(color: ktPanelBorder),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF97A3B6),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _denomGradient(int value) {
    switch (value) {
      case 500:
        return const LinearGradient(
          colors: [Color(0xFF1A1000), Color(0xFF4A2E00)],
        );
      case 200:
        return const LinearGradient(
          colors: [Color(0xFF001A0D), Color(0xFF004422)],
        );
      case 100:
        return const LinearGradient(
          colors: [Color(0xFF000F29), Color(0xFF002A6E)],
        );
      case 50:
        return const LinearGradient(
          colors: [Color(0xFF1A0900), Color(0xFF4A2000)],
        );
      case 20:
        return const LinearGradient(
          colors: [Color(0xFF1A0000), Color(0xFF4A0808)],
        );
      case 10:
        return const LinearGradient(
          colors: [Color(0xFF001A00), Color(0xFF004400)],
        );
      case 5:
        return const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF333333)],
        );
      case 2:
        return const LinearGradient(
          colors: [Color(0xFF1A1000), Color(0xFF3E2B00)],
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF111111), Color(0xFF2A2A2A)],
        );
    }
  }

  Color _denomAccent(int value) {
    switch (value) {
      case 500:
        return ktDenom500;
      case 200:
        return ktDenom200;
      case 100:
        return ktDenom100;
      case 50:
        return ktDenom50;
      case 20:
        return ktDenom20;
      case 10:
        return ktDenom10;
      case 5:
        return ktDenom5;
      case 2:
        return ktDenom2;
      default:
        return ktDenomOther;
    }
  }

  Widget _buildDenomCard(int value) {
    final all = [..._notes, ..._coins];
    final index = all.indexOf(value);
    final c = _qtyCtrls[value]!;
    final qty = _toInt(c.text);
    final active = qty > 0;
    final accent = _denomAccent(value);
    final isFocused = _focusedDenomIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _focusedDenomIndex = index),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isFocused
                ? ktPrimary
                : (active
                    ? ktPrimary.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.17)),
            width: isFocused ? 2 : 1,
          ),
          gradient: _denomGradient(value),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: ktTextWhite,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _stepButton(Icons.remove, () {
                  final next = (qty - 1).clamp(0, 999999);
                  c.text = '$next';
                  _recalc();
                }),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      '$qty',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: ktTextWhite,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _stepButton(Icons.add, () {
                  c.text = '${qty + 1}';
                  _recalc();
                }),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                NumberFormat('#,##0', 'en_IN').format(qty * value),
                style: TextStyle(
                  color: active ? accent : Colors.white38,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
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
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ktPanelBorder),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          leading: const Icon(Icons.edit_note_rounded, color: ktIndigo300, size: 22),
          title: const Text(
            KtStrings.additionalDetails,
            style: TextStyle(
                color: ktTextWhite, fontSize: 14, fontWeight: FontWeight.w700),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          children: [
            Row(
              children: [
                Expanded(
                    child: _numField(
                        KtStrings.weekExpenses.toUpperCase(), _weekCtrl)),
                const SizedBox(width: 10),
                Expanded(
                    child: _numField(
                        KtStrings.adjustAmount.toUpperCase(), _adjustCtrl)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                    child: _numField(
                        KtStrings.atmWithdrawal.toUpperCase(), _atmCtrl)),
                const SizedBox(width: 10),
                Expanded(
                    child: _roField(
                        KtStrings.acPaid.toUpperCase(), _acPaid.toStringAsFixed(2))),
              ],
            ),
            const SizedBox(height: 10),
            _roField(
              KtStrings.availableBalance.toUpperCase(),
              _showAvailable ? _fmtCurrency(_available, decimal: true) : '****',
              trailing: IconButton(
                onPressed: () =>
                    setState(() => _showAvailable = !_showAvailable),
                icon: Icon(
                  _showAvailable ? Icons.visibility : Icons.visibility_off,
                  color: ktTextGray500,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _remarksCtrl,
              minLines: 3,
              maxLines: 3,
              style: const TextStyle(color: ktTextWhite),
              decoration: InputDecoration(
                hintText: KtStrings.enterRemarks,
                hintStyle: const TextStyle(color: ktTextGray500),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: ktPanelBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: const BorderSide(color: ktPanelBorder),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: ktTextWhite, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: const TextStyle(color: ktTextGray500),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 11,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: ktPanelBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: ktPanelBorder),
            ),
          ),
        ),
      ],
    );
  }

  Widget _roField(String label, String value, {Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: ktPanelBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFFA5B4FC),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _loading ? null : _clearAll,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              style: OutlinedButton.styleFrom(
                foregroundColor: ktRose400,
                side: const BorderSide(color: Color(0x55EF4444)),
                padding: const EdgeInsets.symmetric(vertical: 20), // Increased height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                backgroundColor: ktRose400.withValues(alpha: 0.05),
              ),
              label: const Text(
                'Clear',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _save,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              style: ElevatedButton.styleFrom(
                backgroundColor: ktPrimaryAccent,
                foregroundColor: ktWhite,
                padding: const EdgeInsets.symmetric(vertical: 20), // Increased height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
              ),
              label: Text(
                _editingRowIndex == null ? 'Save' : 'Update',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _numberToWords(int value) {
    if (value <= 0) return KtStrings.zeroRupees;
    const ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    const tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    String twoDigits(int n) {
      if (n < 20) return ones[n];
      return '${tens[n ~/ 10]}${n % 10 > 0 ? ' ${ones[n % 10]}' : ''}';
    }

    String threeDigits(int n) {
      final h = n ~/ 100;
      final rem = n % 100;
      final start = h > 0 ? '${ones[h]} ${KtStrings.hundred}' : '';
      final end = rem > 0 ? twoDigits(rem) : '';
      if (start.isNotEmpty && end.isNotEmpty) return '$start ${KtStrings.and} $end';
      return '$start$end';
    }

    final crore = value ~/ 10000000;
    final lakh = (value % 10000000) ~/ 100000;
    final thousand = (value % 100000) ~/ 1000;
    final rest = value % 1000;

    final parts = <String>[];
    if (crore > 0) parts.add('${twoDigits(crore)} ${KtStrings.crore}');
    if (lakh > 0) parts.add('${twoDigits(lakh)} ${KtStrings.lakh}');
    if (thousand > 0) parts.add('${twoDigits(thousand)} ${KtStrings.thousand}');
    if (rest > 0) parts.add(threeDigits(rest));

    final rupeeWord = value == 1 ? KtStrings.rupee : KtStrings.rupees;
    return '${parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim()} $rupeeWord ${KtStrings.only}';
  }

  Widget _buildWordsHeaderSecondUI() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EB),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
          )
        ],
      ),
      child: Text(
        _numberToWords(_grandTotal.toInt()),
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildFooterSecondUI() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFFF5722),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  'Notes: ${_toInt(_notesTotal / 1)}', // Simplified count for now
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(width: 12),
                Text(
                  'Coins: ${_toInt(_coinsTotal / 1)}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            'Total: ₹${_grandTotal.toInt()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProCounterUI(int crossAxisCount) {
    final allDenoms = [..._notes, ..._coins];
    return Column(
      children: [
        _buildProTotalsCard(),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 124, // Increased to fix overflow
          ),
          itemCount: allDenoms.length,
          itemBuilder: (ctx, idx) {
            final v = allDenoms[idx];
            return _buildProDenomCard(v, idx);
          },
        ),
      ],
    );
  }

  Widget _buildProTotalsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ktTealPanel,ktTealPanel], // Emerald gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ktAmber, width: 2),
        boxShadow: [
          BoxShadow(
            color: ktEmerald.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Total Cash in Hand',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _fmtCurrency(_grandTotal, decimal: true),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 44,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _numberToWords(_grandTotal.toInt()),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildProDenomCard(int value, int index) {
    final c = _qtyCtrls[value]!;
    final qty = _toInt(c.text);
    final isFocused = _focusedDenomIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _focusedDenomIndex = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ktPanelBorder,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ktIndigo300, width: 1.5),
          boxShadow: [
            if (isFocused)
              BoxShadow(
                color: ktEmerald.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '$value',
                  style: const TextStyle(
                    color: ktTextWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('×', style: TextStyle(color: ktRose, fontSize: 18)),
                ),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$qty',
                      style: const TextStyle(
                        color: ktDenom500,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: ktAmber),
            const SizedBox(height: 10),
            Center(
              child: Text(
                _fmtCurrency(qty * value, decimal: true),
                style: const TextStyle(
                  color: ktPurple400,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleKeyboardKeyPress(String key) {
    if (_focusedDenomIndex == null) return;
    final value = [..._notes, ..._coins][_focusedDenomIndex!];
    final c = _qtyCtrls[value]!;
    if (c.text == '0') {
      c.text = key;
    } else {
      c.text += key;
    }
  }

  void _handleKeyboardClear() {
    if (_focusedDenomIndex == null) return;
    final value = [..._notes, ..._coins][_focusedDenomIndex!];
    _qtyCtrls[value]!.text = '0';
  }

  void _handleKeyboardBackspace() {
    if (_focusedDenomIndex == null) return;
    final value = [..._notes, ..._coins][_focusedDenomIndex!];
    final c = _qtyCtrls[value]!;
    if (c.text.length > 1) {
      c.text = c.text.substring(0, c.text.length - 1);
    } else {
      c.text = '0';
    }
  }

  void _handleKeyboardIncrement(int delta) {
    if (_focusedDenomIndex == null) return;
    final value = [..._notes, ..._coins][_focusedDenomIndex!];
    final c = _qtyCtrls[value]!;
    final current = _toInt(c.text);
    c.text = (current + delta).toString();
  }

  void _handleKeyboardUp() {
    if (_focusedDenomIndex != null && _focusedDenomIndex! > 0) {
      setState(() => _focusedDenomIndex = _focusedDenomIndex! - 1);
    }
  }

  void _handleKeyboardDown() {
    final all = [..._notes, ..._coins];
    if (_focusedDenomIndex != null && _focusedDenomIndex! < all.length - 1) {
      setState(() => _focusedDenomIndex = _focusedDenomIndex! + 1);
    }
  }
}
