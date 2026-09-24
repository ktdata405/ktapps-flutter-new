import 'package:flutter/material.dart';
import '../core_constants.dart';
import '../core_ui_utils.dart';
import '../core_utils.dart';
import 'house_models.dart';
import 'house_service.dart';

class HouseEntryScreen extends StatefulWidget {
  final HouseBillRecord? editRecord;
  final HlDisbursementRecord? editHlRecord;

  const HouseEntryScreen({super.key, this.editRecord, this.editHlRecord});

  @override
  State<HouseEntryScreen> createState() => _HouseEntryScreenState();
}

class _HouseEntryScreenState extends State<HouseEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final HouseService _service = HouseService();

  int _currentTab = 0; // 0 = House Bills (Splitwise), 1 = HL-disbursement

  // House Bill Controllers
  late String _houseSNo;
  DateTime _houseDate = DateTime.now();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: '0');
  final TextEditingController _contractAmountController = TextEditingController(text: '0');
  final TextEditingController _balanceAmountController = TextEditingController(text: '0');

  // HL Disbursement Controllers
  late String _hlSNo;
  DateTime _hlDate = DateTime.now();
  final TextEditingController _hlAmountController = TextEditingController(text: '0');

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editRecord != null) {
      _currentTab = 0;
      final rec = widget.editRecord!;
      _houseSNo = rec.sNo;
      _groupNameController.text = rec.groupName;
      _amountController.text = rec.amount.toString();
      _contractAmountController.text = rec.contractAmount.toString();
      _balanceAmountController.text = rec.balanceAmount.toString();

      final parsed = ktParseDate(rec.date);
      if (parsed != null) {
        _houseDate = parsed;
      }
      _hlSNo = HlDisbursementRecord.generateSNo();
    } else if (widget.editHlRecord != null) {
      _currentTab = 1;
      final rec = widget.editHlRecord!;
      _hlSNo = rec.sNo;
      _hlAmountController.text = rec.amount.toString();

      final parsed = ktParseDate(rec.date);
      if (parsed != null) {
        _hlDate = parsed;
      }
      _houseSNo = HouseBillRecord.generateSNo();
    } else {
      _houseSNo = HouseBillRecord.generateSNo();
      _hlSNo = HlDisbursementRecord.generateSNo();
    }
  }

  void _generateNewSNo() {
    setState(() {
      if (_currentTab == 0) {
        _houseSNo = HouseBillRecord.generateSNo();
      } else {
        _hlSNo = HlDisbursementRecord.generateSNo();
      }
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _amountController.dispose();
    _contractAmountController.dispose();
    _balanceAmountController.dispose();
    _hlAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final initial = _currentTab == 0 ? _houseDate : _hlDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (_currentTab == 0) {
          _houseDate = picked;
        } else {
          _hlDate = picked;
        }
      });
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    bool success = true;
    if (_currentTab == 0) {
      final record = HouseBillRecord(
        sNo: _houseSNo,
        date: ktFormatDateForSheet(_houseDate), // Saved on server in sheet format like Essential
        groupName: _groupNameController.text.trim(),
        amount: double.tryParse(_amountController.text) ?? 0.0,
        contractAmount: double.tryParse(_contractAmountController.text) ?? 0.0,
        balanceAmount: double.tryParse(_balanceAmountController.text) ?? 0.0,
        timestamp: DateTime.now().toIso8601String(),
      );

      if (widget.editRecord != null) {
        success = await _service.updateHouseBill(record);
      } else {
        success = await _service.addHouseBill(record);
      }
    } else {
      final record = HlDisbursementRecord(
        sNo: _hlSNo,
        date: ktFormatDateForSheet(_hlDate),
        amount: double.tryParse(_hlAmountController.text) ?? 0.0,
        timestamp: DateTime.now().toIso8601String(),
      );

      if (widget.editHlRecord != null) {
        success = await _service.updateHlDisbursement(record);
      } else {
        success = await _service.addHlDisbursement(record);
      }
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
    });

    if (success) {
      final isEdit = widget.editRecord != null || widget.editHlRecord != null;
      ktShowCustomToast(context, isEdit ? KtStrings.dataUpdated : KtStrings.dataSaved);
      if (isEdit) {
        Navigator.pop(context, true);
      } else {
        _resetForm();
      }
    } else {
      ktShowCustomToast(context, KtStrings.saveFailed);
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    if (_currentTab == 0) {
      _groupNameController.clear();
      _amountController.text = '0';
      _contractAmountController.text = '0';
      _balanceAmountController.text = '0';
      _houseSNo = HouseBillRecord.generateSNo();
    } else {
      _hlAmountController.text = '0';
      _hlSNo = HlDisbursementRecord.generateSNo();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.editRecord != null || widget.editHlRecord != null;

    return Scaffold(
      backgroundColor: isDark ? ktBgDark : ktLightScaffoldBg,
      appBar: AppBar(
        backgroundColor: isDark ? ktDarkBlueHeader : Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_currentTab == 0 ? ktHousePrimary : ktHouseSecondary, ktHousePrimary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_currentTab == 0 ? Icons.home_work_rounded : Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentTab == 0
                      ? (widget.editRecord != null ? KtStrings.editHouseBill : KtStrings.houseConstructionTitle)
                      : (widget.editHlRecord != null ? KtStrings.editHlDisbursement : KtStrings.hlDisbursementTitle),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  _currentTab == 0 ? KtStrings.houseConstructionSubtitle : KtStrings.hlDisbursementSubtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? ktTextGray400 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          ktHeaderIcon(Icons.assessment_rounded, () {
            Navigator.pushNamed(context, '/report/house');
          }),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Tab Switcher Bar
          if (!isEditing)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? ktCardBg : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currentTab == 0 ? ktHousePrimary.withOpacity(isDark ? 0.25 : 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: _currentTab == 0 ? Border.all(color: ktHousePrimary.withOpacity(0.4)) : null,
                        ),
                        child: Center(
                          child: Text(
                            KtStrings.houseConstructionTitle,
                            style: TextStyle(
                              color: _currentTab == 0 ? ktHousePrimary : (isDark ? ktTextGray400 : Colors.black54),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currentTab == 1 ? ktHouseSecondary.withOpacity(isDark ? 0.25 : 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: _currentTab == 1 ? Border.all(color: ktHouseSecondary.withOpacity(0.4)) : null,
                        ),
                        child: Center(
                          child: Text(
                            KtStrings.hlDisbursementTitle,
                            style: TextStyle(
                              color: _currentTab == 1 ? ktHouseSecondary : (isDark ? ktTextGray400 : Colors.black54),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Form content
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _currentTab == 0 ? _buildHouseForm(isDark) : _buildHlForm(isDark),
                  const SizedBox(height: 24),

                  // Submit Button
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _currentTab == 0
                            ? [ktHousePrimary, ktHouseSecondary]
                            : [ktHouseSecondary, ktHousePrimary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: (_currentTab == 0 ? ktHousePrimary : ktHouseSecondary).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              isEditing
                                  ? KtStrings.update
                                  : (_currentTab == 0 ? KtStrings.addHouseBill : KtStrings.addHlDisbursement),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // S.No & Date Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? ktCardBg : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              // S.No Container
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'S.NO (AUTO)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ktTextGray400),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: ktHousePrimary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: ktHousePrimary.withOpacity(0.3)),
                          ),
                          child: Text(
                            _houseSNo,
                            style: const TextStyle(
                              color: ktHousePrimary,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _generateNewSNo,
                          icon: const Icon(Icons.refresh_rounded, size: 20, color: ktHousePrimary),
                          tooltip: 'Generate new S.No',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Date Container
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DATE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ktTextGray400),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.08)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 18, color: ktHousePrimary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ktFormatDate(_houseDate),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Columns A, B, C, D Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? ktCardBg : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded, color: ktHousePrimary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'HOUSE CONSTRUCTION BILL DETAILS',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Column A: Group Name
              _buildTextField(
                controller: _groupNameController,
                label: 'Column A: Group Name',
                hint: 'Enter group name / contractor',
                icon: Icons.group_rounded,
                isDark: isDark,
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter Group Name' : null,
              ),
              const SizedBox(height: 16),

              // Column B: Amount
              _buildTextField(
                controller: _amountController,
                label: 'Column B: Amount (₹)',
                hint: '0.00',
                icon: Icons.currency_rupee_rounded,
                isDark: isDark,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || double.tryParse(val) == null) return 'Please enter valid Amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Column C: Contract Amount
              _buildTextField(
                controller: _contractAmountController,
                label: 'Column C: Contract Amount (₹)',
                hint: '0.00',
                icon: Icons.assignment_turned_in_rounded,
                isDark: isDark,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || double.tryParse(val) == null) return 'Please enter valid Contract Amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Column D: Balance Amount
              _buildTextField(
                controller: _balanceAmountController,
                label: 'Column D: Balance Amount (₹)',
                hint: '0.00',
                icon: Icons.account_balance_wallet_rounded,
                isDark: isDark,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || double.tryParse(val) == null) return 'Please enter valid Balance Amount';
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHlForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // S.No & Date Card for HL
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? ktCardBg : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'S.NO (AUTO)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ktTextGray400),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: ktHouseSecondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: ktHouseSecondary.withOpacity(0.3)),
                          ),
                          child: Text(
                            _hlSNo,
                            style: const TextStyle(
                              color: ktHouseSecondary,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _generateNewSNo,
                          icon: const Icon(Icons.refresh_rounded, size: 20, color: ktHouseSecondary),
                          tooltip: 'Generate new S.No',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DATE',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ktTextGray400),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.08)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 18, color: ktHouseSecondary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ktFormatDate(_hlDate),
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Amount Card for HL
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? ktCardBg : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance_rounded, color: ktHouseSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'HL DISBURSEMENT DETAILS',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _hlAmountController,
                label: 'Amount (₹)',
                hint: '0.00',
                icon: Icons.currency_rupee_rounded,
                isDark: isDark,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (val) {
                  if (val == null || double.tryParse(val) == null) return 'Please enter valid Amount';
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDark ? ktTextGray400 : Colors.black54,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? ktTextGray500 : Colors.black38),
            prefixIcon: Icon(icon, color: ktHousePrimary, size: 20),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.08)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: isDark ? ktBorderWhite10 : Colors.black.withOpacity(0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: ktHousePrimary, width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
