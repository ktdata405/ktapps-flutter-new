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
    final filteredReports = reportData.where((item) {
      final q = _searchQuery.toLowerCase().trim();
      return q.isEmpty || item.text.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? ktBgDark : ktLightScaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        title: Text(
          'Reports Dashboard',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          const AmbientBackground(),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search reports...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: ktPrimary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? ktCardBg : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? ktBorderWhite10 : Colors.black.withValues(alpha: 0.1),
                      ),
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
                            Icon(
                              Icons.search_off_rounded,
                              size: 56,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No reports found',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black87,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: filteredReports.length,
                        itemBuilder: (context, i) {
                          final item = filteredReports[i];
                          return InkWell(
                            onTap: () => Navigator.pushNamed(context, item.route),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? ktCardBg : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: isDark
                                      ? item.color.withValues(alpha: 0.2)
                                      : item.color.withValues(alpha: 0.3),
                                ),
                                boxShadow: isDark
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.04),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: item.color.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(item.icon, color: item.color, size: 28),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    item.text,
                                    style: TextStyle(
                                      color: isDark ? ktTextWhite : Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
