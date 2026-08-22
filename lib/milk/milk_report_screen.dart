import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'milk_screen.dart';

// ── Design constants ─────────────────────────────────────────────────────────
const _bgDark = Color(0xFF070B16);
const _cardBg = Color(0xFF0F172A);
const _surfaceBg = Color(0x8B171E34);
const _primary = Color(0xFF6366F1);
const _success = Color(0xFF10B981);
const _orange = Color(0xFFFB923C);
const _rose = Color(0xFFEF4444);
const _cyan = Color(0xFF06B6D4);
const _textWhite = Colors.white;
const _textGray400 = Color(0xFF94A3B8);
const _textGray500 = Color(0xFF64748B);
const _borderWhite8 = Color(0x14FFFFFF);
const _borderWhite5 = Color(0x0DFFFFFF);

const _milkSheetUrl =
    'https://script.google.com/macros/s/AKfycbw9HPgLQojIqypEKeaCpwdZtdXmM7gqANY8LFWLWUAe5CNexRLTyrrX6JLFmiZC03B4CQ/exec';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

// ── Data models ───────────────────────────────────────────────────────────────
class _MilkRecord {
  final String date;
  final double morning;
  final double evening;
  final double unitPrice;
  final double dailyCost;
  final String remarks;
  final String status;
  final String stage;

  _MilkRecord({
    required this.date,
    required this.morning,
    required this.evening,
    required this.unitPrice,
    required this.dailyCost,
    required this.remarks,
    required this.status,
    required this.stage,
  });

  double get total => morning + evening;

