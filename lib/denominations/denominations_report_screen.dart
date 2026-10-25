import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core_constants.dart';
import '../core_ui_utils.dart';
import '../core_utils.dart';
import 'denominations_service.dart';

class _DenomMonthlySummary {
  final String monthKey;
  final DateTime sortDate;
  double totalOffering = 0;
  double weekExpenses = 0;
  double adjustAmount = 0;
  double atmWithdrawal = 0;
  double acPaid = 0;
  int count = 0;
  final List<Map<String, dynamic>> records = [];

  _DenomMonthlySummary(this.monthKey, this.sortDate);
}

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
  int _reportTab = 0; // 0 = Monthly View, 1 = Overall View
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
      symbol: 'Rs. ',
      decimalDigits: decimals,
    ).format(n);
  }

  List<_DenomMonthlySummary> get _monthlySummaries {
    final map = <String, _DenomMonthlySummary>{};
    for (final row in _rows) {
      final date = ktParseDate(row['Date']);
      final monthKey = date != null ? DateFormat('MMMM yyyy').format(date) : 'Unknown Month';
      final sortDate = date != null ? DateTime(date.year, date.month, 1) : DateTime(2000, 1, 1);
      
      final summary = map.putIfAbsent(monthKey, () => _DenomMonthlySummary(monthKey, sortDate));
      summary.totalOffering += double.tryParse('${row['Total'] ?? 0}') ?? 0;
      summary.weekExpenses += double.tryParse('${row['Week Expenses'] ?? 0}') ?? 0;
      summary.adjustAmount += double.tryParse('${row['Adjust Amount'] ?? 0}') ?? 0;
      summary.atmWithdrawal += double.tryParse('${row['ATM Withdrawal'] ?? 0}') ?? 0;
      summary.acPaid += double.tryParse('${row['A/C Paid'] ?? 0}') ?? 0;
      summary.count++;
      summary.records.add(row);
    }
    final list = map.values.toList();
    list.sort((a, b) => b.sortDate.compareTo(a.sortDate));
    return list;
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
            _buildHeader(),
            const SizedBox(height: 18),
            if (_sheet2Raw != null) ...[
              _buildBalanceCard(),
              const SizedBox(height: 18),
            ],
            _buildReportTabBar(),
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
            else if (_reportTab == 0)
              _buildMonthlyView()
            else if (_reportTab == 1)
              _buildDetailedView()
            else
              _buildListView(),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (_rows.isEmpty) {
      return const Center(child: Text('No records found', style: TextStyle(color: ktTextGray400)));
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final row = _rows[index];
        final dateRaw = row['Date']?.toString() ?? '-';
        final date = ktParseDate(dateRaw);
        final dateLabel = date == null ? dateRaw : ktFormatDate(date);

        final total = _formatCurrency(row['Total']);
        final weekExp = _formatCurrency(row['Week Expenses']);
        final atm = _formatCurrency(row['ATM Withdrawal']);
        final adjust = _formatCurrency(row['Adjust Amount']);
        final acPaid = _formatCurrency(row['A/C Paid']);

        return KtMilkReportCard(
          dateTitle: dateLabel,
          leftTitle: 'Offering',
          leftTitleColor: ktEmerald,
          leftQtyLabel: 'Total',
          leftQtyValue: total,
          leftRateLabel: 'Week Exp',
          leftRateValue: weekExp,
          leftAmtLabel: 'ATM',
          leftAmtValue: atm,
          rightTitle: 'Effective Amounts',
          rightTitleColor: ktAmber,
          rightQtyLabel: 'A/C Paid',
          rightQtyValue: acPaid,
          rightRateLabel: 'Adjust',
          rightRateValue: adjust,
          rightAmtLabel: 'Total',
          rightAmtValue: total,
          onTap: () => _showDetails(row),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Denom's Report", style: TextStyle(color: ktWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                Text("Reports Overview", style: TextStyle(color: ktWhite38, fontSize: 11)),
              ],
            ),
          ),
          ktHeaderIcon(Icons.refresh, _fetch),
          const SizedBox(width: 8),
          ktHeaderIcon(Icons.add, () => Navigator.pushNamed(context, '/denominations').then((_) => _fetch())),
          const SizedBox(width: 8),
          ktHeaderIcon(Icons.home, () => Navigator.popUntil(context, (route) => route.isFirst)),
          const SizedBox(width: 8),
          ktHeaderIcon(Icons.settings, () => Navigator.pushNamed(context, '/settings')),
        ],
      ),
    );
  }

  Widget _buildReportTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ktPanelBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _reportTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _reportTab == 0 ? ktPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Monthly View', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _reportTab = 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _reportTab == 2 ? ktPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('List View', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _reportTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _reportTab == 1 ? ktPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Detailed View', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyView() {
    final summaries = _monthlySummaries;
    if (summaries.isEmpty) {
      return const Center(child: Text('No monthly data', style: TextStyle(color: ktTextGray400)));
    }
    final cards = summaries.asMap().entries.map((e) => _monthlySummaryCard(e.value, e.key)).toList();
    return _buildTwoItemGrid(cards);
  }

  Widget _monthlySummaryCard(_DenomMonthlySummary summary, int index) {
    final isMobile = MediaQuery.of(context).size.width < 650;
    final accentColor = [ktPrimary, ktEmerald, ktAmber, ktBlue, ktViolet, ktRose, ktCyan][index % 7];
    return Container(
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showMonthDetails(summary),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: isMobile ? 8 : 10,
                          height: isMobile ? 20 : 24,
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            summary.monthKey,
                            style: TextStyle(
                              color: ktTextWhite,
                              fontSize: isMobile ? 12 : 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: isMobile ? 3 : 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      isMobile ? '${summary.count}' : '${summary.count} Entries',
                      style: TextStyle(color: accentColor, fontSize: isMobile ? 9 : 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 10 : 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isMobile ? 'TOTAL' : 'TOTAL OFFERINGS', style: TextStyle(color: ktTextGray500, fontSize: isMobile ? 9 : 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatCurrency(summary.totalOffering),
                      style: TextStyle(
                        color: ktEmerald,
                        fontSize: isMobile ? 13 : 18,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 10 : 12),
              const Divider(color: ktBorderWhite10),
              SizedBox(height: isMobile ? 10 : 12),
              Wrap(
                spacing: isMobile ? 6 : 8,
                runSpacing: isMobile ? 6 : 8,
                children: [
                  _summaryMetricChip('Week Exp', _formatCurrency(summary.weekExpenses), ktRose, isMobile),
                  _summaryMetricChip('ATM', _formatCurrency(summary.atmWithdrawal), ktBlue, isMobile),
                  _summaryMetricChip('Adjust', _formatCurrency(summary.adjustAmount), ktAmber, isMobile),
                  _summaryMetricChip('A/C Paid', _formatCurrency(summary.acPaid), ktViolet, isMobile),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryMetricChip(String label, String value, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 10, vertical: isMobile ? 4 : 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: isMobile ? 9 : 10, fontWeight: FontWeight.w700)),
          Text(value, style: TextStyle(color: ktTextWhite, fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final isMobile = MediaQuery.of(context).size.width < 650;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 18, vertical: isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ktPrimary.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          colors: [
            ktPrimary.withValues(alpha: 0.1),
            ktSecondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.account_balance_wallet_rounded, color: ktPrimary, size: 16),
              SizedBox(width: 8),
              Text(
                'Avl Bal: ',
                style: TextStyle(
                  color: ktTextGray400,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                _showBalance ? _formatCurrency(_sheet2Raw) : 'Rs. ••••••',
                style: TextStyle(
                  color: ktEmerald,
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => setState(() => _showBalance = !_showBalance),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ktWhite.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ktPanelBorder),
                  ),
                  child: Icon(
                    _showBalance ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: ktWhite70,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedView() {
    final summaries = _monthlySummaries;
    if (summaries.isEmpty) {
      return const Center(child: Text('No transactions found', style: TextStyle(color: ktTextGray400)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: summaries.map((summary) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 18,
                    decoration: BoxDecoration(
                      color: ktPrimary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    summary.monthKey.toUpperCase(),
                    style: const TextStyle(
                      color: ktWhite,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: ktPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${summary.count}',
                      style: const TextStyle(color: ktPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildGridItems(summary.records),
            const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildGridItems(List<Map<String, dynamic>> items) {
    final cards = items.asMap().entries.map((e) => _reportCard(e.value, e.key)).toList();
    return _buildTwoItemGrid(cards);
  }

  Widget _buildTwoItemGrid(List<Widget> children) {
    final List<Widget> rows = [];
    for (int i = 0; i < children.length; i += 2) {
      final child1 = children[i];
      final child2 = (i + 1 < children.length) ? children[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: child1),
              const SizedBox(width: 14),
              Expanded(
                child: child2 ?? const SizedBox(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _reportCard(Map<String, dynamic> row, int index) {
    final isMobile = MediaQuery.of(context).size.width < 650;
    final dateRaw = row['Date']?.toString() ?? '-';
    final date = ktParseDate(dateRaw);
    final dateLabel = date == null ? dateRaw : ktFormatDate(date);
    
    final total = _formatCurrency(row['Total']);
    
    final colors = [
      {'label': const Color(0xFF60A5FA), 'amount': const Color(0xFF34D399)}, // Blue & Emerald
      {'label': const Color(0xFFFBBF24), 'amount': const Color(0xFFF472B6)}, // Amber & Pink
      {'label': const Color(0xFFA78BFA), 'amount': const Color(0xFF818CF8)}, // Violet & Indigo
      {'label': const Color(0xFFFB7185), 'amount': const Color(0xFF2DD4BF)}, // Rose & Teal
    ];
    final colorPair = colors[index % colors.length];

    return Container(
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ktPanelBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetails(row),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: TextStyle(
                  color: colorPair['label'],
                  fontSize: isMobile ? 11 : 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                total,
                style: TextStyle(
                  color: colorPair['amount'],
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              SizedBox(height: isMobile ? 6 : 8),
              Text(
                isMobile ? 'TOTAL' : 'OFFERINGS',
                style: TextStyle(
                  color: const Color(0xFF7D8799),
                  fontSize: isMobile ? 8 : 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: isMobile ? 0.5 : 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMonthDetails(_DenomMonthlySummary summary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ktSlateBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: ktPrimary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: ktPrimary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(summary.monthKey, style: const TextStyle(color: ktWhite, fontSize: 18, fontWeight: FontWeight.w900)),
                        Text('${summary.count} Records Found', style: const TextStyle(color: ktTextGray400, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: ktWhite38),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ktCardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ktPanelBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL MONTHLY OFFERING', style: TextStyle(color: ktTextGray500, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                      Text(_formatCurrency(summary.totalOffering), style: const TextStyle(color: ktEmerald, fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: ktBorderWhite10),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _summaryMetricChip('Week Exp', _formatCurrency(summary.weekExpenses), ktRose, false),
                      _summaryMetricChip('ATM', _formatCurrency(summary.atmWithdrawal), ktBlue, false),
                      _summaryMetricChip('Adjust', _formatCurrency(summary.adjustAmount), ktAmber, false),
                      _summaryMetricChip('A/C Paid', _formatCurrency(summary.acPaid), ktViolet, false),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'DAILY TRANSACTIONS',
              style: TextStyle(color: ktTextGray400, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: summary.records.length,
                itemBuilder: (context, index) {
                  final row = summary.records[index];
                  final dateRaw = row['Date']?.toString() ?? '';
                  final parsedDate = ktParseDate(dateRaw);
                  final dateLabel = parsedDate != null ? ktFormatDate(parsedDate) : (dateRaw.isNotEmpty ? dateRaw : '-');
                  final totalVal = _formatCurrency(row['Total']);
                  final weekExp = _formatCurrency(row['Week Expenses']);
                  final atm = _formatCurrency(row['ATM Withdrawal']);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: ktCardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: ktPanelBorder),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pop(context);
                        _showDetails(row);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 36,
                              decoration: BoxDecoration(
                                color: [ktPrimary, ktEmerald, ktAmber, ktBlue, ktViolet, ktRose, ktCyan][index % 7],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateLabel,
                                    style: const TextStyle(
                                      color: ktWhite,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text('Exp: $weekExp', style: const TextStyle(color: ktRose, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                                      const SizedBox(width: 10),
                                      Text('ATM: $atm', style: const TextStyle(color: ktBlue, fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  totalVal,
                                  style: const TextStyle(
                                    color: ktEmerald,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'VIEW DETAILS',
                                  style: TextStyle(
                                    color: ktPrimary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> row) {
    final List<Map<String, dynamic>> details = [];

    final date = ktParseDate(row['Date']);
    final dateSubtitle = date == null ? (row['Date']?.toString() ?? '-') : ktFormatDate(date);

    final denoms = ['500', '200', '100', '50', '20', '10', '5', '2', '1'];
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            color: style.$1.withValues(alpha: isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: style.$2.withValues(alpha: isDark ? 0.3 : 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Rs. $d',
                style: TextStyle(
                  color: v > 0 ? (isDark ? style.$3 : style.$2.withRed(100)) : (isDark ? Colors.white38 : Colors.black45),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(width: 1, height: 12, color: isDark ? Colors.white24 : Colors.black12),
              ),
              Text(
                '$v',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
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
    
    details.add({
      'label': 'TOTAL OFFERING',
      'value': _formatCurrency(row['Total']),
      'color': Colors.white,
    });

    details.add({
      'label': 'Closing Balance',
      'value': closingEntry.key.isNotEmpty ? _formatCurrency(closingEntry.value) : _formatCurrency(row['Total']),
      'color': ktTeal500,
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
