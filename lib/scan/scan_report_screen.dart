import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ktppsflutter/core_constants.dart';
import 'scan_models.dart';
import 'scan_service.dart';

class ScanReportScreen extends StatefulWidget {
  const ScanReportScreen({super.key});

  @override
  State<ScanReportScreen> createState() => _ScanReportScreenState();
}

class _ScanReportScreenState extends State<ScanReportScreen> {
  final ScanService _service = ScanService();
  List<ScanRecord> _allScans = [];
  List<ScanRecord> _filteredScans = [];
  bool _loading = false;
  bool _isGridView = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final scans = await _service.fetchScans();
    setState(() {
      _allScans = scans;
      _applyFilters();
      _loading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredScans = _allScans.where((s) {
        return s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               s.timestamp.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
      _filteredScans.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

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
                  child: RefreshIndicator(
                    onRefresh: _fetchData,
                    color: Colors.indigoAccent,
                    child: _loading && _allScans.isEmpty
                        ? _buildSkeletons()
                        : _filteredScans.isEmpty
                            ? _buildEmptyState()
                            : _buildContent(),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
              const Text('Scan History', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              _HeaderBtn(icon: _isGridView ? Icons.view_list : Icons.grid_view, onTap: () => setState(() => _isGridView = !_isGridView)),
              const SizedBox(width: 8),
              _HeaderBtn(icon: Icons.home_outlined, onTap: () => Navigator.popUntil(context, (r) => r.isFirst)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) { setState(() => _searchQuery = v); _applyFilters(); },
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search documents...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
              prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 20),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.8),
        itemCount: _filteredScans.length,
        itemBuilder: (context, i) => _ScanCard(scan: _filteredScans[i], index: i, onTap: () => _openLightbox(i)),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredScans.length,
        itemBuilder: (context, i) => _ScanListTile(scan: _filteredScans[i], onTap: () => _openLightbox(i)),
      );
    }
  }

  void _openLightbox(int index) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => _LightboxScreen(scans: _filteredScans, initialIndex: index)));
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.search_off, size: 64, color: Colors.white10), const SizedBox(height: 16), Text(_searchQuery.isEmpty ? 'No scans found' : 'No matching results', style: const TextStyle(color: Colors.white38))]));
  }

  Widget _buildSkeletons() {
    return GridView.count(padding: const EdgeInsets.all(16), crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, children: List.generate(6, (i) => Container(decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)))));
  }

  Widget _buildBackgroundOrbs() {
    return Stack(children: [
      Positioned(top: -100, right: -100, child: _Orb(color: Colors.indigoAccent.withValues(alpha: 0.1), size: 300)),
      Positioned(bottom: -100, left: -100, child: _Orb(color: Colors.purpleAccent.withValues(alpha: 0.05), size: 300)),
    ]);
  }
}

class _ScanCard extends StatelessWidget {
  final ScanRecord scan; final int index; final VoidCallback onTap;
  const _ScanCard({required this.scan, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String imageUrl = scan.id.isNotEmpty ? 'https://lh3.googleusercontent.com/d/${scan.id}' : scan.url;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF151A25), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Stack(children: [
              Positioned.fill(child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.black26, child: const Icon(Icons.broken_image, color: Colors.white10)))),
              Positioned(bottom: 8, left: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)), child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
            ])),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(DateFormat('MMM d, y').format(DateTime.tryParse(scan.timestamp) ?? DateTime.now()), style: const TextStyle(color: Colors.indigoAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(scan.name, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanListTile extends StatelessWidget {
  final ScanRecord scan; final VoidCallback onTap;
  const _ScanListTile({required this.scan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String imageUrl = scan.id.isNotEmpty ? 'https://lh3.googleusercontent.com/d/${scan.id}' : scan.url;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF151A25), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
        child: Row(
          children: [
            Container(width: 60, height: 44, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(scan.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(DateFormat('MMM d, y').format(DateTime.tryParse(scan.timestamp) ?? DateTime.now()), style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ])),
            const Icon(Icons.chevron_right, color: Colors.white10),
          ],
        ),
      ),
    );
  }
}

class _LightboxScreen extends StatefulWidget {
  final List<ScanRecord> scans; final int initialIndex;
  const _LightboxScreen({required this.scans, required this.initialIndex});
  @override
  State<_LightboxScreen> createState() => _LightboxScreenState();
}

class _LightboxScreenState extends State<_LightboxScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.scans.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, i) {
              final scan = widget.scans[i];
              String imageUrl = scan.id.isNotEmpty ? 'https://lh3.googleusercontent.com/d/${scan.id}' : scan.url;
              return Center(child: InteractiveViewer(minScale: 0.5, maxScale: 4.0, child: Image.network(imageUrl, fit: BoxFit.contain)));
            },
          ),
          Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
          Positioned(bottom: 40, left: 0, right: 0, child: Column(children: [
            Text(widget.scans[_currentIndex].name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('${_currentIndex + 1} / ${widget.scans.length}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ])),
        ],
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))), child: Icon(icon, color: Colors.white60, size: 20)));
  }
}

class _Orb extends StatelessWidget {
  final Color color; final double size;
  const _Orb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) { return Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent))); }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();
  @override
  Widget build(BuildContext context) { return CustomPaint(size: Size.infinite, painter: _GridPainter()); }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.01)..strokeWidth = 1.0;
    const step = 40.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
