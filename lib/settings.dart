import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HomeUiMode { legacy, center, side, temp }

class SettingsScreen extends StatefulWidget {
  final ValueChanged<bool>? onThemeChanged;
  final VoidCallback? onSettingsSaved;

  const SettingsScreen({
    super.key,
    this.onThemeChanged,
    this.onSettingsSaved,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;

  String _language = 'en';
  bool _darkMode = true;
  bool _notificationsEnabled = false;
  String _notificationStyle = 'toast';

  HomeUiMode _uiMode = HomeUiMode.center;

  bool _pinEnabled = false;
  bool _fingerprintEnabled = false;
  bool _hasPin = false;
  bool _showPinEditor = false;

  bool _cashewAutoCalc = true;
  double _milkDefaultPrice = 60.0;
  bool _loanReminders = true;

  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _milkPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _newPinController.dispose();
    _confirmPinController.dispose();
    _milkPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUnifiedUi = prefs.getBool('useNewMainUI');
    final useSide = prefs.getBool('useSideWheelUI') ?? false;
    final useTemp = prefs.getBool('useTempWheelUI') ?? false;

    HomeUiMode resolvedMode;
    if (useTemp) {
      resolvedMode = HomeUiMode.temp;
    } else if (useSide) {
      resolvedMode = HomeUiMode.side;
    } else if (savedUnifiedUi == false) {
      resolvedMode = HomeUiMode.legacy;
    } else {
      resolvedMode = HomeUiMode.center;
    }

    if (!mounted) return;
    setState(() {
      _language = prefs.getString('language') ?? 'en';
      _darkMode = prefs.getBool('darkMode') ?? true;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? false;
      _notificationStyle = prefs.getString('notificationStyle') ?? 'toast';
      _uiMode = resolvedMode;
      _pinEnabled = prefs.getBool('pinEnabled') ?? false;
      _fingerprintEnabled = prefs.getBool('fingerprintUnlock') ?? false;
      _hasPin = (prefs.getString('appPin') ?? '').isNotEmpty;
      _cashewAutoCalc = prefs.getBool('cashew_auto_calc') ?? true;
      _milkDefaultPrice = prefs.getDouble('milk_default_price') ?? 60.0;
      _loanReminders = prefs.getBool('loan_reminders') ?? true;
      _milkPriceController.text = _milkDefaultPrice.toString();
      _loading = false;
    });
  }

  Future<void> _saveDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
    widget.onSettingsSaved?.call();
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    widget.onSettingsSaved?.call();
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    widget.onSettingsSaved?.call();
  }

  Future<void> _applyUiMode(HomeUiMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _uiMode = mode);

    final isCenter = mode == HomeUiMode.center;
    final isSide = mode == HomeUiMode.side;
    final isTemp = mode == HomeUiMode.temp;

    await prefs.setBool('useNewMainUI', mode != HomeUiMode.legacy);
    await prefs.setBool('useSideWheelUI', isSide);
    await prefs.setBool('useTempWheelUI', isTemp);
    await prefs.setBool('useNewHomeUI', isCenter || isSide || isTemp);
    await prefs.setBool('useNewDashboardUI', isCenter || isSide || isTemp);