  factory _MilkRecord.fromJson(Map<String, dynamic> j) {
    final morning = double.tryParse('${j['morning'] ?? 0}') ?? 0;
    final evening = double.tryParse('${j['evening'] ?? 0}') ?? 0;
    final unitPrice =
        double.tryParse('${j['unitprice'] ?? j['unitPrice'] ?? 80}') ?? 80;
    return _MilkRecord(
      date: j['date']?.toString() ?? '',
      morning: morning,
      evening: evening,
      unitPrice: unitPrice,
      dailyCost: (morning + evening) * unitPrice,
      remarks: j['remarks']?.toString() ?? '',
      status: j['status']?.toString() ?? 'Unpaid',
      stage: j['stage']?.toString() ?? 'completed',
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MilkReportScreen
// ════════════════════════════════════════════════════════════════════════════
class MilkReportScreen extends StatefulWidget {
  const MilkReportScreen({super.key});

  @override
  State<MilkReportScreen> createState() => _MilkReportScreenState();
}

class _MilkReportScreenState extends State<MilkReportScreen> {
  // ── view state ─────────────────────────────────────────────────────────────
  bool _filterExpanded = true;
  String _viewMode = 'cards'; // cards | list
  String _summaryViewMode = 'list'; // card | list

  // ── filter state ───────────────────────────────────────────────────────────
  String _selectedMonth = '';
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  // ── data ───────────────────────────────────────────────────────────────────
  List<_MilkRecord> _allData = [];
  bool _isMonthPaid = false;
  List<String> _draftDates = [];

  // ── confirm dialog ─────────────────────────────────────────────────────────
  bool _confirmOpen = false;
  String _confirmMode = 'markPaid'; // markPaid | settleDrafts

  @override
  void initState() {
    super.initState();
    _selectedMonth = _months[DateTime.now().month - 1];
    _fetchReport();
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  String _fmtDDMMMYYYY(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${_months[d.month - 1]}/${d.year}';
  }

  DateTime? _parseDate(String s) {
    if (s.isEmpty) return null;
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
    // Try space-separated format: DD MMM YYYY
    final spaceParts = s.trim().split(' ');
    if (spaceParts.length == 3) {
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
      final month = mo[spaceParts[1].toLowerCase()];
      if (month != null) {
        return DateTime(
          int.parse(spaceParts[2]),
          month,
          int.parse(spaceParts[0]),
        );
      }
    }
    return DateTime.tryParse(s);
  }

  String _formatDateDisplay(String dateStr) {
    if (dateStr.isEmpty) return dateStr;
    // Convert DD/MMM/YYYY to DD MMM YYYY
    final parts = dateStr.split('/');
    if (parts.length == 3) {
      return '${parts[0]} ${parts[1]} ${parts[2]}';
    }
    return dateStr;
  }

  void _changeMonth(int offset) {
    int mi = _months.indexOf(_selectedMonth);
    int yr = _selectedYear;
    mi += offset;
    if (mi < 0) {
      mi = 11;
      yr--;
    } else if (mi > 11) {
      mi = 0;
      yr++;
    }
    if (yr >= 2020 && yr <= DateTime.now().year) {
      setState(() {
        _selectedMonth = _months[mi];
        _selectedYear = yr;
      });
      _fetchReport();
    }
  }

  void _setQuickMonth(int offset) {
    final now = DateTime.now();
    final target = DateTime(now.year, now.month + offset, 1);
    setState(() {
      _selectedMonth = _months[target.month - 1];
      _selectedYear = target.year;
    });
    _fetchReport();
  }

  // ── API: fetch report ──────────────────────────────────────────────────────
  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final sheetName = '$_selectedMonth $_selectedYear';
      final url =
          '$_milkSheetUrl?sheetName=${Uri.encodeComponent(sheetName)}&t=${DateTime.now().millisecondsSinceEpoch}';
      final response = await http.get(Uri.parse(url));
      final res = jsonDecode(response.body) as Map<String, dynamic>;
      final rows =
          (res['data'] as List? ?? [])
              .map((r) => _MilkRecord.fromJson(r as Map<String, dynamic>))
              .toList();

      // Sort by date (newest first)
      rows.sort((a, b) {
        final da = _parseDate(a.date);
        final db = _parseDate(b.date);
        if (da == null || db == null) return 0;
        return db.compareTo(da);
      });

      // Check if all rows are paid
      final allPaid =
          rows.isNotEmpty &&
          rows.every((r) => r.status.toLowerCase() == 'paid');

      // Collect draft dates
      final drafts =
          rows
              .where((r) => r.stage.toLowerCase() == 'draft')
              .map((r) => _formatDateDisplay(r.date))
              .toSet()
              .toList();

      setState(() {
        _allData = rows;
        _isMonthPaid = allPaid;
        _draftDates = drafts;
      });
    } catch (e) {
      debugPrint('Fetch error: $e');
      _showAlert('Error', 'Failed to load data: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Summary calculations ───────────────────────────────────────────────────
  double get _totalMorningLiters => _allData.fold(0.0, (s, r) => s + r.morning);
  double get _totalEveningLiters => _allData.fold(0.0, (s, r) => s + r.evening);
  double get _totalMorningAmount {
    double sum = 0;
    for (final r in _allData) {
      sum += r.morning * r.unitPrice;
    }
    return sum;
  }

  double get _totalEveningAmount {
    double sum = 0;
    for (final r in _allData) {
      sum += r.evening * r.unitPrice;
    }
    return sum;
  }

  double get _totalLiters => _totalMorningLiters + _totalEveningLiters;
  double get _totalCost => _totalMorningAmount + _totalEveningAmount;

  // ── Mark paid ──────────────────────────────────────────────────────────────
  void _onMarkPaidTap() {
    if (_draftDates.isNotEmpty) {
      setState(() {
        _confirmMode = 'settleDrafts';
        _confirmOpen = true;
      });
    } else {
      setState(() {
        _confirmMode = 'markPaid';
        _confirmOpen = true;
      });
    }
  }

  Future<void> _proceedMarkPaid() async {
    setState(() {
      _confirmOpen = false;
      _isLoading = true;
    });
    try {
      final sheetName = '$_selectedMonth $_selectedYear';
      final payload = {
        'type': 'milk',
        'action': 'markMonthPaid',
        'sheetName': sheetName,
        'status': 'Paid',
      };
      await http.post(Uri.parse(_milkSheetUrl), body: jsonEncode(payload));
      setState(() => _isMonthPaid = true);
      if (_confirmMode == 'settleDrafts' && _draftDates.isNotEmpty) {
        _showAlert(
          'Draft Days Settled',
          'Marked month as paid with draft dates: ${_draftDates.join(', ')}',
        );
      }
    } catch (e) {
      _showAlert('Error', 'Failed to update status: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ── Edit entry ─────────────────────────────────────────────────────────────
  void _editEntry(int index) {
    if (index < 0 || index >= _allData.length) return;
    // Navigate to milk screen with data
    // In a real app, you'd pass the data through navigation arguments
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MilkScreen()),
    );
  }

  void _showAlert(String title, String message, {bool isError = false}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: _cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: isError ? _rose : _success,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: _textWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(color: _textGray400, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _buildDarkTheme(),
      child: Scaffold(
        backgroundColor: _bgDark,
        body: Stack(
          children: [
            // Background blobs
            _buildBgBlobs(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _buildHeroStrip(),
                          const SizedBox(height: 12),
                          _buildFilterPanel(),
                          const SizedBox(height: 12),
                          _buildMonthlySummary(),
                          const SizedBox(height: 12),
                          _buildDetailedCollection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading) _buildLoader(),
            if (_confirmOpen) _buildConfirmDialog(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: _primary,
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MilkScreen()),
              ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _bgDark,
      colorScheme: const ColorScheme.dark(
        surface: _cardBg,
        primary: _primary,
        onSurface: _textWhite,
      ),
      fontFamily: 'Plus Jakarta Sans',
    );
  }

  Widget _buildBgBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -80,
          child: Container(
            width: 450,
            height: 450,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_primary.withValues(alpha: 0.1), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -80,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [_cyan.withValues(alpha: 0.08), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A223B).withValues(alpha: 0.9),
            const Color(0xFF141830).withValues(alpha: 0.82),
          ],
        ),
        border: const Border(bottom: BorderSide(color: _borderWhite8)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                ),
              ],
            ),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Milk Report',
                  style: TextStyle(
                    color: _textWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'MONTHLY COLLECTION RECORDS',
                  style: TextStyle(
                    color: _primary.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          _headerBtn(
            Icons.tune,
            onTap: () => setState(() => _filterExpanded = !_filterExpanded),
            active: _filterExpanded,
          ),
          const SizedBox(width: 6),
          _headerBtn(
            Icons.add,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MilkScreen()),
                ),
          ),
          const SizedBox(width: 6),
          _headerBtn(Icons.home, onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _headerBtn(
    IconData icon, {
    required VoidCallback onTap,
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              active
                  ? _primary.withValues(alpha: 0.16)
                  : const Color(0xFF9AA8FF).withValues(alpha: 0.08),
          border: Border.all(
            color:
                active
                    ? _primary.withValues(alpha: 0.4)
                    : const Color(0xFFBAC7FF).withValues(alpha: 0.2),
          ),
        ),
        child: Icon(
          icon,
          color: active ? _primary : const Color(0xFFB8C4EA),
          size: 16,
        ),
      ),
    );
  }

  // ── Hero strip ─────────────────────────────────────────────────────────────
  Widget _buildHeroStrip() {
    return Row(
      children: [
        _heroChip(Icons.calendar_today, 'Monthly Tracking'),
        const SizedBox(width: 8),
        _heroChip(Icons.show_chart, 'Live Summary'),
      ],
    );
  }

  Widget _heroChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFBAC7FF).withValues(alpha: 0.28),
        ),
        color: const Color(0xFF9AA8FF).withValues(alpha: 0.1),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFC8D3FF), size: 12),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFC8D3FF),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter panel ───────────────────────────────────────────────────────────
  Widget _buildFilterPanel() {
    if (!_filterExpanded) return const SizedBox.shrink();

    final years = List.generate(
      DateTime.now().year - 2019,
      (i) => DateTime.now().year - i,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _glassDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    color: _primary.withValues(alpha: 0.7),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'FILTER PERIOD',
                    style: TextStyle(
                      color: Color(0xFFC7D2FE),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _navArrowBtn(Icons.chevron_left, () => _changeMonth(-1)),
                  const SizedBox(width: 6),
                  _navArrowBtn(Icons.chevron_right, () => _changeMonth(1)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MONTH',
                      style: TextStyle(
                        color: _textGray400,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _dropdownContainer(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMonth,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(
                            color: _textWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          items:
                              _months
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedMonth = v);
                            }
                          },
                        ),
                      ),
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
                      'YEAR',
                      style: TextStyle(
                        color: _textGray400,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _dropdownContainer(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedYear,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(
                            color: _textWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          items:
                              years
                                  .map(
                                    (y) => DropdownMenuItem(
                                      value: y,
                                      child: Text('$y'),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedYear = v);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _quickFilterChip('Current Month', () => _setQuickMonth(0)),
              const SizedBox(width: 8),
              _quickFilterChip('Previous Month', () => _setQuickMonth(-1)),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _fetchReport,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF818CF8).withValues(alpha: 0.65),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5E6EC1).withValues(alpha: 0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Fetch Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navArrowBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFF9AA8FF).withValues(alpha: 0.08),
          border: Border.all(
            color: const Color(0xFFBAC7FF).withValues(alpha: 0.2),
          ),
        ),
        child: Icon(icon, color: const Color(0xFFB8C4EA), size: 14),
      ),
    );
  }

