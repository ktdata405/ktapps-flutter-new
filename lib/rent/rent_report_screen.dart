import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core_utils.dart';
import '../core_ui_utils.dart';
import 'package:ktppsflutter/core_constants.dart';
import 'rent_models.dart';
import 'rent_service.dart';
import 'rent_entry_screen.dart';


// Keep the report's original dark palette while resolving light-mode contrast.
Color _reportColor(BuildContext context, Color dark, {bool surface = false, bool border = false}) {
  final theme = Theme.of(context);
  if (theme.brightness == Brightness.dark) return dark;
  if (surface) return theme.colorScheme.surfaceContainerLow;
  if (border) return theme.colorScheme.outlineVariant;
  final hsl = HSLColor.fromColor(dark);
  if (hsl.saturation < 0.1) {
    return dark.a < 1 ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface;
  }
  var light = hsl.withAlpha(1);
  final backgroundLuminance = theme.colorScheme.surfaceContainerLow.computeLuminance();
  while (light.lightness > 0.05 &&
      (backgroundLuminance + 0.05) / (light.toColor().computeLuminance() + 0.05) < 4.5) {
    light = light.withLightness((light.lightness - 0.02).clamp(0.0, 1.0));
  }
  return light.toColor();
}

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
  int _reportTab = 0; // 0 = List View, 1 = Detailed View


  Widget _reportHeaderIcon(IconData icon, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? ktPanelBorder : theme.colorScheme.outlineVariant),
        ),
        child: Icon(icon, size: 16, color: isDark ? Colors.white70 : theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? ktBgDark : Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStats(),
            const SizedBox(height: 4),
            _buildReportTabBar(),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchData,
                color: ktPrimary,
                child: _loading && _allRecords.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: ktPrimary))
                    : _filteredRecords.isEmpty
                        ? _buildEmptyState()
                        : (_reportTab == 0 ? _buildListView() : _buildDetailedGridView()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTabBar() {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? ktCardBg : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _reportColor(context, ktPanelBorder, border: true)),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _reportTab = 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _reportTab == 0 ? ktPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('List View', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _reportTab = 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _reportTab == 1 ? ktPrimary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Detailed View', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredRecords.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final record = _filteredRecords[index];
        final dateLabel = ktFormatDate(_parseDate(record.date));
        final sideColor = record.side == 'Kalyan' ? ktPrimary : ktSecondary;

        return _reportRecordCard(context, KtMilkReportCard(
          dateTitle: '$dateLabel (${record.side})',
          leftTitle: 'Rent & Paid',
          leftTitleColor: sideColor,
          leftQtyLabel: 'Rent',
          leftQtyValue: '₹${record.rentAmount.toStringAsFixed(0)}',
          leftRateLabel: 'Paid',
          leftRateValue: '₹${record.paidAmount.toStringAsFixed(0)}',
          leftAmtLabel: 'Total',
          leftAmtValue: '₹${record.totalPaid.toStringAsFixed(0)}',
          rightTitle: 'Bills & Adjust',
          rightTitleColor: ktAmber,
          rightQtyLabel: 'Power',
          rightQtyValue: '₹${record.powerBill.toStringAsFixed(0)}',
          rightRateLabel: 'Water',
          rightRateValue: '₹${record.waterBill.toStringAsFixed(0)}',
          rightAmtLabel: 'Bal/Adj',
          rightAmtValue: '₹${record.balanceAmount.toStringAsFixed(0)}',
          onTap: () => _showRecordDetails(record),
        ));
      },
    );
  }

  Widget _buildDetailedGridView() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: 85,
      ),
      itemCount: _filteredRecords.length,
      itemBuilder: (context, index) => _buildRecordCard(index),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rent Report',
              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
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
                color: isDark ? ktCardBg : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _reportColor(context, ktBorderWhite10, border: true)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_sideFilter, style: TextStyle(color: _reportColor(context, ktAmber500), fontSize: 12, fontWeight: FontWeight.bold)),
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
                .map((e) => PopupMenuItem(value: e, child: Text(e, style: TextStyle(color: textColor, fontSize: 13))))
                .toList(),
            color: isDark ? ktCardBg : Theme.of(context).colorScheme.surface,
          ),
         /* _reportHeaderIcon(
            onPressed: () => Navigator.pushNamed(context, '/rent').then((_) => _fetchData()),
            icon: const Icon(Icons.add_box_outlined, color: ktWhite, size: 22),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
          ),*/
          const SizedBox(width: 8),
          _reportHeaderIcon(Icons.add, () => Navigator.pushNamed(context, '/rent')),
          /*IconButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            icon: const Icon(Icons.home_outlined, color: ktWhite, size: 22),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
          ),*/
          const SizedBox(width: 8),
          _reportHeaderIcon(Icons.home_rounded, () => Navigator.popUntil(context, (route) => route.isFirst)),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _reportColor(context, ktBorderWhite10, border: true)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '₹${NumberFormat('#,##,###').format(value)}',
            style: TextStyle(color: _reportColor(context, color), fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final record = _filteredRecords[index];
    final sideColor = record.side == 'Kalyan' ? ktPrimary : ktSecondary;

    return GestureDetector(
      onTap: () => _showRecordDetails(record),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? ktCardBg : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _reportColor(context, ktBorderWhite10, border: true)),
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
                style: TextStyle(color: _reportColor(context, sideColor), fontSize: 16, fontWeight: FontWeight.bold),
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
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 9),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${NumberFormat('#,###').format(record.totalPaid)}',
                    style: TextStyle(color: _reportColor(context, ktGreen500), fontWeight: FontWeight.w900, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_right, color: _reportColor(context, ktTextGray500), size: 14),
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
        {'label': 'Power Bill', 'value': '₹${fmt.format(record.powerBill)}', 'color': _reportColor(context, ktAmber)},
        {'label': 'Water Bill', 'value': '₹${fmt.format(record.waterBill)}', 'color': _reportColor(context, ktBlue)},
        {'label': 'Adjustment', 'value': '₹${fmt.format(record.adjustAmount)}', 'color': _reportColor(context, ktEmerald)},
        {'label': 'Balance Deduct', 'value': '₹${fmt.format(record.balanceAmount)}', 'color': _reportColor(context, ktRose)},
        {'label': 'Total Paid', 'value': '₹${fmt.format(record.totalPaid)}', 'color': _reportColor(context, ktTeal500), 'isHighlight': true},
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
        backgroundColor: _reportColor(context, ktCardBg, surface: true),
        title: Text('Delete Record', style: TextStyle(color: _reportColor(context, ktWhite))),
        content: Text('Are you sure you want to delete this record?', style: TextStyle(color: _reportColor(context, ktTextGray500))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: _reportColor(context, ktRose)))),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: _reportColor(context, ktTextGray500)),
          SizedBox(height: 16),
          Text('No records found', style: TextStyle(color: _reportColor(context, ktTextGray500))),
        ],
      ),
    );
  }
}

