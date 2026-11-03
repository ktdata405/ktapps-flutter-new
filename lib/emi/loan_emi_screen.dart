import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../core_constants.dart';
import '../core_ui_utils.dart';
import '../core_utils.dart';
import 'emi_screen.dart';
import 'emi_ui.dart';
import 'loan_emi_models.dart';
import 'loan_emi_service.dart';

class LoanEmiScreen extends StatefulWidget {
  const LoanEmiScreen({super.key, this.editRecord, this.embedded = false});
  final LoanEmiRecord? editRecord;
  final bool embedded;

  @override
  State<LoanEmiScreen> createState() => _LoanEmiScreenState();
}

class _LoanEmiScreenState extends State<LoanEmiScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _service = LoanEmiService();
  final _lender = TextEditingController();
  final _account = TextEditingController();
  final _principal = TextEditingController();
  final _rate = TextEditingController(text: '0');
  final _tenure = TextEditingController(text: '12');
  final _fee = TextEditingController(text: '0');
  final _remarks = TextEditingController();
  final _details = {
    for (final field in LoanDetailField.values) field: TextEditingController(),
  };
  late DateTime _startDate;
  late DateTime _firstEmiDate;
  late final String _requestId;
  EmiLoanType _type = EmiLoanType.home;
  bool _saving = false;

  bool get _locked => widget.editRecord?.payments.isNotEmpty ?? false;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _requestId = LoanEmiService.createRequestId();
    _startDate = getIndiaTime();
    _firstEmiDate = DateTime(_startDate.year, _startDate.month + 1, 5);
    final record = widget.editRecord;
    if (record != null) {
      _type = record.type;
      _lender.text = record.lender;
      _account.text = record.accountNumber;
      _principal.text = formatIndianAmount(record.principal);
      _rate.text = record.annualRate.toString();
      _tenure.text = record.tenureMonths.toString();
      _fee.text = formatIndianAmount(record.processingFee);
      _remarks.text = record.remarks;
      _startDate = ktParseDate(record.startDate)!;
      _firstEmiDate = ktParseDate(record.firstEmiDate)!;
      for (final field in record.type.fields) {
        _details[field]!.text = record.details[field.key] ?? '';
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _lender,
      _account,
      _principal,
      _rate,
      _tenure,
      _fee,
      _remarks,
      ..._details.values,
    ]) {
      controller.dispose();
    }
    _service.dispose();
    super.dispose();
  }

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.replaceAll(',', '').trim()) ?? 0;

  void _clearForm() {
    if (_locked) return;
    _formKey.currentState?.reset();
    for (final controller in [
      _lender,
      _account,
      _principal,
      _rate,
      _tenure,
      _fee,
      _remarks,
      ..._details.values,
    ]) {
      controller.clear();
    }
    setState(() {
      _type = EmiLoanType.home;
      _rate.text = '0';
      _tenure.text = '12';
      _fee.text = '0';
      _startDate = getIndiaTime();
      _firstEmiDate = DateTime(_startDate.year, _startDate.month + 1, 5);
    });
  }

  String? _validateNumber(String? text, {bool positive = false}) {
    final value = double.tryParse((text ?? '').replaceAll(',', '').trim());
    if (value == null ||
        !value.isFinite ||
        value < 0 ||
        (positive && value == 0)) {
      return positive
          ? KtStrings.invalidLoanPositive
          : KtStrings.invalidLoanNumber;
    }
    return null;
  }

  LoanEmiRecord _record() => LoanEmiRecord(
    id: widget.editRecord?.id,
    type: _type,
    lender: _lender.text.trim(),
    accountNumber: _account.text.trim(),
    startDate: ktFormatDate(_startDate),
    firstEmiDate: ktFormatDate(_firstEmiDate),
    principal: _number(_principal),
    annualRate: _number(_rate),
    tenureMonths: int.tryParse(_tenure.text.trim()) ?? 0,
    processingFee: _number(_fee),
    details: {
      for (final field in _type.fields)
        field.key:
            field.numeric
                ? _number(_details[field]!).toString()
                : _details[field]!.text.trim(),
    },
    remarks: _remarks.text.trim(),
    payments: widget.editRecord?.payments ?? const [],
  );

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_firstEmiDate.isBefore(
      DateTime(_startDate.year, _startDate.month, _startDate.day),
    )) {
      ktShowCustomToast(context, KtStrings.invalidFirstEmiDate);
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.saveRecord(_record(), requestId: _requestId);
      if (!mounted) return;
      ktShowCustomToast(context, KtStrings.loanEmiSaved);
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) ktShowCustomToast(context, KtStrings.saveFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate(bool firstEmi) async {
    final date = firstEmi ? _firstEmiDate : _startDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked != null && mounted) {
      setState(() {
        if (firstEmi) {
          _firstEmiDate = picked;
        } else {
          _startDate = picked;
        }
      });
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool numeric = false,
    bool positive = false,
    bool enabled = true,
    bool required = true,
    bool currency = false,
    bool digitsOnly = false,
    IconData? inputIcon,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icon =
        inputIcon ??
        (numeric ? Icons.numbers_rounded : Icons.edit_note_rounded);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(label, icon, isDark),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: enabled && !_saving,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
            keyboardType:
                numeric
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
            inputFormatters: [
              if (currency) const IndianAmountInputFormatter(),
              if (digitsOnly) FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: emiInputDecoration(
              isDark: isDark,
              icon: icon,
              hint: label,
            ),
            onChanged: (_) => setState(() {}),
            validator:
                validator ??
                (text) =>
                    numeric
                        ? _validateNumber(text, positive: positive)
                        : required && (text == null || text.trim().isEmpty)
                        ? KtStrings.requiredLoanField
                        : null,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label, IconData icon, bool isDark) => Row(
    children: [
      Icon(icon, size: 16, color: ktCcEmiPrimary),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      ),
    ],
  );

  Widget _liveDetails(bool isDark) {
    final record = _record();
    final currency = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );
    Widget metric(String label, String value) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
    return Container(
      key: const ValueKey('loan-live-details'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: emiCalculationGradient(isDark),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: ktCcEmiPrimary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _type.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const Icon(
                Icons.analytics_rounded,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            KtStrings.monthlyEmiLabel,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              currency.format(record.monthlyEmi),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            '${KtStrings.tenureMonthsLabel}: ${record.tenureMonths}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: metric(
                  KtStrings.totalInterestLabel,
                  currency.format(record.totalInterest),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: metric(
                  KtStrings.processingFeeLabel,
                  currency.format(record.processingFee),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: metric(
                  KtStrings.loanPrincipalLabel,
                  currency.format(record.principal),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: metric(
                  KtStrings.totalPayableLabel,
                  currency.format(record.totalPayable),
                ),
              ),
            ],
          ),
          if (record.tenureMonths > 0 && record.tenureMonths <= 600) ...[
            const SizedBox(height: 12),
            metric(
              KtStrings.loanEstimatedCompletion,
              ktFormatDate(record.dueDate(record.tenureMonths)),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            KtStrings.loanEmiEstimate,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? ktBgDark : const Color(0xFFF8FAFC),
      appBar:
          widget.embedded
              ? null
              : AppBar(
                automaticallyImplyLeading: false,
                title: Text(
                  widget.editRecord == null
                      ? KtStrings.addLoanEmi
                      : KtStrings.editLoanEmi,
                ),
                actions: [
                  IconButton(
                    tooltip: KtStrings.emiReportTitle,
                    icon: const Icon(
                      Icons.assessment_rounded,
                      color: ktCcEmiPrimary,
                    ),
                    onPressed:
                        _saving
                            ? null
                            : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const EmiScreen(
                                      report: true,
                                      initialTab: 1,
                                    ),
                              ),
                            ),
                  ),
                ],
              ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _liveDetails(isDark),
                  const SizedBox(height: 24),
                  if (_locked)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: Text(KtStrings.loanTermsLocked),
                    ),
                  _sectionHeader(
                    KtStrings.loanTypeLabel,
                    Icons.account_balance_rounded,
                    isDark,
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    key: const ValueKey('loan-type-chips'),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final type in EmiLoanType.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                type.label,
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
                              backgroundColor: isDark ? ktCardBg : Colors.white,
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
                              onSelected:
                                  _locked || _saving
                                      ? null
                                      : (_) => setState(() => _type = type),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _field(KtStrings.lenderLabel, _lender)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          KtStrings.loanAccountLabel,
                          _account,
                          numeric: true,
                          digitsOnly: true,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          KtStrings.loanPrincipalLabel,
                          _principal,
                          numeric: true,
                          positive: true,
                          enabled: !_locked,
                          inputIcon: Icons.currency_rupee_rounded,
                          currency: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          KtStrings.interestRateLabel,
                          _rate,
                          numeric: true,
                          enabled: !_locked,
                          inputIcon: Icons.percent_rounded,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _field(
                          KtStrings.tenureMonthsLabel,
                          _tenure,
                          numeric: true,
                          enabled: !_locked,
                          validator: (text) {
                            final value = int.tryParse(text?.trim() ?? '');
                            return value == null || value < 1 || value > 600
                                ? KtStrings.invalidLoanTenure
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          KtStrings.processingFeeLabel,
                          _fee,
                          numeric: true,
                          enabled: !_locked,
                          currency: true,
                        ),
                      ),
                    ],
                  ),
                  for (final first in [false, true])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionHeader(
                            first
                                ? KtStrings.firstEmiDateLabel
                                : KtStrings.loanStartDate,
                            Icons.calendar_today_rounded,
                            isDark,
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap:
                                _locked || _saving
                                    ? null
                                    : () => _pickDate(first),
                            borderRadius: BorderRadius.circular(16),
                            child: InputDecorator(
                              decoration: emiInputDecoration(
                                isDark: isDark,
                                icon: Icons.event_note_rounded,
                              ).copyWith(enabled: !_locked && !_saving),
                              child: Text(
                                ktFormatDate(
                                  first ? _firstEmiDate : _startDate,
                                ),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  for (final field in _type.fields)
                    _field(
                      field.label,
                      _details[field]!,
                      numeric: field.numeric,
                      positive: field.numeric,
                      enabled: !_locked,
                      validator:
                          field == LoanDetailField.goldPurity
                              ? (text) {
                                final value = double.tryParse(text ?? '');
                                return value == null ||
                                        !value.isFinite ||
                                        value <= 0 ||
                                        value > 24
                                    ? KtStrings.invalidGoldPurity
                                    : null;
                              }
                              : null,
                    ),
                  _field(KtStrings.remarksOptional, _remarks, required: false),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _saving || _locked ? null : _clearForm,
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  isDark ? Colors.white : ktCcEmiPrimary,
                              side: BorderSide(
                                color:
                                    isDark
                                        ? ktBorderWhite10
                                        : ktCcEmiPrimary.withValues(
                                          alpha: 0.45,
                                        ),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Clear',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ktCcEmiPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
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
                                    : const Icon(Icons.save_rounded),
                            label: const Text('Save'),
                          ),
                        ),
                      ),
                    ],
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
