import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core_constants.dart';
import '../core_ui_utils.dart';
import '../core_utils.dart';
import 'cc_emi_models.dart';
import 'cc_emi_service.dart';

class CcEmiScreen extends StatefulWidget {
  final CreditCardEmiRecord? editRecord;
  const CcEmiScreen({super.key, this.editRecord});

  @override
  State<CcEmiScreen> createState() => _CcEmiScreenState();
}

class _CcEmiScreenState extends State<CcEmiScreen> {
  final CcEmiService _service = CcEmiService();
  final _formKey = GlobalKey<FormState>();

  late DateTime _purchaseDate;
  final TextEditingController _cardNameController = TextEditingController();
  final TextEditingController _merchantController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _interestRateController = TextEditingController();
  final TextEditingController _processingFeeController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  bool _isNoCostEmi = false;
  int _selectedTenure = 12;
  int _selectedDueDay = 5;
  String _selectedCategory = 'Electronics';
  String _amountInWords = '';
  bool _loading = false;

  final List<String> _popularCards = [
    'HDFC Bank',
    'ICICI Bank',
    'SBI Card',
    'Axis Bank',
    'Amazon Pay ICICI',
    'OneCard',
    'AMEX',
    'Kotak',
  ];

  final List<String> _categories = [
    'Electronics',
    'Appliances',
    'Travel',
    'Shopping',
    'Health',
    'Education',
    'Other',
  ];

  final List<int> _tenureOptions = [3, 6, 9, 12, 18, 24, 36];
  final List<int> _dueDayOptions = [1, 5, 10, 15, 20, 25];

