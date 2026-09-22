import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core_utils.dart';
import '../core_constants.dart';
import 'calculator_components.dart';
import 'calculator_utils.dart';

class GovtSchemesCalculator extends StatefulWidget {
  const GovtSchemesCalculator({super.key});

  @override
  State<GovtSchemesCalculator> createState() => _GovtSchemesCalculatorState();
}

class _GovtSchemesCalculatorState extends State<GovtSchemesCalculator> {
  String _selectedTab = 'ssa';
  String _investMode = 'sip'; // 'sip' or 'lumpsum'

  final _investmentController = TextEditingController();
  final _ageController = TextEditingController();
  final _returnController = TextEditingController();
  final _tenureController = TextEditingController(text: '10');
  final _startYearController = TextEditingController(text: getIndiaTime().year.toString());

  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _returnController.text = _getDefaultRoiForScheme('ssa').toString();
  }

  double _getDefaultRoiForScheme(String scheme) {
    switch (scheme) {
      case 'ssa': return 8.2;
      case 'ppf': return 7.1;
      case 'nps': return 10.0;
      case 'mf': return 12.0;
      case 'nsc': return 7.7;
      case 'kvp': return 7.5;
      case 'scss': return 8.2;
      case 'pomis': return 7.4;
      case 'mssc': return 7.5;
      default: return 7.0;
    }
  }

  void _calculate() {
    final investment = double.tryParse(_investmentController.text.replaceAll(',', '')) ?? 0;
    if (investment <= 0) return;

    setState(() {
      switch (_selectedTab) {
        case 'ssa':
          _calculateSSA(investment); break;
        case 'ppf':
          _calculatePPF(investment); break;
        case 'nps':
          _calculateNPS(investment); break;
        case 'mf':
          _calculateMF(investment); break;
        case 'nsc':
          _calculateNSC(investment); break;
        case 'kvp':
          _calculateKVP(investment); break;
        case 'scss':
          _calculateSCSS(investment); break;
        case 'pomis':
          _calculatePOMIS(investment); break;
        case 'mssc':
          _calculateMSSC(investment); break;
      }
    });

    if (_result != null && mounted) {
      showCalcResultBottomSheet(
        context: context,
        title: _getSchemeTitle(_selectedTab),
        icon: Icons.account_balance,
        themeColor: ktOrange,
        resultWidget: _buildResults(),
      );
    }
  }

  String _getSchemeTitle(String scheme) {
    switch (scheme) {
      case 'ssa': return 'Sukanya Samriddhi (SSA)';
      case 'ppf': return 'Public Provident Fund (PPF)';
      case 'nps': return 'National Pension System (NPS)';
      case 'mf': return 'Mutual Fund Calculation Result';
      case 'nsc': return 'National Savings Certificate';
      case 'kvp': return 'Kisan Vikas Patra';
      case 'scss': return 'Senior Citizens Scheme';
      case 'pomis': return 'Post Office Monthly Income';
      case 'mssc': return 'Mahila Samman Scheme';
      default: return 'Investment Calculation';
    }
  }

  void _calculateSSA(double invest) {
    double rate = double.tryParse(_returnController.text.replaceAll(',', '')) ?? 8.2;
    int startYear = int.tryParse(_startYearController.text.replaceAll(',', '')) ?? getIndiaTime().year;
    double annualDeposit = _investMode == 'sip' ? invest * 12 : invest;
    double totalInvest = 0, balance = 0;
    for (int i = 0; i < 21; i++) {
      if (i < 15) { balance += annualDeposit; totalInvest += annualDeposit; }
      balance += (balance * rate) / 100;
    }
    _result = {
      'roi': '$rate% p.a.',
      'investType': _investMode == 'sip' ? 'Monthly SIP (₹${CalculatorUtils.formatGrouped(invest)}/mo)' : 'Annual LumpSum',
      'totalInvest': totalInvest,
      'interest': balance - totalInvest,
      'maturity': balance,
      'year': startYear + 21,
    };
  }

  void _calculatePPF(double invest) {
    double rate = double.tryParse(_returnController.text.replaceAll(',', '')) ?? 7.1;
    const duration = 15;
    double annualDeposit = _investMode == 'sip' ? invest * 12 : invest;
    double balance = 0;
    for (int i = 0; i < duration; i++) { balance += annualDeposit; balance += (balance * rate) / 100; }
    _result = {
      'roi': '$rate% p.a.',
      'investType': _investMode == 'sip' ? 'Monthly SIP (₹${CalculatorUtils.formatGrouped(invest)}/mo)' : 'Annual LumpSum',
      'totalInvest': annualDeposit * duration,
      'interest': balance - (annualDeposit * duration),
      'maturity': balance,
      'tenure': '15 Years',
    };
  }

  void _calculateNPS(double invest) {
    int age = int.tryParse(_ageController.text.replaceAll(',', '')) ?? 30;
    double rate = double.tryParse(_returnController.text.replaceAll(',', '')) ?? 10.0;
    int years = 60 - age;
    if (years <= 0) years = 1;

    if (_investMode == 'sip') {
      int months = years * 12;
      double r = rate / 12 / 100;
      double maturity = invest * ((math.pow(1 + r, months) - 1) / r) * (1 + r);
      double totalInvest = invest * months;
      _result = {
        'roi': '$rate% p.a.',
        'investType': 'Monthly SIP (₹${CalculatorUtils.formatGrouped(invest)}/mo)',
        'totalInvest': totalInvest,
        'interest': maturity - totalInvest,
        'maturity': maturity,
        'tenure': '$years Years till retirement',
      };
    } else {
      double annualDeposit = invest;
      double balance = 0;
      for (int i = 0; i < years; i++) {
        balance += annualDeposit;
        balance += (balance * rate) / 100;
      }
      _result = {
        'roi': '$rate% p.a.',
        'investType': 'Annual LumpSum',
        'totalInvest': annualDeposit * years,
        'interest': balance - (annualDeposit * years),
        'maturity': balance,
        'tenure': '$years Years till retirement',
      };
    }
  }

  void _calculateMF(double invest) {
    double rate = double.tryParse(_returnController.text.replaceAll(',', '')) ?? 12.0;
    int years = int.tryParse(_tenureController.text.replaceAll(',', '')) ?? 10;
    if (years <= 0) years = 1;

    if (_investMode == 'sip') {
      int months = years * 12;
      double r = rate / 12 / 100;
      double maturity = invest * ((math.pow(1 + r, months) - 1) / r) * (1 + r);
      double totalInvest = invest * months;
      _result = {
        'roi': '$rate% p.a.',
        'investType': 'Monthly SIP (₹${CalculatorUtils.formatGrouped(invest)}/mo)',
        'totalInvest': totalInvest,
        'interest': maturity - totalInvest,
        'maturity': maturity,
        'tenure': '$years Years ($months Months)',
      };
    } else {
      double maturity = invest * math.pow(1 + rate / 100, years);
      _result = {
        'roi': '$rate% p.a.',
        'investType': 'One-time LumpSum',
        'totalInvest': invest,
        'interest': maturity - invest,
        'maturity': maturity,
        'tenure': '$years Years',
      };
    }
  }

  void _calculateNSC(double invest) {
    double rate = double.tryParse(_returnController.text.replaceAll(',', '')) ?? 7.7;
    const years = 5;
    double maturity = invest * math.pow(1 + rate / 100, years);
    _result = {'roi': '$rate% p.a.', 'investType': 'LumpSum', 'totalInvest': invest, 'interest': maturity - invest, 'maturity': maturity, 'tenure': '5 Years'};
  }

  void _calculateKVP(double invest) {
    double rate = double.tryParse(_returnController.text.replaceAll(',', '')) ?? 7.5;
    double maturity = invest * math.pow(1 + rate / 100, 115 / 12);
    _result = {'roi': '$rate% p.a.', 'investType': 'LumpSum', 'totalInvest': invest, 'interest': maturity - invest, 'maturity': maturity, 'tenure': '115 Months (9y 7m)'};
  }

  void _calculateSCSS(double invest) {
    double rate = double.tryParse(_returnController.text.replaceAll(',', '')) ?? 8.2;
    const years = 5;
    double quarterly = (invest * rate / 100) / 4;
    _result = {'roi': '$rate% p.a.', 'investType': 'LumpSum', 'totalInvest': invest, 'interest': quarterly * 4 * years, 'maturity': invest, 'quarterly': quarterly, 'tenure': '5 Years'};
  }

  void _calculatePOMIS(double invest) {
    double rate = double.tryParse(_returnController.text.replaceAll(',', '')) ?? 7.4;
    double monthly = (invest * rate / 100) / 12;
    _result = {'roi': '$rate% p.a.', 'investType': 'LumpSum', 'totalInvest': invest, 'interest': monthly * 60, 'maturity': invest, 'monthly': monthly, 'tenure': '5 Years'};
  }

  void _calculateMSSC(double invest) {
    double rate = double.tryParse(_returnController.text.replaceAll(',', '')) ?? 7.5;
    const years = 2;
    double maturity = invest * math.pow(1 + (rate / 4) / 100, years * 4);
    _result = {'roi': '$rate% p.a.', 'investType': 'LumpSum', 'totalInvest': invest, 'interest': maturity - invest, 'maturity': maturity, 'tenure': '2 Years'};
  }

  void _clear() {
    setState(() {
      _investmentController.clear();
      _ageController.clear();
      _returnController.text = _getDefaultRoiForScheme(_selectedTab).toString();
      _tenureController.text = '10';
      _result = null;
    });
  }

  Widget _buildRoiBadge() {
    double currentRate = double.tryParse(_returnController.text) ?? _getDefaultRoiForScheme(_selectedTab);
    String roiText = '$currentRate% p.a.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ktOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ktOrange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.trending_up_rounded, color: ktOrange, size: 16),
              SizedBox(width: 6),
              Text(
                'Rate of Interest (ROI)',
                style: TextStyle(color: ktTextWhite, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ktOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              roiText,
              style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeObservations() {
    late String title;
    late String observation;
    late IconData icon;

    switch (_selectedTab) {
      case 'ssa':
        title = 'Sukanya Samriddhi Account (SSA)';
        observation = 'High-interest government savings scheme for girl child education & marriage. Lock-in 21 years (deposit for 15 years).';
        icon = Icons.child_care_rounded;
        break;
      case 'ppf':
        title = 'Public Provident Fund (PPF)';
        observation = 'Guaranteed tax-free long-term savings scheme under Section 80C. 15-year tenure with extension options.';
        icon = Icons.savings_rounded;
        break;
      case 'nps':
        title = 'National Pension System (NPS)';
        observation = 'Market-linked voluntary pension system for long-term retirement planning with additional 80CCD(1B) tax benefits.';
        icon = Icons.account_balance_wallet_rounded;
        break;
      case 'mf':
        title = 'Mutual Funds (SIP / LumpSum)';
        observation = 'Wealth creation scheme through systematic investment (SIP) or one-time lump sum in equity & debt mutual funds.';
        icon = Icons.show_chart_rounded;
        break;
      case 'nsc':
        title = 'National Savings Certificate (NSC)';
        observation = 'Fixed income post office savings scheme with 5-year lock-in period and annual compounded interest.';
        icon = Icons.verified_user_rounded;
        break;
      case 'kvp':
        title = 'Kisan Vikas Patra (KVP)';
        observation = 'Doubles your investment amount in 115 months (9 years 7 months) with government-backed security.';
        icon = Icons.eco_rounded;
        break;
      case 'scss':
        title = 'Senior Citizens Savings Scheme (SCSS)';
        observation = 'Quarterly interest payout scheme for senior citizens aged 60+. 5-year tenure with high safety.';
        icon = Icons.elderly_rounded;
        break;
      case 'pomis':
        title = 'Post Office Monthly Income Scheme (POMIS)';
        observation = 'Provides steady monthly income payout on fixed deposit for a 5-year tenure.';
        icon = Icons.payments_rounded;
        break;
      case 'mssc':
        title = 'Mahila Samman Savings Certificate (MSSC)';
        observation = 'Special 2-year deposit scheme for women and girl children with partial withdrawal facility.';
        icon = Icons.female_rounded;
        break;
      default:
        title = 'Government Scheme';
        observation = 'Government backed savings scheme offering secure returns.';
        icon = Icons.account_balance_rounded;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ktOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ktOrange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: ktOrange, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ktTextWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            observation,
            style: TextStyle(
              color: ktTextWhite.withValues(alpha: 0.75),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  bool get _isSipApplicable => ['ssa', 'ppf', 'nps', 'mf'].contains(_selectedTab);

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ktBorderWhite5,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeBtn(
              label: 'Monthly SIP',
              icon: Icons.repeat_rounded,
              isActive: _investMode == 'sip',
              onTap: () => setState(() {
                _investMode = 'sip';
                _result = null;
              }),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ModeBtn(
              label: 'LumpSum / Annual',
              icon: Icons.account_balance_wallet_outlined,
              isActive: _investMode == 'lumpsum',
              onTap: () => setState(() {
                _investMode = 'lumpsum';
                _result = null;
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String investLabel = 'Investment Amount';
    if (_isSipApplicable) {
      investLabel = _investMode == 'sip' ? 'SIP' : 'LumpSum';
    }

    return CalcBaseLayout(
      title: 'Govt Schemes',
      inputs: [
        _buildTabs(),
        _buildSchemeObservations(),
        if (_isSipApplicable) ...[
          const SizedBox(height: 16),
          _buildModeToggle(),
        ],
        const SizedBox(height: 16),
        _buildRoiBadge(),
        const SizedBox(height: 16),
        CalcInput(
          label: investLabel,
          controller: _investmentController,
          hint: _investMode == 'sip' ? 'e.g. 5,000' : 'e.g. 50,000',
          prefix: const Icon(Icons.currency_rupee, size: 20, color: ktTextGray400),
          isCurrency: true,
        ),
        CalcInput(
          label: "ROI % (p.a.)",
          controller: _returnController,
          hint: _getDefaultRoiForScheme(_selectedTab).toString(),
          onChanged: (v) => setState(() {}),
          suffix: const Padding(padding: EdgeInsets.all(12), child: Text('%', style: TextStyle(color: ktTextGray400))),
        ),
        if (_selectedTab == 'ssa') ...[
          CalcInput(label: "Girl's Present Age", controller: _ageController, hint: 'e.g. 5'),
          CalcInput(label: "Start Year", controller: _startYearController, hint: '2024'),
        ],
        if (_selectedTab == 'nps') ...[
          CalcInput(label: "Current Age", controller: _ageController, hint: 'e.g. 30'),
        ],
        if (_selectedTab == 'mf') ...[
          CalcInput(
            label: "Investment Tenure (Years)",
            controller: _tenureController,
            hint: '10',
          ),
        ],
      ],
      actions: [
        CalcButton(label: 'Calculate', icon: Icons.calculate, color: ktOrange, onPressed: _calculate),
        const SizedBox(width: 12),
        CalcButton(label: 'Reset', icon: Icons.refresh, color: ktBorderWhite5, onPressed: _clear),
      ],
      results: _result != null ? _buildResults() : null,
    );
  }

  Widget _buildTabs() {
    final allSchemes = [
      {'id': 'ssa', 'name': 'SSA'},
      {'id': 'ppf', 'name': 'PPF'},
      {'id': 'nps', 'name': 'NPS'},
      {'id': 'mf', 'name': 'MF'},
      {'id': 'nsc', 'name': 'NSC'},
      {'id': 'kvp', 'name': 'KVP'},
      {'id': 'scss', 'name': 'SCSS'},
      {'id': 'pomis', 'name': 'POMIS'},
      {'id': 'mssc', 'name': 'MSSC'},
    ];

    final row1 = allSchemes.sublist(0, 5);
    final row2 = allSchemes.sublist(5);

    Widget buildChip(Map<String, String> s) {
      final isSelected = _selectedTab == s['id'];
      return ChoiceChip(
        label: Text(
          s['name']!,
          style: TextStyle(
            color: isSelected ? Colors.black : ktTextGray400,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
        selected: isSelected,
        onSelected: (v) {
          if (v) {
            setState(() {
              _selectedTab = s['id']!;
              _returnController.text = _getDefaultRoiForScheme(s['id']!).toString();
              _result = null;
              _clear();
            });
          }
        },
        selectedColor: ktOrange,
        backgroundColor: ktBorderWhite5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      );
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: row1.map((s) => Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 6),
                child: buildChip(s),
              )).toList(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: row2.map((s) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: buildChip(s),
              )).toList(),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: allSchemes.map((s) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: buildChip(s),
        )).toList(),
      ),
    );
  }

  Widget _buildResults() {
    return CalcResultCard(
      title: 'Investment Summary',
      children: [
        if (_result!['roi'] != null) ...[
          CalcResultRow(label: 'Rate of Interest (ROI)', value: _result!['roi'].toString(), color: ktEmerald),
          const Divider(color: ktBorderWhite5, height: 24),
        ],
        if (_result!['investType'] != null) ...[
          CalcResultRow(label: 'Investment Mode', value: _result!['investType'].toString(), color: ktTextWhite),
          const Divider(color: ktBorderWhite5, height: 24),
        ],
        CalcResultRow(label: 'Total Investment', value: CalculatorUtils.formatCurrency(_result!['totalInvest']), color: ktTextWhite),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'Total Interest / Gain', value: CalculatorUtils.formatCurrency(_result!['interest']), color: ktCyan),
        const Divider(color: ktBorderWhite5, height: 24),
        CalcResultRow(label: 'Maturity Amount', value: CalculatorUtils.formatCurrency(_result!['maturity']), color: ktOrange),
        if (_result!['tenure'] != null) ...[
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Tenure / Duration', value: _result!['tenure'].toString(), color: ktTextWhite),
        ],
        if (_result!['year'] != null) ...[
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Maturity Year', value: _result!['year'].toString(), color: ktTextWhite),
        ],
        if (_result!['monthly'] != null) ...[
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Monthly Payout', value: CalculatorUtils.formatCurrency(_result!['monthly']), color: ktCyan),
        ],
        if (_result!['quarterly'] != null) ...[
          const Divider(color: ktBorderWhite5, height: 24),
          CalcResultRow(label: 'Quarterly Payout', value: CalculatorUtils.formatCurrency(_result!['quarterly']), color: ktCyan),
        ],
      ],
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeBtn({required this.label, required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? ktOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.black : ktTextGray400),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black : ktTextGray400,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
