import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core_utils.dart';
import '../core_ui_utils.dart';
import 'package:ktppsflutter/core_constants.dart';
import 'rent_models.dart';
import 'rent_service.dart';

class RentEntryScreen extends StatefulWidget {
  final RentRecord? editRecord;
  const RentEntryScreen({super.key, this.editRecord});

  @override
  State<RentEntryScreen> createState() => _RentEntryScreenState();
}

class _RentEntryScreenState extends State<RentEntryScreen> {
  final RentService _service = RentService();

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
  bool _isEditingRent = false;

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
      _selectedDate = getIndiaTime();
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
        return getIndiaTime();
      }
    }
  }

  void _calculateTotal() {
    final paid = double.tryParse(_paidController.text) ?? 0;
    final water = double.tryParse(_waterController.text) ?? 0;
    final balance = double.tryParse(_balanceController.text) ?? 0;
    final adjust = double.tryParse(_adjustController.text) ?? 0;
    final power = double.tryParse(_powerController.text) ?? 0;

    final total = (paid + water + adjust + power) - balance;
    _totalController.text = total.toStringAsFixed(2);
    if (mounted) setState(() {});
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: getIndiaTime(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: ktPrimary,
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
        _selectedDate = getIndiaTime();
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(KtStrings.pleaseSelectSide)));
      return;
    }
    setState(() => _loading = true);
    final record = RentRecord(
      date: ktFormatDateForSheet(_selectedDate),
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
      ktShowCustomToast(
        context,
        widget.editRecord != null ? KtStrings.recordUpdated : KtStrings.recordSaved,
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
    return Scaffold(
      backgroundColor: ktBgDark,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      _buildQuickDate(),
                      const SizedBox(height: 16),
                      const SizedBox(height: 8),
                      _buildRentAmountField(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInput(
                              label: KtStrings.rentPaid,
                              controller: _paidController,
                              icon: Icons.account_balance_wallet,
                              color: ktBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInput(
                              label: KtStrings.balanceAmount,
                              controller: _balanceController,
                              icon: Icons.balance,
                              color: ktRose,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInput(
                              label: KtStrings.powerBill,
                              controller: _powerController,
                              icon: Icons.bolt,
                              color: ktAmber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInput(
                              label: KtStrings.waterBill,
                              controller: _waterController,
                              icon: Icons.water_drop,
                              color: ktBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildInput(
                        label: KtStrings.adjustAmount,
                        controller: _adjustController,
                        icon: Icons.tune,
                        color: ktViolet,
                      ),
                      const SizedBox(height: 12),
                      _buildRemarksInput(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildBottomAction(),
          if (_loading) _buildLoader(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: ktWhite, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.editRecord != null ? 'Edit Rent' : 'Rent Entry',
              style: const TextStyle(color: ktWhite, fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            offset: const Offset(0, 40),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: ktCardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ktBorderWhite10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_selectedSide ?? 'Side', style: const TextStyle(color: ktWhite, fontSize: 12, fontWeight: FontWeight.bold)),
                  const Icon(Icons.keyboard_arrow_down, color: ktWhite, size: 14),
                ],
              ),
            ),
            onSelected: (val) => setState(() => _selectedSide = val),
            itemBuilder: (context) => ['Kalyan', 'Srikanth']
                .map((e) => PopupMenuItem(value: e, child: Text(e, style: const TextStyle(color: ktWhite, fontSize: 13))))
                .toList(),
            color: ktCardBg,
          ),
          IconButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            icon: const Icon(Icons.home_outlined, color: ktWhite, size: 22),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/report/rent'),
            icon: const Icon(Icons.insert_chart_outlined, color: ktWhite, size: 22),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDate() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ktBorderWhite10),
      ),
      child: InkWell(
        onTap: () => _selectDate(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DATE', style: TextStyle(color: ktTextGray500, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_month, color: ktPrimary, size: 16),
                const SizedBox(width: 6),
                Text(ktFormatDate(_selectedDate), style: const TextStyle(color: ktWhite, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title.toUpperCase(), style: const TextStyle(color: ktTextGray500, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        ...children,
      ],
    );
  }

  Widget _buildRentAmountField() {
    if (_isEditingRent) {
      return _buildInput(
        label: KtStrings.rentAmount,
        controller: _rentController,
        icon: Icons.currency_rupee,
        color: ktEmerald,
        suffix: IconButton(
          icon: const Icon(Icons.check, color: ktEmerald, size: 18),
          onPressed: () => setState(() => _isEditingRent = false),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ktBorderWhite10),
      ),
      child: Row(
        children: [
          const Icon(Icons.currency_rupee, color: ktEmerald, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Rent: ${_rentController.text.isEmpty ? "0.00" : _rentController.text}',
              style: const TextStyle(color: ktWhite, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: ktTextGray500, size: 18),
            onPressed: () => setState(() => _isEditingRent = true),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    Widget? suffix,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ktBorderWhite10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: const TextStyle(color: ktWhite, fontSize: 15, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: label,
                hintStyle: const TextStyle(color: ktTextGray500, fontSize: 13, fontWeight: FontWeight.normal),
              ),
            ),
          ),
          if (suffix != null) suffix,
        ],
      ),
    );
  }

  Widget _buildRemarksInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ktCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ktBorderWhite10),
      ),
      child: TextField(
        controller: _remarksController,
        maxLines: 2,
        style: const TextStyle(color: ktWhite, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Add remarks here...',
          hintStyle: TextStyle(color: ktTextGray500),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ktCardBg,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20)],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TOTAL PAID', style: TextStyle(color: ktTextGray500, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(
                    '₹ ${_totalController.text}',
                    style: const TextStyle(color: ktEmerald, fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: _clearForm,
              icon: const Icon(Icons.restart_alt, color: ktTextGray500, size: 24),
              tooltip: 'Clear Form',
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: ktPrimary,
                foregroundColor: ktWhite,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(widget.editRecord != null ? KtStrings.update : KtStrings.save, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: const Center(child: CircularProgressIndicator(color: ktPrimary)),
    );
  }
}
