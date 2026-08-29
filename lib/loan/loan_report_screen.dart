import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ktppsflutter/core_constants.dart';
import 'loan_models.dart';
import 'loan_service.dart';
import 'loan_screen.dart';

class LoanReportScreen extends StatefulWidget {
  const LoanReportScreen({super.key});

  @override
  State<LoanReportScreen> createState() => _LoanReportScreenState();
}

class _LoanReportScreenState extends State<LoanReportScreen> {
  final LoanService _service = LoanService();
  List<LoanRecord> _allLoans = [];
  bool _loading = false;

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

    return Scaffold(
      backgroundColor: const Color(0xFF030305),
      body: Stack(
        children: [
          const _GridBackground(),
          const _BackgroundOrbs(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDesktop),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchData,
                    color: ktPrimary,
                    backgroundColor: const Color(0xFF1E1B4B),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? width * 0.05 : 16, vertical: 16),
                      child: Column(
                        children: [
                          _buildSummaryCards(isDesktop),
                          const SizedBox(height: 24),
                          if (_loading && _allLoans.isEmpty)
                            _buildSkeletons()
                          else if (_allLoans.isEmpty && !_loading)
                            _buildEmptyState()
                          else
                            _buildLoanGrid(isDesktop),
                          const SizedBox(height: 100),
                        ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Loan Report', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text('Track lending and borrowing history', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const Spacer(),
          _buildHeaderAction(Icons.refresh, _fetchData),
          const SizedBox(width: 8),
          _buildHeaderAction(Icons.add, () => Navigator.pushNamed(context, '/loan').then((_) => _fetchData())),
          const SizedBox(width: 8),
          _buildHeaderAction(Icons.home, () => Navigator.popUntil(context, (route) => route.isFirst)),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        child: Icon(icon, color: ktTextGray400, size: 18),
      ),
    );
  }

  Widget _buildSummaryCards(bool isDesktop) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 3 : 1,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isDesktop ? 2.8 : 4.0,
      children: [
        _SummaryCard(title: 'Total Loan Amount', value: '₹${NumberFormat('#,##,###').format(_totalLoan)}', icon: Icons.account_balance, color: Colors.indigoAccent),
        _SummaryCard(title: 'Total Paid', value: '₹${NumberFormat('#,##,###').format(_totalPaid)}', icon: Icons.payments, color: Colors.tealAccent),
        _SummaryCard(title: 'Total Balance', value: '₹${NumberFormat('#,##,###').format(_totalBalance)}', icon: Icons.hourglass_empty, color: Colors.orangeAccent),
      ],
    );
  }

  Widget _buildLoanGrid(bool isDesktop) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: isDesktop ? 520 : 480,
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
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _RepaymentHistorySheet(loan: loan, service: _service),
    );
  }

  void _showRecordPayment(LoanRecord loan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _RecordPaymentSheet(loan: loan, service: _service, onSaved: _fetchData),
    );
  }

  Widget _buildEmptyState() {
    return Column(children: [const SizedBox(height: 60), Icon(Icons.receipt_long_outlined, size: 64, color: Colors.white10), const SizedBox(height: 16), const Text('No loans found', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))]);
  }

  Widget _buildSkeletons() {
    return Column(children: List.generate(3, (i) => Container(height: 200, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24)))));
  }
}

