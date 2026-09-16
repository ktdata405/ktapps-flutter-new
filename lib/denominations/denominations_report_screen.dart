import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core_constants.dart';
import '../core_ui_utils.dart';
import '../core_utils.dart';
import 'denominations_service.dart';

class DenominationsReportScreen extends StatefulWidget {
  const DenominationsReportScreen({super.key});

  @override
  State<DenominationsReportScreen> createState() =>
      _DenominationsReportScreenState();
}

class _DenominationsReportScreenState extends State<DenominationsReportScreen> {
  final _service = DenominationsService();
  bool _loading = true;
  bool _showBalance = false;
  String? _sheet2Raw;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final payload = await _service.fetchReport();
      final dynamic listRaw = payload['reports'] ?? payload['data'];
      
      List<Map<String, dynamic>> rows = [];
      if (listRaw is List) {
        for (var item in listRaw) {
          if (item is Map) {
            rows.add(Map<String, dynamic>.from(item));
          }
        }
      }

      rows.sort((a, b) {
        final da = ktParseDate(a['Date']);
        final db = ktParseDate(b['Date']);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

      setState(() {
        _rows = rows;
        final s2 = payload['sheet2Data'];
        _sheet2Raw = s2 == null || '$s2'.trim().isEmpty ? null : '$s2';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load reports: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatCurrency(Object? amount, {int decimals = 0}) {
    final n = double.tryParse('${amount ?? 0}') ?? 0;
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: decimals,
    ).format(n);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ktBgDark,
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 20),
          children: [
            _buildHeaderBar(),
            const SizedBox(height: 18),
            if (_sheet2Raw != null) _buildBalanceCard(),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_rows.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Column(
                  children: [
                    Icon(Icons.list_alt, color: Color(0xFF475569), size: 68),
                    SizedBox(height: 12),
                    Text(
                      'No reports found',
                      style: TextStyle(
                        color: ktTextGray400,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_rows.length, (i) => _reportCard(_rows[i], i)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ktPanelBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.pie_chart, color: Colors.white70, size: 22),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Denom's Report",
              style: TextStyle(
                color: ktTextWhite,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ktHeaderIcon(Icons.refresh, _fetch),
          const SizedBox(width: 8),
          ktHeaderIcon(
            Icons.add,
            () => Navigator.pushNamed(context, '/denominations'),
          ),
          const SizedBox(width: 8),
          ktHeaderIcon(Icons.home, () => Navigator.pushNamed(context, '/')),
          const SizedBox(width: 8),
          ktHeaderIcon(
            Icons.settings,
            () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }



  Widget _buildBalanceCard() {
    return Center(
      child: Container(
        width: 240,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [ktPrimary, ktSecondary]),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Available Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _showBalance = !_showBalance),
                  child: Icon(
                    _showBalance ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _showBalance ? _formatCurrency(_sheet2Raw) : '****',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportCard(Map<String, dynamic> row, int index) {
    final dateRaw = row['Date']?.toString() ?? '-';
    final date = ktParseDate(dateRaw);
    final dateLabel = date == null ? dateRaw : ktFormatDate(date);
    final mon = date == null ? '---' : DateFormat('MMM').format(date).toUpperCase();
    final yr = date == null ? '----' : DateFormat('yyyy').format(date);
    final day = date == null ? '--' : DateFormat('dd').format(date);

    final total = _formatCurrency(row['Total']);
    final acPaidRaw = double.tryParse('${row['A/C Paid'] ?? 0}') ?? 0;
    final closingEntry = row.entries.firstWhere(
      (e) => e.key.toLowerCase().contains('closing') || e.key.toLowerCase().contains('avl bal'),
      orElse: () => const MapEntry('', ''),
    );
    final closingVal = closingEntry.key.isEmpty ? null : _formatCurrency(closingEntry.value);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ktPanelBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetails(row),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Icon(
                  Icons.payments_rounded,
                  color: Color(0xFF60A5FA),
                  size: 28,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        color: ktTextWhite,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Tap to view details',
                      style: TextStyle(
                        color: Color(0xFF7D8799),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        const Text(
                          'OFFERINGS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          total,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    if (acPaidRaw != 0)
                      Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          const Text(
                            'A/C PAID',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _formatCurrency(acPaidRaw, decimals: 0),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    if (closingVal != null)
                      Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 2,
                        children: [
                          const Text(
                            'WEEK AVL BAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            closingVal,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.keyboard_arrow_right,
                color: ktTextGray500,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> row) {
    final List<Map<String, dynamic>> details = [];

    final date = ktParseDate(row['Date']);
    final dateSubtitle = date == null ? (row['Date']?.toString() ?? '-') : ktFormatDate(date);

    final denoms = ['500', '200', '100', '50', '20', '10', '5', '2', '1'];
    final bodyHeader = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: denoms.map((d) {
        final v = int.tryParse('${row[d] ?? 0}') ?? 0;
        final style = _denomStyle(d, v > 0);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: style.$1.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: style.$2.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '₹$d',
                style: TextStyle(
                  color: style.$3,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(width: 1, height: 12, color: Colors.white24),
              ),
              Text(
                '$v',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    details.add({'label': 'Week Expenses', 'value': _formatCurrency(row['Week Expenses'], decimals: 2), 'color': ktRose});
    details.add({'label': 'Adjust Amount', 'value': _formatCurrency(row['Adjust Amount'], decimals: 2), 'color': ktAmber});
    details.add({'label': 'ATM Withdrawal', 'value': _formatCurrency(row['ATM Withdrawal'], decimals: 2), 'color': ktBlue});
    details.add({'label': 'A/C Paid', 'value': _formatCurrency(row['A/C Paid'], decimals: 2), 'color': ktEmerald});

    final closingEntry = row.entries.firstWhere(
      (e) => e.key.toLowerCase().contains('closing') || e.key.toLowerCase().contains('avl bal'),
      orElse: () => const MapEntry('', ''),
    );
    if (closingEntry.key.isNotEmpty) {
      details.add({'label': 'Closing Balance', 'value': _formatCurrency(closingEntry.value), 'color': ktTeal500});
    }

    details.add({
      'label': 'TOTAL OFFERING',
      'value': _formatCurrency(row['Total']),
      'color': Colors.white,
      'isHighlight': true,
    });

    ktShowDetailsSheet(
      context: context,
      title: 'Denom Details',
      subtitle: dateSubtitle,
      icon: Icons.payments_rounded,
      themeColor: ktPrimary,
      bodyHeader: bodyHeader,
      details: details,
      footerNote: '${row['Remarks'] ?? ''}'.trim().isNotEmpty ? row['Remarks'] : null,
      actions: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/denominations', arguments: row).then((_) => _fetch());
          },
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Edit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ktPrimary,
            foregroundColor: ktWhite,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  (Color, Color, Color) _denomStyle(String d, bool active) {
    if (!active) {
      return (
        const Color(0x1A0B1020),
        const Color(0x1CFFFFFF),
        const Color(0xFF6B7280),
      );
    }
    switch (d) {
      case '500':
        return (
          const Color(0x162563EB),
          const Color(0x553B82F6),
          const Color(0xFF93C5FD),
        );
      case '200':
        return (
          const Color(0x284C1D07),
          const Color(0x55FB923C),
          const Color(0xFFFED7AA),
        );
      case '100':
        return (
          const Color(0x1A065F46),
          const Color(0x5534D399),
          const Color(0xFFA7F3D0),
        );
      case '50':
        return (
          const Color(0x1A831843),
          const Color(0x55EC4899),
          const Color(0xFFF9A8D4),
        );
      case '20':
        return (
          const Color(0x1A1E3A8A),
          const Color(0x556366F1),
          const Color(0xFFC7D2FE),
        );
      case '10':
        return (
          const Color(0x1A7F1D1D),
          const Color(0x55EF4444),
          const Color(0xFFFECACA),
        );
      default:
        return (
          const Color(0x1A1F2937),
          const Color(0x334B5563),
          const Color(0xFFE5E7EB),
        );
    }
  }
}
