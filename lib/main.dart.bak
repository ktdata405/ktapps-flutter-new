import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'report/cashew_report_screen.dart';
import 'report/debts_report_screen.dart';
import 'report/denominations_report_screen.dart';
import 'report/loan_report_screen.dart';
import 'report/milk_report_screen.dart';
import 'report/msi_report_screen.dart';
import 'report/rent_report_screen.dart';
import 'report/scan_report_screen.dart';
import 'report/wallet_report_screen.dart';
import 'screens/calculators_screen.dart';
import 'screens/cashew_screen.dart';
import 'screens/dashboard.dart';
import 'screens/debts_screen.dart';
import 'screens/denominations_screen.dart';
import 'screens/loan_screen.dart';
import 'screens/milk_bill_screen.dart';
import 'screens/msi_screen.dart';
import 'screens/rent_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/wallet_screen.dart';
import 'settings.dart';

void main() {
  runApp(const KTAppsApp());
}

enum WheelLayoutType { centerWheel, sideWheel, tempOrbitWheel }

class KTAppsApp extends StatefulWidget {
  const KTAppsApp({super.key});

  @override
  State<KTAppsApp> createState() => _KTAppsAppState();
}

class _KTAppsAppState extends State<KTAppsApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  WheelLayoutType _selectedLayout = WheelLayoutType.centerWheel;
  bool _pinEnabled = false;
  String _appPin = '1234';
  bool _isAuthenticated = true;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final darkMode = prefs.getBool('darkMode') ?? true;
    final useSide = prefs.getBool('useSideWheelUI') ?? false;
    final useTemp = prefs.getBool('useTempWheelUI') ?? false;
    final pinEnabled = prefs.getBool('pinEnabled') ?? false;
    final pin = prefs.getString('appPin') ?? '1234';

    WheelLayoutType layout = WheelLayoutType.centerWheel;
    if (useTemp) {
      layout = WheelLayoutType.tempOrbitWheel;
    } else if (useSide) {
      layout = WheelLayoutType.sideWheel;
    }

    if (!mounted) return;
    setState(() {
      _themeMode = darkMode ? ThemeMode.dark : ThemeMode.light;
      _selectedLayout = layout;
      _pinEnabled = pinEnabled;
      _appPin = pin;
      _isAuthenticated = !pinEnabled;
      _isReady = true;
    });
  }

  Future<void> _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDark);
    if (!mounted) return;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  Future<void> _changeLayout(WheelLayoutType layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSideWheelUI', layout == WheelLayoutType.sideWheel);
    await prefs.setBool(
        'useTempWheelUI', layout == WheelLayoutType.tempOrbitWheel);
    await prefs.setBool('useNewMainUI', true);

    if (!mounted) return;
    setState(() {
      _selectedLayout = layout;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KT Apps',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        colorScheme: const ColorScheme.light(
          surface: Color(0xCCFFFFFF),
          primary: Color(0xFF6366F1),
          onSurface: Color(0xFF1A202C),
          secondary: Color(0xFF4A5568),
        ),
        fontFamily: 'Plus Jakarta Sans',
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030305),
        colorScheme: const ColorScheme.dark(
          surface: Color(0x990F172A),
          primary: Color(0xFF6366F1),
          onSurface: Colors.white,
          secondary: Color(0xFFA1A1AA),
        ),
        fontFamily: 'Plus Jakarta Sans',
      ),
      routes: {
        '/cashew': (_) => const CashewScreen(),
        '/milk': (_) => const MilkBillScreen(),
        '/rent': (_) => const RentScreen(),
        '/msi': (_) => const MsiScreen(),
        '/debts': (_) => const DebtsScreen(),
        '/denominations': (_) => const DenominationsScreen(),
        '/calculator': (_) => const CalculatorsScreen(),
        '/loan': (_) => const LoanScreen(),
        '/scan': (_) => const ScanScreen(),
        '/wallet': (_) => const WalletScreen(),
        '/reports': (_) => const DashboardScreen(),
        '/settings': (_) => SettingsScreen(
              onThemeChanged: _toggleTheme,
              onSettingsSaved: _loadSettings,
            ),
        '/report/cashew': (_) => const CashewReportScreen(),
        '/report/milk': (_) => const MilkReportScreen(),
        '/report/rent': (_) => const RentReportScreen(),
        '/report/msi': (_) => const MsiReportScreen(),
        '/report/debts': (_) => const DebtsReportScreen(),
        '/report/denominations': (_) => const DenominationsReportScreen(),
        '/report/loan': (_) => const LoanReportScreen(),
        '/report/scan': (_) => const ScanReportScreen(),
        '/report/wallet': (_) => const WalletReportScreen(),
      },
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_pinEnabled && !_isAuthenticated) {
      return AuthScreen(
        correctPin: _appPin,
        onSuccess: () {
          setState(() {
            _isAuthenticated = true;
          });
        },
      );
    }

    return MainHomeScreen(
      selectedLayout: _selectedLayout,
      isDarkMode: _themeMode == ThemeMode.dark,
      onToggleTheme: _toggleTheme,
      onChangeLayout: _changeLayout,
    );
  }
}

