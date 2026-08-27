import 'dart:ui';
import 'package:flutter/material.dart';

class LoanSettingsScreen extends StatefulWidget {
  const LoanSettingsScreen({super.key});

  @override
  State<LoanSettingsScreen> createState() => _LoanSettingsScreenState();
}

class _LoanSettingsScreenState extends State<LoanSettingsScreen> {
  final List<Map<String, dynamic>> _themes = [
    {"name": "Default Dark", "primary": Color(0xFF6C63FF), "secondary": Color(0xFF00D2FC), "bg": Color(0xFF1a1a2e)},
    {"name": "Ocean Blue", "primary": Color(0xFF3498db), "secondary": Color(0xFF2ecc71), "bg": Color(0xFF2c3e50)},
    {"name": "Forest Green", "primary": Color(0xFF27ae60), "secondary": Color(0xFF2980b9), "bg": Color(0xFF2d3436)},
    {"name": "Sunset Orange", "primary": Color(0xFFe67e22), "secondary": Color(0xFFf39c12), "bg": Color(0xFF34495e)},
    {"name": "Royal Purple", "primary": Color(0xFF9b59b6), "secondary": Color(0xFF8e44ad), "bg": Color(0xFF2c3e50)},
    {"name": "Crimson Red", "primary": Color(0xFFe74c3c), "secondary": Color(0xFFc0392b), "bg": Color(0xFF2d3436)},
    {"name": "Emerald City", "primary": Color(0xFF1abc9c), "secondary": Color(0xFF16a085), "bg": Color(0xFF2c3e50)},
  ];

  String _selectedTheme = "Default Dark";
  bool _isDarkMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030305),
      body: Stack(
        children: [
          const _GridBackground(),
          _buildBackgroundOrbs(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Choose Theme'),
                        const SizedBox(height: 16),
                        _buildThemeGrid(),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Preferences'),
                        const SizedBox(height: 16),
                        _buildDarkModeToggle(),
                      ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
          const SizedBox(width: 8),
          const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Spacer(),
          _buildHeaderAction(Icons.home, () => Navigator.popUntil(context, (route) => route.isFirst)),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        child: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildThemeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.5),
      itemCount: _themes.length,
      itemBuilder: (context, i) {
        final theme = _themes[i];
        final isSelected = _selectedTheme == theme['name'];
        return InkWell(
          onTap: () => setState(() => _selectedTheme = theme['name']),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF151A25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? theme['primary'] : Colors.white.withValues(alpha: 0.05), width: 2),
            ),
            child: Stack(
              children: [
                Positioned(top: 12, left: 12, right: 12, bottom: 40, child: Row(children: [
                  Expanded(child: Container(decoration: BoxDecoration(color: theme['primary'], borderRadius: BorderRadius.circular(8)))),
                  const SizedBox(width: 8),
                  Expanded(child: Container(decoration: BoxDecoration(color: theme['secondary'], borderRadius: BorderRadius.circular(8)))),
                ])),
                Positioned(bottom: 12, left: 12, child: Text(theme['name'], style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold))),
                if (isSelected) const Positioned(top: 8, right: 8, child: Icon(Icons.check_circle, color: Colors.white, size: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDarkModeToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF151A25), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Dark Mode', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          Switch(value: _isDarkMode, onChanged: (v) => setState(() => _isDarkMode = v), activeColor: const Color(0xFF6366F1)),
        ],
      ),
    );
  }

  Widget _buildBackgroundOrbs() {
    return Stack(children: [
      Positioned(top: -100, left: -100, child: _Orb(color: const Color(0xFF6366F1).withValues(alpha: 0.1), size: 400)),
      Positioned(bottom: -100, right: -100, child: _Orb(color: const Color(0xFF8B5CF6).withValues(alpha: 0.1), size: 400)),
    ]);
  }
}

class _Orb extends StatelessWidget {
  final Color color; final double size;
  const _Orb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) { return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent))); }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();
  @override
  Widget build(BuildContext context) { return CustomPaint(size: Size.infinite, painter: _GridPainter()); }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.02)..strokeWidth = 1.0;
    const step = 40.0;
    for (double i = 0; i < size.width; i += step) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += step) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
