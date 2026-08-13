import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/msi_record.dart';
import '../services/api_service.dart';
import '../screens/msi_screen.dart';

// ─────────────────────────────────────────────────────────────
// MSI Report Screen  (converted from msireport.html)
// ─────────────────────────────────────────────────────────────

/// Platform configuration (Zerodha Coin / Groww / Govt. / NJ / INDMoney)
class _MsiPlatform {
  const _MsiPlatform({
    required this.name,
    required this.color,
    required this.icon,
    required this.fields,
  });
  final String name;
  final Color color;
  final IconData icon;
  final List<String> fields; // keys matching _fieldValue() switch
}

class MsiReportsScreen extends StatefulWidget {
  const MsiReportsScreen({super.key});

  @override
  State<MsiReportsScreen> createState() => _MsiReportsScreenState();
}

class _MsiReportsScreenState extends State<MsiReportsScreen> {
  // ── Platform configs ──
  static const Map<String, _MsiPlatform> _kalyanPlatforms = {
    'coin': _MsiPlatform(
      name: 'Zerodha Coin',
      color: Color(0xFF3B82F6),
      icon: Icons.monetization_on_rounded,
      fields: [
        'coinQuantumLiquid', 'coinNaviNifty', 'coinInvescoSmall',
        'coinAxisNifty', 'coinBirlaNifty', 'coinDspNifty', 'coinEdelweissBond'
      ],
    ),
    'groww': _MsiPlatform(
      name: 'Groww',
      color: Color(0xFF10B981),
      icon: Icons.eco_rounded,
      fields: ['coinCanaraSmall', 'coinQuantSmall', 'coinBirlaPsu', 'coinPowerGrid'],
    ),
    'govt': _MsiPlatform(
      name: 'Govt. Schemes',
      color: Color(0xFFF59E0B),
      icon: Icons.account_balance_rounded,
      fields: ['ppfAccount', 'ssaAccount', 'npsTier1', 'npsTier2'],
    ),
    'nj': _MsiPlatform(
      name: 'NJ Wealth',
      color: Color(0xFFEF4444),
      icon: Icons.work_rounded,
      fields: [
        'njAxisMidcap', 'njDspMidcap', 'njInvescoMidcap',
        'njKotakEmerging', 'njNipponGrowth'
      ],
    ),
  };

  static const Map<String, _MsiPlatform> _layanPlatforms = {
    'indmoney': _MsiPlatform(
      name: 'INDMoney',
      color: Color(0xFF8B5CF6),
      icon: Icons.show_chart_rounded,
      fields: ['indJioFlexi', 'indBandhanSmall', 'indNtpcGreen'],
    ),
  };

  static const Map<String, String> _fieldLabels = {
    'coinQuantumLiquid': 'Quantum Liquid',
    'coinNaviNifty': 'Navi Nifty 50',
    'coinInvescoSmall': 'Invesco Small',
    'coinAxisNifty': 'Axis Nifty',
    'coinBirlaNifty': 'Birla Nifty',
    'coinDspNifty': 'DSP Nifty',
    'coinEdelweissBond': 'Edelweiss Bond',
    'coinCanaraSmall': 'Canara Small',
    'coinQuantSmall': 'Quant Small',
    'coinBirlaPsu': 'Birla PSU',
    'coinPowerGrid': 'Power Grid',
    'npsTier1': 'NPS Tier 1',
    'npsTier2': 'NPS Tier 2',
    'ssaAccount': 'SSA',
    'ppfAccount': 'PPF',
    'njAxisMidcap': 'Axis Mid Cap',
    'njDspMidcap': 'DSP Mid Cap',
    'njInvescoMidcap': 'Invesco Mid Cap',
    'njKotakEmerging': 'Kotak Emerging',
    'njNipponGrowth': 'Nippon Growth',
    'indJioFlexi': 'Jio Flexi',
    'indBandhanSmall': 'Bandhan Small',
    'indNtpcGreen': 'NTPC Green',
  };

