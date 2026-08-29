import 'dart:convert';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'cashew_constants.dart';
import 'cashew_import_screen.dart';
import 'cashew_models.dart';
import 'cashew_report_screen.dart';
import 'cashew_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// CashewScreen
// ════════════════════════════════════════════════════════════════════════════
class CashewScreen extends StatefulWidget {
  const CashewScreen({super.key});

  @override
  State<CashewScreen> createState() => _CashewScreenState();
}

class _CashewScreenState extends State<CashewScreen> {
  final CashewService _service = CashewService();

  // ── date ─────────────────────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  String _saveStatus = 'checking';
  bool _isLoading = false;
  String _loadingText = '';
  bool _isEditMode = false;
  String? _originalDate;

  // ── expense rows ──────────────────────────────────────────────────────────
  final List<ExpenseRow> _rows = [];
  final List<TextEditingController> _amountControllers = [];
  final List<TextEditingController> _descControllers = [];

  // ── calendar accordion ────────────────────────────────────────────────────
  bool _calendarOpen = false;
  List<String> _existingDates = [];

  // ── calculator ────────────────────────────────────────────────────────────
  bool _calcOpen = false;
  String _calcExpression = '';
  String _calcDisplay = '0';
  String _calcHistory = '';

  // ── import preview ────────────────────────────────────────────────────────
  Map<String, List<ImportEntry>>? _importedGrouped;
  String? _importActiveDate;
  int _importTotalRows = 0;
  int _importSkipped = 0;
  bool _importPreviewOpen = false;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _addDefaultRows();
    _fetchDataForDate(_selectedDate);
  }

  @override
  void dispose() {
    for (final c in _amountControllers) {
      c.dispose();
    }
    for (final c in _descControllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  String _fmtDDMMMYYYY(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${cashewMonths[d.month - 1]}/${d.year}';
  }

  DateTime? _parseDDMMMYYYY(String s) {
    final m = RegExp(r'^(\d{2})/(\w{3})/(\d{4})$').firstMatch(s.trim());
    if (m == null) return null;
    const mo = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12,
    };
    return DateTime(
      int.tryParse(m.group(3)!) ?? 2024,
      mo[m.group(2)!.toLowerCase()] ?? 1,
      int.tryParse(m.group(1)!) ?? 1,
    );
  }

  String _sheetNameFromDate(DateTime d) {
    return '${cashewMonths[d.month - 1]} ${d.year}';
  }

  double get _grandTotal {
    double t = 0;
    for (final c in _amountControllers) {
      t += double.tryParse(c.text) ?? 0;
    }
    return t;
  }

  // ── row management ────────────────────────────────────────────────────────
  void _addDefaultRows() {
    for (final cat in ['Home', 'My Family', 'My Personal']) {
      _rows.add(ExpenseRow(category: cat));
      _amountControllers.add(TextEditingController());
      _descControllers.add(TextEditingController());
    }
  }

  void _addRow({
    String category = 'Select Category',
    String description = '',
    String amount = '',
    String status = 'completed',
  }) {
    setState(() {
      _rows.add(
        ExpenseRow(
          category: category,
          description: description,
          amount: amount,
          status: status,
        ),
      );
      final a = TextEditingController(text: amount);
      final d = TextEditingController(text: description);
      a.addListener(() => setState(() {}));
      _amountControllers.add(a);
      _descControllers.add(d);
    });
  }

  void _removeRow(int index) {
    if (_rows.length <= 1) {
      setState(() {
        _amountControllers[0].clear();
        _descControllers[0].clear();
        _rows[0] = ExpenseRow(category: 'Select Category');
      });
      return;
    }
    setState(() {
      _rows.removeAt(index);
      _amountControllers[index].dispose();
      _amountControllers.removeAt(index);
      _descControllers[index].dispose();
      _descControllers.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      for (final c in _amountControllers) {
        c.dispose();
      }
      for (final c in _descControllers) {
        c.dispose();
      }
      _rows.clear();
      _amountControllers.clear();
      _descControllers.clear();
      _isEditMode = false;
      _originalDate = null;
      _addDefaultRows();
      _saveStatus = 'no-data';
    });
  }

  void _parseAndCalculate(int index) {
    final text = _descControllers[index].text;
    if (text.isEmpty) return;
    double total = 0;
    bool found = false;
    for (final part in text.split(',')) {
      final matches = RegExp(r'(\d+(\.\d+)?|\.\d+)').allMatches(part).toList();
      if (matches.isNotEmpty) {
        final val = double.tryParse(matches.last.group(0)!);
        if (val != null) {
          total += val;
          found = true;
        }
      }
    }
    if (found) {
      _amountControllers[index].text = total.toStringAsFixed(2);
      setState(() {});
    }
  }

  // ── API: fetch ────────────────────────────────────────────────────────────
  Future<void> _fetchDataForDate(DateTime date) async {
    setState(() {
      _isLoading = true;
      _loadingText = 'Fetching Data';
      _saveStatus = 'checking';
    });
    try {
      final sheetName = _sheetNameFromDate(date);
      final formattedDate = _fmtDDMMMYYYY(date);
      
      // Parallelize requests to improve speed
      final results = await Future.wait([
        _service.fetchDataForDate(date, formattedDate, sheetName),
        _service.fetchDatesForCalendar(sheetName)
      ]);

      final data = results[0] as Map<String, dynamic>;
      final forDate = data['rows'] as List;
      final dates = results[1] as List<String>;

      for (final c in _amountControllers) {
        c.dispose();
      }
      for (final c in _descControllers) {
        c.dispose();
      }
      _rows.clear();
      _amountControllers.clear();
      _descControllers.clear();

      if (forDate.isNotEmpty) {
        _isEditMode = true;
        _originalDate = formattedDate;
        for (final item in forDate) {
          _rows.add(
            ExpenseRow(
              category: item['category'] ?? 'Select Category',
              description: item['description'] ?? '',
              amount: '${item['amount'] ?? ''}',
              status: item['status'] ?? 'completed',
            ),
          );
          final a = TextEditingController(text: '${item['amount'] ?? ''}');
          final d = TextEditingController(text: item['description'] ?? '');
          a.addListener(() => setState(() {}));
          _amountControllers.add(a);
          _descControllers.add(d);
        }
        _saveStatus = 'saved';
      } else {
        _isEditMode = false;
        _originalDate = null;
        _addDefaultRows();
        _saveStatus = 'no-data';
      }
      setState(() => _existingDates = dates);
    } catch (e) {
      debugPrint('Fetch error: $e');
      _saveStatus = 'no-data';
      if (_rows.isEmpty) _addDefaultRows();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDatesForCalendar(DateTime date) async {
    try {
      final sheetName = _sheetNameFromDate(date);
      final dates = await _service.fetchDatesForCalendar(sheetName);
      setState(() => _existingDates = dates);
    } catch (_) {
      setState(() => _existingDates = []);
    }
  }

  // ── API: save ─────────────────────────────────────────────────────────────
  Future<void> _saveData(String status) async {
    final norm = status.toLowerCase() == 'draft' ? 'draft' : 'completed';
    final expenses = <Map<String, dynamic>>[];
    double total = 0;
    for (int i = 0; i < _rows.length; i++) {
      final cat = _rows[i].category;
      final amount = double.tryParse(_amountControllers[i].text) ?? 0;
      if (cat != 'Select Category' && amount > 0) {
        expenses.add({
          'date': _fmtDDMMMYYYY(_selectedDate),
          'category': cat,
          'description': _descControllers[i].text,
          'amount': amount,
          'status': norm,
        });
        total += amount;
      }
    }
    if (expenses.isEmpty) {
      _showAlert(
        'No Expenses',
        'Please add at least one valid expense.',
        isError: true,
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _loadingText = 'Saving Data';
    });
    try {
      await _service.saveData({
        'type': 'cashew',
        'expenses': expenses,
        'total': total,
        'isEdit': _isEditMode,
        'action': _isEditMode ? 'update' : 'add',
        'originalDate': _originalDate,
      });
      setState(() {
        _saveStatus = 'saved';
        _isEditMode = true;
        _originalDate = _fmtDDMMMYYYY(_selectedDate);
      });
      await _fetchDatesForCalendar(_selectedDate);
      _showAlert(
        'Success',
        'Expenses saved! Status: ${norm == 'draft' ? 'Draft' : 'Completed'}',
      );
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(
            () => _selectedDate = _selectedDate.add(const Duration(days: 1)),
          );
          _fetchDataForDate(_selectedDate);
        }
      });
    } catch (e) {
      _showAlert('Error', 'Error sending data: $e', isError: true);
      setState(() => _saveStatus = 'no-data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAlert(String title, String message, {bool isError = false}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: cashewCardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: isError ? cashewRose : cashewEmerald,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: cashewTextWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(color: cashewTextGray400, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: cashewPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ── Calculator logic ──────────────────────────────────────────────────────
  void _calcAppend(String v) {
    if (_calcExpression.isEmpty && ['+', '*', '/'].contains(v)) return;
    setState(() {
      _calcExpression += v;
      _updateCalcUI();
    });
  }

  void _calcClear() => setState(() {
    _calcExpression = '';
    _calcDisplay = '0';
    _calcHistory = '';
  });

  void _calcDelete() => setState(() {
    if (_calcExpression.isNotEmpty) {
      _calcExpression = _calcExpression.substring(
        0,
        _calcExpression.length - 1,
      );
    }
    _updateCalcUI();
  });

  void _calcResult() {
    try {
      if (_calcExpression.isEmpty) return;
      String expr = _calcExpression;
      while (expr.isNotEmpty &&
          ['+', '-', '*', '/'].contains(expr[expr.length - 1])) {
        expr = expr.substring(0, expr.length - 1);
      }
      if (expr.isEmpty) return;
      final r = _evalExpr(expr);
      setState(() {
        _calcHistory = '$expr =';
        _calcDisplay = r.toStringAsFixed(r.truncateToDouble() == r ? 0 : 6);
        _calcExpression = _calcDisplay;
      });
    } catch (_) {
      setState(() {
        _calcDisplay = 'Error';
        _calcExpression = '';
      });
    }
  }

  double _evalExpr(String e) {
    for (int i = e.length - 1; i > 0; i--) {
      if (e[i] == '+' || e[i] == '-') {
        return _evalExpr(e.substring(0, i)) +
            (e[i] == '+' ? 1 : -1) * _evalExpr(e.substring(i + 1));
      }
    }
    for (int i = e.length - 1; i > 0; i--) {
      if (e[i] == '*' || e[i] == '/') {
        return e[i] == '*'
            ? _evalExpr(e.substring(0, i)) * _evalExpr(e.substring(i + 1))
            : _evalExpr(e.substring(0, i)) / _evalExpr(e.substring(i + 1));
      }
    }
    return double.parse(e.trim());
  }

  void _updateCalcUI() {
    const ops = ['+', '-', '*', '/'];
    int last = -1;
    for (int i = _calcExpression.length - 1; i >= 0; i--) {
      if (ops.contains(_calcExpression[i])) {
        last = i;
        break;
      }
    }
    if (last != -1) {
      _calcHistory = _calcExpression.substring(0, last + 1);
      _calcDisplay = _calcExpression.substring(last + 1);
      if (_calcDisplay.isEmpty) _calcDisplay = '0';
    } else {
      _calcHistory = '';
      _calcDisplay = _calcExpression.isEmpty ? '0' : _calcExpression;
    }
  }

  // ── Import Excel ──────────────────────────────────────────────────────────
  dynamic _cellRaw(CellValue? cv) {
    if (cv == null) return null;
    if (cv is TextCellValue) return cv.value;
    if (cv is IntCellValue) return cv.value;
    if (cv is DoubleCellValue) return cv.value;
    if (cv is DateCellValue) return cv.asDateTimeLocal();
    if (cv is DateTimeCellValue) return cv.asDateTimeLocal();
    if (cv is BoolCellValue) return cv.value;
    return cv.toString();
  }

  void _importExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null) return;

    setState(() {
      _isLoading = true;
      _loadingText = 'Reading Excel...';
    });

    try {
      final bytes = result.files.first.bytes;
      if (bytes == null) throw 'No data received';
      final excel = Excel.decodeBytes(bytes);
      final allEntries = <ImportEntry>[];
      int skipped = 0;

      for (final sheetName in excel.tables.keys) {
        final sheet = excel.tables[sheetName]!;
        final rows = sheet.rows;
        if (rows.isEmpty) continue;

        // Build header index map
        final headerMap = <String, int>{};
        for (int c = 0; c < rows[0].length; c++) {
          final raw = _cellRaw(rows[0][c]?.value);
          if (raw == null) continue;
          final norm = raw.toString().toLowerCase().replaceAll(
            RegExp(r'[^a-z0-9]'),
            '',
          );
          headerMap[norm] = c;
        }

        int colIdx(List<String> aliases) {
          for (final alias in aliases) {
            final norm = alias.toLowerCase().replaceAll(
              RegExp(r'[^a-z0-9]'),
              '',
            );
            for (final key in headerMap.keys) {
              if (key == norm || key.contains(norm) || norm.contains(key)) {
                return headerMap[key]!;
              }
            }
          }
          return -1;
        }

        final dateIdx = colIdx([
          'date',
          'transaction date',
          'txn date',
          'entry date',
        ]);
        final amountIdx = colIdx([
          'debit',
          'debit amount',
          'withdrawal',
          'amount',
          'txn amount',
          'amt',
        ]);
        final remarksIdx = colIdx([
          'remarks',
          'remark',
          'narration',
          'description',
          'details',
        ]);
        final tagIdx = colIdx(['tags', 'tag', 'category label']);

        for (int r = 1; r < rows.length; r++) {
          final row = rows[r];

          final tagRaw = tagIdx >= 0 ? _cellRaw(row[tagIdx]?.value) : null;
          final tag = tagRaw?.toString().trim() ?? '';
          if (tag.toLowerCase() == 'self' ||
              tag.toLowerCase() == 'self transfer') {
            skipped++;
            continue;
          }

          if (dateIdx < 0) {
            skipped++;
            continue;
          }
          final rawDate = _cellRaw(row[dateIdx]?.value);
          DateTime? parsedDate;
          if (rawDate is DateTime) {
            parsedDate = rawDate;
          } else if (rawDate is String) {
            parsedDate = _parseDDMMMYYYY(rawDate) ?? DateTime.tryParse(rawDate);
          } else if (rawDate is int) {
            parsedDate = DateTime(1899, 12, 30).add(Duration(days: rawDate));
          }
          if (parsedDate == null) {
            skipped++;
            continue;
          }

          double? amount;
          if (amountIdx >= 0) {
            final rawAmt = _cellRaw(row[amountIdx]?.value);
            if (rawAmt is num) {
              amount = rawAmt.abs().toDouble();
            } else if (rawAmt is String) {
              amount =
                  double.tryParse(
                    rawAmt.replaceAll(RegExp(r'[^\d.]'), ''),
                  )?.abs();
            }
          }
          if (amount == null || amount <= 0) {
            skipped++;
            continue;
          }

          final remarksRaw =
              remarksIdx >= 0 ? _cellRaw(row[remarksIdx]?.value) : null;
          final remarks = remarksRaw?.toString().trim() ?? '';
          final safeRemark = remarks.isEmpty ? 'Imported' : remarks;

          allEntries.add(
            ImportEntry(
              date: _fmtDDMMMYYYY(parsedDate),
              category: 'My Personal',
              tag: tag,
              remarks: safeRemark,
              description: '$safeRemark-Amount($amount)',
              amount: amount,
            ),
          );
        }
      }

      if (allEntries.isEmpty) {
        _showAlert('Import Error', 'No valid rows found.', isError: true);
        return;
      }

      final grouped = <String, List<ImportEntry>>{};
      for (final e in allEntries) {
        grouped.putIfAbsent(e.date, () => []).add(e);
      }

      final firstDate =
          (grouped.keys.toList()..sort((a, b) {
                final da = _parseDDMMMYYYY(a);
                final db = _parseDDMMMYYYY(b);
                if (da == null || db == null) return 0;
                return da.compareTo(db);
              }))
              .first;

      setState(() {
        _importedGrouped = grouped;
        _importTotalRows = allEntries.length;
        _importSkipped = skipped;
        _importActiveDate = firstDate;
        _importPreviewOpen = true;
      });
    } catch (e) {
      _showAlert('Import Error', 'Could not read file: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyImportedDate() {
    if (_importActiveDate == null || _importedGrouped == null) return;
    final entries = _importedGrouped![_importActiveDate] ?? [];
    for (final c in _amountControllers) {
      c.dispose();
    }
    for (final c in _descControllers) {
      c.dispose();
    }
    _rows.clear();
    _amountControllers.clear();
    _descControllers.clear();
    final d = _parseDDMMMYYYY(_importActiveDate!);
    if (d != null) _selectedDate = d;
    for (final e in entries) {
      _rows.add(
        ExpenseRow(
          category: e.category,
          description: e.description,
          amount: e.amount.toStringAsFixed(2),
          status: 'completed',
        ),
      );
      final a = TextEditingController(text: e.amount.toStringAsFixed(2));
      final dc = TextEditingController(text: e.description);
      a.addListener(() => setState(() {}));
      _amountControllers.add(a);
      _descControllers.add(dc);
    }
    setState(() {
      _importPreviewOpen = false;
      _saveStatus = 'no-data';
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _darkTheme(),
      child: Scaffold(
        backgroundColor: cashewBgDark,
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildBgGlows(),
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Column(
                      children: [
                        _buildDateNavigator(),
                        const SizedBox(height: 12),
                        ..._buildExpensesList(),
                      ],
                    ),
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
            if (_calendarOpen)
              Positioned(top: 8, right: 16, child: _buildCalendarAccordion()),
            if (_isLoading) _buildLoader(),
            if (_calcOpen) _buildCalcModal(),
            if (_importPreviewOpen && _importedGrouped != null)
              _buildImportModal(),
          ],
        ),
      ),
    );
  }

  ThemeData _darkTheme() => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: cashewBgDark,
    colorScheme: const ColorScheme.dark(
      surface: cashewCardBg,
      primary: cashewPrimary,
      onSurface: cashewTextWhite,
    ),
    fontFamily: 'Plus Jakarta Sans',
  );

  Widget _buildBgGlows() => const SizedBox.shrink();

  // ── AppBar ────────────────────────────────────────────────────────────────
  AppBar _buildAppBar() => AppBar(
    toolbarHeight: 80,
    backgroundColor: const Color(0xFF0B1322),
    elevation: 0,
    titleSpacing: 0,
    leading: Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF10C9E9), Color(0xFF0B89B6)],
        ),
        boxShadow: [
          BoxShadow(color: cashewCyan.withValues(alpha: 0.18), blurRadius: 10),
        ],
      ),
      child: const Icon(
        Icons.account_balance_wallet,
        color: Colors.white,
        size: 20,
      ),
    ),
    title: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cashew',
          style: TextStyle(
            color: cashewTextWhite,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'Expense Tracker',
          style: TextStyle(color: cashewTextGray400, fontSize: 11),
        ),
      ],
    ),
    actions: [
      _calendarTitleBarBtn(),
      _iconBtn(
        Icons.calculate_outlined,
        () => setState(() => _calcOpen = true),
      ),
      _iconBtn(
        Icons.upload_file_outlined,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CashewImportScreen()),
        ),
      ),
      _iconBtn(
        Icons.bar_chart_rounded,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CashewReportScreen()),
        ),
      ),
      const SizedBox(width: 8),
    ],
  );

  Widget _calendarTitleBarBtn() => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: () => setState(() => _calendarOpen = !_calendarOpen),
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withValues(alpha: 0.02),
          border: Border.all(color: cashewPanelBorder),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: cashewTextGray400,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              _sheetNameFromDate(_selectedDate),
              style: const TextStyle(
                color: cashewTextGray400,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 2),
            AnimatedRotation(
              turns: _calendarOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: cashewTextGray400,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withValues(alpha: 0.02),
          border: Border.all(color: cashewPanelBorder),
        ),
        child: Icon(icon, color: cashewTextGray400, size: 18),
      ),
    ),
  );

  // ── Date Navigator ────────────────────────────────────────────────────────
  Widget _buildDateNavigator() => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
    decoration: BoxDecoration(
      color: cashewCardBg,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: cashewPanelBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DATE',
          style: TextStyle(
            color: cashewTextGray500,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _navBtn(Icons.chevron_left, () => _changeDate(-1)),
            Expanded(
              child: GestureDetector(
                onTap: _pickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        color: cashewTextGray400,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: cashewTextWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: cashewTextGray400,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _navBtn(Icons.chevron_right, () => _changeDate(1)),
          ],
        ),
        const SizedBox(height: 8),
        Center(child: _saveStatusBadge()),
      ],
    ),
  );

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF12284F), Color(0xFF11306B)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x334A7CFF)),
      ),
      child: Icon(icon, color: cashewTextWhite, size: 22),
    ),
  );

  Widget _saveStatusBadge() {
    Color bg, tc, bc;
    String label;
    switch (_saveStatus) {
      case 'saved':
        bg = cashewEmerald.withValues(alpha: 0.15);
        tc = cashewEmerald;
        bc = cashewEmerald.withValues(alpha: 0.4);
        label = '● Saved';
      case 'no-data':
        bg = cashewRose.withValues(alpha: 0.15);
        tc = cashewRose;
        bc = cashewRose.withValues(alpha: 0.4);
        label = '● No Data';
      default:
        bg = cashewTextGray500.withValues(alpha: 0.15);
        tc = cashewTextGray400;
        bc = cashewTextGray500.withValues(alpha: 0.3);
        label = '● Checking...';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bc),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tc,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder:
          (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: const ColorScheme.dark(primary: cashewPrimary),
            ),
            child: child!,
          ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchDataForDate(picked);
    }
  }

  void _changeDate(int days) {
    final next = _selectedDate.add(Duration(days: days));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _selectedDate = next);
    _fetchDataForDate(next);
  }

  // ── Calendar accordion ────────────────────────────────────────────────────
  Widget _buildCalendarAccordion() => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 315),
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1222),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cashewPanelBorder),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _calendarOpen = !_calendarOpen),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      color: cashewCyan.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: cashewCyan,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    _sheetNameFromDate(_selectedDate),
                    style: const TextStyle(
                      color: cashewTextWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _calendarOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      color: cashewTextWhite,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_calendarOpen) ...[
            const Divider(height: 1, color: cashewBorderWhite5),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(7, 7, 7, 4),
                  child: _buildCalGrid(),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _legendDot(
                        cashewEmerald.withValues(alpha: 0.2),
                        cashewEmerald.withValues(alpha: 0.4),
                        'Data',
                      ),
                      const SizedBox(width: 8),
                      _legendDot(
                        Colors.white.withValues(alpha: 0.04),
                        Colors.white.withValues(alpha: 0.08),
                        'Empty',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _legendDot(Color bg, Color border, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(color: border),
        ),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: const TextStyle(
          color: cashewTextGray500,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    ],
  );

  Widget _buildCalGrid() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final firstDay = DateTime(year, month, 1).weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    return Column(
      children: [
        Row(
          children:
              days
                  .map(
                    (d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            color: cashewTextGray500,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 2),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            childAspectRatio: 1.0,
          ),
          itemCount: firstDay + daysInMonth,
          itemBuilder: (ctx, i) {
            if (i < firstDay) return const SizedBox.shrink();
            final day = i - firstDay + 1;
            final dayStr = day.toString().padLeft(2, '0');
            final fullDate = '$dayStr/${cashewMonths[month - 1]}/$year';
            final hasData = _existingDates.contains(fullDate);
            final isSel = day == _selectedDate.day;
            Color bg, tc;
            Color? bc;
            if (isSel) {
              bg = cashewPrimary;
              tc = Colors.white;
              bc = cashewPrimary;
            } else if (hasData) {
              bg = cashewEmerald.withValues(alpha: 0.15);
              tc = cashewEmerald;
              bc = cashewEmerald.withValues(alpha: 0.2);
            } else {
              bg = Colors.white.withValues(alpha: 0.02);
              tc = cashewTextGray400;
              bc = null;
            }
            return GestureDetector(
              onTap: () {
                final nd = DateTime(year, month, day);
                if (!nd.isAfter(DateTime.now())) {
                  setState(() => _selectedDate = nd);
                  _fetchDataForDate(nd);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(5),
                  border: bc != null ? Border.all(color: bc) : null,
                  boxShadow:
                      isSel
                          ? [
                            BoxShadow(
                              color: cashewPrimary.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ]
                          : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: tc,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ── Expense list ──────────────────────────────────────────────────────────
  List<Widget> _buildExpensesList() =>
      List.generate(_rows.length, _buildExpenseRow);

  Widget _buildExpenseRow(int i) {
    final accent = _categoryAccent(_rows[i].category);
    final isCompact = MediaQuery.of(context).size.width < 900;
    final amountButtonWidth = isCompact ? 42.0 : 46.0;
    final amountGap = isCompact ? 6.0 : 8.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: cashewCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cashewPanelBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCompact) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      _categoryIcon(_rows[i].category),
                      color: accent,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CATEGORY',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _rows[i].category,
                            isExpanded: true,
                            icon: const SizedBox.shrink(),
                            dropdownColor: cashewSlate800,
                            style: const TextStyle(
                              color: cashewTextWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            items:
                                cashewCategories
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: cashewTextWhite,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _rows[i].category = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AMOUNT',
                    style: TextStyle(
                      color: cashewTextGray400,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A1222),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: cashewPanelBorder),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                '₹',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _amountControllers[i],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'),
                                    ),
                                  ],
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    color: cashewTextWhite,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'monospace',
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(color: cashewTextGray500),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: amountGap),
                      Container(
                        width: amountButtonWidth,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A1222),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cashewPanelBorder),
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: cashewTextGray400,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: amountGap),
                      GestureDetector(
                        onTap: () => _removeRow(i),
                        child: Container(
                          width: amountButtonWidth,
                          height: 42,
                          decoration: BoxDecoration(
                            color: cashewRose.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: cashewRose.withValues(alpha: 0.55),
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: cashewRose,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      _categoryIcon(_rows[i].category),
                      color: accent,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CATEGORY',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _rows[i].category,
                            isExpanded: true,
                            icon: const SizedBox.shrink(),
                            dropdownColor: cashewSlate800,
                            style: const TextStyle(
                              color: cashewTextWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            items:
                                cashewCategories
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(
                                          c,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: cashewTextWhite,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _rows[i].category = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AMOUNT',
                          style: TextStyle(
                            color: cashewTextGray400,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A1222),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: cashewPanelBorder),
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      '₹',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _amountControllers[i],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'^\d*\.?\d*'),
                                          ),
                                        ],
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          color: cashewTextWhite,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'monospace',
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: '0',
                                          hintStyle: TextStyle(
                                            color: cashewTextGray500,
                                          ),
                                          border: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 46,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A1222),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: cashewPanelBorder),
                              ),
                              child: const Icon(
                                Icons.keyboard_arrow_down,
                                color: cashewTextGray400,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _removeRow(i),
                              child: Container(
                                width: 46,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: cashewRose.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: cashewRose.withValues(alpha: 0.55),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: cashewRose,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            const Text(
              'DESCRIPTION',
              style: TextStyle(
                color: cashewTextGray400,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (!isCompact) const SizedBox(width: 70),
                Expanded(
                  child: Container(
                    height: 104,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1222),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.65)),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _descControllers[i],
                            maxLength: 500,
                            maxLines: null,
                            expands: true,
                            style: const TextStyle(
                              color: cashewTextGray400,
                              fontSize: 12.5,
                            ),
                            decoration: const InputDecoration(
                              counterText: '',
                              hintText:
                                  'What is this for? (e.g. Groceries 500, Milk 30)',
                              hintStyle: TextStyle(
                                color: cashewTextGray500,
                                fontSize: 12,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (_) {
                              _parseAndCalculate(i);
                              setState(() {});
                            },
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${_descControllers[i].text.length}/500',
                            style: const TextStyle(
                              color: cashewTextGray400,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    final normalized = category.trim().toLowerCase();
    if (normalized.contains('home')) return Icons.home_outlined;
    if (normalized.contains('family')) return Icons.groups_2_outlined;
    if (normalized.contains('personal')) return Icons.person_outline;
    if (normalized.contains('baby')) return Icons.child_care_outlined;
    if (normalized.contains('credit')) return Icons.credit_card_outlined;
    if (normalized.contains('invest')) return Icons.trending_up_outlined;
    return Icons.layers_outlined;
  }

  Color _categoryAccent(String category) {
    final normalized = category.trim().toLowerCase();
    if (normalized.contains('home')) return cashewCyan;
    if (normalized.contains('family')) return const Color(0xFFC084FC);
    if (normalized.contains('personal')) return const Color(0xFF19E887);
    if (normalized.contains('credit')) return const Color(0xFFFDA4AF);
    return const Color(0xFF8B9BB7);
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final total = _grandTotal;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0E1627),
        border: Border.all(color: cashewPanelBorder),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL EXPENSE',
                    style: TextStyle(
                      color: cashewTextGray500,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rs. ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: cashewTextWhite,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'DAYS WITH DATA',
                    style: TextStyle(
                      color: cashewTextGray500,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 72,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1222),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cashewPanelBorder),
                    ),
                    child: Center(
                      child: Text(
                        '${_existingDates.length}',
                        style: const TextStyle(
                          color: cashewCyan,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  Icons.add,
                  'Add',
                  const Color(0xFF0A1222),
                  cashewCyan,
                  borderColor: cashewCyan.withValues(alpha: 0.55),
                  onTap: () => _addRow(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _clearAll,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cashewRose.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cashewRose.withValues(alpha: 0.55)),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: cashewRose,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionBtn(
                  Icons.edit_note,
                  'Draft',
                  const Color(0xFF0A1222),
                  Colors.white,
                  borderColor: cashewPanelBorder,
                  onTap: () => _saveData('draft'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _actionBtn(
                  Icons.check,
                  'Save',
                  null,
                  Colors.white,
                  gradient: true,
                  onTap: () => _saveData('completed'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    Color? bg,
    Color tc, {
    bool gradient = false,
    Color? borderColor,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 44,
      decoration: BoxDecoration(
        color: gradient ? null : bg,
        gradient:
            gradient
                ? const LinearGradient(
                  colors: [Color(0xFF3F55E4), Color(0xFF1FC8C0)],
                )
                : null,
        borderRadius: BorderRadius.circular(10),
        border:
            gradient ? null : Border.all(color: borderColor ?? cashewBorderWhite5),
        boxShadow:
            gradient
                ? [
                  BoxShadow(
                    color: cashewCyan.withValues(alpha: 0.25),
                    blurRadius: 12,
                  ),
                ]
                : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: tc, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: tc,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    ),
  );

  // ── Loader ────────────────────────────────────────────────────────────────
  Widget _buildLoader() => Container(
    color: Colors.black.withValues(alpha: 0.6),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(color: cashewEmerald, strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            _loadingText,
            style: const TextStyle(
              color: cashewTextWhite,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  // ── Calculator modal ──────────────────────────────────────────────────────
  Widget _buildCalcModal() => GestureDetector(
    onTap: () => setState(() => _calcOpen = false),
    child: Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cashewCardBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 40),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.calculate, color: cashewEmerald, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Calculator',
                          style: TextStyle(
                            color: cashewTextWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _calcOpen = false),
                      child: const Icon(
                        Icons.close,
                        color: cashewTextGray400,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cashewBorderWhite5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _calcHistory,
                        style: TextStyle(
                          color: cashewPrimary.withValues(alpha: 0.5),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _calcDisplay,
                        style: const TextStyle(
                          color: cashewTextWhite,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _calcButtons(),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _calcButtons() {
    final btnBg = Colors.white.withValues(alpha: 0.05);
    final opBg = cashewPrimary.withValues(alpha: 0.15);
    final clearBg = cashewRose.withValues(alpha: 0.15);

    Widget b(String l, Color bg, Color tc, VoidCallback fn, {int flex = 1}) =>
        Expanded(
          flex: flex,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: fn,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    l,
                    style: TextStyle(
                      color: tc,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

    return Column(
      children: [
        Row(
          children: [
            b('AC', clearBg, cashewRose, _calcClear, flex: 2),
            b('⌫', btnBg, cashewTextGray400, _calcDelete),
            b('÷', opBg, cashewPrimary, () => _calcAppend('/')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            b('7', btnBg, cashewTextWhite, () => _calcAppend('7')),
            b('8', btnBg, cashewTextWhite, () => _calcAppend('8')),
            b('9', btnBg, cashewTextWhite, () => _calcAppend('9')),
            b('×', opBg, cashewPrimary, () => _calcAppend('*')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            b('4', btnBg, cashewTextWhite, () => _calcAppend('4')),
            b('5', btnBg, cashewTextWhite, () => _calcAppend('5')),
            b('6', btnBg, cashewTextWhite, () => _calcAppend('6')),
            b('−', opBg, cashewPrimary, () => _calcAppend('-')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            b('1', btnBg, cashewTextWhite, () => _calcAppend('1')),
            b('2', btnBg, cashewTextWhite, () => _calcAppend('2')),
            b('3', btnBg, cashewTextWhite, () => _calcAppend('3')),
            b('+', opBg, cashewPrimary, () => _calcAppend('+')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            b('0', btnBg, cashewTextWhite, () => _calcAppend('0'), flex: 2),
            b('.', btnBg, cashewTextWhite, () => _calcAppend('.')),
            b('=', cashewEmerald, Colors.white, _calcResult),
          ],
        ),
      ],
    );
  }

  // ── Import preview modal ──────────────────────────────────────────────────
  Widget _buildImportModal() {
    final grouped = _importedGrouped!;
    final sortedDates =
        grouped.keys.toList()..sort((a, b) {
          final da = _parseDDMMMYYYY(a);
          final db = _parseDDMMMYYYY(b);
          if (da == null || db == null) return 0;
          return da.compareTo(db);
        });
    double grandTotal = 0;
    for (final v in grouped.values) {
      for (final e in v) {
        grandTotal += e.amount;
      }
    }
    final current = List<ImportEntry>.from(grouped[_importActiveDate] ?? [])
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final selTotal = current.fold(0.0, (s, e) => s + e.amount);

    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Color(0xFF0F1623),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        cashewEmerald.withValues(alpha: 0.08),
                        cashewPrimary.withValues(alpha: 0.06),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [cashewEmerald, cashewPrimary],
                              ),
                            ),
                            child: const Icon(
                              Icons.upload_file,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Import Preview',
                                  style: TextStyle(
                                    color: cashewTextWhite,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '$_importTotalRows rows · ${sortedDates.length} dates',
                                  style: const TextStyle(
                                    color: cashewTextGray400,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                () =>
                                    setState(() => _importPreviewOpen = false),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border.all(color: cashewBorderWhite10),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: cashewTextGray400,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _iStat(
                            'Total Rows',
                            '$_importTotalRows',
                            Colors.white,
                          ),
                          _iStat('Dates', '${sortedDates.length}', cashewPrimary),
                          _iStat(
                            'Grand Total',
                            '₹${grandTotal.toStringAsFixed(0)}',
                            cashewEmerald,
                          ),
                          _iStat(
                            'Skipped',
                            '$_importSkipped',
                            const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      // Date sidebar
                      Container(
                        width: 130,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          color: Colors.black.withValues(alpha: 0.15),
                        ),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(8, 8, 8, 4),
                              child: Text(
                                'By Date',
                                style: TextStyle(
                                  color: cashewTextGray500,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: sortedDates.length,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                itemBuilder: (ctx, idx) {
                                  final date = sortedDates[idx];
                                  final isActive = date == _importActiveDate;
                                  final rows = grouped[date]!;
                                  final rowTot = rows.fold(
                                    0.0,
                                    (s, e) => s + e.amount,
                                  );
                                  return GestureDetector(
                                    onTap:
                                        () => setState(
                                          () => _importActiveDate = date,
                                        ),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 4),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color:
                                            isActive
                                                ? cashewPrimary.withValues(
                                                  alpha: 0.18,
                                                )
                                                : Colors.transparent,
                                        border: Border.all(
                                          color:
                                              isActive
                                                  ? cashewPrimary.withValues(
                                                    alpha: 0.4,
                                                  )
                                                  : Colors.transparent,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            date,
                                            style: TextStyle(
                                              color:
                                                  isActive
                                                      ? const Color(0xFFA5B4FC)
                                                      : cashewTextGray400,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${rows.length} rows',
                                                style: const TextStyle(
                                                  color: cashewTextGray500,
                                                  fontSize: 9,
                                                ),
                                              ),
                                              Text(
                                                '₹${rowTot.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  color: cashewEmerald,
                                                  fontSize: 9,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Table
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: cashewPrimary.withValues(alpha: 0.06),
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _importActiveDate ?? '',
                                    style: const TextStyle(
                                      color: cashewTextWhite,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '${current.length} | ₹${selTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: cashewEmerald,
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: current.length,
                                itemBuilder: (ctx, idx) {
                                  final e = current[idx];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.05,
                                          ),
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 24,
                                          child: Text(
                                            '${idx + 1}',
                                            style: const TextStyle(
                                              color: cashewTextGray500,
                                              fontSize: 10,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            e.remarks,
                                            style: const TextStyle(
                                              color: cashewTextGray400,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '₹${e.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: cashewEmerald,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _importPreviewOpen = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(color: cashewBorderWhite10),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: cashewTextGray400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _applyImportedDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: cashewEmerald,
                          ),
                          child: const Text(
                            'Import',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iStat(String label, String value, Color color) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cashewBorderWhite5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: cashewTextGray500,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    ),
  );
}
