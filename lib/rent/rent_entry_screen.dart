import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'rent_models.dart';
import 'rent_service.dart';
import 'rent_report_screen.dart';

class RentEntryScreen extends StatefulWidget {
  final RentRecord? editRecord;
  const RentEntryScreen({super.key, this.editRecord});

  @override
  State<RentEntryScreen> createState() => _RentEntryScreenState();
}

class _RentEntryScreenState extends State<RentEntryScreen> {
  final RentService _service = RentService();
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDate;
  String? _selectedSide;
  final TextEditingController _rentController = TextEditingController(text: '5500');
  final TextEditingController _paidController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  final TextEditingController _powerController = TextEditingController();
  final TextEditingController _waterController = TextEditingController();
  final TextEditingController _adjustController = TextEditingController();
  final TextEditingController _totalController = TextEditingController(text: '0.00');
  final TextEditingController _remarksController = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editRecord != null) {
      final r = widget.editRecord!;
      _selectedDate = _parseDate(r.date);
      _selectedSide = r.side;
      _rentController.text = r.rentAmount.toString();
      _paidController.text = r.paidAmount.toString();
      _balanceController.text = r.balanceAmount.toString();
      _powerController.text = r.powerBill.toString();
      _waterController.text = r.waterBill.toString();
      _adjustController.text = r.adjustAmount.toString();
      _remarksController.text = r.remarks;
    } else {
      _selectedDate = DateTime.now();
    }
    _calculateTotal();

    _paidController.addListener(_calculateTotal);
    _waterController.addListener(_calculateTotal);
    _balanceController.addListener(_calculateTotal);
    _adjustController.addListener(_calculateTotal);
    _powerController.addListener(_calculateTotal);
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

  void _calculateTotal() {
    final paid = double.tryParse(_paidController.text) ?? 0;
    final water = double.tryParse(_waterController.text) ?? 0;
    final balance = double.tryParse(_balanceController.text) ?? 0;
    final adjust = double.tryParse(_adjustController.text) ?? 0;
    final power = double.tryParse(_powerController.text) ?? 0;

    // Based on UI formula: Total Paid = Rent Paid + Water Bill + Adjust Amount + Power Bill - Balance Amount
    final total = (paid + water + adjust + power) - balance;
    _totalController.text = total.toStringAsFixed(2);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
        _selectedSide = null;
        _rentController.text = '5500';
        _paidController.clear();
        _balanceController.clear();
        _powerController.clear();
        _waterController.clear();
        _adjustController.clear();
        _remarksController.clear();
        _calculateTotal();
      } else {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedSide == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Side')));
      return;
    }
    setState(() => _loading = true);
    final record = RentRecord(
      date: DateFormat('dd/MMM/yyyy').format(_selectedDate),
      side: _selectedSide!,
      rentAmount: double.tryParse(_rentController.text) ?? 0,
      paidAmount: double.tryParse(_paidController.text) ?? 0,
      balanceAmount: double.tryParse(_balanceController.text) ?? 0,
      powerBill: double.tryParse(_powerController.text) ?? 0,
      waterBill: double.tryParse(_waterController.text) ?? 0,
      adjustAmount: double.tryParse(_adjustController.text) ?? 0,
      totalPaid: double.tryParse(_totalController.text) ?? 0,
      remarks: _remarksController.text.isEmpty ? '-' : _remarksController.text,
    );
    bool success;
    if (widget.editRecord != null) {
      success = await _service.updateRecord(record, widget.editRecord!.date, widget.editRecord!.side);
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
        Navigator.pop(context);
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.home, color: Color(0xFF8B5CF6), size: 20),
            ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tenant Details',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Rent Management',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildTopIcon(
            Icons.pie_chart_outline,
            onTap: () => Navigator.pushNamed(context, '/report/rent'),
          ),
          const SizedBox(width: 8),
          _buildTopIcon(
            Icons.home_outlined,
            onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
          const SizedBox(width: 8),
          _buildTopIcon(
            Icons.settings_outlined,
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopIcon(IconData icon, {String? badge, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.6), size: 20),
            if (badge != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                  child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(bool isDesktop) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: const Color(0x990F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isMobile ? 48 : 56,
                height: isMobile ? 48 : 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.description_outlined, color: Colors.white, size: isMobile ? 24 : 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Tenant Record',
                      style: TextStyle(color: Colors.white, fontSize: isMobile ? 20 : 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter all rent related details to keep your records organized',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: isMobile ? 12 : 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildPickers(isDesktop),
          const SizedBox(height: 24),
          if (!isDesktop) ...[
            const Text('AMOUNTS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
          ],
          _buildInputGrid(isDesktop),
          const SizedBox(height: 24),
          _buildTotalSection(),
          const SizedBox(height: 24),
          if (!isDesktop) ...[
            const Text('REMARKS', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 16),
          ],
          _buildRemarksSection(),
        ],
      ),
    );
  }

  Widget _buildPickers(bool isDesktop) {
    final datePicker = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Date', style: _labelStyle),
        const SizedBox(height: 8),
        _buildCustomPicker(
          icon: Icons.calendar_today_outlined,
          text: DateFormat('d MMMM yyyy').format(_selectedDate),
          onTap: () => _selectDate(context),
        ),
      ],
    );

    final sidePicker = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Side / Unit', style: _labelStyle),
        const SizedBox(height: 8),
        _buildCustomPicker(
          icon: Icons.business_outlined,
          text: _selectedSide ?? 'Select Side',
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF1E293B),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: ['Kalyan', 'Srikanth']
                    .map((e) => ListTile(
                          title: Text(e, style: const TextStyle(color: Colors.white)),
                          onTap: () {
                            setState(() => _selectedSide = e);
                            Navigator.pop(context);
                          },
                        ))
                    .toList(),
              ),
            );
          },
        ),
      ],
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(child: datePicker),
          const SizedBox(width: 20),
          Expanded(child: sidePicker),
        ],
      );
    } else {
      return Column(
        children: [
          datePicker,
          const SizedBox(height: 16),
          sidePicker,
        ],
      );
    }
  }

  Widget _buildCustomPicker({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInputGrid(bool isDesktop) {
    final items = [
      _RentInputCard(
        label: 'Rent Amount',
        controller: _rentController,
        icon: Icons.currency_rupee,
        color: const Color(0xFF10B981),
        showCheck: true,
      ),
      _RentInputCard(
        label: 'Rent Paid',
        controller: _paidController,
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF3B82F6),
      ),
      _RentInputCard(
        label: 'Balance Amount',
        controller: _balanceController,
        icon: Icons.balance_outlined,
        color: const Color(0xFF8B5CF6),
      ),
      _RentInputCard(
        label: 'Power Bill',
        controller: _powerController,
        icon: Icons.bolt_outlined,
        color: const Color(0xFFFBBF24),
      ),
      _RentInputCard(
        label: 'Water Bill',
        controller: _waterController,
        icon: Icons.water_drop_outlined,
        color: const Color(0xFF3B82F6),
      ),
      _RentInputCard(
        label: 'Adjust Amount',
        controller: _adjustController,
        icon: Icons.tune_outlined,
        color: const Color(0xFFF97316),
        isActive: true,
      ),
    ];

    if (isDesktop) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 4,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => items[index],
      );
    } else {
      return Column(
        children: List.generate(items.length, (index) => Padding(padding: const EdgeInsets.only(bottom: 16), child: items[index])),
      );
    }
  }

  Widget _buildTotalSection() {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final mainInfo = Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.description_outlined, color: Color(0xFF10B981)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Paid',
                style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                _totalController.text,
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        if (!isMobile) ...[
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              'Total Paid = Rent Paid + Water Bill + Adjust Amount + Power Bill - Balance Amount',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
            ),
          ),
        ],
        const SizedBox(width: 16),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 20),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mainInfo,
          if (isMobile) ...[
            const SizedBox(height: 12),
            Text(
              'Total Paid = Rent Paid + Water Bill + Adjust Amount + Power Bill - Balance Amount',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRemarksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (MediaQuery.of(context).size.width > 900) const Text('Remarks', style: _labelStyle),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.comment_outlined, color: Color(0xFF8B5CF6), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _remarksController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter remarks here...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_remarksController.text.length} / 500',
                style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10),
              ),
            ],
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
            icon: const Icon(Icons.delete_outline, size: 20),
            label: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8B5CF6),
              side: const BorderSide(color: Color(0xFF8B5CF6)),
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20)],
            ),
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.send, size: 20),
              label: Text(widget.editRecord != null ? 'Update Record' : 'Submit Record', style: const TextStyle(fontWeight: FontWeight.bold)),
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
      color: Colors.black.withOpacity(0.8),
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
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6366F1)),
                  SizedBox(height: 24),
                  Text('Saving Record', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
        Positioned(top: -100, left: -100, child: _Orb(color: const Color(0xFF6366F1).withOpacity(0.2), size: 500)),
        Positioned(bottom: -100, right: -100, child: _Orb(color: const Color(0xFFEC4899).withOpacity(0.2), size: 500)),
      ],
    );
  }

  static const _labelStyle = TextStyle(color: Color(0xFF94A3B8), fontSize: 13, fontWeight: FontWeight.w500);
}

