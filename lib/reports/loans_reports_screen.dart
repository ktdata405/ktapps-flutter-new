import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/loan_record.dart';
import '../screens/loans_screen.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────
// Loans Report Screen  (converted from loanreport.html)
// ─────────────────────────────────────────────────────────────
class LoansReportsScreen extends StatefulWidget {
  const LoansReportsScreen({super.key});

  @override
  State<LoansReportsScreen> createState() => _LoansReportsScreenState();
}

class _LoansReportsScreenState extends State<LoansReportsScreen> {
  List<LoanRecord> _loans = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final rows = await ApiService.fetchLoans();
      if (!mounted) return;
      setState(() {
        _loans = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String _fmtCurrency(double v) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
          .format(v);

  double get _totalLoan =>
      _loans.fold(0, (s, l) => s + l.amount);
  double get _totalPaid =>
      _loans.fold(0, (s, l) => s + l.paid);
  double get _totalBalance =>
      _loans.fold(0, (s, l) => s + l.balance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        onPressed: () async {
          final ok = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const LoansScreen()),
          );
          if (ok == true) _fetch();
        },
        child: const Icon(Icons.add_rounded),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _loans.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    children: [
                      _summaryRow(),
                      const SizedBox(height: 16),
                      ..._loans.map(_buildLoanCard),
                    ],
                  ),
                ),
    );
  }

  // ── AppBar ──
  AppBar _buildAppBar() => AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(children: [
          const Icon(Icons.savings_rounded,
              color: Color(0xFF818CF8), size: 22),
          const SizedBox(width: 8),
          const Text('Loan Report',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
        ]),
        actions: [
          _navBtn(Icons.add_rounded, 'New Loan', () async {
            final ok = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const LoansScreen()),
            );
            if (ok == true) _fetch();
          }),
          _navBtn(Icons.refresh_rounded, 'Refresh', _fetch),
          _navBtn(Icons.home_rounded, 'Home',
              () => Navigator.of(context).popUntil((r) => r.isFirst)),
          const SizedBox(width: 4),
        ],
      );

  Widget _navBtn(IconData icon, String tip, VoidCallback onTap) => Tooltip(
        message: tip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40, height: 40,
            margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: const Color(0xFF94A3B8), size: 16),
          ),
        ),
      );

  // ── Summary Cards ──
  Widget _summaryRow() => LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth > 500;
        final cards = [
          _summaryCard('Total Loan Amount', _fmtCurrency(_totalLoan),
              Icons.account_balance_rounded, const Color(0xFF6366F1),
              const Color(0x206366F1)),
          _summaryCard('Total Paid', _fmtCurrency(_totalPaid),
              Icons.payments_rounded, const Color(0xFF10B981),
              const Color(0x2010B981)),
          _summaryCard('Total Balance', _fmtCurrency(_totalBalance),
              Icons.timelapse_rounded, const Color(0xFFF43F5E),
              const Color(0x20F43F5E)),
        ];
        return wide
            ? Row(children: [
                for (int i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(child: cards[i]),
                ],
              ])
            : Column(
                children: cards
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: c,
                        ))
                    .toList(),
              );
      });

  Widget _summaryCard(String label, String value, IconData icon,
      Color iconColor, Color iconBg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xB31E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: iconColor.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Loan Card ──
  Widget _buildLoanCard(LoanRecord loan) {
    final accent = loan.isGiven ? const Color(0xFF10B981) : const Color(0xFFF43F5E);
    final accentBg = loan.isGiven
        ? const Color(0x2010B981)
        : const Color(0x20F43F5E);
    final statusColor = switch (loan.status) {
      'Closed' => const Color(0xFF94A3B8),
      'Defaulted' => const Color(0xFFF97316),
      _ => const Color(0xFF818CF8),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xB31E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: loan.isClosed
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Opacity(
        opacity: loan.isClosed ? 0.65 : 1.0,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loan.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(loan.date,
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                ),
                _badge(loan.type, accent, accentBg),
                const SizedBox(width: 6),
                _badge(loan.status, statusColor,
                    statusColor.withValues(alpha: 0.12)),
              ]),

              const SizedBox(height: 14),

              // Metrics grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 3.0,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                children: [
                  _metricTile('Interest Rate', '${loan.interestRate}%'),
                  _metricTile('Tenure', loan.tenureDisplay),
                  _metricTile('EMI Amount',
                      _fmtCurrency(loan.emi)),
                  _metricTile('EMIs Paid',
                      '${loan.emisPaid} / ${loan.tenureMonths}'),
                ],
              ),

              const SizedBox(height: 12),

              // Progress
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_fmtCurrency(loan.paid)} / ${_fmtCurrency(loan.amount)}',
                        style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${(loan.progressPct * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: loan.isClosed
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF818CF8),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: loan.progressPct,
                      backgroundColor: const Color(0xFF374151),
                      color: loan.isClosed
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF6366F1),
                      minHeight: 7,
                    ),
                  ),
                ],
              ),

              // Remarks
              if (loan.remarks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(loan.remarks,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
              ],

              const SizedBox(height: 12),

              // Footer
              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Balance',
                          style: TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 11)),
                      Text(
                        _fmtCurrency(loan.balance),
                        style: TextStyle(
                          color: loan.isClosed
                              ? const Color(0xFF6B7280)
                              : Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(children: [
                  _actionBtn(Icons.history_rounded, 'Repayment History',
                      () => _showRepaymentHistory(loan)),
                  const SizedBox(width: 6),
                  _actionBtn(Icons.payments_rounded, 'Record Payment',
                      () => _showPaymentModal(loan),
                      iconColor: const Color(0xFF34D399),
                      bgColor: const Color(0x2010B981)),
                  const SizedBox(width: 6),
                  _actionBtn(Icons.edit_rounded, 'Edit Loan', () async {
                    final ok = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                          builder: (_) => LoansScreen(editRecord: loan)),
                    );
                    if (ok == true) _fetch();
                  }),
                  const SizedBox(width: 6),
                  _actionBtn(Icons.delete_rounded, 'Delete Loan',
                      () => _deleteLoan(loan),
                      iconColor: const Color(0xFFFB7185),
                      bgColor: const Color(0x20F43F5E)),
                ]),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color textColor, Color bgColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label,
            style: TextStyle(
                color: textColor, fontSize: 11, fontWeight: FontWeight.w700)),
      );

  Widget _metricTile(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF94A3B8), fontSize: 10)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ],
        ),
      );

  Widget _actionBtn(
    IconData icon,
    String tip,
    VoidCallback onTap, {
    Color iconColor = const Color(0xFF94A3B8),
    Color bgColor = const Color(0xFF0F172A),
  }) =>
      Tooltip(
        message: tip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
        ),
      );

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_balance_rounded,
                size: 72, color: Color(0xFF374151)),
            const SizedBox(height: 16),
            const Text('No loans found',
                style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _fetch,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );

  // ── Repayment History Modal ──────────────────────────────────
  Future<void> _showRepaymentHistory(LoanRecord loan) async {
    final repayments = await ApiService.fetchRepaymentStatus(loan.id ?? '');
    if (!mounted) return;

    // Build a map: "YYYY-MM" → status
    final histMap = {
      for (final r in repayments)
        '${r.year}-${r.month.toString().padLeft(2, '0')}': r.status,
    };

    final startDate = _parseDate(loan.date);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (_, controller) => Column(children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Repayment History',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 17)),
                      Text(loan.name,
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white70),
                ),
              ]),
            ),
            const Divider(color: Colors.white12, height: 1),
            // Grid
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: const EdgeInsets.all(16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.85,
                ),
                itemCount: loan.tenureMonths,
                itemBuilder: (_, i) {
                  final d = DateTime(
                      startDate.year,
                      startDate.month + i,
                      1);
                  final key =
                      '${d.year}-${d.month.toString().padLeft(2, '0')}';
                  final status = histMap[key] ?? 'Pending';
                  final isDone = status == 'Done';

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () async {
                      final newStatus =
                          isDone ? 'Pending' : 'Done';
                      await ApiService.updateRepaymentStatus(
                        loan.id ?? '',
                        d.year, d.month, newStatus,
                      );
                      setSheet(() {
                        histMap[key] = newStatus;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isDone
                            ? const Color(0x3010B981)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDone
                              ? const Color(0x8010B981)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMM').format(d),
                            style: TextStyle(
                              color: isDone
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '${d.year}',
                            style: TextStyle(
                              color: isDone
                                  ? const Color(0xFF34D399)
                                      .withValues(alpha: 0.7)
                                  : const Color(0xFF64748B),
                              fontSize: 9,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isDone ? 'DONE' : 'PENDING',
                            style: TextStyle(
                              color: isDone
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF64748B),
                              fontSize: 7,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Close button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ),
          ]),
        );
      }),
    );
  }

  DateTime _parseDate(String s) {
    try {
      return DateFormat('dd/MMM/yyyy').parse(s);
    } catch (_) {
      return DateTime.now();
    }
  }

  // ── Payment Modal ────────────────────────────────────────────
  Future<void> _showPaymentModal(LoanRecord loan) async {
    final dateCtrl = TextEditingController(
        text: DateFormat('dd/MMM/yyyy').format(DateTime.now()));
    final amountCtrl = TextEditingController();
    final remarksCtrl = TextEditingController();
    String payType = 'EMI';
    DateTime payDate = DateTime.now();
    final payFormKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheet) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
            child: Form(
              key: payFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Record Payment',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17)),
                          Text(loan.name,
                              style: const TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // Date
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: payDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setSheet(() {
                          payDate = picked;
                          dateCtrl.text = DateFormat('dd/MMM/yyyy')
                              .format(picked);
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                          labelText: 'Payment Date',
                          prefixIcon:
                              Icon(Icons.calendar_today_rounded)),
                      child: Text(dateCtrl.text,
                          style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Amount
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.currency_rupee_rounded),
                    ),
                    validator: (v) {
                      if ((v ?? '').trim().isEmpty) return 'Required';
                      if (double.tryParse(v!.trim()) == null) {
                        return 'Invalid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Payment type
                  DropdownButtonFormField<String>(
                    value: payType,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: const InputDecoration(
                      labelText: 'Payment Type',
                      prefixIcon: Icon(Icons.payments_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'EMI', child: Text('EMI Payment')),
                      DropdownMenuItem(
                          value: 'Principal',
                          child: Text('Principal Payment')),
                      DropdownMenuItem(
                          value: 'Full Settlement',
                          child: Text('Full Settlement')),
                      DropdownMenuItem(
                          value: 'Interest',
                          child: Text('Interest Payment')),
                    ],
                    onChanged: (v) => setSheet(() => payType = v ?? payType),
                  ),
                  const SizedBox(height: 12),

                  // Remarks
                  TextFormField(
                    controller: remarksCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Remarks (Optional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!payFormKey.currentState!.validate()) {
                                  return;
                                }
                                setSheet(() => saving = true);
                                await ApiService.addLoanPayment({
                                  'loanId': loan.id,
                                  'date': dateCtrl.text,
                                  'amount': double.tryParse(
                                          amountCtrl.text.trim()) ??
                                      0,
                                  'type': payType,
                                  'remarks': remarksCtrl.text.trim(),
                                });
                                if (ctx.mounted) Navigator.pop(ctx);
                                _fetch();
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(saving
                            ? 'Saving...'
                            : 'Record Payment'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      }),
    );
    dateCtrl.dispose();
    amountCtrl.dispose();
    remarksCtrl.dispose();
  }

  // ── Delete Loan ──────────────────────────────────────────────
  Future<void> _deleteLoan(LoanRecord loan) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Loan',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Delete loan for "${loan.name}"? This cannot be undone.',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || loan.id == null) return;
    await ApiService.deleteLoan(loan.id!);
    _fetch();
  }
}

