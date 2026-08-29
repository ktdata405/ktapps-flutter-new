import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String _yearFilter = 'This Year';
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
        return DateTime(0);
      }
    }
  }

  double get _totalRent => _filteredRecords.fold(0, (sum, item) => sum + item.rentAmount);
  double get _totalCollected => _filteredRecords.fold(0, (sum, item) => sum + item.totalPaid);
  double get _pendingAmount => _filteredRecords.fold(0, (sum, item) => sum + item.balanceAmount);
  double get _collectionRate => _totalRent > 0 ? (_totalCollected / _totalRent) * 100 : 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;

    return Scaffold(
      backgroundColor: const Color(0xFF030305),
      body: Stack(
        children: [
          const _GridBackground(),
          const _BackgroundOrbs(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDesktop),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchData,
                    color: ktPrimary,
                    backgroundColor: const Color(0xFF1E1B4B),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? width * 0.05 : 16),
                      child: Column(
                        children: [
                          _buildKPIGrid(isDesktop),
                          const SizedBox(height: 24),
                          if (_loading && _allRecords.isEmpty)
                            _buildSkeletons()
                          else if (_filteredRecords.isEmpty && !_loading)
                            _buildEmptyState()
                          else
                            _buildList(isDesktop),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          if (isDesktop) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.description_outlined, color: Color(0xFF8B5CF6)),
            ),
            const SizedBox(width: 16),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tenant Report',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                'Track rent collections and payment history',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          if (isDesktop) ...[
            _buildDropdownFilter(_sideFilter, ['All', 'Kalyan', 'Srikanth'], (v) {
              setState(() { _sideFilter = v; _applyFilter(); });
            }, displayMap: {'All': 'All Sides'}),
            const SizedBox(width: 12),
            _buildDropdownFilter(_yearFilter, ['This Year', 'Last Year', 'Overall'], (v) {
              setState(() => _yearFilter = v);
            }),
            const SizedBox(width: 12),
            _buildHeaderAction(Icons.refresh, _fetchData),
            const SizedBox(width: 12),
            _buildHeaderAction(Icons.add, () => Navigator.pushNamed(context, '/rent').then((_) => _fetchData())),
            const SizedBox(width: 12),
            _buildHeaderAction(Icons.home, () => Navigator.popUntil(context, (route) => route.isFirst)),
            const SizedBox(width: 12),
            _buildHeaderAction(Icons.settings, () => Navigator.pushNamed(context, '/settings')),
            const SizedBox(width: 12),
            _buildExportButton(),
          ] else ...[
            _buildHeaderAction(Icons.refresh, _fetchData),
            const SizedBox(width: 8),
            _buildHeaderAction(Icons.add, () => Navigator.pushNamed(context, '/rent').then((_) => _fetchData())),
            const SizedBox(width: 8),
            _buildHeaderAction(Icons.home, () => Navigator.popUntil(context, (route) => route.isFirst)),
            const SizedBox(width: 8),
            _buildExportButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(String value, List<String> options, ValueChanged<String> onChanged, {Map<String, String>? displayMap}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1E1B4B),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 16),
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          items: options.map((e) => DropdownMenuItem(value: e, child: Text(displayMap?[e] ?? e))).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: ktTextGray400, size: 20),
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      decoration: BoxDecoration(
        color: ktPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.file_upload_outlined, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Export', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKPIGrid(bool isDesktop) {
    return LayoutBuilder(builder: (context, constraints) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isDesktop ? 4 : 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: isDesktop ? 2.5 : 1.0,
        children: [
          _KPIItem(
            icon: Icons.description_outlined,
            title: 'Total Rent',
            value: NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0).format(_totalRent),
            subtitle: 'Expected',
            color: ktPrimary,
          ),
          _KPIItem(
            icon: Icons.person_outline,
            title: 'Total Collected',
            value: NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0).format(_totalCollected),
            subtitle: 'Collected',
            color: ktEmerald,
          ),
          _KPIItem(
            icon: Icons.donut_large_outlined,
            title: 'Collection Rate',
            value: '${_collectionRate.toStringAsFixed(2)}%',
            subtitle: 'vs Expected',
            color: const Color(0xFF3B82F6),
          ),
          _KPIItem(
            icon: Icons.pending_actions_outlined,
            title: 'Pending Amount',
            value: NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0).format(_pendingAmount),
            subtitle: 'Remaining',
            color: const Color(0xFFF97316),
          ),
        ],
      );
    });
  }

  Widget _buildList(bool isDesktop) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredRecords.length,
      itemBuilder: (context, index) {
        final record = _filteredRecords[index];
        return _RentReportCard(
          record: record,
          isExpanded: _expandedIndex == index,
          isDesktop: isDesktop,
          onToggle: () => setState(() => _expandedIndex = _expandedIndex == index ? null : index),
          onDelete: () => _deleteRecord(record),
          onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RentEntryScreen(editRecord: record))).then((_) => _fetchData()),
        );
      },
    );
  }

  Future<void> _deleteRecord(RentRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1B4B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          title: const Text('Delete Record', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to delete this record? This cannot be undone.', style: TextStyle(color: ktTextGray400)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: ktTextGray400))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFB7185).withValues(alpha: 0.2), foregroundColor: const Color(0xFFFB7185), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFFB7185)))),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      final success = await _service.deleteRecord(record.date, record.side);
      if (success) {
        _fetchData();
      } else {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildEmptyState() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 50),
        Icon(Icons.assignment_late_outlined, size: 64, color: Color(0xFF334155)),
        SizedBox(height: 16),
        Text('No records found', style: TextStyle(color: ktTextGray400, fontSize: 18)),
      ],
    );
  }

  Widget _buildSkeletons() {
    return Column(children: List.generate(5, (index) => const _SkeletonCard()));
  }
}

