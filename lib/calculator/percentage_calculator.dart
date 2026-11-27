import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core_constants.dart';
import 'calculator_components.dart';

class PercentageCalculator extends StatefulWidget {
  const PercentageCalculator({super.key});

  @override
  State<PercentageCalculator> createState() => _PercentageCalculatorState();
}

class _PercentageCalculatorState extends State<PercentageCalculator> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Calculator Settings', style: TextStyle(color: isDark ? ktTextWhite : Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(height: 24),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: ktCyan),
                title: Text('Precision / Decimal Places', style: TextStyle(color: isDark ? ktTextWhite : Colors.black87)),
                subtitle: const Text('Default (2 decimals)', style: TextStyle(color: ktTextGray400, fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, color: ktTextGray400),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Precision setting updated')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline, color: ktSecondary),
                title: Text('About Smart Percentage', style: TextStyle(color: isDark ? ktTextWhite : Colors.black87)),
                subtitle: const Text('Version 1.0.0', style: TextStyle(color: ktTextGray400, fontSize: 11)),
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }

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
      _PercentOption(
        title: 'Income Tax',
        subtitle: 'India (New/Old) & Global slabs',
        icon: Icons.account_balance_outlined,
        color: const Color(0xFF1E293B), // Dark Slate / Navy
        route: '/calculator/percentage/income_tax',
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? ktBgDark : ktLightScaffoldBg,
      body: Stack(
        children: [
          const _ParticleBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 900),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.8,
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
                          ),
                          const SizedBox(height: 16),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: isDark
                        ? const [ktTextWhite, Colors.white38, ktTextWhite]
                        : const [Colors.black87, Colors.black45, Colors.black87],
                    stops: [
                      _shimmerController.value - 0.2,
                      _shimmerController.value,
                      _shimmerController.value + 0.2,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: const Text(
                  'Smart Percentage Calculator',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _openSettings(context),
                icon: Icon(Icons.settings_outlined, color: isDark ? ktTextWhite : Colors.black87, size: 20),
                tooltip: 'Settings',
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? ktBorderWhite5 : Colors.black.withValues(alpha: 0.05),
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: isDark ? ktTextWhite : Colors.black87, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? ktBorderWhite5 : Colors.black.withValues(alpha: 0.05),
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
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

class _ParticleBackground extends StatefulWidget {
  const _ParticleBackground();
  @override
  State<_ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<_ParticleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = List.generate(40, (i) => _Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..addListener(() => setState(() {
      for (var p in _particles) { p.update(); }
    })) ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(size: Size.infinite, painter: _ParticlePainter(particles: _particles, isDark: isDark));
  }
}

class _Particle {
  late double x, y, vx, vy, size;
  _Particle() {
    final rand = math.Random();
    x = rand.nextDouble() * 1000;
    y = rand.nextDouble() * 1000;
    vx = (rand.nextDouble() - 0.5) * 0.5;
    vy = (rand.nextDouble() - 0.5) * 0.5;
    size = rand.nextDouble() * 2 + 1;
  }
  void update() {
    x += vx; y += vy;
    if (x < 0 || x > 1000) vx *= -1;
    if (y < 0 || y > 1000) vy *= -1;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final bool isDark;
  _ParticlePainter({required this.particles, required this.isDark});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    for (var p in particles) {
      final pos = Offset(p.x / 1000 * size.width, p.y / 1000 * size.height);
      canvas.drawCircle(pos, p.size, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 1. Basic Calculator Hub Screen
class BasicCalculatorScreen extends StatefulWidget {
  const BasicCalculatorScreen({super.key});

  @override
  State<BasicCalculatorScreen> createState() => _BasicCalculatorScreenState();
}

class _BasicCalculatorScreenState extends State<BasicCalculatorScreen> {
  int _mode = 0; // 0: X% of Y, 1: X is % of Y, 2: Inc/Dec, 3: % Diff
  bool _incDecMode = true; // true = increase, false = decrease
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
            CalcResultRow(label: 'Result Value', value: formatIndianCurrency(res), color: ktCyan),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Formula', value: '($v1 ÷ 100) × $v2', color: ktTextGray400),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Step 1', value: '$v1 ÷ 100 = ${v1 / 100}', color: ktOrange),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Step 2', value: '${v1 / 100} × $v2 = ${formatIndianCurrency(res)}', color: ktEmerald),
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
    } else if (_mode == 2) {
      double diff = (v1 * v2) / 100;
      double res = _incDecMode ? v1 + diff : v1 - diff;
      showCalcResultBottomSheet(
        context: context,
        title: '${_incDecMode ? "Increase" : "Decrease"} $v1 by $v2%',
        icon: Icons.trending_up_rounded,
        themeColor: ktOrange,
        resultWidget: CalcResultCard(
          title: 'Detailed Calculation Steps',
          children: [
            CalcResultRow(label: 'Final Value', value: formatIndianCurrency(res), color: ktOrange),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Difference', value: (_incDecMode ? '+' : '-') + formatIndianCurrency(diff), color: _incDecMode ? ktEmerald : ktRose),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Formula', value: '$v1 ${_incDecMode ? '+' : '-'} ($v1 × $v2 ÷ 100)', color: ktTextGray400),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Step 1', value: '$v1 × $v2 ÷ 100 = ${formatIndianCurrency(diff)}', color: ktCyan),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Step 2', value: '$v1 ${_incDecMode ? '+' : '-'} ${formatIndianCurrency(diff)} = ${formatIndianCurrency(res)}', color: ktEmerald),
          ],
        ),
      );
    } else if (_mode == 3) {
      if (v1 + v2 == 0) return;
      double absDiff = (v1 - v2).abs();
      double avg = (v1 + v2) / 2;
      double res = (absDiff / avg) * 100;
      showCalcResultBottomSheet(
        context: context,
        title: 'Percentage Difference',
        icon: Icons.compare_arrows_rounded,
        themeColor: ktSecondary,
        resultWidget: CalcResultCard(
          title: 'Detailed Calculation Steps',
          children: [
            CalcResultRow(label: 'Percentage Difference', value: '${res.toStringAsFixed(2)}%', color: ktSecondary),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Absolute Difference', value: formatIndianCurrency(absDiff), color: ktOrange),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Formula', value: '(|A - B| ÷ ((A + B) ÷ 2)) × 100', color: ktTextGray400),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Step 1', value: '|$v1 - $v2| = ${formatIndianCurrency(absDiff)}', color: ktCyan),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Step 2', value: '($v1 + $v2) ÷ 2 = $avg', color: ktEmerald),
            const Divider(color: ktBorderWhite5, height: 24),
            CalcResultRow(label: 'Step 3', value: '(${formatIndianCurrency(absDiff)} ÷ $avg) × 100 = ${res.toStringAsFixed(2)}%', color: ktSecondary),
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _tabBtn(0, 'X% of Y'),
              const SizedBox(width: 8),
              _tabBtn(1, 'X is % of Y'),
              const SizedBox(width: 8),
              _tabBtn(2, 'Inc / Dec'),
              const SizedBox(width: 8),
              _tabBtn(3, '% Diff'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_mode == 2) ...[
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: ktBorderWhite5, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _incDecMode = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: _incDecMode ? ktEmerald : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text('Increase', style: TextStyle(color: _incDecMode ? Colors.white : ktTextGray400, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _incDecMode = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: !_incDecMode ? ktRose : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text('Decrease', style: TextStyle(color: !_incDecMode ? Colors.white : ktTextGray400, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        CalcInput(
          label: _mode == 0 ? 'Percentage (X)' : (_mode == 1 ? 'Part Value (X)' : (_mode == 2 ? 'Initial Value' : 'Value A')),
          controller: _val1Controller,
          hint: 'e.g. 15',
          isCurrency: true,
          suffix: _mode == 0 ? const Padding(padding: EdgeInsets.all(16), child: Text('%', style: TextStyle(color: ktTextGray400))) : null,
        ),
        const SizedBox(height: 12),
        CalcInput(
          label: _mode == 0 ? 'Whole Value (Y)' : (_mode == 1 ? 'Whole Value (Y)' : (_mode == 2 ? 'Percentage (%)' : 'Value B')),
          controller: _val2Controller,
          hint: 'e.g. 1,00,000',
          isCurrency: true,
          suffix: _mode == 2 ? const Padding(padding: EdgeInsets.all(16), child: Text('%', style: TextStyle(color: ktTextGray400))) : null,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
          CalcResultRow(label: 'Final Price', value: formatIndianCurrency(finalPrice), color: ktEmerald),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'You Save', value: formatIndianCurrency(saveAmount), color: ktCyan),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Original Price', value: formatIndianCurrency(price), color: ktTextGray400),
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
          CalcResultRow(label: 'Net Amount', value: formatIndianCurrency(netAmount), color: ktCyan),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Total GST ($rate%)', value: formatIndianCurrency(gstAmount), color: ktOrange),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'CGST (${rate / 2}%)', value: formatIndianCurrency(gstAmount / 2), color: ktTextGray400),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'SGST (${rate / 2}%)', value: formatIndianCurrency(gstAmount / 2), color: ktTextGray400),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Gross Total', value: formatIndianCurrency(grossAmount), color: ktEmerald),
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
          CalcResultRow(label: isProfit ? 'Net Profit' : 'Net Loss', value: formatIndianCurrency(diff.abs()), color: isProfit ? ktEmerald : ktRose),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Percentage', value: '${pct.toStringAsFixed(2)}%', color: isProfit ? ktEmerald : ktRose),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Cost Price (CP)', value: formatIndianCurrency(cp), color: ktTextGray400),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Selling Price (SP)', value: formatIndianCurrency(sp), color: ktTextGray400),
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
          CalcResultRow(label: 'New Annual Salary', value: formatIndianCurrency(newSalary), color: ktCyan),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Hike Amount', value: formatIndianCurrency(hikeAmount), color: ktEmerald),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Monthly Increase', value: formatIndianCurrency(hikeAmount / 12), color: ktOrange),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Current Salary', value: formatIndianCurrency(sal), color: ktTextGray400),
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

// 7. Income Tax Calculator Screen
class IncomeTaxCalculatorScreen extends StatefulWidget {
  const IncomeTaxCalculatorScreen({super.key});

  @override
  State<IncomeTaxCalculatorScreen> createState() => _IncomeTaxCalculatorScreenState();
}

class _IncomeTaxCalculatorScreenState extends State<IncomeTaxCalculatorScreen> {
  String _country = 'India'; // 'India' or 'Other'
  bool _isNewRegime = true; // true for New, false for Old (for India)

  final _incomeController = TextEditingController();
  final _sec80cController = TextEditingController(text: '1,50,000');
  final _sec80dController = TextEditingController(text: '25,000');
  final _homeLoanController = TextEditingController(text: '0');
  final _npsController = TextEditingController(text: '0');

  void _calculate() {
    double grossIncome = double.tryParse(_incomeController.text.replaceAll(',', '')) ?? 0;
    double sec80c = double.tryParse(_sec80cController.text.replaceAll(',', '')) ?? 0;
    if (sec80c > 150000) sec80c = 150000;
    double sec80d = double.tryParse(_sec80dController.text.replaceAll(',', '')) ?? 0;
    double homeLoan = double.tryParse(_homeLoanController.text.replaceAll(',', '')) ?? 0;
    if (homeLoan > 200000) homeLoan = 200000;
    double nps = double.tryParse(_npsController.text.replaceAll(',', '')) ?? 0;
    if (nps > 50000) nps = 50000;

    double totalDeductions = sec80c + sec80d + homeLoan + nps;

    double standardDeduction = _country == 'India' ? (_isNewRegime ? 75000 : 50000) : 15000;
    double taxableIncome = grossIncome - standardDeduction - (_isNewRegime ? 0 : totalDeductions);
    if (taxableIncome < 0) taxableIncome = 0;

    double tax = 0;
    List<String> steps = [];

    if (_country == 'India') {
      if (_isNewRegime) {
        steps.add('Standard Deduction: ₹$standardDeduction');
        steps.add('Net Taxable Income: ₹$taxableIncome');

        if (taxableIncome <= 700000) {
          tax = 0;
          steps.add('Rebate u/s 87A: Income <= ₹7L, Tax = ₹0');
        } else {
          double rem = taxableIncome;
          if (rem > 300000) {
            double slabAmt = math.min(rem - 300000, 400000);
            double slabTax = slabAmt * 0.05;
            tax += slabTax;
            steps.add('₹3L - ₹7L @ 5%: ₹$slabTax');
          }
          if (rem > 700000) {
            double slabAmt = math.min(rem - 700000, 300000);
            double slabTax = slabAmt * 0.10;
            tax += slabTax;
            steps.add('₹7L - ₹10L @ 10%: ₹$slabTax');
          }
          if (rem > 1000000) {
            double slabAmt = math.min(rem - 1000000, 200000);
            double slabTax = slabAmt * 0.15;
            tax += slabTax;
            steps.add('₹10L - ₹12L @ 15%: ₹$slabTax');
          }
          if (rem > 1200000) {
            double slabAmt = math.min(rem - 1200000, 300000);
            double slabTax = slabAmt * 0.20;
            tax += slabTax;
            steps.add('₹12L - ₹15L @ 20%: ₹$slabTax');
          }
          if (rem > 1500000) {
            double slabAmt = rem - 1500000;
            double slabTax = slabAmt * 0.30;
            tax += slabTax;
            steps.add('Above ₹15L @ 30%: ₹$slabTax');
          }
        }
      } else {
        steps.add('Standard Deduction: ₹$standardDeduction');
        steps.add('Total Deductions (80C, 80D, Home Loan, NPS): ₹$totalDeductions');
        steps.add('Net Taxable Income: ₹$taxableIncome');

        if (taxableIncome <= 500000) {
          tax = 0;
          steps.add('Rebate u/s 87A: Income <= ₹5L, Tax = ₹0');
        } else {
          double rem = taxableIncome;
          if (rem > 250000) {
            double slabAmt = math.min(rem - 250000, 250000);
            double slabTax = slabAmt * 0.05;
            tax += slabTax;
            steps.add('₹2.5L - ₹5L @ 5%: ₹$slabTax');
          }
          if (rem > 500000) {
            double slabAmt = math.min(rem - 500000, 500000);
            double slabTax = slabAmt * 0.20;
            tax += slabTax;
            steps.add('₹5L - ₹10L @ 20%: ₹$slabTax');
          }
          if (rem > 1000000) {
            double slabAmt = rem - 1000000;
            double slabTax = slabAmt * 0.30;
            tax += slabTax;
            steps.add('Above ₹10L @ 30%: ₹$slabTax');
          }
        }
      }
    } else {
      steps.add('Standard Deduction: \$$standardDeduction');
      steps.add('Net Taxable Income: \$$taxableIncome');
      if (taxableIncome <= 11000) {
        tax = taxableIncome * 0.10;
        steps.add('Up to \$11,000 @ 10%: \$$tax');
      } else if (taxableIncome <= 44725) {
        tax = 1100 + (taxableIncome - 11000) * 0.12;
        steps.add('Progressive tax up to 12%: \$$tax');
      } else {
        tax = 5147 + (taxableIncome - 44725) * 0.22;
        steps.add('Progressive tax up to 22%: \$$tax');
      }
    }

    double cess = tax * 0.04;
    double totalTax = tax + cess;
    double takeHome = grossIncome - totalTax;

    final pastYearsComparison = _country == 'India' ? _calculatePastFiveYearsTax(grossIncome, totalDeductions, _isNewRegime) : <Map<String, dynamic>>[];

    showCalcResultBottomSheet(
      context: context,
      title: 'Income Tax Calculation Summary',
      icon: Icons.account_balance_outlined,
      themeColor: ktSecondary,
      resultWidget: CalcResultCard(
        title: 'Detailed Tax Breakdown',
        children: [
          CalcResultRow(label: 'Total Tax Payable', value: formatIndianCurrency(totalTax), color: ktRose),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Base Tax', value: formatIndianCurrency(tax), color: ktOrange),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Health & Education Cess (4%)', value: formatIndianCurrency(cess), color: ktTextGray400),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Estimated Take-Home', value: formatIndianCurrency(takeHome), color: ktEmerald),
          const Divider(color: ktBorderWhite5, height: 24),
          ...steps.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('• $s', style: const TextStyle(color: ktTextGray400, fontSize: 11)),
          )),
          if (pastYearsComparison.isNotEmpty) ...[
            const Divider(color: ktBorderWhite5, height: 24),
            const Text(
              'Last 5 Financial Years Tax Comparison',
              style: TextStyle(color: ktTextWhite, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 10),
            ...pastYearsComparison.map((item) {
              final taxVal = item['tax'] as double;
              final pctVal = item['avgPct'] as double;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: CalcResultRow(
                  label: '${item['fy']} (Avg Tax: ${pctVal.toStringAsFixed(2)}%)',
                  value: formatIndianCurrency(taxVal),
                  color: ktCyan,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _calculatePastFiveYearsTax(double grossIncome, double deductions, bool isNewRegime) {
    List<Map<String, dynamic>> results = [];
    results.add(_computeFYResult('FY 2024-25', grossIncome, deductions, isNewRegime, 2024));
    results.add(_computeFYResult('FY 2023-24', grossIncome, deductions, isNewRegime, 2023));
    results.add(_computeFYResult('FY 2022-23', grossIncome, deductions, isNewRegime, 2022));
    results.add(_computeFYResult('FY 2021-22', grossIncome, deductions, isNewRegime, 2021));
    results.add(_computeFYResult('FY 2020-21', grossIncome, deductions, isNewRegime, 2020));
    return results;
  }

  Map<String, dynamic> _computeFYResult(String fyLabel, double grossIncome, double deductions, bool isNewRegime, int fyYear) {
    double tax = _computeIndiaTax(grossIncome, deductions, isNewRegime, fyYear);
    double avgPct = grossIncome > 0 ? (tax / grossIncome) * 100 : 0;
    return {'fy': fyLabel, 'tax': tax, 'avgPct': avgPct};
  }

  double _computeIndiaTax(double grossIncome, double deductions, bool isNewRegime, int fyYear) {
    double stdDed = fyYear >= 2024 && isNewRegime ? 75000 : 50000;
    double taxable = grossIncome - stdDed - (isNewRegime ? 0 : deductions);
    if (taxable < 0) taxable = 0;
    double tax = 0;

    if (isNewRegime) {
      if (fyYear >= 2024) {
        if (taxable <= 700000) return 0;
        double rem = taxable;
        if (rem > 300000) tax += math.min(rem - 300000, 400000) * 0.05;
        if (rem > 700000) tax += math.min(rem - 700000, 300000) * 0.10;
        if (rem > 1000000) tax += math.min(rem - 1000000, 200000) * 0.15;
        if (rem > 1200000) tax += math.min(rem - 1200000, 300000) * 0.20;
        if (rem > 1500000) tax += (rem - 1500000) * 0.30;
      } else if (fyYear == 2023) {
        if (taxable <= 700000) return 0;
        double rem = taxable;
        if (rem > 300000) tax += math.min(rem - 300000, 300000) * 0.05;
        if (rem > 600000) tax += math.min(rem - 600000, 300000) * 0.10;
        if (rem > 900000) tax += math.min(rem - 900000, 300000) * 0.15;
        if (rem > 1200000) tax += math.min(rem - 1200000, 300000) * 0.20;
        if (rem > 1500000) tax += (rem - 1500000) * 0.30;
      } else {
        double rem = taxable;
        if (rem > 250000) tax += math.min(rem - 250000, 250000) * 0.05;
        if (rem > 500000) tax += math.min(rem - 500000, 250000) * 0.10;
        if (rem > 750000) tax += math.min(rem - 750000, 250000) * 0.15;
        if (rem > 1000000) tax += math.min(rem - 1000000, 250000) * 0.20;
        if (rem > 1250000) tax += math.min(rem - 1250000, 250000) * 0.25;
        if (rem > 1500000) tax += (rem - 1500000) * 0.30;
      }
    } else {
      if (taxable <= 500000) return 0;
      double rem = taxable;
      if (rem > 250000) tax += math.min(rem - 250000, 250000) * 0.05;
      if (rem > 500000) tax += math.min(rem - 500000, 500000) * 0.20;
      if (rem > 1000000) tax += (rem - 1000000) * 0.30;
    }

    double cess = tax * 0.04;
    return tax + cess;
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'Income Tax Calculator',
      inputs: [
        Row(
          children: [
            Expanded(child: _countryBtn('India')),
            const SizedBox(width: 8),
            Expanded(child: _countryBtn('Other Countries')),
          ],
        ),
        const SizedBox(height: 16),
        if (_country == 'India') ...[
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: ktBorderWhite5, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isNewRegime = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: _isNewRegime ? ktSecondary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text('New Regime', style: TextStyle(color: _isNewRegime ? Colors.white : ktTextGray400, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isNewRegime = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(color: !_isNewRegime ? ktSecondary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text('Old Regime', style: TextStyle(color: !_isNewRegime ? Colors.white : ktTextGray400, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        CalcInput(label: 'Annual Gross Income', controller: _incomeController, hint: 'e.g. 12,00,000', isCurrency: true),
        if (_country == 'India' && !_isNewRegime) ...[
          const SizedBox(height: 12),
          CalcInput(label: 'Sec 80C (PPF, ELSS, Life Ins. - Max ₹1.5L)', controller: _sec80cController, hint: '1,50,000', isCurrency: true),
          const SizedBox(height: 12),
          CalcInput(label: 'Sec 80D (Health Insurance - Max ₹25K/50K)', controller: _sec80dController, hint: '25,000', isCurrency: true),
          const SizedBox(height: 12),
          CalcInput(label: 'Sec 24 (Home Loan Interest - Max ₹2L)', controller: _homeLoanController, hint: '0', isCurrency: true),
          const SizedBox(height: 12),
          CalcInput(label: 'Sec 80CCD(1B) (NPS - Max ₹50K)', controller: _npsController, hint: '0', isCurrency: true),
        ],
      ],
      actions: [
        CalcButton(label: 'Calculate Tax', icon: Icons.calculate, color: ktSecondary, onPressed: _calculate),
      ],
    );
  }

  Widget _countryBtn(String c) {
    final active = _country == c;
    return InkWell(
      onTap: () => setState(() => _country = c),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? ktSecondary.withValues(alpha: 0.2) : ktBorderWhite5,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? ktSecondary : Colors.transparent),
        ),
        alignment: Alignment.center,
        child: Text(c, style: TextStyle(color: active ? ktSecondary : ktTextGray400, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}
