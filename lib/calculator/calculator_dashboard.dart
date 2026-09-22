import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core_constants.dart';

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
      backgroundColor: ktBgDark,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: const [ktTextWhite, Colors.white38, ktTextWhite],
                    stops: [
                      _shimmerController.value - 0.2,
                      _shimmerController.value,
                      _shimmerController.value + 0.2,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: const Text(KtStrings.calculators, style: TextStyle(color: ktTextWhite, fontSize: 20, fontWeight: FontWeight.bold)),
              );
            },
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _openQuickCalculator(context),
                icon: const Icon(Icons.calculate_outlined, color: ktTextWhite, size: 20),
                tooltip: 'Quick Calculator',
                style: IconButton.styleFrom(backgroundColor: ktBorderWhite5, padding: const EdgeInsets.all(8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: ktTextWhite, size: 20),
                style: IconButton.styleFrom(backgroundColor: ktBorderWhite5, padding: const EdgeInsets.all(8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openQuickCalculator(BuildContext context) {
    String expr = '';
    String output = '0';

    double? evalExpr(String value) {
      final safe = value.replaceAll(' ', '');
      final token = RegExp(r'(-?\d+(?:\.\d+)?)|[+\-*/]');
      final tokens = token.allMatches(safe).map((m) => m.group(0)!).toList(growable: false);
      if (tokens.isEmpty) return null;

      final numbers = <double>[];
      final ops = <String>[];
      int i = 0;
      while (i < tokens.length) {
        final t = tokens[i];
        final n = double.tryParse(t);
        if (n != null) {
          numbers.add(n);
          i++;
          continue;
        }
        if (['*', '/'].contains(t) && numbers.isNotEmpty && i + 1 < tokens.length) {
          final r = double.tryParse(tokens[i + 1]);
          if (r == null) return null;
          final l = numbers.removeLast();
          numbers.add(t == '*' ? l * r : l / r);
          i += 2;
          continue;
        }
        ops.add(t);
        i++;
      }

      double acc = numbers.firstOrNull ?? 0;
      for (var j = 0; j < ops.length; j++) {
        if (j + 1 >= numbers.length) break;
        acc = ops[j] == '+' ? acc + numbers[j + 1] : acc - numbers[j + 1];
      }
      return acc;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setInner) {
            void append(String t) {
              setInner(() {
                expr += t;
                output = expr;
              });
            }

            return Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.05)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: ktEmerald.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.calculate, color: ktEmerald, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              KtStrings.calculator,
                              style: TextStyle(
                                color: isDark ? ktTextWhite : Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close, color: isDark ? Colors.white54 : Colors.black45, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? ktBorderWhite10 : Colors.black12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            expr.isEmpty ? '0' : expr,
                            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            output,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: isDark ? ktTextWhite : Colors.black87,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final key in ['7', '8', '9', '/', '4', '5', '6', '*', '1', '2', '3', '-', '0', '.', 'C', '+'])
                              SizedBox(
                                width: 56,
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isDark ? ktBorderWhite5 : Colors.grey.shade200,
                                    foregroundColor: isDark ? ktTextWhite : Colors.black87,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: EdgeInsets.zero,
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    if (key == 'C') {
                                      setInner(() {
                                        expr = '';
                                        output = '0';
                                      });
                                      return;
                                    }
                                    append(key);
                                  },
                                  child: Text(key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ktEmerald,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              final result = evalExpr(expr);
                              if (result == null) {
                                setInner(() => output = 'Error');
                              } else {
                                setInner(() {
                                  output = result.toStringAsFixed(result.truncateToDouble() == result ? 0 : 2);
                                  expr = output;
                                });
                              }
                            },
                            child: const Text('CALCULATE RESULT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGrid() {
    final items = [
      _CalcItem(title: KtStrings.landCalculator, icon: Icons.straighten, color: ktEmerald, route: '/calculator/land'),
      _CalcItem(title: KtStrings.govtSchemes, icon: Icons.account_balance, color: ktOrange, route: '/calculator/govt'),
      _CalcItem(title: KtStrings.interestFloatFlat, icon: Icons.percent, color: ktSecondary, route: '/calculator/interest'),
      _CalcItem(title: KtStrings.villageFinance, icon: Icons.people, color: ktSecondary, route: '/calculator/village'),
      _CalcItem(title: KtStrings.lamfCalculator, icon: Icons.savings, color: ktOrange, route: '/calculator/lamf'),
    ];

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 850),
        child: LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = 3;
            double childAspectRatio = 1.8;
            
            if (constraints.maxWidth > 900) {
              crossAxisCount = 5;
              childAspectRatio = 1.9;
            } else if (constraints.maxWidth > 600) {
              crossAxisCount = 4;
              childAspectRatio = 1.8;
            }

            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => _CalcCard(item: items[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(color: Colors.white38, fontSize: 11),
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
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: _isHovered ? ktCardBg.withValues(alpha: 0.8) : ktCardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered ? widget.item.color.withValues(alpha: 0.5) : ktBorderWhite5,
            width: 1.5,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: widget.item.color.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: _isHovered ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.item.icon, color: widget.item.color, size: 20),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.item.title,
              style: TextStyle(
                color: ktTextWhite.withValues(alpha: _isHovered ? 1.0 : 0.85),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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
