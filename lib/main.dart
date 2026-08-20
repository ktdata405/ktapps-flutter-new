import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cashew/cashew_report_screen.dart';
import 'cashew/cashew_screen.dart';
import 'denominations/denominations_report_screen.dart';
import 'denominations/denominations_screen.dart';
import 'milk/milk_screen.dart';
import 'milk/milk_report_screen.dart';
import 'msi/msi_report_screen.dart';
import 'msi/msi_screen.dart';
import 'settings.dart';

void main() {
  runApp(const KTAppsApp());
}

enum WheelLayoutType {
  centerWheel,
  sideWheel,
  tempOrbitWheel,
  dashboardUI,
  portalUI
}

class KTAppsApp extends StatefulWidget {
  const KTAppsApp({super.key});

  @override
  State<KTAppsApp> createState() => _KTAppsAppState();
}

class _KTAppsAppState extends State<KTAppsApp> {
  ThemeMode _themeMode = ThemeMode.light;
  WheelLayoutType _selectedLayout = WheelLayoutType.portalUI;
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
    final darkMode = prefs.getBool('darkMode') ?? false;
    final useSide = prefs.getBool('useSideWheelUI') ?? false;
    final useTemp = prefs.getBool('useTempWheelUI') ?? false;
    final useDashboard = prefs.getBool('useDashboardUI') ?? false;
    final usePortal = prefs.getBool('usePortalUI') ?? true;
    final pinEnabled = prefs.getBool('pinEnabled') ?? false;
    final pin = prefs.getString('appPin') ?? '1234';

    WheelLayoutType layout = WheelLayoutType.portalUI;
    if (usePortal) {
      layout = WheelLayoutType.portalUI;
    } else if (useDashboard) {
      layout = WheelLayoutType.dashboardUI;
    } else if (useTemp) {
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
    await prefs.setBool(
        'useDashboardUI', layout == WheelLayoutType.dashboardUI);
    await prefs.setBool('usePortalUI', layout == WheelLayoutType.portalUI);
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
        '/milk': (_) => const MilkScreen(),
        '/rent': (_) => const _PlaceholderScreen(title: 'Rent'),
        '/msi': (_) => const MsiScreen(),
        '/debts': (_) => const _PlaceholderScreen(title: 'Debts'),
        '/denominations': (_) => const DenominationsScreen(),
        '/calculator': (_) => const _PlaceholderScreen(title: 'Calculators'),
        '/loan': (_) => const _PlaceholderScreen(title: 'Loan'),
        '/scan': (_) => const _PlaceholderScreen(title: 'Scan'),
        '/wallet': (_) => const _PlaceholderScreen(title: 'Wallet'),
        '/reports': (_) => const _PlaceholderScreen(title: 'Reports Dashboard'),
        '/settings': (_) => SettingsScreen(
              onThemeChanged: _toggleTheme,
              onSettingsSaved: _loadSettings,
            ),
        '/report/milk': (_) => const MilkReportScreen(),
        '/report/rent': (_) => const _PlaceholderScreen(title: 'Rent Report'),
        '/report/msi': (_) => const MsiReportScreen(),
        '/report/debts': (_) => const _PlaceholderScreen(title: 'Debts Report'),
        '/report/denominations': (_) => const DenominationsReportScreen(),
        '/report/loan': (_) => const _PlaceholderScreen(title: 'Loan Report'),
        '/report/scan': (_) => const _PlaceholderScreen(title: 'Scan Report'),
        '/report/wallet': (_) =>
            const _PlaceholderScreen(title: 'Wallet Report'),
        '/report/cashew': (_) => const CashewReportScreen(),
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
      color: Color(0xFF22C55E)),
  const AppItem(
      id: 2,
      text: 'Milk Bill',
      route: '/milk',
      icon: Icons.water_drop,
      color: Color(0xFF3B82F6)),
  const AppItem(
      id: 3,
      text: 'Rent',
      route: '/rent',
      icon: Icons.home,
      color: Color(0xFF8B5CF6)),
  const AppItem(
      id: 4,
      text: 'MSI',
      route: '/msi',
      icon: Icons.show_chart,
      color: Color(0xFF06B6D4)),
  const AppItem(
      id: 5,
      text: 'Debts',
      route: '/debts',
      icon: Icons.receipt_long,
      color: Color(0xFFEF4444)),
  const AppItem(
      id: 6,
      text: 'Denoms',
      route: '/denominations',
      icon: Icons.attach_money,
      color: Color(0xFF10B981)),
  const AppItem(
      id: 7,
      text: 'Calculators',
      route: '/calculator',
      icon: Icons.calculate,
      color: Color(0xFFF59E0B)),
  const AppItem(
      id: 8,
      text: 'Loan',
      route: '/loan',
      icon: Icons.account_balance,
      color: Color(0xFF6366F1)),
  const AppItem(
      id: 9,
      text: 'Scan',
      route: '/scan',
      icon: Icons.qr_code_scanner,
      color: Color(0xFFA855F7)),
  const AppItem(
      id: 10,
      text: 'Wallet',
      route: '/wallet',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF14B8A6)),
];

