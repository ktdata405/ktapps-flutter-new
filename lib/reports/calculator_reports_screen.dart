import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/calculator_record.dart';
import '../services/api_service.dart';

class CalculatorReportsScreen extends StatefulWidget {
  const CalculatorReportsScreen({super.key});

  @override
  State<CalculatorReportsScreen> createState() => _CalculatorReportsScreenState();
}

class _CalculatorReportsScreenState extends State<CalculatorReportsScreen> {
  final _searchCtrl = TextEditingController();
  List<CalculatorRecord> _rows = [];
  List<CalculatorRecord> _visible = [];
  bool _loading = true;
  String _moduleFilter = 'All';

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
    final data = await ApiService.fetchCalculatorRecords();
    if (!mounted) return;
    setState(() {
      _rows = data;
      _loading = false;
    });
    _apply();
  }

  void _apply() {
    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = _rows.where((r) {
      final moduleOk = _moduleFilter == 'All' || r.module == _moduleFilter;
      final text = '${r.module} ${r.inputSummary} ${r.resultSummary} ${r.note}'.toLowerCase();
      final searchOk = q.isEmpty || text.contains(q);
      return moduleOk && searchOk;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    setState(() => _visible = filtered);
  }

  List<String> get _modules {
    final set = _rows.map((e) => e.module).toSet().toList()..sort();
    return ['All', ...set];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        title: const Text('Calculator Reports'),
        actions: [
          IconButton(onPressed: _fetch, icon: const Icon(Icons.refresh_rounded)),
          IconButton(onPressed: _clearAll, icon: const Icon(Icons.delete_sweep_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
                children: [
                  _header(),
                  const SizedBox(height: 10),
                  _filters(),
                  const SizedBox(height: 10),
                  if (_visible.isEmpty)
                    _empty()
                  else
                    ..._visible.map(_card),
                ],
              ),
            ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xBF18181B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            ),
            child: const Icon(Icons.analytics_rounded, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saved Calculations',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                Text('${_rows.length} total records',
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ],
            ),
          ),
        ]),
      );

  Widget _filters() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xBF18181B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(children: [
          TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: 'Search calculations',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _modules.map((m) {
                final active = _moduleFilter == m;
                return InkWell(
                  onTap: () {
                    setState(() => _moduleFilter = m);
                    _apply();
                  },
                  borderRadius: BorderRadius.circular(99),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF6366F1) : const Color(0xFF27272A),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: active ? const Color(0xFF818CF8) : const Color(0xFF3F3F46),
                      ),
                    ),
                    child: Text(m,
                        style: TextStyle(
                            color: active ? Colors.white : const Color(0xFFA1A1AA),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                );
              }).toList(),
            ),
          ),
        ]),
      );

  Widget _card(CalculatorRecord r) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xBF18181B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0x1A6366F1),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0x406366F1)),
              ),
              child: Text(r.module,
                  style: const TextStyle(
                      color: Color(0xFFA5B4FC), fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            Text(DateFormat('dd MMM yyyy, hh:mm a').format(r.createdAt),
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
            const SizedBox(width: 8),
            InkWell(
              onTap: () => _delete(r),
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.delete_outline_rounded,
                    size: 16, color: Color(0xFFFB7185)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          const Text('Input',
              style: TextStyle(
                  color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700)),
          Text(r.inputSummary, style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(height: 6),
          const Text('Result',
              style: TextStyle(
                  color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700)),
          Text(r.resultSummary, style: const TextStyle(color: Colors.white, fontSize: 12)),
          if (r.note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(r.note,
                style: const TextStyle(
                    color: Color(0xFF64748B), fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ]),
      );

  Widget _empty() => Container(
        padding: const EdgeInsets.symmetric(vertical: 50),
        decoration: BoxDecoration(
          color: const Color(0xBF18181B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Column(
          children: [
            Icon(Icons.inbox_outlined, color: Color(0xFF52525B), size: 44),
            SizedBox(height: 8),
            Text('No calculations found',
                style: TextStyle(color: Color(0xFF71717A))),
          ],
        ),
      );

  Future<void> _delete(CalculatorRecord r) async {
    if (r.id == null) return;
    await ApiService.deleteCalculatorRecord(r.id!);
    _fetch();
  }

  Future<void> _clearAll() async {
    await ApiService.clearCalculatorRecords();
    _fetch();
  }
}

