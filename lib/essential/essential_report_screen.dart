import 'package:flutter/material.dart';
import '../core_constants.dart';
import '../core_ui_utils.dart';
import '../core_utils.dart';
import 'essential_entry_screen.dart';
import 'essential_models.dart';
import 'essential_service.dart';

class EssentialReportScreen extends StatefulWidget {
  const EssentialReportScreen({super.key});

  @override
  State<EssentialReportScreen> createState() => _EssentialReportScreenState();
}

class _EssentialReportScreenState extends State<EssentialReportScreen> {
  final EssentialService _service = EssentialService();
  int _currentTab = 0; // 0 = Essential Items, 1 = Cash Gift

  List<EssentialRecord> _allRecords = [];
  List<CashGiftRecord> _allCashGifts = [];
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSortAscending = true; // true = A-Z, false = Z-A

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
    final records = await _service.fetchRecords();
    final cashGifts = await _service.fetchCashGiftRecords();
    if (!mounted) return;
    setState(() {
      _allRecords = records;
      _allCashGifts = cashGifts;
      _isLoading = false;
    });
  }

  String _formatDisplayDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    final parsed = ktParseDate(rawDate);
    if (parsed != null) {
      return ktFormatDate(parsed);
    }
    return rawDate;
  }

  List<EssentialRecord> get _filteredRecords {
    final list = _allRecords.where((rec) {
      final q = _searchQuery.toLowerCase().trim();
      return q.isEmpty ||
          rec.fullName.toLowerCase().contains(q) ||
          rec.date.toLowerCase().contains(q) ||
          rec.totalAmount.toString().contains(q);
    }).toList();

    list.sort((a, b) {
      final cmp = a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
      return _isSortAscending ? cmp : -cmp;
    });

    return list;
  }

  List<CashGiftRecord> get _filteredCashGifts {
    final list = _allCashGifts.where((rec) {
      final q = _searchQuery.toLowerCase().trim();
      return q.isEmpty ||
          rec.name.toLowerCase().contains(q) ||
          rec.date.toLowerCase().contains(q) ||
          rec.modeOfPayment.toLowerCase().contains(q) ||
          rec.status.toLowerCase().contains(q) ||
          rec.amount.toString().contains(q);
    }).toList();

    list.sort((a, b) {
      final cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return _isSortAscending ? cmp : -cmp;
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredRecords = _filteredRecords;
    final filteredCashGifts = _filteredCashGifts;

    final totalDeliveries = _allRecords.length;
    final totalAmountSum = _allRecords.fold<double>(0, (sum, r) => sum + r.totalAmount);
    final totalItemsSum = _allRecords.fold<double>(0, (sum, r) => sum + r.totalQuantity);

    final totalGifts = _allCashGifts.length;
    final totalGiftAmountSum = _allCashGifts.fold<double>(0, (sum, r) => sum + r.amount);

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
                gradient: const LinearGradient(
                  colors: [ktEssentialPrimary, ktEssentialSecondary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.assessment_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentTab == 0 ? KtStrings.essentialReport : 'Cash Gift Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  _currentTab == 0 ? KtStrings.essentialReportSubtitle : 'Cash Gifts Overview',
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
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ktHeaderIcon(
              Icons.home_rounded,
              () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ktHeaderIcon(
              _isSortAscending ? Icons.sort_by_alpha_rounded : Icons.swap_vert_rounded,
              () {
                setState(() {
                  _isSortAscending = !_isSortAscending;
                });
                ktShowCustomToast(
                  context,
                  _isSortAscending ? 'Sorted A - Z' : 'Sorted Z - A',
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ktHeaderIcon(Icons.refresh_rounded, _fetchData),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ktHeaderIcon(
              Icons.add_rounded,
              () => Navigator.pushNamed(context, '/essential').then((_) => _fetchData()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: _buildTabBar(isDark),
            ),

            // KPI Summary Bar
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _currentTab == 0
                  ? _buildKPIBar(
                      deliveries: totalDeliveries,
                      amountSum: totalAmountSum,
                      itemsSum: totalItemsSum,
                      isDark: isDark,
                    )
                  : _buildCashGiftKPIBar(
                      totalGifts: totalGifts,
                      totalAmount: totalGiftAmountSum,
                      isDark: isDark,
                    ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 13),
                decoration: InputDecoration(
                  hintText: _currentTab == 0
                      ? 'Search by Full Name, Date...'
                      : 'Search by Name, Mode, Status...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 12,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: ktEssentialPrimary, size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? ktCardBg : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: ktEssentialPrimary),
                  ),
                ),
              ),
            ),

            // List of Record Cards
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: ktEssentialPrimary),
                    )
                  : _currentTab == 0
                      ? (filteredRecords.isEmpty
                          ? _buildEmptyState(isDark, 'No Essential Deliveries Found')
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                              itemCount: filteredRecords.length,
                              itemBuilder: (context, index) {
                                final rec = filteredRecords[index];
                                return _buildRecordTile(rec, isDark);
                              },
                            ))
                      : (filteredCashGifts.isEmpty
                          ? _buildEmptyState(isDark, 'No Cash Gift Records Found')
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(14, 4, 14, 20),
                              itemCount: filteredCashGifts.length,
                              itemBuilder: (context, index) {
                                final rec = filteredCashGifts[index];
                                return _buildCashGiftTile(rec, isDark);
                              },
                            )),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/essential').then((_) => _fetchData()),
        backgroundColor: ktEssentialPrimary,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
        label: Text(
          _currentTab == 0 ? KtStrings.addEssential : 'Add Cash Gift',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    final tabs = ['Essential Items', 'Cash Gift'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isActive = _currentTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentTab = i;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? ktEssentialPrimary.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isActive
                      ? Border.all(color: ktEssentialPrimary.withValues(alpha: 0.3))
                      : null,
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive
                        ? ktEssentialPrimary
                        : (isDark ? Colors.white60 : Colors.black54),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKPIBar({
    required int deliveries,
    required double amountSum,
    required double itemsSum,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildKPICard('Deliveries', deliveries.toString(), ktEssentialPrimary, isDark),
          _buildKPICard('Total Items', itemsSum.toStringAsFixed(0), ktEssentialSecondary, isDark),
          _buildKPICard('Total Amount', '₹${amountSum.toStringAsFixed(0)}', ktEssentialAccent, isDark),
        ],
      ),
    );
  }

  Widget _buildCashGiftKPIBar({
    required int totalGifts,
    required double totalAmount,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildKPICard('Total Gifts', totalGifts.toString(), ktEssentialPrimary, isDark),
          _buildKPICard('Total Amount', '₹${totalAmount.toStringAsFixed(0)}', ktEssentialAccent, isDark),
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value, Color color, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordTile(EssentialRecord rec, bool isDark) {
    final formattedDate = _formatDisplayDate(rec.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showRecordDetailsBottomSheet(rec, isDark),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ktEssentialPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ktEssentialPrimary.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: ktEssentialPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 12,
                            color: ktEssentialSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rec.fullName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: ktEssentialPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ktEssentialPrimary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '₹${rec.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: ktEssentialPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCashGiftTile(CashGiftRecord rec, bool isDark) {
    final formattedDate = _formatDisplayDate(rec.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCashGiftDetailsBottomSheet(rec, isDark),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: ktEssentialSecondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ktEssentialSecondary.withValues(alpha: 0.2)),
                  ),
                  child: const Icon(
                    Icons.card_giftcard_rounded,
                    color: ktEssentialSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            size: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$formattedDate • ${rec.modeOfPayment}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rec.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: ktEssentialSecondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ktEssentialSecondary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '₹${rec.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: ktEssentialSecondary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      rec.status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: rec.status.toLowerCase() == 'completed' || rec.status.toLowerCase() == 'success'
                            ? ktEssentialPrimary
                            : Colors.orange,
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

  void _showRecordDetailsBottomSheet(EssentialRecord rec, bool isDark) {
    final formattedDate = _formatDisplayDate(rec.date);

    ktShowDetailsSheet(
      context: context,
      title: rec.fullName,
      subtitle: formattedDate,
      icon: Icons.local_shipping_rounded,
      themeColor: ktEssentialPrimary,
      details: [
        {'label': KtStrings.fullNameLabel, 'value': rec.fullName},
        {'label': KtStrings.dateAndDayLabel, 'value': formattedDate},
        {'label': KtStrings.itemDLabel, 'value': rec.itemD.toString()},
        {'label': KtStrings.itemELabel, 'value': rec.itemE.toString()},
        {'label': KtStrings.itemFLabel, 'value': rec.itemF.toString()},
        {'label': KtStrings.itemGLabel, 'value': rec.itemG.toString()},
        {'label': KtStrings.itemHLabel, 'value': rec.itemH.toString()},
        {
          'label': KtStrings.totalAmountLabel,
          'value': '₹${rec.totalAmount.toStringAsFixed(2)}',
          'color': ktEssentialPrimary,
          'isHighlight': true,
        },
      ],
      actions: [
        ktDeleteButton(
          onPressed: () async {
            Navigator.pop(context);
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Record?'),
                content: Text('Are you sure you want to delete delivery record for ${rec.fullName}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete', style: TextStyle(color: ktRose)),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await _service.deleteRecord(rec.sNo);
              if (!mounted) return;
              ktShowCustomToast(context, 'Record deleted');
              _fetchData();
            }
          },
        ),
        ktEditButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EssentialEntryScreen(editRecord: rec),
              ),
            ).then((_) => _fetchData());
          },
          label: KtStrings.edit,
        ),
      ],
    );
  }

  void _showCashGiftDetailsBottomSheet(CashGiftRecord rec, bool isDark) {
    final formattedDate = _formatDisplayDate(rec.date);

    ktShowDetailsSheet(
      context: context,
      title: rec.name,
      subtitle: formattedDate,
      icon: Icons.card_giftcard_rounded,
      themeColor: ktEssentialSecondary,
      details: [
        {'label': 'Name', 'value': rec.name},
        {'label': 'Date', 'value': formattedDate},
        {'label': 'Mode of Payment', 'value': rec.modeOfPayment},
        {'label': 'Status', 'value': rec.status},
        {'label': 'Remarks', 'value': rec.remarks.isNotEmpty ? rec.remarks : '-'},
        {
          'label': 'Amount',
          'value': '₹${rec.amount.toStringAsFixed(2)}',
          'color': ktEssentialSecondary,
          'isHighlight': true,
        },
      ],
      actions: [
        ktDeleteButton(
          onPressed: () async {
            Navigator.pop(context);
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Cash Gift?'),
                content: Text('Are you sure you want to delete cash gift record for ${rec.name}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete', style: TextStyle(color: ktRose)),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await _service.deleteCashGiftRecord(rec.sNo);
              if (!mounted) return;
              ktShowCustomToast(context, 'Record deleted');
              _fetchData();
            }
          },
        ),
        ktEditButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EssentialEntryScreen(editCashGiftRecord: rec),
              ),
            ).then((_) => _fetchData());
          },
          label: KtStrings.edit,
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 56,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to create a new record',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}
