import 'package:flutter/material.dart';
import '../core_constants.dart';
import 'calculator_components.dart';

class PercentageCalculator extends StatelessWidget {
  const PercentageCalculator({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final options = [
      _PercentOption(
        title: 'Basic Calculator',
        subtitle: 'Percentage, increase, decrease',
        icon: Icons.calculate_outlined,
        color: const Color(0xFF1E3A8A), // Dark Blue
        route: '/calculator/percentage/basic',
      ),
      _PercentOption(
        title: 'Discount',
        subtitle: 'Shopping and final prices',
        icon: Icons.shopping_cart_outlined,
        color: const Color(0xFF064E3B), // Dark Emerald / Green
        route: '/calculator/percentage/discount',
      ),
      _PercentOption(
        title: 'GST & Tax',
        subtitle: 'CGST, SGST, IGST',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF78350F), // Dark Amber / Brown
        route: '/calculator/percentage/gst',
      ),
      _PercentOption(
        title: 'Profit & Loss',
        subtitle: 'Margin, markup, profit',
        icon: Icons.insights_rounded,
        color: const Color(0xFF311050), // Dark Purple
        route: '/calculator/percentage/profit_loss',
      ),
      _PercentOption(
        title: 'Salary & Finance',
        subtitle: 'Hikes, interest, growth',
        icon: Icons.account_balance_wallet_outlined,
        color: const Color(0xFF022C22), // Dark Teal
        route: '/calculator/percentage/salary',
      ),
      _PercentOption(
        title: 'Education',
        subtitle: 'Marks, attendance, grades',
        icon: Icons.school_outlined,
        color: const Color(0xFF581C87), // Dark Maroon / Burgundy
        route: '/calculator/percentage/education',
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? ktBgDark : ktLightScaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? ktTextWhite : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Smart Percentage Calculator',
          style: TextStyle(color: isDark ? ktTextWhite : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.9,
                  ),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final opt = options[index];
                    return InkWell(
                      onTap: () => Navigator.pushNamed(context, opt.route),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: opt.color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(opt.icon, color: ktCyan, size: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  opt.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt.subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 10.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.history, size: 16, color: ktTextGray400),
                        SizedBox(width: 8),
                        Text('Calculation History', style: TextStyle(color: ktTextWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.star_border, size: 16, color: ktTextGray400),
                        SizedBox(width: 6),
                        Text('Favorites', style: TextStyle(color: ktTextWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
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
}

class _PercentOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  _PercentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

// 1. Basic Calculator Hub Screen
class BasicCalculatorScreen extends StatefulWidget {
  const BasicCalculatorScreen({super.key});

  @override
  State<BasicCalculatorScreen> createState() => _BasicCalculatorScreenState();
}

class _BasicCalculatorScreenState extends State<BasicCalculatorScreen> {
  int _mode = 0;
  final _val1Controller = TextEditingController();
  final _val2Controller = TextEditingController();

  void _calculate() {
    double v1 = double.tryParse(_val1Controller.text.replaceAll(',', '')) ?? 0;
    double v2 = double.tryParse(_val2Controller.text.replaceAll(',', '')) ?? 0;

    if (_mode == 0) {
      double res = (v1 * v2) / 100;
      showCalcResultBottomSheet(
        context: context,
        title: 'What is $v1% of $v2?',
        icon: Icons.percent,
        themeColor: ktCyan,
        resultWidget: CalcResultCard(
          title: 'Detailed Calculation Steps',
          children: [
            CalcResultRow(label: 'Result Value', value: res.toStringAsFixed(2), color: ktCyan),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Formula', value: '($v1 ÷ 100) × $v2', color: ktTextGray400),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Step 1', value: '$v1 ÷ 100 = ${v1 / 100}', color: ktOrange),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Step 2', value: '${v1 / 100} × $v2 = $res', color: ktEmerald),
          ],
        ),
      );
    } else if (_mode == 1) {
      if (v2 == 0) return;
      double res = (v1 / v2) * 100;
      showCalcResultBottomSheet(
        context: context,
        title: '$v1 is what % of $v2?',
        icon: Icons.pie_chart_rounded,
        themeColor: ktEmerald,
        resultWidget: CalcResultCard(
          title: 'Detailed Calculation Steps',
          children: [
            CalcResultRow(label: 'Percentage', value: '${res.toStringAsFixed(2)}%', color: ktEmerald),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Formula', value: '($v1 ÷ $v2) × 100', color: ktTextGray400),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Step 1', value: '$v1 ÷ $v2 = ${v1 / v2}', color: ktOrange),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Step 2', value: '${v1 / v2} × 100 = ${res.toStringAsFixed(2)}%', color: ktCyan),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'Basic Calculator',
      inputs: [
        Row(
          children: [
            Expanded(child: _tabBtn(0, 'X% of Y')),
            const SizedBox(width: 8),
            Expanded(child: _tabBtn(1, 'X is % of Y')),
          ],
        ),
        const SizedBox(height: 20),
        CalcInput(
          label: _mode == 0 ? 'Percentage (X)' : 'Part Value (X)',
          controller: _val1Controller,
          hint: 'e.g. 15',
          isCurrency: true,
        ),
        const SizedBox(height: 12),
        CalcInput(
          label: 'Whole Value (Y)',
          controller: _val2Controller,
          hint: 'e.g. 1,00,000',
          isCurrency: true,
        ),
      ],
      actions: [
        CalcButton(label: 'Calculate', icon: Icons.calculate, color: ktCyan, onPressed: _calculate),
      ],
    );
  }

  Widget _tabBtn(int idx, String label) {
    final active = _mode == idx;
    return InkWell(
      onTap: () => setState(() => _mode = idx),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? ktCyan.withValues(alpha: 0.2) : ktBorderWhite5,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? ktCyan : Colors.transparent),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: active ? ktCyan : ktTextGray400, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}

// 2. Discount Calculator Screen
class DiscountCalculatorScreen extends StatefulWidget {
  const DiscountCalculatorScreen({super.key});

  @override
  State<DiscountCalculatorScreen> createState() => _DiscountCalculatorScreenState();
}

class _DiscountCalculatorScreenState extends State<DiscountCalculatorScreen> {
  final _priceController = TextEditingController();
  final _discountController = TextEditingController();

  void _calculate() {
    double price = double.tryParse(_priceController.text.replaceAll(',', '')) ?? 0;
    double disc = double.tryParse(_discountController.text.replaceAll(',', '')) ?? 0;
    double saveAmount = (price * disc) / 100;
    double finalPrice = price - saveAmount;

    showCalcResultBottomSheet(
      context: context,
      title: 'Discount Calculation Summary',
      icon: Icons.shopping_cart_outlined,
      themeColor: ktEmerald,
      resultWidget: CalcResultCard(
        title: 'Detailed Breakdown',
        children: [
          CalcResultRow(label: 'Final Price', value: finalPrice.toStringAsFixed(2), color: ktEmerald),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'You Save', value: saveAmount.toStringAsFixed(2), color: ktCyan),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Original Price', value: price.toStringAsFixed(2), color: ktTextGray400),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Formula', value: 'Price - (Price × Discount ÷ 100)', color: ktTextGray400),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'Discount Calculator',
      inputs: [
        CalcInput(label: 'Original Price', controller: _priceController, hint: 'e.g. 2,500', isCurrency: true),
        const SizedBox(height: 12),
        CalcInput(label: 'Discount Percentage (%)', controller: _discountController, hint: 'e.g. 20', isCurrency: true, suffix: const Padding(padding: EdgeInsets.all(16), child: Text('%', style: TextStyle(color: ktTextGray400)))),
      ],
      actions: [
        CalcButton(label: 'Calculate', icon: Icons.calculate, color: ktEmerald, onPressed: _calculate),
      ],
    );
  }
}

// 3. GST & Tax Calculator Screen
class GstTaxCalculatorScreen extends StatefulWidget {
  const GstTaxCalculatorScreen({super.key});

  @override
  State<GstTaxCalculatorScreen> createState() => _GstTaxCalculatorScreenState();
}

class _GstTaxCalculatorScreenState extends State<GstTaxCalculatorScreen> {
  final _amountController = TextEditingController();
  final _gstRateController = TextEditingController(text: '18');
  bool _isExclusive = true;

  void _calculate() {
    double amt = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    double rate = double.tryParse(_gstRateController.text.replaceAll(',', '')) ?? 0;

    double netAmount, gstAmount, grossAmount;
    if (_isExclusive) {
      netAmount = amt;
      gstAmount = (amt * rate) / 100;
      grossAmount = netAmount + gstAmount;
    } else {
      grossAmount = amt;
      netAmount = amt / (1 + (rate / 100));
      gstAmount = grossAmount - netAmount;
    }

    showCalcResultBottomSheet(
      context: context,
      title: 'GST & Tax Breakdown',
      icon: Icons.receipt_long_outlined,
      themeColor: ktOrange,
      resultWidget: CalcResultCard(
        title: 'Detailed Tax Summary',
        children: [
          CalcResultRow(label: 'Net Amount', value: netAmount.toStringAsFixed(2), color: ktCyan),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Total GST ($rate%)', value: gstAmount.toStringAsFixed(2), color: ktOrange),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'CGST (${rate / 2}%)', value: (gstAmount / 2).toStringAsFixed(2), color: ktTextGray400),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'SGST (${rate / 2}%)', value: (gstAmount / 2).toStringAsFixed(2), color: ktTextGray400),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Gross Total', value: grossAmount.toStringAsFixed(2), color: ktEmerald),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'GST & Tax Calculator',
      inputs: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: ktBorderWhite5, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isExclusive = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: _isExclusive ? ktOrange : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text('Exclusive', style: TextStyle(color: _isExclusive ? Colors.white : ktTextGray400, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isExclusive = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(color: !_isExclusive ? ktOrange : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text('Inclusive', style: TextStyle(color: !_isExclusive ? Colors.white : ktTextGray400, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CalcInput(label: 'Amount', controller: _amountController, hint: 'e.g. 10,000', isCurrency: true),
        const SizedBox(height: 12),
        CalcInput(label: 'GST Rate (%)', controller: _gstRateController, hint: '18', isCurrency: true, suffix: const Padding(padding: EdgeInsets.all(16), child: Text('%', style: TextStyle(color: ktTextGray400)))),
      ],
      actions: [
        CalcButton(label: 'Calculate', icon: Icons.calculate, color: ktOrange, onPressed: _calculate),
      ],
    );
  }
}

// 4. Profit & Loss Calculator Screen
class ProfitLossCalculatorScreen extends StatefulWidget {
  const ProfitLossCalculatorScreen({super.key});

  @override
  State<ProfitLossCalculatorScreen> createState() => _ProfitLossCalculatorScreenState();
}

class _ProfitLossCalculatorScreenState extends State<ProfitLossCalculatorScreen> {
  final _cpController = TextEditingController();
  final _spController = TextEditingController();

  void _calculate() {
    double cp = double.tryParse(_cpController.text.replaceAll(',', '')) ?? 0;
    double sp = double.tryParse(_spController.text.replaceAll(',', '')) ?? 0;
    double diff = sp - cp;
    double pct = cp > 0 ? (diff.abs() / cp) * 100 : 0;
    bool isProfit = diff >= 0;

    showCalcResultBottomSheet(
      context: context,
      title: isProfit ? 'Profit Summary' : 'Loss Summary',
      icon: Icons.insights_rounded,
      themeColor: isProfit ? ktEmerald : ktRose,
      resultWidget: CalcResultCard(
        title: 'Detailed Breakdown',
        children: [
          CalcResultRow(label: isProfit ? 'Net Profit' : 'Net Loss', value: diff.abs().toStringAsFixed(2), color: isProfit ? ktEmerald : ktRose),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Percentage', value: '${pct.toStringAsFixed(2)}%', color: isProfit ? ktEmerald : ktRose),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Cost Price (CP)', value: cp.toStringAsFixed(2), color: ktTextGray400),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Selling Price (SP)', value: sp.toStringAsFixed(2), color: ktTextGray400),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'Profit & Loss Calculator',
      inputs: [
        CalcInput(label: 'Cost Price (CP)', controller: _cpController, hint: 'e.g. 1,000', isCurrency: true),
        const SizedBox(height: 12),
        CalcInput(label: 'Selling Price (SP)', controller: _spController, hint: 'e.g. 1,250', isCurrency: true),
      ],
      actions: [
        CalcButton(label: 'Calculate', icon: Icons.calculate, color: ktSecondary, onPressed: _calculate),
      ],
    );
  }
}

// 5. Salary & Finance Calculator Screen
class SalaryFinanceCalculatorScreen extends StatefulWidget {
  const SalaryFinanceCalculatorScreen({super.key});

  @override
  State<SalaryFinanceCalculatorScreen> createState() => _SalaryFinanceCalculatorScreenState();
}

class _SalaryFinanceCalculatorScreenState extends State<SalaryFinanceCalculatorScreen> {
  final _salaryController = TextEditingController();
  final _hikeController = TextEditingController();

  void _calculate() {
    double sal = double.tryParse(_salaryController.text.replaceAll(',', '')) ?? 0;
    double hike = double.tryParse(_hikeController.text.replaceAll(',', '')) ?? 0;
    double hikeAmount = (sal * hike) / 100;
    double newSalary = sal + hikeAmount;

    showCalcResultBottomSheet(
      context: context,
      title: 'Salary Hike Summary',
      icon: Icons.account_balance_wallet_outlined,
      themeColor: ktCyan,
      resultWidget: CalcResultCard(
        title: 'Detailed Breakdown',
        children: [
          CalcResultRow(label: 'New Annual Salary', value: newSalary.toStringAsFixed(2), color: ktCyan),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Hike Amount', value: hikeAmount.toStringAsFixed(2), color: ktEmerald),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Monthly Increase', value: (hikeAmount / 12).toStringAsFixed(2), color: ktOrange),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Current Salary', value: sal.toStringAsFixed(2), color: ktTextGray400),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'Salary & Finance Calculator',
      inputs: [
        CalcInput(label: 'Current Salary', controller: _salaryController, hint: 'e.g. 6,00,000', isCurrency: true),
        const SizedBox(height: 12),
        CalcInput(label: 'Hike Percentage (%)', controller: _hikeController, hint: 'e.g. 15', isCurrency: true, suffix: const Padding(padding: EdgeInsets.all(16), child: Text('%', style: TextStyle(color: ktTextGray400)))),
      ],
      actions: [
        CalcButton(label: 'Calculate', icon: Icons.calculate, color: ktCyan, onPressed: _calculate),
      ],
    );
  }
}

// 6. Education Calculator Screen
class EducationCalculatorScreen extends StatefulWidget {
  const EducationCalculatorScreen({super.key});

  @override
  State<EducationCalculatorScreen> createState() => _EducationCalculatorScreenState();
}

class _EducationCalculatorScreenState extends State<EducationCalculatorScreen> {
  final _obtainedController = TextEditingController();
  final _totalController = TextEditingController();

  void _calculate() {
    double ob = double.tryParse(_obtainedController.text.replaceAll(',', '')) ?? 0;
    double tot = double.tryParse(_totalController.text.replaceAll(',', '')) ?? 0;
    if (tot == 0) return;
    double percentage = (ob / tot) * 100;

    String grade = 'F';
    if (percentage >= 90) {
      grade = 'A+ (Distinction)';
    } else if (percentage >= 80) {
      grade = 'A (First Class)';
    } else if (percentage >= 70) {
      grade = 'B (Second Class)';
    } else if (percentage >= 60) {
      grade = 'C (Pass)';
    } else if (percentage >= 50) {
      grade = 'D (Pass)';
    }

    showCalcResultBottomSheet(
      context: context,
      title: 'Academic Results Summary',
      icon: Icons.school_outlined,
      themeColor: ktSecondary,
      resultWidget: CalcResultCard(
        title: 'Detailed Breakdown',
        children: [
          CalcResultRow(label: 'Percentage', value: '${percentage.toStringAsFixed(2)}%', color: ktSecondary),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Grade / Status', value: grade, color: ktEmerald),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Marks Obtained', value: ob.toStringAsFixed(0), color: ktTextGray400),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Total Marks', value: tot.toStringAsFixed(0), color: ktTextGray400),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'Education Calculator',
      inputs: [
        CalcInput(label: 'Marks Obtained', controller: _obtainedController, hint: 'e.g. 450', isCurrency: true),
        const SizedBox(height: 12),
        CalcInput(label: 'Total Marks', controller: _totalController, hint: 'e.g. 500', isCurrency: true),
      ],
      actions: [
        CalcButton(label: 'Calculate', icon: Icons.calculate, color: ktSecondary, onPressed: _calculate),
      ],
    );
  }
}
