import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core_constants.dart';
import '../core_ui_utils.dart';
import '../core_utils.dart';
import 'emi_screen.dart';
import 'emi_payment_history_pdf.dart';
import 'emi_ui.dart';
import 'loan_emi_models.dart';
import 'loan_emi_service.dart';

String _currency(double value) => NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 2,
).format(value);

class LoanEmiReportScreen extends StatefulWidget {
  const LoanEmiReportScreen({super.key, this.service, this.embedded = false});
  final LoanEmiService? service;
  final bool embedded;

  @override
  State<LoanEmiReportScreen> createState() => LoanEmiReportScreenState();
}

class LoanEmiReportScreenState extends State<LoanEmiReportScreen>
    with AutomaticKeepAliveClientMixin {
  late final LoanEmiService _service;
  final _search = TextEditingController();
  List<LoanEmiRecord> _records = [];
  bool _loading = true;
  bool _failed = false;
  EmiLoanType? _type;
  String _status = KtStrings.allLoanStatuses;
  Future<void> refreshRecords() => _loading ? Future.value() : _load();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? LoanEmiService();
    _load();
  }

  @override
  void dispose() {
    _service.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final records = await _service.fetchRecords();
      records.sort(
        (a, b) =>
            ktParseDate(b.startDate)!.compareTo(ktParseDate(a.startDate)!),
      );
      if (mounted) setState(() => _records = records);
    } catch (error) {
      debugPrint('Loan EMI report failed: $error');
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _entry([LoanEmiRecord? record]) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EmiScreen(initialTab: 1, loanRecord: record),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _payment(LoanEmiRecord record) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoanPaymentSheet(record: record, service: _service),
    );
    if (saved == true && mounted) {
      ktShowCustomToast(context, KtStrings.emiPaymentRecorded);
      await _load();
    }
  }

  Future<void> _reviseRate(LoanEmiRecord record) async {
    final rateController = TextEditingController(
      text: record.currentAnnualRate.toString(),
    );
    final today = getIndiaTime();
    var effectiveDate = DateTime(today.year, today.month, today.day);
    var option = LoanRateRevisionOption.recalculateEmi;
    var confirming = false;
    try {
      final selection = await showModalBottomSheet<
        ({
          double rate,
          DateTime date,
          LoanRateRevisionOption option,
          LoanRateRevisionPreview preview,
        })
      >(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder:
            (sheetContext) => StatefulBuilder(
              builder: (context, setSheetState) {
                final rate = double.tryParse(rateController.text.trim());
                LoanRateRevisionPreview? preview;
                String? previewError;
                if (rate != null && rate.isFinite && rate >= 0) {
                  try {
                    preview = record.previewRateRevision(rate, option);
                  } on StateError catch (error) {
                    previewError = error.message;
                  }
                }
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                        padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              color: ktCcEmiPrimary,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                KtStrings.loanRateRevisionTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            16,
                            24,
                            16 + MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child:
                              confirming
                                  ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        KtStrings.confirmRateRevision,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${record.lender} • ${record.accountNumber}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${KtStrings.interestRateLabel}: $rate%',
                                      ),
                                      Text(
                                        '${KtStrings.effectiveDateLabel}: ${ktFormatDate(effectiveDate)}',
                                      ),
                                      Text(option.label),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${KtStrings.revisedEmiLabel}: ${_currency(preview!.monthlyEmi)}',
                                      ),
                                      Text(
                                        '${KtStrings.revisedTenureLabel}: ${preview.remainingTenureMonths} months',
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        KtStrings.rateRevisionEstimateNote,
                                      ),
                                    ],
                                  )
                                  : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextFormField(
                                        controller: rateController,
                                        autofocus: true,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: const InputDecoration(
                                          labelText:
                                              KtStrings.interestRateLabel,
                                          suffixText: '%',
                                        ),
                                        onChanged: (_) => setSheetState(() {}),
                                      ),
                                      const SizedBox(height: 12),
                                      OutlinedButton.icon(
                                        onPressed: () async {
                                          final picked = await showDatePicker(
                                            context: sheetContext,
                                            initialDate: effectiveDate,
                                            firstDate: DateTime(
                                              today.year,
                                              today.month,
                                              today.day,
                                            ),
                                            lastDate: DateTime(2200),
                                          );
                                          if (picked != null) {
                                            setSheetState(
                                              () => effectiveDate = picked,
                                            );
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.calendar_today_rounded,
                                        ),
                                        label: Text(
                                          '${KtStrings.effectiveDateLabel}: ${ktFormatDate(effectiveDate)}',
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        KtStrings.repaymentChangeLabel,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      for (final choice
                                          in LoanRateRevisionOption.values)
                                        RadioListTile<LoanRateRevisionOption>(
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(choice.label),
                                          value: choice,
                                          groupValue: option,
                                          onChanged: (value) {
                                            if (value != null) {
                                              setSheetState(
                                                () => option = value,
                                              );
                                            }
                                          },
                                        ),
                                      if (preview != null) ...[
                                        const Divider(),
                                        Text(
                                          '${KtStrings.currentOutstandingLabel}: ${_currency(record.outstanding)}',
                                        ),
                                        Text(
                                          '${KtStrings.revisedEmiLabel}: ${_currency(preview.monthlyEmi)}',
                                        ),
                                        Text(
                                          '${KtStrings.revisedTenureLabel}: ${preview.remainingTenureMonths} months',
                                        ),
                                      ],
                                      if (previewError != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8,
                                          ),
                                          child: Text(
                                            previewError,
                                            style: TextStyle(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.error,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        KtStrings.rateRevisionEstimateNote,
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          12,
                          24,
                          20 + MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed:
                                    confirming
                                        ? () => setSheetState(
                                          () => confirming = false,
                                        )
                                        : () => Navigator.pop(sheetContext),
                                child: Text(
                                  confirming
                                      ? KtStrings.cancelRateRevision
                                      : KtStrings.cancel,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed:
                                    confirming
                                        ? () => Navigator.pop(sheetContext, (
                                          rate: rate!,
                                          date: effectiveDate,
                                          option: option,
                                          preview: preview!,
                                        ))
                                        : preview == null || rate == null
                                        ? null
                                        : () => setSheetState(
                                          () => confirming = true,
                                        ),
                                child: Text(
                                  confirming
                                      ? KtStrings.saveRateRevision
                                      : KtStrings.reviewRateRevision,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      );
      if (selection == null || !mounted) return;
      final revision = LoanRateRevision(
        id: LoanEmiService.createRequestId(),
        loanId: record.id!,
        effectiveDate: ktFormatDate(selection.date),
        annualRate: selection.rate,
        option: selection.option,
        monthlyEmi: selection.preview.monthlyEmi,
        remainingTenureMonths: selection.preview.remainingTenureMonths,
      );
      await _service.recordRateRevision(revision);
      if (!mounted) return;
      ktShowCustomToast(context, KtStrings.rateRevisionSaved);
      await _load();
    } catch (error) {
      debugPrint('Loan ROI revision failed: $error');
      if (mounted) ktShowCustomToast(context, KtStrings.saveFailed);
    } finally {
      rateController.dispose();
    }
  }

  Future<void> _delete(LoanEmiRecord record) async {
    if (record.payments.isNotEmpty) {
      ktShowCustomToast(context, KtStrings.loanHasPayments);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(KtStrings.delete),
            content: const Text(KtStrings.confirmDeleteLoanEmi),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(KtStrings.cancel),
              ),
              ktDeleteButton(onPressed: () => Navigator.pop(context, true)),
            ],
          ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _service.deleteRecord(record.id!);
      if (!mounted) return;
      ktShowCustomToast(context, KtStrings.loanEmiDeleted);
      await _load();
    } catch (_) {
      if (mounted) ktShowCustomToast(context, KtStrings.saveFailed);
    }
  }

  void _details(LoanEmiRecord record) {
    ktShowDetailsSheet(
      context: context,
      title: record.lender,
      subtitle: '${record.type.label} - ${record.accountNumber}',
      icon: Icons.account_balance_rounded,
      themeColor: ktCcEmiPrimary,
      details: [
        {
          'label': KtStrings.principalOutstandingLabel,
          'value': _currency(record.outstanding),
          'isHighlight': true,
          'color': ktRose,
        },
        {
          'label': KtStrings.loanPrincipalLabel,
          'value': _currency(record.principal),
          'color': ktRose,
        },
        {
          'label': KtStrings.interestRateLabel,
          'value': '${record.currentAnnualRate}%',
        },
        for (final revision in record.rateRevisions)
          {
            'label':
                '${KtStrings.interestRateLabel} from ${revision.effectiveDate}',
            'value':
                '${revision.annualRate}% • ${revision.option.label} • '
                '${_currency(revision.monthlyEmi)} / month • '
                '${revision.remainingTenureMonths} months',
          },
        {
          'label': KtStrings.tenureMonthsLabel,
          'value': record.tenureMonths.toString(),
        },
        {
          'label': KtStrings.monthlyEmiLabel,
          'value': _currency(record.monthlyEmi),
          'color': ktRose,
        },
        {
          'label': KtStrings.processingFeeLabel,
          'value': _currency(record.processingFee),
          'color': ktRose,
        },
        {
          'label': KtStrings.totalInterestLabel,
          'value': _currency(record.totalInterest),
          'color': ktRose,
        },
        {
          'label': KtStrings.totalPayableLabel,
          'value': _currency(record.totalPayable),
          'color': ktRose,
        },
        {'label': KtStrings.loanStartDate, 'value': record.startDate},
        {'label': KtStrings.firstEmiDateLabel, 'value': record.firstEmiDate},
        {
          'label': KtStrings.principalPaidLabel,
          'value': _currency(record.principalPaid),
          'color': ktEmerald,
        },
        {
          'label': KtStrings.interestPaidLabel,
          'value': _currency(record.interestPaid),
          'color': ktEmerald,
        },
        for (final field in record.type.fields)
          {'label': field.label, 'value': record.details[field.key] ?? ''},
        {'label': KtStrings.remarks, 'value': record.remarks},
      ],
      footerNote: KtStrings.loanEmiEstimate,
      actions: [
        if (!record.isCompleted)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _reviseRate(record);
            },
            icon: const Icon(Icons.trending_up_rounded),
            label: const Text(KtStrings.reviseLoanRate),
          ),
        ktEditButton(
          onPressed: () {
            Navigator.pop(context);
            _entry(record);
          },
        ),
        if (record.payments.isEmpty)
          ktDeleteButton(
            onPressed: () {
              Navigator.pop(context);
              _delete(record);
            },
          ),
        if (!record.isCompleted)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _payment(record);
            },
            icon: const Icon(Icons.payment_rounded),
            label: const Text(KtStrings.recordPayment),
          ),
        if (!record.isCompleted)
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _repaymentHistory(record);
            },
            icon: const Icon(Icons.history_rounded),
            label: const Text(KtStrings.repaymentHistory),
          ),
      ],
    );
  }

  void _repaymentHistory(LoanEmiRecord record) {
    ktShowDetailsSheet(
      context: context,
      title: KtStrings.repaymentHistory,
      subtitle: '${record.lender} - ${record.accountNumber}',
      icon: Icons.history_rounded,
      themeColor: ktCcEmiPrimary,
      details: [
        if (record.payments.isEmpty)
          {'label': KtStrings.repaymentHistory, 'value': 'No payments recorded'}
        else
          for (final payment in record.payments.reversed) ...[
            {
              'label': payment.paymentDate,
              'value': _currency(payment.amountPaid),
              'color': ktEmerald,
            },
            {
              'label': KtStrings.principalPaidLabel,
              'value': _currency(payment.principalPaid),
              'color': ktEmerald,
            },
            {
              'label': KtStrings.interestPaidLabel,
              'value': _currency(payment.interestPaid),
              'color': ktEmerald,
            },
            {'label': KtStrings.paymentModeLabel, 'value': payment.paymentMode},
            if (payment.remarks.isNotEmpty)
              {'label': KtStrings.remarks, 'value': payment.remarks},
          ],
      ],
      actions: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: ktCcEmiPrimary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
            _downloadPaymentHistoryPdf(record);
          },
          icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
          label: const Text(KtStrings.downloadPaymentHistoryPdf),
        ),
      ],
    );
  }

  Future<void> _downloadPaymentHistoryPdf(LoanEmiRecord record) async {
    try {
      await exportLoanPaymentHistoryPdf(record);
      if (mounted) ktShowCustomToast(context, KtStrings.paymentHistoryPdfReady);
    } catch (_) {
      if (mounted)
        ktShowCustomToast(context, KtStrings.paymentHistoryPdfFailed);
    }
  }

  void _showPreview(List<LoanEmiRecord> records) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = ktFormatDate(getIndiaTime());
    final principal = records.fold<double>(
      0,
      (sum, record) => sum + record.principal,
    );
    final payable = records.fold<double>(
      0,
      (sum, record) => sum + record.totalPayable,
    );
    final paid = records.fold<double>(
      0,
      (sum, record) => sum + record.principalPaid + record.interestPaid,
    );
    final outstanding = records.fold<double>(
      0,
      (sum, record) => sum + record.outstanding,
    );
    final interestPaid = records.fold<double>(
      0,
      (sum, record) => sum + record.interestPaid,
    );
    final progress = payable <= 0 ? 0.0 : (paid / payable).clamp(0.0, 1.0);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (modalContext) => Container(
            height: MediaQuery.of(modalContext).size.height * 0.88,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
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
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [ktCcEmiPrimary, ktCcEmiSecondary],
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              KtStrings.previewLoanEmiStatement,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Generated: $today • ${records.length} Records',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(modalContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
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
                                const Text(
                                  'LOAN SUMMARY',
                                  style: TextStyle(
                                    color: ktCcEmiPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                Text(
                                  '${(progress * 100).toStringAsFixed(1)}% Paid',
                                  style: const TextStyle(
                                    color: ktEmerald,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _previewMetric(
                                  'Total Payable',
                                  _currency(payable),
                                  isDark,
                                ),
                                _previewMetric(
                                  'Paid',
                                  _currency(paid),
                                  isDark,
                                  color: ktEmerald,
                                ),
                                _previewMetric(
                                  'Outstanding',
                                  _currency(outstanding),
                                  isDark,
                                  color: ktRose,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _previewMetric(
                                  'Interest Paid',
                                  _currency(interestPaid),
                                  isDark,
                                  color: ktEmerald,
                                ),
                                _previewMetric(
                                  'Active Loans',
                                  '${records.where((record) => !record.isCompleted).length}',
                                  isDark,
                                ),
                                _previewMetric(
                                  'Completed',
                                  '${records.where((record) => record.isCompleted).length}',
                                  isDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
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
                      Text(
                        'LOAN EMIS & PAYMENT STATUS',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (records.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              KtStrings.noLoanEmis,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ),
                        )
                      else
                        for (var index = 0; index < records.length; index++)
                          _loanPreviewRow(records[index], index + 1, isDark),
                    ],
                  ),
                ),
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
                            final summary =
                                StringBuffer()
                                  ..writeln(
                                    '=== KT APPS - LOAN EMI STATEMENT ===',
                                  )
                                  ..writeln('Date: $today')
                                  ..writeln(
                                    'Principal: ${_currency(principal)}',
                                  )
                                  ..writeln(
                                    'Total Payable: ${_currency(payable)}',
                                  )
                                  ..writeln('Paid: ${_currency(paid)}')
                                  ..writeln(
                                    'Outstanding: ${_currency(outstanding)}',
                                  )
                                  ..writeln(
                                    'Interest Paid: ${_currency(interestPaid)}',
                                  );
                            for (final record in records) {
                              summary.writeln(
                                '• ${record.lender} (${record.type.label}): Paid ${_currency(record.principalPaid + record.interestPaid)} / ${_currency(record.principal)} • Outstanding ${_currency(record.outstanding)} • ${record.isCompleted ? KtStrings.loanCompleted : KtStrings.activeText}',
                              );
                            }
                            Clipboard.setData(
                              ClipboardData(text: summary.toString()),
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
                          onPressed: () => Navigator.pop(modalContext),
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

  Widget _previewMetric(
    String label,
    String value,
    bool isDark, {
    Color? color,
  }) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white54 : Colors.black54,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: color ?? (isDark ? Colors.white : Colors.black87),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    ),
  );

  Widget _loanPreviewRow(
    LoanEmiRecord record,
    int index,
    bool isDark,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color:
          isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.025),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black12),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: ktCcEmiPrimary.withValues(alpha: 0.15),
          child: Text(
            '$index',
            style: const TextStyle(
              color: ktCcEmiPrimary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.lender,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${record.type.label} • ${record.accountNumber}',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${_currency(record.principalPaid + record.interestPaid)} paid / ${_currency(record.principal)}',
                style: const TextStyle(
                  color: ktEmerald,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _currency(record.outstanding),
              style: TextStyle(
                color: record.isCompleted ? Colors.grey : ktRose,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              record.isCompleted
                  ? KtStrings.loanCompleted
                  : KtStrings.activeText,
              style: TextStyle(
                color: record.isCompleted ? Colors.grey : ktEmerald,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final query = _search.text.toLowerCase().trim();
    final records =
        _records
            .where(
              (record) =>
                  (_type == null || record.type == _type) &&
                  (_status == KtStrings.allLoanStatuses ||
                      (_status == KtStrings.loanCompleted
                          ? record.isCompleted
                          : !record.isCompleted)) &&
                  ('${record.lender} ${record.accountNumber}'
                      .toLowerCase()
                      .contains(query)),
            )
            .toList()
          ..sort((a, b) {
            final completionOrder = (a.isCompleted ? 1 : 0).compareTo(
              b.isCompleted ? 1 : 0,
            );
            if (completionOrder != 0) return completionOrder;
            return b.principal.compareTo(a.principal);
          });
    final outstanding = _records.fold(
      0.0,
      (sum, record) => sum + record.outstanding,
    );
    final commitment = _records
        .where((record) => !record.isCompleted)
        .fold(0.0, (sum, record) => sum + record.monthlyEmi);
    return Scaffold(
      backgroundColor: isDark ? ktBgDark : const Color(0xFFF8FAFC),
      appBar:
          widget.embedded
              ? null
              : AppBar(
                automaticallyImplyLeading: false,
                title: const Text(KtStrings.loanEmiReport),
                actions: [
                  IconButton(
                    tooltip: KtStrings.previewReport,
                    onPressed: () => _showPreview(records),
                    icon: const Icon(
                      Icons.preview_rounded,
                      color: ktCcEmiPrimary,
                    ),
                  ),
                  IconButton(
                    tooltip: KtStrings.refresh,
                    onPressed: _loading ? null : _load,
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: ktCcEmiPrimary,
                    ),
                  ),
                ],
              ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cards = [
                          emiReportKpiCard(
                            title: KtStrings.principalOutstandingLabel,
                            value: _currency(outstanding),
                            icon: Icons.account_balance_wallet_rounded,
                            color: ktCcEmiPrimary,
                            isDark: isDark,
                          ),
                          emiReportKpiCard(
                            title: KtStrings.monthlyEmiCommitment,
                            value: _currency(commitment),
                            icon: Icons.calendar_month_rounded,
                            color: ktEmerald,
                            isDark: isDark,
                          ),
                          emiReportKpiCard(
                            title: KtStrings.interestPaidLabel,
                            value: _currency(
                              _records.fold(
                                0.0,
                                (sum, record) => sum + record.interestPaid,
                              ),
                            ),
                            icon: Icons.trending_up_rounded,
                            color: ktRose,
                            isDark: isDark,
                          ),
                          emiReportKpiCard(
                            title: KtStrings.loanActiveTotal,
                            value:
                                '${_records.where((record) => !record.isCompleted).length} / ${_records.length}',
                            icon: Icons.account_balance_rounded,
                            color: ktCyan,
                            isDark: isDark,
                          ),
                        ];
                        return Wrap(
                          key: const ValueKey('loan-report-summary'),
                          spacing: 12,
                          runSpacing: 10,
                          children:
                              cards
                                  .map(
                                    (card) => SizedBox(
                                      width:
                                          constraints.maxWidth < 360
                                              ? constraints.maxWidth
                                              : (constraints.maxWidth - 12) / 2,
                                      child: card,
                                    ),
                                  )
                                  .toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      decoration: emiInputDecoration(
                        isDark: isDark,
                        hint: KtStrings.loanSearch,
                        icon: Icons.search_rounded,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final type in <EmiLoanType?>[
                            null,
                            ...EmiLoanType.values,
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  type?.label ?? KtStrings.allLoanTypes,
                                  style: TextStyle(
                                    color:
                                        _type == type
                                            ? Colors.white
                                            : (isDark
                                                ? Colors.white70
                                                : Colors.black87),
                                    fontSize: 12,
                                    fontWeight:
                                        _type == type
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                  ),
                                ),
                                selected: _type == type,
                                selectedColor: ktCcEmiPrimary,
                                backgroundColor:
                                    isDark ? ktCardBg : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color:
                                        _type == type
                                            ? ktCcEmiPrimary
                                            : (isDark
                                                ? ktBorderWhite10
                                                : Colors.black12),
                                  ),
                                ),
                                onSelected: (_) => setState(() => _type = type),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final status in [
                            KtStrings.allLoanStatuses,
                            KtStrings.activeText,
                            KtStrings.loanCompleted,
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(status),
                                selected: _status == status,
                                onSelected:
                                    (_) => setState(() => _status = status),
                                selectedColor: ktCcEmiPrimary,
                                backgroundColor:
                                    isDark ? ktCardBg : Colors.grey.shade200,
                                labelStyle: TextStyle(
                                  color:
                                      _status == status
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white70
                                              : Colors.black87),
                                  fontSize: 12,
                                  fontWeight:
                                      _status == status
                                          ? FontWeight.w900
                                          : FontWeight.w600,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color:
                                        _status == status
                                            ? ktCcEmiPrimary
                                            : (isDark
                                                ? ktBorderWhite10
                                                : Colors.black12),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: ktCcEmiPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              side: BorderSide(
                                color: ktCcEmiPrimary.withValues(alpha: 0.6),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _showPreview(records),
                            icon: const Icon(Icons.preview_rounded, size: 16),
                            label: const Text(
                              KtStrings.previewReport,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_failed)
                      Row(
                        children: [
                          const Expanded(
                            child: Text(KtStrings.loanEmiLoadFailed),
                          ),
                          TextButton(
                            onPressed: _load,
                            child: const Text(KtStrings.refresh),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (_loading || records.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child:
                    _loading
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: ktCcEmiPrimary,
                          ),
                        )
                        : Center(
                          child: Text(
                            _failed
                                ? KtStrings.loanEmiLoadFailed
                                : KtStrings.noLoanEmis,
                          ),
                        ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final record = records[index];
                    return _loanTile(record, isDark, index);
                  }, childCount: records.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _loanTile(LoanEmiRecord record, bool isDark, int index) {
    final progress = (record.principalPaid / record.principal).clamp(0.0, 1.0);
    final statusColor = record.isCompleted ? Colors.grey : ktEmerald;
    const lightAlternates = [
      Color(0xFFF0F7FF),
      Color(0xFFF0FAF6),
      Color(0xFFFFF8ED),
    ];
    const darkAlternates = [
      Color(0xFF17243A),
      Color(0xFF172D2A),
      Color(0xFF30271B),
    ];
    final cardColor =
        record.isCompleted
            ? (isDark ? const Color(0xFF252A32) : const Color(0xFFE5E7EB))
            : (isDark ? darkAlternates[index % 3] : lightAlternates[index % 3]);
    final textColor = isDark ? Colors.white : Colors.black87;
    final mutedColor = isDark ? Colors.white54 : Colors.black54;
    Widget metric(
      String label,
      String value,
      CrossAxisAlignment alignment, {
      Color? color,
    }) => Expanded(
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(
            label,
            style: TextStyle(
              color: mutedColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment:
                alignment == CrossAxisAlignment.end
                    ? Alignment.centerRight
                    : alignment == CrossAxisAlignment.center
                    ? Alignment.center
                    : Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color ?? textColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
    return Container(
      key: ValueKey('loan-record-${record.id}'),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              isDark
                  ? [cardColor.withValues(alpha: 0.55), const Color(0xFF0F172A)]
                  : [cardColor.withValues(alpha: 0.8), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.25),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.account_balance_rounded,
                    color: statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.lender,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      (record.isCompleted
                              ? KtStrings.loanCompleted
                              : KtStrings.activeText)
                          .toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final info = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.type.label,
                            style: TextStyle(
                              color:
                                  record.isCompleted ? Colors.grey : textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${KtStrings.loanAccountLabel}: ${record.accountNumber}',
                            style: TextStyle(color: mutedColor, fontSize: 11),
                          ),
                          Text(
                            '${KtStrings.dueDayLabel}: ${ktParseDate(record.firstEmiDate)!.day}',
                            style: TextStyle(color: mutedColor, fontSize: 11),
                          ),
                        ],
                      );
                      final emi = Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _currency(record.monthlyEmi),
                            style: TextStyle(
                              color: record.isCompleted ? Colors.grey : ktRose,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Text(
                            KtStrings.emiPerMonth,
                            style: TextStyle(color: mutedColor, fontSize: 10),
                          ),
                        ],
                      );
                      if (constraints.maxWidth < 360) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [info, const SizedBox(height: 8), emi],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: info),
                          const SizedBox(width: 12),
                          emi,
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          KtStrings.loanPrincipalProgress,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          color: statusColor,
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
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      valueColor: AlwaysStoppedAnimation(statusColor),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      metric(
                        KtStrings.loanPrincipalLabel,
                        _currency(record.principal),
                        CrossAxisAlignment.start,
                        color: record.isCompleted ? Colors.grey : ktRose,
                      ),
                      metric(
                        KtStrings.loanStartDate,
                        record.startDate,
                        CrossAxisAlignment.center,
                      ),
                      metric(
                        KtStrings.principalOutstandingLabel,
                        _currency(record.outstanding),
                        CrossAxisAlignment.end,
                        color: record.isCompleted ? Colors.grey : ktRose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!record.isCompleted)
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
                          onPressed: () => _payment(record),
                          icon: const Icon(Icons.payment_rounded, size: 14),
                          label: const Text(
                            KtStrings.emiPayAction,
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
                        onPressed: () => _details(record),
                        icon: const Icon(Icons.info_outline_rounded, size: 16),
                        label: const Text(
                          KtStrings.emiDetailsAction,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (record.isCompleted)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: ktCcEmiPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onPressed: () => _repaymentHistory(record),
                          icon: const Icon(Icons.history_rounded, size: 16),
                          label: const Text(
                            KtStrings.repaymentHistory,
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
}

class _LoanPaymentSheet extends StatefulWidget {
  const _LoanPaymentSheet({required this.record, required this.service});
  final LoanEmiRecord record;
  final LoanEmiService service;

  @override
  State<_LoanPaymentSheet> createState() => _LoanPaymentSheetState();
}

class _LoanPaymentSheetState extends State<_LoanPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _principal = TextEditingController();
  final _interest = TextEditingController();
  final _remarks = TextEditingController();
  late final String _id;
  DateTime _date = getIndiaTime();
  String _mode = KtStrings.loanPaymentModes.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _id = LoanEmiService.createRequestId();
    final record = widget.record;
    final start = ktParseDate(record.startDate)!;
    if (_date.isBefore(start)) _date = start;
    final interest = record.outstanding * record.annualRate / 1200;
    _interest.text = interest.toStringAsFixed(2);
    _principal.text = (record.monthlyEmi - interest)
        .clamp(0, record.outstanding)
        .toStringAsFixed(2);
  }

  @override
  void dispose() {
    _principal.dispose();
    _interest.dispose();
    _remarks.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_date.isBefore(ktParseDate(widget.record.startDate)!)) {
      ktShowCustomToast(context, KtStrings.invalidLoanPaymentDate);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.service.recordPayment(
        LoanEmiPayment(
          id: _id,
          loanId: widget.record.id!,
          paymentDate: ktFormatDate(_date),
          principalPaid: double.parse(_principal.text.trim()),
          interestPaid: double.parse(_interest.text.trim()),
          paymentMode: _mode,
          remarks: _remarks.text.trim(),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) ktShowCustomToast(context, KtStrings.saveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0F172A) : Colors.white;
    return PopScope(
      canPop: !_saving,
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black12),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              12,
              24,
              MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '${widget.record.lender} • ${widget.record.accountNumber}',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${KtStrings.principalOutstandingLabel}: ${_currency(widget.record.outstanding)}',
                    style: const TextStyle(
                      color: ktRose,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final principal in [true, false])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: principal ? _principal : _interest,
                        enabled: !_saving,
                        style: const TextStyle(
                          color: ktEmerald,
                          fontWeight: FontWeight.w800,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              principal
                                  ? KtStrings.principalPaidLabel
                                  : KtStrings.interestPaidLabel,
                          prefixIcon: const Icon(
                            Icons.currency_rupee_rounded,
                            color: ktCcEmiPrimary,
                          ),
                          filled: true,
                          fillColor: isDark ? ktCardBg : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? ktBorderWhite10 : Colors.black12,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (text) {
                          final value = double.tryParse(text?.trim() ?? '');
                          if (value == null || !value.isFinite || value < 0) {
                            return KtStrings.invalidLoanNumber;
                          }
                          if (principal &&
                              (value <= 0 ||
                                  value > widget.record.outstanding + 0.005)) {
                            return KtStrings.loanPaymentInvalid;
                          }
                          return null;
                        },
                      ),
                    ),
                  Text(
                    '${KtStrings.paymentAmountLabel}: ${_currency((double.tryParse(_principal.text) ?? 0) + (double.tryParse(_interest.text) ?? 0))}',
                    style: const TextStyle(
                      color: ktEmerald,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed:
                        _saving
                            ? null
                            : () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate:
                                    ktParseDate(widget.record.startDate)!,
                                lastDate: DateTime(2200),
                              );
                              if (picked != null && mounted) {
                                setState(() => _date = picked);
                              }
                            },
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: Text(
                      '${KtStrings.paymentDate}: ${ktFormatDate(_date)}',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _mode,
                    dropdownColor: isDark ? ktSlate800 : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      labelText: KtStrings.paymentModeLabel,
                      filled: true,
                      fillColor: isDark ? ktCardBg : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? ktBorderWhite10 : Colors.black12,
                        ),
                      ),
                    ),
                    items:
                        KtStrings.loanPaymentModes
                            .map(
                              (mode) => DropdownMenuItem(
                                value: mode,
                                child: Text(mode),
                              ),
                            )
                            .toList(),
                    onChanged:
                        _saving
                            ? null
                            : (mode) {
                              if (mode != null) setState(() => _mode = mode);
                            },
                  ),
                  TextFormField(
                    controller: _remarks,
                    enabled: !_saving,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: KtStrings.remarksOptional,
                      filled: true,
                      fillColor: isDark ? ktCardBg : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? ktBorderWhite10 : Colors.black12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ktCcEmiPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    icon:
                        _saving
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.payment_rounded),
                    label: const Text(KtStrings.recordPayment),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
