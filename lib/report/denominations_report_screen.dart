import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/denomination_record.dart';
import '../services/api_service.dart';
import '../screens/denominations_screen.dart';

class DenominationsReportScreen extends StatefulWidget {
  const DenominationsReportScreen({super.key});

  @override
  State<DenominationsReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<DenominationsReportScreen> {
  bool _isLoading = true;
  bool _showBalance = false;
  List<DenominationRecord> _reports = [];
  double _sheet2Data = 0;
  final Set<int> _expanded = <int>{};

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final currentMonth = DateFormat('MMM yyyy').format(DateTime.now());
    final res = await ApiService.fetchReports(currentMonth);
    final rawBal = res['sheet2Data'];
    setState(() {
      _reports = res['reports'] as List<DenominationRecord>;
      _sheet2Data = rawBal is num
          ? rawBal.toDouble()
          : double.tryParse(rawBal?.toString() ?? '0') ?? 0;
      _isLoading = false;
    });
  }

  DateTime _parseDate(String value) {
    final fromTry = DateTime.tryParse(value);
    if (fromTry != null) return fromTry;
    final parts = value.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]) ?? 1;
      final m = _monthToNum(parts[1]);
      final y = int.tryParse(parts[2]) ?? DateTime.now().year;
      return DateTime(y, m, d);
    }
    return DateTime.now();
  }

  int _monthToNum(String mon) {
    const map = {
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
    return map[mon.toLowerCase().substring(0, 3)] ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF131A3A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(1.0, 1.0),
            radius: 1.25,
            colors: [Color(0xFF2A1E4D), Color(0xFF1A1F4A)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF6EA0FF)),
          )
              : Column(
            children: [
              _buildTopBar(),
              const SizedBox(height: 18),
              _buildBalanceCard(money),
              const SizedBox(height: 22),
              Expanded(
                child: _reports.isEmpty
                    ? const Center(
                  child: Text(
                    'No reports found',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                )
                    : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  itemCount: _reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) => _buildReportCard(index, _reports[index], money),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF171E3A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3A4466)),
      ),
      child: Row(
        children: [
          const Icon(Icons.pie_chart_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Denominations Report',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 32 / 2),
            ),
          ),
          _actionCircle(
            icon: Icons.sync,
            active: true,
            onTap: _fetchData,
          ),
          const SizedBox(width: 8),
          _actionCircle(
            icon: Icons.add,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DenominationsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          _actionCircle(
            icon: Icons.home,
            onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          const SizedBox(width: 8),
          _actionCircle(
            icon: Icons.settings,
            square: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionCircle({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
    bool square = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(square ? 10 : 22),
          color: active ? const Color(0xFF274983) : const Color(0xFF2D334A),
          border: Border.all(color: const Color(0xFF47516D)),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }

  Widget _buildBalanceCard(NumberFormat money) {
    final balanceText = _showBalance ? money.format(_sheet2Data) : '****';
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x553934A4), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Available Balance',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 21 / 2),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => setState(() => _showBalance = !_showBalance),
                child: Icon(
                  _showBalance ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            balanceText,
            style: const TextStyle(color: Colors.white, fontSize: 34 / 2, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(int index, DenominationRecord rec, NumberFormat money) {
    final dt = _parseDate(rec.date);
    final isExpanded = _expanded.contains(index);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF171E3A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3A4466)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expanded.remove(index);
                } else {
                  _expanded.add(index);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  _dateBadge(dt),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(dt),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 26 / 2),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Tap to view details',
                          style: TextStyle(color: Color(0xFF8A94B3), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 210,
                    child: _metricStack(rec, money),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: const Color(0xFF313A5B),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white70),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DenominationsScreen()),
                      );
                    },
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF97A0BD),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                height: 240,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(color: Color(0xFF2C3553), height: 16),
                        const _SectionTitle(label: 'DENOMINATIONS'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _chip('500', rec.d500),
                            _chip('200', rec.d200),
                            _chip('100', rec.d100),
                            _chip('50', rec.d50),
                            _chip('20', rec.d20),
                            _chip('10', rec.d10),
                            _chip('5', rec.d5),
                            _chip('2', rec.d2),
                            _chip('1', rec.d1),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const _SectionTitle(label: 'DETAILS'),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _detailRow('Week Expenses', money.format(rec.weekExpenses), dense: true),
                                  _detailRow('ATM Withdrawal', money.format(rec.atmWithdrawal), dense: true),
                                  _detailRow('Week Closing Balance', money.format(rec.weekClosingBalance), dense: true),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              child: Column(
                                children: [
                                  _detailRow('Adjust Amount', money.format(rec.adjustAmount), dense: true),
                                  _detailRow('A/C Paid', money.format(rec.acPaid), dense: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const _SectionTitle(label: 'REMARKS'),
                        const SizedBox(height: 6),
                        if (rec.remarks.trim().isNotEmpty)
                          Text(
                            rec.remarks.trim(),
                            style: const TextStyle(color: Color(0xFF98A4C2), fontSize: 12, height: 1.35),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dateBadge(DateTime dt) {
    final mon = DateFormat('MMM').format(dt).toUpperCase();
    final day = DateFormat('dd').format(dt);
    final year = DateFormat('yyyy').format(dt);

    return Container(
      width: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF27314E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF435175)),
      ),
      child: Column(
        children: [
          Text(mon, style: const TextStyle(color: Color(0xFF6EA0FF), fontSize: 9, fontWeight: FontWeight.w700)),
          Text(day, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.1)),
          Text(year, style: const TextStyle(color: Color(0xFF9EA8C6), fontSize: 9, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _metricStack(DenominationRecord rec, NumberFormat money) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _metricLine('OFFERINGS', money.format(rec.total), strong: true),
        const SizedBox(height: 2),
        _metricLine('A/C PAID', money.format(rec.acPaid)),
        const SizedBox(height: 2),
        _metricLine('WEEK AVL BAL', money.format(rec.weekClosingBalance)),
      ],
    );
  }

  Widget _metricLine(String label, String value, {bool strong = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: strong ? 33 / 2 : 24 / 2,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _chip(String denom, int count) {
    final colors = _chipColorByDenom(denom);
    final isZero = count == 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isZero ? const Color(0xFF22283F) : colors.$1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isZero ? const Color(0xFF2E3652) : colors.$2),
      ),
      child: Text(
        '₹$denom  |  $count',
        style: TextStyle(
          color: isZero ? const Color(0xFF8C95AF) : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  (Color, Color) _chipColorByDenom(String denom) {
    switch (denom) {
      case '500':
        return (const Color(0x2B1E5AA8), const Color(0xFF2F6BC2));
      case '200':
        return (const Color(0x2B7A3F1F), const Color(0xFFA95E2A));
      case '100':
        return (const Color(0x2B145844), const Color(0xFF238A72));
      case '50':
        return (const Color(0x2B5F1B5E), const Color(0xFF8D2D8B));
      case '20':
        return (const Color(0x2B1A2E75), const Color(0xFF4B5FC5));
      case '10':
        return (const Color(0x2B5A1F25), const Color(0xFF973642));
      default:
        return (const Color(0x1FFFFFFF), const Color(0x2FFFFFFF));
    }
  }

  Widget _detailRow(String label, String value, {bool dense = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 1 : 2),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 28 / 2, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 30 / 2, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          SizedBox(height: dense ? 3 : 5),
          const Divider(color: Color(0xFF2C3553), height: 1),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.layers, color: Colors.white, size: 14),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

