import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'milk_report_screen.dart';

// ── Colours matching milk.html exactly ─────────────────────────────────────
const _bgDark = Color(0xFF0B0F19);
const _cardBg = Color(0xFF151A25);
const _slate800 = Color(0xFF1E293B);
const _primary = Color(0xFF6366F1);
const _emerald = Color(0xFF10B981);
const _orange = Color(0xFFFB923C);
const _rose = Color(0xFFEF4444);
const _textWhite = Colors.white;
const _textGray400 = Color(0xFF94A3B8);
const _textGray500 = Color(0xFF64748B);
const _borderWhite10 = Color(0x1AFFFFFF);
const _borderWhite5 = Color(0x0DFFFFFF);

const _milkSheetUrl =
    'https://script.google.com/macros/s/AKfycbw9HPgLQojIqypEKeaCpwdZtdXmM7gqANY8LFWLWUAe5CNexRLTyrrX6JLFmiZC03B4CQ/exec';

const _unitPrice = 80.0;
const _defaultMorning = 1.5;
const _defaultEvening = 0.5;

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

// ════════════════════════════════════════════════════════════════════════════
// MilkScreen
// ════════════════════════════════════════════════════════════════════════════
class MilkScreen extends StatefulWidget {
  const MilkScreen({super.key});

  @override
  State<MilkScreen> createState() => _MilkScreenState();
}

class _MilkScreenState extends State<MilkScreen> {
  // ── date ─────────────────────────────────────────────────────────────────
  DateTime _selectedDate = DateTime.now();
  String _saveStatus = 'checking'; // checking, saved, draft, no-data
  bool _isLoading = false;
  String _loadingText = '';

  // ── inputs ──────────────────────────────────────────────────────────────
  final TextEditingController _morningController =
      TextEditingController(text: _defaultMorning.toString());
  final TextEditingController _eveningController =
      TextEditingController(text: _defaultEvening.toString());
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _dailyCostController = TextEditingController();
  bool _isDailyCostManual = false;

