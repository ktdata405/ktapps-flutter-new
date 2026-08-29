import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core_constants.dart';
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
  final Set<int> _open = {};

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final payload = await _service.fetchReport();
      final listRaw =
          (payload is Map)
              ? (payload['reports'] ?? payload['data'] ?? const [])
              : const [];
      final rows =
          (listRaw as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

      rows.sort((a, b) {
        final da = _parseDate(a['Date']);
        final db = _parseDate(b['Date']);
        if (da == null && db == null) return 0;
        if (da == null) return 1;
        if (db == null) return -1;
        return db.compareTo(da);
      });

      setState(() {
        _rows = rows;
        final s2 = payload is Map ? payload['sheet2Data'] : null;
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

  DateTime? _parseDate(Object? v) {
    final raw = (v ?? '').toString().trim();
    if (raw.isEmpty) return null;
    final direct = DateTime.tryParse(raw);
    if (direct != null) return direct;
    for (final p in ['dd/MMM/yyyy', 'dd-MM-yyyy', 'dd/MM/yyyy']) {
      try {
        return DateFormat(p).parseStrict(raw);
      } catch (_) {}
    }
    return null;
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
              'Denominations Report',
              style: TextStyle(
                color: ktTextWhite,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _headerIcon(Icons.refresh, _fetch, filled: true),
          const SizedBox(width: 8),
          _headerIcon(
            Icons.add,
            () => Navigator.pushNamed(context, '/denominations'),
          ),
          const SizedBox(width: 8),
          _headerIcon(Icons.home, () => Navigator.pushNamed(context, '/')),
          const SizedBox(width: 8),
          _headerIcon(
            Icons.settings,
            () => Navigator.pushNamed(context, '/settings'),
            outlined: true,
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(
    IconData icon,
    VoidCallback onTap, {
    bool filled = false,
    bool outlined = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color:
              filled
                  ? const Color(0xFF213B6C)
                  : Colors.white.withValues(alpha: 0.08),
          border: outlined ? Border.all(color: ktPanelBorder) : null,
        ),
        child: Icon(icon, color: Colors.white, size: 19),
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
    final open = _open.contains(index);
    final dateRaw = row['Date']?.toString() ?? '-';
    final date = _parseDate(dateRaw);
    final dateLabel =
        date == null ? dateRaw : DateFormat('dd MMM yyyy').format(date);
    final mon =
        date == null ? '---' : DateFormat('MMM').format(date).toUpperCase();
    final yr = date == null ? '----' : DateFormat('yyyy').format(date);
    final day = date == null ? '--' : DateFormat('dd').format(date);

    final total = _formatCurrency(row['Total']);
    final acPaidRaw = double.tryParse('${row['A/C Paid'] ?? 0}') ?? 0;
    final closingEntry = row.entries.firstWhere(
      (e) =>
          e.key.toLowerCase().contains('closing') ||
          e.key.toLowerCase().contains('avl bal'),
      orElse: () => const MapEntry('', ''),
    );
    final closingVal =
        closingEntry.key.isEmpty ? null : _formatCurrency(closingEntry.value);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ktPanelBorder),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap:
                () => setState(
                  () => open ? _open.remove(index) : _open.add(index),
                ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(color: ktPanelBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          mon,
                          style: const TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          day,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            height: 0.95,
                          ),
                        ),
                        Text(
                          yr,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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
                  Container(width: 1, height: 56, color: ktPanelBorder),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed:
                        () => Navigator.pushNamed(
                          context,
                          '/denominations',
                          arguments: row,
                        ),
                    icon: const Icon(Icons.edit, color: Colors.white, size: 18),
                  ),
                  Icon(
                    open ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white70,
                    size: 19,
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: ktPanelBorder)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DENOMINATIONS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final d in [
                          '500',
                          '200',
                          '100',
                          '50',
                          '20',
                          '10',
                          '5',
                          '2',
                          '1',
                        ])
                          _denomChip(d, row[d]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'DETAILS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _detailRow(
                            'Week Expenses',
                            row['Week Expenses'],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _detailRow(
                            'Adjust Amount',
                            row['Adjust Amount'],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _detailRow(
                            'ATM Withdrawal',
                            row['ATM Withdrawal'],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _detailRow('A/C Paid', row['A/C Paid']),
                        ),
                      ],
                    ),
                    if (closingVal != null)
                      _detailRow('Week Closing Balance', closingEntry.value),
                    if ('${row['Remarks'] ?? ''}'.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'REMARKS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '"${row['Remarks']}"',
                              style: const TextStyle(
                                color: ktTextGray400,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
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

  Widget _denomChip(String d, Object? val) {
    final v = int.tryParse('${val ?? 0}') ?? 0;
    final active = v > 0;
    final style = _denomStyle(d, active);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: style.$1,
        border: Border.all(color: style.$2),
      ),
      child: Text(
        '₹$d   |   $v',
        style: TextStyle(
          color: style.$3,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
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

  Widget _detailRow(String label, Object? value) {
    final n = double.tryParse('${value ?? ''}');
    final display =
        n == null ? '${value ?? '-'}' : _formatCurrency(n, decimals: 2);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x1FFFFFFF))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            display,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
