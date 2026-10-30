import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core_utils.dart';
import 'package:ktppsflutter/core_constants.dart';
import 'debts_models.dart';
import 'debts_service.dart';
import 'debts_screen.dart';


// Keep the report's original dark palette while resolving light-mode contrast.
Color _reportColor(BuildContext context, Color dark, {bool surface = false, bool border = false}) {
  final theme = Theme.of(context);
  if (theme.brightness == Brightness.dark) return dark;
  if (surface) return theme.colorScheme.surfaceContainerLow;
  if (border) return theme.colorScheme.outlineVariant;
  final hsl = HSLColor.fromColor(dark);
  if (hsl.saturation < 0.1) {
    return dark.a < 1 ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.onSurface;
  }
  var light = hsl.withAlpha(1);
  final backgroundLuminance = theme.colorScheme.surfaceContainerLow.computeLuminance();
  while (light.lightness > 0.05 &&
      (backgroundLuminance + 0.05) / (light.toColor().computeLuminance() + 0.05) < 4.5) {
    light = light.withLightness((light.lightness - 0.02).clamp(0.0, 1.0));
  }
  return light.toColor();
}

class DebtsReportScreen extends StatefulWidget {
  const DebtsReportScreen({super.key});

  @override
  State<DebtsReportScreen> createState() => _DebtsReportScreenState();
}

class _DebtsReportScreenState extends State<DebtsReportScreen> {
  final DebtsService _service = DebtsService();
  List<DebtRecord> _allRecords = [];
  List<DebtRecord> _filteredRecords = [];
  bool _loading = false;

