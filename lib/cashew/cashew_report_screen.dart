import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core_constants.dart';
import '../core_ui_utils.dart';
import '../core_utils.dart';
import '../widgets/period_filter_panel.dart';
import 'cashew_constants.dart';
import 'cashew_models.dart';
import 'cashew_screen.dart' show CashewScreen;
import 'cashew_service.dart';
import 'cashew_import_screen.dart';

// ── Design constants ─────────────────────────────────────────────────────────
// Consistently using shared constants from cashew_constants.dart

// ── Data models ───────────────────────────────────────────────────────────────
// Moved to cashew_models.dart

// ════════════════════════════════════════════════════════════════════════════
// CashewReportScreen
// ════════════════════════════════════════════════════════════════════════════
class CashewReportScreen extends StatefulWidget {
  const CashewReportScreen({super.key});

  @override
  State<CashewReportScreen> createState() => _CashewReportScreenState();
}

class _CashewReportScreenState extends State<CashewReportScreen>
    with SingleTickerProviderStateMixin {
  final CashewService _service = CashewService();

  // ── view state ─────────────────────────────────────────────────────────────
  int _currentTab = 0; // 0=Transactions, 1=Insights, 2=Scheduled
  int _insightsSubTab = 0; // 0 = Overall Insights, 1 = Detailed Insights
  final Set<String> _expandedCategories = {};
  final _tabs = ['Transactions', 'Insights', 'Scheduled'];
  int _periodTab = 1;
  final _periodTabs = ['Last Month', 'This Month', 'Quarter'];

  // ── filter state ───────────────────────────────────────────────────────────
  String _selectedMonth = '';
  int _selectedYear = getIndiaTime().year;
  String _searchQuery = '';
  String _categoryFilter = '';
  String _sortOrder = 'desc'; // 'desc' or 'asc'
  bool _isLoading = false;
  bool _showOutflow = false;
  bool _showIncome = false;
  bool _showExpenses = false;
  bool _showBalance = false;
  bool _showTransactions = false;
  bool _showIncomeInput = false;

  // ── data ───────────────────────────────────────────────────────────────────
  List<CashewRecord> _allData = [];
  List<CashewRecord> _filteredData = [];
  List<ScheduledRecord> _scheduledData = [];
  String _scheduledStatus = 'upcoming'; // upcoming | completed
  String _scheduledSearch = '';
  final Set<String> _selectedScheduledKeys = {};

  // ── calculator ─────────────────────────────────────────────────────────────
  bool _calcOpen = false;
  String _calcExpression = '';
  String _calcDisplay = '0';
  String _calcHistory = '';

  // ── export ─────────────────────────────────────────────────────────────────
  bool _exportOptionsOpen = false;
  bool _exportPreviewOpen = false;
  String _exportPreviewContent = '';
  String _exportCategory = 'All Categories';
  String _exportSort = 'desc';
  bool _exportCurrentMonthOnly = false;
  String _exportFromMonth =
      ktMonths[getIndiaTime().month > 1 ? getIndiaTime().month - 2 : 0];
  int _exportFromYear = getIndiaTime().year;
  String _exportToMonth = ktMonths[getIndiaTime().month - 1];
  int _exportToYear = getIndiaTime().year;

  List<CashewRecord> _exportFilteredRecords = [];
  double _exportGrandTotal = 0.0;
  String _pdfPeriodStr = '';
  String _pdfCategoryStr = '';

  // ── modals ─────────────────────────────────────────────────────────────────
  bool _categoryTxnOpen = false;
  String _categoryTxnName = '';
  String? _categoryTxnDate;
  bool _missedDatesOpen = false;
  List<String> _missedDates = [];
  bool _addScheduledOpen = false;
  bool _settingsOpen = false;

  // ── settings form ──────────────────────────────────────────────────────────
  final _incomeCtrl = TextEditingController();

  // ── scheduled form ─────────────────────────────────────────────────────────
  final _scheduledDateCtrl = TextEditingController();
  String _scheduledCategory = cashewCategories[0];
  final _scheduledDescCtrl = TextEditingController();
  String _scheduledRepeat = 'none';
  final _scheduledAmountCtrl = TextEditingController();
  DateTime _scheduledDate = getIndiaTime();

  @override
  void initState() {
    super.initState();
    _selectedMonth = ktMonths[getIndiaTime().month - 1];
    _fetchReport();
  }

  @override
  void dispose() {
    _scheduledDateCtrl.dispose();
    _scheduledDescCtrl.dispose();
    _scheduledAmountCtrl.dispose();
    _incomeCtrl.dispose();
    super.dispose();
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  void _changeMonth(int offset) {
    int mi = ktMonths.indexOf(_selectedMonth);
    if (mi < 0) mi = getIndiaTime().month - 1;
    int yr = _selectedYear;
    mi += offset;
    if (mi > 11) {
      mi = 0;
      yr++;
    } else if (mi < 0) {
      mi = 11;
      yr--;
    }
    if (yr >= 2020 && yr <= getIndiaTime().year) {
      setState(() {
        _selectedMonth = ktMonths[mi];
        _selectedYear = yr;
        _fetchReport();
      });
    }
  }

  String _fmtDDMMMYYYY(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${ktMonths[d.month - 1]}/${d.year}';
  }

  DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
    // YYYY-MM-DD
    final iso = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s.trim());
    if (iso != null) {
      return DateTime(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
    }
    // DD/MMM/YYYY
    final m = RegExp(r'^(\d{1,2})/(\w{3})/(\d{4})$').firstMatch(s.trim());
    if (m != null) {
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
      final month = mo[m.group(2)!.toLowerCase()];
      if (month != null) {
        return DateTime(int.parse(m.group(3)!), month, int.parse(m.group(1)!));
      }
    }
    return DateTime.tryParse(s);
  }

  String _formatDateDisplay(String dateStr) {
    final d = _parseDate(dateStr);
    if (d == null) return dateStr;
    return '${d.day.toString().padLeft(2, '0')}/${ktMonths[d.month - 1]}/${d.year}';
  }

  String _formatDateWithDay(String dateStr) {
    final d = _parseDate(dateStr);
    if (d == null) return dateStr;
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return '${_formatDateDisplay(dateStr)}(${days[d.weekday % 7]})';
  }

  Map<String, dynamic> _getCategoryStyle(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('home')) {
      return {
        'color': const Color(0xFF6366F1),
        'bg': const Color(0x1A6366F1),
        'icon': Icons.home,
      };
    }
    if (cat.contains('personal')) {
      return {
        'color': const Color(0xFFA855F7),
        'bg': const Color(0x1AA855F7),
        'icon': Icons.person,
      };
    }
    if (cat.contains('family')) {
      return {
        'color': const Color(0xFF10B981),
        'bg': const Color(0x1A10B981),
        'icon': Icons.people,
      };
    }
    if (cat.contains('baby')) {
      return {
        'color': const Color(0xFFF43F5E),
        'bg': const Color(0x1AF43F5E),
        'icon': Icons.child_care,
      };
    }
    if (cat.contains('credit')) {
      return {
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0x1AF59E0B),
        'icon': Icons.credit_card,
      };
    }
    if (cat.contains('emi')) {
      return {
        'color': const Color(0xFFEF4444),
        'bg': const Color(0x1AEF4444),
        'icon': Icons.receipt_long,
      };
    }
    if (cat.contains('schedule')) {
      return {
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0x1A8B5CF6),
        'icon': Icons.calendar_today,
      };
    }
    if (cat.contains('mutual') || cat.contains('invest')) {
      return {
        'color': const Color(0xFF06B6D4),
        'bg': const Color(0x1A06B6D4),
        'icon': Icons.trending_up,
      };
    }
    if (cat.contains('latha')) {
      return {
        'color': const Color(0xFFEC4899),
        'bg': const Color(0x1AEC4899),
        'icon': Icons.favorite,
      };
    }
    return {
      'color': cashewTextGray400,
      'bg': const Color(0x1A94A3B8),
      'icon': Icons.label,
    };
  }

  // ── API: fetch report ──────────────────────────────────────────────────────
  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final res = await _service.fetchReport(
        month: _selectedMonth,
        year: _selectedYear,
        fetchAll: _selectedMonth == 'All',
      );
      final rows =
          (res['data'] as List? ?? [])
              .map((r) => CashewRecord.fromJson(r as Map<String, dynamic>))
              .toList();

      final prefs = await SharedPreferences.getInstance();
      final defaultIncome = prefs.getDouble('cashew_monthly_income') ?? 0.0;

      setState(() {
        _allData = rows;
        final apiInc = double.tryParse(res['totalIncome']?.toString() ?? '0') ?? 0.0;
        if (defaultIncome != 0) {
          _incomeCtrl.text = defaultIncome.toString();
        } else {
          _incomeCtrl.text = apiInc.toString();
        }
      });
      _applyFilter();
    } catch (e) {
      debugPrint('Fetch error: $e');
      _showAlert('Error', 'Failed to load data: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchScheduled() async {
    setState(() => _isLoading = true);
    try {
      final rows = await _service.fetchScheduled();
      final scheduled =
          rows.map((item) {
            final desc = item['description']?.toString() ?? '';
            final clean = desc.split('||')[0].trim();
            String repeat = 'none';
            String? completedOn;
            for (final part in desc.split('||').skip(1)) {
              final pair = RegExp(
                r'^(\w+)\s*:\s*(.+)$',
              ).firstMatch(part.trim());
              if (pair != null) {
                final key = pair.group(1)!.toLowerCase();
                final val = pair.group(2)!.trim();
                if (key == 'repeat') repeat = val.toLowerCase();
                if (key == 'completedon') completedOn = val;
              }
            }
            final rawRepeat =
                item['repeat']?.toString().toLowerCase() ?? 'none';
            if (rawRepeat != 'none') repeat = rawRepeat;
            final parsedDate = _parseDate(item['date']?.toString() ?? '');
            final amount = double.tryParse('${item['amount'] ?? 0}') ?? 0;
            final key =
                '${item['date']}||${item['category']}||$clean||${amount.toStringAsFixed(2)}||$repeat';
            return ScheduledRecord(
              date: item['date']?.toString() ?? '',
              category: item['category']?.toString() ?? '',
              description: desc,
              cleanDescription: clean,
              amount: amount,
              repeat: repeat,
              completedOn: completedOn,
              parsedDate: parsedDate,
              selectionKey: key,
            );
          }).toList();
      setState(() => _scheduledData = scheduled);
    } catch (e) {
      debugPrint('Scheduled fetch error: $e');
      _showAlert('Error', 'Failed to load scheduled: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredData =
          _allData.where((r) {
            final matchSearch =
                _searchQuery.isEmpty ||
                r.description.toLowerCase().contains(_searchQuery);
            final matchCat =
                _categoryFilter.isEmpty || r.category == _categoryFilter;
            return matchSearch && matchCat;
          }).toList();
    });
  }

  List<ScheduledRecord> _getVisibleScheduled() {
    final today = getIndiaTime();
    final todayOnly = DateTime(today.year, today.month, today.day);
    return _scheduledData.where((item) {
        if (item.parsedDate == null) return false;
        final hasCompletedOn = (item.completedOn ?? '').trim().isNotEmpty;
        bool isCompleted;
        if (item.repeat == 'none') {
          isCompleted = hasCompletedOn || item.parsedDate!.isBefore(todayOnly);
        } else {
          isCompleted = hasCompletedOn && item.parsedDate!.isAfter(todayOnly);
        }
        final statusOk =
            _scheduledStatus == 'completed' ? isCompleted : !isCompleted;
        final text = '${item.category} ${item.cleanDescription}'.toLowerCase();
        final searchOk =
            _scheduledSearch.isEmpty || text.contains(_scheduledSearch);
        return statusOk && searchOk;
      }).toList()
      ..sort((a, b) => a.parsedDate!.compareTo(b.parsedDate!));
  }

  String _getRepeatLabel(String repeat) {
    switch (repeat.toLowerCase()) {
      case 'monthly':
        return 'Repeats monthly';
      case 'yearly':
        return 'Repeats yearly';
      case 'weekly':
        return 'Repeats weekly';
      default:
        return 'Does not repeat';
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? cashewRose : cashewEmerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
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

  // ── Calculator ────────────────────────────────────────────────────────────
  void _calcAppend(String val) {
    if (_calcExpression.isEmpty && ['+', '*', '/'].contains(val)) return;
    setState(() {
      _calcExpression += val;
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
      final result = _evalExpr(expr);
      setState(() {
        _calcHistory = '$expr =';
        _calcDisplay = result.toStringAsFixed(
          result.truncateToDouble() == result ? 0 : 6,
        );
        _calcExpression = _calcDisplay;
      });
    } catch (_) {
      setState(() {
        _calcDisplay = 'Error';
        _calcExpression = '';
      });
    }
  }

  double _evalExpr(String expr) {
    for (int i = expr.length - 1; i > 0; i--) {
      if (expr[i] == '+' || expr[i] == '-') {
        return _evalExpr(expr.substring(0, i)) +
            (expr[i] == '+' ? 1 : -1) * _evalExpr(expr.substring(i + 1));
      }
    }
    for (int i = expr.length - 1; i > 0; i--) {
      if (expr[i] == '*' || expr[i] == '/') {
        return expr[i] == '*'
            ? _evalExpr(expr.substring(0, i)) * _evalExpr(expr.substring(i + 1))
            : _evalExpr(expr.substring(0, i)) /
                _evalExpr(expr.substring(i + 1));
      }
    }
    return double.parse(expr.trim());
  }

  void _updateCalcUI() {
    final ops = ['+', '-', '*', '/'];
    int lastIdx = -1;
    for (int i = _calcExpression.length - 1; i >= 0; i--) {
      if (ops.contains(_calcExpression[i])) {
        lastIdx = i;
        break;
      }
    }
    if (lastIdx != -1) {
      _calcHistory = _calcExpression.substring(0, lastIdx + 1);
      _calcDisplay = _calcExpression.substring(lastIdx + 1);
      if (_calcDisplay.isEmpty) _calcDisplay = '0';
    } else {
      _calcHistory = '';
      _calcDisplay = _calcExpression.isEmpty ? '0' : _calcExpression;
    }
  }

  // ── Edit date entries ─────────────────────────────────────────────────────
  void _editDateEntries(String dateStr) {
    final parsed = _parseDate(dateStr);
    if (parsed == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CashewScreen(initialDate: parsed)),
    );
  }

  // ── Missed dates ─────────────────────────────────────────────────────────
  void _showMissedDates() {
    if (_filteredData.isEmpty) {
      _showAlert('Info', 'No entries available.', isError: false);
      return;
    }
    final validDates =
        _filteredData
            .map((r) => _parseDate(r.date))
            .whereType<DateTime>()
            .toList()
          ..sort();
    if (validDates.isEmpty) return;

    DateTime rangeStart, rangeEnd;
    if (_selectedMonth == 'All') {
      rangeStart = validDates.first;
      rangeEnd = validDates.last;
    } else {
      final monthIdx = ktMonths.indexOf(_selectedMonth);
      rangeStart = DateTime(_selectedYear, monthIdx + 1, 1);
      rangeEnd = DateTime(_selectedYear, monthIdx + 2, 0);
      final today = getIndiaTime();
      if (rangeEnd.isAfter(today)) rangeEnd = today;
    }

    final existing =
        validDates.map((d) => '${d.year}-${d.month}-${d.day}').toSet();
    final missed = <String>[];
    DateTime cursor = rangeStart;
    while (!cursor.isAfter(rangeEnd)) {
      final key = '${cursor.year}-${cursor.month}-${cursor.day}';
      if (!existing.contains(key)) {
        missed.add(_fmtDDMMMYYYY(cursor));
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    setState(() {
      _missedDates = missed;
      _missedDatesOpen = true;
    });
  }

  // ── Scheduled: add to cashew ──────────────────────────────────────────────
  Future<void> _addScheduledToCashew(ScheduledRecord item) async {
    setState(() => _isLoading = true);
    try {
      final now = getIndiaTime();
      final today = _fmtDDMMMYYYY(now);
      final sheetName = '${ktMonths[now.month - 1]} ${now.year}';
      final cashewPayload = {
        'type': 'cashew',
        'sheetName': sheetName,
        'action': 'add',
        'expenses': [
          {
            'date': today,
            'category': item.category,
            'description': item.cleanDescription,
            'amount': item.amount,
            'status': 'completed',
          },
        ],
      };
      DateTime nextDue = item.parsedDate!;
      switch (item.repeat) {
        case 'monthly':
          nextDue = DateTime(nextDue.year, nextDue.month + 1, nextDue.day);
          break;
        case 'yearly':
          nextDue = DateTime(nextDue.year + 1, nextDue.month, nextDue.day);
          break;
        case 'weekly':
          nextDue = nextDue.add(const Duration(days: 7));
          break;
      }
      final scheduledPayload = {
        'type': 'cashew',
        'isScheduled': true,
        'action': 'update',
        'targetSheetName': 'Scheduled',
        'sheetName': 'Scheduled',
        'originalDate': item.date,
        'originalEntry': {
          'category': item.category,
          'description': item.cleanDescription,
          'amount': item.amount,
        },
        'expenses': [
          {
            'date': _fmtDDMMMYYYY(nextDue),
            'category': item.category,
            'description': '${item.cleanDescription} || completedOn:$today',
            'amount': item.amount,
            'repeat': item.repeat,
          },
        ],
      };
      await _service.saveData(cashewPayload);
      await _service.saveData(scheduledPayload);
      _showToast('Added to Cashew!');
      await _fetchScheduled();
    } catch (e) {
      _showToast('Failed: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Save scheduled transaction ─────────────────────────────────────────────
  Future<void> _saveScheduledTransaction() async {
    final amount = double.tryParse(_scheduledAmountCtrl.text);
    if (amount == null || amount <= 0) {
      _showAlert('Validation', 'Please enter a valid amount.', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final dateStr = _fmtDDMMMYYYY(_scheduledDate);
      final desc =
          _scheduledDescCtrl.text.trim().isEmpty
              ? _scheduledCategory
              : _scheduledDescCtrl.text.trim();
      final payload = {
        'type': 'cashew',
        'isScheduled': true,
        'action': 'add',
        'targetSheetName': 'Scheduled',
        'sheetName': 'Scheduled',
        'expenses': [
          {
            'date': dateStr,
            'category': _scheduledCategory,
            'description': desc,
            'amount': amount,
            'repeat': _scheduledRepeat,
          },
        ],
      };
      await _service.saveData(payload);
      setState(() => _addScheduledOpen = false);
      _showToast('Scheduled transaction saved.');
      await _fetchScheduled();
    } catch (e) {
      _showToast('Failed: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Save Monthly Income ───────────────────────────────────────────────────
  Future<void> _saveMonthlyIncome() async {
    final income = double.tryParse(_incomeCtrl.text);
    if (income == null || income < 0) {
      _showAlert('Validation', 'Please enter a valid income amount.',
          isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final sheetName = '$_selectedMonth $_selectedYear';
      final payload = {
        'type': 'cashew',
        'action': 'setIncome',
        'sheetName': sheetName,
        'income': income,
      };
      await _service.saveData(payload);
      _showToast('Monthly income updated.');
      await _fetchReport();
    } catch (e) {
      _showToast('Failed to update income: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showIncomeEditBottomSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? cashewCardBg : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final incomeVal = double.tryParse(_incomeCtrl.text) ?? 0.0;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Update Income ($_selectedMonth $_selectedYear)',
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => setModalState(() => _showIncomeInput = !_showIncomeInput),
                        icon: Icon(
                          _showIncomeInput ? Icons.visibility : Icons.visibility_off,
                          color: cashewPrimary,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _incomeCtrl,
                    obscureText: !_showIncomeInput,
                    onChanged: (v) => setModalState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: cashewPrimary, fontSize: 18),
                      hintText: 'Enter income amount',
                      hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: cashewPrimary),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (_showIncomeInput) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: cashewTextGray500, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Formatted: ₹ ${incomeVal.toLocaleString()}',
                          style: const TextStyle(
                            color: cashewTextGray400,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _saveMonthlyIncome();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cashewPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Save Income', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 15)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Export ─────────────────────────────────────────────────────────────────
  String _formatAmountExport(double amount) {
    final isInteger = amount % 1 == 0;
    final str = isInteger ? amount.toInt().toString() : amount.toStringAsFixed(2);
    final parts = str.split('.');
    final intPart = parts[0];
    String formattedInt = intPart;
    if (intPart.length > 3) {
      final lastThree = intPart.substring(intPart.length - 3);
      final rest = intPart.substring(0, intPart.length - 3);
      final withCommas = rest.replaceAllMapped(
        RegExp(r'(\d)(?=(\d{2})+$)'),
        (m) => '${m[1]},',
      );
      formattedInt = '$withCommas,$lastThree';
    }
    return parts.length > 1 ? '$formattedInt.${parts[1]}' : formattedInt;
  }

  Future<void> _generateExport() async {
    setState(() {
      _exportOptionsOpen = false;
      _isLoading = true;
    });
    try {
      final res = await _service.fetchReport(fetchAll: true);
      final allRecords =
          (res['data'] as List? ?? [])
              .map((r) => CashewRecord.fromJson(r as Map<String, dynamic>))
              .toList();

      DateTime start, end;
      if (_exportCurrentMonthOnly) {
        final now = getIndiaTime();
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else {
        final fromIdx = ktMonths.indexOf(_exportFromMonth);
        final toIdx = ktMonths.indexOf(_exportToMonth);
        start = DateTime(_exportFromYear, fromIdx + 1, 1);
        end = DateTime(_exportToYear, toIdx + 2, 0, 23, 59, 59);
      }

      var filtered =
          allRecords.where((r) {
            final d = _parseDate(r.date);
            if (d == null) return false;
            final periodOk = !d.isBefore(start) && !d.isAfter(end);
            final catOk =
                _exportCategory == 'All' ||
                _exportCategory == 'All Categories' ||
                r.category.trim().toLowerCase() == _exportCategory.trim().toLowerCase();
            return periodOk && catOk;
          }).toList();

      filtered.sort((a, b) {
        final da = _parseDate(a.date);
        final db = _parseDate(b.date);
        if (da == null || db == null) return 0;
        return _exportSort == 'asc' ? da.compareTo(db) : db.compareTo(da);
      });

      if (filtered.isEmpty) {
        _showAlert('Notice', 'No data to export.', isError: false);
        return;
      }

      final grandTotal = filtered.fold(0.0, (s, r) => s + r.amount);
      _exportFilteredRecords = filtered;
      _exportGrandTotal = grandTotal;

      if (_exportCurrentMonthOnly) {
        final now = getIndiaTime();
        final monthStr = ktMonths[now.month - 1];
        _pdfPeriodStr = '$monthStr ${now.year} - $monthStr ${now.year}';
      } else {
        _pdfPeriodStr = '$_exportFromMonth $_exportFromYear - $_exportToMonth $_exportToYear';
      }
      _pdfCategoryStr = (_exportCategory == 'All' || _exportCategory == 'All Categories') ? 'All' : _exportCategory;

      final sb = StringBuffer();
      sb.writeln('CASHEW REPORT');
      sb.writeln('===================================');
      sb.writeln('Period: $_pdfPeriodStr');
      sb.writeln('Category: $_pdfCategoryStr');
      sb.writeln('Total Amount: Rs. ${_formatAmountExport(grandTotal)}');
      sb.writeln('===================================');
      sb.writeln();

      // Group records by formatted date display
      final Map<String, List<CashewRecord>> groupedByDate = {};
      for (final r in filtered) {
        final dStr = _formatDateDisplay(r.date);
        groupedByDate.putIfAbsent(dStr, () => []).add(r);
      }

      // Preserve date ordering from sorted list
      final Set<String> dateOrder = {};
      for (final r in filtered) {
        dateOrder.add(_formatDateDisplay(r.date));
      }

      for (final dateStr in dateOrder) {
        final dateRecords = groupedByDate[dateStr] ?? [];
        final dayTotal = dateRecords.fold(0.0, (s, r) => s + r.amount);
        final descStr = dateRecords
            .map((r) => r.description.isNotEmpty ? r.description : r.category)
            .join(', ');

        sb.writeln('Date: $dateStr');
        sb.writeln('$descStr | Total: Rs. ${_formatAmountExport(dayTotal)}');
        sb.writeln();
      }

      sb.writeln();

      setState(() {
        _exportPreviewContent = sb.toString();
        _exportPreviewOpen = true;
      });
    } catch (e) {
      _showAlert('Error', 'Export failed: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyExport() {
    Clipboard.setData(ClipboardData(text: _exportPreviewContent));
    _showToast('Copied to clipboard!');
  }

  Future<void> _exportPdf() async {
    try {
      final pdf = pw.Document();

      String pdfTextClean(String input) => input.replaceAll(RegExp(r'[^\x20-\x7E]'), '');

      // Group records by formatted date display
      final Map<String, List<CashewRecord>> groupedByDate = {};
      for (final r in _exportFilteredRecords) {
        final dStr = _formatDateDisplay(r.date);
        groupedByDate.putIfAbsent(dStr, () => []).add(r);
      }

      final Set<String> dateOrder = {};
      for (final r in _exportFilteredRecords) {
        dateOrder.add(_formatDateDisplay(r.date));
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 12),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          build: (context) => [
            pw.Text(
              'CASHEW REPORT',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF1E1B4B)),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF1F5F9),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Period: $_pdfPeriodStr', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                      pw.Text('Category: $_pdfCategoryStr', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('Total Amount: Rs. ${_formatAmountExport(_exportGrandTotal)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF047857))),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Description', 'Day Total'],
              data: dateOrder.map((dateStr) {
                final dateRecords = groupedByDate[dateStr] ?? [];
                final dayTotal = dateRecords.fold(0.0, (s, r) => s + r.amount);
                final descStr = dateRecords
                    .map((r) => r.description.isNotEmpty ? r.description : r.category)
                    .join(', ');
                return [
                  dateStr,
                  pdfTextClean(descStr),
                  'Rs. ${_formatAmountExport(dayTotal)}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF4F46E5),
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(80),
                1: const pw.FlexColumnWidth(),
                2: const pw.FixedColumnWidth(100),
              },
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF8FAFC),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'GRAND TOTAL: Rs. ${_formatAmountExport(_exportGrandTotal)}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: const PdfColor.fromInt(0xFF1E1B4B),
                ),
              ),
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes, filename: 'cashew_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    } catch (e) {
      _showAlert('Export Error', 'Could not generate PDF: $e', isError: true);
    }
  }

  Future<void> _exportTxt() async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(_exportPreviewContent));
      await Printing.sharePdf(bytes: bytes, filename: 'cashew_report_${DateTime.now().millisecondsSinceEpoch}.txt');
    } catch (e) {
      _showAlert('Export Error', 'Could not export TXT: $e', isError: true);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 980;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? cashewBgDark : ktLightScaffoldBg,
      body: Stack(
        children: [
          const Positioned.fill(child: _BgGlow()),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                    child:
                        wide
                            ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      _buildFilterCard(),
                                      const SizedBox(height: 10),
                                      _buildStatsCards(),
                                      const SizedBox(height: 10),
                                      _buildTabBar(),
                                      const SizedBox(height: 10),
                                      _buildTabContent(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                _buildOverviewSidePanel(),
                              ],
                            )
                            : Column(
                              children: [
                                _buildFilterCard(),
                                const SizedBox(height: 10),
                                _buildStatsCards(),
                                const SizedBox(height: 10),
                                _buildTabBar(),
                                const SizedBox(height: 10),
                                _buildTabContent(),
                              ],
                            ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading) _buildLoader(),
          if (_calcOpen) _buildCalculatorModal(),
          if (_settingsOpen) _buildSettingsModal(),
          if (_exportOptionsOpen) _buildExportOptionsModal(),
          if (_exportPreviewOpen) _buildExportPreviewModal(),
          if (_categoryTxnOpen) _buildCategoryTxnModal(),
          if (_missedDatesOpen) _buildMissedDatesModal(),
          if (_addScheduledOpen) _buildAddScheduledModal(),
        ],
      ),
      floatingActionButton:
          _currentTab == 2
              ? FloatingActionButton(
                backgroundColor: cashewPrimary,
                onPressed: () {
                  setState(() {
                    _scheduledDate = getIndiaTime();
                    _scheduledCategory = cashewCategories[0];
                    _scheduledDescCtrl.clear();
                    _scheduledRepeat = 'none';
                    _scheduledAmountCtrl.clear();
                    _addScheduledOpen = true;
                  });
                },
                child: const Icon(Icons.add),
              )
              : null,
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2E2D34) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? cashewBorderWhite8 : Colors.black.withValues(alpha: 0.08)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: cashewPrimary,
            ),
            child: const Icon(Icons.show_chart, color: Colors.white, size: 15),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cashew Report',
                style: TextStyle(
                  color: isDark ? cashewTextWhite : Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Your Expenses Insights',
                style: TextStyle(
                  color: isDark ? cashewTextGray500 : Colors.black54,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 6),
          ktHeaderIcon(
            Icons.upload_file_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CashewImportScreen()),
            ),
            context: context,
          ),
          const SizedBox(width: 6),
          ktHeaderIcon(
            Icons.add,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CashewScreen()),
            ),
            context: context,
          ),
          const SizedBox(width: 6),
          ktHeaderIcon(
            Icons.download_for_offline_outlined,
            () => setState(() => _exportOptionsOpen = true),
            context: context,
          ),
          const SizedBox(width: 6),
          ktHeaderIcon(
            Icons.home_filled,
                () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }



  // ── Filter Card ─────────────────────────────────────────────────────────────
  Widget _buildFilterCard() {
    final validMonth = ktMonths.contains(_selectedMonth) ? _selectedMonth : ktMonths[getIndiaTime().month - 1];
    return PeriodFilterPanel(
      month: validMonth,
      year: _selectedYear,
      onMonthChanged: (value) {
        setState(() {
          _selectedMonth = value;
          _fetchReport();
        });
      },
      onYearChanged: (value) {
        setState(() {
          _selectedYear = value;
          _fetchReport();
        });
      },
      onPrevious: () => _changeMonth(-1),
      onRefresh: () {
        if (!_isLoading) _fetchReport();
      },
      onNext: () => _changeMonth(1),
    );
  }

  Widget _dropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: cashewInk,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cashewBorderWhite8),
      ),
      child: child,
    );
  }

  BoxDecoration _glassDeco() {
    return BoxDecoration(
      color: cashewTealPanel.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: cashewPanelBorderReport.withValues(alpha: 0.6)),
    );
  }

  Widget _buildOverviewSidePanel() {
    final expenses = _allData.fold(0.0, (s, r) => s + r.amount);
    final income = double.tryParse(_incomeCtrl.text) ?? 0;
    final balance = income - expenses;

    return SizedBox(
      width: 190,
      child: Column(
        children: [
          _overviewCard('Total Income', income, cashewEmerald, _showIncome, 
            () => setState(() => _showIncome = !_showIncome)),
          const SizedBox(height: 8),
          _overviewCard('Total Expenses', expenses, cashewRose, _showExpenses,
            () => setState(() => _showExpenses = !_showExpenses)),
          const SizedBox(height: 8),
          _overviewCard('Total Balance', balance, balance >= 0 ? cashewEmerald : cashewRose, _showBalance,
            () => setState(() => _showBalance = !_showBalance)),
        ],
      ),
    );
  }

  Widget _overviewCard(String title, double value, Color color, bool visible, VoidCallback onToggle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cashewCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cashewBorderWhite8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: cashewTextGray400,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: color.withValues(alpha: 0.6),
                  size: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  visible ? 'Rs. ${value.toStringAsFixed(2)}' : 'Rs. ••••',
                  style: const TextStyle(
                    color: cashewTextWhite,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              Icon(Icons.arrow_outward, color: color, size: 14),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats Cards ────────────────────────────────────────────────────────────
  Widget _buildStatsCards() {
    final expenses = _allData.fold(0.0, (s, r) => s + r.amount);
    final income = double.tryParse(_incomeCtrl.text) ?? 0;
    final balance = income - expenses;
    
    final period =
        _selectedMonth == 'All'
            ? 'All Time Records'
            : '$_selectedMonth $_selectedYear';
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.arrow_upward_rounded,
            iconBg: cashewRose.withValues(alpha: 0.1),
            iconColor: cashewRose,
            label: 'Total Expenses',
            value: _showExpenses ? 'Rs. ${expenses.toLocaleString()}' : 'Rs. ••••',
            sub: period,
            borderColor: cashewRose.withValues(alpha: 0.5),
            badgeText: 'Spending',
            badgeColor: cashewRose,
            visible: _showExpenses,
            onToggle: () => setState(() => _showExpenses = !_showExpenses),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            icon: Icons.account_balance_wallet_outlined,
            iconBg: (balance >= 0 ? cashewEmerald : cashewRose).withValues(alpha: 0.1),
            iconColor: balance >= 0 ? cashewEmerald : cashewRose,
            label: 'Current Balance',
            value: _showBalance ? 'Rs. ${balance.toLocaleString()}' : 'Rs. ••••',
            sub: 'Income - Expenses',
            borderColor: (balance >= 0 ? cashewEmerald : cashewRose).withValues(alpha: 0.5),
            badgeText: balance >= 0 ? 'Surplus' : 'Deficit',
            badgeColor: balance >= 0 ? cashewEmerald : cashewRose,
            visible: _showBalance,
            onToggle: () => setState(() => _showBalance = !_showBalance),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
    required Color borderColor,
    required String badgeText,
    required Color badgeColor,
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A).withValues(alpha: 0.7) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: cashewTextGray400,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              GestureDetector(
                onTap: onToggle,
                child: Icon(
                  visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: iconColor.withValues(alpha: 0.5),
                  size: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: cashewTextWhite,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              color: cashewTextGray500,
              fontSize: 9,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab Bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cashewBorderWhite5),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final isActive = _currentTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _currentTab = i);
                if (i == 2) _fetchScheduled();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? cashewPrimary.withValues(alpha: 0.15) : null,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      isActive
                          ? Border.all(color: cashewPrimary.withValues(alpha: 0.3))
                          : null,
                ),
                child: Text(
                  _tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? cashewTextWhite : cashewTextGray400,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── Tab content ────────────────────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildTransactionsView();
      case 1:
        return _buildInsightsView();
      case 2:
        return _buildScheduledView();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Transactions View ──────────────────────────────────────────────────────
  Widget _buildTransactionsView() {
    final grouped = <String, List<CashewRecord>>{};
    for (final r in _filteredData) {
      final d = _formatDateDisplay(r.date);
      grouped.putIfAbsent(d, () => []).add(r);
    }
    final sortedDates =
        grouped.keys.toList()..sort((a, b) {
          final da = _parseDate(a), db = _parseDate(b);
          if (da == null || db == null) return 0;
          return _sortOrder == 'desc' ? db.compareTo(da) : da.compareTo(db);
        });

    final definedCats = cashewCategories.where((c) => c != 'Select Category').toList();
    final dataCats = _allData
        .map((r) => r.category)
        .where((c) => c.isNotEmpty && c != 'Select Category')
        .toSet();
    final cats = {...definedCats, ...dataCats}.toList()..sort();
    final totalSpent = _filteredData.fold(0.0, (s, r) => s + r.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 💎 Minimalist Hero Section
        _buildMinimalHero(totalSpent),
        const SizedBox(height: 32),

        // 🎛️ Floating Action Strip
        _buildActionStrip(cats),
        const SizedBox(height: 32),

        // 🛰️ The Timeline
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HISTORY',
              style: TextStyle(
                color: cashewTextGray400.withValues(alpha: 0.5),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            GestureDetector(
              onTap: _showMissedDates,
              child: Text(
                '${sortedDates.length} Days Active',
                style: const TextStyle(
                  color: cashewPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        sortedDates.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final group = grouped[date]!;
                  final dayTotal = group.fold(0.0, (s, r) => s + r.amount);
                  return _buildTimelineGroup(date, group, dayTotal);
                },
              ),
      ],
    );
  }

  Widget _buildMinimalHero(double total) {
    final income = double.tryParse(_incomeCtrl.text) ?? 0;
    return Column(
      children: [
        Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Total Expenses',
                    style: TextStyle(
                      color: cashewTextGray400,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3.0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => setState(() => _showOutflow = !_showOutflow),
                    child: Icon(
                      _showOutflow ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: cashewPrimary,
                      size: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Color(0xFF94A3B8)],
                ).createShader(bounds),
                child: Text(
                  _showOutflow ? 'Rs. ${total.toLocaleString()}' : 'Rs ••••',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w200,
                    fontFamily: 'Plus Jakarta Sans',
                    letterSpacing: -1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 📈 Income Summary Strip (Visible on all screens)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cashewEmerald.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.south_west_rounded, color: cashewEmerald, size: 12),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Monthly Income', style: TextStyle(color: cashewTextGray500, fontSize: 8, fontWeight: FontWeight.w800)),
                      Text(
                        _showIncome ? income.toLocaleString() : '••••',
                        style: const TextStyle(color: cashewTextWhite, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    //onTap: () => setState(() => _showIncome = !_showIncome),
                    child: Icon(
                      _showIncome ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white24,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showIncomeEditBottomSheet(),
                    child: const Icon(
                      Icons.edit,
                      color: cashewPrimary,
                      size: 14,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionStrip(List<String> cats) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (v) {
                    setState(() => _searchQuery = v.toLowerCase());
                    _applyFilter();
                  },
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Find a transaction...',
                    hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: isDark ? Colors.white38 : Colors.black38, size: 20),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _circleActionBtn(
              icon: _sortOrder == 'desc' ? Icons.sort_rounded : Icons.filter_list_rounded,
              onTap: () => setState(() => _sortOrder = _sortOrder == 'desc' ? 'asc' : 'desc'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: const {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
                PointerDeviceKind.stylus,
              },
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                _neoFilterChip('All', _categoryFilter == '', () {
                  setState(() => _categoryFilter = '');
                  _applyFilter();
                }),
                ...cats.map((c) => _neoFilterChip(c, _categoryFilter == c, () {
                  setState(() => _categoryFilter = c);
                  _applyFilter();
                })),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleActionBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: cashewPrimary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: cashewPrimary.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _neoFilterChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white60,
            fontSize: 12,
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineGroup(String date, List<CashewRecord> items, double total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vertical Line & Dot
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: cashewPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatDateWithDay(date).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _showTransactions = !_showTransactions),
                        child: Icon(
                          _showTransactions ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white24,
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _editDateEntries(date),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white24,
                          size: 10,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _showTransactions ? '₹${total.toLocaleString()}' : '₹ ••••',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...items.asMap().entries.map((e) => _buildCleanRow(e.value, date, e.key)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCleanRow(CashewRecord item, String date, int index) {
    final style = _getCategoryStyle(item.category);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Alternate colors for transaction text
    final textColors = [
      const Color(0xFF60A5FA), // Blue
      const Color(0xFF34D399), // Emerald
      const Color(0xFFFBBF24), // Amber
      const Color(0xFFF472B6), // Pink
      const Color(0xFFA78BFA), // Violet
    ];
    final rowTextColor = isDark
        ? textColors[index % textColors.length]
        : const [Color(0xFF1D4ED8), Color(0xFF047857), Color(0xFF92400E), Color(0xFFBE185D), Color(0xFF6D28D9)][index % textColors.length];

    return GestureDetector(
      onTap: () => setState(() {
        _categoryTxnName = item.category;
        _categoryTxnDate = date;
        _categoryTxnOpen = true;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (style['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                style['icon'] as IconData,
                color: style['color'] as Color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category,
                    style: TextStyle(
                      color: rowTextColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: TextStyle(
                        color: isDark
                            ? cashewTextGray500.withValues(alpha: 0.6)
                            : const Color(0xFF475569),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _showTransactions ? '₹${item.amount.toLocaleString()}' : '₹ ••••',
              style: TextStyle(
                color: rowTextColor.withValues(alpha: 0.9),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: cashewTextGray500.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No matching records',
            style: TextStyle(
              color: cashewTextGray500.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(color: cashewTextGray500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Insights View ──────────────────────────────────────────────────────────
  Widget _buildInsightsView() {
    if (_allData.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Text(
          'No data available',
          textAlign: TextAlign.center,
          style: TextStyle(color: cashewTextGray500),
        ),
      );
    }

    return Column(
      children: [
        // Sub-tabs: Overall Insights, Detailed Insights
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: cashewCardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cashewPanelBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _insightsSubTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _insightsSubTab == 0 ? cashewPrimary.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: _insightsSubTab == 0 ? Border.all(color: cashewPrimary.withValues(alpha: 0.4)) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Overall Insights',
                      style: TextStyle(
                        color: _insightsSubTab == 0 ? cashewTextWhite : cashewTextGray400,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _insightsSubTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _insightsSubTab == 1 ? cashewPrimary.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: _insightsSubTab == 1 ? Border.all(color: cashewPrimary.withValues(alpha: 0.4)) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Detailed Insights',
                      style: TextStyle(
                        color: _insightsSubTab == 1 ? cashewTextWhite : cashewTextGray400,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        _insightsSubTab == 0 ? _buildOverallInsightsView() : _buildDetailedInsightsView(),
      ],
    );
  }

  Widget _buildOverallInsightsView() {
    final totals = <String, double>{};
    for (final r in _allData) {
      totals[r.category] = (totals[r.category] ?? 0) + r.amount;
    }
    final sorted =
        totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final grandTotal = sorted.fold(0.0, (s, e) => s + e.value);

    return Column(
      children:
          sorted.map((entry) {
            final cat = entry.key;
            final amount = entry.value;
            final percent = grandTotal > 0 ? amount / grandTotal : 0.0;
            final style = _getCategoryStyle(cat);
            return GestureDetector(
              onTap:
                  () => setState(() {
                    _categoryTxnName = cat;
                    _categoryTxnDate = null;
                    _categoryTxnOpen = true;
                  }),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cashewCardBg.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cashewBorderWhite5),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (style['bg'] as Color),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            style['icon'] as IconData,
                            color: style['color'] as Color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat,
                                style: const TextStyle(
                                  color: cashewTextWhite,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${(percent * 100).toStringAsFixed(1)}% of total',
                                style: const TextStyle(
                                  color: cashewTextGray500,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rs. ${amount.toLocaleString()}',
                              style: const TextStyle(
                                color: cashewTextWhite,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const Text(
                              'tap to view',
                              style: TextStyle(
                                color: cashewTextGray500,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percent.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: style['color'] as Color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildDetailedInsightsView() {
    final recordsToUse = _filteredData.isNotEmpty ? _filteredData : _allData;
    if (recordsToUse.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Text(
          'No records available for detailed insights',
          textAlign: TextAlign.center,
          style: TextStyle(color: cashewTextGray500),
        ),
      );
    }

    final Map<String, List<CashewRecord>> byCategory = {};
    for (final r in recordsToUse) {
      final cat = r.category.isEmpty ? 'Uncategorized' : r.category;
      byCategory.putIfAbsent(cat, () => []).add(r);
    }

    // Category Order: Home, My Family, Baby, My Personal, followed by others
    const customOrder = ['home', 'my family', 'baby', 'my personal'];
    final sortedEntries = byCategory.entries.toList()..sort((a, b) {
      final keyA = a.key.toLowerCase().trim();
      final keyB = b.key.toLowerCase().trim();
      final idxA = customOrder.indexOf(keyA);
      final idxB = customOrder.indexOf(keyB);
      if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
      if (idxA != -1) return -1;
      if (idxB != -1) return 1;
      return keyA.compareTo(keyB);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        return Column(
          children: sortedEntries.map((entry) {
            final catName = entry.key;
            final catRecords = entry.value;
            final totalAmount = catRecords.fold(0.0, (sum, r) => sum + r.amount);
            final style = _getCategoryStyle(catName);
            final isExpanded = _expandedCategories.contains(catName);

            final Map<String, double> itemTotals = {};
            for (final r in catRecords) {
              final desc = r.description.trim();
              if (desc.isEmpty) continue;
              final parts = desc.split(',');
              bool parsedAny = false;
              for (final part in parts) {
                final subPart = part.trim();
                if (subPart.isEmpty) continue;
                final dashIndex = subPart.lastIndexOf('-');
                if (dashIndex != -1) {
                  final itemName = subPart.substring(0, dashIndex).trim();
                  final amtStr = subPart.substring(dashIndex + 1).trim();
                  final amt = double.tryParse(amtStr.replaceAll(RegExp(r'[^0-9.]'), ''));
                  if (itemName.isNotEmpty && amt != null) {
                    itemTotals[itemName] = (itemTotals[itemName] ?? 0) + amt;
                    parsedAny = true;
                  }
                }
              }
              if (!parsedAny) {
                itemTotals[desc] = (itemTotals[desc] ?? 0) + r.amount;
              }
            }

            final sortedItems = itemTotals.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cashewCardBg.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cashewBorderWhite5),
              ),
              child: Column(
                children: [
                  // Category Header (Clickable for Expand/Collapse)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedCategories.remove(catName);
                        } else {
                          _expandedCategories.add(catName);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: cashewCardBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: (style['bg'] as Color),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              style['icon'] as IconData,
                              color: style['color'] as Color,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              catName,
                              style: const TextStyle(
                                color: cashewTextWhite,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            '-Rs. ${totalAmount.toLocaleString()}',
                            style: const TextStyle(
                              color: Color(0xFFEF4444), // Maroon / Red
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: cashewTextGray400,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Expandable Table Content
                  if (isExpanded) ...[
                    const Divider(height: 1, color: cashewBorderWhite5),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: sortedItems.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No detailed item descriptions found',
                                style: TextStyle(color: cashewTextGray500, fontSize: 12),
                              ),
                            )
                          : _buildItemTableView(sortedItems, catRecords, catName, isWide, style),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildItemTableView(
    List<MapEntry<String, double>> sortedItems,
    List<CashewRecord> catRecords,
    String catName,
    bool isWide,
    Map<String, dynamic> style,
  ) {
    if (isWide) {
      // Web: 2 items side by side in a row
      final rows = <Widget>[];
      for (int i = 0; i < sortedItems.length; i += 2) {
        final item1 = sortedItems[i];
        final item2 = (i + 1 < sortedItems.length) ? sortedItems[i + 1] : null;

        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildItemCell(item1, i, catRecords, catName, style),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: item2 != null
                      ? _buildItemCell(item2, i + 1, catRecords, catName, style)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      }
      return Column(children: rows);
    } else {
      // Mobile: 1 item per row
      return Column(
        children: sortedItems.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildItemCell(item, idx, catRecords, catName, style),
          );
        }).toList(),
      );
    }
  }

  Widget _buildItemCell(
    MapEntry<String, double> item,
    int index,
    List<CashewRecord> catRecords,
    String catName,
    Map<String, dynamic> style,
  ) {
    final bgColor = index.isEven
        ? Colors.white.withValues(alpha: 0.03)
        : Colors.white.withValues(alpha: 0.07);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cashewBorderWhite5),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: style['color'] as Color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.key,
              style: const TextStyle(
                color: cashewTextWhite,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '-Rs. ${item.value.toLocaleString()}',
            style: const TextStyle(
              color: Color(0xFFEF4444), // Maroon / Red
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showItemDateWiseDetails(context, catName, item.key, catRecords),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline,
                size: 14,
                color: cashewTextGray400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showItemDateWiseDetails(
    BuildContext context,
    String catName,
    String itemName,
    List<CashewRecord> catRecords,
  ) {
    final List<Map<String, dynamic>> dateWiseDetails = [];
    for (final r in catRecords) {
      final desc = r.description.trim();
      if (desc.isEmpty) continue;
      final parts = desc.split(',');
      bool foundInParts = false;
      for (final part in parts) {
        final subPart = part.trim();
        if (subPart.isEmpty) continue;
        final dashIndex = subPart.lastIndexOf('-');
        if (dashIndex != -1) {
          final curItemName = subPart.substring(0, dashIndex).trim();
          final amtStr = subPart.substring(dashIndex + 1).trim();
          final amt = double.tryParse(amtStr.replaceAll(RegExp(r'[^0-9.]'), ''));
          if (curItemName.toLowerCase() == itemName.toLowerCase() && amt != null) {
            dateWiseDetails.add({
              'date': r.date.isNotEmpty ? r.date : 'Unknown Date',
              'amount': amt,
            });
            foundInParts = true;
          }
        }
      }
      if (!foundInParts && desc.toLowerCase() == itemName.toLowerCase()) {
        dateWiseDetails.add({
          'date': r.date.isNotEmpty ? r.date : 'Unknown Date',
          'amount': r.amount,
        });
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: cashewCardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 450),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category: $catName',
                          style: const TextStyle(
                            color: cashewTextGray400,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          itemName,
                          style: const TextStyle(
                            color: cashewTextWhite,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: cashewTextGray400),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: cashewBorderWhite5),
              const SizedBox(height: 12),
              Expanded(
                child: dateWiseDetails.isEmpty
                    ? const Center(
                        child: Text(
                          'No date-wise details found',
                          style: TextStyle(color: cashewTextGray500),
                        ),
                      )
                    : ListView.builder(
                        itemCount: dateWiseDetails.length,
                        itemBuilder: (context, index) {
                          final detail = dateWiseDetails[index];
                          final dateStr = detail['date'].toString();
                          final amt = detail['amount'] as double;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: index.isEven
                                  ? Colors.white.withValues(alpha: 0.03)
                                  : Colors.white.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: cashewBorderWhite5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: cashewTextGray400),
                                    const SizedBox(width: 8),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(
                                        color: cashewTextWhite,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '-Rs. ${amt.toLocaleString()}',
                                  style: const TextStyle(
                                    color: Color(0xFFEF4444), // Maroon / Red
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
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
        );
      },
    );
  }

  // ── Scheduled View ─────────────────────────────────────────────────────────
  Widget _buildScheduledView() {
    final visible = _getVisibleScheduled();
    final total = visible.fold(0.0, (s, e) => s + e.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
        gradient: const LinearGradient(
          colors: [Color(0x38636601), Color(0x1F10B981)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cashewPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cashewPrimary.withValues(alpha: 0.35)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Color(0xFFC4B5FD),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Scheduled',
                      style: TextStyle(
                        color: Color(0xFFC4B5FD),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (_scheduledStatus == 'upcoming' &&
                      _selectedScheduledKeys.isNotEmpty)
                    GestureDetector(
                      onTap: _saveSelectedScheduled,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                                                   vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_box_outlined,
                              color: Color(0xFFDBEAFE),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Save (${_selectedScheduledKeys.length})',
                              style: const TextStyle(
                                color: Color(0xFFDBEAFE),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _scheduledDate = getIndiaTime();
                        _scheduledCategory = cashewCategories[0];
                        _scheduledDescCtrl.clear();
                        _scheduledRepeat = 'none';
                        _scheduledAmountCtrl.clear();
                        _addScheduledOpen = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: cashewEmerald.withValues(alpha: 0.45)),
                        gradient: LinearGradient(
                          colors: [
                            cashewEmerald.withValues(alpha: 0.28),
                            cashewPrimary.withValues(alpha: 0.25),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Color(0xFFECFEFF), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(
                              color: Color(0xFFECFEFF),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
          const SizedBox(height: 12),
          // Status tabs
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF020617).withValues(alpha: 0.65) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: cashewTextGray500.withValues(alpha: 0.2)),
            ),
            child: Row(
              children:
                  ['upcoming', 'completed'].map((status) {
                    final isActive = _scheduledStatus == status;
                    return Expanded(
                      child: GestureDetector(
                        onTap:
                            () => setState(() {
                              _scheduledStatus = status;
                              _selectedScheduledKeys.clear();
                            }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient:
                                isActive
                                    ? LinearGradient(
                                      colors: [
                                        cashewPrimary.withValues(alpha: 0.34),
                                        cashewSecondary.withValues(alpha: 0.3),
                                      ],
                                    )
                                    : null,
                            border:
                                isActive
                                    ? Border.all(
                                      color: cashewPrimary.withValues(alpha: 0.45),
                                    )
                                    : null,
                            boxShadow:
                                isActive
                                    ? [
                                      BoxShadow(
                                        color: cashewPrimary.withValues(alpha: 0.25),
                                        blurRadius: 10,
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Text(
                            status[0].toUpperCase() + status.substring(1),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isActive ? Colors.white : cashewTextGray400,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          // Search
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF020617).withValues(alpha: 0.72) : Colors.white,
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: cashewTextGray500, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged:
                        (v) =>
                            setState(() => _scheduledSearch = v.toLowerCase()),
                    style: const TextStyle(
                      color: cashewTextWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search scheduled...',
                      hintStyle: TextStyle(color: cashewTextGray500, fontSize: 13),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Meta strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cashewTextGray400.withValues(alpha: 0.3)),
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF020617).withValues(alpha: 0.55) : const Color(0xFFF8FAFC),
                ),
                child: Text(
                  '${visible.length} entr${visible.length == 1 ? 'y' : 'ies'}',
                  style: const TextStyle(
                    color: cashewTextGray400,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cashewEmerald.withValues(alpha: 0.38)),
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF064E3B).withValues(alpha: 0.28) : const Color(0xFFECFDF5),
                ),
                child: Text(
                  'Rs. ${total.toLocaleString()}',
                  style: const TextStyle(
                    color: Color(0xFF6EE7B7),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Items
          if (visible.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: cashewTextGray400.withValues(alpha: 0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Text(
                'No scheduled transactions',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cashewTextGray500,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            )
          else
            ...visible.map((item) => _buildScheduledItem(item)),
        ],
      ),
    );
  }

  Widget _buildScheduledItem(ScheduledRecord item) {
    final style = _getCategoryStyle(item.category);
    final isUpcoming = _scheduledStatus == 'upcoming';
    final rowKey = item.selectionKey;
    final isSelected = _selectedScheduledKeys.contains(rowKey);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x242563EB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x4C60A5FA)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (style['bg'] as Color),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Icon(
              style['icon'] as IconData,
              color: style['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.cleanDescription.isNotEmpty
                      ? item.cleanDescription
                      : item.category,
                  style: const TextStyle(
                    color: Color(0xFFDBEAFE),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getRepeatLabel(item.repeat),
                  style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUpcoming)
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedScheduledKeys.remove(rowKey);
                  } else {
                    _selectedScheduledKeys.add(rowKey);
                  }
                });
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF7DD3FC).withValues(alpha: 0.5),
                  ),
                  color:
                      isSelected ? const Color(0x470E95E9) : Colors.transparent,
                ),
                child:
                    isSelected
                        ? const Icon(
                          Icons.check,
                          color: Color(0xFF7DD3FC),
                          size: 14,
                        )
                        : null,
              ),
            ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${item.amount.toLocaleString()}',
                style: const TextStyle(
                  color: Color(0xFF93C5FD),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                _formatDateWithDay(item.date),
                style: const TextStyle(
                  color: Color(0xFFDBEAFE),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (isUpcoming) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _addScheduledToCashew(item),
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0x242563EB),
                  border: Border.all(color: const Color(0x4C60A5FA)),
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF93C5FD),
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveSelectedScheduled() async {
    final selectedItems =
        _getVisibleScheduled()
            .where((item) => _selectedScheduledKeys.contains(item.selectionKey))
            .toList();
    if (selectedItems.isEmpty) return;
    setState(() => _isLoading = true);
    int success = 0;
    for (final item in selectedItems) {
      try {
        await _addScheduledToCashew(item);
        _selectedScheduledKeys.remove(item.selectionKey);
        success++;
      } catch (_) {}
    }
    if (success > 0) {
      _showToast('Saved $success transaction(s).');
    }
    setState(() => _isLoading = false);
  }

  Widget _buildSettingsModal() {
    return GestureDetector(
      onTap: () => setState(() => _settingsOpen = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 340,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 40)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.settings_rounded, color: cashewPrimary, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Cashew Settings',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _settingsOpen = false),
                        child: const Icon(Icons.close, color: Colors.white24, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'MONTHLY INCOME ($_selectedMonth $_selectedYear)',
                    style: TextStyle(
                      color: cashewTextGray400.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _incomeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                    decoration: _inputDeco('Enter amount', Icons.currency_rupee_rounded),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _settingsOpen = false;
                            _calcOpen = true;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.calculate_outlined, size: 16, color: Colors.white60),
                                SizedBox(width: 8),
                                Text('Calculator', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _saveMonthlyIncome,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: cashewPrimary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: cashewPrimary.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Save Income',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildLoader() {
    return Container(
      color: const Color(0xCC0F172A),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(color: cashewPrimary, strokeWidth: 3),
            ),
            SizedBox(height: 16),
            Text(
              'Analyzing Data',
              style: TextStyle(
                color: cashewTextWhite,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Please wait a moment',
              style: TextStyle(
                color: cashewTextGray400,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Calculator Modal ─────────────────────────────────────────────────────
  Widget _buildCalculatorModal() {
    return GestureDetector(
      onTap: () => setState(() => _calcOpen = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(28),
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
                      Row(
                        children: [
                          const Icon(
                            Icons.calculate,
                            color: cashewPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Calculator',
                            style: TextStyle(
                              color: cashewTextWhite,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _calcOpen = false),
                        child: const Icon(
                          Icons.close,
                          color: cashewTextGray500,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF020617).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
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
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _calcDisplay,
                          style: const TextStyle(
                            color: cashewTextWhite,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _calcButtonGrid(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _calcButtonGrid() {
    Widget btn(
      String label,
      Color bg,
      Color color,
      VoidCallback onTap, {
      int flex = 1,
    }) {
      return Expanded(
        flex: flex,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            btn('AC', cashewRose.withValues(alpha: 0.15), cashewRose, _calcClear, flex: 2),
            btn('⌫', Colors.white.withValues(alpha: 0.08), cashewTextGray400, _calcDelete),
            btn(
              '÷',
              cashewPrimary.withValues(alpha: 0.15),
              cashewPrimary,
              () => _calcAppend('/'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            btn(
              '7',
              Colors.white.withValues(alpha: 0.05),
              cashewTextWhite,
              () => _calcAppend('7'),
            ),
            btn(
              '8',
              Colors.white.withValues(alpha: 0.05),
              cashewTextWhite,
              () => _calcAppend('8'),
            ),
            btn(
              '9',
              Colors.white.withValues(alpha: 0.05),
              cashewTextWhite,
              () => _calcAppend('9'),
            ),
            btn(
              '×',
              cashewPrimary.withValues(alpha: 0.15),
              cashewPrimary,
              () => _calcAppend('*'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            btn(
              '4',
              Colors.white.withValues(alpha: 0.05),
              cashewTextWhite,
              () => _calcAppend('4'),
            ),
            btn(
              '5',
              Colors.white.withValues(alpha: 0.05),
              cashewTextWhite,
              () => _calcAppend('5'),
            ),
            btn(
              '6',
              Colors.white.withValues(alpha: 0.05),
              cashewTextWhite,
              () => _calcAppend('6'),
            ),
            btn(
              '−',
              cashewPrimary.withValues(alpha: 0.15),
              cashewPrimary,
              () => _calcAppend('-'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            btn(
              '1',
              Colors.white.withValues(alpha: 0.05),
              cashewTextWhite,
              () => _calcAppend('1'),
            ),
            btn(
              '2',
              Colors.white.withValues(alpha: 0.05),
              cashewTextWhite,
              () => _calcAppend('2'),
            ),
            btn(
              '3',
              Colors.white.withValues(alpha: 0.05),
              cashewTextWhite,
              () => _calcAppend('3'),
            ),
            btn(
              '+',
              cashewPrimary.withValues(alpha: 0.15),
              cashewPrimary,
              () => _calcAppend('+'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            btn(
              '0',
              Colors.white.withValues(alpha: 0.05),
              cashewTextWhite,
              () => _calcAppend('0'),
              flex: 2,
            ),
            btn(
              '.',
              Colors.white.withValues(alpha: 0.05),
              cashewTextWhite,
              () => _calcAppend('.'),
            ),
            btn('=', cashewEmerald, Colors.white, _calcResult),
          ],
        ),
      ],
    );
  }

  // ── Export Options Modal ──────────────────────────────────────────────────
  Widget _buildExportOptionsModal() {
    final definedCats = cashewCategories.where((c) => c != 'Select Category').toList();
    final dataCats = _allData
        .map((r) => r.category)
        .where((c) => c.isNotEmpty && c != 'Select Category')
        .toSet();
    final combinedCats = {...definedCats, ...dataCats}.toList()..sort();
    final allCats = ['All Categories', ...combinedCats];
    final years = List.generate(
      getIndiaTime().year - 2019,
      (i) => getIndiaTime().year - i,
    );

    return GestureDetector(
      onTap: () => setState(() => _exportOptionsOpen = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: MediaQuery.of(context).size.width - 32,
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF0F172A)
                    : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: cashewBorderWhite8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.file_upload_outlined,
                              color: cashewPrimary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Export Records',
                              style: TextStyle(
                                color: cashewTextWhite,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap:
                              () => setState(() => _exportOptionsOpen = false),
                          child: const Icon(
                            Icons.close,
                            color: cashewTextGray500,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: cashewBorderWhite5),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CATEGORY',
                          style: TextStyle(
                            color: cashewTextGray400,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: const {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.trackpad,
                              PointerDeviceKind.stylus,
                            },
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: allCats.map((c) {
                                final isSelected =
                                    _exportCategory == c ||
                                    (_exportCategory == 'All' && c == 'All Categories');
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _exportCategory = c;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? cashewPrimary
                                            : (Theme.of(context).brightness == Brightness.dark
                                                ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                                : Colors.white),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected ? cashewPrimary : cashewBorderWhite8,
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: cashewPrimary.withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isSelected) ...[
                                            const Icon(
                                              Icons.check_rounded,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 5),
                                          ],
                                          Text(
                                            c,
                                            style: TextStyle(
                                              color: isSelected ? Colors.white : cashewTextGray400,
                                              fontSize: 12,
                                              fontWeight:
                                                  isSelected ? FontWeight.w700 : FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => setState(() => _exportCurrentMonthOnly = !_exportCurrentMonthOnly),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: cashewBorderWhite8),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _exportCurrentMonthOnly,
                                    onChanged: (v) => setState(() => _exportCurrentMonthOnly = v!),
                                    activeColor: cashewPrimary,
                                    side: const BorderSide(color: cashewTextGray500),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Current Month Only',
                                  style: TextStyle(
                                    color: cashewTextWhite,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Date range
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'FROM',
                                    style: TextStyle(
                                      color: cashewTextGray400,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _dropdownSmall(
                                          value: _exportFromMonth,
                                          items: ktMonths
                                              .map(
                                                (m) => DropdownMenuItem(
                                                  value: m,
                                                  child: Text(m),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) => setState(() => _exportFromMonth = v!),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: _dropdownSmall(
                                          value: _exportFromYear,
                                          items: years
                                              .map(
                                                (y) => DropdownMenuItem(
                                                  value: y,
                                                  child: Text('$y'),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) => setState(() => _exportFromYear = v!),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TO',
                                    style: TextStyle(
                                      color: cashewTextGray400,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _dropdownSmall(
                                          value: _exportToMonth,
                                          items: ktMonths
                                              .map(
                                                (m) => DropdownMenuItem(
                                                  value: m,
                                                  child: Text(m),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) => setState(() => _exportToMonth = v!),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: _dropdownSmall(
                                          value: _exportToYear,
                                          items: years
                                              .map(
                                                (y) => DropdownMenuItem(
                                                  value: y,
                                                  child: Text('$y'),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) => setState(() => _exportToYear = v!),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: cashewBorderWhite5),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap:
                              () => setState(() => _exportOptionsOpen = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.transparent,
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                color: cashewTextGray400,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _generateExport,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: cashewPrimary,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: cashewPrimary.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Text(
                              'Generate Export',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
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
      ),
    );
  }

  Widget _dropdownSmall<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cashewBorderWhite8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(color: cashewTextWhite, fontSize: 12),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── Export Preview Modal ──────────────────────────────────────────────────
  Widget _buildExportPreviewModal() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width - 32,
          height: MediaQuery.of(context).size.height * 0.85,
          constraints: const BoxConstraints(maxWidth: 820),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF0F172A)
                : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: cashewBorderWhite8),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Export Preview',
                      style: TextStyle(
                        color: cashewTextWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _exportPreviewOpen = false),
                      child: const Icon(
                        Icons.close,
                        color: cashewTextGray500,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: cashewBorderWhite5),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF030712),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cashewBorderWhite8),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(
                      _exportPreviewContent,
                      style: const TextStyle(
                        color: Color(0xFFA5B4FC),
                        fontSize: 11,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: cashewBorderWhite5),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _exportPreviewOpen = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: cashewTextGray400,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _copyExport,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: cashewBorderWhite8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 15, color: cashewTextWhite),
                            SizedBox(width: 6),
                            Text(
                              'Copy',
                              style: TextStyle(
                                color: cashewTextWhite,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _exportPdf,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF43F5E),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF43F5E).withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.picture_as_pdf_rounded, size: 15, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'PDF',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _exportTxt,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.download_rounded, size: 15, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              '.TXT',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
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
    );
  }

  // ── Category Transactions Modal ───────────────────────────────────────────
  Widget _buildCategoryTxnModal() {
    final style = _getCategoryStyle(_categoryTxnName);
    var txns = _allData.where((r) => r.category == _categoryTxnName).toList();

    if (_categoryTxnDate != null) {
      txns = txns.where((r) => _formatDateDisplay(r.date) == _categoryTxnDate).toList();
    }

    final total = txns.fold(0.0, (s, r) => s + r.amount);

    // Group by date
    final byDate = <String, List<CashewRecord>>{};
    for (final r in txns) {
      final d = _formatDateDisplay(r.date);
      byDate.putIfAbsent(d, () => []).add(r);
    }
    final sortedDates =
        byDate.keys.toList()..sort((a, b) {
          final da = _parseDate(a), db = _parseDate(b);
          if (da == null || db == null) return 0;
          return da.compareTo(db);
        });

    return GestureDetector(
      onTap: () => setState(() => _categoryTxnOpen = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cashewPrimary.withValues(alpha: 0.07),
                      border: const Border(
                        bottom: BorderSide(color: cashewBorderWhite8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: (style['bg'] as Color),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            style['icon'] as IconData,
                            color: style['color'] as Color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _categoryTxnDate != null 
                                  ? '$_categoryTxnName ($_categoryTxnDate)' 
                                  : _categoryTxnName,
                                style: const TextStyle(
                                  color: cashewTextWhite,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${txns.length} transaction${txns.length != 1 ? 's' : ''}',
                                style: const TextStyle(
                                  color: cashewTextGray400,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _categoryTxnOpen = false),
                          child: const Icon(
                            Icons.close,
                            color: cashewTextGray500,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Summary
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0x40000000),
                      border: Border(bottom: BorderSide(color: cashewBorderWhite5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.list_alt_outlined,
                              color: cashewTextGray500,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${txns.length}',
                              style: const TextStyle(
                                color: cashewTextWhite,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Text(
                              ' entries',
                              style: TextStyle(color: cashewTextGray500),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.currency_rupee,
                              color: cashewEmerald,
                              size: 12,
                            ),
                            Text(
                              'Rs. ${total.toLocaleString()}',
                              style: const TextStyle(
                                color: Color(0xFF6EE7B7),
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // List
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: sortedDates.length,
                      itemBuilder: (ctx, i) {
                        final date = sortedDates[i];
                        final rows = byDate[date]!;
                        final dayTotal = rows.fold(0.0, (s, r) => s + r.amount);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 11,
                                          color: cashewTextGray500,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          date,
                                          style: const TextStyle(
                                            color: cashewTextGray400,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Rs. ${dayTotal.toLocaleString()}',
                                      style: const TextStyle(
                                        color: cashewTextGray400,
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...rows.map(
                                (r) => Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.03),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          r.description.isNotEmpty
                                              ? r.description
                                              : '—',
                                          style: const TextStyle(
                                            color: cashewTextGray400,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Rs. ${r.amount.toLocaleString()}',
                                        style: const TextStyle(
                                          color: cashewTextWhite,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
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
          ),
        ),
      ),
    );
  }

  // ── Missed Dates Modal ─────────────────────────────────────────────────────
  Widget _buildMissedDatesModal() {
    return GestureDetector(
      onTap: () => setState(() => _missedDatesOpen = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: MediaQuery.of(context).size.width - 32,
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: cashewBorderWhite8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.event_busy, color: cashewRose, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Missed Dates',
                              style: TextStyle(
                                color: cashewTextWhite,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _missedDatesOpen = false),
                          child: const Icon(
                            Icons.close,
                            color: cashewTextGray500,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: cashewBorderWhite5),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _missedDates.isEmpty
                              ? 'No missed days in selected range.'
                              : '${_missedDates.length} missed day${_missedDates.length != 1 ? 's' : ''} found.',
                          style: const TextStyle(
                            color: cashewTextGray400,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 280),
                          child:
                              _missedDates.isEmpty
                                  ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cashewEmerald.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: cashewEmerald.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'All dates have entries.',
                                        style: TextStyle(
                                          color: cashewEmerald,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _missedDates.length,
                                    itemBuilder:
                                        (ctx, i) => Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: cashewRose.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: cashewRose.withValues(alpha: 0.2),
                                            ),
                                          ),
                                          child: Text(
                                            _missedDates[i],
                                            style: const TextStyle(
                                              color: Color(0xFFFCA5A5),
                                              fontWeight: FontWeight.w600,
                                            ),
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
      ),
    );
  }

  // ── Add Scheduled Modal ───────────────────────────────────────────────────
  Widget _buildAddScheduledModal() {
    return GestureDetector(
      onTap: () => setState(() => _addScheduledOpen = false),
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: MediaQuery.of(context).size.width - 32,
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: MediaQuery.of(context).size.height * 0.86,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: cashewBorderWhite8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                color: Color(0xFFC084FC),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Add Scheduled',
                                style: TextStyle(
                                  color: cashewTextWhite,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap:
                                () => setState(() => _addScheduledOpen = false),
                            child: const Icon(
                              Icons.close,
                              color: cashewTextGray500,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: cashewBorderWhite5),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _scheduledDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  builder:
                                      (ctx, child) => Theme(
                                        data: ThemeData.dark().copyWith(
                                          colorScheme: const ColorScheme.dark(
                                            primary: cashewPrimary,
                                          ),
                                        ),
                                        child: child!,
                                      ),
                                );
                                if (picked != null) {
                                  setState(() => _scheduledDate = picked);
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0F172A,
                                  ).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cashewBorderWhite8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: cashewTextGray500,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      ktFormatDate(_scheduledDate),
                                      style: const TextStyle(
                                        color: cashewTextWhite,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _scheduledFormField(
                              label: 'CATEGORY',
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _scheduledCategory,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF1E293B),
                                  style: const TextStyle(
                                    color: cashewTextWhite,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items:
                                      cashewCategories
                                          .map(
                                            (c) => DropdownMenuItem(
                                              value: c,
                                              child: Text(c),
                                            ),
                                          )
                                          .toList(),
                                  onChanged:
                                      (v) => setState(
                                        () => _scheduledCategory = v!,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _scheduledDescCtrl,
                              style: const TextStyle(
                                color: cashewTextWhite,
                                fontSize: 13,
                              ),
                              decoration: _inputDeco(
                                'Description',
                                Icons.description_outlined,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _scheduledFormField(
                              label: 'REPEAT',
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _scheduledRepeat,
                                  isExpanded: true,
                                  dropdownColor: const Color(0xFF1E293B),
                                  style: const TextStyle(
                                    color: cashewTextWhite,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'none',
                                      child: Text('Does not repeat'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'monthly',
                                      child: Text('Repeats monthly'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'yearly',
                                      child: Text('Repeats yearly'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'weekly',
                                      child: Text('Repeats weekly'),
                                    ),
                                  ],
                                  onChanged:
                                      (v) =>
                                          setState(() => _scheduledRepeat = v!),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: _scheduledAmountCtrl,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: const TextStyle(
                                color: cashewTextWhite,
                                fontSize: 13,
                              ),
                              decoration: _inputDeco(
                                'Amount',
                                Icons.currency_rupee_outlined,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: cashewBorderWhite5),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap:
                                () => setState(() => _addScheduledOpen = false),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: cashewTextGray400,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _saveScheduledTransaction,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: cashewPrimary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Save',
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
        ),
      ),
    );
  }

  Widget _scheduledFormField({required String label, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cashewBorderWhite8),
      ),
      child: child,
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: cashewTextGray400, fontSize: 12),
      prefixIcon: Icon(icon, color: cashewTextGray500, size: 18),
      filled: true,
      fillColor: const Color(0xFF0F172A).withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cashewBorderWhite8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cashewBorderWhite8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cashewPrimary),
      ),
    );
  }
}

// ── Background glow widget ─────────────────────────────────────────────────
class _BgGlow extends StatelessWidget {
  const _BgGlow();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -60,
          left: -60,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -60,
          right: -60,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFF43F5E).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height / 2 - 200,
          left: MediaQuery.of(context).size.width / 2 - 200,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFA855F7).withValues(alpha: 0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Number formatting extension ────────────────────────────────────────────
extension _NumberFormat on double {
  String toLocaleString() {
    final formatted = toStringAsFixed(2);
    final parts = formatted.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    // Indian number formatting
    if (intPart.length <= 3) return '$intPart.$decPart';
    final lastThree = intPart.substring(intPart.length - 3);
    final rest = intPart.substring(0, intPart.length - 3);
    final withCommas = rest.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+$)'),
      (m) => '${m[1]},',
    );
    return '$withCommas,$lastThree.$decPart';
  }
}