class _RentInputCard extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final Color color;
  final bool showCheck;
  final bool isActive;

  const _RentInputCard({
    required this.label,
    required this.controller,
    required this.icon,
    required this.color,
    this.showCheck = false,
    this.isActive = false,
  });

  @override
  State<_RentInputCard> createState() => _RentInputCardState();
}

class _RentInputCardState extends State<_RentInputCard> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _isFocused || widget.isActive
        ? widget.color.withOpacity(0.8)
        : Colors.white.withOpacity(0.15);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isFocused ? widget.color.withOpacity(0.05) : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: _isFocused || widget.isActive ? 2 : 1.5,
        ),
        boxShadow: _isFocused
            ? [BoxShadow(color: widget.color.withOpacity(0.1), blurRadius: 10, spreadRadius: 0)]
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, color: widget.color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    color: _isFocused ? widget.color : const Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(color: Color(0xFF334155)),
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          if (widget.showCheck)
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color.withOpacity(0.5)),
              ),
              child: Icon(Icons.check, color: widget.color, size: 14),
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
    final paint = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 1.0;
    const step = 40.0;
    for (double i = 0; i < size.width; i += step) { canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint); }
    for (double i = 0; i < size.height; i += step) { canvas.drawLine(Offset(0, i), Offset(size.width, i), paint); }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
