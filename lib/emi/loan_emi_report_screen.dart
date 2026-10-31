import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core_constants.dart';
import '../core_ui_utils.dart';
import '../core_utils.dart';
import 'emi_screen.dart';
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
      builder: (_) => _LoanPaymentSheet(record: record, service: _service),
    );
    if (saved == true && mounted) {
      ktShowCustomToast(context, KtStrings.emiPaymentRecorded);
      await _load();
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
      bodyHeader:
          record.payments.isEmpty
              ? null
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    KtStrings.repaymentSchedule,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  for (final payment in record.payments)
                    ExpansionTile(
                      title: Text(
                        '${payment.paymentDate} - ${_currency(payment.amountPaid)}',
                      ),
                      subtitle: Text(payment.paymentMode),
                      children: [
                        ListTile(
                          title: Text(
                            '${KtStrings.principalPaidLabel}: ${_currency(payment.principalPaid)}',
                          ),
                          subtitle: Text(
                            '${KtStrings.interestPaidLabel}: ${_currency(payment.interestPaid)}\n'
                            '${payment.remarks}',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
      details: [
        {
          'label': KtStrings.principalOutstandingLabel,
          'value': _currency(record.outstanding),
          'isHighlight': true,
        },
        {
          'label': KtStrings.loanPrincipalLabel,
          'value': _currency(record.principal),
        },
        {
          'label': KtStrings.interestRateLabel,
          'value': '${record.annualRate}%',
        },
        {
          'label': KtStrings.tenureMonthsLabel,
          'value': record.tenureMonths.toString(),
        },
        {
          'label': KtStrings.monthlyEmiLabel,
          'value': _currency(record.monthlyEmi),
        },
        {
          'label': KtStrings.processingFeeLabel,
          'value': _currency(record.processingFee),
        },
        {
          'label': KtStrings.totalInterestLabel,
          'value': _currency(record.totalInterest),
        },
        {
          'label': KtStrings.totalPayableLabel,
          'value': _currency(record.totalPayable),
        },
        {'label': KtStrings.loanStartDate, 'value': record.startDate},
        {'label': KtStrings.firstEmiDateLabel, 'value': record.firstEmiDate},
        {
          'label': KtStrings.principalPaidLabel,
          'value': _currency(record.principalPaid),
        },
        {
          'label': KtStrings.interestPaidLabel,
          'value': _currency(record.interestPaid),
        },
        for (final field in record.type.fields)
          {'label': field.label, 'value': record.details[field.key] ?? ''},
        {'label': KtStrings.remarks, 'value': record.remarks},
      ],
      footerNote: KtStrings.loanEmiEstimate,
      actions: [
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
      ],
    );
  }

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
            .toList();
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
                    DropdownButton<EmiLoanType?>(
                      value: _type,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<EmiLoanType?>(
                          value: null,
                          child: Text(KtStrings.allLoanTypes),
                        ),
                        ...EmiLoanType.values.map(
                          (type) => DropdownMenuItem<EmiLoanType?>(
                            value: type,
                            child: Text(type.label),
                          ),
                        ),
                      ],
                      onChanged: (type) => setState(() => _type = type),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final status in [
                          KtStrings.allLoanStatuses,
                          KtStrings.activeText,
                          KtStrings.loanCompleted,
                        ])
                          ChoiceChip(
                            label: Text(status),
                            selected: _status == status,
                            onSelected: (_) => setState(() => _status = status),
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
                      ],
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
                    return _loanTile(record, isDark);
                  }, childCount: records.length),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: ktCcEmiPrimary,
        foregroundColor: Colors.white,
        onPressed: () => _entry(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(KtStrings.addLoanEmi),
      ),
    );
  }

  Widget _loanTile(LoanEmiRecord record, bool isDark) {
    final progress = (record.principalPaid / record.principal).clamp(0.0, 1.0);
    final statusColor = record.isCompleted ? ktEmerald : ktCcEmiPrimary;
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
                  ? [
                    ktCcEmiPrimary.withValues(alpha: 0.25),
                    const Color(0xFF0F172A),
                  ]
                  : [ktCcEmiPrimary.withValues(alpha: 0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: ktCcEmiPrimary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: ktCcEmiPrimary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            Material(
              color: ktCcEmiPrimary.withValues(alpha: 0.2),
              child: InkWell(
                onTap: () => _details(record),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_rounded,
                        color: ktCcEmiPrimary,
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
                              color: textColor,
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
                              color: textColor,
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
                        color: record.isCompleted ? ktEmerald : ktRose,
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
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              KtStrings.recordEmiPaymentTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ktCcEmiPrimary,
              ),
            ),
            Text('${widget.record.lender} - ${widget.record.accountNumber}'),
            Text(
              '${KtStrings.principalOutstandingLabel}: ${_currency(widget.record.outstanding)}',
            ),
            const SizedBox(height: 16),
            for (final principal in [true, false])
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: principal ? _principal : _interest,
                  enabled: !_saving,
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
            ),
            OutlinedButton.icon(
              onPressed:
                  _saving
                      ? null
                      : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: ktParseDate(widget.record.startDate)!,
                          lastDate: DateTime(2200),
                        );
                        if (picked != null && mounted) {
                          setState(() => _date = picked);
                        }
                      },
              icon: const Icon(Icons.calendar_today_rounded),
              label: Text('${KtStrings.paymentDate}: ${ktFormatDate(_date)}'),
            ),
            DropdownButtonFormField<String>(
              value: _mode,
              decoration: const InputDecoration(
                labelText: KtStrings.paymentModeLabel,
              ),
              items:
                  KtStrings.loanPaymentModes
                      .map(
                        (mode) =>
                            DropdownMenuItem(value: mode, child: Text(mode)),
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
              decoration: const InputDecoration(
                labelText: KtStrings.remarksOptional,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ktCcEmiPrimary,
                foregroundColor: Colors.white,
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
  );
}
