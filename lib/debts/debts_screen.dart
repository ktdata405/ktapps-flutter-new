import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'debts_models.dart';
import 'debts_service.dart';

class DebtsScreen extends StatefulWidget {
  final DebtRecord? editRecord;
  const DebtsScreen({super.key, this.editRecord});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final DebtsService _service = DebtsService();
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  String _type = 'given';
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editRecord != null) {
      final r = widget.editRecord!;
      _selectedDate = _parseDate(r.date);
      _type = r.type;
      _personController.text = r.person;
      _amountController.text = r.amount.toString();
      _remarksController.text = r.remarks;
    } else {
      _selectedDate = DateTime.now();
    }
  }

  DateTime _parseDate(String dateStr) {
    try {
      return DateFormat('dd/MMM/yyyy').parse(dateStr);
    } catch (e) {
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        return DateTime.now();
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6366F1),
            onPrimary: Colors.white,
            surface: Color(0xFF1E293B),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _clearForm() {
    setState(() {
      if (widget.editRecord == null) {
        _selectedDate = DateTime.now();
        _type = 'given';
        _personController.clear();
        _amountController.clear();
        _remarksController.clear();
      } else {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _submit() async {
    if (_personController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter Person Name')));
      return;
    }
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid Amount')));
      return;
    }

    setState(() => _loading = true);
    final record = DebtRecord(
      id: widget.editRecord?.id,
      date: DateFormat('dd/MMM/yyyy').format(_selectedDate),
      type: _type,
      person: _personController.text,
      amount: amount,
      remarks: _remarksController.text.isEmpty ? '' : _remarksController.text,
      status: widget.editRecord?.status ?? 'pending',
      settleRemarks: widget.editRecord?.settleRemarks ?? '',
    );

    bool success;
    if (widget.editRecord != null) {
      success = await _service.updateRecord(record);
    } else {
      success = await _service.addRecord(record);
    }

    setState(() => _loading = false);
    if (success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.editRecord != null ? 'Record updated successfully!' : 'Record saved successfully!')),
      );
      if (widget.editRecord != null) {
        Navigator.pop(context, true);
      } else {
        _clearForm();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF030305),
      body: Stack(
        children: [
          const _GridBackground(),
          _buildBackgroundOrbs(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? MediaQuery.of(context).size.width * 0.1 : 16,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        _buildMainCard(isDesktop),
                        const SizedBox(height: 20),
                        _buildActions(isDesktop),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_loading) _buildLoader(),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Debts Manager',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Track Lending & Borrowing',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          _buildTopIcon(Icons.pie_chart_outline, onTap: () => Navigator.pushNamed(context, '/report/debts')),
          const SizedBox(width: 8),
          _buildTopIcon(Icons.home_outlined, onTap: () => Navigator.popUntil(context, (route) => route.isFirst)),
        ],
      ),
    );
  }

  Widget _buildTopIcon(IconData icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
      ),
    );
  }

  Widget _buildMainCard(bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0x990F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.handshake_outlined, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.editRecord != null ? 'Edit Debt Record' : 'Add New Debt',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Record your lending and borrowing activities',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildTypeSelector(),
          const SizedBox(height: 24),
          _buildInputFields(isDesktop),
          const SizedBox(height: 24),
          _buildDatePicker(),
          const SizedBox(height: 24),
          _buildRemarksSection(),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _TypeButton(
            label: 'Given',
            icon: Icons.trending_up,
            color: const Color(0xFF10B981),
            isSelected: _type == 'given',
            onTap: () => setState(() => _type = 'given'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _TypeButton(
            label: 'Taken',
            icon: Icons.trending_down,
            color: const Color(0xFFF43F5E),
            isSelected: _type == 'taken',
            onTap: () => setState(() => _type = 'taken'),
          ),
        ),
      ],
    );
  }

  Widget _buildInputFields(bool isDesktop) {
    final personInput = _DebtInputCard(
      label: 'PERSON NAME',
      controller: _personController,
      icon: Icons.person_outline,
      color: const Color(0xFF6366F1),
      hint: 'e.g. John Doe',
      keyboardType: TextInputType.text,
    );
    final amountInput = _DebtInputCard(
      label: 'AMOUNT',
      controller: _amountController,
      icon: Icons.currency_rupee,
      color: const Color(0xFF6366F1),
      hint: '0.00',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      isMono: true,
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: personInput),
          const SizedBox(width: 20),
          Expanded(child: amountInput),
        ],
      );
    } else {
      return Column(
        children: [
          personInput,
          const SizedBox(height: 16),
          amountInput,
        ],
      );
    }
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('DATE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, color: Color(0xFF6366F1), size: 20),
                const SizedBox(width: 12),
                Text(
                  DateFormat('dd/MMM/yyyy').format(_selectedDate),
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRemarksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('REMARKS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: TextField(
            controller: _remarksController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Add notes here...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isDesktop) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _clearForm,
            icon: const Icon(Icons.refresh, size: 20),
            label: const Text('Clear', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.3), blurRadius: 20)],
            ),
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_outlined, size: 20),
              label: Text(widget.editRecord != null ? 'Update Record' : 'Save Record', style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoader() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: const Color(0x991E293B),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6366F1)),
                  SizedBox(height: 24),
                  Text('Processing...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(
      children: [
        Positioned(top: -100, left: -100, child: _Orb(color: const Color(0xFF6366F1).withValues(alpha: 0.2), size: 500)),
        Positioned(bottom: -100, right: -100, child: _Orb(color: const Color(0xFF10B981).withValues(alpha: 0.15), size: 500)),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({required this.label, required this.icon, required this.color, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : const Color(0x33000000),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1)),
        ),
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: isSelected ? color : Colors.white38, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? color : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DebtInputCard extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color color;
  final String hint;
  final TextInputType keyboardType;
  final bool isMono;

  const _DebtInputCard({
    required this.label,
    required this.controller,
    required this.icon,
    required this.color,
    required this.hint,
    required this.keyboardType,
    this.isMono = false,
  });

  @override
  State<_DebtInputCard> createState() => _DebtInputCardState();
}

class _DebtInputCardState extends State<_DebtInputCard> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() => _isFocused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _isFocused ? Colors.black.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _isFocused ? widget.color : Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: Colors.white.withValues(alpha: 0.38), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: widget.keyboardType,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: widget.isMono ? 'monospace' : null,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: widget.hint,
                    hintStyle: const TextStyle(color: Color(0xFF334155)),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)),
    );
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.infinite, painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.02)..strokeWidth = 1.0;
    const step = 40.0;
    for (double i = 0; i < size.width; i += step) { canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint); }
    for (double i = 0; i < size.height; i += step) { canvas.drawLine(Offset(0, i), Offset(size.width, i), paint); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