  Widget _quickFilterChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: const Color(0xFFBAC7FF).withValues(alpha: 0.34),
          ),
          color: const Color(0xFF9AA8FF).withValues(alpha: 0.15),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFD3DBFF),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _dropdownContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF11182D).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFBAC7FF).withValues(alpha: 0.2),
        ),
      ),
      child: child,
    );
  }

  BoxDecoration _glassDeco() {
    return BoxDecoration(
      color: _surfaceBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFBAC7FF).withValues(alpha: 0.2)),
      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 34)],
    );
  }

  // ── Monthly summary ────────────────────────────────────────────────────────
  Widget _buildMonthlySummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _glassDeco(),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: _success, size: 14),
              const SizedBox(width: 8),
              const Text(
                'MONTHLY SUMMARY',
                style: TextStyle(
                  color: Color(0xFFC7D2FE),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              _summaryViewToggle(),
            ],
          ),
          const SizedBox(height: 12),
          _summaryViewMode == 'card'
              ? _buildSummaryCardView()
              : _buildSummaryListView(),
        ],
      ),
    );
  }

  Widget _summaryViewToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFBAC7FF).withValues(alpha: 0.26),
        ),
        color: const Color(0xFF9AA8FF).withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          _viewToggleBtn(
            'Card',
            Icons.grid_view,
            _summaryViewMode == 'card',
            () => setState(() => _summaryViewMode = 'card'),
          ),
          _viewToggleBtn(
            'List',
            Icons.list,
            _summaryViewMode == 'list',
            () => setState(() => _summaryViewMode = 'list'),
          ),
        ],
      ),
    );
  }

  Widget _viewToggleBtn(
    String label,
    IconData icon,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color:
              active
                  ? const Color(0xFFBAC7FF).withValues(alpha: 0.24)
                  : Colors.transparent,
          boxShadow:
              active
                  ? [
                    BoxShadow(
                      color: const Color(0xFFBAC7FF).withValues(alpha: 0.34),
                      blurRadius: 1,
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: active ? Colors.white : const Color(0xFFB7C2EA),
              size: 12,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFFB7C2EA),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCardView() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                'Morning',
                '${_totalMorningLiters.toStringAsFixed(1)} L',
                '₹${_formatNumber(_totalMorningAmount)}',
                const Color(0xFFFBBF24),
                const Color(0xFFFCD34D),
                LinearGradient(
                  colors: [
                    const Color(0xFFFBBF24).withValues(alpha: 0.22),
                    const Color(0xFFEA580C).withValues(alpha: 0.16),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                'Evening',
                '${_totalEveningLiters.toStringAsFixed(1)} L',
                '₹${_formatNumber(_totalEveningAmount)}',
                const Color(0xFF818CF8),
                const Color(0xFFA5B4FC),
                LinearGradient(
                  colors: [
                    _primary.withValues(alpha: 0.28),
                    _cyan.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                'Total Quantity',
                '${_totalLiters.toStringAsFixed(1)} L',
                null,
                const Color(0xFF34D399),
                const Color(0xFF22D3EE),
                LinearGradient(
                  colors: [
                    _success.withValues(alpha: 0.22),
                    _cyan.withValues(alpha: 0.14),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _totalAmountCard()),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
    String label,
    String value,
    String? subValue,
    Color labelColor,
    Color valueColor,
    Gradient bg,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: labelColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 4),
            Text(
              subValue,
              style: TextStyle(
                color: valueColor.withValues(alpha: 0.8),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _totalAmountCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _success.withValues(alpha: 0.20),
            _cyan.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _success.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Amount',
            style: TextStyle(
              color: Color(0xFF34D399),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${_formatNumber(_totalCost)}',
            style: const TextStyle(
              color: Color(0xFF34D399),
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          _paymentStatusWidget(),
        ],
      ),
    );
  }

  Widget _buildSummaryListView() {
    return Row(
      children: [
        Expanded(child: _combinedStatsCard()),
        const SizedBox(width: 12),
        Expanded(child: _totalStatsCard()),
      ],
    );
  }

  Widget _combinedStatsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primary.withValues(alpha: 0.16),
            _cyan.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF818CF8).withValues(alpha: 0.30),
        ),
      ),
      child: Column(
        children: [
          _statsLine(
            'Morning Quantity',
            '${_totalMorningLiters.toStringAsFixed(1)} L',
            const Color(0xFFFCD34D),
            const Color(0xFFFBBF24),
          ),
          const SizedBox(height: 8),
          _statsLine(
            'Morning Amount',
            '₹${_formatNumber(_totalMorningAmount)}',
            const Color(0xFFFDE68A),
            const Color(0xFFFCD34D),
          ),
          const SizedBox(height: 8),
          _statsLine(
            'Evening Quantity',
            '${_totalEveningLiters.toStringAsFixed(1)} L',
            const Color(0xFFA5B4FC),
            const Color(0xFF818CF8),
          ),
          const SizedBox(height: 8),
          _statsLine(
            'Evening Amount',
            '₹${_formatNumber(_totalEveningAmount)}',
            const Color(0xFFBFDBFE),
            const Color(0xFFA5B4FC),
          ),
        ],
      ),
    );
  }

  Widget _statsLine(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFBAC7FF).withValues(alpha: 0.26),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalStatsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _success.withValues(alpha: 0.20),
            _cyan.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _success.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          _totalStatsLine(
            'Total Quantity',
            '${_totalLiters.toStringAsFixed(1)} L',
            const Color(0xFF7DD3FC),
            const Color(0xFF22D3EE),
          ),
          const SizedBox(height: 8),
          _totalStatsLine(
            'Total Amount',
            '₹${_formatNumber(_totalCost)}',
            const Color(0xFFFCD34D),
            const Color(0xFF34D399),
          ),
          const SizedBox(height: 8),
          _paymentStatusWidget(),
        ],
      ),
    );
  }

  Widget _totalStatsLine(
    String label,
    String value,
    Color labelColor,
    Color valueColor,
  ) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF6EE7B7).withValues(alpha: 0.28),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentStatusWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Payment Status',
          style: TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        _isMonthPaid
            ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _success.withValues(alpha: 0.24),
                    const Color(0xFF059669).withValues(alpha: 0.18),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _success.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF86EFAC), size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Paid',
                    style: TextStyle(
                      color: Color(0xFF86EFAC),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
            : GestureDetector(
              onTap: _onMarkPaidTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _rose.withValues(alpha: 0.35),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFFFECACA),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Un-Paid',
                      style: TextStyle(
                        color: Color(0xFFFECACA),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  // ── Detailed collection ────────────────────────────────────────────────────
  Widget _buildDetailedCollection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _glassDeco(),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.table_chart, color: _primary, size: 14),
              const SizedBox(width: 8),
              const Text(
                'DETAILED COLLECTION',
                style: TextStyle(
                  color: Color(0xFFC7D2FE),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              _detailViewToggle(),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF9AA8FF).withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFFBAC7FF).withValues(alpha: 0.26),
                  ),
                ),
                child: Text(
                  '${_allData.length} days',
                  style: const TextStyle(
                    color: Color(0xFFD3DBFF),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _viewMode == 'cards' ? _buildCardsView() : _buildTableView(),
        ],
      ),
    );
  }

  Widget _detailViewToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFBAC7FF).withValues(alpha: 0.26),
        ),
        color: const Color(0xFF9AA8FF).withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          _viewToggleBtn(
            'Cards',
            Icons.grid_view,
            _viewMode == 'cards',
            () => setState(() => _viewMode = 'cards'),
          ),
          _viewToggleBtn(
            'List',
            Icons.table_chart,
            _viewMode == 'list',
            () => setState(() => _viewMode = 'list'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsView() {
    if (_allData.isEmpty) {
      return _emptyState();
    }
    return Column(
      children: List.generate(_allData.length, (index) {
        final record = _allData[index];
        final theme = index % 2 == 0 ? 'indigo' : 'teal';
        return _dayCard(record, index, theme);
      }),
    );
  }

  Widget _dayCard(_MilkRecord record, int index, String theme) {
    final isIndigo = theme == 'indigo';
    final dateColor =
        isIndigo ? const Color(0xFFA5B4FC) : const Color(0xFF6EE7B7);
    final stageBadge = _stageBadge(record.stage);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              isIndigo
                  ? [
                    const Color(0xFF353D66).withValues(alpha: 0.88),
                    const Color(0xFF182039).withValues(alpha: 0.9),
                  ]
                  : [
                    const Color(0xFF174C56).withValues(alpha: 0.82),
                    const Color(0xFF182039).withValues(alpha: 0.9),
                  ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isIndigo
                  ? const Color(0xFFBAC7FF).withValues(alpha: 0.28)
                  : const Color(0xFF7DE3F5).withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color:
                isIndigo
                    ? const Color(0xFF2D3764).withValues(alpha: 0.35)
                    : const Color(0xFF154858).withValues(alpha: 0.32),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dateColor.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _formatDateDisplay(record.date),
                style: TextStyle(
                  color: dateColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              stageBadge,
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFBBF24).withValues(alpha: 0.18),
                      const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '₹${record.dailyCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _editEntry(index),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFBAC7FF).withValues(alpha: 0.26),
                    ),
                    color: const Color(0xFF9AA8FF).withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFFC7D2FE),
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          if (record.remarks.isNotEmpty) ...[
            const SizedBox(height: 9),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFBAC7FF).withValues(alpha: 0.14),
                ),
                color: const Color(0xFF0C1222).withValues(alpha: 0.36),
              ),
              child: Text(
                '📝 ${record.remarks}',
                style: const TextStyle(color: Color(0xFFBDC9EE), fontSize: 10),
              ),
            ),
          ],
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _blockItem(
                  '☀️ Morn',
                  '${record.morning.toStringAsFixed(1)}',
                  'litres',
                  const Color(0xFFFBBF24),
                  const Color(0xFFFCD34D),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _blockItem(
                  '🌙 Eve',
                  '${record.evening.toStringAsFixed(1)}',
                  'litres',
                  const Color(0xFF818CF8),
                  const Color(0xFFA5B4FC),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _blockItem(
                  '⚡ Total',
                  '${record.total.toStringAsFixed(1)}',
                  'litres',
                  const Color(0xFF34D399),
                  const Color(0xFF6EE7B7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _blockItem(
    String label,
    String value,
    String sub,
    Color labelColor,
    Color valueColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            labelColor.withValues(alpha: 0.22),
            labelColor.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: labelColor.withValues(alpha: 0.40)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(
              color: valueColor,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stageBadge(String stage) {
    final isDraft = stage.toLowerCase() == 'draft';
    final isDone = stage.toLowerCase() == 'completed';

    if (isDraft) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: _rose.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _rose.withValues(alpha: 0.42)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note, color: Color(0xFFFCA5A5), size: 10),
            SizedBox(width: 4),
            Text(
              'Draft',
              style: TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );
    }
    if (isDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: _success.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _success.withValues(alpha: 0.36)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, color: Color(0xFF6EE7B7), size: 10),
            SizedBox(width: 4),
            Text(
              'Done',
              style: TextStyle(
                color: Color(0xFF6EE7B7),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _textGray500.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _textGray500.withValues(alpha: 0.24)),
      ),
      child: const Text(
        '—',
        style: TextStyle(
          color: _textGray500,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTableView() {
    if (_allData.isEmpty) {
      return _emptyState();
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _borderWhite8),
        borderRadius: BorderRadius.circular(14),
        color: const Color(0xFF0E1425).withValues(alpha: 0.58),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF181F36).withValues(alpha: 0.96),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'DATE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFA8B5DF),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '☀️',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFCD34D),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '🌙',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFA5B4FC),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '⚡',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6EE7B7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹ COST',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'STAGE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFA78BFA),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: 40),
              ],
            ),
          ),
          // Rows
          ...List.generate(_allData.length, (index) {
            final r = _allData[index];
            final isEven = index % 2 == 0;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color:
                    isEven
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.02),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFBAC7FF).withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatDateDisplay(r.date),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${r.morning.toStringAsFixed(1)} L',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFCD34D),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${r.evening.toStringAsFixed(1)} L',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFA5B4FC),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${r.total.toStringAsFixed(1)} L',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF6EE7B7),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${r.dailyCost.toStringAsFixed(2)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  Expanded(child: Center(child: _stageBadge(r.stage))),
                  SizedBox(
                    width: 40,
                    child: GestureDetector(
                      onTap: () => _editEntry(index),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFFBAC7FF,
                            ).withValues(alpha: 0.26),
                          ),
                          color: const Color(
                            0xFF9AA8FF,
                          ).withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Color(0xFFC7D2FE),
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.inbox,
            color: const Color(0xFF9AA8FF).withValues(alpha: 0.4),
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'NO RECORDS FOUND',
            style: TextStyle(
              color: Color(0xFFAAB6DF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Loader ─────────────────────────────────────────────────────────────────
  Widget _buildLoader() {
    return Container(
      color: const Color(0xCC020617),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _primary.withValues(alpha: 0.2),
                        width: 4,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      color: _primary,
                      strokeWidth: 4,
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.water_drop, color: _primary, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Fetching Data…',
              style: TextStyle(
                color: _textWhite,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirm dialog ─────────────────────────────────────────────────────────
  Widget _buildConfirmDialog() {
    final isSettleDrafts = _confirmMode == 'settleDrafts';
    return GestureDetector(
      onTap: () => setState(() => _confirmOpen = false),
      child: Container(
        color: const Color(0xBF020617),
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
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 360),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1428).withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.30),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 60),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF8B5CF6).withValues(alpha: 0.20),
                              _primary.withValues(alpha: 0.12),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.30),
                          ),
                        ),
                        child: const Center(
                          child: Text('💳', style: TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isSettleDrafts ? 'Draft days found' : 'Mark as Paid?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          '$_selectedMonth $_selectedYear',
                          style: const TextStyle(
                            color: Color(0xFFC4B5FD),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (isSettleDrafts) ...[
                        const Text(
                          'Please complete the draft milk days listed below, or choose Settle Draft Days to continue payment marking.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _textGray400,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 110),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _borderWhite8),
                          ),
                          child: ListView(
                            shrinkWrap: true,
                            children:
                                _draftDates
                                    .map(
                                      (d) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          '• $d',
                                          style: const TextStyle(
                                            color: Color(0xFFFCA5A5),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          "This will mark the entire month's milk bill as paid. This action will be saved to the sheet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _textGray400,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _confirmOpen = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.10),
                                  ),
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                                child: Text(
                                  isSettleDrafts
                                      ? 'Review Draft Days'
                                      : 'Cancel',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: _textGray400,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: _proceedMarkPaid,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF8B5CF6),
                                      Color(0xFF6366F1),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF8B5CF6,
                                      ).withValues(alpha: 0.40),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isSettleDrafts
                                          ? 'Settle Drafts'
                                          : 'Mark Paid',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
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
        ),
      ),
    );
  }

  String _formatNumber(double value) {
    return value
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},');
  }
}
