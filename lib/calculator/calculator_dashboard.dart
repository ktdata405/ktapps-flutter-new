import 'dart:math' as math;
import 'package:flutter/material.dart';

class CalculatorDashboard extends StatefulWidget {
  const CalculatorDashboard({super.key});

  @override
  State<CalculatorDashboard> createState() => _CalculatorDashboardState();
}

class _CalculatorDashboardState extends State<CalculatorDashboard> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030305),
      body: Stack(
        children: [
          const _ParticleBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildGrid()),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: const [Colors.white, Colors.white38, Colors.white],
                    stops: [
                      _shimmerController.value - 0.2,
                      _shimmerController.value,
                      _shimmerController.value + 0.2,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: const Text('Calculators', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              );
            },
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white), style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.05), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final items = [
      _CalcItem(title: 'Land Calculator', icon: Icons.straighten, color: const Color(0xFF4ADE80), route: '/calculator/land'),
      _CalcItem(title: 'Govt Schemes', icon: Icons.account_balance, color: const Color(0xFFFBBF24), route: '/calculator/govt'),
      _CalcItem(title: 'Interest Float/Flat', icon: Icons.percent, color: const Color(0xFFF472B6), route: '/calculator/interest'),
      _CalcItem(title: 'Village Finance', icon: Icons.people, color: const Color(0xFFC084FC), route: '/calculator/village'),
      _CalcItem(title: 'Vehicle Info', icon: Icons.car_repair, color: const Color(0xFF60A5FA), route: '/calculator/vehicle'),
      _CalcItem(title: 'LAMF Calculator', icon: Icons.savings, color: const Color(0xFFFB923C), route: '/calculator/lamf'),
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.2),
      itemCount: items.length,
      itemBuilder: (context, i) => _CalcCard(item: items[i]),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(color: Colors.white38, fontSize: 12),
          children: [
            TextSpan(text: '© 2024 '),
            TextSpan(text: 'Thammineni Technologies', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            TextSpan(text: '. All rights reserved.'),
          ],
        ),
      ),
    );
  }
}

class _CalcItem {
  final String title; final IconData icon; final Color color; final String route;
  _CalcItem({required this.title, required this.icon, required this.color, required this.route});
}

class _CalcCard extends StatefulWidget {
  final _CalcItem item;
  const _CalcCard({required this.item});
  @override
  State<_CalcCard> createState() => _CalcCardState();
}

class _CalcCardState extends State<_CalcCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, widget.item.route),
      onHover: (v) => setState(() => _isHovered = v),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF151A25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _isHovered ? widget.item.color : Colors.white.withValues(alpha: 0.05)),
          boxShadow: _isHovered ? [BoxShadow(color: widget.item.color.withValues(alpha: 0.2), blurRadius: 20)] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)), child: Icon(widget.item.icon, color: widget.item.color, size: 28)),
            const SizedBox(height: 12),
            Text(widget.item.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
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
    }))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.infinite, painter: _ParticlePainter(particles: _particles));
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
  _ParticlePainter({required this.particles});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.1);
    for (var p in particles) {
      final pos = Offset(p.x / 1000 * size.width, p.y / 1000 * size.height);
      canvas.drawCircle(pos, p.size, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
