import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core_utils.dart';
import '../core_ui_utils.dart';
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
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              mainAxisExtent: 85,
                            ),
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
                  Text(_sideFilter, style: const TextStyle(color: ktAmber500, fontSize: 12, fontWeight: FontWeight.bold)),
                  const Icon(Icons.keyboard_arrow_down, color: ktPink500, size: 14),
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
         /* ktHeaderIcon(
            onPressed: () => Navigator.pushNamed(context, '/rent').then((_) => _fetchData()),
            icon: const Icon(Icons.add_box_outlined, color: ktWhite, size: 22),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
          ),*/
          const SizedBox(width: 8),
          ktHeaderIcon(Icons.add, () => Navigator.pushNamed(context, '/rent')),
          /*IconButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            icon: const Icon(Icons.home_outlined, color: ktWhite, size: 22),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
          ),*/
          const SizedBox(width: 8),
          ktHeaderIcon(Icons.home_rounded, () => Navigator.popUntil(context, (route) => route.isFirst)),
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
            child: _statItem('Total Rent Collected', _totalCollected, ktEmerald),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statItem('Pending Balance', _pendingAmount, ktRose),
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
    final sideColor = record.side == 'Kalyan' ? ktPrimary : ktSecondary;

    return GestureDetector(
      onTap: () => _showRecordDetails(record),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: ktCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ktBorderWhite10),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: sideColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                record.side.substring(0, 1).toUpperCase(),
                style: TextStyle(color: sideColor, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    ktFormatDate(ktParseDate(record.date) ?? getIndiaTime()),
                    style: const TextStyle(color: ktWhite, fontWeight: FontWeight.bold, fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${NumberFormat('#,###').format(record.totalPaid)}',
                    style: const TextStyle(color: ktGreen500, fontWeight: FontWeight.w900, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_right, color: ktTextGray500, size: 14),
          ],
        ),
      ),
    );
  }

  void _showRecordDetails(RentRecord record) {
    final sideColor = record.side == 'Kalyan' ? ktPrimary : ktSecondary;
    final fmt = NumberFormat('#,##,###');

    ktShowDetailsSheet(
      context: context,
      title: 'Rent Details',
      icon: Icons.receipt_long_rounded,
      themeColor: sideColor,
      details: [
        {'label': 'Date', 'value': ktFormatDate(ktParseDate(record.date) ?? getIndiaTime())},
        {'label': 'Side', 'value': record.side},
        {'label': 'Rent Amount', 'value': '₹${fmt.format(record.rentAmount)}'},
        {'label': 'Rent Paid', 'value': '₹${fmt.format(record.paidAmount)}'},
        {'label': 'Power Bill', 'value': '₹${fmt.format(record.powerBill)}', 'color': ktAmber},
        {'label': 'Water Bill', 'value': '₹${fmt.format(record.waterBill)}', 'color': ktBlue},
        {'label': 'Adjustment', 'value': '₹${fmt.format(record.adjustAmount)}', 'color': ktEmerald},
        {'label': 'Balance Deduct', 'value': '₹${fmt.format(record.balanceAmount)}', 'color': ktRose},
        {'label': 'Total Paid', 'value': '₹${fmt.format(record.totalPaid)}', 'color': ktTeal500, 'isHighlight': true},
      ],
      footerNote: (record.remarks.isNotEmpty && record.remarks != '-') ? record.remarks : null,
      actions: [
        ktDeleteButton(
          onPressed: () {
            Navigator.pop(context);
            _deleteRecord(record);
          },
        ),
        const SizedBox(width: 8),
        ktEditButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RentEntryScreen(editRecord: record)),
            ).then((_) => _fetchData());
          },
        ),
      ],
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
