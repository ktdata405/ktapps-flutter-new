import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core_constants.dart';
import '../core_ui_utils.dart';
import '../core_utils.dart';
import 'house_entry_screen.dart';
import 'house_models.dart';
import 'house_service.dart';

class HouseReportScreen extends StatefulWidget {
  const HouseReportScreen({super.key});

  @override
  State<HouseReportScreen> createState() => _HouseReportScreenState();
}

class _HouseReportScreenState extends State<HouseReportScreen> {
  final HouseService _service = HouseService();
  int _currentTab = 0; // 0 = House Bills, 1 = HL-disbursement

  List<HouseBillRecord> _allHouseBills = [];
  List<HlDisbursementRecord> _allHlDisbursements = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSortAscending = true;

  final NumberFormat _currencyFmt = NumberFormat('#,##,###', 'en_IN');

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    final bills = await _service.fetchHouseBills();
    final hl = await _service.fetchHlDisbursements();
    if (!mounted) return;
    setState(() {
      _allHouseBills = bills;
      _allHlDisbursements = hl;
      _isLoading = false;
    });
  }

  String _formatDisplayDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    final parsed = ktParseDate(rawDate);
    if (parsed != null) {
      return ktFormatDate(parsed); // Returns "dd/MMM/yyyy (E)" e.g. "25/Sep/2026 (Fri)"
    }
    return rawDate;
  }

  List<HouseBillRecord> get _filteredBills {
    final list = _allHouseBills.where((rec) {
      final q = _searchQuery.toLowerCase().trim();
      return q.isEmpty ||
          rec.groupName.toLowerCase().contains(q) ||
          rec.date.toLowerCase().contains(q) ||
          rec.amount.toString().contains(q) ||
          rec.contractAmount.toString().contains(q) ||
          rec.balanceAmount.toString().contains(q);
    }).toList();

    list.sort((a, b) {
      final cmp = a.groupName.toLowerCase().compareTo(b.groupName.toLowerCase());
      return _isSortAscending ? cmp : -cmp;
    });

    return list;
  }

  List<HlDisbursementRecord> get _filteredHl {
    final list = _allHlDisbursements.where((rec) {
      final q = _searchQuery.toLowerCase().trim();
      return q.isEmpty ||
          rec.date.toLowerCase().contains(q) ||
          rec.amount.toString().contains(q);
    }).toList();

    list.sort((a, b) {
      final cmp = a.date.compareTo(b.date);
      return _isSortAscending ? cmp : -cmp;
    });

    return list;
  }

  Future<void> _deleteBill(String sNo) async {
    final success = await _service.deleteHouseBill(sNo);
    if (!mounted) return;
    if (success) {
      ktShowCustomToast(context, 'Bill deleted successfully');
      _fetchData();
    } else {
      ktShowCustomToast(context, 'Failed to delete bill');
    }
  }

  Future<void> _deleteHl(String sNo) async {
    final success = await _service.deleteHlDisbursement(sNo);
    if (!mounted) return;
    if (success) {
      ktShowCustomToast(context, 'Disbursement deleted successfully');
      _fetchData();
    } else {
      ktShowCustomToast(context, 'Failed to delete disbursement');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredBills = _filteredBills;
    final filteredHl = _filteredHl;
    final screenWidth = MediaQuery.of(context).size.width;

    // Two items in a row on mobile, 3-4 on web/tablet (as requested: "two items in a row")
    final crossAxisCount = screenWidth > 900 ? 4 : (screenWidth > 600 ? 3 : 2);

    final totalBillsCount = _allHouseBills.length;
    final totalAmountSum = _allHouseBills.fold<double>(0, (sum, r) => sum + r.amount);
    final totalBalanceSum = _allHouseBills.fold<double>(0, (sum, r) => sum + r.balanceAmount);

    final totalHlCount = _allHlDisbursements.length;
    final totalHlAmountSum = _allHlDisbursements.fold<double>(0, (sum, r) => sum + r.amount);

    return Scaffold(
      backgroundColor: isDark ? ktBgDark : ktLightScaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? ktDarkBlueHeader : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_currentTab == 0 ? ktHousePrimary : ktHouseSecondary, ktHousePrimary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_currentTab == 0 ? Icons.assessment_rounded : Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentTab == 0 ? KtStrings.houseConstructionReport : KtStrings.hlDisbursementReport,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  _currentTab == 0 ? KtStrings.houseConstructionReportSubtitle : KtStrings.hlDisbursementSubtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? ktTextGray400 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Home Icon
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ktHeaderIcon(
              Icons.home_rounded,
              () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ),
          // Sort Toggle Button
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ktHeaderIcon(
              _isSortAscending ? Icons.sort_by_alpha_rounded : Icons.swap_vert_rounded,
              () {
                setState(() {
                  _isSortAscending = !_isSortAscending;
                });
                ktShowCustomToast(context, _isSortAscending ? 'Sorted A - Z' : 'Sorted Z - A');
              },
            ),
          ),
          // Refresh Button
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ktHeaderIcon(Icons.refresh_rounded, _fetchData),
          ),
          // Add Button
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ktHeaderIcon(
              Icons.add_rounded,
              () => Navigator.pushNamed(context, '/house').then((_) => _fetchData()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/house').then((_) => _fetchData()),
        backgroundColor: _currentTab == 0 ? ktHousePrimary : ktHouseSecondary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          _currentTab == 0 ? KtStrings.addHouseBill : KtStrings.addHlDisbursement,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab Switcher Bar
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? ktCardBg : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _currentTab == 0 ? ktHousePrimary.withOpacity(isDark ? 0.25 : 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: _currentTab == 0 ? Border.all(color: ktHousePrimary.withOpacity(0.4)) : null,
                        ),
                        child: Center(
                          child: Text(
                            KtStrings.houseConstructionTitle,
                            style: TextStyle(
                              color: _currentTab == 0 ? ktHousePrimary : (isDark ? ktTextGray400 : Colors.black54),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _currentTab == 1 ? ktHouseSecondary.withOpacity(isDark ? 0.25 : 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: _currentTab == 1 ? Border.all(color: ktHouseSecondary.withOpacity(0.4)) : null,
                        ),
                        child: Center(
                          child: Text(
                            KtStrings.hlDisbursementTitle,
                            style: TextStyle(
                              color: _currentTab == 1 ? ktHouseSecondary : (isDark ? ktTextGray400 : Colors.black54),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // KPI Summary Cards Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _currentTab == 0
                  ? Row(
                      children: [
                        Expanded(child: _buildKPICard('Bills', totalBillsCount.toString(), ktHousePrimary, isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildKPICard('Amount', '₹${_currencyFmt.format(totalAmountSum)}', ktHouseSecondary, isDark)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildKPICard('Balance', '₹${_currencyFmt.format(totalBalanceSum)}', ktHouseAccent, isDark)),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildKPICard('Disbursements', totalHlCount.toString(), ktHouseSecondary, isDark)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildKPICard('Total Amount', '₹${_currencyFmt.format(totalHlAmountSum)}', ktHousePrimary, isDark)),
                      ],
                    ),
            ),
            const SizedBox(height: 12),

            // Search Bar with Clear Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 13),
                decoration: InputDecoration(
                  hintText: _currentTab == 0 ? 'Search by group name or amount...' : 'Search by date or amount...',
                  hintStyle: TextStyle(color: isDark ? ktTextGray500 : Colors.black38, fontSize: 12),
                  prefixIcon: Icon(Icons.search_rounded, color: _currentTab == 0 ? ktHousePrimary : ktHouseSecondary, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? ktCardBg : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.08)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _currentTab == 0 ? ktHousePrimary : ktHouseSecondary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Grid View (Two items in a row, inviting style, no left S.No numbers)
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: _currentTab == 0 ? ktHousePrimary : ktHouseSecondary))
                  : (_currentTab == 0
                      ? (filteredBills.isEmpty
                          ? _buildEmptyState(isDark, 'No House Construction Bills Found')
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 90),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.1,
                              ),
                              itemCount: filteredBills.length,
                              itemBuilder: (context, i) => _buildHouseBillCard(filteredBills[i], isDark),
                            ))
                      : (filteredHl.isEmpty
                          ? _buildEmptyState(isDark, 'No HL Disbursements Found')
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 90),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 1.3,
                              ),
                              itemCount: filteredHl.length,
                              itemBuilder: (context, i) => _buildHlCard(filteredHl[i], isDark),
                            ))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: isDark ? ktTextGray400 : Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color, fontFamily: 'monospace'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 56, color: isDark ? ktTextGray500 : Colors.black26),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? ktTextGray400 : Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseBillCard(HouseBillRecord rec, bool isDark) {
    final displayDate = _formatDisplayDate(rec.date);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _showHouseBillDetailsBottomSheet(rec, isDark),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Row: Group Name & Icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        rec.groupName,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ktHousePrimary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.home_work_rounded, color: ktHousePrimary, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Date with Day
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 11, color: ktHousePrimary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        displayDate,
                        style: TextStyle(
                          color: isDark ? ktTextGray400 : Colors.black54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Amounts Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AMOUNT',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isDark ? ktTextGray500 : Colors.black45),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '₹${_currencyFmt.format(rec.amount)}',
                          style: const TextStyle(
                            color: ktHousePrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'BALANCE',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isDark ? ktTextGray500 : Colors.black45),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '₹${_currencyFmt.format(rec.balanceAmount)}',
                          style: const TextStyle(
                            color: ktHouseAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHlCard(HlDisbursementRecord rec, bool isDark) {
    final displayDate = _formatDisplayDate(rec.date);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _showHlDetailsBottomSheet(rec, isDark),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'HL Disbursement',
                        style: TextStyle(
                          color: ktHouseSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: ktHouseSecondary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: ktHouseSecondary, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 11, color: ktHouseSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        displayDate,
                        style: TextStyle(
                          color: isDark ? ktTextGray400 : Colors.black54,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'DISBURSED',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: isDark ? ktTextGray500 : Colors.black45),
                    ),
                    Text(
                      '₹${_currencyFmt.format(rec.amount)}',
                      style: const TextStyle(
                        color: ktHouseSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHouseBillDetailsBottomSheet(HouseBillRecord rec, bool isDark) {
    ktShowDetailsSheet(
      context: context,
      title: rec.groupName,
      subtitle: 'Bill Details • S.No: ${rec.sNo}',
      icon: Icons.home_work_rounded,
      themeColor: ktHousePrimary,
      details: [
        {'label': 'Date & Day', 'value': _formatDisplayDate(rec.date)},
        {'label': 'Group Name', 'value': rec.groupName},
        {'label': 'Amount', 'value': '₹${_currencyFmt.format(rec.amount)}', 'color': ktHousePrimary, 'isHighlight': true},
        {'label': 'Contract Amount', 'value': '₹${_currencyFmt.format(rec.contractAmount)}'},
        {'label': 'Balance Amount', 'value': '₹${_currencyFmt.format(rec.balanceAmount)}', 'color': ktHouseAccent},
      ],
      footerNote: 'Record synchronized with Google Sheets (Splitwise sheet).',
      actions: [
        ktDeleteButton(
          onPressed: () {
            Navigator.pop(context);
            _deleteBill(rec.sNo);
          },
        ),
        ktEditButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HouseEntryScreen(editRecord: rec)),
            ).then((_) => _fetchData());
          },
        ),
      ],
    );
  }

  void _showHlDetailsBottomSheet(HlDisbursementRecord rec, bool isDark) {
    ktShowDetailsSheet(
      context: context,
      title: 'HL Disbursement',
      subtitle: 'Disbursement Details • S.No: ${rec.sNo}',
      icon: Icons.account_balance_wallet_rounded,
      themeColor: ktHouseSecondary,
      details: [
        {'label': 'Date & Day', 'value': _formatDisplayDate(rec.date)},
        {'label': 'Amount', 'value': '₹${_currencyFmt.format(rec.amount)}', 'color': ktHouseSecondary, 'isHighlight': true},
        {'label': 'S.No', 'value': rec.sNo},
      ],
      footerNote: 'Record synchronized with Google Sheets (HL-disbursement sheet).',
      actions: [
        ktDeleteButton(
          onPressed: () {
            Navigator.pop(context);
            _deleteHl(rec.sNo);
          },
        ),
        ktEditButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => HouseEntryScreen(editHlRecord: rec)),
            ).then((_) => _fetchData());
          },
        ),
      ],
    );
  }
}
