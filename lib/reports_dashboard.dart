import 'package:flutter/material.dart';
import 'core_constants.dart';
import 'main.dart';

class ReportsDashboard extends StatefulWidget {
  const ReportsDashboard({super.key});

  @override
  State<ReportsDashboard> createState() => _ReportsDashboardState();
}

class _ReportsDashboardState extends State<ReportsDashboard> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surface;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final filteredReports = reportData.where((item) {
      final q = _searchQuery.toLowerCase().trim();
      return q.isEmpty || item.text.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? ktBgDark : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Reports Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          if (isDark) const AmbientBackground(),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: 'Search reports...',
                    hintStyle: TextStyle(color: textColor.withValues(alpha: 0.54)),
                    prefixIcon: const Icon(Icons.search_rounded, color: ktPrimary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: textColor.withValues(alpha: 0.7)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? ktCardBg : surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: textColor.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: textColor.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: ktPrimary, width: 2),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredReports.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 56, color: textColor.withValues(alpha: 0.54)),
                            const SizedBox(height: 12),
                            Text('No reports found', style: TextStyle(color: textColor.withValues(alpha: 0.7), fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.0),
                        itemCount: filteredReports.length,
                        itemBuilder: (context, i) {
                          final item = filteredReports[i];
                          return InkWell(
                            onTap: () => Navigator.pushNamed(context, item.route),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              decoration: BoxDecoration(color: isDark ? ktCardBg : surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: item.color.withValues(alpha: 0.2))),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(width: 56, height: 56, decoration: BoxDecoration(color: item.color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(item.icon, color: item.color, size: 28)),
                                  const SizedBox(height: 16),
                                  Text(item.text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
