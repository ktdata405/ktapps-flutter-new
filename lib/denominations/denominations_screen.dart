import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../core_constants.dart';
import '../core_utils.dart';
import '../core_ui_utils.dart';
import 'denominations_service.dart';
import 'denoms_keyboard.dart';
import 'regular_denom_entry_ui.dart';
import 'pro_counter_denom_entry_ui.dart';
import 'modern_grid_denom_entry_ui.dart';
import 'classic_list_denom_entry_ui.dart';
import '../calculator/calculator_utils.dart';

class DenominationsScreen extends StatefulWidget {
  const DenominationsScreen({super.key});

  @override
  State<DenominationsScreen> createState() => _DenominationsScreenState();
}

class _DenominationsScreenState extends State<DenominationsScreen> {
  final _service = DenominationsService();
  static const _notes = [500, 200, 100, 50, 20, 10];
  static const _coins = [5, 2, 1];
  static const _draftKey = 'denom_entry_draft_v1';
  static const _draftDuration = Duration(hours: 24);
  Timer? _draftTimer;

  final _weekCtrl = TextEditingController();
  final _adjustCtrl = TextEditingController();
  final _atmCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _remarksFocus = FocusNode();
  final Map<int, TextEditingController> _qtyCtrls = {
    for (final v in [..._notes, ..._coins]) v: TextEditingController(),
  };