class _KPIItem extends StatelessWidget {
  final IconData icon;
  final String title, value, subtitle;
  final Color color;
  const _KPIItem({required this.icon, required this.title, required this.value, required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151A25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RentReportCard extends StatelessWidget {
  final RentRecord record;
  final bool isExpanded, isDesktop;
  final VoidCallback onToggle, onDelete, onEdit;

  const _RentReportCard({required this.record, required this.isExpanded, required this.isDesktop, required this.onToggle, required this.onDelete, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final accentColor = record.side == 'Kalyan' ? ktPrimary : const Color(0xFFEC4899);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151A25),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text(record.side.substring(0, 1), style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Text(record.date, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text(record.side, style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        Text(
                          NumberFormat.currency(symbol: '₹', locale: 'en_IN', decimalDigits: 0).format(record.totalPaid),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _ActionButton(icon: Icons.edit_note_outlined, color: Colors.white.withValues(alpha: 0.6), onTap: onEdit),
                  const SizedBox(width: 8),
                  _ActionButton(icon: Icons.delete_outline, color: Colors.white.withValues(alpha: 0.6), onTap: onDelete),
                  const SizedBox(width: 8),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.white.withValues(alpha: 0.3), size: 20),
                ],
              ),
            ),
          ),
          if (isExpanded) _buildExpandedView(),
        ],
      ),
    );
  }

  Widget _buildExpandedView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          Divider(color: Colors.white.withValues(alpha: 0.05), height: 32),
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildPaymentSummary()),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: _buildCollectionOverview()),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: _buildPaymentRecords()),
              ],
            )
          else
            Column(
              children: [
                _buildPaymentSummary(),
                const SizedBox(height: 24),
                _buildCollectionOverview(),
                const SizedBox(height: 24),
                _buildPaymentRecords(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary() {
    return _SectionContainer(
      icon: Icons.description_outlined,
      title: 'Payment Summary',
      child: Column(
        children: [
          _SummaryRow(label: 'Rent Amount', value: '₹ ${NumberFormat('#,##,###').format(record.rentAmount)}'),
          _SummaryRow(label: 'Rent Paid', value: '₹ ${NumberFormat('#,##,###').format(record.paidAmount)}'),
          _SummaryRow(label: 'Power Bill', value: '₹ ${NumberFormat('#,##,###').format(record.powerBill)}'),
          _SummaryRow(label: 'Water Bill', value: '₹ ${NumberFormat('#,##,###').format(record.waterBill)}'),
          _SummaryRow(label: 'Adjustments', value: '₹ ${NumberFormat('#,##,###').format(record.adjustAmount)}', valueColor: ktEmerald),
          _SummaryRow(label: 'Balance Deducted', value: '₹ ${NumberFormat('#,##,###').format(record.balanceAmount)}', valueColor: const Color(0xFFFB7185)),
          _SummaryRow(label: 'Total Paid', value: '₹ ${NumberFormat('#,##,###').format(record.totalPaid)}', isHighlighted: true, valueColor: ktEmerald),
          _SummaryRow(label: 'Remarks', value: record.remarks.isEmpty ? '-' : record.remarks, isLast: true),
        ],
      ),
    );
  }

  Widget _buildCollectionOverview() {
    return _SectionContainer(
      icon: Icons.bar_chart_outlined,
      title: 'Collection Overview',
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _Legend(label: 'Expected', color: ktPrimary),
              SizedBox(width: 12),
              _Legend(label: 'Collected', color: ktEmerald),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(12, (i) => _BarColumn(
                month: ktMonths[i],
                expectedHeight: 40 + (i * 10.0 % 100),
                collectedHeight: 30 + (i * 12.0 % 90),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRecords() {
    return _SectionContainer(
      icon: Icons.list_alt_outlined,
      title: 'Payment Records',
      headerTrailing: const Text('View All', style: TextStyle(color: ktPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
      child: Column(
        children: [
          _PaymentRecordRow(date: record.date, rent: record.rentAmount, paid: record.totalPaid),
          _PaymentRecordRow(date: '01 May 2026', rent: 5500, paid: 5500),
          _PaymentRecordRow(date: '15 Apr 2026', rent: 5500, paid: 5630, isLast: true),
        ],
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? headerTrailing;
  const _SectionContainer({required this.icon, required this.title, required this.child, this.headerTrailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: ktPrimary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: ktPrimary, size: 16)),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              if (headerTrailing != null) ...[const Spacer(), headerTrailing!],
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool isHighlighted, isLast;
  final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, this.isHighlighted = false, this.isLast = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: isHighlighted ? 14 : 13)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: isHighlighted ? 16 : 14,
                    fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.05), height: 1),
          ],
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final Color color;
  const _Legend({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6), Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11))]);
  }
}

class _BarColumn extends StatelessWidget {
  final String month;
  final double expectedHeight, collectedHeight;
  const _BarColumn({required this.month, required this.expectedHeight, required this.collectedHeight});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(width: 8, height: expectedHeight, decoration: BoxDecoration(color: ktPrimary, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 4),
            Container(width: 8, height: collectedHeight, decoration: BoxDecoration(color: ktEmerald, borderRadius: BorderRadius.circular(4))),
          ],
        ),
        const SizedBox(height: 8),
        Text(month, style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10)),
      ],
    );
  }
}

class _PaymentRecordRow extends StatelessWidget {
  final String date;
  final double rent, paid;
  final bool isLast;
  const _PaymentRecordRow({required this.date, required this.rent, required this.paid, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        children: [
          Row(
            children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.05))), child: const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 14)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(date, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('Rent ₹ ${NumberFormat('#,###').format(rent)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Paid ₹ ${NumberFormat('#,###').format(paid)}', style: const TextStyle(color: ktEmerald, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: ktEmerald.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Row(children: [Icon(Icons.check_circle, color: ktEmerald, size: 10), SizedBox(width: 4), Text('Paid', style: TextStyle(color: ktEmerald, fontSize: 9, fontWeight: FontWeight.bold))]),
                  ),
                ],
              ),
            ],
          ),
          if (!isLast) const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon; final Color color; final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.05))), child: Icon(icon, color: color, size: 18)));
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.infinite, painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.015)..strokeWidth = 1.0;
    const step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BackgroundOrbs extends StatelessWidget {
  const _BackgroundOrbs();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: -100, left: -100, child: Container(width: 400, height: 400, decoration: BoxDecoration(color: ktPrimary.withValues(alpha: 0.05), shape: BoxShape.circle), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)))),
        Positioned(bottom: -50, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(color: const Color(0xFFEC4899).withValues(alpha: 0.05), shape: BoxShape.circle), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)))),
      ],
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), height: 80,
      decoration: BoxDecoration(color: const Color(0xFF151A25), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
    );
  }
}
