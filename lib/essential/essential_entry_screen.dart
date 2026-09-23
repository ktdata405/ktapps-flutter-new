import 'package:flutter/material.dart';
import '../core_constants.dart';
import '../core_ui_utils.dart';
import '../core_utils.dart';
import 'essential_models.dart';
import 'essential_service.dart';

// Distribution Essential Entry Screen
class EssentialEntryScreen extends StatefulWidget {
  final EssentialRecord? editRecord;

  const EssentialEntryScreen({super.key, this.editRecord});

  @override
  State<EssentialEntryScreen> createState() => _EssentialEntryScreenState();
}

class _EssentialEntryScreenState extends State<EssentialEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final EssentialService _service = EssentialService();

  late String _sNo;
  DateTime _selectedDate = DateTime.now();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _itemDController = TextEditingController(text: '1');
  final TextEditingController _itemEController = TextEditingController(text: '1');
  final TextEditingController _itemFController = TextEditingController(text: '0');
  final TextEditingController _itemGController = TextEditingController(text: '0');
  final TextEditingController _itemHController = TextEditingController(text: '0');
  final TextEditingController _totalAmountController = TextEditingController(text: '0');

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.editRecord != null) {
      final rec = widget.editRecord!;
      _sNo = rec.sNo;
      _fullNameController.text = rec.fullName;
      _itemDController.text = rec.itemD.toString();
      _itemEController.text = rec.itemE.toString();
      _itemFController.text = rec.itemF.toString();
      _itemGController.text = rec.itemG.toString();
      _itemHController.text = rec.itemH.toString();
      _totalAmountController.text = rec.totalAmount.toString();

      final parsed = ktParseDate(rec.date);
      if (parsed != null) {
        _selectedDate = parsed;
      }
    } else {
      _generateNewSNo();
    }
  }

  void _generateNewSNo() {
    setState(() {
      _sNo = EssentialRecord.generateSNo();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _itemDController.dispose();
    _itemEController.dispose();
    _itemFController.dispose();
    _itemGController.dispose();
    _itemHController.dispose();
    _totalAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final record = EssentialRecord(
      sNo: _sNo,
      date: ktFormatDateForSheet(_selectedDate), // Format e.g. "22/Sep/2026"
      fullName: _fullNameController.text.trim(),
      itemD: double.tryParse(_itemDController.text.trim()) ?? 0.0,
      itemE: double.tryParse(_itemEController.text.trim()) ?? 0.0,
      itemF: double.tryParse(_itemFController.text.trim()) ?? 0.0,
      itemG: double.tryParse(_itemGController.text.trim()) ?? 0.0,
      itemH: double.tryParse(_itemHController.text.trim()) ?? 0.0,
      totalAmount: double.tryParse(_totalAmountController.text.trim()) ?? 0.0,
    );

    bool success;
    if (widget.editRecord != null) {
      success = await _service.updateRecord(record);
    } else {
      success = await _service.addRecord(record);
    }

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    if (success) {
      ktShowCustomToast(
        context,
        widget.editRecord != null ? KtStrings.recordUpdated : KtStrings.recordSaved,
      );
      if (widget.editRecord != null) {
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
    _fullNameController.clear();
    _itemDController.text = '1';
    _itemEController.text = '1';
    _itemFController.text = '0';
    _itemGController.text = '0';
    _itemHController.text = '0';
    _totalAmountController.text = '0';

    _generateNewSNo();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.editRecord != null;

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
                gradient: const LinearGradient(
                  colors: [ktEssentialPrimary, ktEssentialSecondary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? KtStrings.editEssential : KtStrings.essentialTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  KtStrings.essentialSubtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? ktTextGray400 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ktHeaderIcon(
              Icons.home_rounded,
              () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ktHeaderIcon(
              Icons.bar_chart_rounded,
              () => Navigator.pushNamed(context, '/report/essential'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. S.No Auto-generated Card
                _buildSNoCard(isDark),
                const SizedBox(height: 20),

                // 2. Main Entry Form Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? ktCardBg : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.06),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date & Day Field (e.g. 22/Sep/2026 (Wed))
                      _buildTextFieldLabel(KtStrings.dateAndDayLabel, isDark, required: true),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0B1222) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, color: ktEssentialPrimary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  ktFormatDateForSheet(_selectedDate),
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Icon(Icons.arrow_drop_down_rounded, color: isDark ? Colors.white54 : Colors.black54),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Full Name Field (Column C)
                      _buildTextFieldLabel(KtStrings.fullNameLabel, isDark, required: true),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _fullNameController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: _inputDecoration(
                          hint: KtStrings.enterFullNameHint,
                          icon: Icons.person_outline_rounded,
                          isDark: isDark,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter Full Name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Item Quantities Section Header (Columns D - H)
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, color: ktEssentialPrimary, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'ESSENTIAL ITEMS QUANTITIES (COLUMNS D - H)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark ? ktTextGray400 : Colors.black54,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _buildQtyField(
                              controller: _itemDController,
                              label: KtStrings.itemDLabel,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQtyField(
                              controller: _itemEController,
                              label: KtStrings.itemELabel,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQtyField(
                              controller: _itemFController,
                              label: KtStrings.itemFLabel,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQtyField(
                              controller: _itemGController,
                              label: KtStrings.itemGLabel,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQtyField(
                              controller: _itemHController,
                              label: KtStrings.itemHLabel,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Total Amount (Column K)
                      _buildTextFieldLabel(KtStrings.totalAmountLabel, isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _totalAmountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: ktEssentialPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                        decoration: _inputDecoration(
                          hint: '0.00',
                          icon: Icons.account_balance_wallet_outlined,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit / Update & Clear Action Buttons
                Row(
                  children: [
                    if (!isEdit)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _resetForm,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text(KtStrings.clearAll),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : Colors.black87,
                            side: BorderSide(
                              color: isDark ? ktBorderWhite10 : Colors.black26,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    if (!isEdit) const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [ktEssentialPrimary, ktEssentialSecondary],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: ktEssentialPrimary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveRecord,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Icon(isEdit ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                                  color: Colors.white),
                          label: Text(
                            _isSaving
                                ? KtStrings.loading
                                : (isEdit ? KtStrings.updateRecord : KtStrings.addEssential),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
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
    );
  }

  Widget _buildQtyField({
    required TextEditingController controller,
    required String label,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? const Color(0xFF0B1222) : const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ktEssentialPrimary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSNoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF064E3B), const Color(0xFF0C4A6E)]
              : [const Color(0xFFECFDF5), const Color(0xFFE0F2FE)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ktEssentialPrimary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ktEssentialPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.tag_rounded, color: ktEssentialPrimary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${KtStrings.sNoLabel} (Auto Generated)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? ktTextGray400 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _sNo,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                    color: ktEssentialPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Last 3 digits of current ms',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          if (widget.editRecord == null)
            IconButton(
              tooltip: 'Regenerate S.No',
              icon: const Icon(Icons.refresh_rounded, color: ktEssentialPrimary),
              onPressed: _generateNewSNo,
            ),
        ],
      ),
    );
  }

  Widget _buildTextFieldLabel(String label, bool isDark, {bool required = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white70 : Colors.black87,
            letterSpacing: 0.3,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text('*', style: TextStyle(color: ktRose, fontWeight: FontWeight.bold)),
        ],
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.white38 : Colors.black38,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: ktEssentialPrimary, size: 20),
      filled: true,
      fillColor: isDark ? const Color(0xFF0B1222) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ktEssentialPrimary, width: 2),
      ),
    );
  }
}
