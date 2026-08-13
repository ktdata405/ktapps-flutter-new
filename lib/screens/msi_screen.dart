import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/msi_record.dart';
import '../services/api_service.dart';

// ─────────────────────────────────────────────────────────────
// MSI Entry Screen  (converted from msi.html)
// ─────────────────────────────────────────────────────────────
class MsiScreen extends StatefulWidget {
  const MsiScreen({super.key, this.editRecord});
  final MsiRecord? editRecord;

  @override
  State<MsiScreen> createState() => _MsiScreenState();
}

class _MsiScreenState extends State<MsiScreen> {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static final _years = List.generate(11, (i) => (2020 + i).toString());

  String _user = 'Kalyan';
  late String _month;
  late String _year;
  bool _saving = false;
  double _total = 0;

  // ── Kalyan – Coin controllers ──
  late final TextEditingController _coinQuantumLiquid;
  late final TextEditingController _coinNaviNifty;
  late final TextEditingController _coinInvescoSmall;
  late final TextEditingController _coinAxisNifty;
  late final TextEditingController _coinBirlaNifty;
  late final TextEditingController _coinDspNifty;
  late final TextEditingController _coinEdelweissBond;
  // ── Kalyan – Groww controllers ──
  late final TextEditingController _coinCanaraSmall;
  late final TextEditingController _coinQuantSmall;
  late final TextEditingController _coinBirlaPsu;
  late final TextEditingController _coinPowerGrid;
  // ── Kalyan – Govt controllers ──
  late final TextEditingController _npsTier1;
  late final TextEditingController _npsTier2;
  late final TextEditingController _ssaAccount;
  late final TextEditingController _ppfAccount;
  // ── Layan – INDMoney controllers ──
  late final TextEditingController _indJioFlexi;
  late final TextEditingController _indBandhanSmall;
  late final TextEditingController _indNtpcGreen;

  bool get _isEdit => widget.editRecord != null;

  List<TextEditingController> get _allCtrl => [
        _coinQuantumLiquid, _coinNaviNifty, _coinInvescoSmall, _coinAxisNifty,
        _coinBirlaNifty, _coinDspNifty, _coinEdelweissBond,
        _coinCanaraSmall, _coinQuantSmall, _coinBirlaPsu, _coinPowerGrid,
        _npsTier1, _npsTier2, _ssaAccount, _ppfAccount,
        _indJioFlexi, _indBandhanSmall, _indNtpcGreen,
      ];

  @override
  void initState() {
    super.initState();
    final r = widget.editRecord;
    _user = r?.user ?? 'Kalyan';
    _month = r?.month ?? _months[DateTime.now().month - 1];
    _year = r?.year ?? DateTime.now().year.toString();

    String v(double? d, [double def = 0]) =>
        (d ?? def) == 0 ? '0' : (d ?? def).toStringAsFixed(0);

    _coinQuantumLiquid = TextEditingController(text: v(r?.coinQuantumLiquid, 1331));
    _coinNaviNifty     = TextEditingController(text: v(r?.coinNaviNifty,     1331));
    _coinInvescoSmall  = TextEditingController(text: v(r?.coinInvescoSmall,  1331));
    _coinAxisNifty     = TextEditingController(text: v(r?.coinAxisNifty,     1331));
    _coinBirlaNifty    = TextEditingController(text: v(r?.coinBirlaNifty,    1331));
    _coinDspNifty      = TextEditingController(text: v(r?.coinDspNifty,      1331));
    _coinEdelweissBond = TextEditingController(text: v(r?.coinEdelweissBond, 1331));
    _coinCanaraSmall   = TextEditingController(text: v(r?.coinCanaraSmall,   6050));
    _coinQuantSmall    = TextEditingController(text: v(r?.coinQuantSmall));
    _coinBirlaPsu      = TextEditingController(text: v(r?.coinBirlaPsu));
    _coinPowerGrid     = TextEditingController(text: v(r?.coinPowerGrid));
    _npsTier1          = TextEditingController(text: v(r?.npsTier1, 5500));
    _npsTier2          = TextEditingController(text: v(r?.npsTier2));
    _ssaAccount        = TextEditingController(text: v(r?.ssaAccount, 2500));
    _ppfAccount        = TextEditingController(text: v(r?.ppfAccount, 10000));
    _indJioFlexi       = TextEditingController(text: v(r?.indJioFlexi));
    _indBandhanSmall   = TextEditingController(text: v(r?.indBandhanSmall));
    _indNtpcGreen      = TextEditingController(text: v(r?.indNtpcGreen));

    for (final c in _allCtrl) {
      c.addListener(_calcTotal);
    }
    _calcTotal();
  }

