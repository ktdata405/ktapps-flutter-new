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
        title: 'What is X% of Y?',
        subtitle: 'Calculate percentage of any number',
        icon: Icons.percent,
        color: ktCyan,
        route: '/calculator/percentage/of_number',
      ),
      _PercentOption(
        title: 'X is what % of Y?',
        subtitle: 'Find percentage ratio between two numbers',
        icon: Icons.pie_chart_rounded,
        color: ktEmerald,
        route: '/calculator/percentage/is_percent',
      ),
      _PercentOption(
        title: 'Percentage Increase / Decrease',
        subtitle: 'Calculate growth or reduction percentage',
        icon: Icons.trending_up_rounded,
        color: ktOrange,
        route: '/calculator/percentage/inc_dec',
      ),
      _PercentOption(
        title: 'Percentage Difference',
        subtitle: 'Find difference percentage between two values',
        icon: Icons.compare_arrows_rounded,
        color: ktSecondary,
        route: '/calculator/percentage/difference',
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
          'Percentage Calculator',
          style: TextStyle(color: isDark ? ktTextWhite : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: GridView.builder(
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
                      gradient: LinearGradient(
                        colors: [
                          opt.color.withValues(alpha: 0.2),
                          opt.color.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: opt.color.withValues(alpha: 0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: opt.color.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: opt.color.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(opt.icon, color: opt.color, size: 18),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.title,
                              style: TextStyle(
                                color: isDark ? ktTextWhite : Colors.black87,
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
                                color: isDark ? ktTextGray400 : Colors.black54,
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

// 1. What is X% of Y? Screen
class PercentOfNumberScreen extends StatefulWidget {
  const PercentOfNumberScreen({super.key});

  @override
  State<PercentOfNumberScreen> createState() => _PercentOfNumberScreenState();
}

class _PercentOfNumberScreenState extends State<PercentOfNumberScreen> {
  final _xController = TextEditingController();
  final _yController = TextEditingController();

  void _calculate() {
    double x = double.tryParse(_xController.text.replaceAll(',', '')) ?? 0;
    double y = double.tryParse(_yController.text.replaceAll(',', '')) ?? 0;
    double result = (x * y) / 100;

    showCalcResultBottomSheet(
      context: context,
      title: 'What is $x% of $y?',
      icon: Icons.percent,
      themeColor: ktCyan,
      resultWidget: CalcResultCard(
        title: 'Detailed Calculation Steps',
        children: [
          CalcResultRow(label: 'Result Value', value: result.toStringAsFixed(2), color: ktCyan),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Formula Used', value: '($x / 100) × $y', color: ktTextGray400),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Step 1 (Convert %)', value: '$x ÷ 100 = ${x / 100}', color: ktOrange),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Step 2 (Multiply)', value: '${x / 100} × $y = $result', color: ktEmerald),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'What is X% of Y?',
      inputs: [
        CalcInput(label: 'Percentage (X)', controller: _xController, hint: 'e.g. 15', isCurrency: true, suffix: const Padding(padding: EdgeInsets.all(16), child: Text('%', style: TextStyle(color: ktTextGray400)))),
        const SizedBox(height: 12),
        CalcInput(label: 'Number (Y)', controller: _yController, hint: 'e.g. 2,00,000', isCurrency: true),
      ],
      actions: [
        CalcButton(label: 'Calculate', icon: Icons.calculate, color: ktCyan, onPressed: _calculate),
      ],
    );
  }
}

// 2. X is what % of Y? Screen
class NumberIsPercentScreen extends StatefulWidget {
  const NumberIsPercentScreen({super.key});

  @override
  State<NumberIsPercentScreen> createState() => _NumberIsPercentScreenState();
}

class _NumberIsPercentScreenState extends State<NumberIsPercentScreen> {
  final _xController = TextEditingController();
  final _yController = TextEditingController();

  void _calculate() {
    double x = double.tryParse(_xController.text.replaceAll(',', '')) ?? 0;
    double y = double.tryParse(_yController.text.replaceAll(',', '')) ?? 0;
    if (y == 0) return;
    double result = (x / y) * 100;

    showCalcResultBottomSheet(
      context: context,
      title: '$x is what % of $y?',
      icon: Icons.pie_chart_rounded,
      themeColor: ktEmerald,
      resultWidget: CalcResultCard(
        title: 'Detailed Calculation Steps',
        children: [
          CalcResultRow(label: 'Percentage Result', value: '${result.toStringAsFixed(2)}%', color: ktEmerald),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Formula Used', value: '($x ÷ $y) × 100', color: ktTextGray400),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Step 1 (Division)', value: '$x ÷ $y = ${x / y}', color: ktOrange),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Step 2 (Multiply by 100)', value: '${x / y} × 100 = ${result.toStringAsFixed(2)}%', color: ktCyan),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'X is what % of Y?',
      inputs: [
        CalcInput(label: 'Part Value (X)', controller: _xController, hint: 'e.g. 25,000', isCurrency: true),
        const SizedBox(height: 12),
        CalcInput(label: 'Whole Value (Y)', controller: _yController, hint: 'e.g. 2,00,000', isCurrency: true),
      ],
      actions: [
        CalcButton(label: 'Calculate', icon: Icons.calculate, color: ktEmerald, onPressed: _calculate),
      ],
    );
  }
}

// 3. Percentage Increase / Decrease Screen
class PercentIncDecScreen extends StatefulWidget {
  const PercentIncDecScreen({super.key});

  @override
  State<PercentIncDecScreen> createState() => _PercentIncDecScreenState();
}

class _PercentIncDecScreenState extends State<PercentIncDecScreen> {
  final _valController = TextEditingController();
  final _pctController = TextEditingController();
  bool _isIncrease = true;

  void _calculate() {
    double v = double.tryParse(_valController.text.replaceAll(',', '')) ?? 0;
    double p = double.tryParse(_pctController.text.replaceAll(',', '')) ?? 0;
    double diff = (v * p) / 100;
    double result = _isIncrease ? v + diff : v - diff;

    showCalcResultBottomSheet(
      context: context,
      title: '${_isIncrease ? "Increase" : "Decrease"} $v by $p%',
      icon: Icons.trending_up_rounded,
      themeColor: ktOrange,
      resultWidget: CalcResultCard(
        title: 'Detailed Calculation Steps',
        children: [
          CalcResultRow(label: 'Final Value', value: result.toStringAsFixed(2), color: ktOrange),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Difference Amount', value: (_isIncrease ? '+' : '-') + diff.toStringAsFixed(2), color: _isIncrease ? ktEmerald : ktRose),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Formula Used', value: '$v ${_isIncrease ? '+' : '-'} ($v × $p ÷ 100)', color: ktTextGray400),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Step 1 (Percentage Amt)', value: '$v × $p ÷ 100 = $diff', color: ktCyan),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Step 2 (Final calculation)', value: '$v ${_isIncrease ? '+' : '-'} $diff = $result', color: ktEmerald),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'Percentage Increase / Decrease',
      inputs: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: ktBorderWhite5, borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isIncrease = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _isIncrease ? ktEmerald : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text('Increase', style: TextStyle(color: _isIncrease ? Colors.white : ktTextGray400, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _isIncrease = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: !_isIncrease ? ktRose : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text('Decrease', style: TextStyle(color: !_isIncrease ? Colors.white : ktTextGray400, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CalcInput(label: 'Initial Value', controller: _valController, hint: 'e.g. 50,000', isCurrency: true),
        const SizedBox(height: 12),
        CalcInput(label: 'Percentage (%)', controller: _pctController, hint: 'e.g. 18', suffix: const Padding(padding: EdgeInsets.all(16), child: Text('%', style: TextStyle(color: ktTextGray400)))),
      ],
      actions: [
        CalcButton(label: 'Calculate', icon: Icons.calculate, color: ktOrange, onPressed: _calculate),
      ],
    );
  }
}

// 4. Percentage Difference Screen
class PercentDiffScreen extends StatefulWidget {
  const PercentDiffScreen({super.key});

  @override
  State<PercentDiffScreen> createState() => _PercentDiffScreenState();
}

class _PercentDiffScreenState extends State<PercentDiffScreen> {
  final _aController = TextEditingController();
  final _bController = TextEditingController();

  void _calculate() {
    double a = double.tryParse(_aController.text.replaceAll(',', '')) ?? 0;
    double b = double.tryParse(_bController.text.replaceAll(',', '')) ?? 0;
    if (a + b == 0) return;
    double absDiff = (a - b).abs();
    double avg = (a + b) / 2;
    double result = (absDiff / avg) * 100;

    showCalcResultBottomSheet(
      context: context,
      title: 'Percentage Difference',
      icon: Icons.compare_arrows_rounded,
      themeColor: ktSecondary,
      resultWidget: CalcResultCard(
        title: 'Detailed Calculation Steps',
        children: [
          CalcResultRow(label: 'Percentage Difference', value: '${result.toStringAsFixed(2)}%', color: ktSecondary),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Absolute Difference', value: absDiff.toStringAsFixed(2), color: ktOrange),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Formula Used', value: '(|A - B| ÷ ((A + B) ÷ 2)) × 100', color: ktTextGray400),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Step 1 (Absolute Diff)', value: '|$a - $b| = $absDiff', color: ktCyan),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Step 2 (Average)', value: '($a + $b) ÷ 2 = $avg', color: ktEmerald),
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Step 3 (Percentage)', value: '($absDiff ÷ $avg) × 100 = ${result.toStringAsFixed(2)}%', color: ktSecondary),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CalcBaseLayout(
      title: 'Percentage Difference',
      inputs: [
        CalcInput(label: 'Value A', controller: _aController, hint: 'e.g. 120', isCurrency: true),
        const SizedBox(height: 12),
        CalcInput(label: 'Value B', controller: _bController, hint: 'e.g. 150', isCurrency: true),
      ],
      actions: [
        CalcButton(label: 'Calculate', icon: Icons.calculate, color: ktSecondary, onPressed: _calculate),
      ],
    );
  }
}