  static double _fv(MsiRecord r, String f) => switch (f) {
        'coinQuantumLiquid' => r.coinQuantumLiquid,
        'coinNaviNifty' => r.coinNaviNifty,
        'coinInvescoSmall' => r.coinInvescoSmall,
        'coinAxisNifty' => r.coinAxisNifty,
        'coinBirlaNifty' => r.coinBirlaNifty,
        'coinDspNifty' => r.coinDspNifty,
        'coinEdelweissBond' => r.coinEdelweissBond,
        'coinCanaraSmall' => r.coinCanaraSmall,
        'coinQuantSmall' => r.coinQuantSmall,
        'coinBirlaPsu' => r.coinBirlaPsu,
        'coinPowerGrid' => r.coinPowerGrid,
        'npsTier1' => r.npsTier1,
        'npsTier2' => r.npsTier2,
        'ssaAccount' => r.ssaAccount,
        'ppfAccount' => r.ppfAccount,
        'njAxisMidcap' => r.njAxisMidcap,
        'njDspMidcap' => r.njDspMidcap,
        'njInvescoMidcap' => r.njInvescoMidcap,
        'njKotakEmerging' => r.njKotakEmerging,
        'njNipponGrowth' => r.njNipponGrowth,
        'indJioFlexi' => r.indJioFlexi,
        'indBandhanSmall' => r.indBandhanSmall,
        'indNtpcGreen' => r.indNtpcGreen,
        _ => 0,
      };

  // ── State ──
  String _user = 'Kalyan';
  List<MsiRecord> _records = [];
  int _monthIndex = -1;
  int _tab = 0; // 0=overview 1=total 2=history
  bool _isLoading = true;
  bool _totalVisible = false;
  String _historyCategory = 'all';
  bool _historySortDesc = true;
  bool _historyWithDataOnly = false;

  Map<String, _MsiPlatform> get _platforms =>
      _user == 'Layan' ? _layanPlatforms : _kalyanPlatforms;

  // ── Formatters ──
  static String _fmtCurrency(double v) =>
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
          .format(v);

  static String _fmtNum(double v) =>
      v == 0 ? '-' : NumberFormat('#,##,###', 'en_IN').format(v);