  @override
  void initState() {
    super.initState();
    if (widget.editRecord != null) {
      final r = widget.editRecord!;
      _purchaseDate = ktParseDate(r.purchaseDate) ?? getIndiaTime();
      _cardNameController.text = r.cardName;
      _merchantController.text = r.merchantName;
      _amountController.text = r.totalAmount > 0 ? r.totalAmount.toStringAsFixed(0) : '';
      _isNoCostEmi = r.interestRate == 0;
      _interestRateController.text = r.interestRate > 0 ? r.interestRate.toString() : '0';
      _processingFeeController.text = r.processingFee > 0 ? r.processingFee.toStringAsFixed(0) : '';
      _selectedTenure = r.tenureMonths;
      _selectedDueDay = r.dueDay;
      _selectedCategory = _categories.contains(r.category) ? r.category : 'Electronics';
      _remarksController.text = r.remarks;
      _updateAmountInWords(_amountController.text);
    } else {
      _purchaseDate = getIndiaTime();
      _interestRateController.text = '14.0';
    }

    _amountController.addListener(() {
      _updateAmountInWords(_amountController.text);
      setState(() {});
    });
    _interestRateController.addListener(() => setState(() {}));
    _processingFeeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _merchantController.dispose();
    _amountController.dispose();
    _interestRateController.dispose();
    _processingFeeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _updateAmountInWords(String value) {
    final cleanValue = value.replaceAll(',', '');
    final numVal = double.tryParse(cleanValue);
    if (numVal != null && numVal > 0) {
      setState(() {
        _amountInWords = '${_numberToText(numVal.toInt())} ${KtStrings.rupees} ${KtStrings.only}';
      });
    } else {
      setState(() {
        _amountInWords = '';
      });
    }
  }

  String _numberToText(int n) {
    if (n < 0) return "Minus ${_numberToText(-n)}";
    if (n == 0) return "Zero";

    const units = [
      "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine",
      "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen",
      "Seventeen", "Eighteen", "Nineteen"
    ];
    const tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];

    String convert(int num) {
      if (num < 20) return units[num];
      if (num < 100) return tens[num ~/ 10] + (num % 10 != 0 ? " ${units[num % 10]}" : "");
      if (num < 1000) return "${units[num ~/ 100]} ${KtStrings.hundred}${num % 100 != 0 ? " ${KtStrings.and} ${convert(num % 100)}" : ""}";
      if (num < 100000) return "${convert(num ~/ 1000)} ${KtStrings.thousand}${num % 1000 != 0 ? " ${convert(num % 1000)}" : ""}";
      if (num < 10000000) return "${convert(num ~/ 100000)} ${KtStrings.lakh}${num % 100000 != 0 ? " ${convert(num % 100000)}" : ""}";
      return "${convert(num ~/ 10000000)} ${KtStrings.crore}${num % 10000000 != 0 ? " ${convert(num % 10000000)}" : ""}";
    }

    return convert(n);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: ktCcEmiPrimary,
            onPrimary: Colors.white,
            surface: Color(0xFF1E293B),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  double _getCalculatedPrincipal() {
    return double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
  }

  double _getCalculatedRate() {
    if (_isNoCostEmi) return 0.0;
    return double.tryParse(_interestRateController.text) ?? 0.0;
  }

  double _getCalculatedProcessingFee() {
    return double.tryParse(_processingFeeController.text.replaceAll(',', '')) ?? 0.0;
  }

  double _getCalculatedMonthlyEmi() {
    final p = _getCalculatedPrincipal();
    final r = _getCalculatedRate();
    return CreditCardEmiRecord.calculateEmi(p, r, _selectedTenure);
  }

  double _getCalculatedTotalInterest() {
    final p = _getCalculatedPrincipal();
    final emi = _getCalculatedMonthlyEmi();
    return CreditCardEmiRecord.calculateTotalInterest(emi, _selectedTenure, p);
  }

  double _getCalculatedTotalPayable() {
    return _getCalculatedPrincipal() + _getCalculatedTotalInterest() + _getCalculatedProcessingFee();
  }

  DateTime _getCalculatedEndDate() {
    return DateTime(_purchaseDate.year, _purchaseDate.month + _selectedTenure, _selectedDueDay);
  }

  String _formatCurrency(double value) {
    return NumberFormat('#,##,###', 'en_IN').format(value);
  }

  Future<void> _saveEmiRecord() async {
    if (!_formKey.currentState!.validate()) return;

    if (_cardNameController.text.trim().isEmpty) {
      ktShowCustomToast(context, KtStrings.enterCardNameWarning);
      return;
    }

    if (_merchantController.text.trim().isEmpty) {
      ktShowCustomToast(context, KtStrings.enterMerchantWarning);
      return;
    }

    final principal = _getCalculatedPrincipal();
    if (principal <= 0) {
      ktShowCustomToast(context, KtStrings.enterValidAmountHint);
      return;
    }

    setState(() => _loading = true);

    final emiVal = _getCalculatedMonthlyEmi();
    final interestVal = _getCalculatedTotalInterest();
    final payableVal = _getCalculatedTotalPayable();
    final dateStr = ktFormatDate(_purchaseDate); // Rule: Project Date format

    final record = CreditCardEmiRecord(
      id: widget.editRecord?.id,
      cardName: _cardNameController.text.trim(),
      merchantName: _merchantController.text.trim(),
      purchaseDate: dateStr,
      totalAmount: principal,
      interestRate: _getCalculatedRate(),
      tenureMonths: _selectedTenure,
      monthlyEmi: emiVal,
      processingFee: _getCalculatedProcessingFee(),
      totalInterest: interestVal,
      totalPayable: payableVal,
      emisPaid: widget.editRecord?.emisPaid ?? 0,
      dueDay: _selectedDueDay,
      firstEmiDate: ktFormatDate(DateTime(_purchaseDate.year, _purchaseDate.month + 1, _selectedDueDay)),
      status: widget.editRecord?.status ?? 'Active',
      category: _selectedCategory,
      remarks: _remarksController.text.trim(),
      repayments: widget.editRecord?.repayments ?? [],
    );

    final success = await _service.saveRecord(record);

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      ktShowCustomToast(
        context,
        widget.editRecord != null ? KtStrings.ccEmiRecordUpdated : KtStrings.ccEmiRecordSaved,
      );
      Navigator.pop(context, true);
    } else {
      ktShowCustomToast(context, KtStrings.saveFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? ktBgDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ktCcEmiPrimary, ktCcEmiSecondary],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.editRecord != null ? KtStrings.editCcEmi : KtStrings.addCcEmi,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  KtStrings.creditCardEmiSubtitle,
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ktHeaderIcon(Icons.history_rounded, () {
              Navigator.pushReplacementNamed(context, '/report/credit_card_emi');
            }),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Summary Card
                  _buildLiveCalculationCard(isDark),
                  const SizedBox(height: 24),

                  // Card Bank Selection
                  _buildSectionHeader(KtStrings.cardNameLabel, Icons.account_balance_rounded, isDark),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _popularCards.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final bank = _popularCards[index];
                        final isSelected = _cardNameController.text == bank;
                        return ChoiceChip(
                          label: Text(
                            bank,
                            style: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: ktCcEmiPrimary,
                          backgroundColor: isDark ? ktCardBg : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? ktCcEmiPrimary : (isDark ? ktBorderWhite10 : Colors.black12),
                            ),
                          ),
                          onSelected: (val) {
                            setState(() {
                              _cardNameController.text = bank;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _cardNameController,
                    hint: KtStrings.enterCardNameHint,
                    icon: Icons.credit_card_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // Merchant Name
                  _buildSectionHeader(KtStrings.merchantNameLabel, Icons.shopping_bag_rounded, isDark),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _merchantController,
                    hint: KtStrings.enterMerchantHint,
                    icon: Icons.storefront_rounded,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // Category & Date Row
                  Row(
                    children: [
                      // Category
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(KtStrings.categoryLabel, Icons.category_rounded, isDark),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark ? ktCardBg : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  dropdownColor: isDark ? ktSlate800 : Colors.white,
                                  items: _categories.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat,
                                      child: Text(
                                        cat,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedCategory = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Purchase Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(KtStrings.purchaseDateLabel, Icons.calendar_today_rounded, isDark),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _selectDate(context),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark ? ktCardBg : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.event_note_rounded, color: ktCcEmiPrimary, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ktFormatDate(_purchaseDate), // Project rule: Date format
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 20),

                  // Purchase Amount & In Words
                  _buildSectionHeader(KtStrings.purchaseAmountLabel, Icons.currency_rupee_rounded, isDark),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _amountController,
                    hint: '0',
                    icon: Icons.currency_rupee_rounded,
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                  ),
                  if (_amountInWords.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        _amountInWords,
                        style: const TextStyle(
                          color: ktEmerald,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // No Cost EMI Switch & Interest Rate
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? ktCardBg : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: ktEmerald.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.percent_rounded, color: ktEmerald, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  KtStrings.noCostEmiLabel,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isNoCostEmi,
                              activeColor: ktEmerald,
                              onChanged: (val) {
                                setState(() {
                                  _isNoCostEmi = val;
                                  if (val) {
                                    _interestRateController.text = '0';
                                  } else {
                                    _interestRateController.text = '14.0';
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        if (!_isNoCostEmi) ...[
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          _buildTextField(
                            controller: _interestRateController,
                            hint: '14.0',
                            label: KtStrings.interestRateLabel,
                            icon: Icons.speed_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tenure Selection
                  _buildSectionHeader(KtStrings.tenureMonthsLabel, Icons.timelapse_rounded, isDark),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tenureOptions.map((tenure) {
                      final isSelected = _selectedTenure == tenure;
                      return ChoiceChip(
                        label: Text(
                          '$tenure M',
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: ktCcEmiPrimary,
                        backgroundColor: isDark ? ktCardBg : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? ktCcEmiPrimary : (isDark ? ktBorderWhite10 : Colors.black12),
                          ),
                        ),
                        onSelected: (val) {
                          setState(() => _selectedTenure = tenure);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Processing Fee & Due Day Row
                  Row(
                    children: [
                      // Processing Fee
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(KtStrings.processingFeeLabel, Icons.receipt_rounded, isDark),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _processingFeeController,
                              hint: '0',
                              icon: Icons.receipt_rounded,
                              keyboardType: TextInputType.number,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Monthly Due Day
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(KtStrings.dueDayLabel, Icons.event_repeat_rounded, isDark),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isDark ? ktCardBg : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedDueDay,
                                  isExpanded: true,
                                  dropdownColor: isDark ? ktSlate800 : Colors.white,
                                  items: _dueDayOptions.map((day) {
                                    return DropdownMenuItem(
                                      value: day,
                                      child: Text(
                                        'Day $day',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedDueDay = val);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Remarks Optional
                  _buildSectionHeader(KtStrings.remarksOptional, Icons.notes_rounded, isDark),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _remarksController,
                    hint: 'Additional details or notes...',
                    icon: Icons.edit_note_rounded,
                    isDark: isDark,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _saveEmiRecord,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ktCcEmiPrimary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: ktCcEmiPrimary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  widget.editRecord != null ? Icons.check_circle_rounded : Icons.save_rounded,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.editRecord != null ? KtStrings.updateRecord : KtStrings.saveRecord,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ktCcEmiPrimary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? label,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13),
        prefixIcon: Icon(icon, color: ktCcEmiPrimary, size: 20),
        filled: true,
        fillColor: isDark ? ktCardBg : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? ktBorderWhite10 : Colors.black12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? ktBorderWhite10 : Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: ktCcEmiPrimary, width: 2),
        ),
      ),
    );
  }

  Widget _buildLiveCalculationCard(bool isDark) {
    final emi = _getCalculatedMonthlyEmi();
    final interest = _getCalculatedTotalInterest();
    final payable = _getCalculatedTotalPayable();
    final endDate = _getCalculatedEndDate();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF311B92)]
              : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isNoCostEmi ? '0% NO COST EMI' : 'STANDARD EMI',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Icon(
                Icons.analytics_rounded,
                color: Colors.white.withValues(alpha: 0.8),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            KtStrings.monthlyEmiLabel.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '₹${_formatCurrency(emi)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ month x $_selectedTenure M',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  KtStrings.totalInterestLabel,
                  '₹${_formatCurrency(interest)}',
                ),
              ),
              Container(width: 1, height: 28, color: Colors.white24),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildMetricItem(
                    KtStrings.totalPayableLabel,
                    '₹${_formatCurrency(payable)}',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 14, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text(
                'Est. Completion: ${ktFormatDate(endDate)}', // Project rule: Date format
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
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
  }
}
