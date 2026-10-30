import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core_utils.dart';
import '../core_ui_utils.dart';
import 'package:ktppsflutter/core_constants.dart';
import 'loan_models.dart';
import 'loan_service.dart';
import 'loan_screen.dart';


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

class LoanReportScreen extends StatefulWidget {
  const LoanReportScreen({super.key});

  @override
  State<LoanReportScreen> createState() => _LoanReportScreenState();
}

class _LoanReportScreenState extends State<LoanReportScreen> {
  final LoanService _service = LoanService();
  List<LoanRecord> _allLoans = [];
  bool _loading = false;


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
    final loans = await _service.fetchLoans();
    if (!mounted) return;
    setState(() {
      _allLoans = loans;
      _loading = false;
    });
  }

  double get _totalLoan => _allLoans.fold(0.0, (sum, l) => sum + l.amount);
  double get _totalPaid => _allLoans.fold(0.0, (sum, l) => sum + l.paid);
  double get _totalBalance => _totalLoan - _totalPaid;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ktDarkBg : Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (isDark) const _GridBackground(),
          if (isDark) const _BackgroundOrbs(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDesktop),
                Expanded(
                  child: _loading && _allLoans.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: ktPrimary))
                      : RefreshIndicator(
                          onRefresh: _fetchData,
                          color: ktPrimary,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 16),
                            child: Center(
                              child: Container(
                                constraints: BoxConstraints(maxWidth: isDesktop ? 1100 : double.infinity),
                                child: Column(
                                  children: [
                                    _buildSummaryCards(isDesktop),
                                    const SizedBox(height: 24),
                                    if (_allLoans.isEmpty && !_loading)
                                      _buildEmptyState()
                                    else
                                      _buildLoanGrid(isDesktop),
                                    const SizedBox(height: 100),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (_loading && _allLoans.isNotEmpty)
            const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(backgroundColor: Colors.transparent, color: ktPrimary)),
        ],
      ),
    );
  }


  Widget _buildHeader(bool isDesktop) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back, color: textColor)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                KtStrings.loanReport,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                KtStrings.loanReportSubtitle,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          _reportHeaderIcon(Icons.refresh, _fetchData),
          const SizedBox(width: 8),
          _reportHeaderIcon(Icons.add, () => Navigator.pushNamed(context, '/loan').then((_) => _fetchData())),
          const SizedBox(width: 8),
          _reportHeaderIcon(Icons.home, () => Navigator.popUntil(context, (route) => route.isFirst)),
        ],
      ),
    );
  }


  Widget _buildSummaryCards(bool isDesktop) {
    return _LoanProgressSummary(
      totalLoan: _totalLoan,
      totalPaid: _totalPaid,
      totalBalance: _totalBalance,
      isDesktop: isDesktop,
    );
  }

  Widget _buildLoanGrid(bool isDesktop) {
    final width = MediaQuery.of(context).size.width;
    int crossAxisCount = 1;
    if (width > 1050) {
      crossAxisCount = 3;
    } else if (width > 680) {
      crossAxisCount = 2;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: isDesktop ? 200 : 175,
      ),
      itemCount: _allLoans.length,
      itemBuilder: (context, index) {
        final loan = _allLoans[index];

        return _LoanCard(
          loan: loan,
          onViewHistory: () => _showRepaymentHistory(loan),
          onRecordPayment: () => _showRecordPayment(loan),
          onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoanScreen(editRecord: loan))).then((v) { if (v == true) _fetchData(); }),
        );
      },
    );

  }




  void _showRepaymentHistory(LoanRecord loan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _reportColor(context, ktSlateBg, surface: true),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _RepaymentHistorySheet(loan: loan, service: _service),
    );
  }

  void _showRecordPayment(LoanRecord loan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _reportColor(context, ktSlateBg, surface: true),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _RecordPaymentSheet(loan: loan, service: _service, onSaved: _fetchData),
    );
  }

  Widget _buildEmptyState() {
    return Column(children: [const SizedBox(height: 60), Icon(Icons.receipt_long_outlined, size: 64, color: _reportColor(context, ktWhite10, border: true)), const SizedBox(height: 16), Text(KtStrings.noLoansFound, style: TextStyle(color: _reportColor(context, Colors.grey), fontWeight: FontWeight.bold))]);
  }

  Widget _buildSkeletons() {
    return Column(children: List.generate(3, (i) => Container(height: 200, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: _reportColor(context, Colors.white).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24)))));
  }
}

class _LoanProgressSummary extends StatelessWidget {
  final double totalLoan;
  final double totalPaid;
  final double totalBalance;
  final bool isDesktop;

