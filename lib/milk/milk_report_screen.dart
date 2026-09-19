import 'package:flutter/material.dart';

import '../core_constants.dart';
import '../core_ui_utils.dart';
import '../core_utils.dart';
import 'milk_models.dart';
import 'milk_screen.dart';
import 'milk_service.dart';

// ── Design constants ─────────────────────────────────────────────────────────
const _surfaceBg = Color(0x8B171E34);

// ════════════════════════════════════════════════════════════════════════════
// MilkReportScreen
// ════════════════════════════════════════════════════════════════════════════
class MilkReportScreen extends StatefulWidget {
  const MilkReportScreen({super.key});

  @override
  State<MilkReportScreen> createState() => _MilkReportScreenState();
}

class _MilkReportScreenState extends State<MilkReportScreen> {
  final MilkService _milkService = MilkService();

  // ── view state ─────────────────────────────────────────────────────────────
  bool _filterExpanded = true;
  String _viewMode = 'cards'; // cards | list

  // ── filter state ───────────────────────────────────────────────────────────
  String _selectedMonth = '';
  int _selectedYear = getIndiaTime().year;
  bool _isLoading = false;

  // ── data ───────────────────────────────────────────────────────────────────
  List<MilkRecord> _allData = [];
  bool _isMonthPaid = false;
  List<String> _draftDates = [];

  // ── confirm dialog ─────────────────────────────────────────────────────────
  bool _confirmOpen = false;
  String _confirmMode = 'markPaid'; // markPaid | settleDrafts

  @override
  void initState() {
    super.initState();
    _selectedMonth = ktMonths[getIndiaTime().month - 1];
    _fetchReport();
  }