  // ── Total across all months ──
  double get _allTimeTotal => _records.fold(0, (s, r) {
        double t = 0;
        for (final p in _platforms.values) {
          for (final f in p.fields) {
            t += _fv(r, f);
          }
        }
        return s + t;
      });

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.fetchMsiData(_user);
      if (!mounted) return;
      final now = DateTime.now();
      const mo = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      // Find current month index
      int idx = data.indexWhere((r) =>
          r.month == _monthName(now.month) &&
          r.year == now.year.toString());
      if (idx < 0) idx = data.isEmpty ? -1 : data.length - 1;
      setState(() {
        _records = data;
        _monthIndex = idx;
        _isLoading = false;
        _historyCategory = 'all';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  static String _monthName(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[(m - 1).clamp(0, 11)];
  }

  void _changeMonth(int delta) {
    if (_monthIndex < 0) return;
    final next = _monthIndex + delta;
    if (next >= 0 && next < _records.length) {
      setState(() => _monthIndex = next);
    }
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SafeArea(
        child: Column(children: [
          _buildNavbar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF0EA5E9)))
                : _buildBody(),
          ),
        ]),
      ),
      // FAB for mobile quick-add
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        onPressed: () async {
          final ok = await Navigator.push<bool>(
              context, MaterialPageRoute(builder: (_) => const MsiScreen()));
          if (ok == true) _fetchData();
        },
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  // ── Navbar ──
  Widget _buildNavbar() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          // Brand
          const Icon(Icons.science_rounded,
              color: Color(0xFF0EA5E9), size: 22),
          const SizedBox(width: 8),
          const Text('MSI',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const Text(' Report',
              style: TextStyle(
                  color: Color(0xFFA1A1AA),
                  fontSize: 20,
                  fontWeight: FontWeight.w300)),
          const Spacer(),
          _navBtn(Icons.add_rounded, 'Add New', () async {
            final ok = await Navigator.push<bool>(context,
                MaterialPageRoute(builder: (_) => const MsiScreen()));
            if (ok == true) _fetchData();
          }),
          const SizedBox(width: 8),
          _navBtn(Icons.refresh_rounded, 'Refresh', _fetchData),
          const SizedBox(width: 8),
          _navBtn(Icons.home_rounded, 'Home',
              () => Navigator.of(context).popUntil((r) => r.isFirst)),
          const SizedBox(width: 8),
          _navBtn(Icons.settings_rounded, 'Settings', () {}),
        ]),
      );

  Widget _navBtn(IconData icon, String tip, VoidCallback onTap) => Tooltip(
        message: tip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF27272A)),
            ),
            child: Icon(icon, color: Colors.white, size: 17),
          ),
        ),
      );

  // ── Body ──
  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        _buildHeroGrid(),
        const SizedBox(height: 16),
        _buildTabBar(),
        const SizedBox(height: 16),
        _buildTabContent(),
      ],
    );
  }

  // ── Hero Grid ──
  Widget _buildHeroGrid() {
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 700;
      return wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _buildBalanceCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildControlsCard()),
            ])
          : Column(children: [
              _buildBalanceCard(),
              const SizedBox(height: 16),
              _buildControlsCard(),
            ]);
    });
  }

  // ── Balance Card ──
  Widget _buildBalanceCard() => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF18181B), Color(0xFF131316)]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('TOTAL INVESTMENTS',
                  style: TextStyle(
                      color: Color(0xFFA1A1AA),
                      fontSize: 12,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              InkWell(
                onTap: () =>
                    setState(() => _totalVisible = !_totalVisible),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _totalVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: const Color(0xFFA1A1AA), size: 18),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Text(
              _totalVisible ? _fmtCurrency(_allTimeTotal) : '****',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  height: 1),
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _metaItem(Icons.trending_up_rounded,
                  '${_records.length} months', const Color(0xFF10B981)),
            ]),
          ],
        ),
      );

  Widget _metaItem(IconData icon, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      );

  // ── Controls Card ──
  Widget _buildControlsCard() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF27272A)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // User select
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('User:',
                  style: TextStyle(
                      color: Color(0xFFA1A1AA), fontSize: 14)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF09090B),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _user,
                    dropdownColor: const Color(0xFF18181B),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: Color(0xFFA1A1AA)),
                    items: const [
                      DropdownMenuItem(
                          value: 'Kalyan', child: Text('Kalyan')),
                      DropdownMenuItem(
                          value: 'Layan', child: Text('Layan')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _user = v;
                          _historyCategory = 'all';
                        });
                        _fetchData();
                      }
                    },
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            // Month nav
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _navBtn(Icons.chevron_left_rounded, 'Prev',
                  () => _changeMonth(-1)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF09090B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF27272A)),
                ),
                child: Text(
                  _monthIndex >= 0 && _monthIndex < _records.length
                      ? '${_records[_monthIndex].month} ${_records[_monthIndex].year}'
                      : '-',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              _navBtn(Icons.chevron_right_rounded, 'Next',
                  () => _changeMonth(1)),
              const SizedBox(width: 12),
              _navBtn(Icons.edit_rounded, 'Edit', _editCurrentMonth),
            ]),
            const SizedBox(height: 16),
            // Current month total chip
            if (_monthIndex >= 0 && _monthIndex < _records.length)
              _metaItem(
                Icons.currency_rupee_rounded,
                _fmtCurrency(_monthTotal(_records[_monthIndex])),
                const Color(0xFF0EA5E9),
              ),
          ],
        ),
      );

  double _monthTotal(MsiRecord r) {
    double t = 0;
    for (final p in _platforms.values) {
      for (final f in p.fields) {
        t += _fv(r, f);
      }
    }
    return t;
  }

  void _editCurrentMonth() async {
    if (_monthIndex < 0 || _monthIndex >= _records.length) return;
    final record = _records[_monthIndex];
    final ok = await Navigator.push<bool>(context,
        MaterialPageRoute(builder: (_) => MsiScreen(editRecord: record)));
    if (ok == true) _fetchData();
  }

  // ── Tab Bar ──
  Widget _buildTabBar() => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF27272A)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _tabBtn(0, 'This Month'),
            _tabBtn(1, 'All Time'),
            _tabBtn(2, 'Transaction History'),
          ]),
        ),
      );

  Widget _tabBtn(int idx, String label) => GestureDetector(
        onTap: () => setState(() => _tab = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _tab == idx ? const Color(0xFF0EA5E9) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: _tab == idx
                ? [
                    const BoxShadow(
                        color: Color(0x4D0EA5E9),
                        blurRadius: 12,
                        offset: Offset(0, 4))
                  ]
                : null,
          ),
          child: Text(label,
              style: TextStyle(
                  color:
                      _tab == idx ? Colors.white : const Color(0xFFA1A1AA),
                  fontWeight: FontWeight.w500,
                  fontSize: 14)),
        ),
      );

  // ── Tab Content ──
  Widget _buildTabContent() {
    if (_records.isEmpty) return _emptyState();
    switch (_tab) {
      case 0:
        return _buildOverviewCards();
      case 1:
        return _buildTotalCards();
      case 2:
        return _buildHistoryView();
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Overview Cards (current month) ──
  Widget _buildOverviewCards() {
    if (_monthIndex < 0 || _monthIndex >= _records.length) {
      return _emptyState();
    }
    final r = _records[_monthIndex];
    return _buildPlatformCards(r, 'Current Month');
  }

  // ── Total Cards (all-time cumulative) ──
  Widget _buildTotalCards() {
    if (_records.isEmpty) return _emptyState();

    // Build a synthetic "all-time totals" record
    final totals = <String, double>{};
    for (final p in _platforms.values) {
      for (final f in p.fields) {
        totals[f] = 0;
      }
    }
    for (final r in _records) {
      for (final p in _platforms.values) {
        for (final f in p.fields) {
          totals[f] = (totals[f] ?? 0) + _fv(r, f);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _platforms.entries.map((e) {
        final p = e.value;
        final platformTotal =
            p.fields.fold(0.0, (s, f) => s + (totals[f] ?? 0));
        if (platformTotal == 0) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPlatformCard(
              p, totals, platformTotal, 'All Time Total'),
        );
      }).toList(),
    );
  }

  // ── Platform Cards Widget ──
  Widget _buildPlatformCards(MsiRecord r, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _platforms.entries.map((e) {
        final p = e.value;
        final platformTotal = p.fields.fold(0.0, (s, f) => s + _fv(r, f));
        if (platformTotal == 0) return const SizedBox.shrink();
        final dataMap = {for (final f in p.fields) f: _fv(r, f)};
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildPlatformCard(p, dataMap, platformTotal, label),
        );
      }).toList(),
    );
  }

  Widget _buildPlatformCard(
    _MsiPlatform p,
    Map<String, double> data,
    double platformTotal,
    String label,
  ) {
    final items = p.fields
        .map((f) => MapEntry(f, data[f] ?? 0))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: p.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(p.icon, color: p.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                    Text(label,
                        style: const TextStyle(
                            color: Color(0xFFA1A1AA), fontSize: 12)),
                  ],
                ),
              ),
              Text(
                _fmtCurrency(platformTotal),
                style: TextStyle(
                    color: p.color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ]),
          ),
          const Divider(color: Color(0x14FFFFFF), height: 1),
          // Item list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              children: items.map((item) {
                final hasVal = item.value > 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Icon(Icons.circle,
                        size: 6,
                        color: hasVal
                            ? p.color.withValues(alpha: 0.7)
                            : const Color(0xFF3F3F46)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          _fieldLabels[item.key] ?? item.key,
                          style: TextStyle(
                              color: hasVal
                                  ? const Color(0xFFA1A1AA)
                                  : const Color(0xFF3F3F46),
                              fontSize: 13)),
                    ),
                    Text(
                      _fmtNum(item.value),
                      style: TextStyle(
                          color: hasVal
                              ? Colors.white
                              : const Color(0xFF3F3F46),
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ]),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── History View ──
  Widget _buildHistoryView() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: Column(
        children: [
          // Sub-tabs (category filter)
          _buildHistorySubtabs(),
          // Filters
          _buildHistoryFilters(),
          // Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            child: _buildTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySubtabs() {
    final cats = [
      MapEntry('all', 'All'),
      ..._platforms.entries.map((e) => MapEntry(e.key, e.value.name)),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: cats.map((c) {
          final active = c.key == _historyCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _historyCategory = c.key),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0x2D6366F1)
                      : const Color(0xFF151519),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: active
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF27272A)),
                ),
                child: Text(c.value,
                    style: TextStyle(
                        color: active
                            ? Colors.white
                            : const Color(0xFFA1A1AA),
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHistoryFilters() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(children: [
          // Data filter
          _filterSelect(
            ['All Rows', 'With Data'],
            _historyWithDataOnly ? 'With Data' : 'All Rows',
            (v) => setState(() => _historyWithDataOnly = v == 'With Data'),
          ),
          const SizedBox(width: 8),
          // Sort order
          _filterSelect(
            ['Newest First', 'Oldest First'],
            _historySortDesc ? 'Newest First' : 'Oldest First',
            (v) => setState(
                () => _historySortDesc = v == 'Newest First'),
          ),
        ]),
      );

  Widget _filterSelect(
      List<String> items, String value, ValueChanged<String> onChange) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF27272A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF18181B),
          style: const TextStyle(color: Color(0xFFECECF1), fontSize: 12),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Color(0xFFA1A1AA), size: 14),
          isDense: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChange(v);
          },
        ),
      ),
    );
  }

  // ── Table ──
  Widget _buildTable() {
    final activeCategories = _historyCategory == 'all'
        ? _platforms.entries.toList()
        : _platforms.entries
            .where((e) => e.key == _historyCategory)
            .toList();

    final visibleFields = activeCategories
        .expand((e) => e.value.fields)
        .toList();

    var rows = List<MsiRecord>.from(_records);
    if (_historySortDesc) rows = rows.reversed.toList();
    if (_historyWithDataOnly) {
      rows = rows.where((r) {
        return visibleFields.any((f) => _fv(r, f) > 0);
      }).toList();
    }

    const double periodW = 150;
    const double totalW = 110;
    const double cellW = 96;

    // Calculate total table width
    final tableW =
        periodW + totalW + visibleFields.length * cellW;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: tableW),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Group header row ──
          Container(
            color: const Color(0xFF202024),
            child: Row(children: [
              _thCell('Period', periodW, rowSpan: true, sticky: true),
              _thCell('Total', totalW, rowSpan: true, sticky: true,
                  textColor: const Color(0xFF0EA5E9)),
              ...activeCategories.expand((e) {
                final p = e.value;
                return [
                  _groupCell(p.name, p.fields.length * cellW, p.color),
                ];
              }),
            ]),
          ),
          // ── Field header row ──
          Container(
            color: const Color(0xFF202024),
            child: Row(children: [
              // Period and Total headers already span 2 rows — spacers
              SizedBox(width: periodW),
              SizedBox(width: totalW),
              ...activeCategories.expand((e) {
                final p = e.value;
                return e.value.fields.asMap().entries.map((fe) {
                  final isFirst = fe.key == 0;
                  return _fieldCell(
                      _fieldLabels[fe.value] ?? fe.value,
                      cellW, p.color, isFirst: isFirst);
                });
              }),
            ]),
          ),
          const Divider(color: Color(0xFF27272A), height: 1),
          // ── Data rows ──
          ...rows.asMap().entries.map((rowEntry) {
            final i = rowEntry.key;
            final r = rowEntry.value;
            final isEven = i % 2 == 0;
            final rowBg = isEven
                ? const Color(0x05FFFFFF)
                : const Color(0x0AFFFFFF);

            // Compute total for this row (visible fields only)
            final rowTotal = visibleFields.fold(
                0.0, (s, f) => s + _fv(r, f));

            return Container(
              color: rowBg,
              child: Row(children: [
                // Period cell with edit button
                SizedBox(
                  width: periodW,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(children: [
                      Expanded(
                        child: Text('${r.month} ${r.year}',
                            style: TextStyle(
                                color: isEven
                                    ? const Color(0xFFC4B5FD)
                                    : const Color(0xFF7DD3FC),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                      InkWell(
                        onTap: () async {
                          final ok = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      MsiScreen(editRecord: r)));
                          if (ok == true) _fetchData();
                        },
                        child: const Icon(Icons.edit_rounded,
                            size: 13, color: Color(0xFFA1A1AA)),
                      ),
                    ]),
                  ),
                ),
                // Total cell
                SizedBox(
                  width: totalW,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Text(_fmtNum(rowTotal),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            color: isEven
                                ? const Color(0xFFA5F3FC)
                                : const Color(0xFF86EFAC),
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                // Field cells
                ...activeCategories.expand((e) {
                  final catKey = e.key;
                  final p = e.value;
                  return p.fields.asMap().entries.map((fe) {
                    final val = _fv(r, fe.value);
                    final hasVal = val > 0;
                    Color cellColor;
                    switch (catKey) {
                      case 'coin':
                        cellColor = isEven
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFFBFDBFE);
                        break;
                      case 'groww':
                        cellColor = isEven
                            ? const Color(0xFF34D399)
                            : const Color(0xFFA7F3D0);
                        break;
                      case 'govt':
                        cellColor = isEven
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFFFDE68A);
                        break;
                      case 'nj':
                        cellColor = isEven
                            ? const Color(0xFFF87171)
                            : const Color(0xFFFECACA);
                        break;
                      case 'indmoney':
                        cellColor = isEven
                            ? const Color(0xFFA78BFA)
                            : const Color(0xFFDDD6FE);
                        break;
                      default:
                        cellColor = const Color(0xFF9CA3AF);
                    }
                    return SizedBox(
                      width: cellW,
                      child: Container(
                        color: switch (catKey) {
                          'coin' => isEven
                              ? const Color(0x0A3B82F6)
                              : const Color(0x153B82F6),
                          'groww' => isEven
                              ? const Color(0x0A10B981)
                              : const Color(0x1510B981),
                          'govt' => isEven
                              ? const Color(0x0AF59E0B)
                              : const Color(0x15F59E0B),
                          'nj' => isEven
                              ? const Color(0x0AEF4444)
                              : const Color(0x15EF4444),
                          'indmoney' => isEven
                              ? const Color(0x0A8B5CF6)
                              : const Color(0x158B5CF6),
                          _ => Colors.transparent,
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Text(
                            _fmtNum(val),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: hasVal
                                  ? cellColor
                                  : const Color(0xFF52525B),
                              fontSize: 12,
                              fontWeight: hasVal
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                }),
              ]),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _thCell(String text, double width,
      {bool rowSpan = false, bool sticky = false, Color? textColor}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(text,
            style: TextStyle(
                color: textColor ?? const Color(0xFFD4D4DC),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
      ),
    );
  }

  Widget _groupCell(String name, double width, Color color) => SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border(
                bottom: BorderSide(
                    color: color.withValues(alpha: 0.4))),
          ),
          child: Text(name,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
        ),
      );

  Widget _fieldCell(String label, double width, Color color,
      {bool isFirst = false}) =>
      SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            border: Border(
              bottom: BorderSide(color: color.withValues(alpha: 0.35)),
              left: isFirst
                  ? BorderSide(
                      color: color.withValues(alpha: 0.4), width: 2)
                  : BorderSide.none,
            ),
          ),
          child: Text(label,
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5)),
        ),
      );

  Widget _emptyState() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.bar_chart_rounded,
                size: 72, color: Color(0xFF374151)),
            const SizedBox(height: 16),
            const Text('No data found',
                style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh_rounded,
                  size: 16, color: Color(0xFF0EA5E9)),
              label: const Text('Refresh',
                  style: TextStyle(color: Color(0xFF0EA5E9))),
            ),
          ]),
        ),
      );
}


