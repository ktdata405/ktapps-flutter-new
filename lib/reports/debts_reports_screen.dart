import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/debt_record.dart';
import '../screens/debts_screen.dart';
import '../services/api_service.dart';

class DebtsReportsScreen extends StatefulWidget {
  const DebtsReportsScreen({super.key});

  @override
  State<DebtsReportsScreen> createState() => _DebtsReportsScreenState();
}

class _DebtsReportsScreenState extends State<DebtsReportsScreen> {
  final _searchCtrl = TextEditingController();

  List<DebtRecord> _allDebts = [];
  List<DebtRecord> _visibleDebts = [];
  bool _loading = true;

  String _statusFilter = 'pending'; // pending|settled|all
  String _typeFilter = 'all'; // lent|borrowed|all
  String _overviewMode = 'card'; // card|list

  @override
  void initState() {
    super.initState();
    _fetch();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final rows = await ApiService.fetchDebts();
      if (!mounted) return;
      setState(() {
        _allDebts = rows;
        _loading = false;
      });
      _applyFilters();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load debts')),
      );
    }
  }

  void _applyFilters() {
    final q = _searchCtrl.text.trim().toLowerCase();
    var rows = List<DebtRecord>.from(_allDebts);

    rows = rows.where((d) {
      final searchOk = q.isEmpty ||
          d.person.toLowerCase().contains(q) ||
          d.remarks.toLowerCase().contains(q);

      final statusOk = _statusFilter == 'all' || d.status == _statusFilter;

      final mappedType = d.type == 'given' ? 'lent' : 'borrowed';
      final typeOk = _typeFilter == 'all' || mappedType == _typeFilter;

      return searchOk && statusOk && typeOk;
    }).toList();

    rows.sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));

    if (mounted) {
      setState(() => _visibleDebts = rows);
    }
  }

  DateTime _parseDate(String s) {
    final m = RegExp(r'^(\d{2})/(\w{3})/(\d{4})$').firstMatch(s);
    if (m == null) return DateTime(2000);
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
    final day = int.tryParse(m.group(1)!) ?? 1;
    final month = months[m.group(2)!] ?? 1;
    final year = int.tryParse(m.group(3)!) ?? 2000;
    return DateTime(year, month, day);
  }

  String _fmtCurrency(double value) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
          .format(value);

  int get _activeCount => _allDebts.where((d) => !d.isSettled).length;
  int get _peopleCount =>
      _allDebts.where((d) => !d.isSettled).map((d) => d.person).toSet().length;
  int get _settledCount => _allDebts.where((d) => d.isSettled).length;

  double get _totalLent => _allDebts
      .where((d) => !d.isSettled && d.type == 'given')
      .fold(0, (s, d) => s + d.amount);

  double get _totalBorrowed => _allDebts
      .where((d) => !d.isSettled && d.type == 'taken')
      .fold(0, (s, d) => s + d.amount);

  @override
  Widget build(BuildContext context) {
    final debtsByPerson = _groupByPerson(_visibleDebts);

    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      appBar: AppBar(
        title: const Text('Debts Intelligence'),
        backgroundColor: const Color(0xFF030712),
        actions: [
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh_rounded)),
          IconButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            icon: const Icon(Icons.home_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const DebtsScreen()),
          );
          if (ok == true) _fetch();
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
              children: [
                _topMetrics(),
                const SizedBox(height: 10),
                _filterPanel(),
                const SizedBox(height: 10),
                _listHeader(_visibleDebts.length),
                const SizedBox(height: 8),
                if (_visibleDebts.isEmpty)
                  _emptyCard()
                else
                  ...debtsByPerson.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _personBlock(e.key, e.value),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _topMetrics() {
    final total = _totalLent + _totalBorrowed;
    final lentPct = total == 0 ? 0.0 : (_totalLent / total);
    final borrowedPct = total == 0 ? 0.0 : (_totalBorrowed / total);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xBF0F172A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _modeChip('card', 'Card'),
              const SizedBox(width: 6),
              _modeChip('list', 'List'),
            ],
          ),
          const SizedBox(height: 8),
          _overviewMode == 'list'
              ? Column(
                  children: [
                    _listMetric('Active Debts', '$_activeCount', Colors.white),
                    _listMetric('People Involved', '$_peopleCount', const Color(0xFFC4B5FD)),
                    _listMetric('Settled Records', '$_settledCount', const Color(0xFF6EE7B7)),
                    _listMetric('Total Receivable', _fmtCurrency(_totalLent), Colors.white),
                    LinearProgressIndicator(
                      value: lentPct,
                      backgroundColor: Colors.white12,
                      color: const Color(0xFF34D399),
                    ),
                    const SizedBox(height: 8),
                    _listMetric('Total Payable', _fmtCurrency(_totalBorrowed), Colors.white),
                    LinearProgressIndicator(
                      value: borrowedPct,
                      backgroundColor: Colors.white12,
                      color: const Color(0xFFFB7185),
                    ),
                  ],
                )
              : GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.85,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: [
                    _metricCard('Active Debts', '$_activeCount', Colors.white),
                    _metricCard('People Involved', '$_peopleCount', const Color(0xFFC4B5FD)),
                    _metricCard('Settled Records', '$_settledCount', const Color(0xFF6EE7B7)),
                    _metricCard('Total Receivable', _fmtCurrency(_totalLent), Colors.white),
                    _metricCard('Total Payable', _fmtCurrency(_totalBorrowed), Colors.white),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _modeChip(String value, String label) {
    final active = _overviewMode == value;
    return InkWell(
      onTap: () => setState(() => _overviewMode = value),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: active
                ? const Color(0xFF818CF8)
                : Colors.white.withValues(alpha: 0.22),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _listMetric(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w700)),
          ),
          Text(
            value,
            style: TextStyle(color: valueColor, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _filterPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xBF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Search by name or remarks',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Pending', _statusFilter == 'pending',
                  () => _setStatus('pending')),
              _chip('Settled', _statusFilter == 'settled',
                  () => _setStatus('settled')),
              _chip('All', _statusFilter == 'all', () => _setStatus('all')),
              const SizedBox(width: 8),
              _chip('All Types', _typeFilter == 'all', () => _setType('all')),
              _chip('Lent', _typeFilter == 'lent', () => _setType('lent')),
              _chip('Borrowed', _typeFilter == 'borrowed',
                  () => _setType('borrowed')),
            ],
          ),
        ],
      ),
    );
  }

  void _setStatus(String v) {
    setState(() => _statusFilter = v);
    _applyFilters();
  }

  void _setType(String v) {
    setState(() => _typeFilter = v);
    _applyFilters();
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: active ? const Color(0xFF6366F1) : const Color(0x991E293B),
          border: Border.all(
            color: active ? const Color(0xFF818CF8) : const Color(0xFF334155),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _listHeader(int count) {
    final status = _statusFilter == 'all'
        ? 'All'
        : _statusFilter == 'pending'
            ? 'Pending'
            : 'Settled';
    final type = _typeFilter == 'all'
        ? 'Debts'
        : _typeFilter == 'lent'
            ? 'Lent'
            : 'Borrowed';

    return Row(
      children: [
        Text(
          '$status $type',
          style: const TextStyle(
            color: Color(0xFFCBD5E1),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Text(
            '$count record${count == 1 ? '' : 's'}',
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 42),
      decoration: BoxDecoration(
        color: const Color(0xBF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 42, color: Color(0xFF475569)),
          SizedBox(height: 8),
          Text('No matching records',
              style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Map<String, List<DebtRecord>> _groupByPerson(List<DebtRecord> rows) {
    final map = <String, List<DebtRecord>>{};
    for (final r in rows) {
      map.putIfAbsent(r.person.isEmpty ? 'Unknown' : r.person, () => []);
      map[r.person.isEmpty ? 'Unknown' : r.person]!.add(r);
    }
    return map;
  }

  Widget _personBlock(String person, List<DebtRecord> rows) {
    rows.sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));

    double net = 0;
    var pending = 0;
    for (final r in rows) {
      if (!r.isSettled) pending += 1;
      net += r.type == 'given' ? r.amount : -r.amount;
    }

    final netPositive = net >= 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0x660A1223),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF6366F1),
                  child: Text(
                    _initials(person),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                      Text(
                        '${rows.length} transaction${rows.length == 1 ? '' : 's'}'
                        '${pending > 0 ? ' · $pending pending' : ''}',
                        style: TextStyle(
                          color:
                              pending > 0 ? const Color(0xFFFBBF24) : const Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: netPositive
                        ? const Color(0x2210B981)
                        : const Color(0x22F43F5E),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: netPositive
                          ? const Color(0x4010B981)
                          : const Color(0x40F43F5E),
                    ),
                  ),
                  child: Text(
                    '${netPositive ? 'Pays you' : 'You pay'} ${_fmtCurrency(net.abs())}',
                    style: TextStyle(
                      color: netPositive
                          ? const Color(0xFF34D399)
                          : const Color(0xFFFB7185),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: rows.map(_debtRow).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ').where((e) => e.trim().isNotEmpty).toList();
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Widget _debtRow(DebtRecord r) {
    final isGiven = r.type == 'given';
    final accent = isGiven ? const Color(0xFF34D399) : const Color(0xFFFB7185);
    final month = _parseDate(r.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(
                  '${month.day}'.padLeft(2, '0'),
                  style: TextStyle(
                      color: accent, fontSize: 12, fontWeight: FontWeight.w900),
                ),
                Text(
                  DateFormat('MMM').format(month),
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.9),
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${isGiven ? 'Given to' : 'Taken from'} ${r.person}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _badge(isGiven ? 'Lent' : 'Borrowed',
                        isGiven ? const Color(0xFF34D399) : const Color(0xFFFB7185)),
                    _badge(r.isSettled ? 'Settled' : 'Pending',
                        r.isSettled ? const Color(0xFF34D399) : const Color(0xFFFBBF24)),
                  ],
                ),
                if (r.remarks.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(r.remarks,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _fmtCurrency(r.amount),
                style: TextStyle(
                  color: r.isSettled ? const Color(0xFF94A3B8) : Colors.white,
                  fontWeight: FontWeight.w900,
                  decoration: r.isSettled ? TextDecoration.lineThrough : null,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _actionBtn(Icons.edit_rounded, 'Edit', () async {
                    final ok = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => DebtsScreen(editRecord: r)),
                    );
                    if (ok == true) _fetch();
                  }),
                  const SizedBox(width: 4),
                  _actionBtn(
                    r.isSettled ? Icons.restart_alt_rounded : Icons.check_circle_rounded,
                    r.isSettled ? 'Reopen' : 'Settle',
                    () => _toggleStatus(r),
                  ),
                  const SizedBox(width: 4),
                  _actionBtn(Icons.delete_rounded, 'Delete', () => _delete(r)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String tip, VoidCallback onTap) {
    return Tooltip(
      message: tip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  Future<void> _toggleStatus(DebtRecord r) async {
    final isSettling = !r.isSettled;
    final remarksCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: Text(isSettling ? 'Settle Debt' : 'Reopen Debt',
              style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isSettling
                    ? 'Mark this debt as settled?'
                    : 'Mark this debt as pending again?',
                style: const TextStyle(color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: remarksCtrl,
                decoration:
                    const InputDecoration(hintText: 'Add remarks (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isSettling ? 'Settle' : 'Reopen'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || r.id == null) return;

    await ApiService.updateDebtStatus(
      r.id!,
      status: r.isSettled ? 'pending' : 'settled',
      settleRemarks: remarksCtrl.text.trim(),
    );
    _fetch();
  }

  Future<void> _delete(DebtRecord r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text('Delete Debt', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to delete this record?',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (ok != true || r.id == null) return;
    await ApiService.deleteDebt(r.id!);
    _fetch();
  }
}