  // ── calendar accordion ────────────────────────────────────────────────────
  bool _calendarOpen = false;
  List<String> _existingDates = [];
  Map<String, String> _dateStageMap = {}; // date string → 'draft' | 'completed'

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _checkEditData();
    _fetchDataForDate(_selectedDate);
    _morningController.addListener(_calculateDaily);
    _eveningController.addListener(_calculateDaily);
  }

  @override
  void dispose() {
    _morningController.dispose();
    _eveningController.dispose();
    _remarksController.dispose();
    _dailyCostController.dispose();
    super.dispose();
  }

  // ── Check for edit data from report screen ──────────────────────────────
  void _checkEditData() {
    // This would typically use SharedPreferences or a state management solution
    // For now, we'll handle this through the constructor or navigation arguments
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  String _fmtDDMMMYYYY(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${_months[d.month - 1]}/${d.year}';
  }

  DateTime? _parseDDMMMYYYY(String s) {
    final m = RegExp(r'^(\d{1,2})/(\w{3})/(\d{4})$').firstMatch(s.trim());
    if (m == null) return null;
    const mo = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12
    };
    return DateTime(
      int.tryParse(m.group(3)!) ?? 2024,
      mo[m.group(2)!.toLowerCase()] ?? 1,
      int.tryParse(m.group(1)!) ?? 1,
    );
  }

  String _sheetNameFromDate(DateTime d) {
    return '${_months[d.month - 1]} ${d.year}';
  }

  double get _morningValue => double.tryParse(_morningController.text) ?? 0;
  double get _eveningValue => double.tryParse(_eveningController.text) ?? 0;
  double get _dailyTotal => _morningValue + _eveningValue;

  double get _dailyCost {
    if (_isDailyCostManual) {
      return double.tryParse(_dailyCostController.text) ?? 0;
    }
    return _dailyTotal * _unitPrice;
  }

  void _calculateDaily() {
    if (!_isDailyCostManual) {
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
      final url =
          '$_milkSheetUrl?sheetName=${Uri.encodeComponent(sheetName)}&t=${DateTime.now().millisecondsSinceEpoch}';
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final allRows = (data['data'] as List? ?? []);

      // Build date stage map
      _dateStageMap.clear();
      _existingDates.clear();
      for (final row in allRows) {
        final dateStr = _normalizeSheetDate(row['date']?.toString() ?? '');
        if (dateStr.isNotEmpty) {
          _existingDates.add(dateStr);
          _dateStageMap[dateStr] =
              (row['stage']?.toString() ?? 'completed').toLowerCase();
        }
      }

      // Find data for selected date
      final forDate = allRows.where((e) {
        final rowDate = _normalizeSheetDate(e['date']?.toString() ?? '');
        return rowDate == formattedDate;
      }).toList();

      if (forDate.isNotEmpty) {
        final row = forDate.first;
        final morning = double.tryParse('${row['morning'] ?? ''}') ?? _defaultMorning;
        final evening = double.tryParse('${row['evening'] ?? ''}') ?? _defaultEvening;
        final stage = (row['stage']?.toString() ?? 'completed').toLowerCase();

        _morningController.text = morning.toString();
        _eveningController.text = evening.toString();
        _remarksController.text = row['remarks']?.toString() ?? '';

        if (_isDailyCostManual) {
          _toggleDailyCostEdit();
        }

        setState(() {
          _saveStatus = stage == 'draft' ? 'draft' : 'saved';
        });
      } else {
        _morningController.text = _defaultMorning.toString();
        _eveningController.text = _defaultEvening.toString();
        _remarksController.clear();
        if (_isDailyCostManual) {
          _toggleDailyCostEdit();
        }
        setState(() => _saveStatus = 'no-data');
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
      setState(() => _saveStatus = 'no-data');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _normalizeSheetDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    final normalized = dateStr.trim();
    if (RegExp(r'^\d{2}/[A-Za-z]{3}/\d{4}$').hasMatch(normalized)) {
      return normalized;
    }
    try {
      // Try parsing as input date format (YYYY-MM-DD)
      final parts = normalized.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return _fmtDDMMMYYYY(DateTime(year, month, day));
      }
    } catch (_) {}
    return '';
  }

  // ── Toggle daily cost edit ────────────────────────────────────────────────
  void _toggleDailyCostEdit() {
    setState(() {
      _isDailyCostManual = !_isDailyCostManual;
      if (_isDailyCostManual) {
        _dailyCostController.text = _dailyCost.toStringAsFixed(2);
      }
    });
  }

  // ── Clear inputs ──────────────────────────────────────────────────────────
  void _clearInputs() {
    setState(() {
      _morningController.text = _defaultMorning.toString();
      _eveningController.text = _defaultEvening.toString();
      _remarksController.clear();
      if (_isDailyCostManual) {
        _toggleDailyCostEdit();
      }
    });
  }

  // ── Change date ───────────────────────────────────────────────────────────
  void _changeDate(int days) {
    final next = _selectedDate.add(Duration(days: days));
    if (next.isAfter(DateTime.now())) return;
    setState(() => _selectedDate = next);
    _fetchDataForDate(next);
  }

  // ── Save data ─────────────────────────────────────────────────────────────
  Future<void> _saveMilkData(String status) async {
    final morning = _morningValue;
    final evening = _eveningValue;
    final remarks = _remarksController.text;
    final normalizedStage = status.toLowerCase() == 'draft' ? 'draft' : 'completed';
    final dailyCost = _dailyCost;

    if (_selectedDate.year == 0) {
      _showAlert('Error', 'Please select a date', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingText = 'Saving...';
    });

    final date = _fmtDDMMMYYYY(_selectedDate);

    final payload = {
      'type': 'milk',
      'action': 'add',
      'date': date,
      'morning': morning,
      'evening': evening,
      'unitPrice': _unitPrice,
      'dailyCost': dailyCost,
      'remarks': remarks,
      'stage': normalizedStage,
    };

    try {
      await http.post(
        Uri.parse(_milkSheetUrl),
        body: jsonEncode(payload),
      );

      setState(() {
        _saveStatus = normalizedStage == 'draft' ? 'draft' : 'saved';
      });

      _showAlert(
        'Success',
        'Data saved successfully! Stage: ${normalizedStage == 'draft' ? 'Draft' : 'Completed'}',
      );

      _clearInputs();

      // Move to next day
      final nextDay = _selectedDate.add(const Duration(days: 1));
      if (!nextDay.isAfter(DateTime.now())) {
        setState(() => _selectedDate = nextDay);
        await _fetchDataForDate(nextDay);
      }
    } catch (e) {
      _showAlert('Error', 'Error saving data: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAlert(String title, String message, {bool isError = false}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? _rose : _emerald, size: 22),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: _textWhite, fontWeight: FontWeight.w700)),
        ]),
        content: Text(message,
            style: const TextStyle(color: _textGray400, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK',
                  style: TextStyle(
                      color: _primary, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
          data: ThemeData.dark()
              .copyWith(colorScheme: const ColorScheme.dark(primary: _primary)),
          child: child!),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchDataForDate(picked);
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _darkTheme(),
      child: Scaffold(
        backgroundColor: _bgDark,
        appBar: _buildAppBar(),
        body: Stack(children: [
          _buildBgGlows(),
          Column(children: [
            Expanded(
                child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(children: [
                _buildDateNavigator(),
                const SizedBox(height: 12),
                _buildCalendarAccordion(),
                const SizedBox(height: 12),
                _buildCollectionInputs(),
                const SizedBox(height: 12),
                _buildTotalsCard(),
                const SizedBox(height: 12),
                _buildRemarksInput(),
              ]),
            )),
            _buildBottomBar(),
          ]),
          if (_isLoading) _buildLoader(),
        ]),
      ),
    );
  }

  ThemeData _darkTheme() => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bgDark,
        colorScheme: const ColorScheme.dark(
            surface: _cardBg, primary: _primary, onSurface: _textWhite),
        fontFamily: 'Plus Jakarta Sans',
      );

  Widget _buildBgGlows() {
    return Stack(children: [
      Positioned(
          top: -60,
          left: -60,
          child: _glowCircle(const Color(0xFF6366F1), 0.2)),
      Positioned(
          bottom: -60,
          right: -60,
          child: _glowCircle(const Color(0xFF3B82F6), 0.2)),
    ]);
  }

  Widget _glowCircle(Color color, double opacity) => Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [color.withValues(alpha: opacity), Colors.transparent]),
        ),
      );

  // ── AppBar ────────────────────────────────────────────────────────────────
  AppBar _buildAppBar() => AppBar(
        backgroundColor: const Color(0xFF0B0F19).withValues(alpha: 0.9),
        elevation: 0,
        titleSpacing: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF3B82F6)]),
            boxShadow: [
              BoxShadow(color: _primary.withValues(alpha: 0.3), blurRadius: 8)
            ],
          ),
          child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
        ),
        title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Milk Bill',
                  style: TextStyle(
                      color: _textWhite,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              Text('Daily Tracker',
                  style: TextStyle(color: _textGray400, fontSize: 10)),
            ]),
        actions: [
          _iconBtn(Icons.pie_chart_rounded, () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MilkReportScreen()))),
          _iconBtn(Icons.home_rounded, () => Navigator.pop(context)),
          const SizedBox(width: 8),
        ],
      );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: _borderWhite5),
            ),
            child: Icon(icon, color: _textGray400, size: 18),
          ),
        ),
      );

  // ── Date Navigator ────────────────────────────────────────────────────────
  Widget _buildDateNavigator() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('DATE',
              style: TextStyle(
                  color: _textGray500,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4)),
          const SizedBox(height: 8),
          Row(children: [
            _navBtn(Icons.chevron_left, () => _changeDate(-1)),
            Expanded(
                child: GestureDetector(
              onTap: _pickDate,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderWhite10),
                ),
                child: Text(
                    DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: _textWhite,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            )),
            _navBtn(Icons.chevron_right, () => _changeDate(1)),
          ]),
          const SizedBox(height: 10),
          Center(child: _saveStatusBadge()),
        ]),
      );

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _borderWhite10),
          ),
          child: Icon(icon, color: _textGray400, size: 20),
        ),
      );

  Widget _saveStatusBadge() {
    Color bg, tc, bc;
    String label;
    switch (_saveStatus) {
      case 'saved':
        bg = _emerald.withValues(alpha: 0.15);
        tc = _emerald;
        bc = _emerald.withValues(alpha: 0.4);
        label = '● Done';
      case 'draft':
        bg = _orange.withValues(alpha: 0.15);
        tc = _orange;
        bc = _orange.withValues(alpha: 0.4);
        label = '● Draft';
      case 'no-data':
        bg = _rose.withValues(alpha: 0.15);
        tc = _rose;
        bc = _rose.withValues(alpha: 0.4);
        label = '● No Data';
      default:
        bg = _textGray500.withValues(alpha: 0.15);
        tc = _textGray400;
        bc = _textGray500.withValues(alpha: 0.3);
        label = '● Checking...';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: bc)),
      child: Text(label,
          style: TextStyle(
              color: tc,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6)),
    );
  }

  // ── Calendar accordion ────────────────────────────────────────────────────
  Widget _buildCalendarAccordion() => Container(
        decoration: BoxDecoration(
          color: _slate800.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(children: [
          GestureDetector(
            onTap: () => setState(() => _calendarOpen = !_calendarOpen),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: _primary.withValues(alpha: 0.2)),
                    child: const Icon(Icons.calendar_month,
                        color: _primary, size: 18)),
                const SizedBox(width: 12),
                Text(_sheetNameFromDate(_selectedDate),
                    style: const TextStyle(
                        color: _textWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5)),
                const Spacer(),
                AnimatedRotation(
                  turns: _calendarOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down,
                      color: _textGray400, size: 20),
                ),
              ]),
            ),
          ),
          if (_calendarOpen) ...[
            const Divider(height: 1, color: _borderWhite5),
            Padding(padding: const EdgeInsets.all(12), child: _buildCalGrid()),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendDot(_emerald.withValues(alpha: 0.15),
                        _emerald.withValues(alpha: 0.2), _emerald, 'Done'),
                    const SizedBox(width: 16),
                    _legendDot(_orange.withValues(alpha: 0.18),
                        _orange.withValues(alpha: 0.3), _orange, 'Draft'),
                    const SizedBox(width: 16),
                    _legendDot(Colors.white.withValues(alpha: 0.02),
                        Colors.white.withValues(alpha: 0.1), _textGray500, 'Empty'),
                  ]),
            ),
          ],
        ]),
      );

  Widget _legendDot(Color bg, Color border, Color textColor, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: border))),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: textColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0)),
        ],
      );

  Widget _buildCalGrid() {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final year = _selectedDate.year;
    final month = _selectedDate.month;
    final firstDay = DateTime(year, month, 1).weekday % 7;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    return Column(children: [
      Row(
          children: days
              .map((d) => Expanded(
                    child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                color: _textGray500,
                                fontSize: 10,
                                fontWeight: FontWeight.w700))),
                  ))
              .toList()),
      const SizedBox(height: 6),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, mainAxisSpacing: 2, crossAxisSpacing: 2),
        itemCount: firstDay + daysInMonth,
        itemBuilder: (ctx, i) {
          if (i < firstDay) return const SizedBox.shrink();
          final day = i - firstDay + 1;
          final dayStr = day.toString().padLeft(2, '0');
          final fullDate = '$dayStr/${_months[month - 1]}/$year';
          final hasData = _existingDates.contains(fullDate);
          final stage = _dateStageMap[fullDate] ?? '';
          final isDraft = hasData && stage == 'draft';
          final isSel = day == _selectedDate.day;

          Color bg, tc;
          Color? bc;
          if (isSel) {
            bg = _primary;
            tc = Colors.white;
            bc = _primary;
          } else if (isDraft) {
            bg = _orange.withValues(alpha: 0.18);
            tc = _orange;
            bc = _orange.withValues(alpha: 0.28);
          } else if (hasData) {
            bg = _emerald.withValues(alpha: 0.15);
            tc = _emerald;
            bc = _emerald.withValues(alpha: 0.2);
          } else {
            bg = Colors.white.withValues(alpha: 0.02);
            tc = _textGray400;
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
                borderRadius: BorderRadius.circular(8),
                border: bc != null ? Border.all(color: bc) : null,
                boxShadow: isSel
                    ? [
                        BoxShadow(
                            color: _primary.withValues(alpha: 0.4),
                            blurRadius: 12)
                      ]
                    : null,
              ),
              child: Center(
                  child: Text('$day',
                      style: TextStyle(
                          color: tc,
                          fontSize: 13,
                          fontWeight: FontWeight.w600))),
            ),
          );
        },
      ),
    ]);
  }

  // ── Collection inputs ─────────────────────────────────────────────────────
  Widget _buildCollectionInputs() => Row(
        children: [
          Expanded(child: _buildCollectionInput(
            label: 'MORNING COLLECTION (LITERS)',
            icon: Icons.wb_sunny_rounded,
            controller: _morningController,
            iconColor: _primary,
          )),
          const SizedBox(width: 12),
          Expanded(child: _buildCollectionInput(
            label: 'EVENING COLLECTION (LITERS)',
            icon: Icons.nightlight_round,
            controller: _eveningController,
            iconColor: _primary,
          )),
        ],
      );

  Widget _buildCollectionInput({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color iconColor,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: _textGray500,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderWhite10),
            ),
            child: Row(children: [
              Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(icon, color: iconColor, size: 18)),
              Expanded(
                  child: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                ],
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: _textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: '0.0',
                  hintStyle: TextStyle(color: _textGray500),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              )),
            ]),
          ),
        ]),
      );

  // ── Totals card ───────────────────────────────────────────────────────────
  Widget _buildTotalsCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _primary.withValues(alpha: 0.3)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        child: Column(children: [
          Row(children: [
            Expanded(child: _totalItem('DAILY TOTAL', '${_dailyTotal.toStringAsFixed(1)} L', _textWhite)),
            Expanded(child: _totalItem('UNIT PRICE', '₹${_unitPrice.toInt()}', _textWhite)),
            Expanded(child: Column(children: [
              _totalItem('DAILY COST', '₹${_dailyCost.toStringAsFixed(2)}', _emerald),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _toggleDailyCostEdit,
                child: Text(
                  _isDailyCostManual ? 'Auto Cost' : 'Edit Cost',
                  style: TextStyle(
                      color: _primary.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ])),
          ]),
          if (_isDailyCostManual) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('MANUAL DAILY COST (INR)',
                    style: TextStyle(
                        color: _textGray500,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderWhite10),
                  ),
                  child: TextField(
                    controller: _dailyCostController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                    ],
                    style: const TextStyle(
                        color: _emerald,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace'),
                    decoration: const InputDecoration(
                      hintText: '160.00',
                      hintStyle: TextStyle(color: _textGray500),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ]),
            ),
          ],
        ]),
      );

  Widget _totalItem(String label, String value, Color valueColor) => Column(
        children: [
          Text(label,
              style: const TextStyle(
                  color: _textGray500,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace')),
        ],
      );

  // ── Remarks input ─────────────────────────────────────────────────────────
  Widget _buildRemarksInput() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('REMARKS / ADDRESS',
              style: TextStyle(
                  color: _textGray500,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderWhite10),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                  padding: EdgeInsets.only(left: 12, top: 14),
                  child: Icon(Icons.comment, color: _primary, size: 18)),
              Expanded(
                  child: TextField(
                controller: _remarksController,
                maxLines: 3,
                style: const TextStyle(
                    color: _textGray400, fontSize: 14, height: 1.5),
                decoration: const InputDecoration(
                  hintText: 'Enter remarks...',
                  hintStyle: TextStyle(color: _textGray500, fontSize: 13),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              )),
            ]),
          ),
        ]),
      );

  // ── Bottom bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0F19).withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: _borderWhite10)),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20)],
      ),
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: _clearInputs,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderWhite5),
              ),
              child: const Icon(Icons.delete_outline, color: _textGray400, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _saveMilkData('draft'),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: _textGray500.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit_note, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Draft',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _saveMilkData('completed'),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF3B82F6)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: _primary.withValues(alpha: 0.3), blurRadius: 12)
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Save',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loader ────────────────────────────────────────────────────────────────
  Widget _buildLoader() => Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(color: _primary, strokeWidth: 3)),
          const SizedBox(height: 16),
          Text(_loadingText,
              style: const TextStyle(
                  color: _textWhite, fontSize: 14, fontWeight: FontWeight.w500)),
        ])),
      );
}

