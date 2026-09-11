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

    // Power bill is excluded as per request (record purpose only)
    final total = (paid + water + adjust) - balance;
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
    return Theme(
      data: _darkTheme(),
      child: Scaffold(
        backgroundColor: ktBgDark,
        body: Stack(
          children: [
            _buildBgGlows(),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        children: [
                          _buildDateNavigator(),
                          const SizedBox(height: 16),
                          _buildRentAmountField(),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCollectionInput(
                                  label: KtStrings.rentPaid,
                                  controller: _paidController,
                                  icon: Icons.account_balance_wallet,
                                  iconColor: ktBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCollectionInput(
                                  label: KtStrings.balanceAmount,
                                  controller: _balanceController,
                                  icon: Icons.balance,
                                  iconColor: ktRose,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCollectionInput(
                                  label: KtStrings.powerBill,
                                  controller: _powerController,
                                  icon: Icons.bolt,
                                  iconColor: ktAmber,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCollectionInput(
                                  label: KtStrings.waterBill,
                                  controller: _waterController,
                                  icon: Icons.water_drop,
                                  iconColor: ktBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildCollectionInput(
                            label: KtStrings.adjustAmount,
                            controller: _adjustController,
                            icon: Icons.tune,
                            iconColor: ktViolet,
                          ),
                          const SizedBox(height: 12),
                          _buildRemarksInput(),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(),
                ],
              ),
            ),
            if (_loading) _buildLoader(),
          ],
        ),
      ),
    );
  }

  ThemeData _darkTheme() => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ktBgDark,
        colorScheme: const ColorScheme.dark(
            surface: ktCardBg, primary: ktPrimary, onSurface: ktTextWhite),
        fontFamily: 'Plus Jakarta Sans',
      );

  Widget _buildBgGlows() {
    return Stack(children: [
      Positioned(
          top: -60,
          left: -60,
          child: _glowCircle(const Color(0xFF6366F1), 0.2)),
      Positioned(
          bottom: -60,
          right: -60,
          child: _glowCircle(const Color(0xFF3B82F6), 0.2)),
    ]);
  }

  Widget _glowCircle(Color color, double opacity) => Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
              colors: [color.withValues(alpha: opacity), Colors.transparent]),
        ),
      );

  Widget _buildAppBar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
            ),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF3B82F6)]),
                boxShadow: [
                  BoxShadow(color: ktPrimary.withValues(alpha: 0.3), blurRadius: 8)
                ],
              ),
              child: const Icon(Icons.home_work_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.editRecord != null ? 'Edit Rent' : 'Rent Entry',
                        style: const TextStyle(
                            color: ktTextWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.w800)),
                    const Text('Monthly Tracker',
                        style: TextStyle(color: ktTextGray400, fontSize: 10)),
                  ]),
            ),
            _buildSideSelector(),
            const SizedBox(width: 8),
            ktHeaderIcon(Icons.bar_chart_rounded, () => Navigator.pushNamed(context, '/report/rent')),
            const SizedBox(width: 8),
            ktHeaderIcon(Icons.home_rounded, () => Navigator.popUntil(context, (route) => route.isFirst)),
          ],
        ),
      );

  Widget _buildSideSelector() => PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        offset: const Offset(0, 40),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(color: ktBorderWhite5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_selectedSide ?? 'Side',
                  style: const TextStyle(
                      color: ktAmber500,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down, color: ktPink700, size: 16),
            ],
          ),
        ),
        onSelected: (val) => setState(() => _selectedSide = val),
        itemBuilder: (context) => ['Kalyan', 'Srikanth']
            .map((e) => PopupMenuItem(value: e, child: Text(e, style: const TextStyle(color: ktWhite, fontSize: 13))))
            .toList(),
        color: ktCardBg,
      );


  Widget _buildDateNavigator() => Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          color: ktCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ktPanelBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(KtStrings.dateLabel,
              style: TextStyle(
                  color: ktTextGray500,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8)),
          const SizedBox(height: 10),
          Row(children: [
            _navBtn(Icons.chevron_left, () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1)))),
            Expanded(
                child: GestureDetector(
              onTap: () => _selectDate(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.calendar_month_outlined, color: ktTextGray400, size: 19),
                  const SizedBox(width: 10),
                  Text(ktFormatDate(_selectedDate),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: ktTextWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down, color: ktTextGray400, size: 18),
                ]),
              ),
            )),
            _navBtn(Icons.chevron_right, () => setState(() {
              final next = _selectedDate.add(const Duration(days: 1));
              if (!next.isAfter(getIndiaTime())) _selectedDate = next;
            })),
          ]),
        ]),
      );

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF12284F), Color(0xFF11306B)]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x334A7CFF)),
          ),
          child: Icon(icon, color: ktTextWhite, size: 22),
        ),
      );

  Widget _buildRentAmountField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ktCardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RENT AMOUNT',
              style: TextStyle(
                  color: ktTextGray500,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _isEditingRent
                    ? TextField(
                        controller: _rentController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: ktTextWhite, fontSize: 18, fontWeight: FontWeight.w800),
                        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                      )
                    : Text(
                        '₹ ${_rentController.text}',
                        style: const TextStyle(color: ktTextWhite, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
              ),
              IconButton(
                icon: Icon(_isEditingRent ? Icons.check : Icons.edit, color: ktPrimary, size: 20),
                onPressed: () => setState(() => _isEditingRent = !_isEditingRent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionInput({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required Color iconColor,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ktCardBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  color: ktTextGray500,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ktBorderWhite10),
            ),
            child: Row(children: [
              Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(icon, color: iconColor, size: 18)),
              Expanded(
                  child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    color: ktTextWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  hintText: '0.0',
                  hintStyle: TextStyle(color: ktTextGray500),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              )),
            ]),
          ),
        ]),
      );

  Widget _buildRemarksInput() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ktCardBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('REMARKS',
              style: TextStyle(
                  color: ktTextGray500,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: ktBlack.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ktBorderWhite10),
            ),
            child: TextField(
              controller: _remarksController,
              maxLines: 2,
              style: const TextStyle(color: ktTextGray400, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Add remarks here...',
                hintStyle: TextStyle(color: ktTextGray500),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
        ]),
      );

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: ktBgDark.withValues(alpha: 0.9),
        border: const Border(top: BorderSide(color: ktBorderWhite10)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL PAID',
                    style: TextStyle(
                        color: ktTextGray500,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                Text(
                  '₹ ${_totalController.text}',
                  style: const TextStyle(
                      color: ktEmerald,
                      fontSize: 22,
                      fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _clearForm,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ktBorderWhite5),
              ),
              child: const Icon(Icons.restart_alt, color: ktTextGray400, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _submit,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF3B82F6)]),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: ktPrimary.withValues(alpha: 0.3), blurRadius: 12)
                ],
              ),
              child: Center(
                child: Text(widget.editRecord != null ? KtStrings.update : KtStrings.save,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() => Container(
        color: Colors.black.withValues(alpha: 0.6),
        child: const Center(child: CircularProgressIndicator(color: ktPrimary)),
      );
}