class AppItem {
  final int id;
  final String text;
  final String route;
  final IconData icon;
  final Color color;

  const AppItem({
    required this.id,
    required this.text,
    required this.route,
    required this.icon,
    required this.color,
  });
}

final List<AppItem> appData = [
  const AppItem(
      id: 1,
      text: 'Cashew',
      route: '/cashew',
      icon: Icons.eco,
      color: Color(0xFFF472B6)),
  const AppItem(
      id: 2,
      text: 'Milk Bill',
      route: '/milk',
      icon: Icons.water_drop,
      color: Color(0xFFE2E8F0)),
  const AppItem(
      id: 3,
      text: 'Rent',
      route: '/rent',
      icon: Icons.home,
      color: Color(0xFFC084FC)),
  const AppItem(
      id: 4,
      text: 'MSI',
      route: '/msi',
      icon: Icons.show_chart,
      color: Color(0xFF38BDF8)),
  const AppItem(
      id: 5,
      text: 'Debts',
      route: '/debts',
      icon: Icons.receipt_long,
      color: Color(0xFFF87171)),
  const AppItem(
      id: 6,
      text: 'Denoms',
      route: '/denominations',
      icon: Icons.attach_money,
      color: Color(0xFF4ADE80)),
  const AppItem(
      id: 7,
      text: 'Calculators',
      route: '/calculator',
      icon: Icons.calculate,
      color: Color(0xFFFB923C)),
  const AppItem(
      id: 8,
      text: 'Loan',
      route: '/loan',
      icon: Icons.account_balance,
      color: Color(0xFF818CF8)),
  const AppItem(
      id: 9,
      text: 'Scan',
      route: '/scan',
      icon: Icons.qr_code_scanner,
      color: Color(0xFFA78BFA)),
  const AppItem(
      id: 10,
      text: 'Wallet',
      route: '/wallet',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF22D3EE)),
];

class AuthScreen extends StatefulWidget {
  final String correctPin;
  final VoidCallback onSuccess;

