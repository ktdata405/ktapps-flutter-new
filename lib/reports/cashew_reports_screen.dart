import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/cashew_record.dart';
import '../screens/cashew_screen.dart';
import '../services/api_service.dart';

class CashewReportsScreen extends StatefulWidget {
  const CashewReportsScreen({super.key});

  @override
  State<CashewReportsScreen> createState() => _CashewReportsScreenState();
}

class _CashewReportsScreenState extends State<CashewReportsScreen> {
  final _searchCtrl = TextEditingController();

  List<CashewRecord> _all = [];
  List<CashewRecord> _visible = [];
  bool _loading = true;

  String _statusFilter = 'all';
  String _categoryFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_apply);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final rows = await ApiService.fetchCashewRecords();
    if (!mounted) return;
    setState(() {
      _all = rows;
      _loading = false;
    });
    _apply();
  }

  void _apply() {
    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = _all.where((r) {
      final statusOk =
          _statusFilter == 'all' || r.status.toLowerCase() == _statusFilter;
      final categoryOk =
          _categoryFilter == 'all' || r.category == _categoryFilter;
      final searchOk = q.isEmpty ||
          r.category.toLowerCase().contains(q) ||
          r.description.toLowerCase().contains(q);
      return statusOk && categoryOk && searchOk;
    }).toList()
      ..sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));

    setState(() => _visible = filtered);
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
    final d = int.tryParse(m.group(1)!) ?? 1;
    final mm = months[m.group(2)!] ?? 1;
    final y = int.tryParse(m.group(3)!) ?? 1970;
    return DateTime(y, mm, d);
  }

  double get _total => _visible.fold<double>(0, (s, e) => s + e.amount);

  int get _days => _visible.map((e) => e.date).toSet().length;

  List<String> get _categories {
    final set = _all.map((e) => e.category).toSet().toList()..sort();
    return ['all', ...set];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: const Color(0xFF020617),
        title: const Text('Cashew Report'),
        actions: [
          IconButton(
              onPressed: _fetch, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CashewScreen()),
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
                _stats(),
                const SizedBox(height: 10),
                _filters(),
                const SizedBox(height: 10),
                ..._buildDateBlocks(),
                if (_visible.isEmpty) _empty(),
              ],
            ),
    );
  }

  Widget _stats() {
    final nf =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xBF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(child: _metric('Total Spent', nf.format(_total))),
          const SizedBox(width: 8),
          Expanded(child: _metric('Days with Data', '$_days')),
          const SizedBox(width: 8),
          Expanded(
            child: _metric(
              'Draft Rows',
              '${_visible.where((e) => e.isDraft).length}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _filters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xBF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Search description or category',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Status')),
                    DropdownMenuItem(
                        value: 'completed', child: Text('Completed')),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                  ],
                  onChanged: (v) {
                    setState(() => _statusFilter = v ?? 'all');
                    _apply();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _categoryFilter,
                  items: _categories
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e == 'all' ? 'All Categories' : e),
                          ))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _categoryFilter = v ?? 'all');
                    _apply();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDateBlocks() {
    final grouped = <String, List<CashewRecord>>{};
    for (final row in _visible) {
      grouped.putIfAbsent(row.date, () => []).add(row);
    }

    final dates = grouped.keys.toList()
      ..sort((a, b) => _parseDate(b).compareTo(_parseDate(a)));

    return dates.map((date) {
      final rows = grouped[date]!;
      final total = rows.fold<double>(0, (s, e) => s + e.amount);
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xBF0F172A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CashewScreen(initialDate: _parseDate(date))),
                );
                if (ok == true) _fetch();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Row(
                  children: [
                    Text(date,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                    const Spacer(),
                    Text(
                      NumberFormat.currency(
                              locale: 'en_IN', symbol: '₹', decimalDigits: 0)
                          .format(total),
                      style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0x33334155)),
            ...rows.map((r) => ListTile(
                  dense: true,
                  title: Text(r.category,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 13)),
                  subtitle: Text(
                    r.description.isEmpty ? 'No description' : r.description,
                    style:
                        const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        NumberFormat.currency(
                                locale: 'en_IN', symbol: '₹', decimalDigits: 0)
                            .format(r.amount),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        r.status,
                        style: TextStyle(
                          color: r.isDraft
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF6EE7B7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
    }).toList();
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xBF0F172A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, color: Color(0xFF475569), size: 40),
          SizedBox(height: 8),
          Text('No records found', style: TextStyle(color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }
}