  String _searchQuery = '';
  String _statusFilter = 'pending';
  String _typeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final records = await _service.fetchRecords();
    setState(() {
      _allRecords = records;
      _applyFilters();
      _loading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredRecords = _allRecords.where((r) {
        final matchesSearch = r.person.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            r.remarks.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesStatus = _statusFilter == 'all' || r.status == _statusFilter;
        final matchesType = _typeFilter == 'all' || r.type == _typeFilter;
        return matchesSearch && matchesStatus && matchesType;
      }).toList();
      _filteredRecords.sort((a, b) => _parseDate(b.date).compareTo(_parseDate(a.date)));
    });
  }

  DateTime _parseDate(String dateStr) {
    return ktParseDate(dateStr) ?? getIndiaTime();
  }

  // Stats computation
  int get _activeCount => _allRecords.where((r) => r.status != 'settled').length;
  int get _peopleCount => _allRecords.where((r) => r.status != 'settled').map((r) => r.person).toSet().length;
  int get _settledCount => _allRecords.where((r) => r.status == 'settled').length;
  double get _totalLent => _allRecords.where((r) => r.status != 'settled' && r.type == 'given').fold(0.0, (sum, r) => sum + r.amount);
  double get _totalBorrowed => _allRecords.where((r) => r.status != 'settled' && r.type == 'taken').fold(0.0, (sum, r) => sum + r.amount);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 1000;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF030305) : Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          if (isDark) const _GridBackground(),
          if (isDark) const _BackgroundOrbs(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isDesktop),
                Expanded(
                  child: _loading && _allRecords.isEmpty
                      ? const Center(child: CircularProgressIndicator(color: ktPrimary))
                      : RefreshIndicator(
                          onRefresh: _fetchData,
                          color: ktPrimary,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 16),
                            child: Center(
                              child: Container(
                                constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : double.infinity),
                                child: Column(
                                  children: [
                                    _buildKPIGrid(isDesktop),
                                    const SizedBox(height: 24),
                                    _buildFilters(),
                                    const SizedBox(height: 24),
                                    if (_filteredRecords.isEmpty && !_loading)
                                      _buildEmptyState()
                                    else
                                      _buildGroupedList(),
                                    const SizedBox(height: 100),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          if (_loading && _allRecords.isNotEmpty)
            const Positioned(
              top: 0, left: 0, right: 0,
              child: LinearProgressIndicator(backgroundColor: Colors.transparent, color: ktPrimary),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDesktop) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: textColor),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Debts Intelligence',
                style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'Real-time cashflow visibility',
                style: TextStyle(color: textColor.withValues(alpha: 0.55), fontSize: 11),
              ),
            ],
          ),
          const Spacer(),
          _buildHeaderAction(Icons.refresh, _fetchData),
          const SizedBox(width: 8),
          _buildHeaderAction(Icons.add, () => Navigator.pushNamed(context, '/debts').then((_) => _fetchData())),
          const SizedBox(width: 8),
          _buildHeaderAction(Icons.home, () => Navigator.popUntil(context, (route) => route.isFirst)),
        ],
      ),
    );
  }

  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: textColor.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: _reportColor(context, ktTextGray400), size: 18),
      ),
    );
  }

  Widget _buildKPIGrid(bool isDesktop) {
    final lentPerc = (_totalLent + _totalBorrowed) > 0 ? _totalLent / (_totalLent + _totalBorrowed) : 0.0;
    final borrowedPerc = (_totalLent + _totalBorrowed) > 0 ? _totalBorrowed / (_totalLent + _totalBorrowed) : 0.0;

    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isDesktop ? 3 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isDesktop ? 2.5 : 1.5,
          children: [
            _KPIItem(title: 'Active Debts', value: _activeCount.toString(), color: ktPrimary),
            _KPIItem(title: 'People', value: _peopleCount.toString(), color: const Color(0xFF8B5CF6)),
            _KPIItem(title: 'Settled', value: _settledCount.toString(), color: ktEmerald),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KPIItem(
                title: 'Receivable',
                value: '₹${NumberFormat('#,##,###').format(_totalLent)}',
                color: ktEmerald,
                progress: lentPerc,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KPIItem(
                title: 'Payable',
                value: '₹${NumberFormat('#,##,###').format(_totalBorrowed)}',
                color: const Color(0xFFF43F5E),
                progress: borrowedPerc,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _reportColor(context, Color(0xFF151A25), surface: true),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _reportColor(context, Colors.white).withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (v) { setState(() => _searchQuery = v); _applyFilters(); },
            style: TextStyle(color: _reportColor(context, Colors.white), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by name or remarks...',
              hintStyle: TextStyle(color: _reportColor(context, Colors.white.withValues(alpha: 0.2))),
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.2),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(label: 'Pending', isActive: _statusFilter == 'pending', color: const Color(0xFFFBBF24), onTap: () { setState(() => _statusFilter = 'pending'); _applyFilters(); }),
                const SizedBox(width: 8),
                _FilterChip(label: 'Settled', isActive: _statusFilter == 'settled', color: ktEmerald, onTap: () { setState(() => _statusFilter = 'settled'); _applyFilters(); }),
                const SizedBox(width: 8),
                _FilterChip(label: 'All Status', isActive: _statusFilter == 'all', color: ktPrimary, onTap: () { setState(() => _statusFilter = 'all'); _applyFilters(); }),
                VerticalDivider(color: _reportColor(context, Colors.white10)),
                _FilterChip(label: 'Lent', isActive: _typeFilter == 'given', color: ktEmerald, onTap: () { setState(() => _typeFilter = 'given'); _applyFilters(); }),
                const SizedBox(width: 8),
                _FilterChip(label: 'Borrowed', isActive: _typeFilter == 'taken', color: const Color(0xFFF43F5E), onTap: () { setState(() => _typeFilter = 'taken'); _applyFilters(); }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    final Map<String, List<DebtRecord>> groups = {};
    for (var r in _filteredRecords) {
      groups.putIfAbsent(r.person, () => []).add(r);
    }

    final sortedPersons = groups.keys.toList()..sort();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedPersons.length,
      itemBuilder: (context, index) {
        final person = sortedPersons[index];
        final items = groups[person]!;
        double net = 0;
        for (var i in items) {
          if (i.status != 'settled') {
            if (i.type == 'given') {
              net += i.amount;
            } else {
              net -= i.amount;
            }
          }
        }

        return _PersonGroup(
          person: person,
          items: items,
          net: net,
          onAction: (action, record) => _handleAction(action, record),
        );
      },
    );
  }

  void _handleAction(String action, DebtRecord record) async {
    if (action == 'edit') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => DebtsScreen(editRecord: record))).then((v) {
        if (v == true) _fetchData();
      });
    } else if (action == 'delete') {
      _confirmDelete(record);
    } else if (action == 'toggle') {
      _toggleStatus(record);
    }
  }

  Future<void> _confirmDelete(DebtRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _reportColor(context, Color(0xFF1E1B4B), surface: true),
        title: Text('Delete Record', style: TextStyle(color: _reportColor(context, Colors.white))),
        content: Text('Are you sure you want to delete this record?', style: TextStyle(color: _reportColor(context, ktTextGray400))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: _reportColor(context, Colors.red)))),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _loading = true);
      await _service.deleteRecord(record.id!);
      _fetchData();
    }
  }

  Future<void> _toggleStatus(DebtRecord record) async {
    final newStatus = record.status == 'settled' ? 'pending' : 'settled';
    final remarksController = TextEditingController();
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _reportColor(context, Color(0xFF1E1B4B), surface: true),
        title: Text(newStatus == 'settled' ? 'Settle Debt' : 'Reopen Debt', style: TextStyle(color: _reportColor(context, Colors.white))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mark this debt as $newStatus?', style: TextStyle(color: _reportColor(context, Colors.white70))),
            const SizedBox(height: 16),
            TextField(
              controller: remarksController,
              decoration: InputDecoration(hintText: 'Remarks (optional)', hintStyle: TextStyle(color: _reportColor(context, Colors.white24))),
              style: TextStyle(color: _reportColor(context, Colors.white)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(newStatus == 'settled' ? 'Settle' : 'Reopen')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      await _service.updateStatus(record.id!, newStatus, remarksController.text);
      _fetchData();
    }
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(Icons.inbox_outlined, size: 64, color: _reportColor(context, Colors.white).withValues(alpha: 0.1)),
        const SizedBox(height: 16),
        Text('No records found', style: TextStyle(color: _reportColor(context, Colors.grey), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSkeletons() {
    return Column(children: List.generate(3, (i) => Container(height: 100, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: _reportColor(context, Colors.white).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24)))));
  }
}

class _KPIItem extends StatelessWidget {
  final String title, value;
  final Color color;
  final double? progress;
  const _KPIItem({required this.title, required this.value, required this.color, this.progress});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151A25) : surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: textColor.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w900)),
          if (progress != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: _reportColor(context, Colors.white).withValues(alpha: 0.05), valueColor: AlwaysStoppedAnimation(color)),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isActive, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? color.withValues(alpha: 0.5) : _reportColor(context, Colors.white).withValues(alpha: 0.1)),
        ),
        child: Text(label, style: TextStyle(color: _reportColor(context, isActive ? color : _reportColor(context, Colors.white38)), fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _PersonGroup extends StatelessWidget {
  final String person;
  final List<DebtRecord> items;
  final double net;
  final Function(String, DebtRecord) onAction;

  const _PersonGroup({required this.person, required this.items, required this.net, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final netColor = net >= 0 ? ktEmerald : const Color(0xFFF43F5E);
    final netLabel = net >= 0 ? 'Pays you' : 'You pay';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _reportColor(context, Color(0xFF151A25), surface: true).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _reportColor(context, Colors.white).withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _reportColor(context, Colors.white).withValues(alpha: 0.02),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: _reportColor(context, Colors.white).withValues(alpha: 0.05))),
            ),
            child: Row(
              children: [
                CircleAvatar(backgroundColor: Colors.indigo.withValues(alpha: 0.2), child: Text(person.substring(0, 1).toUpperCase(), style: TextStyle(color: _reportColor(context, Colors.indigoAccent), fontWeight: FontWeight.bold))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(person, style: TextStyle(color: _reportColor(context, Colors.white), fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${items.length} transactions', style: TextStyle(color: _reportColor(context, Colors.white.withValues(alpha: 0.3)), fontSize: 10)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: netColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: netColor.withValues(alpha: 0.2))),
                  child: Text('$netLabel ₹${NumberFormat('#,##,###').format(net.abs())}', style: TextStyle(color: _reportColor(context, netColor), fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: items.map((item) => _DebtRow(item: item, onAction: onAction)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  final DebtRecord item;
  final Function(String, DebtRecord) onAction;
  const _DebtRow({required this.item, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final isLent = item.type == 'given';
    final isSettled = item.status == 'settled';
    final color = isLent ? ktEmerald : const Color(0xFFF43F5E);
    final dt = ktParseDate(item.date) ?? getIndiaTime();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withValues(alpha: 0.2) : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Opacity(
        opacity: isSettled ? 0.6 : 1.0,
        child: Row(
          children: [
            Container(
              width: 58, height: 44,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    ktFormatDate(dt).replaceFirst(' ', '\n'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _reportColor(context, color), fontSize: 10, fontWeight: FontWeight.w900, height: 1.1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isLent ? 'Given to $person' : 'Taken from $person', style: TextStyle(color: _reportColor(context, Colors.white), fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Badge(label: isLent ? 'Lent' : 'Borrowed', color: color),
                      const SizedBox(width: 4),
                      _Badge(label: isSettled ? 'Settled' : 'Pending', color: isSettled ? ktEmerald : const Color(0xFFFBBF24)),
                    ],
                  ),
                  if (item.remarks.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(item.remarks, style: TextStyle(color: _reportColor(context, Colors.white.withValues(alpha: 0.3)), fontSize: 10, fontStyle: FontStyle.italic), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₹${NumberFormat('#,##,###').format(item.amount)}', style: TextStyle(color: _reportColor(context, isSettled ? _reportColor(context, Colors.white24) : _reportColor(context, Colors.white)), fontSize: 14, fontWeight: FontWeight.w900, decoration: isSettled ? TextDecoration.lineThrough : null)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _RowActionBtn(icon: Icons.edit_note, onTap: () => onAction('edit', item)),
                    const SizedBox(width: 4),
                    _RowActionBtn(icon: isSettled ? Icons.restore : Icons.check_circle_outline, color: isSettled ? Colors.amber : Colors.teal, onTap: () => onAction('toggle', item)),
                    const SizedBox(width: 4),
                    _RowActionBtn(icon: Icons.delete_outline, color: Colors.redAccent, onTap: () => onAction('delete', item)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String get person => item.person;
}

class _Badge extends StatelessWidget {
  final String label; final Color color;
  const _Badge({required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))), child: Text(label, style: TextStyle(color: _reportColor(context, color), fontSize: 8, fontWeight: FontWeight.bold)));
  }
}

class _RowActionBtn extends StatelessWidget {
  final IconData icon; final Color? color; final VoidCallback onTap;
  const _RowActionBtn({required this.icon, this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: Container(width: 28, height: 28, decoration: BoxDecoration(color: _reportColor(context, Colors.white).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: _reportColor(context, Colors.white).withValues(alpha: 0.1))), child: Icon(icon, color: color ?? _reportColor(context, Colors.white38), size: 14)));
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.infinite, painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.015)..strokeWidth = 1.0;
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

class _BackgroundOrbs extends StatelessWidget {
  const _BackgroundOrbs();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(top: -100, left: -100, child: Container(width: 400, height: 400, decoration: BoxDecoration(color: ktPrimary.withValues(alpha: 0.05), shape: BoxShape.circle), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)))),
        Positioned(bottom: -50, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(color: ktEmerald.withValues(alpha: 0.05), shape: BoxShape.circle), child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)))),
      ],
    );
  }
}