  @override
  void dispose() {
    for (final c in _allCtrl) {
      c.removeListener(_calcTotal);
      c.dispose();
    }
    super.dispose();
  }

  double _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '').trim()) ?? 0;

  void _calcTotal() {
    double t = 0;
    if (_user == 'Kalyan') {
      t = _num(_coinQuantumLiquid) + _num(_coinNaviNifty) +
          _num(_coinInvescoSmall) + _num(_coinAxisNifty) +
          _num(_coinBirlaNifty) + _num(_coinDspNifty) +
          _num(_coinEdelweissBond) + _num(_coinCanaraSmall) +
          _num(_coinQuantSmall) + _num(_coinBirlaPsu) +
          _num(_coinPowerGrid) + _num(_npsTier1) + _num(_npsTier2) +
          _num(_ssaAccount) + _num(_ppfAccount);
    } else {
      t = _num(_indJioFlexi) + _num(_indBandhanSmall) + _num(_indNtpcGreen);
    }
    if (mounted) setState(() => _total = t);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final payload = <String, dynamic>{
      'action': _isEdit ? 'update' : 'create',
      'month': _month,
      'year': _year,
      'user_select': _user,
      'total_investment': _total,
      'coin_quantum_liquid': _num(_coinQuantumLiquid),
      'coin_navi_nifty': _num(_coinNaviNifty),
      'coin_invesco_small': _num(_coinInvescoSmall),
      'coin_axis_nifty': _num(_coinAxisNifty),
      'coin_birla_nifty': _num(_coinBirlaNifty),
      'coin_dsp_nifty': _num(_coinDspNifty),
      'coin_edelweiss_bond': _num(_coinEdelweissBond),
      'coin_canara_small': _num(_coinCanaraSmall),
      'coin_quant_small': _num(_coinQuantSmall),
      'coin_birla_psu': _num(_coinBirlaPsu),
      'coin_power_grid': _num(_coinPowerGrid),
      'nps_tier1': _num(_npsTier1),
      'nps_tier2': _num(_npsTier2),
      'ssa_account': _num(_ssaAccount),
      'ppf_account': _num(_ppfAccount),
      'ind_jio_flexi': _num(_indJioFlexi),
      'ind_bandhan_small': _num(_indBandhanSmall),
      'ind_ntpc_green': _num(_indNtpcGreen),
    };
    try {
      await ApiService.saveMsiRecord(payload);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to save')));
      setState(() => _saving = false);
    }
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    final fmtTotal = NumberFormat.currency(
            locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(_total);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(children: [
        Positioned(left: -100, top: -100,
            child: _orb(400, const Color(0x406366F1))),
        Positioned(right: -50, bottom: -50,
            child: _orb(300, const Color(0x40EC4899))),
        SafeArea(
          child: Column(children: [
            _buildHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // ── Total card ──
                  _buildTotalCard(fmtTotal),
                  const SizedBox(height: 20),

                  // ── Top controls: user / month / year ──
                  _buildTopControls(),
                  const SizedBox(height: 28),

                  // ── Sections ──
                  if (_user == 'Kalyan') ...[
                    _section('Zerodha Coin', Icons.monetization_on_rounded,
                        const Color(0xFF6366F1), [
                      _investCard('Quantum Liquid Debt Fund Max -10%',
                          _coinQuantumLiquid),
                      _investCard(
                          'Navi Nifty 50 Index Funds', _coinNaviNifty),
                      _investCard(
                          'Invesco India Small Cap Fund', _coinInvescoSmall),
                      _investCard(
                          'Axis Nifty 100 Index Fund', _coinAxisNifty),
                      _investCard('Aditya Birla Sun Life Nifty 50 Index',
                          _coinBirlaNifty),
                      _investCard('DSP Nifty 50 Index Fund', _coinDspNifty),
                      _investCard('EdelWeiss Bharat Bond FOF - Apr 2031',
                          _coinEdelweissBond),
                    ]),
                    const SizedBox(height: 28),
                    _section('Groww', Icons.eco_rounded,
                        const Color(0xFF10B981), [
                      _investCard('Canara Robeco Small Cap Fund Direct',
                          _coinCanaraSmall),
                      _investCard(
                          'Quant Small Cap Fund Direct Plan [Lum-sum]',
                          _coinQuantSmall),
                      _investCard(
                          'Aditya Birla Sun Life PSU Equity [Lum-sum]',
                          _coinBirlaPsu),
                      _investCard('Power Grid Corp (Stock)', _coinPowerGrid),
                    ]),
                    const SizedBox(height: 28),
                    _section('Govt Investments',
                        Icons.account_balance_rounded,
                        const Color(0xFFF59E0B), [
                      _investCard('NPS Tier - 1', _npsTier1),
                      _investCard('NPS Tier - 2', _npsTier2),
                      _investCard('Sukanya Samriddhi Account (SSA)',
                          _ssaAccount),
                      _investCard('PPF', _ppfAccount),
                    ]),
                  ] else ...[
                    _section('INDMoney', Icons.show_chart_rounded,
                        const Color(0xFF8B5CF6), [
                      _investCard(
                          'JioBlackRock Flexi Cap Fund', _indJioFlexi),
                      _investCard('Bandhan Small Cap Fund', _indBandhanSmall),
                      _investCard('NTPC Green Stock', _indNtpcGreen),
                    ]),
                  ],

                  const SizedBox(height: 40),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 16),
                        shape: const StadiumBorder(),
                        elevation: 8,
                        shadowColor: const Color(0x4D8B5CF6),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: Text(
                        _saving ? 'Saving...' : 'Save',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Header ──
  Widget _buildHeader() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xB31E293B),
          border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: Row(children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(99),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('MSI',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    letterSpacing: 1)),
          ),
          _hBtn(Icons.home_rounded, 'Home',
              () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ]),
      );

  Widget _hBtn(IconData icon, String tip, VoidCallback onTap) => Tooltip(
        message: tip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(99),
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
        ),
      );

  // ── Total card ──
  Widget _buildTotalCard(String fmtTotal) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xB31E293B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.1)),
          boxShadow: const [
            BoxShadow(color: Color(0x26000000), blurRadius: 12)
          ],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL INVESTMENT',
                    style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(fmtTotal,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22)),
              ],
            ),
          ),
        ]),
      );

  // ── Top controls ──
  Widget _buildTopControls() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xB31E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: const BorderSide(color: Color(0xFF8B5CF6), width: 4),
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _labeledDropdown(
                'Select User', _user, ['Kalyan', 'Layan'],
                (v) => setState(() {
                      _user = v!;
                      _calcTotal();
                    })),
            _labeledDropdown(
                'Select Month', _month, _months,
                (v) => setState(() => _month = v!)),
            _labeledDropdown(
                'Select Year', _year, _years,
                (v) => setState(() => _year = v!)),
          ],
        ),
      );

  Widget _labeledDropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          constraints: const BoxConstraints(minWidth: 140),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Color(0xFF9CA3AF), size: 16),
              items: items
                  .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // ── Section ──
  Widget _section(String title, IconData icon, Color color,
      List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 16),
        ...cards,
      ],
    );
  }

  // ── Investment input card ──
  Widget _investCard(String label, TextEditingController ctrl) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xB31E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(children: [
              const Text('₹',
                  style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: TextStyle(color: Color(0xFF475569)),
                  ),
                ),
              ),
            ]),
          ],
        ),
      );

  Widget _orb(double size, Color color) => Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color.withValues(alpha: 0.4),
            Colors.transparent
          ]),
        ),
      );
}