final List<AppItem> reportData = [
  const AppItem(
      id: 101,
      text: 'Cashew',
      route: '/report/cashew',
      icon: Icons.eco,
      color: Color(0xFF22C55E)),
  const AppItem(
      id: 102,
      text: 'Milk Bill',
      route: '/report/milk',
      icon: Icons.water_drop,
      color: Color(0xFF3B82F6)),
  const AppItem(
      id: 103,
      text: 'Rent',
      route: '/report/rent',
      icon: Icons.home,
      color: Color(0xFF8B5CF6)),
  const AppItem(
      id: 104,
      text: 'MSI',
      route: '/report/msi',
      icon: Icons.show_chart,
      color: Color(0xFF06B6D4)),
  const AppItem(
      id: 105,
      text: 'Debts',
      route: '/report/debts',
      icon: Icons.receipt_long,
      color: Color(0xFFEF4444)),
  const AppItem(
      id: 106,
      text: 'Denoms',
      route: '/report/denominations',
      icon: Icons.attach_money,
      color: Color(0xFF10B981)),
  const AppItem(
      id: 107,
      text: 'Loan',
      route: '/report/loan',
      icon: Icons.account_balance,
      color: Color(0xFF6366F1)),
  const AppItem(
      id: 108,
      text: 'Scan',
      route: '/report/scan',
      icon: Icons.qr_code_scanner,
      color: Color(0xFFA855F7)),
  const AppItem(
      id: 109,
      text: 'Wallet',
      route: '/report/wallet',
      icon: Icons.account_balance_wallet,
      color: Color(0xFF14B8A6)),
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
    // Portal UI takes over the full screen (own Scaffold + bottom nav)
    if (selectedLayout == WheelLayoutType.portalUI) {
      return Theme(
        // Keep dark theme scoped to Student Portal only.
        data: ThemeData(
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
        child: PortalHomeScreen(
          isDarkMode: true,
          onToggleTheme: onToggleTheme,
        ),
      );
    }

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
                              PopupMenuItem(
                                value: WheelLayoutType.dashboardUI,
                                child: Text('Dashboard UI'),
                              ),
                              PopupMenuItem(
                                value: WheelLayoutType.portalUI,
                                child: Text('Portal UI'),
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
      case WheelLayoutType.dashboardUI:
        return DashboardLayoutWidget(onAppTap: onAppTap);
      case WheelLayoutType.portalUI:
        // handled above in build(); should never reach here
        return const SizedBox.shrink();
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

// ──────────────────────────────────────────────────────────────────────────────
// STUDENT PORTAL UI  (matches the Student Portal design template)
// ──────────────────────────────────────────────────────────────────────────────

class _PortalEvent {
  final String month, day, weekday, title, time, location;
  final bool isOrange;
  const _PortalEvent(this.month, this.day, this.weekday, this.title, this.time,
      this.location, this.isOrange);
}

class PortalHomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleTheme;

  const PortalHomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<PortalHomeScreen> createState() => _PortalHomeScreenState();
}

class _PortalHomeScreenState extends State<PortalHomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentTab = 0;
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _orbitController;
  String _searchQuery = '';

  static const _purple = Color(0xFF5C35CC);
  static const _purpleLight = Color(0xFF7B5FE0);
  static const _blueEnd = Color(0xFF3A6ADE);
  static const _textDark = Color(0xFF1A1A2E);
  static const _orange = Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 220),
    )..repeat();
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 👋';
    if (h < 21) return 'Good evening 🌙';
    return 'Good night 🌟';
  }

  Widget _buildMainLogo(double size) {
    return ClipOval(
      child: Image.asset(
        'assets/images/main_logo.jpeg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: _buildTabContent(context),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildTabContent(BuildContext context) {
    if (_currentTab == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          _buildReportsAccess(context),
          const SizedBox(height: 10),
        ],
      );
    }

    if (_currentTab == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildUpcomingEvents(context),
          const SizedBox(height: 10),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        _buildQuickAccess(context),
        const SizedBox(height: 10),
      ],
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = theme.colorScheme.onSurface;
    final secondaryText = theme.colorScheme.secondary;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1B2436),
                  theme.colorScheme.surface.withOpacity(0.95),
                  const Color(0xFF222D3E),
                ]
              : [_purple, _purpleLight, _blueEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting text (top + centered)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surface.withOpacity(0.60)
                      : Colors.white12,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Hello, KT ${_currentTab == 0 ? "👋" : ""}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getGreeting(),
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── Quick Access grid ───────────────────────────────────────────────────────

  Widget _buildQuickAccess(BuildContext context) {
    final filtered = _searchQuery.isEmpty
        ? appData
        : appData
            .where((a) => a.text.toLowerCase().contains(_searchQuery))
            .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final useCircular = kIsWeb && constraints.maxWidth >= 560;
              if (useCircular) {
                return _buildCircularQuickAccess(
                    context, filtered, constraints.maxWidth);
              }
              return _buildQuickAccessGrid(context, filtered);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportsAccess(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final useCircular = kIsWeb && constraints.maxWidth >= 560;
              if (useCircular) {
                return _buildCircularQuickAccess(
                    context, reportData, constraints.maxWidth,
                    isReportCard: true);
              }
              return _buildQuickAccessGrid(context, reportData,
                  isReportCard: true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, List<AppItem> items,
      {bool isReportCard = false}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 144,
        mainAxisExtent: 172,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, i) =>
          _buildQuickCard(ctx, items[i], isReportCard: isReportCard),
    );
  }

  Widget _buildCircularQuickAccess(
      BuildContext context, List<AppItem> items, double maxWidth,
      {bool isReportCard = false}) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final circleSize = math.min(maxWidth, 760.0);
    final cardWidth = circleSize >= 680 ? 132.0 : 112.0;
    final cardHeight = circleSize >= 680 ? 156.0 : 132.0;
    final radius = (circleSize / 2) - (cardWidth / 2) - 12;

    return SizedBox(
      height: circleSize,
      child: Center(
        child: SizedBox(
          width: circleSize,
          height: circleSize,
          child: AnimatedBuilder(
            animation: _orbitController,
            builder: (context, child) {
              final rotationOffset = _orbitController.value * 2 * math.pi;
              return Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: circleSize * 0.28,
                      height: circleSize * 0.28,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: _buildMainLogo(circleSize * 0.42)),
                    ),
                  ),
                  ...List.generate(items.length, (index) {
                    final angle = (-math.pi / 2) +
                        (index / items.length) * 2 * math.pi +
                        rotationOffset;
                    final x = (circleSize / 2) +
                        radius * math.cos(angle) -
                        (cardWidth / 2);
                    final y = (circleSize / 2) +
                        radius * math.sin(angle) -
                        (cardHeight / 2);

                    return Positioned(
                      left: x,
                      top: y,
                      child: SizedBox(
                        width: cardWidth,
                        height: cardHeight,
                        child: _buildQuickCard(context, items[index],
                            isReportCard: isReportCard),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static const _subtitles = {
    '/cashew': 'Expense tracker',
    '/milk': 'Milk bills',
    '/rent': 'Rent records',
    '/msi': 'MSI tracker',
    '/debts': 'Debt records',
    '/denominations': 'Denomination mgmt',
    '/calculator': 'Calculators',
    '/loan': 'Loan tracker',
    '/scan': 'QR scanner',
    '/wallet': 'Wallet tracker',
  };

  Widget _buildQuickCard(BuildContext context, AppItem item,
      {bool isReportCard = false}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isNew = item.id == 9; // Scan is "NEW"
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: item.color.withOpacity(isDark ? 0.34 : 0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.30 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.color.withOpacity(isDark ? 0.28 : 0.20),
                  theme.colorScheme.surface.withOpacity(isDark ? 0.62 : 0.90),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: item.color.withOpacity(0.72), width: 1.5),
            ),
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, item.route),
              splashColor: item.color.withOpacity(0.22),
              highlightColor: item.color.withOpacity(0.10),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 51,
                            height: 51,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  item.color.withOpacity(0.95),
                                  item.color
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: item.color.withOpacity(0.45),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child:
                                Icon(item.icon, color: Colors.white, size: 27),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              item.text,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                                color: theme.colorScheme.onSurface,
                                height: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: item.color.withOpacity(0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isReportCard
                                  ? Icons.data_exploration_outlined
                                  : Icons.east_rounded,
                              size: 36,
                              color: item.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isNew)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: _purple,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('NEW',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Upcoming Events ─────────────────────────────────────────────────────────

  static final _events = [
    _PortalEvent('AUG', '20', 'Wed', 'Cashew Season Review',
        '10:00 AM – 01:00 PM', 'Main Office', false),
    _PortalEvent('AUG', '25', 'Mon', 'Rent Due Date', '09:00 AM – 10:00 AM',
        'Room 204', true),
    _PortalEvent('SEP', '1', 'Tue', 'Loan EMI Reminder', '02:00 PM – 03:00 PM',
        'Bank Branch', false),
  ];

  Widget _buildUpcomingEvents(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = theme.colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.event_available_rounded,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Events',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: primaryText)),
                ],
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/reports'),
                child: const Text('View All Events',
                    style: TextStyle(
                        color: _purple,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? theme.colorScheme.surface.withOpacity(0.65)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4))
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Upcoming Schedule',
                    style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                ..._events.map(_buildEventRow),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventRow(_PortalEvent e) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryText = theme.colorScheme.onSurface;
    final secondaryText = theme.colorScheme.secondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date block
          Container(
            width: 54,
            height: 68,
            decoration: BoxDecoration(
              color:
                  isDark ? _purple.withOpacity(0.2) : const Color(0xFFF4F2FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark
                      ? _purple.withOpacity(0.6)
                      : const Color(0xFFDDD6FF),
                  width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(e.month,
                    style: const TextStyle(
                        fontSize: 10,
                        color: _purple,
                        fontWeight: FontWeight.w700)),
                Text(e.day,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _orange)),
                Text(e.weekday,
                    style: TextStyle(fontSize: 10, color: secondaryText)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryText)),
                const SizedBox(height: 4),
                Row(children: [
                  Icon(Icons.access_time_outlined,
                      size: 12, color: secondaryText),
                  const SizedBox(width: 4),
                  Text(e.time,
                      style: TextStyle(fontSize: 11, color: secondaryText)),
                ]),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.location_on_outlined,
                      size: 12, color: secondaryText),
                  const SizedBox(width: 4),
                  Text(e.location,
                      style: TextStyle(fontSize: 11, color: secondaryText)),
                ]),
              ],
            ),
          ),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: e.isOrange
                  ? (isDark
                      ? _orange.withOpacity(0.18)
                      : const Color(0xFFFFF3EE))
                  : (isDark
                      ? _purple.withOpacity(0.18)
                      : const Color(0xFFF0EDFF)),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: e.isOrange ? _orange : _purple, width: 1.5),
            ),
            child: Text('Upcoming',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: e.isOrange ? _orange : _purple)),
          ),
        ],
      ),
    );
  }

  // ── Bottom navigation ────────────────────────────────────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inactiveColor = theme.colorScheme.secondary;
    const navItems = [
      {'icon': Icons.home_rounded, 'label': 'Dashboard'},
      {'icon': Icons.data_exploration_outlined, 'label': 'Reports'},
      {'icon': Icons.event_available, 'label': 'Events'},
      {'icon': Icons.settings_rounded, 'label': 'Settings'},
    ];

    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? theme.colorScheme.surface.withOpacity(0.8) : Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(navItems.length, (i) {
            final selected = _currentTab == i;
            final icon = navItems[i]['icon'] as IconData;
            final label = navItems[i]['label'] as String;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() => _currentTab = i);
                  if (i == 3) Navigator.pushNamed(context, '/settings');
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon,
                          color: selected ? _purple : inactiveColor, size: 24),
                      const SizedBox(height: 4),
                      Text(label,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                              color: selected ? _purple : inactiveColor)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// DASHBOARD UI  (matches the dark CRM-style dashboard template in the image)