Widget _reportRecordCard(BuildContext context, KtMilkReportCard card) {
  final theme = Theme.of(context);
  if (theme.brightness == Brightness.dark) return card;
  final colors = theme.colorScheme;
  Widget section(String title, Color color, String quantity, String rate, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(title, textAlign: TextAlign.center, style: TextStyle(color: _reportColor(context, color), fontSize: 11, fontWeight: FontWeight.w800)),
        ),
        Divider(height: 1, color: colors.outlineVariant),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Text(quantity, style: TextStyle(color: colors.onSurface, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        Divider(height: 1, color: colors.outlineVariant),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(children: [
            Expanded(child: Text(rate, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 9, fontWeight: FontWeight.w700))),
            Expanded(child: Text(amount, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: _reportColor(context, ktEmerald), fontSize: 10, fontWeight: FontWeight.w800))),
          ]),
        ),
      ],
    );
  }
  return GestureDetector(
    onTap: card.onTap,
    child: Container(
      decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: colors.surfaceContainerHighest,
          child: Text('Date: ${card.dateTitle}', textAlign: TextAlign.center, style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
        ),
        IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: section(card.leftTitle, card.leftTitleColor, '${card.leftQtyLabel} : ${card.leftQtyValue}', '${card.leftRateLabel} : ${card.leftRateValue}', '${card.leftAmtLabel} : ${card.leftAmtValue}')),
          VerticalDivider(width: 1, thickness: 1, color: colors.outlineVariant),
          Expanded(child: card.rightTitle == null
              ? Center(child: Text('—', style: TextStyle(color: colors.onSurfaceVariant)))
              : section(card.rightTitle!, card.rightTitleColor ?? ktCyan, '${card.rightQtyLabel ?? ''} : ${card.rightQtyValue ?? ''}', '${card.rightRateLabel ?? ''} : ${card.rightRateValue ?? ''}', '${card.rightAmtLabel ?? ''} : ${card.rightAmtValue ?? ''}')),
        ])),
      ]),
    ),
  );
}
