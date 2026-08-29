import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:ktppsflutter/core_constants.dart';
import 'wallet_models.dart';
import 'wallet_service.dart';

class WalletReportScreen extends StatefulWidget {
  const WalletReportScreen({super.key});

  @override
  State<WalletReportScreen> createState() => _WalletReportScreenState();
}

class _WalletReportScreenState extends State<WalletReportScreen> {
  final WalletService _service = WalletService();
  List<WalletRecord> _allEntries = [];
  List<WalletRecord> _filteredEntries = [];
  bool _loading = false;
  bool _maskSensitive = true;
  bool _isGridView = true;

  String _searchQuery = '';
  String _ownerFilter = '';
  String _typeFilter = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final entries = await _service.fetchEntries();
    setState(() {
      _allEntries = entries;
      _applyFilters();
      _loading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredEntries = _allEntries.where((e) {
        final matchesSearch = e.owner.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            e.textValue.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesOwner = _ownerFilter.isEmpty || e.owner == _ownerFilter;
        final matchesType = _typeFilter.isEmpty || e.type == _typeFilter;
        // Status matching is approximate as it's computed
        return matchesSearch && matchesOwner && matchesType;
      }).toList();
      _filteredEntries.sort((a, b) => b.savedAt.compareTo(a.savedAt));
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
                    color: Colors.cyanAccent,
                    child: _loading && _allEntries.isEmpty
                        ? _buildSkeletons()
                        : _filteredEntries.isEmpty
                            ? _buildEmptyState()
                            : _buildContent(),
                  ),
                ),
              ],
            ),
          ),
          if (_loading && _allEntries.isNotEmpty)
            const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.cyanAccent)),
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wallet Report', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Secured Vault Records', style: TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
              const Spacer(),
              _HeaderBtn(icon: _maskSensitive ? Icons.visibility_off : Icons.visibility, onTap: () => setState(() => _maskSensitive = !_maskSensitive)),
              const SizedBox(width: 8),
              _HeaderBtn(icon: _isGridView ? Icons.view_list : Icons.grid_view, onTap: () => setState(() => _isGridView = !_isGridView)),
              const SizedBox(width: 8),
              _HeaderBtn(icon: Icons.add, onTap: () => Navigator.pushNamed(context, '/wallet')),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) { setState(() => _searchQuery = v); _applyFilters(); },
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search bank, ID, card...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
              prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 20),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          _buildFilters(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final owners = _allEntries.map((e) => e.owner).toSet().toList()..sort();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All Owners', _ownerFilter.isEmpty, () => setState(() { _ownerFilter = ''; _applyFilters(); })),
          ...owners.map((o) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _buildFilterChip(o, _ownerFilter == o, () => setState(() { _ownerFilter = o; _applyFilters(); })),
          )),
          const SizedBox(width: 16),
          _buildFilterChip('Credentials', _typeFilter == 'credential', () => setState(() { _typeFilter = _typeFilter == 'credential' ? '' : 'credential'; _applyFilters(); })),
          const SizedBox(width: 8),
          _buildFilterChip('IDs', _typeFilter == 'id_card', () => setState(() { _typeFilter = _typeFilter == 'id_card' ? '' : 'id_card'; _applyFilters(); })),
          const SizedBox(width: 8),
          _buildFilterChip('Cards', _typeFilter == 'card', () => setState(() { _typeFilter = _typeFilter == 'card' ? '' : 'card'; _applyFilters(); })),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: active ? Colors.cyanAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: active ? Colors.cyanAccent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.1))),
        child: Text(label, style: TextStyle(color: active ? Colors.cyanAccent : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildContent() {
    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.1),
        itemCount: _filteredEntries.length,
        itemBuilder: (context, i) => _WalletCard(entry: _filteredEntries[i], mask: _maskSensitive, onDelete: () => _confirmDelete(_filteredEntries[i])),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredEntries.length,
        itemBuilder: (context, i) => _WalletListTile(entry: _filteredEntries[i], mask: _maskSensitive, onDelete: () => _confirmDelete(_filteredEntries[i])),
      );
    }
  }

  Future<void> _confirmDelete(WalletRecord entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Entry', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete this record for ${entry.title}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _loading = true);
      await _service.deleteEntry(entry.id);
      _fetchData();
    }
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.shield_outlined, size: 64, color: Colors.white10), const SizedBox(height: 16), Text(_searchQuery.isEmpty ? 'No records found' : 'No matching results', style: const TextStyle(color: Colors.white38))]));
  }

  Widget _buildSkeletons() {
    return ListView.builder(padding: const EdgeInsets.all(16), itemCount: 5, itemBuilder: (c, i) => Container(height: 100, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24))));
  }

  Widget _buildBackgroundOrbs() {
    return Stack(children: [
      Positioned(top: -100, left: -100, child: _Orb(color: Colors.indigoAccent.withValues(alpha: 0.05), size: 400)),
      Positioned(bottom: -100, right: -100, child: _Orb(color: Colors.cyanAccent.withValues(alpha: 0.05), size: 400)),
    ]);
  }
}