// ──────────────────────────────────────────────────────────────────────────────

class DashboardLayoutWidget extends StatefulWidget {
  final ValueChanged<String> onAppTap;
  const DashboardLayoutWidget({super.key, required this.onAppTap});

  @override
  State<DashboardLayoutWidget> createState() => _DashboardLayoutWidgetState();
}

class _DashboardLayoutWidgetState extends State<DashboardLayoutWidget> {
  int _selectedIndex = 0;

  static const _sidebarBg = Color(0xFF1B2436);
  static const _contentBg = Color(0xFF222D3E);
  static const _cardBg = Color(0xFF1B2436);
  static const _accentGreen = Color(0xFFB8E044);
  static const _accentCyan = Color(0xFF00D4D8);
  static const _accentOrange = Color(0xFFFF6B35);
  static const _accentRed = Color(0xFFE53935);
  static const _accentBlue = Color(0xFF2196F3); // reserved for future use
  static const _textPrimary = Color(0xFFECEFF4);
  static const _textSecondary = Color(0xFF8A9BB0);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  // ── Sidebar ─────────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return Container(
      width: 88,
      color: _sidebarBg,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accentCyan.withOpacity(0.18),
              shape: BoxShape.circle,
              border:
                  Border.all(color: _accentCyan.withOpacity(0.6), width: 1.5),
            ),
            child: const Icon(Icons.apps_rounded, color: _accentCyan, size: 18),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: appData.length,
              itemBuilder: (ctx, i) => _buildSidebarItem(appData[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(AppItem item, int index) {
    final selected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        widget.onAppTap(item.route);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selected ? item.color.withOpacity(0.18) : Colors.transparent,
          border: selected
              ? Border.all(color: item.color.withOpacity(0.5), width: 1)
              : null,
        ),
        child: Column(
          children: [
            Icon(item.icon,
                color: selected ? item.color : _textSecondary, size: 20),
            const SizedBox(height: 4),
            Text(
              item.text,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 9,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? item.color : _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main content ─────────────────────────────────────────────────────────────

  Widget _buildMainContent() {
    return Container(
      color: _contentBg,
      child: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: status overview + table
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildStatusOverviewRow(),
                      Expanded(child: _buildAppTable()),
                    ],
                  ),
                ),
                // Right column: sales chart
                _buildSalesChartPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _sidebarBg,
        border:
            Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: [
          const Text(
            'DASHBOARD',
            style: TextStyle(
              color: _accentCyan,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.6,
            ),
          ),
          const Spacer(),
          _chip(Icons.sort, 'SORT'),
          const SizedBox(width: 8),
          _chip(Icons.bar_chart_rounded, 'SALES CHART'),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  color: _textSecondary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Status overview row ──────────────────────────────────────────────────────

  Widget _buildStatusOverviewRow() {
    return Container(
      height: 130,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          // Donut + legend
          _buildDonutCard(),
          const SizedBox(width: 8),
          // Stat cards
          Expanded(child: _buildStatCards()),
        ],
      ),
    );
  }

  Widget _buildDonutCard() {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('STATUS',
                  style: TextStyle(
                      fontSize: 8,
                      color: _textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const Text('OVERVIEW',
                  style: TextStyle(
                      fontSize: 8,
                      color: _textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              _legendDot(_accentGreen, 'WON'),
              const SizedBox(height: 4),
              _legendDot(_accentOrange, 'LOST'),
              const SizedBox(height: 4),
              _legendDot(Colors.white24, 'NO SALE'),
            ],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            height: 72,
            child: CustomPaint(
              painter: _DonutPainter(
                segments: [
                  _DonutSegment(_accentGreen, 0.55),
                  _DonutSegment(_accentOrange, 0.30),
                  _DonutSegment(Colors.white24, 0.15),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${appData.length ~/ 2 + 1}',
                      style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900),
                    ),
                    const Text('WON',
                        style: TextStyle(
                            color: _accentGreen,
                            fontSize: 7,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 8, color: _textSecondary)),
      ],
    );
  }

  Widget _buildStatCards() {
    final stats = [
      _StatData('5', 'IN 30 DAYS', Icons.calendar_today, _accentGreen),
      _StatData('${appData.length + 8}', 'IN 60 DAYS', Icons.date_range,
          _accentOrange),
    ];
    return Row(
      children: stats
          .map((s) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.07)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          s.value,
                          style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: s.color),
                        ),
                        Icon(s.icon, size: 14, color: s.color),
                        const SizedBox(height: 2),
                        Text(s.label,
                            style: const TextStyle(
                                fontSize: 8, color: _textSecondary)),
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ── App table ────────────────────────────────────────────────────────────────

  Widget _buildAppTable() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: appData.length,
              itemBuilder: (ctx, i) => _buildTableRow(appData[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    const headers = ['STATUS', 'NAME', 'STAGE', 'PROBABILITY', 'AMOUNT', ''];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        border:
            Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        children: headers
            .map((h) => Expanded(
                  child: Text(h,
                      style: const TextStyle(
                          fontSize: 8,
                          color: _textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                ))
            .toList(),
      ),
    );
  }

  static const _statuses = [
    'WON',
    'LOST',
    'OPEN',
    'WON',
    'OPEN',
    'LOST',
    'WON',
    'OPEN',
    'WON',
    'OPEN'
  ];
  static const _stages = [
    'Lorem',
    'Lorem',
    'Lorem',
    'Lorem',
    'Lorem',
    'Lorem',
    'Lorem',
    'Lorem',
    'Lorem',
    'Lorem'
  ];
  static const _probs = [
    0.90,
    0.50,
    0.15,
    0.30,
    0.10,
    0.80,
    0.60,
    0.20,
    0.75,
    0.40
  ];
  static const _amounts = [
    '\$205,000',
    '\$90,000',
    '\$605,000',
    '\$105,000',
    '\$211,000',
    '\$80,000',
    '\$340,000',
    '\$60,000',
    '\$420,000',
    '\$175,000'
  ];

  Color _statusColor(String status) {
    switch (status) {
      case 'WON':
        return _accentGreen;
      case 'LOST':
        return _accentRed;
      default:
        return Colors.white38;
    }
  }

  Widget _buildTableRow(AppItem item, int i) {
    final status = _statuses[i % _statuses.length];
    final prob = _probs[i % _probs.length];
    final amount = _amounts[i % _amounts.length];
    final stage = _stages[i % _stages.length];
    final sColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Colors.white.withOpacity(0.04))),
      ),
      child: Row(
        children: [
          // Status badge
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: sColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sColor.withOpacity(0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 6,
                      height: 6,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: sColor)),
                  const SizedBox(width: 4),
                  Text(status,
                      style: TextStyle(
                          fontSize: 8,
                          color: sColor,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          // Name
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: item.color),
                  child: Icon(item.icon, size: 11, color: Colors.black87),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(item.text,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 9,
                          color: _textPrimary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          // Stage
          Expanded(
            child: Text(stage,
                style: const TextStyle(fontSize: 9, color: _textSecondary)),
          ),
          // Probability bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(prob * 100).toInt()}%',
                    style: const TextStyle(fontSize: 8, color: _textSecondary)),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: prob,
                    minHeight: 5,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation<Color>(_accentCyan),
                  ),
                ),
              ],
            ),
          ),
          // Amount
          Expanded(
            child: Text(amount,
                style: const TextStyle(
                    fontSize: 9,
                    color: _textPrimary,
                    fontWeight: FontWeight.w600)),
          ),
          // VIEW button
          GestureDetector(
            onTap: () => widget.onAppTap(item.route),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _accentGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _accentGreen.withOpacity(0.7)),
              ),
              child: const Text('VIEW',
                  style: TextStyle(
                      fontSize: 8,
                      color: _accentGreen,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sales chart panel ────────────────────────────────────────────────────────

  Widget _buildSalesChartPanel() {
    return Container(
      width: 160,
      margin: const EdgeInsets.fromLTRB(0, 8, 8, 8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SALES CHART',
              style: TextStyle(
                  fontSize: 8,
                  color: _textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          Row(
            children: [
              _legendDot(_accentGreen, 'WON'),
              const SizedBox(width: 8),
              _legendDot(_accentRed, 'LOST'),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: CustomPaint(
              painter: _DotChartPainter(),
              size: const Size(double.infinity, double.infinity),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('J', style: TextStyle(fontSize: 6, color: _textSecondary)),
              Text('F', style: TextStyle(fontSize: 6, color: _textSecondary)),
              Text('M', style: TextStyle(fontSize: 6, color: _textSecondary)),
              Text('A', style: TextStyle(fontSize: 6, color: _textSecondary)),
              Text('M', style: TextStyle(fontSize: 6, color: _textSecondary)),
              Text('J', style: TextStyle(fontSize: 6, color: _textSecondary)),
              Text('J', style: TextStyle(fontSize: 6, color: _textSecondary)),
              Text('A', style: TextStyle(fontSize: 6, color: _textSecondary)),
              Text('S', style: TextStyle(fontSize: 6, color: _textSecondary)),
              Text('O', style: TextStyle(fontSize: 6, color: _textSecondary)),
              Text('N', style: TextStyle(fontSize: 6, color: _textSecondary)),
              Text('D', style: TextStyle(fontSize: 6, color: _textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Supporting data models ────────────────────────────────────────────────────

class _StatData {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatData(this.value, this.label, this.icon, this.color);
}

class _DonutSegment {
  final Color color;
  final double fraction;
  const _DonutSegment(this.color, this.fraction);
}

// ── Custom painters ───────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;
  const _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2);
    const strokeW = 10.0;
    final innerRect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2 - strokeW);

    double startAngle = -math.pi / 2;
    for (final seg in segments) {
      final sweepAngle = seg.fraction * 2 * math.pi;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.fill;
      final path = Path()
        ..moveTo(size.width / 2, size.height / 2)
        ..arcTo(rect, startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(path, paint);
      startAngle += sweepAngle;
    }

    // Hollow center
    canvas.drawOval(
        innerRect,
        Paint()
          ..color = const Color(0xFF1B2436)
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => false;
}

class _DotChartPainter extends CustomPainter {
  static const _won = Color(0xFFB8E044);
  static const _lost = Color(0xFFE53935);

  // Pre-computed dot data: (monthIndex 0-11, normalizedY 0-1, isWon)
  static const _dots = [
    (0, 0.3, true),
    (0, 0.7, false),
    (1, 0.5, true),
    (1, 0.6, false),
    (2, 0.2, true),
    (2, 0.8, false),
    (3, 0.4, true),
    (3, 0.5, false),
    (4, 0.6, true),
    (4, 0.3, false),
    (5, 0.1, true),
    (5, 0.9, false),
    (6, 0.7, true),
    (6, 0.2, false),
    (7, 0.5, true),
    (7, 0.6, false),
    (8, 0.3, true),
    (8, 0.75, false),
    (9, 0.8, true),
    (9, 0.4, false),
    (10, 0.2, true),
    (10, 0.55, false),
    (11, 0.6, true),
    (11, 0.35, false),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const months = 12;
    final colW = size.width / (months - 1);

    for (final d in _dots) {
      final month = d.$1;
      final y = d.$2;
      final isWon = d.$3;
      final x = month * colW;
      final dy = y * size.height;
      canvas.drawCircle(
        Offset(x, dy),
        3.5,
        Paint()..color = isWon ? _won : _lost,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DotChartPainter old) => false;
}

// ──────────────────────────────────────────────────────────────────────────────

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

// ── Placeholder screen for removed modules ──────────────────────────────────
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
              ),
              child: const Icon(Icons.construction,
                  color: Color(0xFF6366F1), size: 40),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Coming Soon',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
