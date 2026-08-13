import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/rent_record.dart';
import '../services/api_service.dart';
import '../screens/rent_screen.dart';

// ─────────────────────────────────────────────────────────────
// Rent Reports Screen  (converted from tenetreport.html)
// ─────────────────────────────────────────────────────────────
class RentReportsScreen extends StatefulWidget {
  const RentReportsScreen({super.key});

  @override
  State<RentReportsScreen> createState() => _RentReportsScreenState();
}

class _RentReportsScreenState extends State<RentReportsScreen> {
  List<RentRecord> _allRecords = [];
  List<RentRecord> _displayRecords = [];
  bool _isLoading = true;
  bool _totalVisible = false;
  String _sideFilter = 'All'; // 'All' | 'Kalyan' | 'Srikanth'
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.fetchRentData();
      final rows = res['data'] as List<RentRecord>;
      if (!mounted) return;
      setState(() {
        _allRecords = rows;
        _isLoading = false;
        _expanded.clear();
      });
      _applyFilter();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _snack('❌ Error loading data', isError: true);
    }
  }

  void _applyFilter() {
    final filtered = _sideFilter == 'All'
        ? List<RentRecord>.from(_allRecords)
        : _allRecords.where((r) => r.side == _sideFilter).toList();

    filtered.sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
    setState(() {
      _displayRecords = filtered;
      _expanded.clear();
    });
  }

  DateTime _parseDate(String s) {
    if (s.isEmpty) return DateTime(2000);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final parts = s.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]) ?? 1;
      final m = months.indexOf(parts[1]) + 1;
      final y = int.tryParse(parts[2]) ?? 2000;
      if (m > 0) return DateTime(y, m, d);
    }
    return DateTime.tryParse(s) ?? DateTime(2000);
  }

  String _fmtDate(String s) {
    final d = _parseDate(s);
    if (d.year == 2000) return s;
    return DateFormat('dd MMM yyyy').format(d);
  }

  String _fmtCurrency(double v) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
          .format(v);

  double get _totalCollected =>
      _displayRecords.fold(0, (s, r) => s + r.totalPaid);

  Future<void> _deleteRecord(RentRecord record) async {
    final confirmed = await _showDeleteConfirm();
    if (!confirmed) return;

    final payload = {
      'action': 'delete',
      'originalDate': record.date,
      'originalSide': record.side,
    };
    try {
      await ApiService.saveRentPayload(payload);
      if (!mounted) return;
      _snack('✅ Record deleted');
      _fetchData();
    } catch (_) {
      if (!mounted) return;
      _snack('❌ Delete failed', isError: true);
    }
  }

  Future<bool> _showDeleteConfirm() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color(0x4DEF4444))),
            title: const Text('Delete Record',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
            content: const Text(
              'Are you sure you want to delete this record? This cannot be undone.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: Color(0xFF94A3B8))),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : const Color(0xFF22C55E),
    ));
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(children: [
        // Animated orbs
        Positioned(left: -100, top: -100, child: _orb(400, const Color(0x406366F1))),
        Positioned(right: -50, bottom: -50, child: _orb(300, const Color(0x40EC4899))),
        Positioned(top: MediaQuery.of(context).size.height * 0.4,
            left: MediaQuery.of(context).size.width * 0.6,
            child: _orb(200, const Color(0x408B5CF6))),
        SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Color(0xFF34D399)))
                    : _displayRecords.isEmpty
                        ? _emptyState()
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                            children: [
                              _buildTotalSummary(),
                              const SizedBox(height: 10),
                              ..._displayRecords.asMap().entries
                                  .map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _buildCard(e.key, e.value),
                                  )),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const RentScreen()),
          );
          if (res == true) _fetchData();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _orb(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withValues(alpha: 0.4),
            Colors.transparent
          ]),
        ),
      );

  // ── Header ──
  Widget _buildHeader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xB31E293B),
          border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: Row(
          children: [
            const Icon(Icons.pie_chart_rounded, color: Color(0xFF34D399), size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Tenet Report',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
            // Side filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sideFilter,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  icon: const Icon(Icons.keyboard_arrow_down,
                      color: Color(0xFF9CA3AF), size: 16),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Sides')),
                    DropdownMenuItem(value: 'Kalyan', child: Text('Kalyan')),
                    DropdownMenuItem(value: 'Srikanth', child: Text('Srikanth')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _sideFilter = v);
                      _applyFilter();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            _hBtn(Icons.refresh_rounded, 'Refresh', _fetchData),
            const SizedBox(width: 6),
            _hBtn(Icons.add_rounded, 'New Entry', () async {
              final res = await Navigator.push<bool>(
                  context, MaterialPageRoute(builder: (_) => const RentScreen()));
              if (res == true) _fetchData();
            }),
            const SizedBox(width: 6),
            _hBtn(Icons.home_rounded, 'Home',
                () => Navigator.of(context).popUntil((r) => r.isFirst)),
          ],
        ),
      );

  Widget _hBtn(IconData icon, String tip, VoidCallback onTap) => Tooltip(
        message: tip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
        ),
      );

  // ── Total Summary ──
  Widget _buildTotalSummary() => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xB31E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF9333EA)]),
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Collected',
                      style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text(
                    _totalVisible
                        ? _fmtCurrency(_totalCollected)
                        : '₹••••',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()
                          ..shader = const LinearGradient(colors: [
                            Color(0xFF818CF8),
                            Color(0xFFC084FC),
                            Color(0xFFF472B6)
                          ]).createShader(
                              const Rect.fromLTWH(0, 0, 200, 30))),
                  ),
                ],
              ),
            ),
            InkWell(
              onTap: () => setState(() => _totalVisible = !_totalVisible),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Icon(
                    _totalVisible ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFFD1D5DB),
                    size: 16),
              ),
            ),
          ],
        ),
      );

  // ── Accordion Card ──
  Widget _buildCard(int index, RentRecord r) {
    final isKalyan = r.side == 'Kalyan';
    final isOpen = _expanded.contains(index);

    final accentColor = isKalyan ? const Color(0xFF6366F1) : const Color(0xFFEC4899);
    final sideIconBg = isKalyan
        ? const Color(0x266366F1)
        : const Color(0x26EC4899);
    final sideBorderColor = isKalyan
        ? const Color(0x4D6366F1)
        : const Color(0x4DEC4899);
    final sideTextColor = isKalyan
        ? const Color(0xFFA5B4FC)
        : const Color(0xFFFDA4AF);
    final gradFrom = isKalyan ? const Color(0x3F312E81) : const Color(0x3F831843);
    final gradTo   = isKalyan ? const Color(0x264C1D95) : const Color(0x269D174D);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xB31E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 8)],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── Card Header (always visible) ──
          InkWell(
            onTap: () {
              setState(() {
                if (isOpen) {
                  _expanded.remove(index);
                } else {
                  _expanded.clear();
                  _expanded.add(index);
                }
              });
            },
            child: Container(
              decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(color: accentColor, width: 3))),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Side icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: sideIconBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sideBorderColor),
                    ),
                    child: Center(
                      child: Text(
                        isKalyan ? 'K' : 'S',
                        style: TextStyle(
                            color: sideTextColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_fmtDate(r.date),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const SizedBox(height: 3),
                        Row(children: [
                          _sideBadge(r.side, isKalyan),
                          const SizedBox(width: 6),
                          Text(_fmtCurrency(r.totalPaid),
                              style: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14)),
                        ]),
                      ],
                    ),
                  ),
                  // Action buttons + chevron
                  _actionBtn(Icons.edit_rounded, const Color(0xFF818CF8),
                      const Color(0x266366F1), const Color(0x806366F1), () async {
                    final res = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => RentScreen(editRecord: r)),
                    );
                    if (res == true) _fetchData();
                  }),
                  const SizedBox(width: 6),
                  _actionBtn(Icons.delete_outline_rounded, const Color(0xFFFB7185),
                      const Color(0x26F43F5E), const Color(0x80F43F5E),
                      () => _deleteRecord(r)),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 280),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFF64748B), size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Collapsible Details ──
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildDetails(r, isKalyan, gradFrom, gradTo),
            crossFadeState: isOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 280),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails(RentRecord r, bool isKalyan,
      Color gradFrom, Color gradTo) {
    return Column(
      children: [
        const Divider(color: Color(0x0FFFFFFF), height: 1, indent: 14, endIndent: 14),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.8,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _detailTile('Rent Amount', r.rentAmount,
                  Icons.home_rounded, const Color(0xFF818CF8),
                  const Color(0x1A6366F1), const Color(0x336366F1)),
              _detailTile('Paid Amount', r.paidAmount,
                  Icons.check_circle_rounded, const Color(0xFF34D399),
                  const Color(0x1A10B981), const Color(0x3310B981)),
              _detailTile('Balance', r.balanceAmount,
                  Icons.warning_rounded, const Color(0xFFFB7185),
                  const Color(0x1AF43F5E), const Color(0x33F43F5E)),
              _detailTile('Power Bill', r.powerBill,
                  Icons.bolt_rounded, const Color(0xFFFBBF24),
                  const Color(0x1AF59E0B), const Color(0x33F59E0B)),
              _detailTile('Water Bill', r.waterBill,
                  Icons.water_drop_rounded, const Color(0xFF60A5FA),
                  const Color(0x1A3B82F6), const Color(0x333B82F6)),
              _detailTile('Date', 0,
                  Icons.calendar_month_rounded, const Color(0xFF94A3B8),
                  const Color(0x1A64748B), const Color(0x3364748B),
                  dateText: _fmtDate(r.date)),
            ],
          ),
        ),
        // Remarks
        if (r.remarks.isNotEmpty && r.remarks != '-')
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x0FF59E0B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x33F59E0B)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    size: 14, color: Color(0xFFFBBF24)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(r.remarks,
                        style: const TextStyle(
                            color: Color(0xFFD1D5DB), fontSize: 12, height: 1.5))),
              ]),
            ),
          ),
        // Total Paid footer
        Padding(
          padding: const EdgeInsets.all(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [gradFrom, gradTo]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isKalyan
                      ? const Color(0x336366F1)
                      : const Color(0x33EC4899)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isKalyan
                        ? const Color(0x336366F1)
                        : const Color(0x33EC4899),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.savings_rounded,
                      color: isKalyan
                          ? const Color(0xFFA5B4FC)
                          : const Color(0xFFFDA4AF),
                      size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL PAID',
                          style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 2),
                      Text(_fmtCurrency(r.totalPaid),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x2210B981),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: const Color(0x3310B981)),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF34D399)),
                    SizedBox(width: 4),
                    Text('Paid',
                        style: TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailTile(String label, double value, IconData icon,
      Color textColor, Color bg, Color border,
      {String? dateText}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(children: [
            Icon(icon, size: 10, color: textColor.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(label.toUpperCase(),
                style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6)),
          ]),
          const SizedBox(height: 3),
          Text(
            dateText != null ? dateText : _fmtCurrency(value),
            style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color iconColor, Color bg, Color border,
      VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
      );

  Widget _sideBadge(String side, bool isKalyan) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isKalyan ? const Color(0x1A6366F1) : const Color(0x1AEC4899),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: isKalyan
                  ? const Color(0x336366F1)
                  : const Color(0x33EC4899)),
        ),
        child: Text(side,
            style: TextStyle(
                color: isKalyan
                    ? const Color(0xFFA5B4FC)
                    : const Color(0xFFFDA4AF),
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      );

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined,
                size: 72, color: Color(0xFF374151)),
            const SizedBox(height: 16),
            const Text('No records found',
                style: TextStyle(
                    color: Color(0xFF6B7280), fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
}

