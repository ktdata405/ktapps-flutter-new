import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/denomination_record.dart';
import '../screens/denominations_screen.dart';
import '../services/api_service.dart';

class DenominationsReportsScreen extends StatefulWidget {
  const DenominationsReportsScreen({super.key});

  @override
  State<DenominationsReportsScreen> createState() =>
      _DenominationsReportsScreenState();
}

class _DenominationsReportsScreenState
    extends State<DenominationsReportsScreen> {
  List<DenominationRecord> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final rows = await ApiService.fetchDenominationReports();
    if (!mounted) return;
    setState(() {
      _rows = rows;
      _loading = false;
    });
  }

  DateTime _parseDate(String value) {
    final m = RegExp(r'^(\d{2})/(\w{3})/(\d{4})$').firstMatch(value);
    if (m == null) return DateTime(1970);
    const months = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };
    final d = int.tryParse(m.group(1) ?? '') ?? 1;
    final mm = months[m.group(2) ?? 'Jan'] ?? 1;
    final y = int.tryParse(m.group(3) ?? '') ?? 1970;
    return DateTime(y, mm, d);
  }

  double get _latestAvailableBalance =>
      _rows.isEmpty ? 0 : _rows.first.availableBalance;

  @override
  Widget build(BuildContext context) {
    final nf =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Denominations Report'),
        actions: [
          IconButton(
              onPressed: _fetch, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const DenominationsScreen()),
          );
          if (ok == true) _fetch();
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xBF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available Balance',
                          style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(
                        nf.format(_latestAvailableBalance),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 26),
                      ),
                      const SizedBox(height: 6),
                      Text(
                          '${_rows.length} saved record${_rows.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (_rows.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: const Color(0xBF1E293B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 40, color: Color(0xFF475569)),
                        SizedBox(height: 8),
                        Text('No reports found',
                            style: TextStyle(color: Color(0xFF94A3B8))),
                      ],
                    ),
                  )
                else
                  ..._rows.map((row) => _recordTile(row, nf)),
              ],
            ),
    );
  }

  Widget _recordTile(DenominationRecord row, NumberFormat nf) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xBF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        title: Text(row.date,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800)),
        subtitle: Text(
          'Offerings ${nf.format(row.total)}  ·  A/C Paid ${nf.format(row.acPaid)}',
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
        ),
        trailing: Text(
          nf.format(row.availableBalance),
          style: TextStyle(
            color: row.availableBalance >= 0
                ? const Color(0xFF6EE7B7)
                : const Color(0xFFFB7185),
            fontWeight: FontWeight.w800,
          ),
        ),
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final d in const [500, 200, 100, 50, 20, 10, 5, 2, 1])
                _chip('₹$d', row.counts[d] ?? 0),
            ],
          ),
          const SizedBox(height: 10),
          _detailLine('Week Expenses', nf.format(row.weekExpenses)),
          _detailLine('Adjust Amount', nf.format(row.adjustAmount)),
          _detailLine('ATM Withdrawal', nf.format(row.atmWithdrawal)),
          _detailLine('A/C Paid', nf.format(row.acPaid)),
          _detailLine('Available Balance', nf.format(row.availableBalance)),
          if (row.remarks.isNotEmpty) _detailLine('Remarks', row.remarks),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        DenominationsScreen(initialDate: _parseDate(row.date)),
                  ),
                );
                if (ok == true) _fetch();
              },
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String denom, int count) {
    final active = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0x1A6366F1) : const Color(0x0FFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? const Color(0x406366F1)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Text(
        '$denom × $count',
        style: TextStyle(
          color: active ? const Color(0xFFA5B4FC) : const Color(0xFF64748B),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