    widget.onSettingsSaved?.call();
  }

  Future<void> _savePin() async {
    final newPin = _newPinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();
    final isNumeric = RegExp(r'^\d+').hasMatch(newPin) &&
        newPin.runes.every((c) => c >= 48 && c <= 57);

    if (!isNumeric || newPin.length < 4 || newPin.length > 6) {
      _showSnack('PIN must be 4-6 digits.');
      return;
    }

    if (newPin != confirmPin) {
      _showSnack('PINs do not match.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appPin', newPin);

    if (!mounted) return;
    setState(() {
      _hasPin = true;
      _showPinEditor = false;
      _newPinController.clear();
      _confirmPinController.clear();
    });
    _showSnack('PIN saved successfully.');
    widget.onSettingsSaved?.call();
  }

  Future<void> _clearLocalData() async {
    final shouldClear = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear Local Data'),
            content: const Text(
              'Are you sure you want to clear all local settings and data? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Clear'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldClear) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _loadSettings();
    _showSnack('All local data cleared.');
    widget.onSettingsSaved?.call();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor.withValues(alpha: 0.92),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('App Settings', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 14),
            _buildSection(
              context,
              title: 'General',
              children: [
                _buildRow(
                  label: 'Language',
                  trailing: DropdownButton<String>(
                    value: _language,
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English')),
                      DropdownMenuItem(value: 'es', child: Text('Spanish')),
                      DropdownMenuItem(value: 'fr', child: Text('French')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _language = value);
                      _saveString('language', value);
                    },
                  ),
                ),
                _buildRow(
                  label: 'Dark Mode',
                  trailing: Switch.adaptive(
                    value: _darkMode,
                    onChanged: (value) {
                      setState(() => _darkMode = value);
                      _saveBool('darkMode', value);
                      widget.onThemeChanged?.call(value);
                    },
                  ),
                ),
                _buildRow(
                  label: 'Enable Notifications',
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                      _saveBool('notificationsEnabled', value);
                    },
                  ),
                ),
                _buildRow(
                  label: 'Notification Style',
                  trailing: DropdownButton<String>(
                    value: _notificationStyle,
                    items: const [
                      DropdownMenuItem(
                          value: 'toast', child: Text('Toast (Banner)')),
                      DropdownMenuItem(
                          value: 'popup', child: Text('Popup (Dialog)')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _notificationStyle = value);
                      _saveString('notificationStyle', value);
                    },
                  ),
                ),
              ],
            ),
            _buildSection(
              context,
              title: 'Views',
              children: [
                const ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  title: Text('Home + Dashboard UI Mode'),
                  subtitle: Text('Only one toggle can be ON'),
                ),
                _buildUiToggle('Use Center Wheel UI Home + Dashboard UI',
                    HomeUiMode.center),
                _buildUiToggle(
                    'Use Side Wheel UI (Home + Dashboard)', HomeUiMode.side),
                _buildUiToggle(
                    'Use Temp Wheel UI (Home + Dashboard)', HomeUiMode.temp),
              ],
            ),
            _buildSection(
              context,
              title: 'Security',
              children: [
                _buildRow(
                  label: 'Enable PIN Screen',
                  trailing: Switch.adaptive(
                    value: _pinEnabled,
                    onChanged: (value) {
                      setState(() {
                        _pinEnabled = value;
                        if (!value) _showPinEditor = false;
                      });
                      _saveBool('pinEnabled', value);
                    },
                  ),
                ),
                _buildRow(
                  label: 'Set/Change PIN',
                  trailing: FilledButton(
                    onPressed: () {
                      setState(() {
                        _showPinEditor = !_showPinEditor;
                        _newPinController.clear();
                        _confirmPinController.clear();
                      });
                    },
                    child: Text(_hasPin ? 'Change PIN' : 'Set PIN'),
                  ),
                ),
                if (_showPinEditor)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Column(
                      children: [
                        TextField(
                          controller: _newPinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Enter new PIN (4-6 digits)'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _confirmPinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Confirm new PIN'),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                              onPressed: _savePin,
                              child: const Text('Save PIN')),
                        ),
                      ],
                    ),
                  ),
                _buildRow(
                  label: 'Enable Fingerprint Unlock',
                  trailing: Switch.adaptive(
                    value: _fingerprintEnabled,
                    onChanged: (value) {
                      setState(() => _fingerprintEnabled = value);
                      _saveBool('fingerprintUnlock', value);
                    },
                  ),
                ),
              ],
            ),
            _buildSection(
              context,
              title: 'Data Management',
              children: [
                _buildRow(
                  label: 'Clear Local Data',
                  trailing: FilledButton.tonal(
                    onPressed: _clearLocalData,
                    child: const Text('Clear'),
                  ),
                ),
              ],
            ),
            _buildSection(
              context,
              title: 'Module Settings',
              children: [
                _buildModuleAccordion(
                  context,
                  title: 'Cashew',
                  icon: Icons.eco,
                  children: [
                    _buildRow(
                      label: 'Auto-calculate from description',
                      trailing: Switch.adaptive(
                        value: _cashewAutoCalc,
                        onChanged: (value) {
                          setState(() => _cashewAutoCalc = value);
                          _saveBool('cashew_auto_calc', value);
                        },
                      ),
                    ),
                    _buildRow(
                      label: 'Default Sheet URL',
                      trailing: const Icon(Icons.link, size: 18),
                    ),
                  ],
                ),
                _buildModuleAccordion(
                  context,
                  title: 'Milk Bill',
                  icon: Icons.water_drop,
                  children: [
                    _buildRow(
                      label: 'Default Milk Price (L)',
                      trailing: SizedBox(
                        width: 80,
                        child: TextField(
                          controller: _milkPriceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          textAlign: TextAlign.end,
                          decoration: const InputDecoration(
                            prefixText: '₹',
                            isDense: true,
                          ),
                          onSubmitted: (value) {
                            final price = double.tryParse(value);
                            if (price != null) {
                              setState(() => _milkDefaultPrice = price);
                              _saveDouble('milk_default_price', price);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                _buildModuleAccordion(
                  context,
                  title: 'Rent',
                  icon: Icons.home,
                  children: [
                    _buildRow(
                      label: 'Enable Automated Reminders',
                      trailing: Switch.adaptive(
                        value: false,
                        onChanged: (v) {},
                      ),
                    ),
                  ],
                ),
                _buildModuleAccordion(
                  context,
                  title: 'MSI',
                  icon: Icons.show_chart,
                  children: [
                    _buildRow(
                      label: 'Investment Goal Tracking',
                      trailing: Switch.adaptive(
                        value: true,
                        onChanged: (v) {},
                      ),
                    ),
                  ],
                ),
                _buildModuleAccordion(
                  context,
                  title: 'Debts',
                  icon: Icons.receipt_long,
                  children: [
                    _buildRow(
                      label: 'Show Overdue Alerts',
                      trailing: Switch.adaptive(
                        value: true,
                        onChanged: (v) {},
                      ),
                    ),
                  ],
                ),
                _buildModuleAccordion(
                  context,
                  title: 'Denoms',
                  icon: Icons.attach_money,
                  children: [
                    _buildRow(
                      label: 'Show Total Footer',
                      trailing: Switch.adaptive(
                        value: true,
                        onChanged: (v) {},
                      ),
                    ),
                  ],
                ),
                _buildModuleAccordion(
                  context,
                  title: 'Calculators',
                  icon: Icons.calculate,
                  children: [
                    _buildRow(
                      label: 'Default Interest Type',
                      trailing: const Text('Simple'),
                    ),
                  ],
                ),
                _buildModuleAccordion(
                  context,
                  title: 'Loan',
                  icon: Icons.account_balance,
                  children: [
                    _buildRow(
                      label: 'Loan EMI Reminders',
                      trailing: Switch.adaptive(
                        value: _loanReminders,
                        onChanged: (value) {
                          setState(() => _loanReminders = value);
                          _saveBool('loan_reminders', value);
                        },
                      ),
                    ),
                  ],
                ),
                _buildModuleAccordion(
                  context,
                  title: 'Scan',
                  icon: Icons.qr_code_scanner,
                  children: [
                    _buildRow(
                      label: 'Auto-copy to Clipboard',
                      trailing: Switch.adaptive(
                        value: false,
                        onChanged: (v) {},
                      ),
                    ),
                  ],
                ),
                _buildModuleAccordion(
                  context,
                  title: 'Wallet',
                  icon: Icons.account_balance_wallet,
                  children: [
                    _buildRow(
                      label: 'Quick Balance Toggle',
                      trailing: Switch.adaptive(
                        value: true,
                        onChanged: (v) {},
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _buildSection(
              context,
              title: 'About',
              children: const [
                ListTile(
                    dense: true,
                    title: Text('Version'),
                    trailing: Text('1.0.0')),
                ListTile(
                    dense: true,
                    title: Text('Privacy Policy'),
                    trailing: Text('View')),
                ListTile(
                    dense: true,
                    title: Text('Send Feedback'),
                    trailing: Text('Email Us')),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Copyright 2024 Thammineni Technologies. All rights reserved.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUiToggle(String label, HomeUiMode mode) {
    final isActive = _uiMode == mode;
    return _buildRow(
      label: label,
      trailing: Switch.adaptive(
        value: isActive,
        onChanged: (value) {
          if (value) {
            _applyUiMode(mode);
          } else if (_uiMode == mode) {
            _applyUiMode(HomeUiMode.legacy);
          }
        },
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child:
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow({required String label, required Widget trailing}) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      title: Text(label),
      trailing: trailing,
    );
  }

  Widget _buildModuleAccordion(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, size: 18),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        children: children,
      ),
    );
  }
}