  bool _loading = false;
  bool _argsApplied = false;
  bool _showAvailable = false;
  int _uiType = 0;
  int _denomTab = 0; // 0 = Add, 1 = Details
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
    _remarksCtrl.addListener(_recalc);
    _remarksFocus.addListener(_onRemarksFocusChange);
    _loadUiType();
    _cleanupExpiredDraft();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _fetchPreviousBalance(),
    );
  }

  void _onRemarksFocusChange() {
    if (_remarksFocus.hasFocus) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_scrollCtrl.hasClients) {
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      });
    }
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
    _draftTimer?.cancel();
    _weekCtrl.dispose();
    _adjustCtrl.dispose();
    _atmCtrl.dispose();
    _remarksCtrl.dispose();
    _scrollCtrl.dispose();
    _remarksFocus.dispose();
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
          key.contains('closing') ||
          key.contains('balance')) {
        final n = _toDouble(e.value);
        if (n != 0) return n;
      }
    }
    return 0;
  }

  Future<void> _fetchPreviousBalance() async {
    try {
      final apiBal = await _service.fetchPreviousBalance(_fmtDateDisplay(_selectedDate));
      if (apiBal != 0) {
        setState(() {
          _previousBalance = apiBal;
        });
        _recalc();
        return;
      }
    } catch (_) {}

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
          _previousBalance = _toDouble(payload['sheet2Data'] ?? payload['openingBalance'] ?? payload['prevBalance'] ?? 0);
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
    final atm = _toDouble(_atmCtrl.text);
    
    // acPaid = (Today's Offerings + Adjust - ATM) - Week Expenses
    final acPaid = (grand + adjust - atm) - week;

    setState(() {
      _notesTotal = notes;
      _coinsTotal = coins;
      _grandTotal = grand;
      _acPaid = acPaid;
      _available = _previousBalance + acPaid;
    });

    _scheduleSaveDraft();
  }

  void _scheduleSaveDraft() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 500), () {
      _saveDraft();
    });
  }

  Future<void> _saveDraft() async {
    bool hasData = false;
    final qtyMap = <String, String>{};
    for (final v in [..._notes, ..._coins]) {
      final txt = _qtyCtrls[v]!.text.trim();
      if (txt.isNotEmpty && txt != '0') {
        hasData = true;
      }
      qtyMap['$v'] = txt;
    }
    if (_weekCtrl.text.trim().isNotEmpty && _weekCtrl.text.trim() != '0') {
      hasData = true;
    }
    if (_adjustCtrl.text.trim().isNotEmpty && _adjustCtrl.text.trim() != '0') {
      hasData = true;
    }
    if (_atmCtrl.text.trim().isNotEmpty && _atmCtrl.text.trim() != '0') {
      hasData = true;
    }
    if (_remarksCtrl.text.trim().isNotEmpty) {
      hasData = true;
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      if (!hasData) {
        await prefs.remove(_draftKey);
        return;
      }

      final draftData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'selectedDate': _selectedDate.toIso8601String(),
        'qty': qtyMap,
        'week': _weekCtrl.text,
        'adjust': _adjustCtrl.text,
        'atm': _atmCtrl.text,
        'remarks': _remarksCtrl.text,
      };

      await prefs.setString(_draftKey, jsonEncode(draftData));
    } catch (_) {}
  }

  Future<void> _restoreDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey);
      if (raw == null || raw.isEmpty) {
        if (!mounted) return;
        ktShowCustomToast(context, 'No saved draft found');
        return;
      }

      final Map<String, dynamic> data = jsonDecode(raw);
      final int timestamp = data['timestamp'] ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - timestamp > _draftDuration.inMilliseconds) {
        await prefs.remove(_draftKey);
        if (!mounted) return;
        ktShowCustomToast(context, 'Saved draft expired (>24 hours)');
        return;
      }

      final Map<String, dynamic> qtyMap = Map<String, dynamic>.from(data['qty'] ?? {});
      for (final v in [..._notes, ..._coins]) {
        if (qtyMap.containsKey('$v')) {
          _qtyCtrls[v]!.text = (qtyMap['$v'] ?? '').toString();
        }
      }
      _weekCtrl.text = (data['week'] ?? '').toString();
      _adjustCtrl.text = (data['adjust'] ?? '').toString();
      _atmCtrl.text = (data['atm'] ?? '').toString();
      _remarksCtrl.text = (data['remarks'] ?? '').toString();

      if (data['selectedDate'] != null) {
        final dt = DateTime.tryParse(data['selectedDate'].toString());
        if (dt != null) {
          setState(() {
            _selectedDate = dt;
          });
        }
      }

      _recalc();
      _fetchPreviousBalance();

      if (!mounted) return;
      ktShowCustomToast(context, 'Draft restored successfully');
    } catch (e) {
      if (!mounted) return;
      ktShowCustomToast(context, 'Failed to restore draft');
    }
  }

  Future<void> _clearDraft() async {
    _draftTimer?.cancel();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey);
    } catch (_) {}
  }

  Future<void> _cleanupExpiredDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(raw);
        final int timestamp = data['timestamp'] ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - timestamp > _draftDuration.inMilliseconds) {
          await prefs.remove(_draftKey);
        }
      }
    } catch (_) {}
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
    _clearDraft();
    _recalc();
    _fetchPreviousBalance();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final payload = <String, dynamic>{
      'date': ktFormatDateForSheet(_selectedDate),
      'Date': ktFormatDateForSheet(_selectedDate),
      'weekExpenses': _toDouble(_weekCtrl.text),
      'Week Expenses': _toDouble(_weekCtrl.text),
      'adjustAmount': _toDouble(_adjustCtrl.text),
      'Adjust Amount': _toDouble(_adjustCtrl.text),
      'atmWithdrawal': _toDouble(_atmCtrl.text),
      'ATM Withdrawal': _toDouble(_atmCtrl.text),
      'acPaid': _acPaid,
      'A/C Paid': _acPaid,
      'remarks': _remarksCtrl.text.trim(),
      'Remarks': _remarksCtrl.text.trim(),
      'total': _grandTotal.round(),
      'Total': _grandTotal.round(),
    };

    for (final v in [..._notes, ..._coins]) {
      payload['d$v'] = _toInt(_qtyCtrls[v]!.text);
      payload['$v'] = _toInt(_qtyCtrls[v]!.text);
    }

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

      await _clearDraft();

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInner) {
            void append(String t) {
              setInner(() {
                expr += t;
                output = expr;
              });
            }

            return Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.05)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: ktEmerald.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.calculate, color: ktEmerald, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              KtStrings.calculator,
                              style: TextStyle(
                                color: isDark ? ktTextWhite : Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black45, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            expr.isEmpty ? '0' : expr,
                            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            output,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: isDark ? ktTextWhite : Colors.black87,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final key in [
                              '7', '8', '9', '/',
                              '4', '5', '6', '*',
                              '1', '2', '3', '-',
                              '0', '.', 'C', '+'
                            ])
                              SizedBox(
                                width: 56,
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? ktBorderWhite5 : Colors.grey.shade200,
                                    foregroundColor: isDark ? ktTextWhite : Colors.black87,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: EdgeInsets.zero,
                                    elevation: 0,
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
                                  child: Text(key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ktEmerald,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
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
                            child: const Text('CALCULATE RESULT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ktBgDark : ktLightScaffoldBg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              padding: EdgeInsets.fromLTRB(12, 6, 12, _focusedDenomIndex != null ? 350 : 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1360),
                  child: Column(
                    children: [
                      _buildTopHeader(context),
                      const SizedBox(height: 6),
                      _buildDenomEntryTabBar(),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, c) {
                          if (_denomTab == 1) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: [
                                  _buildDetailsCard(),
                                  const SizedBox(height: 12),
                                  _buildDateCard(),
                                  const SizedBox(height: 16),
                                  _buildActionButtons(),
                                ],
                              ),
                            );
                          }

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
                                      if (_uiType != 0) _buildTotalsCard(),
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
                              if (_uiType != 0) ...[
                                const SizedBox(height: 12),
                                _buildTotalsCard(),
                              ],
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
      floatingActionButton: _focusedDenomIndex != null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'clear',
                  onPressed: () {
                    setState(() {
                      for (final c in _qtyCtrls.values) {
                        c.text = '0';
                      }
                      _recalc();
                    });
                  },
                  backgroundColor: Colors.redAccent,
                  tooltip: 'Clear All Quantities',
                  child: const Icon(Icons.clear_all, color: Colors.white),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'restore',
                  onPressed: _restoreDraft,
                  backgroundColor: ktPrimary,
                  tooltip: 'Restore Saved Draft',
                  child: const Icon(Icons.restore, color: Colors.white),
                ),
              ],
            ),
      bottomNavigationBar: _uiType == 2 ? _buildFooterSecondUI() : null,
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  KtStrings.denominationsTitle,
                  style: TextStyle(color: isDark ? ktWhite : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  KtStrings.denominationManager,
                  style: TextStyle(color: isDark ? ktTextGray500 : Colors.black54, fontSize: 11),
                ),
              ],
            ),
          ),
          PopupMenuButton<int>(
            tooltip: 'Select Layout Style',
            initialValue: _uiType,
            color: isDark ? ktCardBg : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (v) {
              setState(() => _uiType = v);
              SharedPreferences.getInstance().then((prefs) {
                prefs.setInt('denominations_ui_type', v);
              });
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 0, child: Text('Pro Counter', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              PopupMenuItem(value: 1, child: Text('Modern Grid', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              PopupMenuItem(value: 2, child: Text('Classic List', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
              PopupMenuItem(value: 3, child: Text('Regular', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: ktPrimary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ktPrimary.withValues(alpha: 0.45)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.dashboard_customize_outlined, size: 14, color: ktIndigo300),
                  const SizedBox(width: 5),
                  Text(
                    _uiType == 0
                        ? 'Pro'
                        : _uiType == 1
                            ? 'Grid'
                            : _uiType == 2
                                ? 'List'
                                : 'Reg',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          ktHeaderIcon(Icons.calculate_outlined, _openCalculator, context: context),
          const SizedBox(width: 6),
          ktHeaderIcon(
            Icons.bar_chart,
            () => Navigator.pushNamed(context, '/report/denominations'),
            context: context,
          ),
          const SizedBox(width: 6),
          ktHeaderIcon(
            Icons.home_filled,
            () => Navigator.popUntil(context, (route) => route.isFirst),
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildDenomEntryTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ktPanelBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _denomTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _denomTab == 0 ? ktPrimary.withValues(alpha: 0.25) : null,
                  borderRadius: BorderRadius.circular(12),
                  border: _denomTab == 0 ? Border.all(color: ktPrimary.withValues(alpha: 0.5)) : null,
                ),
                child: Text(
                  'Add',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _denomTab == 0 ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _denomTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _denomTab == 1 ? ktPrimary.withValues(alpha: 0.25) : null,
                  borderRadius: BorderRadius.circular(12),
                  border: _denomTab == 1 ? Border.all(color: ktPrimary.withValues(alpha: 0.5)) : null,
                ),
                child: Text(
                  'Details',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _denomTab == 1 ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
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
      padding: _uiType == 0 && _uiType != 3 ? EdgeInsets.zero : const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: _uiType == 0 && _uiType != 3 ? Colors.transparent : ktCardBg,
        borderRadius: BorderRadius.circular(18),
        border: _uiType == 0 && _uiType != 3 ? null : Border.all(color: ktPanelBorder),
      ),
      child: Column(
        children: [
          _buildProTotalsCard(),
          const SizedBox(height: 16),
          if (_uiType != 0)
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
            ProCounterDenomEntryUI(
              notes: _notes,
              coins: _coins,
              qtyCtrls: _qtyCtrls,
              focusedIndex: _focusedDenomIndex,
              onRowTap: (idx) => setState(() => _focusedDenomIndex = idx),
              grandTotal: _grandTotal,
              amountInWords: _numberToWords(_grandTotal.toInt()),
            )
          else if (_uiType == 1)
            ModernGridDenomEntryUI(
              notes: _notes,
              coins: _coins,
              qtyCtrls: _qtyCtrls,
              focusedIndex: _focusedDenomIndex,
              onRowTap: (idx) => setState(() => _focusedDenomIndex = idx),
              onUpdateQty: (val, nextQty) {
                final clamped = nextQty.clamp(0, 999999);
                _qtyCtrls[val]!.text = '$clamped';
                _recalc();
              },
              grandTotal: _grandTotal,
              amountInWords: _numberToWords(_grandTotal.toInt()),
              crossAxisCount: crossAxisCount,
              childAspectRatio: adjustedAspect,
            )
          else if (_uiType == 2)
            ClassicListDenomEntryUI(
              notes: _notes,
              coins: _coins,
              qtyCtrls: _qtyCtrls,
              focusedIndex: _focusedDenomIndex,
              onRowTap: (idx) => setState(() => _focusedDenomIndex = idx),
              grandTotal: _grandTotal,
              amountInWords: _numberToWords(_grandTotal.toInt()),
            )
          else if (_uiType == 3)
            RegularDenomEntryUI(
              notes: _notes,
              coins: _coins,
              qtyCtrls: _qtyCtrls,
              onRowTap: (v) {},
              onAddManual: () {
                setState(() {
                  _adjustCtrl.text = (_toDouble(_adjustCtrl.text) + 100).toStringAsFixed(0);
                });
              },
              onSubtractManual: () {
                setState(() {
                  _adjustCtrl.text = (_toDouble(_adjustCtrl.text) - 100).toStringAsFixed(0);
                });
              },
              notesTotal: _notesTotal,
              coinsTotal: _coinsTotal,
              grandTotal: _grandTotal,
              totalNotesCount: _notes.fold(0, (sum, v) => sum + _toInt(_qtyCtrls[v]!.text)),
              totalCoinsCount: _coins.fold(0, (sum, v) => sum + _toInt(_qtyCtrls[v]!.text)),
              amountInWords: '${_numberToWords(_grandTotal.toInt())} Rupees',
            ),
        ],
      ),
    );
  }

  Widget _buildLabeledField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ktTextGray500,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _buildDetailsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ktPanelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ktPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_note_rounded, color: ktPrimary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Additional Details',
                style: TextStyle(
                  color: ktTextWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildLabeledField(
                  label: 'WEEK EXPENSES',
                  child: TextField(
                    controller: _weekCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ktPanelBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ktPanelBorder),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLabeledField(
                  label: 'ADJUST AMOUNT',
                  child: TextField(
                    controller: _adjustCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ktPanelBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ktPanelBorder),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildLabeledField(
                  label: 'ATM WITHDRAWAL',
                  child: TextField(
                    controller: _atmCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ktPanelBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: ktPanelBorder),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLabeledField(
                  label: 'A/C PAID',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: ktPanelBorder),
                    ),
                    child: Text(
                      _acPaid.toStringAsFixed(2),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'AVAILABLE BALANCE',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ktPanelBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _showAvailable ? _fmtCurrency(_available) : '****',
                    style: const TextStyle(
                      color: ktEmerald,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showAvailable = !_showAvailable),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ktWhite.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _showAvailable ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLabeledField(
            label: 'REMARKS',
            child: TextField(
              controller: _remarksCtrl,
              focusNode: _remarksFocus,
              maxLines: 2,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Enter remarks...',
                hintStyle: const TextStyle(color: ktTextGray500),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ktPanelBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ktPanelBorder),
                ),
              ),
            ),
          ),
        ],
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _loading ? null : _clearAll,
            child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ktPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _loading ? null : _save,
            child: Text(
              _editingRowIndex == null ? 'Save' : 'Update',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterSecondUI() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: ktCardBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total:', style: TextStyle(color: ktTextWhite, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(_fmtCurrency(_grandTotal), style: const TextStyle(color: ktEmerald, fontWeight: FontWeight.w900, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildProTotalsCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ktPrimary.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
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
              color: ktTextGray400,
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
              color: ktTextWhite,
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _numberToWords(_grandTotal.toInt()),
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: ktPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  String _numberToWords(int n) => CalculatorUtils.numberToWords(n);

  Widget _buildTotalsCard() => _buildProTotalsCard();

  void _handleKeyboardUp() {
    if (_focusedDenomIndex == null) return;
    setState(() {
      if (_focusedDenomIndex! > 0) {
        _focusedDenomIndex = _focusedDenomIndex! - 1;
      }
    });
  }

  void _handleKeyboardDown() {
    if (_focusedDenomIndex == null) return;
    final all = [..._notes, ..._coins];
    setState(() {
      if (_focusedDenomIndex! < all.length - 1) {
        _focusedDenomIndex = _focusedDenomIndex! + 1;
      }
    });
  }

  void _handleKeyboardKeyPress(String digit) {
    if (_focusedDenomIndex == null) return;
    final all = [..._notes, ..._coins];
    final v = all[_focusedDenomIndex!];
    final c = _qtyCtrls[v]!;
    final current = c.text == '0' ? '' : c.text;
    if (current.length >= 6) return;
    c.text = '$current$digit';
    _recalc();
  }

  void _handleKeyboardClear() {
    if (_focusedDenomIndex == null) return;
    final all = [..._notes, ..._coins];
    final v = all[_focusedDenomIndex!];
    _qtyCtrls[v]!.text = '0';
    _recalc();
  }

  void _handleKeyboardBackspace() {
    if (_focusedDenomIndex == null) return;
    final all = [..._notes, ..._coins];
    final v = all[_focusedDenomIndex!];
    final c = _qtyCtrls[v]!;
    if (c.text.isNotEmpty) {
      c.text = c.text.substring(0, c.text.length - 1);
      if (c.text.isEmpty) c.text = '0';
      _recalc();
    }
  }

  void _handleKeyboardIncrement(int delta) {
    if (_focusedDenomIndex == null) return;
    final all = [..._notes, ..._coins];
    final v = all[_focusedDenomIndex!];
    final c = _qtyCtrls[v]!;
    final current = _toInt(c.text);
    final next = (current + delta).clamp(0, 999999);
    c.text = '$next';
    _recalc();
  }
}