  const _LoanProgressSummary({
    required this.totalLoan,
    required this.totalPaid,
    required this.totalBalance,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final paidPerc = totalLoan > 0 ? (totalPaid / totalLoan) : 0.0;
    final unpaidPerc = 1.0 - paidPerc;
    final fmt = NumberFormat('#,##,###');

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ktDarkCardBg : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CompactMetric(label: 'TOTAL LOAN', value: '₹${fmt.format(totalLoan)}', color: Colors.indigoAccent),
              _CompactMetric(label: 'TOTAL PAID', value: '₹${fmt.format(totalPaid)}', color: Colors.tealAccent),
              _CompactMetric(label: 'TOTAL BALANCE', value: '₹${fmt.format(totalBalance)}', color: Colors.orangeAccent),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('${(paidPerc * 100).toStringAsFixed(0)}% PAID',
                  style: TextStyle(color: _reportColor(context, Colors.tealAccent), fontSize: 9, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 6,
                    child: LinearProgressIndicator(
                      value: paidPerc,
                      backgroundColor: Colors.orangeAccent.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation(Colors.tealAccent),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(unpaidPerc * 100).toStringAsFixed(0)}% UNPAID',
                  style: TextStyle(color: _reportColor(context, Colors.orangeAccent), fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactMetric extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CompactMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: _reportColor(context, ktWhite.withValues(alpha: 0.4)), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: _reportColor(context, color), fontSize: 16, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _LoanCard extends StatelessWidget {
  final LoanRecord loan;
  final VoidCallback onViewHistory, onRecordPayment, onEdit;
  const _LoanCard({required this.loan, required this.onViewHistory, required this.onRecordPayment, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final perc = loan.amount > 0 ? (loan.paid / loan.amount) * 100 : 0.0;
    final isClosed = loan.status == 'Closed';
    final tenureParts = loan.tenure.split(' ');
    final tenureVal = double.tryParse(tenureParts[0])?.toInt() ?? 0;
    
    // Simple EMI Estimate (from original web logic)
    final totalInterest = (loan.amount * loan.interestRate * tenureVal) / 1200;
    final emi = tenureVal > 0 ? (loan.amount + totalInterest) / tenureVal : 0.0;
    final emisPaid = emi > 0 ? (loan.paid / emi).floor() : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: (isDark ? ktDarkCardBg : Theme.of(context).colorScheme.surface).withValues(alpha: isClosed ? 0.8 : 1.0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withValues(alpha: 0.08)),
      ),
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
                    Text(loan.name, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(ktFormatDate(ktParseDate(loan.date) ?? getIndiaTime()), style: TextStyle(color: _reportColor(context, ktWhite38), fontSize: 10)),
                  ],
                ),
              ),
              _Badge(label: loan.type, color: loan.type == 'Given' ? Colors.teal : Colors.redAccent),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatGrid(loan, emi, emisPaid, tenureVal),
          if (loan.remarks.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text("Remarks: ${loan.remarks}", style: TextStyle(color: _reportColor(context, ktAmber500), fontSize: 10, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(KtStrings.balance, style: TextStyle(color: _reportColor(context, ktWhite38), fontSize: 9)),
                    Text('₹${NumberFormat('#,##,###').format(loan.amount - loan.paid)}', style: TextStyle(color: _reportColor(context, isClosed ? _reportColor(context, ktWhite24) : _reportColor(context, ktWhite)), fontSize: 14, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              _IconBtn(icon: Icons.history, onTap: onViewHistory),
              const SizedBox(width: 4),
              _IconBtn(icon: Icons.payments_outlined, color: Colors.tealAccent, onTap: onRecordPayment),
              const SizedBox(width: 4),
              _IconBtn(icon: Icons.edit_note, onTap: onEdit),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  final pendingAmount = loan.amount - loan.paid;
                  ktShowDetailsSheet(
                    context: context,
                    title: 'Loan Breakup Insights',
                    icon: Icons.pie_chart_outline_rounded,
                    themeColor: ktPrimary,
                    subtitle: loan.name,
                    details: [
                      {
                        'label': 'TOTAL PRINCIPAL',
                        'value': '₹${NumberFormat('#,##,###').format(loan.amount)}',
                        'color': _reportColor(context, ktWhite),
                      },
                      {
                        'label': 'TOTAL PAID BACK',
                        'value': '₹${NumberFormat('#,##,###').format(loan.paid)}',
                        'color': _reportColor(context, ktEmerald),
                      },
                      {
                        'label': 'OUTSTANDING BALANCE',
                        'value': '₹${NumberFormat('#,##,###').format(pendingAmount)}',
                        'color': _reportColor(context, ktRose),
                      },
                      {
                        'label': 'COMPLETION PERCENT',
                        'value': '${perc.toStringAsFixed(1)}%',
                        'color': _reportColor(context, ktCyan),
                      },
                    ],
                  );
                },
                child: _buildCircleProgress(context, perc, isClosed),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildCircleProgress(BuildContext context, double perc, bool isClosed) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: perc / 100,
            strokeWidth: 3.5,
            backgroundColor: _reportColor(context, Colors.white10),
            valueColor: AlwaysStoppedAnimation(isClosed ? Colors.grey : ktPrimary),
          ),
          Text(
            '${perc.toStringAsFixed(0)}%',
            style: TextStyle(color: _reportColor(context, Colors.white), fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }



  Widget _buildStatGrid(LoanRecord loan, double emi, int emisPaid, int tenure) {
    return Column(
      children: [
        Row(
          children: [
            _CompactStat(label: 'ROI', value: '${loan.interestRate}%', color: ktCyan),
            _CompactStat(label: 'Tenure', value: loan.tenure.split(' ')[0], color: ktOrange),
            _CompactStat(label: 'EMI', value: NumberFormat('#,###').format(emi), color: ktPrimary),
            _CompactStat(label: 'EMI-Paid', value: '$emisPaid/$tenure', color: ktEmerald),
          ],
        ),
      ],
    );
  }
}


class _CompactStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CompactStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(color: _reportColor(context, ktTextGray400), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(color: _reportColor(context, color), fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}


class _Badge extends StatelessWidget {
  final String label; final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.3))), child: Text(label, style: TextStyle(color: _reportColor(context, color), fontSize: 8, fontWeight: FontWeight.bold)));
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon; final Color? color; final VoidCallback onTap;
  const _IconBtn({required this.icon, this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: Container(width: 32, height: 32, decoration: BoxDecoration(color: color?.withValues(alpha: 0.1) ?? _reportColor(context, Colors.white).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: color?.withValues(alpha: 0.3) ?? _reportColor(context, Colors.white).withValues(alpha: 0.1))), child: Icon(icon, color: color ?? _reportColor(context, Colors.white70), size: 16)));
  }
}


class _RepaymentHistorySheet extends StatefulWidget {
  final LoanRecord loan;
  final LoanService service;
  const _RepaymentHistorySheet({required this.loan, required this.service});

  @override
  State<_RepaymentHistorySheet> createState() => _RepaymentHistorySheetState();
}

class _RepaymentHistorySheetState extends State<_RepaymentHistorySheet> {
  List<RepaymentStatus> _history = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _loading = true);
    final data = await widget.service.getRepaymentStatus(widget.loan.id!);
    if (!mounted) return;
    setState(() { _history = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final tenureParts = widget.loan.tenure.split(' ');
    final tenure = int.tryParse(tenureParts[0]) ?? 0;
    final startDate = _parseDate(widget.loan.date);

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(KtStrings.repaymentHistory, style: TextStyle(color: _reportColor(context, ktWhite), fontSize: 20, fontWeight: FontWeight.bold)),
              Text(widget.loan.name, style: TextStyle(color: _reportColor(context, ktWhite38), fontSize: 12)),
            ]),
            IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: _reportColor(context, ktWhite38))),
          ]),
          const SizedBox(height: 24),
          if (_loading) const Center(child: CircularProgressIndicator())
          else ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.2),
              itemCount: tenure,
              itemBuilder: (context, i) {
                final date = DateTime(startDate.year, startDate.month + i);
                final status = _history.firstWhere((h) => h.year == date.year && h.month == date.month, orElse: () => RepaymentStatus(year: date.year, month: date.month, status: 'Pending'));
                final isDone = status.status == 'Done';

                return InkWell(
                  onTap: () => _toggleStatus(status),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDone ? Colors.tealAccent.withValues(alpha: 0.1) : _reportColor(context, ktWhite).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDone ? Colors.tealAccent.withValues(alpha: 0.3) : _reportColor(context, ktWhite).withValues(alpha: 0.05)),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(DateFormat('MMM').format(date), style: TextStyle(color: _reportColor(context, isDone ? Colors.tealAccent : _reportColor(context, ktWhite)), fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${date.year}', style: TextStyle(color: _reportColor(context, ktWhite38), fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(status.status.toUpperCase(), style: TextStyle(color: _reportColor(context, isDone ? Colors.tealAccent : _reportColor(context, ktWhite24)), fontSize: 8, fontWeight: FontWeight.w900)),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(RepaymentStatus current) async {
    final newStatus = current.status == 'Done' ? 'Pending' : 'Done';
    setState(() => _loading = true);
    final ok = await widget.service.updateRepaymentStatus(widget.loan.id!, current.year, current.month, newStatus);
    if (!mounted) return;
    if (ok) {
      _fetchHistory();
    } else {
      setState(() => _loading = false);
    }
  }

  DateTime _parseDate(String dateStr) {
    try { return DateFormat('dd/MMM/yyyy').parse(dateStr); }
    catch (e) { try { return DateTime.parse(dateStr); } catch (e) { return getIndiaTime(); } }
  }
}

class _RecordPaymentSheet extends StatefulWidget {
  final LoanRecord loan;
  final LoanService service;
  final VoidCallback onSaved;
  const _RecordPaymentSheet({required this.loan, required this.service, required this.onSaved});

  @override
  State<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends State<_RecordPaymentSheet> {
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  String _type = 'Principal';
  DateTime _date = getIndiaTime();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(KtStrings.recordPayment, style: TextStyle(color: _reportColor(context, ktWhite), fontSize: 20, fontWeight: FontWeight.bold)),
          Text(widget.loan.name, style: TextStyle(color: _reportColor(context, ktWhite38), fontSize: 12)),
          const SizedBox(height: 24),
          _buildInput(KtStrings.amount, _amountController, Icons.currency_rupee, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildDropdown(KtStrings.paymentType, _type, [KtStrings.principal, KtStrings.fullSettlement, KtStrings.interest, KtStrings.emi], Icons.money_outlined, (v) => setState(() => _type = v!)),
          const SizedBox(height: 16),
          _buildDatePicker(),
          const SizedBox(height: 16),
          _buildInput(KtStrings.remarksOptional, _remarksController, Icons.notes, maxLines: 2),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: ktPrimary,
                foregroundColor: _reportColor(context, Colors.white),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _loading
                  ? CircularProgressIndicator(color: _reportColor(context, ktWhite))
                  : Text(
                      KtStrings.recordPayment,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: _reportColor(context, ktWhite38), fontSize: 11, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: const Color(0x33000000), borderRadius: BorderRadius.circular(16), border: Border.all(color: _reportColor(context, ktWhite10, border: true))),
        child: TextField(controller: ctrl, keyboardType: keyboardType, maxLines: maxLines, style: TextStyle(color: _reportColor(context, ktWhite)), decoration: InputDecoration(icon: Icon(icon, color: _reportColor(context, ktWhite24), size: 18), border: InputBorder.none)),
      )
    ]);
  }

  Widget _buildDropdown(String label, String value, List<String> opts, IconData icon, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: _reportColor(context, ktWhite38), fontSize: 11, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: const Color(0x33000000), borderRadius: BorderRadius.circular(16), border: Border.all(color: _reportColor(context, ktWhite10, border: true))),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, dropdownColor: _reportColor(context, ktSlateBg, surface: true), items: opts.map((e) => DropdownMenuItem(value: e, child: Text(e, style: TextStyle(color: _reportColor(context, ktWhite))))).toList(), onChanged: onChanged)),
      )
    ]);
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: getIndiaTime());
        if (d != null) setState(() => _date = d);
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(KtStrings.paymentDate, style: TextStyle(color: _reportColor(context, ktWhite38), fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0x33000000), borderRadius: BorderRadius.circular(16), border: Border.all(color: _reportColor(context, ktWhite10, border: true))),
          child: Row(children: [Icon(Icons.calendar_today, color: _reportColor(context, ktWhite24), size: 18), const SizedBox(width: 16), Text(ktFormatDate(_date), style: TextStyle(color: _reportColor(context, ktWhite)))]),
        )
      ]),
    );
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amountController.text);
    if (amt == null || amt <= 0) return;
    setState(() => _loading = true);
    final ok = await widget.service.addTransaction(widget.loan.id!, amt, ktFormatDateForSheet(_date), _type, _remarksController.text);
    if (ok) {
      if (mounted) {
        Navigator.pop(context);
      }
      await Future.delayed(const Duration(milliseconds: 600));
      widget.onSaved();
    } else {
      setState(() => _loading = false);
    }
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();
  @override
  Widget build(BuildContext context) { return CustomPaint(size: Size.infinite, painter: _GridPainter()); }
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
    return Stack(children: [
      Positioned(top: -100, left: -100, child: Container(width: 400, height: 400, decoration: BoxDecoration(color: ktPrimary.withValues(alpha: 0.05), shape: BoxShape.circle), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)))),
      Positioned(bottom: -50, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(color: const Color(0xFFEC4899).withValues(alpha: 0.05), shape: BoxShape.circle), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)))),
    ]);
  }
}
