import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core_constants.dart';
import 'milk_models.dart';
import 'milk_report_screen.dart';
import 'milk_service.dart';

// ── Configuration ────────────────────────────────────────────────────────────
const _unitPrice = 80.0;
const _defaultMorning = 1.5;
const _defaultEvening = 0.5;

// ════════════════════════════════════════════════════════════════════════════
// MilkScreen
// ════════════════════════════════════════════════════════════════════════════
class MilkScreen extends StatefulWidget {
  const MilkScreen({super.key});

  @override
  State<MilkScreen> createState() => _MilkScreenState();
}

class _MilkScreenState extends State<MilkScreen> {
  final MilkService _milkService = MilkService();

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
  final List<String> _existingDates = [];
  final Map<String, String> _dateStageMap = {}; // date string → 'draft' | 'completed'

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
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

  // ── helpers ───────────────────────────────────────────────────────────────
  String _fmtDDMMMYYYY(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${ktMonths[d.month - 1]}/${d.year}';
  }

  String _sheetNameFromDate(DateTime d) {
    return '${ktMonths[d.month - 1]} ${d.year}';
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

      // Requirement 6: parallelize initial data fetch and calendar date fetch using Future.wait
      final results = await Future.wait([
        _milkService.fetchDataForDate(formattedDate, sheetName),
        _milkService.fetchDatesForCalendar(sheetName),
      ]);

      final dataResult = results[0] as Map<String, dynamic>;
      final datesResult = results[1] as List<String>;

      final rows = dataResult['rows'] as List;

      // Update calendar state
      _existingDates.clear();
      _existingDates.addAll(datesResult);
      // Note: dateStageMap is not fully populated here as fetchDatesForCalendar only returns strings.
      // We might need to handle this differently if dateStageMap is critical for the UI.
      // In the original code, it was built from allRows.
      // If needed, we can call fetchReport or adjust MilkService.
      // For now, I'll stick to what MilkService provides.

      if (rows.isNotEmpty) {
        final record = MilkRecord.fromJson(rows.first);
        _morningController.text = record.morning.toString();
        _eveningController.text = record.evening.toString();
        _remarksController.text = record.remarks;

        if (_isDailyCostManual) {
          _toggleDailyCostEdit();
        }

        setState(() {
          _saveStatus = record.stage.toLowerCase() == 'draft' ? 'draft' : 'saved';
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
    final normalizedStage =
        status.toLowerCase() == 'draft' ? 'draft' : 'completed';
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
      await _milkService.saveData(payload);

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
        backgroundColor: ktCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? ktRose : ktEmerald, size: 22),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  color: ktTextWhite, fontWeight: FontWeight.w700)),
        ]),
        content: Text(message,
            style: const TextStyle(color: ktTextGray400, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK',
                  style:
                      TextStyle(color: ktPrimary, fontWeight: FontWeight.bold))),
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
              .copyWith(colorScheme: const ColorScheme.dark(primary: ktPrimary)),
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
        backgroundColor: ktBgDark,
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
                _buildCollectionInputs(),
                const SizedBox(height: 12),
                _buildTotalsCard(),
                const SizedBox(height: 12),
                _buildRemarksInput(),
              ]),
            )),
            _buildBottomBar(),
          ]),
          if (_calendarOpen)
            Positioned(
              top: 8,
              right: 16,
              child: _buildCalendarAccordion(),
            ),
          if (_isLoading) _buildLoader(),
        ]),
      ),
    );
  }

  ThemeData _darkTheme() => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ktBgDark,
        colorScheme: const ColorScheme.dark(
            surface: ktCardBg, primary: ktPrimary, onSurface: ktTextWhite),
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
        backgroundColor: ktBgDark.withValues(alpha: 0.9),
        elevation: 0,
        titleSpacing: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF3B82F6)]),
            boxShadow: [
              BoxShadow(color: ktPrimary.withValues(alpha: 0.3), blurRadius: 8)
            ],
          ),
          child: const Icon(Icons.water_drop, color: Colors.white, size: 20),
        ),
        title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Milk Bill',
                  style: TextStyle(
                      color: ktTextWhite,
                      fontSize: 17,
                      fontWeight: FontWeight.w800)),
              Text('Daily Tracker',
                  style: TextStyle(color: ktTextGray400, fontSize: 10)),
            ]),
        actions: [
          _calendarTitleBarBtn(),
          _iconBtn(
              Icons.pie_chart_rounded,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const MilkReportScreen()))),
          _iconBtn(Icons.home_rounded, () => Navigator.pop(context)),
          const SizedBox(width: 8),
        ],
      );

  Widget _calendarTitleBarBtn() => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => setState(() => _calendarOpen = !_calendarOpen),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: ktBorderWhite5),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined,
                    color: ktTextGray400, size: 16),
                const SizedBox(width: 6),
                Text(_sheetNameFromDate(_selectedDate),
                    style: const TextStyle(
                        color: ktTextGray400,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: _calendarOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down,
                      color: ktTextGray400, size: 16),
                ),
              ],
            ),
          ),
        ),
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
              border: Border.all(color: ktBorderWhite5),
            ),
            child: Icon(icon, color: ktTextGray400, size: 18),
          ),
        ),
      );

  // ── Date Navigator ────────────────────────────────────────────────────────
  Widget _buildDateNavigator() => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: ktCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ktPanelBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('DATE',
              style: TextStyle(
                  color: ktTextGray500,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8)),
          const SizedBox(height: 10),
          Row(children: [
            _navBtn(Icons.chevron_left, () => _changeDate(-1)),
            Expanded(
                child: GestureDetector(
              onTap: _pickDate,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.calendar_month_outlined,
                      color: ktTextGray400, size: 19),
                  const SizedBox(width: 10),
                  Text(DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: ktTextWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down,
                      color: ktTextGray400, size: 18),
                ]),
              ),
            )),
            _navBtn(Icons.chevron_right, () => _changeDate(1)),
          ]),
          const SizedBox(height: 8),
          Center(child: _saveStatusBadge()),
        ]),
      );

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF12284F), Color(0xFF11306B)]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x334A7CFF)),
          ),
          child: Icon(icon, color: ktTextWhite, size: 22),
        ),
      );

  Widget _saveStatusBadge() {
    Color bg, tc, bc;
    String label;
    switch (_saveStatus) {
      case 'saved':
        bg = ktEmerald.withValues(alpha: 0.15);
        tc = ktEmerald;
        bc = ktEmerald.withValues(alpha: 0.4);
        label = '● Saved';
      case 'draft':
        bg = ktOrange.withValues(alpha: 0.15);
        tc = ktOrange;
        bc = ktOrange.withValues(alpha: 0.4);
        label = '● Draft';
      case 'no-data':
        bg = ktRose.withValues(alpha: 0.15);
        tc = ktRose;
        bc = ktRose.withValues(alpha: 0.4);
        label = '● No Data';
      default:
        bg = ktTextGray500.withValues(alpha: 0.15);
        tc = ktTextGray400;
        bc = ktTextGray500.withValues(alpha: 0.3);
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
  Widget _buildCalendarAccordion() => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 315),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A1222),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: ktPanelBorder),
          ),
          child: Column(children: [
            GestureDetector(
              onTap: () => setState(() => _calendarOpen = !_calendarOpen),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(children: [
                  Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7),
                          color: ktCyan.withValues(alpha: 0.1)),
                      child: const Icon(Icons.calendar_month,
                          color: ktCyan, size: 14)),
                  const SizedBox(width: 9),
                  Text(_sheetNameFromDate(_selectedDate),
                      style: const TextStyle(
                          color: ktTextWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _calendarOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: ktTextWhite, size: 18),
                  ),
                ]),
              ),
            ),
            if (_calendarOpen) ...[
              const Divider(height: 1, color: ktBorderWhite5),
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
                          _legendDot(ktEmerald.withValues(alpha: 0.2),
                              ktEmerald.withValues(alpha: 0.4), 'Data'),
                          const SizedBox(width: 8),
                          _legendDot(Colors.white.withValues(alpha: 0.04),
                              Colors.white.withValues(alpha: 0.08), 'Empty'),
                        ]),
                  ),
                ),
              ),
            ],
          ]),
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
                  border: Border.all(color: border))),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: ktTextGray500,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
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
                                color: ktTextGray500,
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2))),
                  ))
              .toList()),
      const SizedBox(height: 2),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            childAspectRatio: 1.0),
        itemCount: firstDay + daysInMonth,
        itemBuilder: (ctx, i) {
          if (i < firstDay) return const SizedBox.shrink();
          final day = i - firstDay + 1;
          final dayStr = day.toString().padLeft(2, '0');
          final fullDate = '$dayStr/${ktMonths[month - 1]}/$year';
          final hasData = _existingDates.contains(fullDate);
          final isSel = day == _selectedDate.day;

          Color bg, tc;
          Color? bc;
          if (isSel) {
            bg = ktPrimary;
            tc = Colors.white;
            bc = ktPrimary;
          } else if (hasData) {
            bg = ktEmerald.withValues(alpha: 0.15);
            tc = ktEmerald;
            bc = ktEmerald.withValues(alpha: 0.2);
          } else {
            bg = Colors.white.withValues(alpha: 0.02);
            tc = ktTextGray400;
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
                boxShadow: isSel
                    ? [
                        BoxShadow(
                            color: ktPrimary.withValues(alpha: 0.3),
                            blurRadius: 4)
                      ]
                    : null,
              ),
              child: Center(
                  child: Text('$day',
                      style: TextStyle(
                          color: tc,
                          fontSize: 11,
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
          Expanded(
              child: _buildCollectionInput(
            label: 'MORNING COLLECTION (LITERS)',
            icon: Icons.wb_sunny_rounded,
            controller: _morningController,
            iconColor: ktPrimary,
          )),
          const SizedBox(width: 12),
          Expanded(
              child: _buildCollectionInput(
            label: 'EVENING COLLECTION (LITERS)',
            icon: Icons.nightlight_round,
            controller: _eveningController,
            iconColor: ktPrimary,
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
          color: ktCardBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: ktTextGray500,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ktBorderWhite10),
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
                    color: ktTextWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: '0.0',
                  hintStyle: TextStyle(color: ktTextGray500),
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
          color: ktPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ktPrimary.withValues(alpha: 0.3)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        child: Column(children: [
          Row(children: [
            Expanded(
                child: _totalItem('DAILY TOTAL',
                    '${_dailyTotal.toStringAsFixed(1)} L', ktTextWhite)),
            Expanded(
                child: _totalItem(
                    'UNIT PRICE', '₹${_unitPrice.toInt()}', ktTextWhite)),
            Expanded(
                child: Column(children: [
              _totalItem(
                  'DAILY COST', '₹${_dailyCost.toStringAsFixed(2)}', ktEmerald),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _toggleDailyCostEdit,
                child: Text(
                  _isDailyCostManual ? 'Auto Cost' : 'Edit Cost',
                  style: TextStyle(
                      color: ktPrimary.withValues(alpha: 0.8),
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
                border: Border(
                    top:
                        BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MANUAL DAILY COST (INR)',
                        style: TextStyle(
                            color: ktTextGray500,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ktBorderWhite10),
                      ),
                      child: TextField(
                        controller: _dailyCostController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'))
                        ],
                        style: const TextStyle(
                            color: ktEmerald,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace'),
                        decoration: const InputDecoration(
                          hintText: '160.00',
                          hintStyle: TextStyle(color: ktTextGray500),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
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
                  color: ktTextGray500,
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
          color: ktCardBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('REMARKS / ADDRESS',
              style: TextStyle(
                  color: ktTextGray500,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ktBorderWhite10),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                  padding: EdgeInsets.only(left: 12, top: 14),
                  child: Icon(Icons.comment, color: ktPrimary, size: 18)),
              Expanded(
                  child: TextField(
                controller: _remarksController,
                maxLines: 3,
                style: const TextStyle(
                    color: ktTextGray400, fontSize: 14, height: 1.5),
                decoration: const InputDecoration(
                  hintText: 'Enter remarks...',
                  hintStyle: TextStyle(color: ktTextGray500, fontSize: 13),
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
        color: ktBgDark.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: ktBorderWhite10)),
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
                border: Border.all(color: ktBorderWhite5),
              ),
              child: const Icon(Icons.delete_outline,
                  color: ktTextGray400, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _saveMilkData('draft'),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: ktTextGray500.withValues(alpha: 0.7),
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
                        color: ktPrimary.withValues(alpha: 0.3), blurRadius: 12)
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
              child:
                  CircularProgressIndicator(color: ktPrimary, strokeWidth: 3)),
          const SizedBox(height: 16),
          Text(_loadingText,
              style: const TextStyle(
                  color: ktTextWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ])),
      );
}