  const AuthScreen({
    super.key,
    required this.correctPin,
    required this.onSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _shakeController;
  String _errorMessage = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 380),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  void _handlePinInput(String value) {
    if (value.length != 4) return;

    if (value == widget.correctPin) {
      widget.onSuccess();
      return;
    }

    setState(() {
      _hasError = true;
      _errorMessage = 'Incorrect PIN. Try again.';
    });

    _shakeController.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      _pinController.clear();
      setState(() {
        _hasError = false;
        _errorMessage = '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            const Positioned.fill(child: AmbientBackground()),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [Color(0x336366F1), Color(0x248B5CF6)],
                        ),
                        border: Border.all(color: const Color(0x476366F1)),
                      ),
                      child: const Icon(Icons.apps_rounded,
                          size: 40, color: Colors.indigoAccent),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'KT Apps',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getGreeting(),
                      style:
                          const TextStyle(fontSize: 12, color: Colors.white54),
                    ),
                    const SizedBox(height: 36),
                    AnimatedBuilder(
                      animation: _shakeController,
                      builder: (context, child) {
                        final dx =
                            math.sin(_shakeController.value * math.pi * 4) * 8;
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final isFilled =
                                  _pinController.text.length > index;
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 9),
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _hasError
                                      ? Colors.red
                                      : (isFilled
                                          ? const Color(0xFF6366F1)
                                          : Colors.transparent),
                                  border: Border.all(
                                    color: _hasError
                                        ? Colors.redAccent
                                        : (isFilled
                                            ? const Color(0xFF6366F1)
                                            : Colors.white24),
                                    width: 2,
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_errorMessage.isNotEmpty)
                      Text(
                        _errorMessage,
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        width: 1,
                        height: 1,
                        child: TextField(
                          controller: _pinController,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          onChanged: (value) {
                            setState(() {});
                            _handlePinInput(value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.keyboard, size: 14, color: Colors.white38),
                        SizedBox(width: 6),
                        Text('Type your 4-digit PIN',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainHomeScreen extends StatelessWidget {
  final WheelLayoutType selectedLayout;
  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;
  final ValueChanged<WheelLayoutType> onChangeLayout;

  const MainHomeScreen({
    super.key,
    required this.selectedLayout,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onChangeLayout,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: AmbientBackground()),
            Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color:
                                  theme.colorScheme.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Icon(Icons.widgets,
                                color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hola KT',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                _getGreeting(),
                                style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.secondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Settings',
                            icon: const Icon(Icons.settings),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/settings'),
                          ),
                          IconButton(
                            tooltip: 'Dashboard',
                            icon: const Icon(Icons.assessment_rounded),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/reports'),
                          ),
                          IconButton(
                            icon: Icon(isDarkMode
                                ? Icons.light_mode
                                : Icons.dark_mode),
                            onPressed: () => onToggleTheme(!isDarkMode),
                          ),
                          PopupMenuButton<WheelLayoutType>(
                            icon: const Icon(Icons.tune),
                            onSelected: onChangeLayout,
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: WheelLayoutType.centerWheel,
                                child: Text('Center Wheel UI'),
                              ),
                              PopupMenuItem(
                                value: WheelLayoutType.sideWheel,
                                child: Text('Side Wheel UI'),
                              ),
                              PopupMenuItem(
                                value: WheelLayoutType.tempOrbitWheel,
                                child: Text('Temp Wheel UI'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildLayout(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Copyright 2024 Thammineni Technologies. All rights reserved.',
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.secondary.withOpacity(0.6)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    void onAppTap(String route) => Navigator.pushNamed(context, route);

    switch (selectedLayout) {
      case WheelLayoutType.sideWheel:
        return SideWheelLayoutWidget(onAppTap: onAppTap);
      case WheelLayoutType.tempOrbitWheel:
        return TempOrbitWheelLayoutWidget(onAppTap: onAppTap);
      case WheelLayoutType.centerWheel:
        return CenterWheelLayoutWidget(onAppTap: onAppTap);
    }
  }
}

class CenterWheelLayoutWidget extends StatelessWidget {
  final ValueChanged<String> onAppTap;

  const CenterWheelLayoutWidget({
    super.key,
    required this.onAppTap,
  });

  @override
  Widget build(BuildContext context) {
    final leftItems = appData.where((e) => e.id <= 5).toList();
    final rightItems = appData.where((e) => e.id > 5).toList();

    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: leftItems
                .map((item) => _buildNode(context, item, isLeft: true))
                .toList(),
          ),
        ),
        Container(
          width: 140,
          height: 140,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: const Color(0xFF6366F1), width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x336366F1), blurRadius: 28)
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.apps, size: 42, color: Color(0xFF6366F1)),
              SizedBox(height: 6),
              Text('KT APPS',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: rightItems
                .map((item) => _buildNode(context, item, isLeft: false))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNode(BuildContext context, AppItem item,
      {required bool isLeft}) {
    return InkWell(
      onTap: () => onAppTap(item.route),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: item.color.withOpacity(0.7), width: 1.5),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          mainAxisAlignment:
              isLeft ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isLeft) _buildBadge(item),
            Expanded(
              child: Text(
                item.text,
                textAlign: isLeft ? TextAlign.right : TextAlign.left,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isLeft) _buildBadge(item),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(AppItem item) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(shape: BoxShape.circle, color: item.color),
      child: Center(
        child: Text(
          '${item.id}',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11),
        ),
      ),
    );
  }
}

class SideWheelLayoutWidget extends StatelessWidget {
  final ValueChanged<String> onAppTap;

  const SideWheelLayoutWidget({
    super.key,
    required this.onAppTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const SweepGradient(
              colors: [
                Color(0xFFF472B6),
                Color(0xFF38BDF8),
                Color(0xFF4ADE80),
                Color(0xFFF472B6)
              ],
            ),
            border: Border.all(color: Colors.white24, width: 4),
          ),
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: const Center(
                child: Text('KT APPS',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ListView.separated(
            itemCount: appData.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = appData[index];
              return InkWell(
                onTap: () => onAppTap(item.route),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(color: item.color.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: item.color),
                        child: Center(
                            child: Icon(item.icon,
                                size: 14, color: Colors.black87)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.text,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 10, color: Colors.white38),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TempOrbitWheelLayoutWidget extends StatefulWidget {
  final ValueChanged<String> onAppTap;

  const TempOrbitWheelLayoutWidget({
    super.key,
    required this.onAppTap,
  });

  @override
  State<TempOrbitWheelLayoutWidget> createState() =>
      _TempOrbitWheelLayoutWidgetState();
}

class _TempOrbitWheelLayoutWidgetState extends State<TempOrbitWheelLayoutWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final center =
            Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        final radius =
            math.min(constraints.maxWidth, constraints.maxHeight) * 0.35;

        return AnimatedBuilder(
          animation: _rotationController,
          builder: (context, child) {
            final angle = _rotationController.value * 2 * math.pi;

            return Stack(
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: OrbitLinesPainter(
                    center: center,
                    radius: radius,
                    angle: angle,
                    itemsCount: appData.length,
                  ),
                ),
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A2A3A),
                      border: Border.all(
                          color: Colors.cyanAccent.withOpacity(0.5), width: 3),
                      boxShadow: const [
                        BoxShadow(color: Colors.cyan, blurRadius: 20)
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'KT APPS',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
                    ),
                  ),
                ),
                ...List.generate(appData.length, (index) {
                  final nodeAngle =
                      angle + (index / appData.length) * 2 * math.pi;
                  final x = center.dx + radius * math.cos(nodeAngle) - 22;
                  final y = center.dy + radius * math.sin(nodeAngle) - 22;
                  final item = appData[index];

                  return Positioned(
                    left: x,
                    top: y,
                    child: InkWell(
                      onTap: () => widget.onAppTap(item.route),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item.color,
                          boxShadow: [
                            BoxShadow(
                                color: item.color.withOpacity(0.6),
                                blurRadius: 10)
                          ],
                        ),
                        child: Icon(item.icon, size: 20, color: Colors.black87),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

class OrbitLinesPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double angle;
  final int itemsCount;

  OrbitLinesPainter({
    required this.center,
    required this.radius,
    required this.angle,
    required this.itemsCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < itemsCount; i++) {
      final nodeAngle = angle + (i / itemsCount) * 2 * math.pi;
      final target = Offset(
        center.dx + radius * math.cos(nodeAngle),
        center.dy + radius * math.sin(nodeAngle),
      );
      canvas.drawLine(center, target, paint);
    }
  }

  @override
  bool shouldRepaint(covariant OrbitLinesPainter oldDelegate) {
    return true;
  }
}

class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF030305)),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.15),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