class _WalletCard extends StatelessWidget {
  final WalletRecord entry; final bool mask; final VoidCallback onDelete;
  const _WalletCard({required this.entry, required this.mask, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF151A25), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IconBox(icon: _getIcon(), color: color),
              IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white24), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: 12),
          Text(entry.owner.toUpperCase(), style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          Text(entry.title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Text(_getPrimaryDetail(), style: const TextStyle(color: Colors.white38, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Color _getColor() {
    if (entry.type == 'credential') return Colors.cyanAccent;
    if (entry.type == 'id_card') return Colors.indigoAccent;
    return Colors.tealAccent;
  }

  IconData _getIcon() {
    if (entry.type == 'credential') return Icons.key_outlined;
    if (entry.type == 'id_card') return Icons.badge_outlined;
    return Icons.credit_card_outlined;
  }

  String _getPrimaryDetail() {
    if (entry.type == 'credential') return entry.credUsername ?? '';
    if (entry.type == 'id_card') return entry.idNumber ?? '';
    return mask ? '**** ${_last4(entry.cardNumber ?? '')}' : (entry.cardNumber ?? '');
  }

  String _last4(String s) {
    final clean = s.replaceAll(RegExp(r'\s+'), '');
    if (clean.length < 4) return clean;
    return clean.substring(clean.length - 4);
  }
}

class _WalletListTile extends StatelessWidget {
  final WalletRecord entry; final bool mask; final VoidCallback onDelete;
  const _WalletListTile({required this.entry, required this.mask, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF151A25), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(
        children: [
          _IconBox(icon: _getIcon(), color: color),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${entry.owner} • ${entry.type.replaceAll('_', ' ').toUpperCase()}', style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold)),
            Text(entry.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(_getDetails(), style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ])),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.white24)),
        ],
      ),
    );
  }

  Color _getColor() {
    if (entry.type == 'credential') return Colors.cyanAccent;
    if (entry.type == 'id_card') return Colors.indigoAccent;
    return Colors.tealAccent;
  }

  IconData _getIcon() {
    if (entry.type == 'credential') return Icons.key;
    if (entry.type == 'id_card') return Icons.badge;
    return Icons.credit_card;
  }

  String _getDetails() {
    if (entry.type == 'credential') return 'User: ${entry.credUsername} | Pass: ${mask ? '******' : entry.credLoginPassword}';
    if (entry.type == 'id_card') return 'No: ${entry.idNumber} | Name: ${entry.idName}';
    return 'No: ${mask ? '**** **** **** ${_last4(entry.cardNumber ?? '')}' : entry.cardNumber} | CVV: ${mask ? '***' : entry.cardCvv}';
  }

  String _last4(String s) {
    final clean = s.replaceAll(RegExp(r'\s+'), '');
    if (clean.length < 4) return clean;
    return clean.substring(clean.length - 4);
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon; final Color color;
  const _IconBox({required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20));
  }
}

class _HeaderBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _HeaderBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Colors.white70, size: 20)));
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