class _SummaryCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF151A25), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(title, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final LoanRecord loan;
  final VoidCallback onViewHistory, onRecordPayment, onEdit;
  const _LoanCard({required this.loan, required this.onViewHistory, required this.onRecordPayment, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final perc = loan.amount > 0 ? (loan.paid / loan.amount) * 100 : 0.0;
    final isClosed = loan.status == 'Closed';
    final tenureParts = loan.tenure.split(' ');
    final tenureVal = double.tryParse(tenureParts[0])?.toInt() ?? 0;
    
    // Simple EMI Estimate (from original web logic)
    final totalInterest = (loan.amount * loan.interestRate * tenureVal) / 1200;
    final emi = tenureVal > 0 ? (loan.amount + totalInterest) / tenureVal : 0.0;
    final emisPaid = emi > 0 ? (loan.paid / emi).floor() : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151A25).withValues(alpha: isClosed ? 0.6 : 1.0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(loan.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(loan.date, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ])),
                      _Badge(label: loan.type, color: loan.type == 'Given' ? Colors.teal : Colors.redAccent),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildStatGrid(loan, emi, emisPaid, tenureVal),
                  const SizedBox(height: 20),
                  _buildProgressBar(perc, loan.paid, loan.amount, isClosed),
                  const SizedBox(height: 16),
                  if (loan.remarks.isNotEmpty)
                    Text(loan.remarks, style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Balance', style: TextStyle(color: Colors.white38, fontSize: 10)),
                Text('₹${NumberFormat('#,##,###').format(loan.amount - loan.paid)}', style: TextStyle(color: isClosed ? Colors.white24 : Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              ])),
              _IconBtn(icon: Icons.history, onTap: onViewHistory),
              const SizedBox(width: 8),
              _IconBtn(icon: Icons.payments_outlined, color: Colors.tealAccent, onTap: onRecordPayment),
              const SizedBox(width: 8),
              _IconBtn(icon: Icons.edit_note, onTap: onEdit),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(LoanRecord loan, double emi, int emisPaid, int tenure) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _StatItem(label: 'Interest Rate', value: '${loan.interestRate}%'),
        _StatItem(label: 'Tenure', value: loan.tenure),
        _StatItem(label: 'EMI Amount', value: '₹${NumberFormat('#,###').format(emi)}'),
        _StatItem(label: 'EMIs Paid', value: '$emisPaid / $tenure'),
      ],
    );
  }

  Widget _buildProgressBar(double perc, double paid, double total, bool isClosed) {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('₹${NumberFormat('#,###').format(paid)} / ₹${NumberFormat('#,###').format(total)}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          Text('${perc.toStringAsFixed(0)}%', style: TextStyle(color: isClosed ? Colors.grey : Colors.indigoAccent, fontSize: 11, fontWeight: FontWeight.w900)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(value: perc / 100, minHeight: 8, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation(isClosed ? Colors.grey : Colors.indigoAccent)),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _Badge extends StatelessWidget {
  final String label; final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))), child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon; final Color? color; final VoidCallback onTap;
  const _IconBtn({required this.icon, this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: color?.withValues(alpha: 0.1) ?? Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: color?.withValues(alpha: 0.3) ?? Colors.white.withValues(alpha: 0.1))), child: Icon(icon, color: color ?? Colors.white70, size: 18)));
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
              const Text('Repayment History', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(widget.loan.name, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ]),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white38)),
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
                      color: isDone ? Colors.tealAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDone ? Colors.tealAccent.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(DateFormat('MMM').format(date), style: TextStyle(color: isDone ? Colors.tealAccent : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${date.year}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      const SizedBox(height: 4),
                      Text(status.status.toUpperCase(), style: TextStyle(color: isDone ? Colors.tealAccent : Colors.white24, fontSize: 8, fontWeight: FontWeight.w900)),
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
    catch (e) { try { return DateTime.parse(dateStr); } catch (e) { return DateTime.now(); } }
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
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Record Payment', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(widget.loan.name, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 24),
          _buildInput('Amount', _amountController, Icons.currency_rupee, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildDropdown('Payment Type', _type, ['Principal', 'Full Settlement', 'Interest', 'EMI'], Icons.money_outlined, (v) => setState(() => _type = v!)),
          const SizedBox(height: 16),
          _buildDatePicker(),
          const SizedBox(height: 16),
          _buildInput('Remarks (Optional)', _remarksController, Icons.notes, maxLines: 2),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: ktPrimary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Record Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: const Color(0x33000000), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: TextField(controller: ctrl, keyboardType: keyboardType, maxLines: maxLines, style: const TextStyle(color: Colors.white), decoration: InputDecoration(icon: Icon(icon, color: Colors.white24, size: 18), border: InputBorder.none)),
      )
    ]);
  }

  Widget _buildDropdown(String label, String value, List<String> opts, IconData icon, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: const Color(0x33000000), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, dropdownColor: const Color(0xFF1E293B), items: opts.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(), onChanged: onChanged)),
      )
    ]);
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
        if (d != null) setState(() => _date = d);
      },
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Payment Date', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 56, padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: const Color(0x33000000), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
          child: Row(children: [const Icon(Icons.calendar_today, color: Colors.white24, size: 18), const SizedBox(width: 16), Text(DateFormat('dd/MMM/yyyy').format(_date), style: const TextStyle(color: Colors.white))]),
        )
      ]),
    );
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amountController.text);
    if (amt == null || amt <= 0) return;
    setState(() => _loading = true);
    final ok = await widget.service.addTransaction(widget.loan.id!, amt, DateFormat('dd/MMM/yyyy').format(_date), _type, _remarksController.text);
    if (ok) {
      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
      }
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
