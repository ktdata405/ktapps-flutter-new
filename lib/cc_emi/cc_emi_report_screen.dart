import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core_constants.dart';
import '../core_ui_utils.dart';
import '../core_utils.dart';
import '../main.dart' show AmbientBackground;
import 'cc_emi_models.dart';
import '../emi/emi_screen.dart';
import '../emi/emi_payment_history_pdf.dart';
import '../emi/emi_ui.dart';
import 'cc_emi_service.dart';

class CcEmiReportScreen extends StatefulWidget {
  const CcEmiReportScreen({super.key, this.embedded = false, this.service});
  final bool embedded;
  final CcEmiService? service;

  @override
  State<CcEmiReportScreen> createState() => CcEmiReportScreenState();
}

class CcEmiReportScreenState extends State<CcEmiReportScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late final CcEmiService _service;
  Future<void> refreshRecords() => _loading ? Future.value() : _loadRecords();

  List<CreditCardEmiRecord> _allRecords = [];
  bool _loading = true;
  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Active', 'Completed'
  String _selectedBankFilter = 'All';

  Future<DateTime?> _selectMonthYear({
    required BuildContext context,
    required DateTime date,
    required bool isDark,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    var selectedMonth = date.month;
    var selectedYear = date.year.clamp(firstDate.year, lastDate.year).toInt();
    return showDialog<DateTime>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor:
                      isDark ? const Color(0xFF0F172A) : Colors.white,
                  title: Text(
                    'Select month and year',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  content: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<int>(
                          value: selectedMonth,
                          decoration: const InputDecoration(labelText: 'Month'),
                          items: List.generate(
                            12,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              enabled:
                                  !((selectedYear == firstDate.year &&
                                          i + 1 < firstDate.month) ||
                                      (selectedYear == lastDate.year &&
                                          i + 1 > lastDate.month)),
                              child: Text(
                                DateFormat(
                                  'MMMM',
                                ).format(DateTime(2000, i + 1)),
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            if (value != null)
                              setDialogState(() => selectedMonth = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<int>(
                          value: selectedYear,
                          decoration: const InputDecoration(labelText: 'Year'),
                          items: [
                            for (
                              var year = firstDate.year;
                              year <= lastDate.year;
                              year++
                            )
                              DropdownMenuItem(
                                value: year,
                                child: Text('$year'),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedYear = value;
                                if (selectedYear == firstDate.year &&
                                    selectedMonth < firstDate.month)
                                  selectedMonth = firstDate.month;
                                if (selectedYear == lastDate.year &&
                                    selectedMonth > lastDate.month)
                                  selectedMonth = lastDate.month;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final maxDay =
                            DateTime(selectedYear, selectedMonth + 1, 0).day;
                        final day = date.day.clamp(1, maxDay).toInt();
                        Navigator.pop(
                          dialogContext,
                          DateTime(selectedYear, selectedMonth, day),
                        );
                      },
                      child: const Text('Select'),
                    ),
                  ],
                ),
          ),
    );
  }

  int _inclusiveMonthCount(DateTime from, DateTime to) =>
      to.isBefore(DateTime(from.year, from.month))
          ? 0
          : (to.year - from.year) * 12 + to.month - from.month + 1;

  Widget _buildPaymentModeTabs({
    required bool isDark,
    required bool bulkPay,
    required ValueChanged<bool> onChanged,
  }) {
    Widget tab(String title, IconData icon, bool selected, bool bulk) {
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onChanged(bulk),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color:
                  selected
                      ? ktCcEmiPrimary
                      : (isDark ? ktCardBg : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    selected
                        ? ktCcEmiPrimary
                        : (isDark ? ktBorderWhite10 : Colors.black12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 17,
                  color:
                      selected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black54),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          selected
                              ? Colors.white
                              : (isDark ? Colors.white70 : Colors.black87),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tab('Single EMI Pay', Icons.payment_rounded, !bulkPay, false),
        const SizedBox(width: 10),
        tab('Bulk EMI Pay', Icons.library_add_check_rounded, bulkPay, true),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CcEmiService();
    _loadRecords();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    final list = await _service.fetchRecords();
    if (!mounted) return;
    setState(() {
      _allRecords = list;
      _loading = false;
    });
  }

  List<CreditCardEmiRecord> get _filteredRecords {
    return _allRecords.where((record) {
      // Status filter
      if (_statusFilter == 'Active' && record.isCompleted) return false;
      if (_statusFilter == 'Completed' && !record.isCompleted) return false;

      // Bank filter
      if (_selectedBankFilter != 'All' &&
          !record.cardName.toLowerCase().contains(
            _selectedBankFilter.toLowerCase(),
          )) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchCard = record.cardName.toLowerCase().contains(q);
        final matchMerchant = record.merchantName.toLowerCase().contains(q);
        final matchCat = record.category.toLowerCase().contains(q);
        final matchParty = record.partyName.toLowerCase().contains(q);
        final matchLoanAccount = record.loanAccountNumber
            .toLowerCase()
            .contains(q);
        if (!matchCard &&
            !matchMerchant &&
            !matchCat &&
            !matchParty &&
            !matchLoanAccount) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  double get _totalOutstanding {
    return _allRecords
        .where((r) => !r.isCompleted)
        .fold(0.0, (sum, r) => sum + r.remainingPayable);
  }

  double get _monthlyCommitment {
    return _allRecords
        .where((r) => !r.isCompleted)
        .fold(0.0, (sum, r) => sum + r.monthlyEmi);
  }

  double get _totalInterest {
    return _allRecords.fold(0.0, (sum, r) => sum + r.totalInterest);
  }

  double get _totalPaidAmount {
    return _allRecords.fold(0.0, (sum, r) => sum + r.paidAmount);
  }

  double get _totalPayableAmount {
    return _allRecords.fold(0.0, (sum, r) => sum + r.totalPayable);
  }

  List<CreditCardEmiRecord> get _partyRecords =>
      _allRecords.where((record) => record.partyName.isNotEmpty).toList();

  double get _partyPaidTotal =>
      _partyRecords.fold(0.0, (sum, record) => sum + record.partyPaid);

  double get _partyGainLossTotal =>
      _partyRecords.fold(0.0, (sum, record) => sum + record.partyGainLoss);

  int get _activeCount => _allRecords.where((r) => !r.isCompleted).length;

  List<String> get _availableBankNames {
    final banks = _allRecords.map((r) => r.cardName).toSet().toList();
    banks.sort();
    return ['All', ...banks];
  }

  String _fmt(double amount) {
    return NumberFormat('#,##,###', 'en_IN').format(amount);
  }

  Future<void> _deleteRecord(CreditCardEmiRecord record) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            title: Text(
              KtStrings.deleteCcEmi,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              KtStrings.confirmDeleteCcEmi,
              style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  KtStrings.cancel,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: ktRose),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  KtStrings.delete,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true && record.id != null) {
      final ok = await _service.deleteRecord(record.id!);
      if (!mounted) return;
      if (ok) {
        ktShowCustomToast(context, KtStrings.ccEmiRecordDeleted);
        _loadRecords();
      } else {
        ktShowCustomToast(context, KtStrings.fetchFailed);
      }
    }
  }

  void _showRecordPaymentDialog(CreditCardEmiRecord record) {
    if (record.id == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nextEmiNum = record.emisPaid + 1;
    final defaultAmount = record.monthlyEmiWithGst;

    final TextEditingController amountCtrl = TextEditingController(
      text: defaultAmount.toStringAsFixed(2),
    );
    final TextEditingController remarksCtrl = TextEditingController();
    String paymentMode = 'Auto Debit';
    DateTime fromDate = getIndiaTime();
    DateTime toDate = getIndiaTime();
    bool bulkPay = false;
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (dialogCtx, setModalState) => Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    20,
                    24,
                    24 + MediaQuery.of(dialogCtx).viewInsets.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white24 : Colors.black12,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: ktCcEmiPrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.payment_rounded,
                                color: ktCcEmiPrimary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    KtStrings.recordEmiPaymentTitle,
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? Colors.white
                                              : Colors.black87,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    '${record.cardName} • EMI #$nextEmiNum / ${record.tenureMonths}',
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? Colors.white54
                                              : Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildPaymentModeTabs(
                          isDark: isDark,
                          bulkPay: bulkPay,
                          onChanged:
                              (value) => setModalState(() => bulkPay = value),
                        ),
                        Text(
                          bulkPay ? 'Payment month range' : 'Payment date',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      isDark ? Colors.white : Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () async {
                                  final picked =
                                      bulkPay
                                          ? await _selectMonthYear(
                                            context: dialogCtx,
                                            date: fromDate,
                                            isDark: isDark,
                                            firstDate: DateTime(2000),
                                            lastDate: getIndiaTime(),
                                          )
                                          : await showDatePicker(
                                            context: dialogCtx,
                                            initialDate: fromDate,
                                            firstDate: DateTime(2000),
                                            lastDate: getIndiaTime(),
                                          );
                                  if (picked != null)
                                    setModalState(() {
                                      fromDate = picked;
                                      if (DateTime(
                                        toDate.year,
                                        toDate.month,
                                      ).isBefore(
                                        DateTime(fromDate.year, fromDate.month),
                                      ))
                                        toDate = fromDate;
                                    });
                                },
                                icon: const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 15,
                                  color: ktCcEmiPrimary,
                                ),
                                label: Text(
                                  '${bulkPay ? 'From' : 'Payment date'}: ${bulkPay ? DateFormat('MMM yyyy').format(fromDate) : ktFormatDate(fromDate)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            if (bulkPay) const SizedBox(width: 10),
                            if (bulkPay)
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        isDark ? Colors.white : Colors.black87,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 12,
                                    ),
                                  ),
                                  onPressed: () async {
                                    final picked = await _selectMonthYear(
                                      context: dialogCtx,
                                      date: toDate,
                                      isDark: isDark,
                                      firstDate: fromDate,
                                      lastDate: getIndiaTime(),
                                    );
                                    if (picked != null)
                                      setModalState(() => toDate = picked);
                                  },
                                  icon: const Icon(
                                    Icons.event_rounded,
                                    size: 15,
                                    color: ktCcEmiPrimary,
                                  ),
                                  label: Text(
                                    'To: ${DateFormat('MMM yyyy').format(toDate)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Payment Amount
                        Text(
                          'Amount per EMI (defaults to the scheduled EMI)',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: amountCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setModalState(() {}),
                          style: TextStyle(
                            color: ktEmerald,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.currency_rupee_rounded,
                              color: ktCcEmiPrimary,
                            ),
                            filled: true,
                            fillColor: isDark ? ktCardBg : Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    isDark ? ktBorderWhite10 : Colors.black12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: ktEmerald.withValues(
                              alpha: isDark ? 0.16 : 0.09,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                bulkPay
                                    ? '${_inclusiveMonthCount(fromDate, toDate)} months selected = ${_inclusiveMonthCount(fromDate, toDate)} EMIs'
                                    : 'Single EMI payment',
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '₹${_fmt((double.tryParse(amountCtrl.text) ?? defaultAmount) * (bulkPay ? _inclusiveMonthCount(fromDate, toDate) : 1))}',
                                style: const TextStyle(
                                  color: ktEmerald,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Payment Mode
                        Text(
                          KtStrings.paymentModeLabel,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: paymentMode,
                          dropdownColor: isDark ? ktSlate800 : Colors.white,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w800,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? ktCardBg : Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    isDark ? ktBorderWhite10 : Colors.black12,
                              ),
                            ),
                          ),
                          items:
                              [
                                    'Auto Debit',
                                    'Credit Card Bill',
                                    'Net Banking',
                                    'UPI',
                                    'Other',
                                  ]
                                  .map(
                                    (mode) => DropdownMenuItem(
                                      value: mode,
                                      child: Text(mode),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (val) {
                            if (val != null)
                              setModalState(() => paymentMode = val);
                          },
                        ),
                        const SizedBox(height: 24),

                        // Confirm Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ktCcEmiPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed:
                                saving
                                    ? null
                                    : () async {
                                      final enteredAmount = double.tryParse(
                                        amountCtrl.text.trim(),
                                      );
                                      final amtPaid =
                                          enteredAmount != null &&
                                                  enteredAmount > 0
                                              ? enteredAmount
                                              : defaultAmount;
                                      final count =
                                          bulkPay
                                              ? _inclusiveMonthCount(
                                                fromDate,
                                                toDate,
                                              )
                                              : 1;
                                      if (count < 1 ||
                                          count > record.remainingEmis ||
                                          (bulkPay &&
                                              DateTime(
                                                toDate.year,
                                                toDate.month,
                                              ).isAfter(
                                                DateTime(
                                                  getIndiaTime().year,
                                                  getIndiaTime().month,
                                                ),
                                              ))) {
                                        ktShowCustomToast(
                                          context,
                                          'Enter a valid EMI count',
                                        );
                                        return;
                                      }
                                      final lastMonth = DateTime(
                                        fromDate.year,
                                        fromDate.month + count - 1,
                                        1,
                                      );
                                      final scheduledDay =
                                          bulkPay
                                              ? record.dueDay
                                              : fromDate.day;
                                      final lastPaymentDate = DateTime(
                                        lastMonth.year,
                                        lastMonth.month,
                                        scheduledDay.clamp(
                                          1,
                                          DateTime(
                                            lastMonth.year,
                                            lastMonth.month + 1,
                                            0,
                                          ).day,
                                        ),
                                      );
                                      if (fromDate.isAfter(getIndiaTime()) ||
                                          (bulkPay &&
                                              _inclusiveMonthCount(
                                                    fromDate,
                                                    toDate,
                                                  ) <
                                                  1) ||
                                          lastPaymentDate.isAfter(
                                            getIndiaTime(),
                                          )) {
                                        ktShowCustomToast(
                                          context,
                                          'Choose a date range covering all installments up to today',
                                        );
                                        return;
                                      }
                                      setModalState(() => saving = true);
                                      final nav = Navigator.of(dialogCtx);
                                      var saved = 0;
                                      for (var i = 0; i < count; i++) {
                                        final month = fromDate.month + i;
                                        final targetMonth = DateTime(
                                          fromDate.year,
                                          month,
                                          1,
                                        );
                                        final date = DateTime(
                                          targetMonth.year,
                                          targetMonth.month,
                                          scheduledDay.clamp(
                                            1,
                                            DateTime(
                                              targetMonth.year,
                                              targetMonth.month + 1,
                                              0,
                                            ).day,
                                          ),
                                        );
                                        final payRecord = EmiPaymentRecord(
                                          id:
                                              '${DateTime.now().millisecondsSinceEpoch}-$i',
                                          emiRecordId: record.id!,
                                          emiNumber: nextEmiNum + i,
                                          paymentDate: ktFormatDate(date),
                                          amountPaid: amtPaid,
                                          paymentMode: paymentMode,
                                          remarks: remarksCtrl.text.trim(),
                                        );
                                        if (!await _service.recordPayment(
                                          record.id!,
                                          payRecord,
                                        ))
                                          break;
                                        saved++;
                                      }
                                      if (!mounted) return;
                                      nav.pop();

                                      if (saved == count) {
                                        ktShowCustomToast(
                                          context,
                                          KtStrings.emiPaymentRecorded,
                                        );
                                        _loadRecords();
                                      } else if (saved > 0) {
                                        ktShowCustomToast(
                                          context,
                                          '$saved of $count EMI payments recorded',
                                        );
                                        _loadRecords();
                                      } else {
                                        ktShowCustomToast(
                                          context,
                                          KtStrings.saveFailed,
                                        );
                                      }
                                    },
                            child:
                                saving
                                    ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(
                                      bulkPay
                                          ? 'Record bulk payments'
                                          : 'Record EMI payment',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
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

  void _showRecordDetails(CreditCardEmiRecord record) {
    ktShowDetailsSheet(
      context: context,
      title: record.cardName,
      subtitle: '${record.merchantName} • ${record.category}',
      icon: Icons.credit_card_rounded,
      themeColor: ktCcEmiPrimary,
      details: [
        {
          'label': KtStrings.purchaseAmountLabel,
          'value': '₹${_fmt(record.totalAmount)}',
          'isHighlight': true,
          'color': ktRose,
        },
        {'label': KtStrings.purchaseDateLabel, 'value': record.purchaseDate},
        if (record.loanAccountNumber.isNotEmpty)
          {
            'label': 'Bajaj EMI Loan / Account Number',
            'value': record.loanAccountNumber,
          },
        {
          'label':
              record.isBajajEmi ? 'Monthly EMI' : 'Monthly EMI (Incl. 18% GST)',
          'value': '₹${_fmt(record.monthlyEmiWithGst)}',
          'color': ktRose,
        },
        {
          'label': KtStrings.interestRateLabel,
          'value':
              record.interestRate == 0
                  ? '0% (No Cost)'
                  : '${record.interestRate}% p.a.',
        },
        {
          'label': KtStrings.totalInterestLabel,
          'value': '₹${_fmt(record.totalInterest)}',
          'color': ktRose,
        },
        if (!record.isBajajEmi)
          {
            'label': 'GST on Interest (18%)',
            'value': '₹${_fmt(record.gstOnInterest)}',
            'color': ktRose,
          },
        {
          'label': 'Processing Fee',
          'value': '₹${_fmt(record.processingFee)}',
          'color': ktRose,
        },
        if (!record.isBajajEmi)
          {
            'label': 'GST on Proc. Fee (18%)',
            'value': '₹${_fmt(record.gstOnProcessingFee)}',
            'color': ktRose,
          },
        if (!record.isBajajEmi)
          {
            'label': 'Total Gov. GST (18%)',
            'value': '₹${_fmt(record.totalGst)}',
            'color': ktRose,
          },
        {
          'label': KtStrings.totalPayableLabel,
          'value': '₹${_fmt(record.totalPayable)}',
          'isHighlight': true,
          'color': ktRose,
        },
        if (record.partyName.isNotEmpty) ...[
          {'label': KtStrings.partyNameLabel, 'value': record.partyName},
          {
            'label': KtStrings.partyPaidLabel,
            'value': '₹${_fmt(record.partyPaid)}',
            'color': ktEmerald,
          },
          {
            'label':
                record.partyGainLoss >= 0
                    ? KtStrings.partyGainLabel
                    : KtStrings.partyLossLabel,
            'value': '₹${_fmt(record.partyGainLoss.abs())}',
            'color': record.partyGainLoss >= 0 ? ktEmerald : ktRose,
          },
        ],
        {
          'label': KtStrings.emisPaidLabel,
          'value': '${record.emisPaid} / ${record.tenureMonths}',
        },
        {
          'label': KtStrings.dueDayLabel,
          'value': 'Day ${record.dueDay} of Month',
        },
        {
          'label': 'Remaining Payable',
          'value': '₹${_fmt(record.remainingPayable)}',
          'color': record.isCompleted ? ktEmerald : ktOrange,
        },
        {
          'label': KtStrings.statusLabel,
          'value': record.status,
          'color': record.isCompleted ? ktEmerald : ktCcEmiPrimary,
        },
      ],
      footerNote:
          record.remarks.isNotEmpty ? 'Remarks: ${record.remarks}' : null,
      actions: [
        if (!record.isCompleted)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: ktEmerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showRecordPaymentDialog(record);
            },
            icon: const Icon(Icons.payment_rounded, size: 16),
            label: const Text(
              'Pay EMI',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ktEditButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EmiScreen(ccRecord: record)),
            ).then((_) => _loadRecords());
          },
        ),
        ktDeleteButton(
          onPressed: () {
            Navigator.pop(context);
            _deleteRecord(record);
          },
        ),
      ],
    );
  }

  void _showPaymentHistory(CreditCardEmiRecord record) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0F172A) : Colors.white;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => Container(
            height: MediaQuery.of(sheetContext).size.height * 0.78,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              border: Border.all(
                color: isDark ? ktBorderWhite10 : Colors.black12,
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          color: ktCcEmiPrimary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Payment history',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${record.cardName} • ${record.emisPaid}/${record.tenureMonths} EMIs paid',
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child:
                        record.repayments.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 42,
                                    color:
                                        isDark
                                            ? Colors.white38
                                            : Colors.black38,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'No payments recorded yet',
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? Colors.white60
                                              : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: record.repayments.length,
                              separatorBuilder:
                                  (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final payment = record.repayments[index];
                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? ktCardBg
                                            : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color:
                                          isDark
                                              ? ktBorderWhite10
                                              : Colors.black12,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: ktEmerald.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_rounded,
                                          color: ktEmerald,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'EMI #${payment.emiNumber}',
                                              style: TextStyle(
                                                color:
                                                    isDark
                                                        ? Colors.white
                                                        : Colors.black87,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '${payment.paymentDate} • ${payment.paymentMode}',
                                              style: TextStyle(
                                                color:
                                                    isDark
                                                        ? Colors.white60
                                                        : Colors.black54,
                                                fontSize: 12,
                                              ),
                                            ),
                                            if (payment.remarks.isNotEmpty)
                                              Text(
                                                payment.remarks,
                                                style: TextStyle(
                                                  color:
                                                      isDark
                                                          ? Colors.white54
                                                          : Colors.black54,
                                                  fontSize: 11,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '₹${_fmt(payment.amountPaid)}',
                                        style: const TextStyle(
                                          color: ktEmerald,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                  ),
                  if (record.repayments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ktCcEmiPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _downloadPaymentHistoryPdf(record),
                          icon: const Icon(Icons.picture_as_pdf_rounded),
                          label: const Text(
                            KtStrings.downloadPaymentHistoryPdf,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _downloadPaymentHistoryPdf(CreditCardEmiRecord record) async {
    try {
      await exportCcPaymentHistoryPdf(record);
      if (mounted) ktShowCustomToast(context, KtStrings.paymentHistoryPdfReady);
    } catch (_) {
      if (mounted)
        ktShowCustomToast(context, KtStrings.paymentHistoryPdfFailed);
    }
  }

  /// Opens an Executive Preview Dialog for the Credit Card EMI Statement
  void _showPreviewModalDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recordsToPreview = _filteredRecords;
    final todayStr = ktFormatDate(getIndiaTime()); // Project date rule

    final totalPayable = _totalPayableAmount;
    final totalPaid = _totalPaidAmount;
    final totalBalance = _totalOutstanding;
    final partyGainLoss = _partyGainLossTotal;
    final overallProgress =
        totalPayable > 0 ? (totalPaid / totalPayable).clamp(0.0, 1.0) : 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (modalCtx) => Container(
            height: MediaQuery.of(context).size.height * 0.88,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                // Handle/Indicator
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [ktCcEmiPrimary, ktCcEmiSecondary],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              KtStrings.previewCcEmiStatement,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Generated: $todayStr • ${recordsToPreview.length} Records',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalCtx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Content Body
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Statement Summary Card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                isDark
                                    ? [
                                      const Color(0xFF1E1B4B),
                                      const Color(0xFF0F172A),
                                    ]
                                    : [const Color(0xFFEEF2FF), Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: ktCcEmiPrimary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  KtStrings.statementSummary.toUpperCase(),
                                  style: const TextStyle(
                                    color: ktCcEmiPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  '${(overallProgress * 100).toStringAsFixed(1)}% Settled',
                                  style: const TextStyle(
                                    color: ktEmerald,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildPreviewStat(
                                    'Total Payable',
                                    '₹${_fmt(totalPayable)}',
                                    isDark,
                                    alignment: CrossAxisAlignment.start,
                                  ),
                                ),
                                Expanded(
                                  child: _buildPreviewStat(
                                    'Total Paid',
                                    '₹${_fmt(totalPaid)}',
                                    isDark,
                                    color: ktEmerald,
                                    alignment: CrossAxisAlignment.center,
                                  ),
                                ),
                                Expanded(
                                  child: _buildPreviewStat(
                                    'Outstanding',
                                    '₹${_fmt(totalBalance)}',
                                    isDark,
                                    color: ktRose,
                                    alignment: CrossAxisAlignment.end,
                                  ),
                                ),
                              ],
                            ),
                            if (_partyRecords.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildPreviewStat(
                                      KtStrings.partyPaidLabel,
                                      '₹${_fmt(_partyPaidTotal)}',
                                      isDark,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildPreviewStat(
                                      partyGainLoss >= 0
                                          ? KtStrings.partyGainLabel
                                          : KtStrings.partyLossLabel,
                                      '₹${_fmt(partyGainLoss.abs())}',
                                      isDark,
                                      color:
                                          partyGainLoss >= 0
                                              ? ktEmerald
                                              : ktRose,
                                      alignment: CrossAxisAlignment.end,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: overallProgress,
                                minHeight: 8,
                                backgroundColor:
                                    isDark ? Colors.white10 : Colors.black12,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  ktEmerald,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Table Header
                      Text(
                        'CREDIT CARD EMIS & PAID STATUS',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Statement Items List
                      if (recordsToPreview.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              KtStrings.noCcEmiFound,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ),
                        )
                      else
                        for (int i = 0; i < recordsToPreview.length; i++)
                          _buildPreviewItemRow(
                            recordsToPreview[i],
                            i + 1,
                            isDark,
                          ),
                    ],
                  ),
                ),

                // Bottom Actions Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? ktCardBg : Colors.grey.shade100,
                    border: Border(
                      top: BorderSide(
                        color: isDark ? ktBorderWhite10 : Colors.black12,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: ktCcEmiPrimary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            final buffer = StringBuffer();
                            buffer.writeln(
                              '=== KT APPS - CC EMI STATEMENT ===',
                            );
                            buffer.writeln('Date: $todayStr');
                            buffer.writeln(
                              'Total Payable: ₹${_fmt(totalPayable)}',
                            );
                            buffer.writeln('Total Paid: ₹${_fmt(totalPaid)}');
                            buffer.writeln(
                              'Outstanding: ₹${_fmt(totalBalance)}',
                            );
                            if (_partyRecords.isNotEmpty) {
                              buffer.writeln(
                                'Party Paid: ₹${_fmt(_partyPaidTotal)}',
                              );
                              buffer.writeln(
                                '${partyGainLoss >= 0 ? KtStrings.partyGainLabel : KtStrings.partyLossLabel}: ₹${_fmt(partyGainLoss.abs())}',
                              );
                            }
                            buffer.writeln(
                              '-----------------------------------',
                            );
                            for (final r in recordsToPreview) {
                              buffer.writeln(
                                '• ${r.cardName} (${r.merchantName}): Paid ₹${_fmt(r.paidAmount)} / ₹${_fmt(r.totalPayable)} [${r.emisPaid}/${r.tenureMonths} EMIs - ${r.status}]',
                              );
                              if (r.partyName.isNotEmpty) {
                                buffer.writeln(
                                  '  Party: ${r.partyName}, Paid ₹${_fmt(r.partyPaid)}, ${r.partyGainLoss >= 0 ? KtStrings.partyGainLabel : KtStrings.partyLossLabel}: ₹${_fmt(r.partyGainLoss.abs())}',
                                );
                              }
                            }
                            Clipboard.setData(
                              ClipboardData(text: buffer.toString()),
                            );
                            ktShowCustomToast(
                              context,
                              KtStrings.copiedToClipboard,
                            );
                          },
                          icon: const Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: ktCcEmiPrimary,
                          ),
                          label: const Text(
                            KtStrings.copySummary,
                            style: TextStyle(
                              color: ktCcEmiPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ktCcEmiPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.pop(modalCtx),
                          child: const Text(
                            KtStrings.close,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildPreviewStat(
    String label,
    String value,
    bool isDark, {
    Color? color,
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment:
              alignment == CrossAxisAlignment.end
                  ? Alignment.centerRight
                  : (alignment == CrossAxisAlignment.center
                      ? Alignment.center
                      : Alignment.centerLeft),
          child: Text(
            value,
            style: TextStyle(
              color: color ?? (isDark ? Colors.white : Colors.black87),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewItemRow(
    CreditCardEmiRecord record,
    int index,
    bool isDark,
  ) {
    final paidPercent =
        record.totalPayable > 0
            ? (record.paidAmount / record.totalPayable * 100).toInt()
            : 0;

    Color statusColor = ktRose;
    String statusLabel = KtStrings.unpaid;
    if (record.isCompleted || record.paidAmount >= record.totalPayable) {
      statusColor = ktEmerald;
      statusLabel = KtStrings.fullyPaid;
    } else if (record.paidAmount > 0) {
      statusColor = ktOrange;
      statusLabel = KtStrings.partiallyPaid;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? ktCardBg : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#$index. ${record.cardName}',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor, width: 1),
                ),
                child: Text(
                  '$statusLabel ($paidPercent%)',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${record.merchantName} • Date: ${record.purchaseDate}', // Project Date rule
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 11,
            ),
          ),
          if (record.partyName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${KtStrings.partyNameLabel}: ${record.partyName} • '
              '${KtStrings.partyPaidLabel}: ₹${_fmt(record.partyPaid)} • '
              '${record.partyGainLoss >= 0 ? KtStrings.partyGainLabel : KtStrings.partyLossLabel}: '
              '₹${_fmt(record.partyGainLoss.abs())}',
              style: TextStyle(
                color: record.partyGainLoss >= 0 ? ktEmerald : ktRose,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid: ₹${_fmt(record.paidAmount)} / ₹${_fmt(record.totalPayable)}',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'EMIs: ${record.emisPaid}/${record.tenureMonths}',
                style: const TextStyle(
                  color: ktCcEmiPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredRecords;

    return Scaffold(
      backgroundColor: isDark ? ktBgDark : const Color(0xFFF8FAFC),
      appBar:
          widget.embedded
              ? null
              : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      KtStrings.creditCardEmiReportTitle,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      KtStrings.creditCardEmiReportSubtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    tooltip: KtStrings.previewReport,
                    icon: const Icon(
                      Icons.preview_rounded,
                      color: ktCcEmiPrimary,
                    ),
                    onPressed: _showPreviewModalDialog,
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: ktCcEmiPrimary,
                    ),
                    onPressed: _loadRecords,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: ktCcEmiPrimary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EmiScreen()),
                      ).then((_) => _loadRecords());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.home, color: ktCcEmiPrimary),
                    onPressed: () {
                      Navigator.pushNamed(context, '/');
                    },
                  ),
                ],
              ),
      body: Stack(
        children: [
          const AmbientBackground(),
          Column(
            children: [
              // Summary KPI Grid
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            title: KtStrings.totalOutstandingEmi,
                            value: '₹${_fmt(_totalOutstanding)}',
                            icon: Icons.account_balance_wallet_rounded,
                            color: ktCcEmiPrimary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKpiCard(
                            title: KtStrings.monthlyEmiCommitment,
                            value: '₹${_fmt(_monthlyCommitment)}/mo',
                            icon: Icons.calendar_month_rounded,
                            color: ktEmerald,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            title: KtStrings.partyPaidLabel,
                            value: '₹${_fmt(_partyPaidTotal)}',
                            icon: Icons.people_alt_rounded,
                            color: ktCyan,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKpiCard(
                            title: KtStrings.partyGainLossLabel,
                            value:
                                '${_partyGainLossTotal >= 0 ? '+' : '-'}₹${_fmt(_partyGainLossTotal.abs())}',
                            icon:
                                _partyGainLossTotal >= 0
                                    ? Icons.trending_up_rounded
                                    : Icons.trending_down_rounded,
                            color:
                                _partyGainLossTotal >= 0 ? ktEmerald : ktRose,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildKpiCard(
                            title: KtStrings.totalInterestPaid,
                            value: '₹${_fmt(_totalInterest)}',
                            icon: Icons.trending_up_rounded,
                            color: ktRose,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKpiCard(
                            title: 'Active / Total',
                            value:
                                '$_activeCount Active (${_allRecords.length})',
                            icon: Icons.credit_score_rounded,
                            color: ktCyan,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search & Filter & Preview Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search card, merchant, or category...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: ktCcEmiPrimary,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: ktCcEmiPrimary,
                            size: 20,
                          ),
                          onPressed: _showPreviewModalDialog,
                        ),
                        filled: true,
                        fillColor: isDark ? ktCardBg : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? ktBorderWhite10 : Colors.black12,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? ktBorderWhite10 : Colors.black12,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: ktCcEmiPrimary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter Tabs (All, Active, Completed) & Preview Action
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFilterTab('All', isDark),
                          const SizedBox(width: 8),
                          _buildFilterTab('Active', isDark),
                          const SizedBox(width: 8),
                          _buildFilterTab('Completed', isDark),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: _showPreviewModalDialog,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: ktCcEmiPrimary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: ktCcEmiPrimary),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.preview_rounded,
                                    color: ktCcEmiPrimary,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Preview',
                                    style: TextStyle(
                                      color: ktCcEmiPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_availableBankNames.length > 1) ...[
                            const SizedBox(width: 8),
                            Container(
                              height: 40,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? ktCardBg : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color:
                                      isDark ? ktBorderWhite10 : Colors.black12,
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: SizedBox(
                                  width: 128,
                                  child: DropdownButton<String>(
                                    value: _selectedBankFilter,
                                    isExpanded: true,
                                    dropdownColor:
                                        isDark ? ktSlate800 : Colors.white,
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? Colors.white
                                              : Colors.black87,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                    selectedItemBuilder:
                                        (context) =>
                                            _availableBankNames
                                                .map(
                                                  (bank) => Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(
                                                      bank == 'All'
                                                          ? 'All Cards'
                                                          : bank,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                    items:
                                        _availableBankNames.map((bank) {
                                          return DropdownMenuItem(
                                            value: bank,
                                            child: Text(
                                              bank == 'All'
                                                  ? 'All Cards'
                                                  : bank,
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(
                                          () => _selectedBankFilter = val,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Record List
              Expanded(
                child:
                    _loading
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: ktCcEmiPrimary,
                          ),
                        )
                        : filtered.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.credit_card_off_rounded,
                                size: 64,
                                color: isDark ? Colors.white38 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                KtStrings.noCcEmiFound,
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: ktCcEmiPrimary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EmiScreen(),
                                    ),
                                  ).then((_) => _loadRecords());
                                },
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add Credit Card EMI'),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final record = filtered[index];
                            return _buildCreditCardTile(record, isDark);
                          },
                        ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title, bool isDark) {
    final isSelected = _statusFilter == title;
    return InkWell(
      onTap: () => setState(() => _statusFilter = title),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? ktCcEmiPrimary
                  : (isDark ? ktCardBg : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? ktCcEmiPrimary
                    : (isDark ? ktBorderWhite10 : Colors.black12),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color:
                isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return emiReportKpiCard(
      title: title,
      value: value,
      icon: icon,
      color: color,
      isDark: isDark,
    );
  }

  Widget _buildCreditCardTile(CreditCardEmiRecord record, bool isDark) {
    final progress = (record.emisPaid / record.tenureMonths).clamp(0.0, 1.0);
    final cardColor = _getCardBankColor(record.cardName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [cardColor.withValues(alpha: 0.25), const Color(0xFF0F172A)]
                  : [cardColor.withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.2),
              ),
              child: Row(
                children: [
                  Icon(Icons.credit_card_rounded, color: cardColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    record.cardName,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          record.isCompleted
                              ? ktEmerald.withValues(alpha: 0.2)
                              : ktCcEmiPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: record.isCompleted ? ktEmerald : ktCcEmiPrimary,
                      ),
                    ),
                    child: Text(
                      record.isCompleted ? 'COMPLETED' : 'ACTIVE',
                      style: TextStyle(
                        color: record.isCompleted ? ktEmerald : ktCcEmiPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.merchantName,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Category: ${record.category} • Due: Day ${record.dueDay}',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${_fmt(record.monthlyEmi)}',
                            style: TextStyle(
                              color: record.isCompleted ? Colors.grey : ktRose,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            '/ month',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress: ${record.emisPaid}/${record.tenureMonths} EMIs',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}% Paid',
                            style: TextStyle(
                              color: record.isCompleted ? ktEmerald : cardColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor:
                              isDark ? Colors.white10 : Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            record.isCompleted ? ktEmerald : cardColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Info grid row
                  Row(
                    children: [
                      Expanded(
                        child: _buildTileMetric(
                          'Total Purchase',
                          '₹${_fmt(record.totalAmount)}',
                          isDark,
                          color: record.isCompleted ? Colors.grey : ktRose,
                          alignment: CrossAxisAlignment.start,
                        ),
                      ),
                      Expanded(
                        child: _buildTileMetric(
                          'Purchase Date',
                          record.purchaseDate, // Formatted via ktFormatDate
                          isDark,
                          alignment: CrossAxisAlignment.center,
                        ),
                      ),
                      Expanded(
                        child: _buildTileMetric(
                          'Outstanding',
                          '₹${_fmt(record.remainingPayable)}',
                          isDark,
                          color: record.isCompleted ? Colors.grey : ktRose,
                          alignment: CrossAxisAlignment.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Action Buttons Row
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      if (!record.isCompleted) ...[
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ktEmerald,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _showRecordPaymentDialog(record),
                          icon: const Icon(Icons.payment_rounded, size: 14),
                          label: const Text(
                            'Pay EMI',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: ktCcEmiPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () => _showPaymentHistory(record),
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: const Text(
                          'Payment history',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: ktCcEmiPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        onPressed: () => _showRecordDetails(record),
                        icon: const Icon(Icons.info_outline_rounded, size: 16),
                        label: const Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTileMetric(
    String label,
    String value,
    bool isDark, {
    Color? color,
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment:
              alignment == CrossAxisAlignment.end
                  ? Alignment.centerRight
                  : (alignment == CrossAxisAlignment.center
                      ? Alignment.center
                      : Alignment.centerLeft),
          child: Text(
            value,
            style: TextStyle(
              color: color ?? (isDark ? Colors.white : Colors.black87),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Color _getCardBankColor(String bankName) {
    final lower = bankName.toLowerCase();
    if (lower.contains('hdfc')) return const Color(0xFF1E3A8A); // Deep Blue
    if (lower.contains('icici') || lower.contains('amazon'))
      return const Color(0xFFEA580C); // Orange
    if (lower.contains('sbi')) return const Color(0xFF0284C7); // Sky Blue
    if (lower.contains('axis'))
      return const Color(0xFF881337); // Maroon/Burgundy
    if (lower.contains('onecard')) return const Color(0xFF374151); // Dark Slate
    if (lower.contains('amex') || lower.contains('american'))
      return const Color(0xFF0D9488); // Teal
    if (lower.contains('kotak')) return const Color(0xFFDC2626); // Red
    return ktCcEmiPrimary;
  }
}
