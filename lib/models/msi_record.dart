// MSI (Monthly SIP Investments) Record Model
class MsiRecord {
  const MsiRecord({
    required this.month,
    required this.year,
    required this.user,
    this.coinQuantumLiquid = 0,
    this.coinNaviNifty = 0,
    this.coinInvescoSmall = 0,
    this.coinAxisNifty = 0,
    this.coinBirlaNifty = 0,
    this.coinDspNifty = 0,
    this.coinEdelweissBond = 0,
    this.coinCanaraSmall = 0,
    this.coinQuantSmall = 0,
    this.coinBirlaPsu = 0,
    this.coinPowerGrid = 0,
    this.npsTier1 = 0,
    this.npsTier2 = 0,
    this.ssaAccount = 0,
    this.ppfAccount = 0,
    this.njAxisMidcap = 0,
    this.njDspMidcap = 0,
    this.njInvescoMidcap = 0,
    this.njKotakEmerging = 0,
    this.njNipponGrowth = 0,
    this.indJioFlexi = 0,
    this.indBandhanSmall = 0,
    this.indNtpcGreen = 0,
  });

  final String month;
  final String year;
  final String user;

  // Kalyan – Zerodha Coin
  final double coinQuantumLiquid;
  final double coinNaviNifty;
  final double coinInvescoSmall;
  final double coinAxisNifty;
  final double coinBirlaNifty;
  final double coinDspNifty;
  final double coinEdelweissBond;

  // Kalyan – Groww
  final double coinCanaraSmall;
  final double coinQuantSmall;
  final double coinBirlaPsu;
  final double coinPowerGrid;

  // Kalyan – Govt Schemes
  final double npsTier1;
  final double npsTier2;
  final double ssaAccount;
  final double ppfAccount;

  // Kalyan – NJ Wealth
  final double njAxisMidcap;
  final double njDspMidcap;
  final double njInvescoMidcap;
  final double njKotakEmerging;
  final double njNipponGrowth;

  // Layan – INDMoney
  final double indJioFlexi;
  final double indBandhanSmall;
  final double indNtpcGreen;

  // ── Computed totals ──
  double get coinTotal =>
      coinQuantumLiquid + coinNaviNifty + coinInvescoSmall + coinAxisNifty +
      coinBirlaNifty + coinDspNifty + coinEdelweissBond;

  double get growwTotal =>
      coinCanaraSmall + coinQuantSmall + coinBirlaPsu + coinPowerGrid;

  double get govtTotal => npsTier1 + npsTier2 + ssaAccount + ppfAccount;

  double get njTotal =>
      njAxisMidcap + njDspMidcap + njInvescoMidcap + njKotakEmerging + njNipponGrowth;

  double get indMoneyTotal => indJioFlexi + indBandhanSmall + indNtpcGreen;

  double get totalInvestment =>
      user == 'Layan' ? indMoneyTotal : coinTotal + growwTotal + govtTotal + njTotal;

  // ── Serialisation ──
  static double _n(Object? v) => double.tryParse('${v ?? 0}') ?? 0;

  factory MsiRecord.fromJson(Map<String, dynamic> json) {
    double g(String k1, [String? k2]) =>
        MsiRecord._n(json[k1] ?? (k2 != null ? json[k2] : null));
    return MsiRecord(
      month: '${json['month'] ?? ''}',
      year: '${json['year'] ?? ''}',
      user: '${json['user_select'] ?? json['user'] ?? 'Kalyan'}',
      coinQuantumLiquid: g('coin_quantum_liquid', 'quantum_liquid'),
      coinNaviNifty: g('coin_navi_nifty', 'navi_nifty'),
      coinInvescoSmall: g('coin_invesco_small', 'invesco_small'),
      coinAxisNifty: g('coin_axis_nifty', 'axis_nifty'),
      coinBirlaNifty: g('coin_birla_nifty', 'birla_nifty'),
      coinDspNifty: g('coin_dsp_nifty', 'dsp_nifty'),
      coinEdelweissBond: g('coin_edelweiss_bond', 'edelweiss_bond'),
      coinCanaraSmall: g('coin_canara_small', 'canara_small'),
      coinQuantSmall: g('coin_quant_small', 'quant_small'),
      coinBirlaPsu: g('coin_birla_psu', 'birla_psu'),
      coinPowerGrid: g('coin_power_grid', 'power_grid'),
      npsTier1: g('nps_tier1'),
      npsTier2: g('nps_tier2'),
      ssaAccount: g('ssa_account', 'ssa'),
      ppfAccount: g('ppf_account', 'ppf'),
      njAxisMidcap: g('nj_axis_midcap', 'axis_midcap'),
      njDspMidcap: g('nj_dsp_midcap', 'dsp_midcap'),
      njInvescoMidcap: g('nj_invesco_midcap', 'invesco_midcap'),
      njKotakEmerging: g('nj_kotak_emerging', 'kotak_emerging'),
      njNipponGrowth: g('nj_nippon_growth', 'nippon_growth'),
      indJioFlexi: g('ind_jio_flexi'),
      indBandhanSmall: g('ind_bandhan_small'),
      indNtpcGreen: g('ind_ntpc_green'),
    );
  }

  Map<String, dynamic> toJson() => {
        'month': month,
        'year': year,
        'user_select': user,
        'total_investment': totalInvestment,
        'coin_quantum_liquid': coinQuantumLiquid,
        'coin_navi_nifty': coinNaviNifty,
        'coin_invesco_small': coinInvescoSmall,
        'coin_axis_nifty': coinAxisNifty,
        'coin_birla_nifty': coinBirlaNifty,
        'coin_dsp_nifty': coinDspNifty,
        'coin_edelweiss_bond': coinEdelweissBond,
        'coin_canara_small': coinCanaraSmall,
        'coin_quant_small': coinQuantSmall,
        'coin_birla_psu': coinBirlaPsu,
        'coin_power_grid': coinPowerGrid,
        'nps_tier1': npsTier1,
        'nps_tier2': npsTier2,
        'ssa_account': ssaAccount,
        'ppf_account': ppfAccount,
        'nj_axis_midcap': njAxisMidcap,
        'nj_dsp_midcap': njDspMidcap,
        'nj_invesco_midcap': njInvescoMidcap,
        'nj_kotak_emerging': njKotakEmerging,
        'nj_nippon_growth': njNipponGrowth,
        'ind_jio_flexi': indJioFlexi,
        'ind_bandhan_small': indBandhanSmall,
        'ind_ntpc_green': indNtpcGreen,
      };
}