  // ── helpers ───────────────────────────────────────────────────────────────
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
    final dt = ktParseDate(dateStr);
    return dt != null ? ktFormatDate(dt) : dateStr;
  }

  void _changeMonth(int offset) {
    int mi = ktMonths.indexOf(_selectedMonth);
    int yr = _selectedYear;
    mi += offset;
    if (mi < 0) {
      mi = 11;
      yr--;
    } else    if (mi > 11) {
      mi = 0;
      yr++;
    }
    if (yr >= 2020 && yr <= getIndiaTime().year) {
      setState(() {
        _selectedMonth = ktMonths[mi];
        _selectedYear = yr;
      });
      _fetchReport();
    }
  }

  void _setQuickMonth(int offset) {
    final now = getIndiaTime();
    final target = DateTime(now.year, now.month + offset, 1);
    setState(() {
      _selectedMonth = ktMonths[target.month - 1];
      _selectedYear = target.year;
    });
    _fetchReport();
  }

  // ── API: fetch report ──────────────────────────────────────────────────────
  Future<void> _fetchReport() async {
    setState(() => _isLoading = true);
    try {
      final res = await _milkService.fetchReport(
        month: _selectedMonth,
        year: _selectedYear,
      );
      final rows =
          (res['data'] as List? ?? [])
              .map((r) => MilkRecord.fromJson(r as Map<String, dynamic>))
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
  double get _totalAdvancePaid => _allData.fold(0.0, (s, r) => s + r.advancePaid);
  double get _totalAmountTaken => _allData.fold(0.0, (s, r) => s + r.amountTaken);
  double get _netPayable => _totalCost - _totalAdvancePaid + _totalAmountTaken;

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
      await _milkService.markMonthPaid(sheetName);
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

  void _showAlert(String title, String message, {bool isError = false}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: ktCardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: isError ? ktRose : ktEmerald,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: ktTextWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: const TextStyle(color: ktTextGray400, fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: ktPrimary,
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
        backgroundColor: ktBgDark,
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
                          const SizedBox(height: 80), // Spacer for FAB
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
          backgroundColor: ktPrimary,
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
      scaffoldBackgroundColor: ktBgDark,
      colorScheme: const ColorScheme.dark(
        surface: ktCardBg,
        primary: ktPrimary,
        onSurface: ktTextWhite,
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
                colors: [ktPrimary.withOpacity(0.1), Colors.transparent],
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
                colors: [ktCyan.withOpacity(0.08), Colors.transparent],
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
            const Color(0xFF1A223B).withOpacity(0.9),
            const Color(0xFF141830).withOpacity(0.82),
          ],
        ),
        border: const Border(bottom: BorderSide(color: ktBorderWhite10)),
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
                  color: ktPrimary.withOpacity(0.35),
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
                    color: ktTextWhite,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Monthly Milk Records',
                  style: TextStyle(
                    color: ktPrimary.withOpacity(0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
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
          _headerBtn(Icons.home, onTap: () => Navigator.pushNamed(context, '/')),
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
                  ? ktPrimary.withOpacity(0.16)
                  : const Color(0xFF9AA8FF).withOpacity(0.08),
          border: Border.all(
            color:
                active
                    ? ktPrimary.withOpacity(0.4)
                    : const Color(0xFFBAC7FF).withOpacity(0.2),
          ),
        ),
        child: Icon(
          icon,
          color: active ? ktPrimary : const Color(0xFFB8C4EA),
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
          color: const Color(0xFFBAC7FF).withOpacity(0.28),
        ),
        color: const Color(0xFF9AA8FF).withOpacity(0.1),
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
      getIndiaTime().year - 2019,
      (i) => getIndiaTime().year - i,
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
                    color: ktPrimary.withOpacity(0.7),
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
                        color: ktTextGray400,
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
                            color: ktTextWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          items:
                              ktMonths
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
                        color: ktTextGray400,
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
                            color: ktTextWhite,
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
                  color: const Color(0xFF818CF8).withOpacity(0.65),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5E6EC1).withOpacity(0.4),
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
          color: const Color(0xFF9AA8FF).withOpacity(0.08),
          border: Border.all(
            color: const Color(0xFFBAC7FF).withOpacity(0.2),
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
            color: const Color(0xFFBAC7FF).withOpacity(0.34),
          ),
          color: const Color(0xFF9AA8FF).withOpacity(0.15),
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
        color: const Color(0xFF11182D).withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFBAC7FF).withOpacity(0.2),
        ),
      ),
      child: child,
    );
  }

  BoxDecoration _glassDeco() {
    return BoxDecoration(
      color: _surfaceBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFBAC7FF).withOpacity(0.2)),
      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 34)],
    );
  }

  // ── Monthly summary ────────────────────────────────────────────────────────
  Widget _buildMonthlySummary() {
    return GestureDetector(
      onTap: _showMonthlySummaryDetails,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _glassDeco(),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ktEmerald.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.bar_chart, color: ktEmerald, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_selectedMonth Month Bill',
                    style: const TextStyle(
                      color: ktTextWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'monthly summary',
                    style: TextStyle(
                      color: ktTextGray400,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${_formatNumber(_netPayable)}',
                  style: const TextStyle(
                    color: ktEmerald,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                _isMonthPaid
                    ? const Text(
                      'PAID',
                      style: TextStyle(
                        color: ktEmerald,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                    : const Text(
                      'UN-PAID',
                      style: TextStyle(
                        color: ktRose,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_right, color: ktTextGray500, size: 20),
          ],
        ),
      ),
    );
  }

  void _showMonthlySummaryDetails() {
    ktShowDetailsSheet(
      context: context,
      title: '$_selectedMonth $_selectedYear Month Bill',
      icon: Icons.bar_chart,
      themeColor: ktEmerald,
      details: [
        {'label': 'Morning Qty', 'value': '${_totalMorningLiters.toStringAsFixed(1)} L'},
        {'label': 'Morning Amt', 'value': '₹${_formatNumber(_totalMorningAmount)}'},
        {'label': 'Evening Qty', 'value': '${_totalEveningLiters.toStringAsFixed(1)} L'},
        {'label': 'Evening Amt', 'value': '₹${_formatNumber(_totalEveningAmount)}'},
        {'label': 'Total Qty', 'value': '${_totalLiters.toStringAsFixed(1)} L', 'color': ktCyan},
        {'label': 'Total Amount', 'value': '₹${_formatNumber(_totalCost)}'},
        {'label': 'Advance Paid', 'value': '₹${_formatNumber(_totalAdvancePaid)}', 'color': ktBlue},
        {'label': 'Amount Taken', 'value': '₹${_formatNumber(_totalAmountTaken)}', 'color': ktRose},
        {'label': 'Net Payable', 'value': '₹${_formatNumber(_netPayable)}', 'color': ktEmerald, 'isHighlight': true},
      ],
      footerNote: 'Payment status for this month is ${_isMonthPaid ? "PAID" : "UN-PAID"}.',
      actions: !_isMonthPaid ? [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            _onMarkPaidTap();
          },
          icon: const Icon(Icons.check_circle_outline, size: 15),
          label: const Text('Mark Month Paid'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ktSuccess,
            foregroundColor: ktWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ] : null,
    );
  }

  void _showMilkRecordDetails(MilkRecord record) {
    ktShowDetailsSheet(
      context: context,
      title: 'Milk Collection Details',
      icon: Icons.water_drop,
      themeColor: ktPrimary,
      details: [
        {'label': 'Date', 'value': _formatDateDisplay(record.date)},
        {'label': 'Morning', 'value': '${record.morning.toStringAsFixed(1)} L'},
        {'label': 'Evening', 'value': '${record.evening.toStringAsFixed(1)} L'},
        {'label': 'Total Qty', 'value': '${record.total.toStringAsFixed(1)} L', 'color': ktCyan},
        {'label': 'Unit Price', 'value': '₹${record.unitPrice.toStringAsFixed(2)}'},
        {'label': 'Daily Cost', 'value': '₹${record.dailyCost.toStringAsFixed(2)}', 'color': ktAmber},
        {'label': 'Advance Paid', 'value': '₹${record.advancePaid.toStringAsFixed(2)}', 'color': ktBlue},
        {'label': 'Amount Taken', 'value': '₹${record.amountTaken.toStringAsFixed(2)}', 'color': ktRose},
        {'label': 'Status', 'value': record.status, 'color': record.status.toLowerCase() == 'paid' ? ktEmerald : ktRose},
        {'label': 'Stage', 'value': record.stage},
      ],
      footerNote: record.remarks.isNotEmpty ? record.remarks : null,
      actions: [
        ktEditButton(
          onPressed: () {
            Navigator.pop(context);
            final parsedDate = _parseDate(record.date);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MilkScreen(initialDate: parsedDate)),
            ).then((_) => _fetchReport());
          },
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          color:
              active
                  ? const Color(0xFFBAC7FF).withOpacity(0.24)
                  : Colors.transparent,
          boxShadow:
              active
                  ? [
                    BoxShadow(
                      color: const Color(0xFFBAC7FF).withOpacity(0.34),
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
              size: 11,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFFB7C2EA),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Detailed collection ────────────────────────────────────────────────────
  Widget _buildDetailedCollection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: _glassDeco(),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.table_chart, color: ktPrimary, size: 14),
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
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF9AA8FF).withOpacity(0.20),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFFBAC7FF).withOpacity(0.26),
                  ),
                ),
                child: Text(
                  '${_allData.length}d',
                  style: const TextStyle(
                    color: Color(0xFFD3DBFF),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
          color: const Color(0xFFBAC7FF).withOpacity(0.26),
        ),
        color: const Color(0xFF9AA8FF).withOpacity(0.08),
      ),
      child: Row(
        children: [
          _viewToggleBtn(
            'List',
            Icons.table_chart,
            _viewMode == 'list',
            () => setState(() => _viewMode = 'list'),
          ),
          _viewToggleBtn(
            'Cart',
            Icons.grid_view,
            _viewMode == 'cards',
            () => setState(() => _viewMode = 'cards'),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsView() {
    if (_allData.isEmpty) {
      return _emptyState();
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        mainAxisExtent: 72,
      ),
      itemCount: _allData.length,
      itemBuilder: (context, index) => _buildMilkRecordCard(_allData[index], index),
    );
  }

  Widget _buildMilkRecordCard(MilkRecord record, int index) {
    final isDraft = record.stage.toLowerCase() == 'draft';
    final themeColor = isDraft ? ktRose : ktPrimary;

    return GestureDetector(
      onTap: () => _showMilkRecordDetails(record),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeColor.withOpacity(0.15),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(
                isDraft ? Icons.edit_note : Icons.water_drop,
                color: themeColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatDateDisplay(record.date),
                    style: const TextStyle(
                      color: ktWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'M:', style: TextStyle(color: Color(0xFFFCD34D))),
                        TextSpan(text: ' ${record.morning.toStringAsFixed(1)} ', style: const TextStyle(color: ktWhite)),
                        const TextSpan(text: 'E:', style: TextStyle(color: Color(0xFFA5B4FC))),
                        TextSpan(text: ' ${record.evening.toStringAsFixed(1)}', style: const TextStyle(color: ktWhite)),
                      ],
                    ),
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '₹${record.dailyCost.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isDraft ? ktRose500 : ktGreen500,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_right, color: ktTextGray500, size: 12),
          ],
        ),
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
          color: ktRose.withOpacity(0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ktRose.withOpacity(0.42)),
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
          color: ktEmerald.withOpacity(0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: ktEmerald.withOpacity(0.36)),
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
        color: ktTextGray500.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ktTextGray500.withOpacity(0.24)),
      ),
      child: const Text(
        '—',
        style: TextStyle(
          color: ktTextGray500,
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Container(
        width: 520, // Fixed width to prevent truncation and allow scrolling
        decoration: BoxDecoration(
          border: Border.all(color: ktBorderWhite10),
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFF0E1425).withOpacity(0.58),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF181F36).withOpacity(0.96),
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
                        fontSize: 10,
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
                        fontSize: 10,
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
                        fontSize: 10,
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
                        fontSize: 10,
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
                        fontSize: 10,
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
                        fontSize: 10,
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
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color:
                      isEven
                          ? Colors.transparent
                          : Colors.white.withOpacity(0.02),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFFBAC7FF).withOpacity(0.08),
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
                          fontSize: 11,
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
                          fontSize: 11,
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
                          fontSize: 11,
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
                          fontSize: 11,
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
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    Expanded(child: Center(child: _stageBadge(r.stage))),
                    SizedBox(
                      width: 40,
                      child: GestureDetector(
                        onTap: () => _showMilkRecordDetails(r),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(
                                0xFFBAC7FF,
                              ).withOpacity(0.26),
                            ),
                            color: const Color(
                              0xFF9AA8FF,
                            ).withOpacity(0.12),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_right,
                            color: Color(0xFFC7D2FE),
                            size: 18,
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
            color: const Color(0xFF9AA8FF).withOpacity(0.4),
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
                        color: ktPrimary.withOpacity(0.2),
                        width: 4,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 56,
                    height: 56,
                    child: CircularProgressIndicator(
                      color: ktPrimary,
                      strokeWidth: 4,
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.water_drop, color: ktPrimary, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Fetching Data…',
              style: TextStyle(
                color: ktTextWhite,
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
                  color: const Color(0xFF0F1428).withOpacity(0.97),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF8B5CF6).withOpacity(0.30),
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
                              const Color(0xFF8B5CF6).withOpacity(0.20),
                              ktPrimary.withOpacity(0.12),
                            ],
                          ),
                          border: Border.all(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withOpacity(0.30),
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
                          ).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withOpacity(0.35),
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
                            color: ktTextGray400,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 110),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ktBorderWhite10),
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
                            color: ktTextGray400,
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
                                    color: Colors.white.withOpacity(0.10),
                                  ),
                                  color: Colors.white.withOpacity(0.06),
                                ),
                                child: Text(
                                  isSettleDrafts
                                      ? 'Review Draft Days'
                                      : 'Cancel',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: ktTextGray400,
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
                                      ).withOpacity(0.40),
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
