import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core_utils.dart';
import 'package:ktppsflutter/core_constants.dart';
import 'rent_models.dart';
import 'rent_service.dart';
import 'rent_entry_screen.dart';

class RentReportScreen extends StatefulWidget {
  const RentReportScreen({super.key});

  @override
  State<RentReportScreen> createState() => _RentReportScreenState();
}

class _RentReportScreenState extends State<RentReportScreen> {
  final RentService _service = RentService();
  List<RentRecord> _allRecords = [];
  List<RentRecord> _filteredRecords = [];
  bool _loading = false;
  String _sideFilter = 'All';
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final records = await _service.fetchRecords();
    setState(() {
      _allRecords = records;
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      if (_sideFilter == 'All') {
        _filteredRecords = List.from(_allRecords);
      } else {
        _filteredRecords = _allRecords.where((r) => r.side == _sideFilter).toList();
      }
      _filteredRecords.sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
    });
  }

  DateTime _parseDate(String dateStr) {
    try {
      return DateFormat('dd/MMM/yyyy').parse(dateStr);
    } catch (e) {
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return getIndiaTime();
      }
    }
  }

  double get _totalCollected => _filteredRecords.fold(0, (sum, item) => sum + item.totalPaid);
  double get _pendingAmount => _filteredRecords.fold(0, (sum, item) => sum + item.balanceAmount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ktBgDark,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStats(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchData,
                color: ktPrimary,
                child: _loading && _allRecords.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: ktPrimary))
                    : _filteredRecords.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filteredRecords.length,
                            itemBuilder: (context, index) => _buildRecordCard(index),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: ktWhite, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Rent Report',
              style: TextStyle(color: ktWhite, fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            offset: const Offset(0, 40),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: ktCardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ktBorderWhite10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_sideFilter, style: const TextStyle(color: ktWhite, fontSize: 12, fontWeight: FontWeight.bold)),
                  const Icon(Icons.keyboard_arrow_down, color: ktWhite, size: 14),
                ],
              ),
            ),
            onSelected: (val) {
              setState(() {
                _sideFilter = val;
                _applyFilter();
              });
            },
            itemBuilder: (context) => ['All', 'Kalyan', 'Srikanth']
                .map((e) => PopupMenuItem(value: e, child: Text(e, style: const TextStyle(color: ktWhite, fontSize: 13))))
                .toList(),
            color: ktCardBg,
          ),
          IconButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            icon: const Icon(Icons.home_outlined, color: ktWhite, size: 22),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/rent').then((_) => _fetchData()),
            icon: const Icon(Icons.add_box_outlined, color: ktWhite, size: 22),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _statItem('COLLECTED', _totalCollected, ktEmerald),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statItem('PENDING', _pendingAmount, ktRose),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ktBorderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: ktTextGray500, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '₹${NumberFormat('#,##,###').format(value)}',
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(int index) {
    final record = _filteredRecords[index];
    final isExpanded = _expandedIndex == index;
    final sideColor = record.side == 'Kalyan' ? ktPrimary : ktSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isExpanded ? sideColor.withValues(alpha: 0.5) : ktBorderWhite10),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: sideColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(
                record.side.substring(0, 1).toUpperCase(),
                style: TextStyle(color: sideColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              ktFormatDate(ktParseDate(record.date) ?? getIndiaTime()),
              style: const TextStyle(color: ktWhite, fontWeight: FontWeight.bold, fontSize: 10),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${NumberFormat('#,###').format(record.totalPaid)}',
                  style: const TextStyle(color: ktGreen500, fontWeight: FontWeight.w900, fontSize: 10),
                ),
                const SizedBox(width: 4),
                Icon(isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right, color: ktTextGray500, size: 18),
              ],
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(color: ktBorderWhite10, height: 20),
                  _detailRow('Rent Amount', record.rentAmount),
                  _detailRow('Rent Paid', record.paidAmount),
                  _detailRow('Power Bill', record.powerBill),
                  _detailRow('Water Bill', record.waterBill),
                  _detailRow('Adjustment', record.adjustAmount, color: ktEmerald),
                  _detailRow('Balance Deduct', record.balanceAmount, color: ktRose),
                  if (record.remarks.isNotEmpty && record.remarks != '-') ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: ktBgDark, borderRadius: BorderRadius.circular(8)),
                      child: Text(record.remarks, style: const TextStyle(color: ktTextGray500, fontSize: 12, fontStyle: FontStyle.italic)),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _actionBtn(Icons.delete_outline, ktRose, () => _deleteRecord(record)),
                      const SizedBox(width: 12),
                      _actionBtn(Icons.edit_outlined, ktPrimary, () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => RentEntryScreen(editRecord: record))).then((_) => _fetchData());
                      }),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, double value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: ktTextGray500, fontSize: 13)),
          Text('₹${NumberFormat('#,###').format(value)}', style: TextStyle(color: color ?? ktWhite, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(icon == Icons.delete_outline ? 'Delete' : 'Edit', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecord(RentRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ktCardBg,
        title: const Text('Delete Record', style: TextStyle(color: ktWhite)),
        content: const Text('Are you sure you want to delete this record?', style: TextStyle(color: ktTextGray500)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: ktRose))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _loading = true);
      await _service.deleteRecord(record.date, record.side);
      _fetchData();
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: ktTextGray500),
          SizedBox(height: 16),
          Text('No records found', style: TextStyle(color: ktTextGray500)),
        ],
      ),
    );
  }
}
